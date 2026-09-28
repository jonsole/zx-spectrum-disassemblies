    DEVICE ZXSPECTRUM48
  ORG $5B00

; The printer buffer, unused
;
; Zeros, as the ROM left them. The loader's routine sits in the middle of the
; buffer (LOADER); nothing else uses it.
PRINTER_BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The loader's routine: unscramble the game and start it
;
; Loaded from the tape into the printer buffer and run by the BASIC loader's
; PRINT USR. It sets bit 7 of the R register, which the refresh count never
; changes and which the game checks at every new game (STOCK_BUILDINGS);
; unscrambles the game block, which the tape loaded 512 bytes higher, a pair of
; bytes at a time -- RLD with the second byte swaps a nibble between the two;
; moves it all down to ENTRY; and jumps there. The build does the same to the
; tape's block and checks the result is the snapshot's (check_loader in
; scripts/build_nightshade.py).
;
; The DI here is for good: nothing in the game enables interrupts again, so
; FRAMES, which the interrupt counts, keeps the value the tape gave it for as
; long as the game runs (SYSTEM_VARIABLES).
LOADER:
  DI                      ; interrupts off, never to come back on
  LD A,R                  ; set bit 7 of R, the mark STOCK_BUILDINGS looks for;
  OR $80                  ; the refresh counts only the low seven bits
  LD R,A                  ;
  LD DE,$6000             ; DE and HL on the first pair of the loaded block;
  LD HL,$6001             ; 17408 pairs
  LD BC,$4400             ;
LOADER_0:
  LD A,(DE)               ; the first byte becomes its own high nibble and the
  RLD                     ; second's; the second, its own low nibble and the
  LD (DE),A               ; first's
  INC DE                  ; on to the next pair, until all are done
  INC DE                  ;
  INC HL                  ;
  INC HL                  ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,LOADER_0          ;
  LD HL,$6000             ; move the whole block down 512 bytes, to where it
  LD DE,ENTRY             ; runs
  LD BC,$8800             ;
  LDIR                    ;
  JP ENTRY                ; and start it

; The rest of the printer buffer, unused
;
; Zeros, as the ROM left them.
PRINTER_BUFFER_END:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
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

; The system variables
;
; The ROM's system variables, as the BASIC loader left them. The game reads
; only two of them, and both were loaded from the tape rather than set by the
; ROM. FRAMES, from the tape's last block: the game checks its middle byte
; (START, the first of the three protection checks) and starts its turn counter
; from it at every new game (NEW_GAME); since interrupts stay off from the
; loader on, FRAMES never counts on, and every game starts its counter from the
; same value. And NMIADD (NMIADD), where the tape put the JP (HL) the game
; dispatches through.
SYSTEM_VARIABLES:
  DEFB $FF,$00,$00,$00,$FF,$00,$23,$0D ; KSTATE to SEED
  DEFB $0D,$23,$05,$00,$00,$00,$16,$13 ;
  DEFB $01,$00,$06,$00,$0B,$00,$01,$00 ;
  DEFB $01,$00,$06,$00,$10,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$3C ;
  DEFB $40,$00,$FF,$CD,$00,$54,$FF,$00 ;
  DEFB $00,$00,$00,$00,$FF,$00,$00,$16 ;
  DEFB $07,$00,$00,$2E,$5E,$00,$00,$B6 ;
  DEFB $5C,$BB,$5C,$CB,$5C,$2E,$5E,$CA ;
  DEFB $5C,$2F,$5E,$32,$5E,$2D,$5E,$EF ;
  DEFB $5E,$34,$5E,$34,$5E,$34,$5E,$2D ;
  DEFB $92,$5C,$00,$02,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$9D,$1A,$00,$00 ;
FRAMES:
  DEFB $34                ; FRAMES, low byte: $34 from the tape, counted on by
                          ; the interrupts that ran before the loader turned
                          ; them off
FRAMES_MIDDLE:
  DEFB $63                ; FRAMES, middle byte: $63 from the tape; the game's
                          ; start returns to BASIC unless it still is (START)
  DEFB $00,$58,$FF,$00,$00,$21,$00,$5B ; FRAMES' high byte to ERR_SP
  DEFB $21,$17,$C0,$50,$E0,$50,$21,$02 ;
  DEFB $21,$17,$03,$40,$00,$40,$00,$00 ;
  DEFB $89,$2E,$9D,$36,$B1,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ;

; The dispatcher's jump
;
; Used by the routine at DISPATCH.
;
; The system variable NMIADD, which the tape loaded with this one byte, JP
; (HL): the second protection check. DISPATCH ends with a jump here, so every
; object's update routine (UPDATES), and the routines of the five smaller
; tables (MONSTER_HIT_TABLE among them), are reached through it. Without the
; tape's byte the jump would run the system variables' own bytes as code, and
; the game would crash at its first update (read, not run; a copy loaded
; without the small blocks is stopped earlier anyway, by START). The game's
; stack, which leaks two bytes at each game over, reaches this byte after 156
; of them and overwrites it (see START).
NMIADD:
  JP (HL)                 ; on to the routine the table gave

; The rest of the system variables
NMIADD_HIGH:
  DEFB $00,$57,$FF,$FF,$FF,$F4,$09,$A8 ; NMIADD's high byte to the end of the
  DEFB $10,$4B,$F4,$09,$C4,$15,$53,$81 ; system variables
  DEFB $0F,$C4,$15,$52,$F4,$09,$C4,$15 ;
  DEFB $50,$80                         ;

; The BASIC loader, and the game's stack
;
; What is left of the BASIC loader: the game block was moved down over its last
; 46 bytes. The game's stack grows down from ENTRY into the top of it (START
; sets SP); in a measured run it went no deeper than 24 bytes.
BASIC_PROGRAM:
  DEFB $00,$00,$5F,$01,$D7,$2E,$31,$0E,$7D,$4C,$CC,$CC,$CC,$2C,$31,$0E
  DEFB $00,$00,$01,$00,$00,$3A,$D7,$2E,$31,$0E,$7D,$4C,$CC,$CC,$CC,$2C
  DEFB $32,$0E,$00,$00,$02,$00,$00,$3A,$D7,$2E,$31,$0E,$7D,$4C,$CC,$CC
  DEFB $CC,$2C,$33,$0E,$00,$00,$03,$00,$00,$3A,$D7,$2E,$31,$0E,$7D,$4C
  DEFB $CC,$CC,$CC,$2C,$34,$0E,$00,$00,$04,$00,$00,$3A,$D7,$2E,$31,$0E
  DEFB $7D,$4C,$CC,$CC,$CC,$2C,$35,$0E,$00,$00,$05,$00,$00,$3A,$DA,$30
  DEFB $0E,$00,$00,$00,$00,$00,$3A,$E7,$30,$0E,$00,$00,$00,$00,$00,$3A
  DEFB $D9,$37,$0E,$00,$00,$07,$00,$00,$3A,$DC,$31,$0E,$00,$00,$01,$00
  DEFB $00,$3A,$FB,$3A,$F5,$AC,$39,$0E,$00,$00,$09,$00,$00,$2C,$35,$0E
  DEFB $00,$00,$05,$00,$00,$3B,$22,$4E,$49,$47,$48,$54,$20,$53,$48,$41
  DEFB $44,$45,$20,$49,$53,$20,$4C,$4F,$41,$44,$49,$4E,$47,$22,$3B,$AC
  DEFB $31,$32,$0E,$00,$00,$0C,$00,$00,$2C,$31,$30,$0E,$00,$00,$0A,$00
  DEFB $00,$3B,$22,$14,$01,$50,$4C,$45,$41,$53,$45,$20,$57,$41,$49,$54
  DEFB $22,$14,$01,$14,$00,$3B,$AC,$30,$0E,$00,$00,$00,$00,$00,$2C,$30
  DEFB $0E,$00,$00,$00,$00,$00,$3A,$EF,$22,$22,$AA,$3A,$D9,$30,$0E,$00
  DEFB $00,$00,$00,$00,$3A,$F5,$AC,$31,$39,$0E,$00,$00,$13,$00,$00,$2C
  DEFB $30,$0E,$00,$00,$00,$00,$00,$3A,$EF,$22,$22,$AF,$3A,$F5,$AC,$31
  DEFB $39,$0E,$00,$00,$13,$00,$00,$2C,$30,$0E,$00,$00,$00,$00,$00,$3A
  DEFB $EF,$22,$22,$AF,$3A,$F5,$AC,$31,$39,$0E,$00,$00,$13,$00,$00,$2C
  DEFB $30,$0E,$00,$00,$00

; Where the loader enters the game
;
; Used by the routine at LOADER.
;
; The loader jumps here once the game is in place. Interrupts are already off;
; the game keeps them so, and starts at START.
ENTRY:
  DI                      ; interrupts off (the loader has done it already)
  JP START                ; to the start

; The town map
;
; A byte a cell, 32 rows of 32: the row is the high byte of V, the column the
; high byte of U. 0 is open ground, 1 and 2 are solid, and 3 up are the cell
; types that are built on (BUILDING_TABLE).
TOWN:
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ; Row 0: 0 open, 0 built
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$00,$14,$00,$03,$01,$01,$01 ; Row 1: 2 open, 2 built
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$00,$00,$00,$03,$01,$01,$01 ; Row 2: 3 open, 1 built
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$00,$03,$18,$14,$01,$01,$01 ; Row 3: 4 open, 9 built
  DEFB $01,$01,$01,$01,$01,$01,$04,$04 ;
  DEFB $04,$04,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$00,$12,$00,$00,$03,$01 ;
  DEFB $01,$00,$00,$00,$00,$12,$00,$04 ; Row 4: 11 open, 8 built
  DEFB $01,$01,$01,$01,$01,$05,$00,$00 ;
  DEFB $00,$00,$23,$01,$01,$05,$23,$05 ;
  DEFB $00,$12,$00,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$08,$00 ; Row 5: 8 open, 7 built
  DEFB $01,$01,$01,$01,$01,$05,$00,$0A ;
  DEFB $0A,$00,$00,$03,$01,$05,$00,$00 ;
  DEFB $00,$12,$00,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$00,$00 ; Row 6: 8 open, 8 built
  DEFB $01,$01,$01,$04,$01,$05,$00,$0A ;
  DEFB $0A,$00,$12,$00,$01,$05,$00,$0A ;
  DEFB $00,$07,$00,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$22,$00,$00,$00 ; Row 7: 18 open, 6 built
  DEFB $00,$00,$00,$00,$00,$12,$00,$00 ;
  DEFB $00,$00,$00,$03,$01,$05,$00,$00 ;
  DEFB $00,$07,$00,$01,$05,$00,$01,$01 ;
  DEFB $01,$01,$01,$05,$00,$00,$00,$03 ; Row 8: 12 open, 15 built
  DEFB $06,$00,$06,$05,$00,$00,$00,$06 ;
  DEFB $06,$04,$00,$03,$01,$14,$08,$06 ;
  DEFB $06,$05,$00,$00,$05,$00,$00,$01 ;
  DEFB $01,$01,$01,$05,$00,$22,$00,$00 ; Row 9: 16 open, 10 built
  DEFB $03,$00,$00,$03,$14,$14,$00,$00 ;
  DEFB $05,$00,$00,$01,$01,$00,$00,$00 ;
  DEFB $00,$00,$00,$14,$14,$00,$03,$01 ;
  DEFB $01,$01,$01,$14,$00,$20,$1D,$00 ; Row 10: 16 open, 12 built
  DEFB $17,$13,$00,$00,$00,$00,$00,$00 ;
  DEFB $03,$00,$11,$0F,$0F,$00,$13,$14 ;
  DEFB $00,$0A,$00,$00,$00,$00,$00,$01 ;
  DEFB $01,$01,$01,$1C,$00,$00,$00,$00 ; Row 11: 15 open, 12 built
  DEFB $17,$17,$19,$17,$11,$09,$11,$00 ;
  DEFB $05,$00,$00,$00,$00,$00,$00,$10 ;
  DEFB $00,$00,$00,$14,$15,$00,$01,$01 ;
  DEFB $01,$01,$15,$00,$00,$13,$16,$16 ; Row 12: 14 open, 12 built
  DEFB $15,$00,$00,$00,$18,$00,$00,$00 ;
  DEFB $12,$00,$1F,$1E,$00,$10,$00,$09 ;
  DEFB $00,$01,$00,$00,$13,$01,$01,$01 ;
  DEFB $01,$01,$01,$16,$00,$14,$00,$00 ; Row 13: 14 open, 8 built
  DEFB $00,$00,$19,$00,$19,$00,$04,$04 ;
  DEFB $04,$00,$00,$00,$00,$0E,$00,$00 ;
  DEFB $00,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$00,$00,$00,$01 ; Row 14: 10 open, 6 built
  DEFB $01,$01,$16,$00,$00,$00,$00,$00 ;
  DEFB $08,$08,$08,$00,$0F,$03,$00,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ; Row 15: 11 open, 7 built
  DEFB $14,$01,$00,$00,$00,$19,$13,$00 ;
  DEFB $00,$00,$00,$00,$0F,$03,$00,$00 ;
  DEFB $00,$01,$01,$01,$15,$23,$01,$01 ;
  DEFB $01,$01,$01,$14,$14,$14,$01,$01 ; Row 16: 9 open, 12 built
  DEFB $00,$17,$00,$16,$18,$18,$00,$00 ;
  DEFB $00,$00,$00,$1B,$0C,$01,$10,$0D ;
  DEFB $00,$01,$01,$01,$02,$00,$13,$01 ;
  DEFB $01,$01,$15,$00,$00,$00,$00,$01 ; Row 17: 17 open, 7 built
  DEFB $01,$15,$00,$14,$00,$00,$00,$01 ;
  DEFB $01,$01,$00,$0D,$00,$1B,$00,$1B ;
  DEFB $00,$00,$03,$00,$00,$00,$00,$01 ;
  DEFB $01,$15,$17,$0F,$0F,$21,$00,$00 ; Row 18: 15 open, 9 built
  DEFB $15,$00,$00,$00,$00,$13,$01,$01 ;
  DEFB $01,$01,$00,$0C,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$01,$0E,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$16,$00 ; Row 19: 8 open, 9 built
  DEFB $00,$00,$0A,$00,$16,$01,$01,$01 ;
  DEFB $0C,$01,$00,$00,$00,$22,$11,$0F ;
  DEFB $11,$23,$00,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$0D,$0F,$23,$0C,$0C,$0D ; Row 20: 14 open, 12 built
  DEFB $21,$00,$00,$00,$0F,$23,$01,$01 ;
  DEFB $00,$00,$00,$06,$00,$09,$00,$00 ;
  DEFB $00,$09,$00,$00,$00,$00,$01,$01 ;
  DEFB $01,$01,$0D,$00,$00,$00,$00,$00 ; Row 21: 13 open, 14 built
  DEFB $03,$00,$1C,$1D,$01,$1C,$0F,$0F ;
  DEFB $0F,$00,$03,$05,$00,$09,$00,$00 ;
  DEFB $00,$09,$00,$0F,$0F,$00,$01,$01 ;
  DEFB $01,$0C,$22,$00,$0D,$0F,$21,$00 ; Row 22: 11 open, 14 built
  DEFB $05,$00,$00,$00,$01,$01,$01,$01 ;
  DEFB $01,$00,$00,$00,$00,$20,$11,$0F ;
  DEFB $11,$21,$00,$1B,$0D,$00,$23,$01 ;
  DEFB $01,$1C,$00,$00,$03,$00,$00,$00 ; Row 23: 18 open, 5 built
  DEFB $05,$00,$22,$00,$01,$01,$01,$00 ;
  DEFB $01,$01,$01,$01,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$10,$01 ;
  DEFB $01,$0D,$00,$10,$05,$00,$0A,$00 ; Row 24: 9 open, 17 built
  DEFB $03,$16,$16,$00,$00,$00,$00,$00 ;
  DEFB $01,$01,$01,$01,$22,$00,$1B,$08 ;
  DEFB $0E,$0C,$0C,$08,$08,$0C,$06,$01 ;
  DEFB $01,$01,$00,$00,$05,$00,$00,$00 ; Row 25: 20 open, 7 built
  DEFB $03,$00,$00,$00,$00,$22,$23,$00 ;
  DEFB $1B,$01,$00,$00,$00,$00,$00,$00 ;
  DEFB $0F,$00,$00,$00,$00,$08,$01,$01 ;
  DEFB $01,$01,$18,$00,$0F,$03,$00,$03 ; Row 26: 11 open, 14 built
  DEFB $05,$00,$08,$00,$00,$20,$21,$00 ;
  DEFB $01,$01,$00,$1E,$1F,$00,$01,$00 ;
  DEFB $0F,$00,$1E,$1F,$00,$08,$01,$01 ;
  DEFB $01,$01,$18,$00,$00,$04,$06,$04 ; Row 27: 14 open, 10 built
  DEFB $00,$00,$08,$01,$00,$00,$00,$00 ;
  DEFB $01,$01,$00,$1C,$1D,$00,$01,$00 ;
  DEFB $0C,$00,$1C,$1D,$00,$00,$01,$01 ;
  DEFB $01,$15,$21,$08,$00,$00,$00,$00 ; Row 28: 15 open, 9 built
  DEFB $00,$08,$06,$01,$01,$00,$1E,$1F ;
  DEFB $01,$01,$00,$00,$00,$00,$01,$00 ;
  DEFB $11,$00,$00,$00,$00,$13,$01,$01 ;
  DEFB $01,$01,$01,$0E,$06,$06,$08,$06 ; Row 29: 3 open, 14 built
  DEFB $06,$00,$01,$01,$01,$00,$1C,$1D ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $0E,$0D,$11,$0F,$0F,$23,$00,$01 ;
  DEFB $01,$01,$01,$01,$01,$05,$00,$03 ; Row 30: 7 open, 3 built
  DEFB $01,$01,$01,$01,$01,$00,$00,$00 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$00,$01,$00,$00,$21,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ; Row 31: 0 open, 0 built
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;
  DEFB $01,$01,$01,$01,$01,$01,$01,$01 ;

; The drawing order
DRAW_ORDER:
  DEFB $40,$80,$60,$00,$50 ; Neighbours 00000: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) the things in it; (+1,+1) the things
                           ; in it
  DEFB $41,$80,$60,$00,$50 ; Neighbours 00001: (-1,+1) its walls (DRAW_WALLS);
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) the things in it; (+1,+1) the things
                           ; in it
  DEFB $40,$81,$60,$00,$50 ; Neighbours 00010: (-1,+1) the things in it;
                           ; (-1,+0) its walls (DRAW_WALLS); (+0,+1) the things
                           ; in it; (-1,-1) the things in it; (+1,+1) the
                           ; things in it
  DEFB $81,$41,$60,$00,$50 ; Neighbours 00011: (-1,+0) its walls (DRAW_WALLS);
                           ; (-1,+1) its walls (DRAW_WALLS); (+0,+1) the things
                           ; in it; (-1,-1) the things in it; (+1,+1) the
                           ; things in it
  DEFB $40,$80,$61,$00,$50 ; Neighbours 00100: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,-1) the things in it; (+1,+1)
                           ; the things in it
  DEFB $61,$41,$80,$00,$50 ; Neighbours 00101: (+0,+1) its walls (DRAW_WALLS);
                           ; (-1,+1) its walls (DRAW_WALLS); (-1,+0) the things
                           ; in it; (-1,-1) the things in it; (+1,+1) the
                           ; things in it
  DEFB $40,$81,$61,$00,$50 ; Neighbours 00110: (-1,+1) the things in it;
                           ; (-1,+0) its walls (DRAW_WALLS); (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,-1) the things in it; (+1,+1)
                           ; the things in it
  DEFB $81,$61,$41,$00,$50 ; Neighbours 00111: (-1,+0) its walls (DRAW_WALLS);
                           ; (+0,+1) its walls (DRAW_WALLS); (-1,+1) its walls
                           ; (DRAW_WALLS); (-1,-1) the things in it; (+1,+1)
                           ; the things in it
  DEFB $40,$80,$60,$01,$50 ; Neighbours 01000: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) its walls (DRAW_WALLS); (+1,+1) the
                           ; things in it
  DEFB $41,$80,$60,$01,$50 ; Neighbours 01001: (-1,+1) its walls (DRAW_WALLS);
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) its walls (DRAW_WALLS); (+1,+1) the
                           ; things in it
  DEFB $40,$01,$81,$60,$50 ; Neighbours 01010: (-1,+1) the things in it;
                           ; (-1,-1) its walls (DRAW_WALLS); (-1,+0) its walls
                           ; (DRAW_WALLS); (+0,+1) the things in it; (+1,+1)
                           ; the things in it
  DEFB $01,$81,$41,$60,$50 ; Neighbours 01011: (-1,-1) its walls (DRAW_WALLS);
                           ; (-1,+0) its walls (DRAW_WALLS); (-1,+1) its walls
                           ; (DRAW_WALLS); (+0,+1) the things in it; (+1,+1)
                           ; the things in it
  DEFB $40,$80,$61,$01,$50 ; Neighbours 01100: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,-1) its walls (DRAW_WALLS);
                           ; (+1,+1) the things in it
  DEFB $61,$41,$80,$01,$50 ; Neighbours 01101: (+0,+1) its walls (DRAW_WALLS);
                           ; (-1,+1) its walls (DRAW_WALLS); (-1,+0) the things
                           ; in it; (-1,-1) its walls (DRAW_WALLS); (+1,+1) the
                           ; things in it
  DEFB $40,$01,$81,$61,$50 ; Neighbours 01110: (-1,+1) the things in it;
                           ; (-1,-1) its walls (DRAW_WALLS); (-1,+0) its walls
                           ; (DRAW_WALLS); (+0,+1) its walls (DRAW_WALLS);
                           ; (+1,+1) the things in it
  DEFB $01,$81,$61,$41,$50 ; Neighbours 01111: (-1,-1) its walls (DRAW_WALLS);
                           ; (-1,+0) its walls (DRAW_WALLS); (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,+1) its walls (DRAW_WALLS);
                           ; (+1,+1) the things in it
  DEFB $40,$80,$60,$00,$51 ; Neighbours 10000: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) the things in it; (+1,+1) its walls
                           ; (DRAW_WALLS)
  DEFB $41,$80,$60,$00,$51 ; Neighbours 10001: (-1,+1) its walls (DRAW_WALLS);
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) the things in it; (+1,+1) its walls
                           ; (DRAW_WALLS)
  DEFB $40,$81,$60,$00,$51 ; Neighbours 10010: (-1,+1) the things in it;
                           ; (-1,+0) its walls (DRAW_WALLS); (+0,+1) the things
                           ; in it; (-1,-1) the things in it; (+1,+1) its walls
                           ; (DRAW_WALLS)
  DEFB $81,$41,$60,$00,$51 ; Neighbours 10011: (-1,+0) its walls (DRAW_WALLS);
                           ; (-1,+1) its walls (DRAW_WALLS); (+0,+1) the things
                           ; in it; (-1,-1) the things in it; (+1,+1) its walls
                           ; (DRAW_WALLS)
  DEFB $40,$80,$51,$61,$00 ; Neighbours 10100: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+1,+1) its walls
                           ; (DRAW_WALLS); (+0,+1) its walls (DRAW_WALLS);
                           ; (-1,-1) the things in it
  DEFB $51,$61,$41,$80,$00 ; Neighbours 10101: (+1,+1) its walls (DRAW_WALLS);
                           ; (+0,+1) its walls (DRAW_WALLS); (-1,+1) its walls
                           ; (DRAW_WALLS); (-1,+0) the things in it; (-1,-1)
                           ; the things in it
  DEFB $40,$51,$61,$81,$00 ; Neighbours 10110: (-1,+1) the things in it;
                           ; (+1,+1) its walls (DRAW_WALLS); (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,+0) its walls (DRAW_WALLS);
                           ; (-1,-1) the things in it
  DEFB $51,$61,$81,$41,$00 ; Neighbours 10111: (+1,+1) its walls (DRAW_WALLS);
                           ; (+0,+1) its walls (DRAW_WALLS); (-1,+0) its walls
                           ; (DRAW_WALLS); (-1,+1) its walls (DRAW_WALLS);
                           ; (-1,-1) the things in it
  DEFB $40,$80,$60,$01,$51 ; Neighbours 11000: (-1,+1) the things in it;
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) its walls (DRAW_WALLS); (+1,+1) its
                           ; walls (DRAW_WALLS)
  DEFB $41,$80,$60,$01,$51 ; Neighbours 11001: (-1,+1) its walls (DRAW_WALLS);
                           ; (-1,+0) the things in it; (+0,+1) the things in
                           ; it; (-1,-1) its walls (DRAW_WALLS); (+1,+1) its
                           ; walls (DRAW_WALLS)
  DEFB $40,$01,$81,$60,$51 ; Neighbours 11010: (-1,+1) the things in it;
                           ; (-1,-1) its walls (DRAW_WALLS); (-1,+0) its walls
                           ; (DRAW_WALLS); (+0,+1) the things in it; (+1,+1)
                           ; its walls (DRAW_WALLS)
  DEFB $01,$81,$41,$60,$51 ; Neighbours 11011: (-1,-1) its walls (DRAW_WALLS);
                           ; (-1,+0) its walls (DRAW_WALLS); (-1,+1) its walls
                           ; (DRAW_WALLS); (+0,+1) the things in it; (+1,+1)
                           ; its walls (DRAW_WALLS)
  DEFB $40,$51,$61,$80,$01 ; Neighbours 11100: (-1,+1) the things in it;
                           ; (+1,+1) its walls (DRAW_WALLS); (+0,+1) its walls
                           ; (DRAW_WALLS); (-1,+0) the things in it; (-1,-1)
                           ; its walls (DRAW_WALLS)
  DEFB $51,$61,$41,$80,$01 ; Neighbours 11101: (+1,+1) its walls (DRAW_WALLS);
                           ; (+0,+1) its walls (DRAW_WALLS); (-1,+1) its walls
                           ; (DRAW_WALLS); (-1,+0) the things in it; (-1,-1)
                           ; its walls (DRAW_WALLS)
  DEFB $40,$01,$81,$51,$61 ; Neighbours 11110: (-1,+1) the things in it;
                           ; (-1,-1) its walls (DRAW_WALLS); (-1,+0) its walls
                           ; (DRAW_WALLS); (+1,+1) its walls (DRAW_WALLS);
                           ; (+0,+1) its walls (DRAW_WALLS)
  DEFB $01,$81,$51,$61,$41 ; Neighbours 11111: (-1,-1) its walls (DRAW_WALLS);
                           ; (-1,+0) its walls (DRAW_WALLS); (+1,+1) its walls
                           ; (DRAW_WALLS); (+0,+1) its walls (DRAW_WALLS);
                           ; (-1,+1) its walls (DRAW_WALLS)

; Building table
BUILDING_TABLE:
  DEFW $0000              ; Cell type 0: nothing to build
  DEFW $0000              ; Cell type 0 turned round: nothing to build
  DEFW BUILDING2          ; Cell type 1
  DEFW BUILDING2          ; Cell type 1 turned round
  DEFW BUILDING4          ; Cell type 2
  DEFW BUILDING4          ; Cell type 2 turned round
  DEFW BUILDING6          ; Cell type 3
  DEFW BUILDING7          ; Cell type 3 turned round
  DEFW BUILDING8          ; Cell type 4
  DEFW BUILDING9          ; Cell type 4 turned round
  DEFW BUILDING10         ; Cell type 5
  DEFW BUILDING11         ; Cell type 5 turned round
  DEFW BUILDING12         ; Cell type 6
  DEFW BUILDING13         ; Cell type 6 turned round
  DEFW BUILDING14         ; Cell type 7
  DEFW BUILDING15         ; Cell type 7 turned round
  DEFW BUILDING16         ; Cell type 8
  DEFW BUILDING16         ; Cell type 8 turned round
  DEFW BUILDING18         ; Cell type 9
  DEFW BUILDING18         ; Cell type 9 turned round
  DEFW BUILDING20         ; Cell type 10
  DEFW BUILDING20         ; Cell type 10 turned round
  DEFW BUILDING22         ; Cell type 11
  DEFW BUILDING23         ; Cell type 11 turned round
  DEFW BUILDING24         ; Cell type 12
  DEFW BUILDING25         ; Cell type 12 turned round
  DEFW BUILDING26         ; Cell type 13
  DEFW BUILDING27         ; Cell type 13 turned round
  DEFW BUILDING28         ; Cell type 14
  DEFW BUILDING29         ; Cell type 14 turned round
  DEFW BUILDING30         ; Cell type 15
  DEFW BUILDING30         ; Cell type 15 turned round
  DEFW BUILDING32         ; Cell type 16
  DEFW BUILDING32         ; Cell type 16 turned round
  DEFW BUILDING34         ; Cell type 17
  DEFW BUILDING34         ; Cell type 17 turned round
  DEFW BUILDING36         ; Cell type 18
  DEFW BUILDING36         ; Cell type 18 turned round
  DEFW BUILDING38         ; Cell type 19
  DEFW BUILDING39         ; Cell type 19 turned round
  DEFW BUILDING40         ; Cell type 20
  DEFW BUILDING41         ; Cell type 20 turned round
  DEFW BUILDING42         ; Cell type 21
  DEFW BUILDING43         ; Cell type 21 turned round
  DEFW BUILDING44         ; Cell type 22
  DEFW BUILDING45         ; Cell type 22 turned round
  DEFW BUILDING46         ; Cell type 23
  DEFW BUILDING46         ; Cell type 23 turned round
  DEFW BUILDING48         ; Cell type 24
  DEFW BUILDING48         ; Cell type 24 turned round
  DEFW BUILDING50         ; Cell type 25
  DEFW BUILDING50         ; Cell type 25 turned round
  DEFW BUILDING52         ; Cell type 26
  DEFW BUILDING53         ; Cell type 26 turned round
  DEFW BUILDING54         ; Cell type 27
  DEFW BUILDING55         ; Cell type 27 turned round
  DEFW BUILDING56         ; Cell type 28
  DEFW BUILDING57         ; Cell type 28 turned round
  DEFW BUILDING58         ; Cell type 29
  DEFW BUILDING59         ; Cell type 29 turned round
  DEFW BUILDING60         ; Cell type 30
  DEFW BUILDING61         ; Cell type 30 turned round
  DEFW BUILDING62         ; Cell type 31
  DEFW BUILDING63         ; Cell type 31 turned round
  DEFW BUILDING64         ; Cell type 32
  DEFW BUILDING65         ; Cell type 32 turned round
  DEFW BUILDING66         ; Cell type 33
  DEFW BUILDING67         ; Cell type 33 turned round
  DEFW BUILDING68         ; Cell type 34
  DEFW BUILDING69         ; Cell type 34 turned round
  DEFW BUILDING70         ; Cell type 35
  DEFW BUILDING71         ; Cell type 35 turned round

; Box table
BOX_TABLE:
  DEFW BOXES0             ; Cell type 0
  DEFW BOXES1             ; Cell type 1
  DEFW BOXES1             ; Cell type 2
  DEFW BOXES3             ; Cell type 3
  DEFW BOXES4             ; Cell type 4
  DEFW BOXES5             ; Cell type 5
  DEFW BOXES6             ; Cell type 6
  DEFW BOXES7             ; Cell type 7
  DEFW BOXES8             ; Cell type 8
  DEFW BOXES9             ; Cell type 9
  DEFW BOXES10            ; Cell type 10
  DEFW BOXES3             ; Cell type 11
  DEFW BOXES4             ; Cell type 12
  DEFW BOXES5             ; Cell type 13
  DEFW BOXES6             ; Cell type 14
  DEFW BOXES7             ; Cell type 15
  DEFW BOXES8             ; Cell type 16
  DEFW BOXES9             ; Cell type 17
  DEFW BOXES18            ; Cell type 18
  DEFW BOXES3             ; Cell type 19
  DEFW BOXES4             ; Cell type 20
  DEFW BOXES5             ; Cell type 21
  DEFW BOXES6             ; Cell type 22
  DEFW BOXES7             ; Cell type 23
  DEFW BOXES8             ; Cell type 24
  DEFW BOXES9             ; Cell type 25
  DEFW BOXES26            ; Cell type 26
  DEFW BOXES27            ; Cell type 27
  DEFW BOXES26            ; Cell type 28
  DEFW BOXES3             ; Cell type 29
  DEFW BOXES30            ; Cell type 30
  DEFW BOXES3             ; Cell type 31
  DEFW BOXES32            ; Cell type 32
  DEFW BOXES33            ; Cell type 33
  DEFW BOXES34            ; Cell type 34
  DEFW BOXES35            ; Cell type 35

; Boxes for cell type 0
;
; 0 boxes.
BOXES0:
  DEFB $00                ; End of the list

; Boxes for cell types 1-2
;
; 4 boxes.
BOXES1:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell types 7, 15, 23
;
; 6 boxes.
BOXES7:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$A8,$02,$18    ; Centre U 66, V 168; half-sizes 2, 24
  DEFB $42,$58,$02,$18    ; Centre U 66, V 88; half-sizes 2, 24
  DEFB $00                ; End of the list

; Boxes for cell types 4, 12, 20
;
; 5 boxes.
BOXES4:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell types 5, 13, 21
;
; 5 boxes.
BOXES5:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell types 6, 14, 22
;
; 5 boxes.
BOXES6:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell types 3, 11, 19, 29, 31
;
; 5 boxes.
BOXES3:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$A8,$02,$18    ; Centre U 66, V 168; half-sizes 2, 24
  DEFB $42,$58,$02,$18    ; Centre U 66, V 88; half-sizes 2, 24
  DEFB $00                ; End of the list

; Boxes for cell types 8, 16, 24
;
; 6 boxes.
BOXES8:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell types 9, 17, 25
;
; 8 boxes.
BOXES9:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$A8,$02,$18    ; Centre U 66, V 168; half-sizes 2, 24
  DEFB $42,$58,$02,$18    ; Centre U 66, V 88; half-sizes 2, 24
  DEFB $00                ; End of the list

; Boxes for cell type 18
;
; 6 boxes.
BOXES18:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$68,$02,$28    ; Centre U 190, V 104; half-sizes 2, 40
  DEFB $BE,$B8,$02,$08    ; Centre U 190, V 184; half-sizes 2, 8
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$98,$02,$28    ; Centre U 66, V 152; half-sizes 2, 40
  DEFB $42,$48,$02,$08    ; Centre U 66, V 72; half-sizes 2, 8
  DEFB $00                ; End of the list

; Boxes for cell type 10
;
; 16 boxes.
BOXES10:
  DEFB $42,$42,$02,$02    ; Centre U 66, V 66; half-sizes 2, 2
  DEFB $60,$42,$04,$02    ; Centre U 96, V 66; half-sizes 4, 2
  DEFB $80,$42,$04,$02    ; Centre U 128, V 66; half-sizes 4, 2
  DEFB $A0,$42,$04,$02    ; Centre U 160, V 66; half-sizes 4, 2
  DEFB $BE,$42,$02,$02    ; Centre U 190, V 66; half-sizes 2, 2
  DEFB $BE,$60,$02,$04    ; Centre U 190, V 96; half-sizes 2, 4
  DEFB $BE,$80,$02,$04    ; Centre U 190, V 128; half-sizes 2, 4
  DEFB $BE,$A0,$02,$04    ; Centre U 190, V 160; half-sizes 2, 4
  DEFB $BE,$BE,$02,$02    ; Centre U 190, V 190; half-sizes 2, 2
  DEFB $A0,$BE,$04,$02    ; Centre U 160, V 190; half-sizes 4, 2
  DEFB $80,$BE,$04,$02    ; Centre U 128, V 190; half-sizes 4, 2
  DEFB $60,$BE,$04,$02    ; Centre U 96, V 190; half-sizes 4, 2
  DEFB $42,$BE,$02,$02    ; Centre U 66, V 190; half-sizes 2, 2
  DEFB $42,$A0,$02,$04    ; Centre U 66, V 160; half-sizes 2, 4
  DEFB $42,$80,$02,$04    ; Centre U 66, V 128; half-sizes 2, 4
  DEFB $42,$60,$02,$04    ; Centre U 66, V 96; half-sizes 2, 4
  DEFB $00                ; End of the list

; Boxes for cell types 26, 28
;
; 6 boxes.
BOXES26:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell type 27
;
; 5 boxes.
BOXES27:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$B8,$02,$08    ; Centre U 66, V 184; half-sizes 2, 8
  DEFB $42,$68,$02,$28    ; Centre U 66, V 104; half-sizes 2, 40
  DEFB $00                ; End of the list

; Boxes for cell type 30
;
; 7 boxes.
BOXES30:
  DEFB $50,$42,$10,$02    ; Centre U 80, V 66; half-sizes 16, 2
  DEFB $A0,$42,$20,$02    ; Centre U 160, V 66; half-sizes 32, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell type 32
;
; 7 boxes.
BOXES32:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $B8,$BE,$08,$02    ; Centre U 184, V 190; half-sizes 8, 2
  DEFB $68,$BE,$28,$02    ; Centre U 104, V 190; half-sizes 40, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell type 33
;
; 6 boxes.
BOXES33:
  DEFB $58,$42,$18,$02    ; Centre U 88, V 66; half-sizes 24, 2
  DEFB $A8,$42,$18,$02    ; Centre U 168, V 66; half-sizes 24, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $80,$BE,$40,$02    ; Centre U 128, V 190; half-sizes 64, 2
  DEFB $42,$A8,$02,$18    ; Centre U 66, V 168; half-sizes 2, 24
  DEFB $42,$58,$02,$18    ; Centre U 66, V 88; half-sizes 2, 24
  DEFB $00                ; End of the list

; Boxes for cell type 34
;
; 6 boxes.
BOXES34:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$58,$02,$18    ; Centre U 190, V 88; half-sizes 2, 24
  DEFB $BE,$A8,$02,$18    ; Centre U 190, V 168; half-sizes 2, 24
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$80,$02,$40    ; Centre U 66, V 128; half-sizes 2, 64
  DEFB $00                ; End of the list

; Boxes for cell type 35
;
; 6 boxes.
BOXES35:
  DEFB $80,$42,$40,$02    ; Centre U 128, V 66; half-sizes 64, 2
  DEFB $BE,$80,$02,$40    ; Centre U 190, V 128; half-sizes 2, 64
  DEFB $A8,$BE,$18,$02    ; Centre U 168, V 190; half-sizes 24, 2
  DEFB $58,$BE,$18,$02    ; Centre U 88, V 190; half-sizes 24, 2
  DEFB $42,$A8,$02,$18    ; Centre U 66, V 168; half-sizes 2, 24
  DEFB $42,$58,$02,$18    ; Centre U 66, V 88; half-sizes 2, 24
  DEFB $00                ; End of the list

; The edge picture under each tile
TILE_EDGES:
  DEFB $00                ; Tile 0: 0
  DEFB $00                ; Tile 1: 0
  DEFB $00                ; Tile 2: 0
  DEFB $00                ; Tile 3: 0
  DEFB $00                ; Tile 4: 0
  DEFB $02                ; Tile 5: 2
  DEFB $03                ; Tile 6: 3
  DEFB $02                ; Tile 7: 2
  DEFB $03                ; Tile 8: 3
  DEFB $00                ; Tile 9: 0
  DEFB $00                ; Tile 10: 0
  DEFB $00                ; Tile 11: 0
  DEFB $00                ; Tile 12: 0
  DEFB $00                ; Tile 13: 0
  DEFB $00                ; Tile 14: 0
  DEFB $00                ; Tile 15: 0
  DEFB $00                ; Tile 16: 0
  DEFB $00                ; Tile 17: 0
  DEFB $00                ; Tile 18: 0
  DEFB $00                ; Tile 19: 0
  DEFB $00                ; Tile 20: 0
  DEFB $00                ; Tile 21: 0
  DEFB $00                ; Tile 22: 0
  DEFB $00                ; Tile 23: 0
  DEFB $00                ; Tile 24: 0
  DEFB $00                ; Tile 25: 0
  DEFB $00                ; Tile 26: 0
  DEFB $00                ; Tile 27: 0
  DEFB $00                ; Tile 28: 0
  DEFB $00                ; Tile 29: 0
  DEFB $00                ; Tile 30: 0
  DEFB $00                ; Tile 31: 0
  DEFB $00                ; Tile 32: 0
  DEFB $00                ; Tile 33: 0
  DEFB $00                ; Tile 34: 0
  DEFB $00                ; Tile 35: 0
  DEFB $00                ; Tile 36: 0
  DEFB $00                ; Tile 37: 0
  DEFB $00                ; Tile 38: 0
  DEFB $00                ; Tile 39: 0
  DEFB $00                ; Tile 40: 0
  DEFB $00                ; Tile 41: 0
  DEFB $00                ; Tile 42: 0
  DEFB $00                ; Tile 43: 0
  DEFB $00                ; Tile 44: 0
  DEFB $00                ; Tile 45: 0
  DEFB $00                ; Tile 46: 0
  DEFB $00                ; Tile 47: 0
  DEFB $00                ; Tile 48: 0
  DEFB $00                ; Tile 49: 0
  DEFB $02                ; Tile 50: 2
  DEFB $03                ; Tile 51: 3

; Building for cell type 7
BUILDING14:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 15/1 16/1 46/1
  DEFB $0F,$01            ; 46/1 15/1 16/1 45/0
  DEFB $10,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $0F,$01            ;
  DEFB $10,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 16/34 15/33
  DEFB $10,$22            ; 8/1 7/1 16/34 15/33 49/4
  DEFB $0F,$21            ;
  DEFB $08,$01            ;
  DEFB $07,$01            ;
  DEFB $10,$22            ;
  DEFB $0F,$21            ;
  DEFB $31,$04            ;

; Building for cell type 7 turned round
BUILDING15:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 15/1 16/1 46/1
  DEFB $0F,$01            ; 46/1 15/1 16/1 45/0
  DEFB $10,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $0F,$01            ;
  DEFB $10,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 16/1 15/1 8/1
  DEFB $10,$01            ; 7/34 16/33 15/1 49/4
  DEFB $0F,$01            ;
  DEFB $08,$01            ;
  DEFB $07,$22            ;
  DEFB $10,$21            ;
  DEFB $0F,$01            ;
  DEFB $31,$04            ;

; Building for cell type 11
BUILDING22:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 43/31 44/35
  DEFB $2B,$1F            ; 18/36 19/35 18/36 19/31 12/37
  DEFB $2C,$23            ;
  DEFB $12,$24            ;
  DEFB $13,$23            ;
  DEFB $12,$24            ;
  DEFB $13,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 44/31 43/36
  DEFB $2C,$1F            ; 44/35 43/36 44/35 43/31 20/38
  DEFB $2B,$24            ;
  DEFB $2C,$23            ;
  DEFB $2B,$24            ;
  DEFB $2C,$23            ;
  DEFB $2B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 11 turned round
BUILDING23:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 9/31 10/35
  DEFB $09,$1F            ; 43/36 44/35 9/36 10/31 12/37
  DEFB $0A,$23            ;
  DEFB $2B,$24            ;
  DEFB $2C,$23            ;
  DEFB $09,$24            ;
  DEFB $0A,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 44/31 43/36
  DEFB $2C,$1F            ; 6/35 5/36 44/35 43/31 20/38
  DEFB $2B,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $2C,$23            ;
  DEFB $2B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 35
BUILDING70:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 13/31 14/31
  DEFB $0D,$1F            ; 13/41 14/41 17/31 17/31 12/37
  DEFB $0E,$1F            ;
  DEFB $0D,$29            ;
  DEFB $0E,$29            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 11/31 11/31
  DEFB $0B,$1F            ; 17/41 17/41 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $11,$29            ;
  DEFB $11,$29            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 35 turned round
BUILDING71:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 5/31 6/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 17/31 17/31
  DEFB $11,$1F            ; 6/31 5/31 17/31 17/31 11/31
  DEFB $11,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 34
BUILDING68:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 13/31 14/31
  DEFB $0D,$1F            ; 13/41 14/41 17/31 17/31 11/31
  DEFB $0E,$1F            ;
  DEFB $0D,$29            ;
  DEFB $0E,$29            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 6/31 5/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 34 turned round
BUILDING69:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 5/31 6/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 14/41 13/41
  DEFB $0E,$29            ; 17/31 17/31 14/31 13/31 20/38
  DEFB $0D,$29            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0E,$1F            ;
  DEFB $0D,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 33
BUILDING66:
  DEFB $0B,$26            ; First face, tiles ground/upper: 11/38 11/41 17/41
  DEFB $0B,$29            ; 5/31 6/31 17/41 11/41 11/31
  DEFB $11,$29            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $11,$29            ;
  DEFB $0B,$29            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 14/41 13/41
  DEFB $0E,$29            ; 14/31 13/31 17/31 17/31 20/38
  DEFB $0D,$29            ;
  DEFB $0E,$1F            ;
  DEFB $0D,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 33 turned round
BUILDING67:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 17/31 17/41
  DEFB $11,$1F            ; 17/41 17/41 17/41 17/31 11/31
  DEFB $11,$29            ;
  DEFB $11,$29            ;
  DEFB $11,$29            ;
  DEFB $11,$29            ;
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 11/31 17/41
  DEFB $0B,$1F            ; 6/31 5/41 17/31 11/41 11/38
  DEFB $11,$29            ;
  DEFB $06,$1F            ;
  DEFB $05,$29            ;
  DEFB $11,$1F            ;
  DEFB $0B,$29            ;
  DEFB $0B,$26            ;

; Building for cell type 32
BUILDING64:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 5/31 6/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ; Second face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 6/31 5/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 32 turned round
BUILDING65:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 5/31 6/31
  DEFB $05,$1F            ; 11/31 17/31 17/31 17/31 12/37
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 14/31 13/31
  DEFB $0E,$1F            ; 14/31 13/31 14/31 13/31 11/31
  DEFB $0D,$1F            ;
  DEFB $0E,$1F            ;
  DEFB $0D,$1F            ;
  DEFB $0E,$1F            ;
  DEFB $0D,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 31
BUILDING62:
  DEFB $11,$1F            ; First face, tiles ground/upper: 17/31 17/31 17/31
  DEFB $11,$1F            ; 17/31 11/31 17/31 17/31 12/37
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 17/31
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;

; Building for cell type 31 turned round
BUILDING63:
  DEFB $0B,$1F            ; First face, tiles ground/upper: 11/31 11/31 11/31
  DEFB $0B,$1F            ; 11/31 11/31 11/31 11/31 11/37
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$25            ;
  DEFB $0B,$25            ; Second face, tiles ground/upper: 11/37 11/31 11/31
  DEFB $0B,$1F            ; 6/31 5/31 11/31 11/31 11/31
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;

; Building for cell type 30
BUILDING60:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 17/31 5/31
  DEFB $11,$1F            ; 6/31 17/31 17/31 17/31 17/31
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ; Second face, tiles ground/upper: 17/31 11/31 11/31
  DEFB $0B,$1F            ; 6/31 5/31 11/31 11/31 20/38
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 30 turned round
BUILDING61:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 11/31 11/31
  DEFB $0B,$1F            ; 5/31 6/31 11/31 11/31 17/31
  DEFB $0B,$1F            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ; Second face, tiles ground/upper: 17/31 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 20/38
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 29
BUILDING58:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 11/31 17/31
  DEFB $0B,$1F            ; 11/31 17/31 11/31 17/31 17/31
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ; Second face, tiles ground/upper: 17/31 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 17/38
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$26            ;

; Building for cell type 29 turned round
BUILDING59:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 17/31
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ; Second face, tiles ground/upper: 17/31 17/31 11/31
  DEFB $11,$1F            ; 6/31 5/31 11/31 17/31 20/38
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 28
BUILDING56:
  DEFB $11,$1F            ; First face, tiles ground/upper: 17/31 11/31 11/31
  DEFB $0B,$1F            ; 5/31 6/31 11/31 11/31 11/37
  DEFB $0B,$1F            ;
  DEFB $05,$1F            ;
  DEFB $06,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$25            ;
  DEFB $0B,$25            ; Second face, tiles ground/upper: 11/37 11/31 11/31
  DEFB $0B,$1F            ; 6/31 5/31 11/31 11/31 17/31
  DEFB $0B,$1F            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $11,$1F            ;

; Building for cell type 28 turned round
BUILDING57:
  DEFB $11,$1F            ; First face, tiles ground/upper: 17/31 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 12/37
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 17/31 17/31
  DEFB $11,$1F            ; 17/31 17/31 17/31 17/31 17/31
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;
  DEFB $11,$1F            ;

; Building for cell type 4
BUILDING8:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 46/1 46/1 46/1
  DEFB $2E,$01            ; 46/1 46/1 46/1 45/0
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/1 46/1
  DEFB $2E,$01            ; 46/1 46/1 46/1 46/1 49/4
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $31,$04            ;

; Building for cell type 4 turned round
BUILDING9:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 47/33 48/34
  DEFB $2F,$21            ; 7/33 8/34 47/33 48/34 45/0
  DEFB $30,$22            ;
  DEFB $07,$21            ;
  DEFB $08,$22            ;
  DEFB $2F,$21            ;
  DEFB $30,$22            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/1 46/1
  DEFB $2E,$01            ; 46/1 46/1 46/1 46/1 49/4
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $31,$04            ;

; Building for cell type 5
BUILDING10:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 15/1 16/1 46/1
  DEFB $0F,$01            ; 46/1 15/1 16/1 45/0
  DEFB $10,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $0F,$01            ;
  DEFB $10,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 16/34 15/33
  DEFB $10,$22            ; 8/1 7/1 16/34 15/33 49/4
  DEFB $0F,$21            ;
  DEFB $08,$01            ;
  DEFB $07,$01            ;
  DEFB $10,$22            ;
  DEFB $0F,$21            ;
  DEFB $31,$04            ;

; Building for cell type 5 turned round
BUILDING11:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 15/1 16/1 46/1
  DEFB $0F,$01            ; 46/1 15/1 16/1 45/0
  DEFB $10,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $0F,$01            ;
  DEFB $10,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 16/1 15/1
  DEFB $10,$01            ; 46/1 46/1 16/1 15/1 49/4
  DEFB $0F,$01            ;
  DEFB $2E,$01            ;
  DEFB $2E,$01            ;
  DEFB $10,$01            ;
  DEFB $0F,$01            ;
  DEFB $31,$04            ;

; Building for cell type 6
BUILDING12:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 47/3 48/2 7/3
  DEFB $2F,$03            ; 8/2 47/3 48/2 45/0
  DEFB $30,$02            ;
  DEFB $07,$03            ;
  DEFB $08,$02            ;
  DEFB $2F,$03            ;
  DEFB $30,$02            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/2 46/3
  DEFB $2E,$02            ; 19/2 18/3 46/2 46/3 49/4
  DEFB $2E,$03            ;
  DEFB $13,$02            ;
  DEFB $12,$03            ;
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $31,$04            ;

; Building for cell type 6 turned round
BUILDING13:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 46/3 46/2 46/3
  DEFB $2E,$03            ; 46/2 46/3 46/2 45/0
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $2E,$02            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/2 46/3
  DEFB $2E,$02            ; 19/2 18/3 46/2 46/3 49/4
  DEFB $2E,$03            ;
  DEFB $13,$02            ;
  DEFB $12,$03            ;
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $31,$04            ;

; Building for cell type 3
BUILDING6:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 47/1 48/1 47/3
  DEFB $2F,$01            ; 48/2 47/1 48/1 45/0
  DEFB $30,$01            ;
  DEFB $2F,$03            ;
  DEFB $30,$02            ;
  DEFB $2F,$01            ;
  DEFB $30,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 48/1 47/1
  DEFB $30,$01            ; 46/2 46/3 48/1 47/1 49/4
  DEFB $2F,$01            ;
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $30,$01            ;
  DEFB $2F,$01            ;
  DEFB $31,$04            ;

; Building for cell type 3 turned round
BUILDING7:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 47/1 48/1 46/3
  DEFB $2F,$01            ; 46/2 47/1 48/1 45/0
  DEFB $30,$01            ;
  DEFB $2E,$03            ;
  DEFB $2E,$02            ;
  DEFB $2F,$01            ;
  DEFB $30,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 16/0 15/2 8/3
  DEFB $10,$00            ; 7/2 16/3 15/1 49/4
  DEFB $0F,$02            ;
  DEFB $08,$03            ;
  DEFB $07,$02            ;
  DEFB $10,$03            ;
  DEFB $0F,$01            ;
  DEFB $31,$04            ;

; Building for cell type 8, type 8 turned round
BUILDING16:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 15/1 16/1 5/33
  DEFB $0F,$01            ; 6/34 15/1 16/1 45/0
  DEFB $10,$01            ;
  DEFB $05,$21            ;
  DEFB $06,$22            ;
  DEFB $0F,$01            ;
  DEFB $10,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 47/1 48/1
  DEFB $2F,$01            ; 46/34 46/33 47/1 48/1 49/4
  DEFB $30,$01            ;
  DEFB $2E,$22            ;
  DEFB $2E,$21            ;
  DEFB $2F,$01            ;
  DEFB $30,$01            ;
  DEFB $31,$04            ;

; Building for cell type 18, type 18 turned round
BUILDING36:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 46/1 47/1 48/1
  DEFB $2E,$01            ; 47/33 48/34 46/1 45/0
  DEFB $2F,$01            ;
  DEFB $30,$01            ;
  DEFB $2F,$21            ;
  DEFB $30,$22            ;
  DEFB $2E,$01            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/1 16/1
  DEFB $2E,$01            ; 15/34 46/33 8/1 7/1 49/4
  DEFB $10,$01            ;
  DEFB $0F,$22            ;
  DEFB $2E,$21            ;
  DEFB $08,$01            ;
  DEFB $07,$01            ;
  DEFB $31,$04            ;

; Building for cell type 10, type 10 turned round
BUILDING20:
  DEFB $05,$26            ; First face, tiles ground/upper: 5/38 6/35 5/36 6/35
  DEFB $06,$23            ; 5/36 6/35 5/36 6/37
  DEFB $05,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $06,$25            ;
  DEFB $06,$25            ; Second face, tiles ground/upper: 6/37 5/36 6/35
  DEFB $05,$24            ; 5/36 6/35 5/36 6/35 5/38
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$26            ;

; Building for cell type 26
BUILDING52:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/3 26/2 5/1
  DEFB $1A,$03            ; 6/1 26/3 26/2 23/0
  DEFB $1A,$02            ;
  DEFB $05,$01            ;
  DEFB $06,$01            ;
  DEFB $1A,$03            ;
  DEFB $1A,$02            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/1 27/1 6/2
  DEFB $1B,$01            ; 5/3 27/1 27/1 25/4
  DEFB $1B,$01            ;
  DEFB $06,$02            ;
  DEFB $05,$03            ;
  DEFB $1B,$01            ;
  DEFB $1B,$01            ;
  DEFB $19,$04            ;

; Building for cell type 26 turned round
BUILDING53:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 29/3 30/2 26/1
  DEFB $1D,$03            ; 26/1 29/3 30/2 23/0
  DEFB $1E,$02            ;
  DEFB $1A,$01            ;
  DEFB $1A,$01            ;
  DEFB $1D,$03            ;
  DEFB $1E,$02            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/1 27/1
  DEFB $1B,$01            ; 24/2 27/3 27/1 27/1 25/4
  DEFB $1B,$01            ;
  DEFB $18,$02            ;
  DEFB $1B,$03            ;
  DEFB $1B,$01            ;
  DEFB $1B,$01            ;
  DEFB $19,$04            ;

; Building for cell type 2, type 2 turned round
BUILDING4:
  DEFB $14,$04            ; First face, tiles ground/upper: 20/4 18/1 19/3 18/2
  DEFB $12,$01            ; 19/3 18/2 19/1 12/0
  DEFB $13,$03            ;
  DEFB $12,$02            ;
  DEFB $13,$03            ;
  DEFB $12,$02            ;
  DEFB $13,$01            ;
  DEFB $0C,$00            ;
  DEFB $0C,$00            ; Second face, tiles ground/upper: 12/0 19/1 18/2
  DEFB $13,$01            ; 19/3 18/2 19/3 18/1 20/4
  DEFB $12,$02            ;
  DEFB $13,$03            ;
  DEFB $12,$02            ;
  DEFB $13,$03            ;
  DEFB $12,$01            ;
  DEFB $14,$04            ;

; Building for cell type 1, type 1 turned round
BUILDING2:
  DEFB $15,$16            ; First face, tiles ground/upper: 21/22 21/22 21/22
  DEFB $15,$16            ; 21/22 21/22 21/22 21/22 21/22
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ; Second face, tiles ground/upper: 21/22 21/22 21/22
  DEFB $15,$16            ; 21/22 21/22 21/22 21/22 21/22
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;
  DEFB $15,$16            ;

; Building for cell type 15, type 15 turned round
BUILDING30:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 11/31 11/31
  DEFB $0B,$1F            ; 18/31 19/31 11/31 11/31 12/37
  DEFB $0B,$1F            ;
  DEFB $12,$1F            ;
  DEFB $13,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 14/40 13/39
  DEFB $0E,$28            ; 6/31 5/31 14/40 13/39 20/38
  DEFB $0D,$27            ;
  DEFB $06,$1F            ;
  DEFB $05,$1F            ;
  DEFB $0E,$28            ;
  DEFB $0D,$27            ;
  DEFB $14,$26            ;

; Building for cell type 12
BUILDING24:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 43/39 44/40
  DEFB $2B,$27            ; 18/31 19/31 43/39 44/40 12/37
  DEFB $2C,$28            ;
  DEFB $12,$1F            ;
  DEFB $13,$1F            ;
  DEFB $2B,$27            ;
  DEFB $2C,$28            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 44/40 43/39
  DEFB $2C,$28            ; 19/31 18/31 44/40 43/39 20/38
  DEFB $2B,$27            ;
  DEFB $13,$1F            ;
  DEFB $12,$1F            ;
  DEFB $2C,$28            ;
  DEFB $2B,$27            ;
  DEFB $14,$26            ;

; Building for cell type 12 turned round
BUILDING25:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 43/39 44/40
  DEFB $2B,$27            ; 5/39 6/40 43/39 44/40 12/37
  DEFB $2C,$28            ;
  DEFB $05,$27            ;
  DEFB $06,$28            ;
  DEFB $2B,$27            ;
  DEFB $2C,$28            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 44/40 43/39
  DEFB $2C,$28            ; 19/31 18/31 44/40 43/39 20/38
  DEFB $2B,$27            ;
  DEFB $13,$1F            ;
  DEFB $12,$1F            ;
  DEFB $2C,$28            ;
  DEFB $2B,$27            ;
  DEFB $14,$26            ;

; Building for cell type 13
BUILDING26:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 43/31 44/35
  DEFB $2B,$1F            ; 18/36 19/35 18/36 19/31 12/37
  DEFB $2C,$23            ;
  DEFB $12,$24            ;
  DEFB $13,$23            ;
  DEFB $12,$24            ;
  DEFB $13,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 44/31 43/36
  DEFB $2C,$1F            ; 6/35 5/36 44/35 43/31 20/38
  DEFB $2B,$24            ;
  DEFB $06,$23            ;
  DEFB $05,$24            ;
  DEFB $2C,$23            ;
  DEFB $2B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 13 turned round
BUILDING27:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 9/31 10/35
  DEFB $09,$1F            ; 43/36 44/37 9/36 10/31 12/37
  DEFB $0A,$23            ;
  DEFB $2B,$24            ;
  DEFB $2C,$25            ;
  DEFB $09,$24            ;
  DEFB $0A,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 10/31 9/36
  DEFB $0A,$1F            ; 19/35 18/36 10/35 9/31 20/38
  DEFB $09,$24            ;
  DEFB $13,$23            ;
  DEFB $12,$24            ;
  DEFB $0A,$23            ;
  DEFB $09,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 14
BUILDING28:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 32/35 11/36
  DEFB $20,$23            ; 7/31 8/31 11/35 32/36 12/37
  DEFB $0B,$24            ;
  DEFB $07,$1F            ;
  DEFB $08,$1F            ;
  DEFB $0B,$23            ;
  DEFB $20,$24            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 32/36 11/35
  DEFB $20,$24            ; 32/31 11/31 32/31 11/31 20/38
  DEFB $0B,$23            ;
  DEFB $20,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $20,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 14 turned round
BUILDING29:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 32/31 11/35
  DEFB $20,$1F            ; 11/36 11/31 11/31 32/31 12/37
  DEFB $0B,$23            ;
  DEFB $0B,$24            ;
  DEFB $0B,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $20,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 32/31 19/36
  DEFB $20,$1F            ; 18/35 11/36 11/35 32/31 20/38
  DEFB $13,$24            ;
  DEFB $12,$23            ;
  DEFB $0B,$24            ;
  DEFB $0B,$23            ;
  DEFB $20,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 27
BUILDING54:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 11/31 32/35
  DEFB $0B,$1F            ; 11/36 32/35 43/36 44/31 12/37
  DEFB $20,$23            ;
  DEFB $0B,$24            ;
  DEFB $20,$23            ;
  DEFB $2B,$24            ;
  DEFB $2C,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 11/31 44/31
  DEFB $0B,$1F            ; 43/36 11/35 32/31 11/31 20/38
  DEFB $2C,$1F            ;
  DEFB $2B,$24            ;
  DEFB $0B,$23            ;
  DEFB $20,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 27 turned round
BUILDING55:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 32/31 43/31
  DEFB $20,$1F            ; 44/35 43/36 44/31 11/31 12/37
  DEFB $2B,$1F            ;
  DEFB $2C,$23            ;
  DEFB $2B,$24            ;
  DEFB $2C,$1F            ;
  DEFB $0B,$1F            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 6/36 5/35
  DEFB $06,$24            ; 11/31 32/36 11/35 32/31 20/38
  DEFB $05,$23            ;
  DEFB $0B,$1F            ;
  DEFB $20,$24            ;
  DEFB $0B,$23            ;
  DEFB $20,$1F            ;
  DEFB $14,$26            ;

; Building for cell type 16, type 16 turned round
BUILDING32:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 17/39 17/40
  DEFB $11,$27            ; 5/39 6/40 43/39 44/40 12/37
  DEFB $11,$28            ;
  DEFB $05,$27            ;
  DEFB $06,$28            ;
  DEFB $2B,$27            ;
  DEFB $2C,$28            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 11/40 17/39
  DEFB $0B,$28            ; 11/40 17/39 11/40 17/39 20/38
  DEFB $11,$27            ;
  DEFB $0B,$28            ;
  DEFB $11,$27            ;
  DEFB $0B,$28            ;
  DEFB $11,$27            ;
  DEFB $14,$26            ;

; Building for cell type 17, type 17 turned round
BUILDING34:
  DEFB $14,$26            ; First face, tiles ground/upper: 20/38 18/41 19/41
  DEFB $12,$29            ; 5/41 6/41 18/41 19/41 12/37
  DEFB $13,$29            ;
  DEFB $05,$29            ;
  DEFB $06,$29            ;
  DEFB $12,$29            ;
  DEFB $13,$29            ;
  DEFB $0C,$25            ;
  DEFB $0C,$25            ; Second face, tiles ground/upper: 12/37 19/41 18/41
  DEFB $13,$29            ; 6/41 5/41 19/41 18/41 20/38
  DEFB $12,$29            ;
  DEFB $06,$29            ;
  DEFB $05,$29            ;
  DEFB $13,$29            ;
  DEFB $12,$29            ;
  DEFB $14,$26            ;

; Building for cell type 9, type 9 turned round
BUILDING18:
  DEFB $31,$04            ; First face, tiles ground/upper: 49/4 47/33 48/34
  DEFB $2F,$21            ; 7/33 8/34 47/33 48/34 45/0
  DEFB $30,$22            ;
  DEFB $07,$21            ;
  DEFB $08,$22            ;
  DEFB $2F,$21            ;
  DEFB $30,$22            ;
  DEFB $2D,$00            ;
  DEFB $2D,$00            ; Second face, tiles ground/upper: 45/0 46/2 46/3 8/1
  DEFB $2E,$02            ; 7/1 46/2 46/3 49/4
  DEFB $2E,$03            ;
  DEFB $08,$01            ;
  DEFB $07,$01            ;
  DEFB $2E,$02            ;
  DEFB $2E,$03            ;
  DEFB $31,$04            ;

; Building for cell type 20
BUILDING40:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/3 26/2 29/3
  DEFB $1A,$03            ; 30/2 29/3 30/2 23/0
  DEFB $1A,$02            ;
  DEFB $1D,$03            ;
  DEFB $1E,$02            ;
  DEFB $1D,$03            ;
  DEFB $1E,$02            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 26/34 26/33
  DEFB $1A,$22            ; 30/34 29/33 26/34 26/33 25/4
  DEFB $1A,$21            ;
  DEFB $1E,$22            ;
  DEFB $1D,$21            ;
  DEFB $1A,$22            ;
  DEFB $1A,$21            ;
  DEFB $19,$04            ;

; Building for cell type 20 turned round
BUILDING41:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 29/1 30/1 50/3
  DEFB $1D,$01            ; 51/2 29/1 30/1 23/0
  DEFB $1E,$01            ;
  DEFB $32,$03            ;
  DEFB $33,$02            ;
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 30/1 29/1
  DEFB $1E,$01            ; 19/34 18/33 19/1 18/1 25/4
  DEFB $1D,$01            ;
  DEFB $13,$22            ;
  DEFB $12,$21            ;
  DEFB $13,$01            ;
  DEFB $12,$01            ;
  DEFB $19,$04            ;

; Building for cell type 19
BUILDING38:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/33 26/34
  DEFB $1A,$21            ; 29/1 30/1 26/33 26/34 23/0
  DEFB $1A,$22            ;
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $1A,$21            ;
  DEFB $1A,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/34 27/33
  DEFB $1B,$22            ; 30/1 29/1 27/34 27/33 25/4
  DEFB $1B,$21            ;
  DEFB $1E,$01            ;
  DEFB $1D,$01            ;
  DEFB $1B,$22            ;
  DEFB $1B,$21            ;
  DEFB $19,$04            ;

; Building for cell type 19 turned round
BUILDING39:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 29/33 30/34
  DEFB $1D,$21            ; 26/1 26/1 29/33 30/34 23/0
  DEFB $1E,$22            ;
  DEFB $1A,$01            ;
  DEFB $1A,$01            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 30/34 29/33
  DEFB $1E,$22            ; 51/1 50/1 30/34 29/33 25/4
  DEFB $1D,$21            ;
  DEFB $33,$01            ;
  DEFB $32,$01            ;
  DEFB $1E,$22            ;
  DEFB $1D,$21            ;
  DEFB $19,$04            ;

; Building for cell type 22
BUILDING44:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/33 26/34
  DEFB $1A,$21            ; 50/33 51/34 29/33 30/34 23/0
  DEFB $1A,$22            ;
  DEFB $32,$21            ;
  DEFB $33,$22            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/34 27/33
  DEFB $1B,$22            ; 27/34 27/33 27/34 27/33 25/4
  DEFB $1B,$21            ;
  DEFB $1B,$22            ;
  DEFB $1B,$21            ;
  DEFB $1B,$22            ;
  DEFB $1B,$21            ;
  DEFB $19,$04            ;

; Building for cell type 22 turned round
BUILDING45:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/33 26/34
  DEFB $1A,$21            ; 26/33 29/34 30/33 26/34 23/0
  DEFB $1A,$22            ;
  DEFB $1A,$21            ;
  DEFB $1D,$22            ;
  DEFB $1E,$21            ;
  DEFB $1A,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 30/34 29/33
  DEFB $1E,$22            ; 30/34 29/33 30/34 29/33 25/4
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $1D,$21            ;
  DEFB $19,$04            ;

; Building for cell type 21
BUILDING42:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 29/33 30/34
  DEFB $1D,$21            ; 29/1 30/1 29/33 30/34 23/0
  DEFB $1E,$22            ;
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 30/1 29/34
  DEFB $1E,$01            ; 51/33 50/34 30/33 29/1 25/4
  DEFB $1D,$22            ;
  DEFB $33,$21            ;
  DEFB $32,$22            ;
  DEFB $1E,$21            ;
  DEFB $1D,$01            ;
  DEFB $19,$04            ;

; Building for cell type 21 turned round
BUILDING43:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/1 26/1
  DEFB $1A,$01            ; 29/33 30/34 26/33 26/34 23/0
  DEFB $1A,$01            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $1A,$21            ;
  DEFB $1A,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/1 30/1
  DEFB $1B,$01            ; 29/1 30/1 29/1 27/1 25/4
  DEFB $1E,$01            ;
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $1D,$01            ;
  DEFB $1B,$01            ;
  DEFB $19,$04            ;

; Building for cell type 25, type 25 turned round
BUILDING50:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 29/33 30/34
  DEFB $1D,$21            ; 50/1 51/1 29/33 30/34 23/0
  DEFB $1E,$22            ;
  DEFB $32,$01            ;
  DEFB $33,$01            ;
  DEFB $1D,$21            ;
  DEFB $1E,$22            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 30/34 29/33
  DEFB $1E,$22            ; 51/1 50/1 26/34 26/33 25/4
  DEFB $1D,$21            ;
  DEFB $33,$01            ;
  DEFB $32,$01            ;
  DEFB $1A,$22            ;
  DEFB $1A,$21            ;
  DEFB $19,$04            ;

; Building for cell type 24, type 24 turned round
BUILDING48:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/33 26/34
  DEFB $1A,$21            ; 50/1 51/33 26/34 26/1 23/0
  DEFB $1A,$22            ;
  DEFB $32,$01            ;
  DEFB $33,$21            ;
  DEFB $1A,$22            ;
  DEFB $1A,$01            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/34 30/33
  DEFB $1B,$22            ; 29/34 30/33 29/34 27/33 25/4
  DEFB $1E,$21            ;
  DEFB $1D,$22            ;
  DEFB $1E,$21            ;
  DEFB $1D,$22            ;
  DEFB $1B,$21            ;
  DEFB $19,$04            ;

; Building for cell type 23, type 23 turned round
BUILDING46:
  DEFB $1C,$04            ; First face, tiles ground/upper: 28/4 26/1 29/1 30/1
  DEFB $1A,$01            ; 29/1 30/1 26/1 23/0
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $1D,$01            ;
  DEFB $1E,$01            ;
  DEFB $1A,$01            ;
  DEFB $17,$00            ;
  DEFB $18,$00            ; Second face, tiles ground/upper: 24/0 27/1 27/1
  DEFB $1B,$01            ; 51/1 50/1 27/1 27/1 25/4
  DEFB $1B,$01            ;
  DEFB $33,$01            ;
  DEFB $32,$01            ;
  DEFB $1B,$01            ;
  DEFB $1B,$01            ;
  DEFB $19,$04            ;

; The panel's frame
PANEL_CHARS:
  DEFB $00                ; Character 0
  DEFB $18                ;
  DEFB $3C                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ; Character 1
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ;
  DEFB $66                ; Character 2
  DEFB $63                ;
  DEFB $31                ;
  DEFB $38                ;
  DEFB $1C                ;
  DEFB $0F                ;
  DEFB $03                ;
  DEFB $00                ;
  DEFB $00                ; Character 3
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $00                ;
  DEFB $66                ; Character 4
  DEFB $C6                ;
  DEFB $8C                ;
  DEFB $1C                ;
  DEFB $38                ;
  DEFB $F0                ;
  DEFB $C0                ;
  DEFB $00                ;

; The font
;
; The printer finds a character at a base plus eight times its code, and the
; base it is given for this font lies $30 characters below it, so these are
; codes $30-$5A. It prints the semicolon's code as the copyright sign, the
; colon's as a full stop, and a space as the character code $3C.
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
  DEFB $7C                ;
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
  DEFB $30                ;
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
  DEFB $18                ;
  DEFB $18                ;
  DEFB $00                ;
  DEFB $3C                ; Character $3B
  DEFB $42                ;
  DEFB $99                ;
  DEFB $A1                ;
  DEFB $A1                ;
  DEFB $99                ;
  DEFB $42                ;
  DEFB $3C                ;
  DEFB $00                ; Character $3C
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character $3D
  DEFB $62                ;
  DEFB $64                ;
  DEFB $08                ;
  DEFB $10                ;
  DEFB $26                ;
  DEFB $46                ;
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
  DEFB $DB                ;
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

; Tile table
TILE_TABLE:
  DEFW TILE0              ; Tile 0
  DEFW TILE1              ; Tile 1
  DEFW TILE2              ; Tile 2
  DEFW TILE3              ; Tile 3
  DEFW TILE4              ; Tile 4
  DEFW TILE5              ; Tile 5
  DEFW TILE6              ; Tile 6
  DEFW TILE7              ; Tile 7
  DEFW TILE8              ; Tile 8
  DEFW TILE9              ; Tile 9
  DEFW TILE10             ; Tile 10
  DEFW TILE11             ; Tile 11
  DEFW TILE12             ; Tile 12
  DEFW TILE13             ; Tile 13
  DEFW TILE14             ; Tile 14
  DEFW TILE15             ; Tile 15
  DEFW TILE16             ; Tile 16
  DEFW TILE17             ; Tile 17
  DEFW TILE18             ; Tile 18
  DEFW TILE19             ; Tile 19
  DEFW TILE20             ; Tile 20
  DEFW TILE21             ; Tile 21
  DEFW TILE22             ; Tile 22
  DEFW TILE23             ; Tile 23
  DEFW TILE24             ; Tile 24
  DEFW TILE25             ; Tile 25
  DEFW TILE26             ; Tile 26
  DEFW TILE27             ; Tile 27
  DEFW TILE28             ; Tile 28
  DEFW TILE29             ; Tile 29
  DEFW TILE30             ; Tile 30
  DEFW TILE31             ; Tile 31
  DEFW TILE32             ; Tile 32
  DEFW TILE33             ; Tile 33
  DEFW TILE34             ; Tile 34
  DEFW TILE35             ; Tile 35
  DEFW TILE36             ; Tile 36
  DEFW TILE37             ; Tile 37
  DEFW TILE38             ; Tile 38
  DEFW TILE39             ; Tile 39
  DEFW TILE40             ; Tile 40
  DEFW TILE41             ; Tile 41
  DEFW TILE0              ; Tile 42
  DEFW TILE43             ; Tile 43
  DEFW TILE44             ; Tile 44
  DEFW TILE45             ; Tile 45
  DEFW TILE46             ; Tile 46
  DEFW TILE47             ; Tile 47
  DEFW TILE48             ; Tile 48
  DEFW TILE49             ; Tile 49
  DEFW TILE50             ; Tile 50
  DEFW TILE51             ; Tile 51

; Graphic table
GRAPHICS:
  DEFW SPRITE0            ; Graphic 0
  DEFW SPRITE0            ; Graphic 1
  DEFW SPRITE2            ; Graphic 2
  DEFW SPRITE3            ; Graphic 3
  DEFW SPRITE4            ; Graphic 4
  DEFW SPRITE5            ; Graphic 5
  DEFW SPRITE6            ; Graphic 6
  DEFW SPRITE7            ; Graphic 7
  DEFW SPRITE4            ; Graphic 8
  DEFW SPRITE5            ; Graphic 9
  DEFW SPRITE6            ; Graphic 10
  DEFW SPRITE7            ; Graphic 11
  DEFW SPRITE12           ; Graphic 12
  DEFW SPRITE13           ; Graphic 13
  DEFW SPRITE14           ; Graphic 14
  DEFW SPRITE15           ; Graphic 15
  DEFW SPRITE16           ; Graphic 16
  DEFW SPRITE17           ; Graphic 17
  DEFW SPRITE18           ; Graphic 18
  DEFW SPRITE19           ; Graphic 19
  DEFW SPRITE18           ; Graphic 20
  DEFW SPRITE17           ; Graphic 21
  DEFW SPRITE22           ; Graphic 22
  DEFW SPRITE0            ; Graphic 23
  DEFW SPRITE24           ; Graphic 24
  DEFW SPRITE25           ; Graphic 25
  DEFW SPRITE26           ; Graphic 26
  DEFW SPRITE27           ; Graphic 27
  DEFW SPRITE26           ; Graphic 28
  DEFW SPRITE25           ; Graphic 29
  DEFW SPRITE30           ; Graphic 30
  DEFW SPRITE0            ; Graphic 31
  DEFW SPRITE32           ; Graphic 32
  DEFW SPRITE33           ; Graphic 33
  DEFW SPRITE34           ; Graphic 34
  DEFW SPRITE35           ; Graphic 35
  DEFW SPRITE34           ; Graphic 36
  DEFW SPRITE33           ; Graphic 37
  DEFW SPRITE38           ; Graphic 38
  DEFW SPRITE39           ; Graphic 39
  DEFW SPRITE40           ; Graphic 40
  DEFW SPRITE41           ; Graphic 41
  DEFW SPRITE42           ; Graphic 42
  DEFW SPRITE43           ; Graphic 43
  DEFW SPRITE42           ; Graphic 44
  DEFW SPRITE41           ; Graphic 45
  DEFW SPRITE46           ; Graphic 46
  DEFW SPRITE47           ; Graphic 47
  DEFW SPRITE48           ; Graphic 48
  DEFW SPRITE49           ; Graphic 49
  DEFW SPRITE50           ; Graphic 50
  DEFW SPRITE51           ; Graphic 51
  DEFW SPRITE52           ; Graphic 52
  DEFW SPRITE53           ; Graphic 53
  DEFW SPRITE54           ; Graphic 54
  DEFW SPRITE53           ; Graphic 55
  DEFW SPRITE56           ; Graphic 56
  DEFW SPRITE57           ; Graphic 57
  DEFW SPRITE58           ; Graphic 58
  DEFW SPRITE59           ; Graphic 59
  DEFW SPRITE60           ; Graphic 60
  DEFW SPRITE61           ; Graphic 61
  DEFW SPRITE62           ; Graphic 62
  DEFW SPRITE63           ; Graphic 63
  DEFW SPRITE64           ; Graphic 64
  DEFW SPRITE65           ; Graphic 65
  DEFW SPRITE66           ; Graphic 66
  DEFW SPRITE65           ; Graphic 67
  DEFW SPRITE68           ; Graphic 68
  DEFW SPRITE69           ; Graphic 69
  DEFW SPRITE70           ; Graphic 70
  DEFW SPRITE69           ; Graphic 71
  DEFW SPRITE72           ; Graphic 72
  DEFW SPRITE73           ; Graphic 73
  DEFW SPRITE74           ; Graphic 74
  DEFW SPRITE73           ; Graphic 75
  DEFW SPRITE76           ; Graphic 76
  DEFW SPRITE77           ; Graphic 77
  DEFW SPRITE78           ; Graphic 78
  DEFW SPRITE77           ; Graphic 79
  DEFW SPRITE48           ; Graphic 80
  DEFW SPRITE49           ; Graphic 81
  DEFW SPRITE50           ; Graphic 82
  DEFW SPRITE51           ; Graphic 83
  DEFW SPRITE52           ; Graphic 84
  DEFW SPRITE53           ; Graphic 85
  DEFW SPRITE54           ; Graphic 86
  DEFW SPRITE53           ; Graphic 87
  DEFW SPRITE56           ; Graphic 88
  DEFW SPRITE57           ; Graphic 89
  DEFW SPRITE58           ; Graphic 90
  DEFW SPRITE59           ; Graphic 91
  DEFW SPRITE60           ; Graphic 92
  DEFW SPRITE61           ; Graphic 93
  DEFW SPRITE62           ; Graphic 94
  DEFW SPRITE63           ; Graphic 95
  DEFW SPRITE96           ; Graphic 96
  DEFW SPRITE97           ; Graphic 97
  DEFW SPRITE96           ; Graphic 98
  DEFW SPRITE97           ; Graphic 99
  DEFW SPRITE100          ; Graphic 100
  DEFW SPRITE100          ; Graphic 101
  DEFW SPRITE102          ; Graphic 102
  DEFW SPRITE102          ; Graphic 103
  DEFW SPRITE104          ; Graphic 104
  DEFW SPRITE104          ; Graphic 105
  DEFW SPRITE106          ; Graphic 106
  DEFW SPRITE106          ; Graphic 107
  DEFW SPRITE108          ; Graphic 108
  DEFW SPRITE109          ; Graphic 109
  DEFW SPRITE110          ; Graphic 110
  DEFW SPRITE111          ; Graphic 111
  DEFW SPRITE112          ; Graphic 112
  DEFW SPRITE113          ; Graphic 113
  DEFW SPRITE114          ; Graphic 114
  DEFW SPRITE115          ; Graphic 115
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
  DEFW SPRITE15           ; Graphic 128
  DEFW SPRITE14           ; Graphic 129
  DEFW SPRITE13           ; Graphic 130
  DEFW SPRITE12           ; Graphic 131
  DEFW SPRITE12           ; Graphic 132
  DEFW SPRITE13           ; Graphic 133
  DEFW SPRITE14           ; Graphic 134
  DEFW SPRITE15           ; Graphic 135
  DEFW SPRITE136          ; Graphic 136
  DEFW SPRITE137          ; Graphic 137
  DEFW SPRITE138          ; Graphic 138
  DEFW SPRITE137          ; Graphic 139
  DEFW SPRITE48           ; Graphic 140
  DEFW SPRITE52           ; Graphic 141
  DEFW SPRITE56           ; Graphic 142
  DEFW SPRITE60           ; Graphic 143
  DEFW SPRITE96           ; Graphic 144
  DEFW SPRITE97           ; Graphic 145
  DEFW SPRITE100          ; Graphic 146
  DEFW SPRITE100          ; Graphic 147
  DEFW SPRITE104          ; Graphic 148
  DEFW SPRITE104          ; Graphic 149
  DEFW SPRITE108          ; Graphic 150
  DEFW SPRITE109          ; Graphic 151
  DEFW SPRITE152          ; Graphic 152
  DEFW SPRITE153          ; Graphic 153
  DEFW SPRITE154          ; Graphic 154
  DEFW SPRITE155          ; Graphic 155
  DEFW SPRITE156          ; Graphic 156
  DEFW SPRITE157          ; Graphic 157

; Sprite for graphics 0-1, 23, 31
;
; Width and height both zero: the drawing code draws nothing.
SPRITE0:
  DEFB $00,$00            ; Width and height

; Edge table
EDGE_TABLE:
  DEFW EDGE0              ; Edge 0
  DEFW EDGE0              ; Edge 1
  DEFW EDGE2              ; Edge 2
  DEFW EDGE3              ; Edge 3

; Edges 0-1
;
; 16 by 10 pixels.
EDGE0:
  DEFB $0A                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FC            ;
  DEFB $03,$F0            ;
  DEFB $0F,$C0            ;
  DEFB $3F,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Edge 2
;
; 16 by 10 pixels.
EDGE2:
  DEFB $0A                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $30,$00            ;
  DEFB $F0,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Edge 3
;
; 16 by 4 pixels.
EDGE3:
  DEFB $04                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$0F            ;
  DEFB $00,$0C            ;

; Sprite for graphic 152
;
; 32 by 26 pixels.
SPRITE152:
  DEFB $04,$1A            ; Width in bytes, and height in rows
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ; Mask and image bytes, a pair per cell,
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ; the bottom row first
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$1F,$FF,$80,$FF,$00 ;
  DEFB $FF,$00,$FF,$F0,$FF,$C0,$FF,$00 ;
  DEFB $FF,$01,$FF,$87,$FF,$80,$FF,$00 ;
  DEFB $FF,$00,$FF,$CE,$FF,$00,$FF,$00 ;
  DEFB $FF,$00,$FF,$63,$FF,$80,$FF,$00 ;
  DEFB $FF,$00,$FF,$30,$FF,$E0,$FF,$00 ;
  DEFB $FF,$00,$FF,$1C,$FF,$BC,$FF,$00 ;
  DEFB $FF,$00,$FF,$07,$FF,$87,$FF,$80 ;
  DEFB $FF,$00,$FF,$03,$FF,$80,$FF,$C0 ;
  DEFB $FF,$00,$FF,$0F,$FF,$03,$FF,$80 ;
  DEFB $FF,$00,$FF,$19,$FF,$0E,$FF,$00 ;
  DEFB $FF,$00,$FF,$71,$FF,$B8,$FF,$00 ;
  DEFB $FF,$FF,$FF,$C1,$FF,$FF,$FF,$FC ;
  DEFB $FF,$80,$FF,$00,$FF,$00,$FF,$03 ;

; Sprite for graphic 153
;
; 16 by 21 pixels.
SPRITE153:
  DEFB $02,$15            ; Width in bytes, and height in rows
  DEFB $FF,$00,$FF,$3F    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$19,$FF,$E5    ; row first
  DEFB $FF,$0E,$FF,$3D    ;
  DEFB $FF,$03,$FF,$81    ;
  DEFB $FF,$00,$FF,$C7    ;
  DEFB $FF,$00,$FF,$72    ;
  DEFB $FF,$07,$FF,$1F    ;
  DEFB $FF,$0D,$FF,$C1    ;
  DEFB $FF,$06,$FF,$7F    ;
  DEFB $FF,$03,$FF,$80    ;
  DEFB $FF,$00,$FF,$F0    ;
  DEFB $FF,$00,$FF,$1F    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$03    ;
  DEFB $FF,$07,$FF,$0F    ;
  DEFB $FF,$0C,$FF,$02    ;
  DEFB $FF,$07,$FF,$02    ;
  DEFB $FF,$01,$FF,$C3    ;
  DEFB $FF,$00,$FF,$78    ;
  DEFB $FF,$00,$FF,$0F    ;

; Sprite for graphic 154
;
; 16 by 24 pixels.
SPRITE154:
  DEFB $02,$18            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$FF,$C1    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$04,$FF,$00    ; row first
  DEFB $FF,$04,$FF,$14    ;
  DEFB $FF,$0A,$FF,$0A    ;
  DEFB $FF,$06,$FF,$1D    ;
  DEFB $FF,$8C,$FF,$1E    ;
  DEFB $FF,$8C,$FF,$1E    ;
  DEFB $FF,$2C,$FF,$1E    ;
  DEFB $FF,$2C,$FF,$1E    ;
  DEFB $FF,$26,$FF,$1C    ;
  DEFB $FF,$A6,$FF,$1D    ;
  DEFB $FF,$E6,$FF,$1E    ;
  DEFB $FF,$36,$FF,$00    ;
  DEFB $FF,$1A,$FF,$1F    ;
  DEFB $FF,$FE,$FF,$07    ;
  DEFB $FF,$00,$FF,$01    ;
  DEFB $FF,$00,$FF,$60    ;
  DEFB $FF,$AF,$FF,$FF    ;
  DEFB $FF,$F8,$FF,$00    ;
  DEFB $FF,$0F,$FF,$00    ;
  DEFB $FF,$C9,$FF,$80    ;
  DEFB $FF,$F8,$FF,$C0    ;
  DEFB $FF,$83,$FF,$80    ;
  DEFB $FF,$FE,$FF,$00    ;

; Sprite for graphic 155
;
; 16 by 28 pixels.
SPRITE155:
  DEFB $02,$1C            ; Width in bytes, and height in rows
  DEFB $FF,$FF,$FF,$FC    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$00,$FF,$03    ; row first
  DEFB $FF,$92,$FF,$00    ;
  DEFB $FF,$23,$FF,$03    ;
  DEFB $FF,$97,$FF,$03    ;
  DEFB $FF,$B7,$FF,$81    ;
  DEFB $FF,$A7,$FF,$81    ;
  DEFB $FF,$A7,$FF,$81    ;
  DEFB $FF,$B3,$FF,$A1    ;
  DEFB $FF,$B3,$FF,$21    ;
  DEFB $FF,$9B,$FF,$30    ;
  DEFB $FF,$DB,$FF,$17    ;
  DEFB $FF,$53,$FF,$3B    ;
  DEFB $FF,$C0,$FF,$1B    ;
  DEFB $FF,$3F,$FF,$9B    ;
  DEFB $FF,$C0,$FF,$79    ;
  DEFB $FF,$60,$FF,$0F    ;
  DEFB $FF,$C0,$FF,$FC    ;
  DEFB $FF,$07,$FF,$8C    ;
  DEFB $FF,$0C,$FF,$09    ;
  DEFB $FF,$07,$FF,$8F    ;
  DEFB $FF,$00,$FF,$62    ;
  DEFB $FF,$00,$FF,$16    ;
  DEFB $FF,$00,$FF,$34    ;
  DEFB $FF,$00,$FF,$28    ;
  DEFB $FF,$00,$FF,$28    ;
  DEFB $FF,$00,$FF,$38    ;
  DEFB $FF,$00,$FF,$10    ;

; Sprite for graphic 156
;
; 16 by 20 pixels.
SPRITE156:
  DEFB $02,$14            ; Width in bytes, and height in rows
  DEFB $FF,$00,$FF,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$F8,$FF,$00    ; row first
  DEFB $FF,$26,$FF,$00    ;
  DEFB $FF,$28,$FF,$00    ;
  DEFB $FF,$3F,$FF,$F0    ;
  DEFB $FF,$80,$FF,$1F    ;
  DEFB $FF,$94,$FF,$00    ;
  DEFB $FF,$D0,$FF,$1F    ;
  DEFB $FF,$87,$FF,$F3    ;
  DEFB $FF,$FC,$FF,$03    ;
  DEFB $FF,$7C,$FF,$00    ;
  DEFB $FF,$47,$FF,$00    ;
  DEFB $FF,$41,$FF,$80    ;
  DEFB $FF,$7F,$FF,$00    ;
  DEFB $FF,$9E,$FF,$00    ;
  DEFB $FF,$83,$FF,$80    ;
  DEFB $FF,$C0,$FF,$C0    ;
  DEFB $FF,$07,$FF,$80    ;
  DEFB $FF,$3C,$FF,$00    ;
  DEFB $FF,$E0,$FF,$00    ;

; Sprite for graphic 157
;
; 16 by 12 pixels.
SPRITE157:
  DEFB $02,$0C            ; Width in bytes, and height in rows
  DEFB $FF,$00,$FF,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $FF,$00,$FF,$00    ; row first
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$F0,$FF,$00    ;
  DEFB $FF,$10,$FF,$00    ;
  DEFB $FF,$7C,$FF,$00    ;
  DEFB $FF,$07,$FF,$80    ;
  DEFB $FF,$E0,$FF,$E0    ;
  DEFB $FF,$1F,$FF,$30    ;
  DEFB $FF,$01,$FF,$F0    ;

; Sprite for graphic 2
;
; 32 by 19 pixels.
SPRITE2:
  DEFB $04,$13            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$01,$00,$80,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$00,$00,$03,$01,$C0,$80 ; the bottom row first
  DEFB $00,$00,$00,$00,$0F,$03,$80,$00 ;
  DEFB $00,$00,$07,$00,$DF,$0B,$80,$00 ;
  DEFB $00,$00,$0F,$07,$FF,$CB,$90,$00 ;
  DEFB $00,$00,$1F,$0F,$FF,$EB,$B8,$10 ;
  DEFB $0F,$00,$9F,$0C,$FF,$2F,$F8,$B0 ;
  DEFB $1F,$0F,$FF,$93,$FF,$CF,$F0,$A0 ;
  DEFB $3F,$1F,$FF,$EF,$FF,$FF,$F0,$A0 ;
  DEFB $7F,$30,$FF,$1F,$FF,$DF,$F0,$A0 ;
  DEFB $7F,$2F,$FF,$FF,$FF,$DF,$F0,$60 ;
  DEFB $7F,$1B,$FF,$FF,$FF,$E7,$F0,$60 ;
  DEFB $7F,$33,$FF,$EB,$FF,$F0,$E0,$C0 ;
  DEFB $7F,$31,$FF,$FF,$FF,$F7,$E0,$C0 ;
  DEFB $3F,$18,$FF,$EF,$FF,$1F,$E0,$C0 ;
  DEFB $1F,$0F,$EF,$C4,$FF,$13,$C0,$80 ;
  DEFB $0F,$07,$CF,$84,$F3,$20,$80,$00 ;
  DEFB $07,$00,$87,$03,$E0,$C0,$00,$00 ;
  DEFB $00,$00,$03,$00,$C0,$00,$00,$00 ;

; Sprite for graphic 136
;
; 24 by 28 pixels.
SPRITE136:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1F,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$FF,$1F,$C0,$00 ;
  DEFB $03,$00,$FF,$FF,$F0,$C0 ;
  DEFB $0F,$03,$FF,$F7,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$E4,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$20,$F8,$70 ;
  DEFB $3F,$1F,$FF,$08,$FC,$78 ;
  DEFB $1F,$0C,$FF,$19,$FC,$78 ;
  DEFB $1F,$0C,$FF,$3B,$FC,$38 ;
  DEFB $BF,$1C,$FF,$7F,$F8,$B0 ;
  DEFB $3F,$1C,$FF,$FC,$F8,$F0 ;
  DEFB $3F,$1E,$FF,$EC,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$CF,$FC,$78 ;
  DEFB $1F,$0F,$FF,$9F,$FC,$F8 ;
  DEFB $1F,$0D,$FF,$BF,$F8,$F0 ;
  DEFB $0F,$04,$FF,$B3,$F0,$E0 ;
  DEFB $0F,$04,$FF,$F9,$F8,$F0 ;
  DEFB $07,$02,$FF,$F9,$F8,$F0 ;
  DEFB $07,$00,$FF,$FA,$F0,$E0 ;
  DEFB $0E,$04,$FF,$75,$F0,$E0 ;
  DEFB $1F,$0E,$FF,$6D,$E0,$C0 ;
  DEFB $1F,$0E,$7F,$2D,$E0,$C0 ;
  DEFB $1F,$0E,$7F,$36,$C0,$80 ;
  DEFB $0F,$06,$3F,$16,$C0,$80 ;
  DEFB $07,$02,$3F,$12,$80,$00 ;
  DEFB $07,$02,$17,$02,$00,$00 ;
  DEFB $02,$00,$02,$00,$00,$00 ;

; Sprite for graphics 137, 139
;
; 24 by 35 pixels.
SPRITE137:
  DEFB $03,$23            ; Width in bytes, and height in rows
  DEFB $00,$00,$36,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$7F,$36,$80,$00 ; bottom row first
  DEFB $01,$00,$FF,$6F,$E0,$80 ;
  DEFB $03,$01,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$F9,$F8,$F0 ;
  DEFB $0F,$07,$FF,$D1,$FC,$E8 ;
  DEFB $0F,$06,$FF,$C1,$F8,$70 ;
  DEFB $1F,$0E,$FF,$80,$FC,$38 ;
  DEFB $3F,$1E,$FF,$15,$FE,$3C ;
  DEFB $3F,$1E,$FF,$3D,$FF,$B6 ;
  DEFB $3F,$1E,$FF,$3F,$FF,$F2 ;
  DEFB $3F,$1E,$FF,$FC,$FF,$FA ;
  DEFB $7F,$3D,$FF,$EC,$FE,$F8 ;
  DEFB $7F,$3D,$FF,$C6,$FE,$7C ;
  DEFB $7F,$3F,$FF,$CF,$FE,$6C ;
  DEFB $7F,$37,$FF,$DF,$FF,$E6 ;
  DEFB $7F,$33,$FF,$FF,$FE,$E0 ;
  DEFB $3F,$13,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$07,$FF,$FF,$FC,$F8 ;
  DEFB $0F,$07,$FF,$FE,$FE,$FC ;
  DEFB $1F,$0F,$FF,$9C,$FF,$F2 ;
  DEFB $1F,$0F,$BF,$1D,$F7,$42 ;
  DEFB $1F,$0F,$9F,$0B,$EA,$40 ;
  DEFB $0F,$07,$9F,$0B,$DC,$88 ;
  DEFB $07,$03,$CF,$87,$FC,$98 ;
  DEFB $03,$00,$DF,$8F,$FE,$9C ;
  DEFB $01,$00,$DF,$8F,$BE,$1C ;
  DEFB $00,$00,$8F,$07,$BC,$18 ;
  DEFB $00,$00,$87,$03,$9C,$08 ;
  DEFB $01,$00,$C3,$81,$9C,$08 ;
  DEFB $03,$01,$E1,$C0,$08,$00 ;
  DEFB $03,$01,$E0,$C0,$00,$00 ;
  DEFB $03,$01,$C0,$80,$00,$00 ;
  DEFB $01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$80,$00,$00,$00 ;

; Sprite for graphic 138
;
; 24 by 32 pixels.
SPRITE138:
  DEFB $03,$20            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$7F,$00,$C0,$00 ; bottom row first
  DEFB $01,$00,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$03,$FF,$F9,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$D9,$FC,$78 ;
  DEFB $3F,$1F,$FF,$C0,$FE,$7C ;
  DEFB $3F,$17,$FF,$00,$FF,$3E ;
  DEFB $1F,$07,$FF,$14,$FF,$3E ;
  DEFB $1F,$0C,$FF,$14,$FF,$9E ;
  DEFB $1F,$0C,$FF,$3F,$FF,$DA ;
  DEFB $1F,$0E,$FF,$7D,$FE,$D8 ;
  DEFB $1F,$0E,$FF,$CC,$FC,$F8 ;
  DEFB $1F,$0F,$FF,$8E,$FC,$78 ;
  DEFB $3F,$1B,$FF,$9F,$FC,$78 ;
  DEFB $3F,$1D,$FF,$BF,$FC,$F8 ;
  DEFB $7F,$3D,$FF,$FF,$FE,$EC ;
  DEFB $7F,$3C,$FF,$FF,$EE,$C4 ;
  DEFB $7F,$38,$FF,$FF,$F7,$E2 ;
  DEFB $7F,$39,$FF,$FF,$FA,$F0 ;
  DEFB $3F,$19,$FF,$EF,$F8,$F0 ;
  DEFB $1F,$09,$EF,$C7,$F8,$F0 ;
  DEFB $1F,$09,$C7,$01,$F0,$E0 ;
  DEFB $0B,$01,$81,$00,$F0,$E0 ;
  DEFB $03,$01,$87,$00,$E0,$C0 ;
  DEFB $01,$00,$0F,$06,$E0,$40 ;
  DEFB $00,$00,$1F,$0F,$E0,$40 ;
  DEFB $00,$00,$1F,$0F,$C0,$00 ;
  DEFB $00,$00,$0F,$07,$80,$00 ;
  DEFB $00,$00,$07,$02,$00,$00 ;
  DEFB $00,$00,$07,$02,$00,$00 ;
  DEFB $00,$00,$02,$00,$00,$00 ;

; The carried things' pictures
ICONS:
  DEFB $00                ; Character 0
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character 1
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character 2
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character 3
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $2F                ; Character 4
  DEFB $2F                ;
  DEFB $28                ;
  DEFB $28                ;
  DEFB $2B                ;
  DEFB $28                ;
  DEFB $28                ;
  DEFB $28                ;
  DEFB $FC                ; Character 5
  DEFB $FC                ;
  DEFB $0C                ;
  DEFB $8C                ;
  DEFB $EC                ;
  DEFB $8C                ;
  DEFB $8C                ;
  DEFB $8C                ;
  DEFB $28                ; Character 6
  DEFB $2F                ;
  DEFB $2F                ;
  DEFB $2F                ;
  DEFB $2F                ;
  DEFB $2F                ;
  DEFB $2F                ;
  DEFB $00                ;
  DEFB $0C                ; Character 7
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $00                ;
  DEFB $01                ; Character 8
  DEFB $02                ;
  DEFB $02                ;
  DEFB $01                ;
  DEFB $19                ;
  DEFB $27                ;
  DEFB $2F                ;
  DEFB $29                ;
  DEFB $80                ; Character 9
  DEFB $40                ;
  DEFB $C0                ;
  DEFB $80                ;
  DEFB $98                ;
  DEFB $E4                ;
  DEFB $EC                ;
  DEFB $98                ;
  DEFB $01                ; Character 10
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $02                ;
  DEFB $02                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $80                ; Character 11
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $40                ;
  DEFB $C0                ;
  DEFB $80                ;
  DEFB $00                ;
  DEFB $1F                ; Character 12
  DEFB $19                ;
  DEFB $09                ;
  DEFB $0C                ;
  DEFB $16                ;
  DEFB $13                ;
  DEFB $11                ;
  DEFB $11                ;
  DEFB $F8                ; Character 13
  DEFB $F8                ;
  DEFB $F0                ;
  DEFB $F0                ;
  DEFB $E8                ;
  DEFB $C8                ;
  DEFB $88                ;
  DEFB $88                ;
  DEFB $11                ; Character 14
  DEFB $12                ;
  DEFB $16                ;
  DEFB $0C                ;
  DEFB $09                ;
  DEFB $19                ;
  DEFB $1F                ;
  DEFB $00                ;
  DEFB $88                ; Character 15
  DEFB $C8                ;
  DEFB $E8                ;
  DEFB $F0                ;
  DEFB $F0                ;
  DEFB $F8                ;
  DEFB $F8                ;
  DEFB $00                ;
  DEFB $17                ; Character 16
  DEFB $17                ;
  DEFB $17                ;
  DEFB $17                ;
  DEFB $16                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $F4                ; Character 17
  DEFB $F4                ;
  DEFB $F4                ;
  DEFB $74                ;
  DEFB $B4                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $01                ; Character 18
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $C0                ; Character 19
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $00                ;
  DEFB $00                ; Character 20
  DEFB $00                ;
  DEFB $00                ;
  DEFB $07                ;
  DEFB $1F                ;
  DEFB $38                ;
  DEFB $73                ;
  DEFB $67                ;
  DEFB $00                ; Character 21
  DEFB $00                ;
  DEFB $00                ;
  DEFB $F0                ;
  DEFB $F8                ;
  DEFB $1C                ;
  DEFB $E6                ;
  DEFB $F6                ;
  DEFB $62                ; Character 22
  DEFB $78                ;
  DEFB $3F                ;
  DEFB $0E                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $76                ; Character 23
  DEFB $E6                ;
  DEFB $CC                ;
  DEFB $38                ;
  DEFB $E0                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character 24
  DEFB $08                ;
  DEFB $06                ;
  DEFB $07                ;
  DEFB $02                ;
  DEFB $0D                ;
  DEFB $1F                ;
  DEFB $5F                ;
  DEFB $00                ; Character 25
  DEFB $00                ;
  DEFB $00                ;
  DEFB $40                ;
  DEFB $E0                ;
  DEFB $F0                ;
  DEFB $F8                ;
  DEFB $E8                ;
  DEFB $1F                ; Character 26
  DEFB $17                ;
  DEFB $0B                ;
  DEFB $0D                ;
  DEFB $1D                ;
  DEFB $10                ;
  DEFB $20                ;
  DEFB $00                ;
  DEFB $D0                ; Character 27
  DEFB $B8                ;
  DEFB $DC                ;
  DEFB $E6                ;
  DEFB $C0                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ; Character 28
  DEFB $30                ;
  DEFB $68                ;
  DEFB $5C                ;
  DEFB $3E                ;
  DEFB $1F                ;
  DEFB $0E                ;
  DEFB $36                ;
  DEFB $00                ; Character 29
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $0C                ;
  DEFB $F2                ;
  DEFB $F6                ;
  DEFB $4B                ; Character 30
  DEFB $59                ;
  DEFB $30                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $0C                ; Character 31
  DEFB $F0                ;
  DEFB $F8                ;
  DEFB $7C                ;
  DEFB $3E                ;
  DEFB $1E                ;
  DEFB $0C                ;
  DEFB $00                ;
  DEFB $00                ; Character 32
  DEFB $03                ;
  DEFB $0F                ;
  DEFB $1E                ;
  DEFB $3C                ;
  DEFB $38                ;
  DEFB $7C                ;
  DEFB $7E                ;
  DEFB $00                ; Character 33
  DEFB $C0                ;
  DEFB $F0                ;
  DEFB $78                ;
  DEFB $3C                ;
  DEFB $3C                ;
  DEFB $7E                ;
  DEFB $0E                ;
  DEFB $78                ; Character 34
  DEFB $70                ;
  DEFB $30                ;
  DEFB $38                ;
  DEFB $1F                ;
  DEFB $0F                ;
  DEFB $03                ;
  DEFB $00                ;
  DEFB $06                ; Character 35
  DEFB $86                ;
  DEFB $CC                ;
  DEFB $FC                ;
  DEFB $F8                ;
  DEFB $F0                ;
  DEFB $C0                ;
  DEFB $00                ;

; Sprite for graphic 118
;
; 24 by 27 pixels.
SPRITE118:
  DEFB $03,$1B            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$02,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$07,$02,$00,$00 ;
  DEFB $00,$00,$07,$03,$84,$00 ;
  DEFB $66,$00,$3F,$01,$CE,$84 ;
  DEFB $FF,$66,$FF,$3D,$FE,$CC ;
  DEFB $7F,$3E,$FF,$FF,$FC,$D8 ;
  DEFB $3F,$1D,$FF,$FE,$FE,$F0 ;
  DEFB $1F,$0B,$FF,$FE,$FF,$FE ;
  DEFB $0F,$07,$FF,$FE,$FE,$F8 ;
  DEFB $0F,$07,$FF,$FD,$F8,$E0 ;
  DEFB $1F,$08,$FF,$BF,$F8,$D0 ;
  DEFB $1F,$07,$FF,$BF,$F8,$B0 ;
  DEFB $1F,$0B,$FF,$BF,$FC,$B8 ;
  DEFB $1F,$0D,$FF,$BF,$FC,$F8 ;
  DEFB $0F,$00,$FF,$DF,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$5F,$F8,$F0 ;
  DEFB $1F,$07,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$09,$FF,$DF,$F8,$F0 ;
  DEFB $0F,$04,$FF,$6F,$F0,$E0 ;
  DEFB $07,$03,$FF,$EF,$F0,$E0 ;
  DEFB $03,$01,$FF,$F3,$E0,$C0 ;
  DEFB $01,$00,$FF,$3C,$E0,$00 ;
  DEFB $00,$00,$7F,$2D,$E0,$C0 ;
  DEFB $00,$00,$FF,$4B,$E0,$40 ;
  DEFB $00,$00,$5F,$0A,$E0,$40 ;
  DEFB $00,$00,$0A,$00,$40,$00 ;

; Sprite for graphic 119
;
; 24 by 28 pixels.
SPRITE119:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$10,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$3C,$10,$60,$00 ;
  DEFB $00,$00,$3E,$1C,$F0,$60 ;
  DEFB $00,$00,$3F,$0E,$F8,$C0 ;
  DEFB $00,$00,$FF,$37,$FC,$98 ;
  DEFB $0D,$00,$FF,$F7,$F8,$F0 ;
  DEFB $1F,$0D,$FF,$FB,$F0,$E0 ;
  DEFB $0F,$03,$FF,$FB,$E0,$C0 ;
  DEFB $0F,$07,$FF,$FB,$F0,$A0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$70 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$70 ;
  DEFB $0F,$01,$FF,$7F,$F8,$70 ;
  DEFB $1F,$0F,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$17,$FF,$7F,$FC,$F8 ;
  DEFB $3F,$1B,$FF,$7F,$FC,$F8 ;
  DEFB $1F,$01,$FF,$BF,$F8,$F0 ;
  DEFB $3F,$1C,$FF,$BF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$BF,$F8,$F0 ;
  DEFB $3F,$13,$FF,$BF,$F0,$E0 ;
  DEFB $3F,$18,$FF,$DF,$F0,$E0 ;
  DEFB $1F,$07,$FF,$DF,$E0,$C0 ;
  DEFB $07,$03,$FF,$E7,$E0,$C0 ;
  DEFB $03,$00,$FF,$78,$C0,$80 ;
  DEFB $01,$00,$FF,$EF,$E0,$C0 ;
  DEFB $03,$01,$FF,$9B,$E0,$40 ;
  DEFB $01,$00,$BF,$12,$40,$00 ;
  DEFB $00,$00,$12,$00,$00,$00 ;

; Sprite for graphic 122
;
; 24 by 26 pixels.
SPRITE122:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$0C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1F,$0C,$00,$00 ; bottom row first
  DEFB $1C,$00,$7F,$03,$80,$00 ;
  DEFB $3F,$1C,$FF,$7C,$00,$00 ;
  DEFB $7F,$3B,$FF,$F3,$80,$00 ;
  DEFB $7F,$37,$FF,$ED,$C0,$80 ;
  DEFB $3F,$0F,$FF,$EE,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$EE,$E0,$C0 ;
  DEFB $3F,$1F,$FF,$F7,$F0,$60 ;
  DEFB $3F,$1F,$FF,$FB,$F0,$E0 ;
  DEFB $3F,$1F,$FF,$FD,$F0,$E0 ;
  DEFB $3F,$1F,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$D0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$A0 ;
  DEFB $0F,$07,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$FF,$F8,$70 ;
  DEFB $0F,$07,$FF,$FC,$7C,$38 ;
  DEFB $0F,$07,$FC,$80,$3C,$18 ;
  DEFB $0F,$07,$80,$00,$1C,$08 ;
  DEFB $0F,$07,$80,$00,$08,$00 ;
  DEFB $07,$03,$80,$00,$00,$00 ;
  DEFB $07,$02,$00,$00,$00,$00 ;
  DEFB $02,$00,$00,$00,$00,$00 ;

; Sprite for graphic 123
;
; 24 by 26 pixels.
SPRITE123:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$7C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$FE,$7C,$00,$00 ; bottom row first
  DEFB $00,$00,$FF,$62,$00,$00 ;
  DEFB $06,$00,$FF,$1C,$00,$00 ;
  DEFB $0F,$06,$FF,$7F,$80,$00 ;
  DEFB $1F,$0D,$FF,$FF,$E0,$80 ;
  DEFB $1F,$0B,$FF,$FF,$F0,$60 ;
  DEFB $0F,$07,$FF,$FE,$F0,$E0 ;
  DEFB $2F,$07,$FF,$FD,$F0,$E0 ;
  DEFB $7F,$2F,$FF,$FF,$E0,$C0 ;
  DEFB $FF,$6F,$FF,$FF,$C0,$80 ;
  DEFB $7F,$2F,$FF,$FF,$F0,$40 ;
  DEFB $3F,$0F,$FF,$FF,$F8,$D0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$D0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$A0 ;
  DEFB $0F,$05,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$07,$FF,$FF,$F8,$70 ;
  DEFB $0F,$07,$FF,$FC,$7C,$38 ;
  DEFB $0F,$07,$FC,$80,$3C,$18 ;
  DEFB $0F,$07,$80,$00,$1C,$08 ;
  DEFB $0F,$07,$80,$00,$08,$00 ;
  DEFB $07,$03,$80,$00,$00,$00 ;
  DEFB $07,$02,$00,$00,$00,$00 ;
  DEFB $02,$00,$00,$00,$00,$00 ;

; Sprite for graphic 126
;
; 24 by 28 pixels.
SPRITE126:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $06,$00,$00,$00,$00,$00 ;
  DEFB $0F,$06,$83,$00,$80,$00 ;
  DEFB $1F,$0F,$C7,$83,$E0,$80 ;
  DEFB $1F,$0F,$EF,$C7,$F8,$E0 ;
  DEFB $1F,$0F,$FF,$E7,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$97,$FE,$FC ;
  DEFB $1F,$0F,$FF,$7F,$FF,$7E ;
  DEFB $0F,$07,$FF,$FF,$FF,$36 ;
  DEFB $0F,$07,$FF,$FE,$FE,$98 ;
  DEFB $0F,$07,$FF,$FF,$F8,$C0 ;
  DEFB $0F,$07,$FF,$FC,$F0,$60 ;
  DEFB $0F,$00,$FF,$FB,$F0,$A0 ;
  DEFB $1F,$0F,$FF,$BB,$F0,$A0 ;
  DEFB $0F,$07,$FF,$BD,$F0,$A0 ;
  DEFB $1F,$0B,$FF,$BD,$F0,$A0 ;
  DEFB $1F,$07,$FF,$BD,$F0,$A0 ;
  DEFB $3F,$1F,$FF,$BF,$F0,$E0 ;
  DEFB $1F,$07,$FF,$BF,$E0,$C0 ;
  DEFB $07,$03,$FF,$DF,$E0,$C0 ;
  DEFB $03,$01,$FF,$DF,$C0,$80 ;
  DEFB $0F,$00,$FF,$CF,$80,$00 ;
  DEFB $1F,$0F,$FF,$F0,$80,$00 ;
  DEFB $0F,$03,$FF,$BF,$80,$00 ;
  DEFB $03,$00,$FF,$35,$80,$00 ;
  DEFB $00,$00,$FF,$65,$80,$00 ;
  DEFB $00,$00,$65,$00,$00,$00 ;

; Sprite for graphic 127
;
; 24 by 28 pixels.
SPRITE127:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1C,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$3F,$1C,$00,$00 ;
  DEFB $00,$00,$7F,$3F,$80,$00 ;
  DEFB $00,$00,$7F,$3F,$C0,$80 ;
  DEFB $00,$00,$7F,$3F,$F8,$C0 ;
  DEFB $03,$00,$BF,$1D,$FC,$F8 ;
  DEFB $07,$03,$FF,$9D,$FC,$F8 ;
  DEFB $07,$03,$FF,$5E,$F8,$E0 ;
  DEFB $07,$02,$FF,$DE,$E0,$00 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $3F,$10,$FF,$FF,$F0,$C0 ;
  DEFB $7F,$2F,$FF,$BF,$F8,$B0 ;
  DEFB $3F,$17,$FF,$BF,$FC,$78 ;
  DEFB $1F,$0B,$FF,$BE,$F8,$F0 ;
  DEFB $1F,$07,$FF,$BF,$F0,$E0 ;
  DEFB $3F,$1F,$FF,$BF,$E0,$C0 ;
  DEFB $1F,$07,$FF,$BF,$E0,$80 ;
  DEFB $07,$03,$FF,$DF,$E0,$C0 ;
  DEFB $03,$01,$FF,$DF,$C0,$80 ;
  DEFB $0F,$00,$FF,$CF,$80,$00 ;
  DEFB $1F,$0F,$FF,$F0,$80,$00 ;
  DEFB $0F,$03,$FF,$BF,$80,$00 ;
  DEFB $03,$00,$FF,$35,$80,$00 ;
  DEFB $00,$00,$FF,$65,$80,$00 ;
  DEFB $00,$00,$65,$00,$00,$00 ;

; The compass, the headings and a life
PANEL_ICONS:
  DEFB $FE                ; Character 0
  DEFB $7F                ;
  DEFB $7F                ;
  DEFB $7F                ;
  DEFB $3F                ;
  DEFB $3F                ;
  DEFB $9F                ;
  DEFB $9F                ;
  DEFB $00                ; Character 1
  DEFB $FC                ;
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $FC                ;
  DEFB $F3                ;
  DEFB $CF                ;
  DEFB $00                ; Character 2
  DEFB $0F                ;
  DEFB $F0                ;
  DEFB $C0                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $C0                ;
  DEFB $00                ; Character 3
  DEFB $00                ;
  DEFB $E0                ;
  DEFB $18                ;
  DEFB $04                ;
  DEFB $02                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $8F                ; Character 4
  DEFB $8C                ;
  DEFB $40                ;
  DEFB $20                ;
  DEFB $18                ;
  DEFB $07                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $03                ; Character 5
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $F0                ;
  DEFB $0F                ;
  DEFB $F0                ; Character 6
  DEFB $FC                ;
  DEFB $3F                ;
  DEFB $0F                ;
  DEFB $03                ;
  DEFB $00                ;
  DEFB $0F                ;
  DEFB $F0                ;
  DEFB $01                ; Character 7
  DEFB $01                ;
  DEFB $02                ;
  DEFB $C4                ;
  DEFB $F0                ;
  DEFB $FC                ;
  DEFB $3F                ;
  DEFB $0C                ;
HEADING_CHARS:
  DEFB $00                ; Character 8
  DEFB $78                ;
  DEFB $7D                ;
  DEFB $6D                ;
  DEFB $6D                ;
  DEFB $6D                ;
  DEFB $6C                ;
  DEFB $00                ;
  DEFB $00                ; Character 9
  DEFB $E7                ;
  DEFB $F6                ;
  DEFB $B6                ;
  DEFB $B7                ;
  DEFB $F6                ;
  DEFB $E6                ;
  DEFB $00                ;
  DEFB $00                ; Character 10
  DEFB $9F                ;
  DEFB $DF                ;
  DEFB $C6                ;
  DEFB $86                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $00                ;
  DEFB $00                ; Character 11
  DEFB $B6                ;
  DEFB $B6                ;
  DEFB $3E                ;
  DEFB $3E                ;
  DEFB $36                ;
  DEFB $36                ;
  DEFB $00                ;
HEADING_TURNED_CHARS:
  DEFB $00                ; Character 12
  DEFB $3C                ;
  DEFB $71                ;
  DEFB $79                ;
  DEFB $1D                ;
  DEFB $7D                ;
  DEFB $7C                ;
  DEFB $00                ;
  DEFB $00                ; Character 13
  DEFB $E6                ;
  DEFB $F6                ;
  DEFB $B6                ;
  DEFB $B7                ;
  DEFB $F7                ;
  DEFB $E3                ;
  DEFB $00                ;
  DEFB $00                ; Character 14
  DEFB $DF                ;
  DEFB $DF                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $C6                ;
  DEFB $86                ;
  DEFB $00                ;
  DEFB $00                ; Character 15
  DEFB $B6                ;
  DEFB $B6                ;
  DEFB $3E                ;
  DEFB $3E                ;
  DEFB $36                ;
  DEFB $36                ;
  DEFB $00                ;
LIFE_CHARS:
  DEFB $00                ; Character 16
  DEFB $00                ;
  DEFB $00                ;
  DEFB $01                ;
  DEFB $03                ;
  DEFB $06                ;
  DEFB $04                ;
  DEFB $0B                ;
  DEFB $00                ; Character 17
  DEFB $00                ;
  DEFB $C0                ;
  DEFB $60                ;
  DEFB $70                ;
  DEFB $F8                ;
  DEFB $78                ;
  DEFB $1C                ;
  DEFB $08                ; Character 18
  DEFB $0B                ;
  DEFB $13                ;
  DEFB $38                ;
  DEFB $3C                ;
  DEFB $3F                ;
  DEFB $2F                ;
  DEFB $0F                ;
  DEFB $DC                ; Character 19
  DEFB $1C                ;
  DEFB $1C                ;
  DEFB $18                ;
  DEFB $20                ;
  DEFB $F8                ;
  DEFB $FC                ;
  DEFB $BC                ;
  DEFB $2F                ; Character 20
  DEFB $6F                ;
  DEFB $6F                ;
  DEFB $07                ;
  DEFB $18                ;
  DEFB $2F                ;
  DEFB $2A                ;
  DEFB $0A                ;
  DEFB $BC                ; Character 21
  DEFB $F8                ;
  DEFB $C4                ;
  DEFB $9C                ;
  DEFB $58                ;
  DEFB $D8                ;
  DEFB $A0                ;
  DEFB $A8                ;
  DEFB $02                ; Character 22
  DEFB $1C                ;
  DEFB $0E                ;
  DEFB $3C                ;
  DEFB $79                ;
  DEFB $03                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $A0                ; Character 23
  DEFB $00                ;
  DEFB $E0                ;
  DEFB $60                ;
  DEFB $F0                ;
  DEFB $E0                ;
  DEFB $80                ;
  DEFB $00                ;

; Sprite for graphics 12, 131-132
;
; 16 by 16 pixels.
SPRITE12:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $01,$00,$00,$00    ;
  DEFB $07,$01,$E0,$00    ;
  DEFB $0F,$07,$F0,$A0    ;
  DEFB $0F,$01,$F0,$20    ;
  DEFB $0F,$06,$F0,$00    ;
  DEFB $0F,$07,$F0,$60    ;
  DEFB $07,$03,$E0,$40    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 13, 130, 133
;
; 16 by 16 pixels.
SPRITE13:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $03,$00,$80,$00    ;
  DEFB $07,$03,$C0,$80    ;
  DEFB $0F,$07,$F0,$C0    ;
  DEFB $1F,$0F,$F8,$B0    ;
  DEFB $1F,$0C,$F8,$30    ;
  DEFB $1F,$00,$F8,$00    ;
  DEFB $1F,$0E,$F8,$30    ;
  DEFB $0F,$06,$F8,$70    ;
  DEFB $07,$02,$F0,$E0    ;
  DEFB $03,$00,$E0,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 14, 129, 134
;
; 16 by 16 pixels.
SPRITE14:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $07,$00,$C0,$00    ;
  DEFB $1F,$07,$E0,$C0    ;
  DEFB $3F,$1F,$F8,$E0    ;
  DEFB $7F,$3F,$FC,$C8    ;
  DEFB $7F,$3F,$FE,$0C    ;
  DEFB $7F,$38,$FE,$0C    ;
  DEFB $7F,$00,$FE,$0C    ;
  DEFB $7F,$30,$FE,$00    ;
  DEFB $7F,$3C,$FE,$20    ;
  DEFB $3F,$1E,$FE,$3C    ;
  DEFB $1F,$0F,$FC,$78    ;
  DEFB $0F,$07,$F8,$70    ;
  DEFB $07,$00,$F0,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 15, 128, 135
;
; 16 by 16 pixels.
SPRITE15:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $07,$00,$80,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$07,$C0,$80    ; row first
  DEFB $3F,$1F,$F8,$00    ;
  DEFB $7F,$38,$FC,$18    ;
  DEFB $FF,$64,$FE,$1C    ;
  DEFB $FF,$50,$FF,$06    ;
  DEFB $FF,$40,$FF,$26    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$00    ;
  DEFB $FF,$00,$FF,$06    ;
  DEFB $FF,$40,$FF,$2E    ;
  DEFB $FF,$68,$FE,$44    ;
  DEFB $FF,$74,$FE,$0C    ;
  DEFB $7F,$3A,$FC,$78    ;
  DEFB $3F,$0E,$F8,$E0    ;
  DEFB $0F,$00,$F0,$00    ;

; Sprite for graphic 3
;
; 16 by 16 pixels.
SPRITE3:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $07,$00,$E0,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $1F,$07,$F8,$E0    ; row first
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $7F,$37,$FE,$FC    ;
  DEFB $FF,$63,$FF,$FE    ;
  DEFB $FF,$63,$FF,$FE    ;
  DEFB $FF,$73,$FF,$FE    ;
  DEFB $7F,$39,$FE,$FC    ;
  DEFB $3F,$0E,$FC,$F0    ;
  DEFB $0F,$02,$F0,$C0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $07,$02,$E0,$40    ;
  DEFB $0F,$05,$F0,$A0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $03,$01,$C0,$80    ;
  DEFB $01,$00,$80,$00    ;

; Sprite for graphics 106-107
;
; 24 by 33 pixels.
SPRITE106:
  DEFB $03,$21            ; Width in bytes, and height in rows
  DEFB $C0,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $1F,$0C,$80,$00,$00,$00 ; bottom row first
  DEFB $1F,$0F,$F0,$80,$00,$00 ;
  DEFB $0F,$07,$F8,$F0,$00,$00 ;
  DEFB $0F,$07,$FF,$F8,$80,$00 ;
  DEFB $07,$03,$FF,$FF,$E0,$80 ;
  DEFB $07,$03,$FF,$FF,$F8,$E0 ;
  DEFB $07,$03,$FF,$BF,$FC,$F8 ;
  DEFB $03,$01,$FF,$DF,$FC,$F8 ;
  DEFB $03,$01,$FF,$FF,$FC,$F8 ;
  DEFB $01,$00,$FF,$EF,$F8,$F0 ;
  DEFB $01,$00,$FF,$EF,$F8,$F0 ;
  DEFB $01,$00,$FF,$FF,$F0,$E0 ;
  DEFB $01,$00,$FF,$F7,$F0,$E0 ;
  DEFB $03,$01,$FF,$F7,$F0,$E0 ;
  DEFB $03,$01,$FF,$F7,$F0,$E0 ;
  DEFB $03,$01,$FF,$F7,$F8,$D0 ;
  DEFB $03,$01,$FF,$EF,$FC,$B8 ;
  DEFB $03,$01,$FF,$EF,$FC,$78 ;
  DEFB $07,$03,$FF,$DF,$FC,$F8 ;
  DEFB $0F,$07,$FF,$DF,$FC,$F8 ;
  DEFB $0F,$07,$FF,$BF,$F8,$F0 ;
  DEFB $07,$02,$FF,$7F,$F0,$E0 ;
  DEFB $3F,$01,$FF,$FF,$E2,$80 ;
  DEFB $7F,$3F,$FF,$FF,$F7,$E2 ;
  DEFB $3F,$1F,$FF,$FF,$FE,$E4 ;
  DEFB $3F,$0F,$FF,$FF,$FC,$98 ;
  DEFB $7F,$33,$FF,$F8,$F8,$70 ;
  DEFB $7F,$30,$FF,$07,$F0,$C0 ;
  DEFB $FF,$77,$FF,$FF,$F0,$20 ;
  DEFB $FF,$7F,$FF,$FC,$E0,$C0 ;
  DEFB $7F,$3F,$FF,$C3,$C0,$00 ;
  DEFB $3F,$00,$C3,$00,$00,$00 ;

; Sprite for graphics 96, 98, 144
;
; 24 by 43 pixels.
SPRITE96:
  DEFB $03,$2B            ; Width in bytes, and height in rows
  DEFB $00,$00,$80,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$C0,$80,$00,$00 ; bottom row first
  DEFB $04,$00,$80,$00,$00,$00 ;
  DEFB $0E,$04,$02,$00,$00,$00 ;
  DEFB $04,$00,$07,$02,$00,$00 ;
  DEFB $00,$00,$42,$00,$00,$00 ;
  DEFB $02,$00,$F4,$40,$00,$00 ;
  DEFB $07,$02,$FE,$94,$00,$00 ;
  DEFB $0B,$01,$FE,$50,$00,$00 ;
  DEFB $1F,$0A,$FF,$AA,$00,$00 ;
  DEFB $0F,$05,$FF,$54,$00,$00 ;
  DEFB $0F,$03,$FF,$6B,$80,$00 ;
  DEFB $1F,$0A,$FF,$90,$80,$00 ;
  DEFB $0F,$06,$FF,$FC,$C0,$80 ;
  DEFB $1F,$0B,$FF,$BA,$80,$00 ;
  DEFB $1F,$07,$FF,$BF,$80,$00 ;
  DEFB $3F,$1F,$FF,$FF,$C0,$80 ;
  DEFB $3F,$1F,$FF,$FF,$E0,$C0 ;
  DEFB $3F,$1F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$ED,$FC,$F8 ;
  DEFB $3F,$1E,$EF,$C5,$FC,$F8 ;
  DEFB $3E,$1C,$EF,$46,$FC,$F8 ;
  DEFB $7E,$3C,$FF,$4E,$FC,$F8 ;
  DEFB $7F,$3E,$FF,$7E,$FE,$FC ;
  DEFB $7F,$3B,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3B,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3D,$FC,$F8,$FE,$7C ;
  DEFB $7F,$3D,$FC,$F8,$FE,$7C ;
  DEFB $7F,$3D,$FF,$F8,$FE,$3C ;
  DEFB $7F,$3C,$FF,$F7,$FF,$3E ;
  DEFB $FE,$7C,$FF,$7E,$3F,$0E ;
  DEFB $FC,$78,$7E,$18,$0E,$00 ;
  DEFB $F8,$70,$18,$00,$00,$00 ;
  DEFB $F8,$70,$00,$00,$00,$00 ;
  DEFB $F0,$60,$00,$00,$00,$00 ;
  DEFB $E0,$40,$00,$00,$00,$00 ;
  DEFB $40,$00,$00,$00,$00,$00 ;

; Sprite for graphics 97, 99, 145
;
; 24 by 43 pixels.
SPRITE97:
  DEFB $03,$2B            ; Width in bytes, and height in rows
  DEFB $00,$00,$20,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $02,$00,$70,$20,$00,$00 ; bottom row first
  DEFB $07,$02,$28,$00,$00,$00 ;
  DEFB $03,$01,$FC,$28,$00,$00 ;
  DEFB $07,$00,$FC,$40,$00,$00 ;
  DEFB $0F,$05,$FE,$54,$00,$00 ;
  DEFB $07,$00,$FF,$AA,$00,$00 ;
  DEFB $0F,$03,$FE,$54,$00,$00 ;
  DEFB $1F,$09,$FF,$AA,$00,$00 ;
  DEFB $1F,$07,$FF,$D5,$80,$00 ;
  DEFB $3F,$17,$FF,$BA,$00,$00 ;
  DEFB $1F,$07,$FF,$FF,$80,$00 ;
  DEFB $1F,$0F,$FF,$FD,$C0,$80 ;
  DEFB $1F,$07,$FF,$FF,$C0,$80 ;
  DEFB $3F,$1F,$FF,$FF,$C0,$80 ;
  DEFB $1F,$0F,$FF,$FF,$C0,$80 ;
  DEFB $3F,$1F,$FF,$FF,$E0,$C0 ;
  DEFB $3F,$1F,$FF,$FF,$E0,$C0 ;
  DEFB $3F,$1F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F0,$E0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FF,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$FB,$F8,$F0 ;
  DEFB $7F,$3F,$FF,$ED,$FC,$F8 ;
  DEFB $3F,$1E,$EF,$C5,$FC,$F8 ;
  DEFB $3E,$1C,$EF,$46,$FC,$F8 ;
  DEFB $7E,$3C,$FF,$4E,$FC,$F8 ;
  DEFB $7F,$3E,$FF,$7E,$FE,$FC ;
  DEFB $7F,$3B,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3B,$FF,$FC,$FE,$FC ;
  DEFB $7F,$3D,$FC,$F8,$FE,$7C ;
  DEFB $7F,$3D,$FC,$F8,$FE,$7C ;
  DEFB $7F,$3D,$FF,$F8,$FE,$3C ;
  DEFB $7F,$3C,$FF,$F7,$FF,$3E ;
  DEFB $FE,$7C,$FF,$7E,$3F,$0E ;
  DEFB $FC,$78,$7E,$18,$0E,$00 ;
  DEFB $F8,$70,$18,$00,$00,$00 ;
  DEFB $F8,$70,$00,$00,$00,$00 ;
  DEFB $F0,$60,$00,$00,$00,$00 ;
  DEFB $E0,$40,$00,$00,$00,$00 ;
  DEFB $40,$00,$00,$00,$00,$00 ;

; Sprite for graphics 5, 9
;
; 24 by 15 pixels.
SPRITE5:
  DEFB $03,$0F            ; Width in bytes, and height in rows
  DEFB $30,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $78,$30,$00,$00,$00,$00 ; bottom row first
  DEFB $FE,$58,$00,$00,$00,$00 ;
  DEFB $FF,$66,$80,$00,$38,$00 ;
  DEFB $7F,$3F,$E0,$80,$7C,$38 ;
  DEFB $3F,$03,$F9,$E0,$FE,$5C ;
  DEFB $03,$00,$FF,$F9,$FE,$E4 ;
  DEFB $00,$00,$FF,$3F,$FC,$F8 ;
  DEFB $00,$00,$FF,$1F,$F8,$C0 ;
  DEFB $01,$00,$FF,$FF,$FC,$F0 ;
  DEFB $03,$01,$FF,$7D,$FE,$FC ;
  DEFB $03,$01,$FD,$90,$FE,$5C ;
  DEFB $01,$00,$F8,$F0,$FE,$64 ;
  DEFB $00,$00,$F0,$00,$7C,$38 ;
  DEFB $00,$00,$00,$00,$38,$00 ;

; Sprite for graphics 4, 8
;
; 24 by 19 pixels.
SPRITE4:
  DEFB $03,$13            ; Width in bytes, and height in rows
  DEFB $00,$00,$04,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1F,$04,$00,$00 ; bottom row first
  DEFB $00,$00,$7F,$1B,$C0,$00 ;
  DEFB $01,$00,$FF,$6A,$F0,$C0 ;
  DEFB $07,$01,$FF,$D1,$FC,$30 ;
  DEFB $1F,$06,$FF,$AA,$FE,$AC ;
  DEFB $3F,$1D,$FF,$55,$FF,$52 ;
  DEFB $7F,$2A,$FF,$9F,$FF,$2A ;
  DEFB $FF,$65,$FF,$7F,$FF,$C4 ;
  DEFB $FF,$69,$FF,$F9,$FF,$F2 ;
  DEFB $FF,$67,$FF,$E0,$FE,$7C ;
  DEFB $7F,$3D,$FF,$8D,$FF,$1E ;
  DEFB $7F,$3E,$FF,$63,$FF,$86 ;
  DEFB $3F,$0F,$FF,$99,$FE,$18 ;
  DEFB $0F,$03,$FF,$E6,$F8,$60 ;
  DEFB $03,$00,$FF,$F9,$E0,$80 ;
  DEFB $00,$00,$FF,$3E,$80,$00 ;
  DEFB $00,$00,$3E,$04,$00,$00 ;
  DEFB $00,$00,$04,$00,$00,$00 ;

; Sprite for graphics 7, 11
;
; 24 by 15 pixels.
SPRITE7:
  DEFB $03,$0F            ; Width in bytes, and height in rows
  DEFB $70,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $FC,$70,$00,$00,$00,$00 ; bottom row first
  DEFB $FF,$7C,$00,$00,$00,$00 ;
  DEFB $7F,$3F,$C0,$00,$7C,$00 ;
  DEFB $3F,$0F,$F1,$C0,$FE,$5C ;
  DEFB $0F,$03,$FF,$F1,$FF,$BE ;
  DEFB $03,$00,$FF,$FD,$FF,$BE ;
  DEFB $00,$00,$FF,$3E,$FF,$BE ;
  DEFB $00,$00,$3F,$0D,$FF,$BE ;
  DEFB $00,$00,$7F,$33,$FE,$DC ;
  DEFB $00,$00,$7F,$3F,$FC,$F0 ;
  DEFB $00,$00,$7F,$3F,$F8,$E0 ;
  DEFB $00,$00,$3F,$1F,$E0,$80 ;
  DEFB $00,$00,$1F,$0E,$80,$00 ;
  DEFB $00,$00,$0E,$00,$00,$00 ;

; Sprite for graphics 6, 10
;
; 24 by 25 pixels.
SPRITE6:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$7E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$7E,$80,$00 ; bottom row first
  DEFB $03,$01,$FF,$81,$C0,$80 ;
  DEFB $07,$03,$FF,$7E,$E0,$C0 ;
  DEFB $0F,$06,$FF,$DF,$F0,$60 ;
  DEFB $0F,$02,$FF,$9F,$F0,$40 ;
  DEFB $0F,$05,$FF,$1F,$F0,$A0 ;
  DEFB $0F,$05,$FF,$8F,$F0,$A0 ;
  DEFB $0F,$04,$FF,$CF,$F0,$20 ;
  DEFB $0F,$04,$FF,$CF,$F0,$20 ;
  DEFB $0F,$04,$FF,$6E,$F0,$20 ;
  DEFB $0F,$04,$FF,$3C,$F0,$20 ;
  DEFB $0F,$04,$FF,$2C,$F0,$20 ;
  DEFB $0F,$04,$FF,$6E,$F0,$20 ;
  DEFB $0F,$04,$FF,$FF,$F0,$20 ;
  DEFB $0F,$05,$FF,$81,$F0,$A0 ;
  DEFB $0F,$04,$FF,$7E,$F0,$20 ;
  DEFB $0F,$05,$FF,$FF,$F0,$A0 ;
  DEFB $0F,$03,$FF,$FF,$F0,$C0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $07,$03,$FF,$FF,$E0,$C0 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphics 108, 150
;
; 24 by 34 pixels.
SPRITE108:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $04,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $0E,$04,$00,$00,$80,$00 ; bottom row first
  DEFB $0F,$06,$C3,$00,$C0,$80 ;
  DEFB $1F,$0F,$E7,$C2,$E0,$C0 ;
  DEFB $0F,$03,$E3,$C1,$F0,$E0 ;
  DEFB $03,$01,$C3,$80,$F8,$70 ;
  DEFB $03,$01,$C7,$83,$F8,$D0 ;
  DEFB $07,$03,$8F,$04,$F0,$E0 ;
  DEFB $07,$02,$DF,$8F,$E0,$80 ;
  DEFB $07,$03,$9F,$0C,$80,$00 ;
  DEFB $07,$03,$DF,$8A,$00,$00 ;
  DEFB $03,$01,$FF,$49,$80,$00 ;
  DEFB $01,$00,$FF,$95,$80,$00 ;
  DEFB $00,$00,$FF,$50,$C0,$80 ;
  DEFB $01,$00,$FF,$AE,$80,$00 ;
  DEFB $00,$00,$FF,$19,$C0,$80 ;
  DEFB $00,$00,$FF,$46,$E0,$40 ;
  DEFB $01,$00,$FF,$81,$F0,$60 ;
  DEFB $01,$00,$FF,$75,$E0,$40 ;
  DEFB $01,$00,$FF,$83,$E0,$40 ;
  DEFB $03,$01,$FF,$74,$F0,$A0 ;
  DEFB $03,$01,$FF,$82,$F0,$A0 ;
  DEFB $03,$01,$FF,$39,$F0,$A0 ;
  DEFB $07,$03,$FF,$54,$E0,$C0 ;
  DEFB $0F,$07,$FF,$56,$C0,$00 ;
  DEFB $0F,$05,$FF,$7F,$80,$00 ;
  DEFB $07,$02,$FF,$6B,$C0,$80 ;
  DEFB $03,$00,$FF,$D1,$E0,$C0 ;
  DEFB $01,$00,$FF,$8B,$E0,$C0 ;
  DEFB $01,$00,$FF,$9F,$E0,$C0 ;
  DEFB $00,$00,$FF,$7F,$C0,$80 ;
  DEFB $00,$00,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$7F,$3E,$00,$00 ;
  DEFB $00,$00,$3E,$00,$00,$00 ;

; Sprite for graphic 114
;
; 24 by 32 pixels.
SPRITE114:
  DEFB $03,$20            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$03,$00,$80,$00 ; bottom row first
  DEFB $1E,$00,$3F,$03,$E0,$80 ;
  DEFB $3F,$1E,$FF,$3C,$F0,$E0 ;
  DEFB $7F,$3C,$FF,$FF,$F8,$70 ;
  DEFB $7F,$33,$FF,$FF,$F8,$B0 ;
  DEFB $3F,$0F,$FF,$FF,$F0,$C0 ;
  DEFB $3F,$1E,$FF,$7F,$F0,$E0 ;
  DEFB $3F,$1D,$FF,$BF,$F0,$E0 ;
  DEFB $3F,$1B,$FF,$DF,$F8,$F0 ;
  DEFB $3F,$1B,$FF,$DF,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$3F,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$01,$FF,$FF,$E4,$C0 ;
  DEFB $0F,$07,$FF,$FF,$EE,$C4 ;
  DEFB $1F,$0F,$FF,$FF,$FE,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$FF,$F6 ;
  DEFB $1F,$0F,$FF,$7D,$FF,$FA ;
  DEFB $3F,$1E,$FF,$FE,$FF,$7A ;
  DEFB $7F,$3E,$FF,$FF,$FE,$3C ;
  DEFB $7F,$3C,$FF,$FF,$FE,$BC ;
  DEFB $7D,$38,$FF,$FF,$FE,$DC ;
  DEFB $7C,$38,$FF,$77,$FE,$DC ;
  DEFB $7C,$38,$FF,$66,$FE,$38 ;
  DEFB $F8,$70,$FE,$64,$7F,$3A ;
  DEFB $FC,$70,$74,$20,$7E,$3C ;
  DEFB $FE,$7C,$20,$00,$7E,$38 ;
  DEFB $FC,$60,$00,$00,$3F,$1E ;
  DEFB $78,$30,$00,$00,$3E,$10 ;
  DEFB $3C,$18,$00,$00,$10,$00 ;
  DEFB $18,$00,$00,$00,$00,$00 ;

; Sprite for graphic 115
;
; 24 by 31 pixels.
SPRITE115:
  DEFB $03,$1F            ; Width in bytes, and height in rows
  DEFB $00,$00,$FC,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FF,$FC,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$C3,$80,$00 ;
  DEFB $0C,$00,$FF,$3C,$C0,$80 ;
  DEFB $1F,$0C,$FF,$FF,$80,$00 ;
  DEFB $3F,$13,$FF,$FF,$C0,$80 ;
  DEFB $7F,$2F,$FF,$FF,$E0,$C0 ;
  DEFB $3F,$1E,$FF,$7F,$F0,$E0 ;
  DEFB $3F,$1D,$FF,$BF,$F0,$E0 ;
  DEFB $3F,$1B,$FF,$DF,$F8,$F0 ;
  DEFB $3F,$1B,$FF,$DF,$F8,$F0 ;
  DEFB $3F,$1D,$FF,$DF,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$3F,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$01,$FF,$FF,$E4,$C0 ;
  DEFB $0F,$07,$FF,$FF,$EE,$C4 ;
  DEFB $0F,$07,$FF,$FF,$FE,$E0 ;
  DEFB $0F,$07,$FF,$FF,$FF,$F6 ;
  DEFB $0F,$07,$FF,$7D,$FF,$F6 ;
  DEFB $0F,$06,$FF,$7E,$FF,$F6 ;
  DEFB $1F,$0E,$FF,$FE,$FE,$F8 ;
  DEFB $1F,$0E,$FF,$FF,$FC,$78 ;
  DEFB $1F,$0E,$FF,$FF,$FC,$78 ;
  DEFB $0F,$06,$FF,$77,$FC,$B8 ;
  DEFB $0F,$06,$FF,$66,$F8,$30 ;
  DEFB $1F,$0E,$FE,$64,$F8,$70 ;
  DEFB $1F,$0C,$F4,$20,$FC,$60 ;
  DEFB $1F,$0F,$A0,$00,$FE,$7C ;
  DEFB $1F,$0C,$00,$00,$7C,$30 ;
  DEFB $0F,$07,$80,$00,$FE,$5C ;
  DEFB $07,$00,$00,$00,$5C,$00 ;

; Sprite for graphics 48, 80, 140
;
; 16 by 13 pixels.
SPRITE48:
  DEFB $02,$0D            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $01,$00,$E0,$00    ; row first
  DEFB $0F,$01,$F8,$E0    ;
  DEFB $3F,$0E,$FC,$38    ;
  DEFB $7F,$3F,$FE,$CC    ;
  DEFB $FF,$78,$FF,$E6    ;
  DEFB $FF,$62,$FF,$76    ;
  DEFB $FF,$67,$FF,$F6    ;
  DEFB $FF,$73,$FF,$E6    ;
  DEFB $7F,$38,$FE,$1C    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $1F,$07,$F8,$F0    ;
  DEFB $07,$00,$F0,$00    ;

; Sprite for graphics 49, 81
;
; 16 by 13 pixels.
SPRITE49:
  DEFB $02,$0D            ; Width in bytes, and height in rows
  DEFB $0F,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $3F,$0F,$C0,$00    ; row first
  DEFB $7F,$3F,$E0,$C0    ;
  DEFB $FF,$70,$F4,$E0    ;
  DEFB $FF,$67,$FE,$74    ;
  DEFB $FF,$6F,$FF,$BA    ;
  DEFB $FF,$6E,$FF,$3A    ;
  DEFB $7F,$37,$FF,$F2    ;
  DEFB $7F,$39,$FF,$E6    ;
  DEFB $3F,$1E,$FE,$0C    ;
  DEFB $1F,$07,$FC,$F8    ;
  DEFB $07,$01,$F8,$E0    ;
  DEFB $01,$00,$E0,$00    ;

; Sprite for graphics 50, 82
;
; 16 by 13 pixels.
SPRITE50:
  DEFB $02,$0D            ; Width in bytes, and height in rows
  DEFB $0F,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $3F,$0F,$E0,$00    ; row first
  DEFB $7F,$3F,$F8,$E0    ;
  DEFB $FF,$78,$FC,$F8    ;
  DEFB $FF,$73,$FE,$7C    ;
  DEFB $FF,$67,$FF,$9E    ;
  DEFB $FF,$76,$FF,$CE    ;
  DEFB $7F,$37,$FF,$3E    ;
  DEFB $7F,$3B,$FE,$FC    ;
  DEFB $3F,$1C,$FC,$F8    ;
  DEFB $1F,$07,$F8,$00    ;
  DEFB $07,$01,$F0,$E0    ;
  DEFB $01,$00,$E0,$00    ;

; Sprite for graphics 51, 83
;
; 16 by 13 pixels.
SPRITE51:
  DEFB $02,$0D            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $0F,$00,$E0,$00    ; row first
  DEFB $3F,$0F,$F8,$E0    ;
  DEFB $7F,$38,$FC,$78    ;
  DEFB $FF,$67,$FE,$BC    ;
  DEFB $FF,$4F,$FF,$CE    ;
  DEFB $FF,$5C,$FF,$66    ;
  DEFB $7F,$1D,$FF,$C6    ;
  DEFB $1F,$0E,$FF,$0E    ;
  DEFB $0F,$07,$FE,$FC    ;
  DEFB $07,$01,$FC,$F0    ;
  DEFB $01,$00,$F0,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 52, 84, 141
;
; 16 by 16 pixels.
SPRITE52:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$08,$00    ; row first
  DEFB $03,$00,$DC,$08    ;
  DEFB $67,$03,$F8,$D0    ;
  DEFB $FF,$67,$F0,$E0    ;
  DEFB $7F,$2F,$F8,$F0    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $3F,$1F,$FE,$F8    ;
  DEFB $3F,$19,$FF,$FA    ;
  DEFB $3F,$16,$FE,$F8    ;
  DEFB $1F,$0E,$F8,$C0    ;
  DEFB $3F,$18,$F8,$B0    ;
  DEFB $7F,$23,$FC,$78    ;
  DEFB $23,$00,$FC,$18    ;
  DEFB $00,$00,$1E,$04    ;
  DEFB $00,$00,$04,$00    ;

; Sprite for graphics 53, 55, 85, 87
;
; 16 by 16 pixels.
SPRITE53:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $03,$00,$C0,$00    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $1F,$0B,$F8,$F0    ;
  DEFB $3F,$1F,$FC,$E8    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $1F,$0B,$F8,$F0    ;
  DEFB $0F,$07,$F0,$C0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 54, 86
;
; 16 by 16 pixels.
SPRITE54:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $20,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $70,$20,$00,$00    ; row first
  DEFB $3D,$10,$C0,$00    ;
  DEFB $3F,$1D,$E6,$C0    ;
  DEFB $1F,$0D,$FF,$E6    ;
  DEFB $1F,$0B,$FE,$DC    ;
  DEFB $3F,$17,$FC,$B8    ;
  DEFB $7F,$1F,$FC,$D0    ;
  DEFB $FF,$5F,$FC,$E8    ;
  DEFB $7F,$1F,$FC,$F8    ;
  DEFB $1F,$0D,$F8,$F0    ;
  DEFB $0F,$02,$F0,$E0    ;
  DEFB $0F,$07,$E0,$40    ;
  DEFB $0F,$06,$C0,$00    ;
  DEFB $1E,$08,$00,$00    ;
  DEFB $08,$00,$00,$00    ;

; Sprite for graphics 56, 88, 142
;
; 16 by 16 pixels.
SPRITE56:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$0C,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $18,$00,$1E,$0C    ; row first
  DEFB $3C,$18,$3F,$1E    ;
  DEFB $7E,$2C,$7F,$3E    ;
  DEFB $7E,$24,$FE,$7C    ;
  DEFB $3F,$1E,$FC,$F8    ;
  DEFB $1F,$05,$F8,$F0    ;
  DEFB $07,$03,$F0,$E0    ;
  DEFB $0F,$07,$E0,$C0    ;
  DEFB $1F,$0F,$F8,$A0    ;
  DEFB $3F,$1F,$FC,$78    ;
  DEFB $7F,$3E,$7E,$2C    ;
  DEFB $FE,$5C,$7E,$24    ;
  DEFB $FC,$68,$3C,$18    ;
  DEFB $78,$30,$18,$00    ;
  DEFB $30,$00,$00,$00    ;

; Sprite for graphics 57, 89
;
; 16 by 16 pixels.
SPRITE57:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$0C,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$1E,$0C    ; row first
  DEFB $00,$00,$3F,$1E    ;
  DEFB $00,$00,$7F,$3E    ;
  DEFB $30,$00,$FE,$7C    ;
  DEFB $79,$30,$FC,$F8    ;
  DEFB $FF,$59,$FC,$F0    ;
  DEFB $FF,$4B,$FE,$0C    ;
  DEFB $7F,$36,$FF,$F6    ;
  DEFB $3F,$0E,$FF,$F2    ;
  DEFB $3F,$1F,$FE,$0C    ;
  DEFB $7F,$3E,$0C,$00    ;
  DEFB $FE,$5C,$00,$00    ;
  DEFB $FC,$68,$00,$00    ;
  DEFB $78,$30,$00,$00    ;
  DEFB $30,$00,$00,$00    ;

; Sprite for graphics 58, 90
;
; 16 by 16 pixels.
SPRITE58:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$0C,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$1E,$0C    ; row first
  DEFB $00,$00,$3F,$0E    ;
  DEFB $00,$00,$7F,$36    ;
  DEFB $00,$00,$FE,$58    ;
  DEFB $01,$00,$FC,$48    ;
  DEFB $03,$00,$F8,$F0    ;
  DEFB $07,$01,$F0,$C0    ;
  DEFB $0F,$06,$E0,$80    ;
  DEFB $1F,$0F,$C0,$00    ;
  DEFB $3F,$1F,$80,$00    ;
  DEFB $7F,$3E,$00,$00    ;
  DEFB $FE,$5C,$00,$00    ;
  DEFB $FC,$68,$00,$00    ;
  DEFB $78,$30,$00,$00    ;
  DEFB $30,$00,$00,$00    ;

; Sprite for graphics 59, 91
;
; 16 by 16 pixels.
SPRITE59:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $03,$00,$0C,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $07,$03,$9E,$0C    ; row first
  DEFB $0F,$05,$FF,$9E    ;
  DEFB $0F,$04,$FF,$BE    ;
  DEFB $07,$03,$FE,$7C    ;
  DEFB $07,$03,$FC,$78    ;
  DEFB $07,$03,$F8,$70    ;
  DEFB $07,$03,$F0,$60    ;
  DEFB $0F,$04,$E0,$C0    ;
  DEFB $1F,$0F,$C0,$80    ;
  DEFB $3F,$1F,$C0,$00    ;
  DEFB $7F,$3E,$E0,$C0    ;
  DEFB $FF,$7D,$F0,$60    ;
  DEFB $FF,$79,$F0,$20    ;
  DEFB $79,$30,$E0,$C0    ;
  DEFB $30,$00,$C0,$00    ;

; Sprite for graphics 60, 92, 143
;
; 16 by 16 pixels.
SPRITE60:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $00,$00,$00,$00    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $1F,$0F,$F8,$70    ;
  DEFB $1F,$0E,$F8,$F0    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 61, 93
;
; 16 by 16 pixels.
SPRITE61:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $00,$00,$00,$00    ; row first
  DEFB $03,$00,$C0,$00    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $3F,$1F,$FC,$B8    ;
  DEFB $3F,$1D,$FC,$F8    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $3F,$1F,$FC,$78    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $00,$00,$00,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 62, 94
;
; 16 by 16 pixels.
SPRITE62:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $03,$00,$C0,$00    ; row first
  DEFB $07,$03,$E0,$C0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $7F,$3C,$FE,$9C    ;
  DEFB $7F,$3C,$FE,$1C    ;
  DEFB $7F,$3E,$FE,$FC    ;
  DEFB $7F,$3C,$FE,$7C    ;
  DEFB $3F,$1E,$FC,$78    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $0F,$07,$F0,$E0    ;
  DEFB $07,$03,$E0,$C0    ;
  DEFB $03,$00,$C0,$00    ;
  DEFB $00,$00,$00,$00    ;

; Sprite for graphics 63, 95
;
; 16 by 16 pixels.
SPRITE63:
  DEFB $02,$10            ; Width in bytes, and height in rows
  DEFB $03,$00,$C0,$00    ; Mask and image bytes, a pair per cell, the bottom
  DEFB $0F,$03,$F0,$C0    ; row first
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $3F,$1F,$FC,$F8    ;
  DEFB $7F,$38,$FE,$FC    ;
  DEFB $7F,$30,$FE,$CC    ;
  DEFB $FF,$70,$FF,$86    ;
  DEFB $FF,$78,$FF,$06    ;
  DEFB $FF,$7E,$FF,$0E    ;
  DEFB $FF,$7C,$FF,$7E    ;
  DEFB $7F,$38,$FE,$3C    ;
  DEFB $7F,$3C,$FE,$3C    ;
  DEFB $3F,$1E,$FC,$78    ;
  DEFB $1F,$0F,$F8,$F0    ;
  DEFB $0F,$03,$F0,$C0    ;
  DEFB $03,$00,$C0,$00    ;

; Sprite for graphics 109, 151
;
; 24 by 36 pixels.
SPRITE109:
  DEFB $03,$24            ; Width in bytes, and height in rows
  DEFB $00,$00,$40,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$E0,$40,$00,$00 ; bottom row first
  DEFB $00,$00,$F8,$60,$00,$00 ;
  DEFB $01,$00,$FC,$F8,$00,$00 ;
  DEFB $00,$00,$FE,$3C,$00,$00 ;
  DEFB $00,$00,$3E,$0C,$00,$00 ;
  DEFB $00,$00,$3E,$18,$00,$00 ;
  DEFB $00,$00,$3F,$0A,$00,$00 ;
  DEFB $00,$00,$3F,$19,$80,$00 ;
  DEFB $00,$00,$7F,$3B,$80,$00 ;
  DEFB $00,$00,$7F,$38,$00,$00 ;
  DEFB $00,$00,$FC,$58,$00,$00 ;
  DEFB $01,$00,$FE,$D4,$00,$00 ;
  DEFB $01,$00,$FF,$D2,$88,$00 ;
  DEFB $20,$00,$FF,$4A,$DC,$88 ;
  DEFB $78,$20,$FF,$41,$DE,$8C ;
  DEFB $FD,$58,$FF,$ED,$FC,$98 ;
  DEFB $F9,$70,$FF,$80,$BC,$18 ;
  DEFB $7F,$38,$FF,$4C,$BC,$18 ;
  DEFB $3F,$14,$FF,$82,$FE,$9C ;
  DEFB $1F,$0A,$FF,$75,$DF,$8A ;
  DEFB $0F,$04,$FF,$82,$FF,$8A ;
  DEFB $0F,$05,$FF,$74,$FF,$E6 ;
  DEFB $0F,$05,$FF,$82,$FF,$1E ;
  DEFB $0F,$05,$FF,$38,$FE,$FC ;
  DEFB $07,$03,$FF,$54,$FC,$C0 ;
  DEFB $0F,$07,$FF,$56,$E0,$C0 ;
  DEFB $0F,$05,$FF,$7F,$C0,$00 ;
  DEFB $07,$02,$FF,$6B,$C0,$80 ;
  DEFB $03,$00,$FF,$D1,$E0,$C0 ;
  DEFB $01,$00,$FF,$8B,$E0,$C0 ;
  DEFB $01,$00,$FF,$9F,$E0,$C0 ;
  DEFB $00,$00,$FF,$7F,$C0,$80 ;
  DEFB $00,$00,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$7F,$3E,$00,$00 ;
  DEFB $00,$00,$3E,$00,$00,$00 ;

; Sprite for graphic 110
;
; 24 by 36 pixels.
SPRITE110:
  DEFB $03,$24            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $06,$00,$00,$00,$C0,$00 ;
  DEFB $0F,$06,$81,$00,$E0,$C0 ;
  DEFB $0F,$07,$F3,$81,$F0,$E0 ;
  DEFB $0F,$07,$FB,$F1,$F8,$70 ;
  DEFB $07,$03,$F3,$61,$FC,$A8 ;
  DEFB $03,$01,$F3,$A1,$F8,$90 ;
  DEFB $03,$01,$E7,$C2,$D0,$80 ;
  DEFB $01,$00,$F7,$A2,$C0,$80 ;
  DEFB $01,$00,$F7,$A3,$C0,$80 ;
  DEFB $03,$01,$FF,$47,$C0,$80 ;
  DEFB $07,$02,$FF,$1B,$A0,$00 ;
  DEFB $07,$02,$FF,$F6,$70,$20 ;
  DEFB $07,$03,$FF,$B8,$F0,$60 ;
  DEFB $07,$03,$FF,$B7,$E0,$C0 ;
  DEFB $03,$00,$FF,$0B,$F0,$E0 ;
  DEFB $03,$00,$FF,$B4,$E0,$00 ;
  DEFB $07,$03,$FC,$B8,$00,$00 ;
  DEFB $0F,$05,$FE,$54,$00,$00 ;
  DEFB $0F,$03,$FF,$EA,$00,$00 ;
  DEFB $0F,$04,$FF,$C5,$80,$00 ;
  DEFB $1F,$0B,$FF,$F4,$C0,$80 ;
  DEFB $0F,$04,$FF,$C2,$C0,$80 ;
  DEFB $1F,$09,$FF,$DB,$80,$00 ;
  DEFB $0F,$01,$FF,$C0,$00,$00 ;
  DEFB $1F,$0E,$FE,$3C,$00,$00 ;
  DEFB $1F,$0D,$FF,$FE,$00,$00 ;
  DEFB $0F,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FE,$FC,$00,$00 ;
  DEFB $03,$01,$FC,$F8,$00,$00 ;
  DEFB $01,$00,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$F0,$00,$00,$00 ;

; Sprite for graphic 111
;
; 24 by 36 pixels.
SPRITE111:
  DEFB $03,$24            ; Width in bytes, and height in rows
  DEFB $00,$00,$30,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$7C,$30,$00,$00 ; bottom row first
  DEFB $00,$00,$FF,$7C,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$7F,$2A,$00,$00 ;
  DEFB $00,$00,$7A,$30,$00,$00 ;
  DEFB $00,$00,$3C,$18,$00,$00 ;
  DEFB $00,$00,$3E,$14,$00,$00 ;
  DEFB $00,$00,$3E,$14,$00,$00 ;
  DEFB $00,$00,$7F,$2E,$00,$00 ;
  DEFB $00,$00,$FF,$4E,$00,$00 ;
  DEFB $01,$00,$FF,$92,$00,$00 ;
  DEFB $03,$01,$FE,$54,$00,$00 ;
  DEFB $07,$02,$FE,$A4,$00,$00 ;
  DEFB $03,$00,$FC,$F8,$00,$00 ;
  DEFB $07,$03,$FC,$B8,$00,$00 ;
  DEFB $07,$03,$F8,$B0,$00,$00 ;
  DEFB $0F,$03,$F0,$00,$60,$00 ;
  DEFB $1F,$08,$F8,$A0,$F0,$60 ;
  DEFB $3F,$13,$FD,$B8,$F8,$F0 ;
  DEFB $7F,$25,$FF,$45,$FC,$68 ;
  DEFB $FF,$73,$FF,$E2,$FE,$D4 ;
  DEFB $FF,$44,$FF,$D6,$DF,$8E ;
  DEFB $FF,$6B,$FF,$F7,$CE,$84 ;
  DEFB $7F,$34,$FF,$C1,$9F,$0A ;
  DEFB $3F,$19,$FF,$DB,$8A,$00 ;
  DEFB $3F,$11,$FF,$C0,$00,$00 ;
  DEFB $1F,$0E,$FE,$3C,$00,$00 ;
  DEFB $1F,$0D,$FF,$FE,$00,$00 ;
  DEFB $0F,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FF,$FE,$00,$00 ;
  DEFB $07,$03,$FE,$FC,$00,$00 ;
  DEFB $03,$01,$FC,$F8,$00,$00 ;
  DEFB $01,$00,$F8,$F0,$00,$00 ;
  DEFB $00,$00,$F0,$00,$00,$00 ;

; Sprite for graphics 104-105, 148-149
;
; 24 by 34 pixels.
SPRITE104:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $07,$00,$E0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $0F,$07,$FC,$E0,$00,$00 ; bottom row first
  DEFB $1F,$0F,$FF,$FC,$00,$00 ;
  DEFB $1F,$0F,$FF,$9F,$80,$00 ;
  DEFB $0F,$07,$FF,$6F,$C0,$80 ;
  DEFB $0F,$07,$FF,$6F,$E0,$C0 ;
  DEFB $07,$03,$FF,$B7,$F0,$E0 ;
  DEFB $07,$03,$FF,$AB,$F8,$F0 ;
  DEFB $07,$01,$FF,$DD,$FC,$F0 ;
  DEFB $07,$02,$FF,$DA,$FC,$88 ;
  DEFB $07,$03,$FF,$3C,$C8,$80 ;
  DEFB $07,$03,$FF,$F9,$C0,$80 ;
  DEFB $0F,$07,$FF,$E6,$C0,$80 ;
  DEFB $0F,$07,$FF,$90,$E0,$40 ;
  DEFB $0F,$07,$FF,$B7,$E0,$80 ;
  DEFB $0F,$07,$FF,$BB,$F0,$A0 ;
  DEFB $0F,$07,$FF,$A9,$F0,$A0 ;
  DEFB $1F,$0F,$FF,$A3,$F0,$20 ;
  DEFB $1F,$0F,$FF,$44,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$42,$E0,$C0 ;
  DEFB $1F,$0E,$FF,$83,$F0,$60 ;
  DEFB $0F,$06,$FF,$81,$F0,$60 ;
  DEFB $07,$01,$FF,$09,$F8,$B0 ;
  DEFB $03,$01,$FF,$2D,$F8,$B0 ;
  DEFB $03,$01,$FF,$61,$FC,$D8 ;
  DEFB $03,$01,$FF,$03,$FC,$D8 ;
  DEFB $03,$01,$FF,$CF,$FE,$CC ;
  DEFB $01,$00,$FF,$FF,$FF,$AE ;
  DEFB $00,$00,$FF,$1E,$FF,$7E ;
  DEFB $60,$00,$1F,$01,$FE,$FC ;
  DEFB $FF,$60,$FF,$1F,$FC,$F0 ;
  DEFB $7F,$1F,$FF,$FF,$F0,$80 ;
  DEFB $1F,$01,$FF,$F8,$80,$00 ;
  DEFB $01,$00,$F8,$00,$00,$00 ;

; Sprite for graphic 72
;
; 24 by 20 pixels.
SPRITE72:
  DEFB $03,$14            ; Width in bytes, and height in rows
  DEFB $00,$00,$3E,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$FF,$1E,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$9F,$80,$00 ;
  DEFB $03,$01,$FF,$9F,$C0,$80 ;
  DEFB $03,$01,$FF,$9F,$C0,$80 ;
  DEFB $03,$01,$FF,$9F,$C0,$80 ;
  DEFB $03,$01,$FF,$9F,$C0,$80 ;
  DEFB $07,$03,$FF,$9F,$E0,$C0 ;
  DEFB $07,$03,$FF,$BF,$E0,$C0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7F,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7F,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7F,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7F,$F0,$E0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $07,$03,$FF,$3F,$E0,$C0 ;
  DEFB $03,$01,$FF,$9F,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$2C,$00,$00 ;
  DEFB $00,$00,$3C,$00,$00,$00 ;

; Sprite for graphics 73, 75
;
; 24 by 20 pixels.
SPRITE73:
  DEFB $03,$14            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$FF,$00,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$07,$FF,$FF,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$39,$FF,$FF,$FE,$FC ;
  DEFB $7F,$39,$FF,$FF,$FE,$FC ;
  DEFB $7F,$38,$FF,$FF,$FE,$FC ;
  DEFB $3F,$1C,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$07,$FF,$3F,$F0,$E0 ;
  DEFB $07,$03,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$CF,$C0,$80 ;
  DEFB $01,$00,$FF,$6E,$80,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphic 74
;
; 24 by 19 pixels.
SPRITE74:
  DEFB $03,$13            ; Width in bytes, and height in rows
  DEFB $01,$00,$FF,$00,$80,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $07,$01,$FF,$FF,$E0,$80 ; bottom row first
  DEFB $1F,$07,$FF,$FF,$F8,$E0 ;
  DEFB $3F,$1B,$FF,$FF,$FC,$F8 ;
  DEFB $7F,$33,$FF,$FF,$FE,$FC ;
  DEFB $FF,$73,$FF,$FF,$FF,$FE ;
  DEFB $FF,$73,$FF,$FF,$FF,$FE ;
  DEFB $7F,$31,$FF,$FF,$FE,$FC ;
  DEFB $7F,$39,$FF,$FF,$FE,$FC ;
  DEFB $7F,$39,$FF,$FF,$FE,$FC ;
  DEFB $3F,$1C,$FF,$FF,$FC,$F8 ;
  DEFB $3F,$1C,$FF,$FF,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$3F,$F8,$F0 ;
  DEFB $0F,$07,$FF,$BF,$F0,$E0 ;
  DEFB $07,$03,$FF,$DF,$E0,$C0 ;
  DEFB $03,$01,$FF,$EF,$C0,$80 ;
  DEFB $01,$00,$FF,$7E,$80,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;

; Sprite for graphic 64
;
; 24 by 17 pixels.
SPRITE64:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$7E,$00,$00,$00 ;
  DEFB $03,$00,$FF,$7E,$80,$00 ;
  DEFB $07,$03,$FF,$FF,$E0,$80 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$3F,$F8,$F0 ;
  DEFB $07,$03,$FF,$3F,$F8,$F0 ;
  DEFB $07,$03,$FF,$9F,$F8,$F0 ;
  DEFB $03,$01,$FF,$CF,$F0,$E0 ;
  DEFB $01,$00,$FF,$63,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$E0,$C0 ;
  DEFB $00,$00,$3F,$0F,$C0,$00 ;
  DEFB $00,$00,$0F,$00,$00,$00 ;

; Sprite for graphics 65, 67
;
; 24 by 17 pixels.
SPRITE65:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$7C,$00,$00,$00 ;
  DEFB $01,$00,$FF,$7C,$80,$00 ;
  DEFB $03,$01,$FF,$FF,$C0,$80 ;
  DEFB $0F,$03,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7F,$E0,$C0 ;
  DEFB $0F,$06,$FF,$7F,$C0,$80 ;
  DEFB $07,$03,$FF,$3F,$80,$00 ;
  DEFB $03,$01,$FF,$9E,$00,$00 ;
  DEFB $01,$00,$FE,$F8,$00,$00 ;
  DEFB $00,$00,$F8,$00,$00,$00 ;

; Sprite for graphic 66
;
; 24 by 17 pixels.
SPRITE66:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $01,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$01,$81,$00,$00,$00 ; bottom row first
  DEFB $03,$01,$C3,$81,$80,$00 ;
  DEFB $01,$00,$C3,$81,$80,$00 ;
  DEFB $01,$00,$FF,$C3,$80,$00 ;
  DEFB $71,$00,$FF,$5A,$80,$00 ;
  DEFB $FF,$71,$FF,$B6,$C0,$80 ;
  DEFB $7F,$1E,$FF,$F9,$FE,$C0 ;
  DEFB $1F,$01,$FF,$FF,$FF,$DE ;
  DEFB $0F,$07,$FF,$FF,$FE,$B0 ;
  DEFB $1F,$03,$FF,$3F,$F0,$C0 ;
  DEFB $7F,$1D,$FF,$3F,$F0,$E0 ;
  DEFB $FF,$73,$FF,$9F,$F8,$C0 ;
  DEFB $73,$00,$FF,$CF,$FC,$B8 ;
  DEFB $07,$03,$FF,$6F,$FE,$0C ;
  DEFB $07,$02,$FF,$3E,$CC,$80 ;
  DEFB $02,$00,$3E,$00,$80,$00 ;

; Sprite for graphics 77, 79
;
; 32 by 17 pixels.
SPRITE77:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$70,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $00,$00,$FC,$70,$00,$00,$00,$00 ; the bottom row first
  DEFB $01,$00,$FE,$FC,$00,$00,$00,$00 ;
  DEFB $01,$00,$FF,$FC,$80,$00,$00,$00 ;
  DEFB $03,$01,$FF,$FF,$E0,$80,$00,$00 ;
  DEFB $07,$03,$FF,$7F,$F0,$E0,$00,$00 ;
  DEFB $03,$01,$FF,$9F,$FF,$F0,$00,$00 ;
  DEFB $01,$00,$FF,$FF,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$FF,$1F,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$3F,$1F,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$1F,$0F,$FF,$FF,$80,$00 ;
  DEFB $00,$00,$3F,$18,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$3F,$1F,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$1F,$00,$FF,$70,$E0,$C0 ;
  DEFB $00,$00,$00,$00,$7F,$3F,$E0,$C0 ;
  DEFB $00,$00,$00,$00,$3F,$01,$C0,$80 ;
  DEFB $00,$00,$00,$00,$01,$00,$80,$00 ;

; Sprite for graphic 78
;
; 32 by 15 pixels.
SPRITE78:
  DEFB $04,$0F            ; Width in bytes, and height in rows
  DEFB $00,$00,$FC,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $01,$00,$FF,$FC,$80,$00,$00,$00 ; the bottom row first
  DEFB $03,$01,$FF,$FF,$C0,$80,$00,$00 ;
  DEFB $07,$03,$FF,$FF,$80,$00,$00,$00 ;
  DEFB $07,$03,$FF,$FE,$F0,$00,$00,$00 ;
  DEFB $03,$01,$FF,$FF,$FC,$F0,$00,$00 ;
  DEFB $03,$01,$FF,$7F,$FE,$FC,$00,$00 ;
  DEFB $07,$03,$FF,$8F,$FF,$FC,$80,$00 ;
  DEFB $03,$00,$FF,$FF,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$FF,$07,$FF,$FF,$E0,$C0 ;
  DEFB $00,$00,$07,$02,$FF,$FF,$E0,$C0 ;
  DEFB $00,$00,$0F,$06,$FF,$3F,$E0,$C0 ;
  DEFB $00,$00,$07,$03,$FF,$CF,$C0,$80 ;
  DEFB $00,$00,$03,$00,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$00,$00,$7F,$00,$00,$00 ;

; Sprite for graphic 76
;
; 32 by 17 pixels.
SPRITE76:
  DEFB $04,$11            ; Width in bytes, and height in rows
  DEFB $03,$00,$80,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell,
  DEFB $07,$03,$E3,$80,$80,$00,$00,$00 ; the bottom row first
  DEFB $0F,$05,$FF,$E3,$C0,$80,$00,$00 ;
  DEFB $0F,$05,$FF,$FF,$E0,$C0,$00,$00 ;
  DEFB $0F,$07,$FF,$FF,$F0,$E0,$00,$00 ;
  DEFB $0F,$02,$FF,$FF,$E0,$C0,$00,$00 ;
  DEFB $1F,$0E,$FF,$1F,$C0,$80,$00,$00 ;
  DEFB $1F,$07,$FF,$FF,$FC,$80,$00,$00 ;
  DEFB $0F,$00,$FF,$3F,$FE,$FC,$00,$00 ;
  DEFB $00,$00,$FF,$7F,$FF,$FE,$00,$00 ;
  DEFB $00,$00,$FF,$61,$FF,$FE,$80,$00 ;
  DEFB $00,$00,$7F,$3E,$FF,$3F,$C0,$80 ;
  DEFB $00,$00,$3F,$03,$FF,$FF,$C0,$80 ;
  DEFB $00,$00,$03,$00,$FF,$2F,$C0,$80 ;
  DEFB $00,$00,$00,$00,$FF,$63,$C0,$80 ;
  DEFB $00,$00,$00,$00,$FF,$7F,$80,$00 ;
  DEFB $00,$00,$00,$00,$7F,$00,$00,$00 ;

; Sprite for graphic 68
;
; 24 by 19 pixels.
SPRITE68:
  DEFB $03,$13            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$13,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$FF,$13,$80,$00 ;
  DEFB $09,$00,$FF,$EB,$80,$00 ;
  DEFB $1D,$08,$FF,$D0,$40,$00 ;
  DEFB $3F,$14,$FF,$34,$E0,$40 ;
  DEFB $1F,$08,$FF,$BB,$DC,$00 ;
  DEFB $0F,$02,$FF,$4B,$FE,$5C ;
  DEFB $0F,$03,$FF,$B6,$FE,$AC ;
  DEFB $1F,$0B,$FF,$7E,$FC,$D0 ;
  DEFB $3F,$15,$FF,$9D,$FE,$E4 ;
  DEFB $1F,$09,$FF,$DF,$FF,$4A ;
  DEFB $0F,$01,$FF,$B7,$EE,$44 ;
  DEFB $1F,$0D,$FF,$5D,$F4,$A0 ;
  DEFB $1F,$0C,$7F,$14,$A0,$00 ;
  DEFB $0C,$00,$7F,$3B,$F0,$20 ;
  DEFB $00,$00,$7F,$37,$A0,$00 ;
  DEFB $00,$00,$3F,$08,$00,$00 ;
  DEFB $00,$00,$08,$00,$00,$00 ;

; Sprite for graphics 69, 71
;
; 24 by 20 pixels.
SPRITE69:
  DEFB $03,$14            ; Width in bytes, and height in rows
  DEFB $00,$00,$01,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$8B,$01,$80,$00 ; bottom row first
  DEFB $01,$00,$DF,$8A,$C0,$80 ;
  DEFB $03,$01,$FB,$41,$E0,$00 ;
  DEFB $05,$00,$FD,$90,$F0,$60 ;
  DEFB $0E,$04,$FE,$0C,$F4,$60 ;
  DEFB $06,$00,$FF,$6E,$EE,$84 ;
  DEFB $07,$02,$FF,$67,$FF,$4A ;
  DEFB $0F,$05,$FF,$3B,$FE,$A4 ;
  DEFB $17,$02,$FF,$D7,$E4,$40 ;
  DEFB $3B,$10,$FF,$AF,$F8,$A0 ;
  DEFB $13,$01,$FF,$7D,$FC,$68 ;
  DEFB $0F,$02,$FF,$FE,$F8,$80 ;
  DEFB $1F,$09,$FF,$6D,$F8,$B0 ;
  DEFB $3F,$14,$7F,$16,$F8,$30 ;
  DEFB $1C,$08,$7F,$29,$B8,$00 ;
  DEFB $08,$00,$FF,$52,$FC,$98 ;
  DEFB $00,$00,$77,$21,$BC,$18 ;
  DEFB $00,$00,$2D,$04,$18,$00 ;
  DEFB $00,$00,$04,$00,$00,$00 ;

; Sprite for graphic 70
;
; 24 by 21 pixels.
SPRITE70:
  DEFB $03,$15            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$B2,$00,$20,$00 ;
  DEFB $01,$00,$FF,$B2,$70,$20 ;
  DEFB $0A,$00,$FE,$34,$F8,$50 ;
  DEFB $1F,$0A,$FF,$4A,$F0,$20 ;
  DEFB $0B,$01,$FF,$B4,$E8,$80 ;
  DEFB $3F,$09,$FF,$5D,$BC,$08 ;
  DEFB $7F,$22,$FF,$FE,$F8,$A0 ;
  DEFB $2F,$02,$FF,$E7,$EC,$40 ;
  DEFB $1F,$09,$FF,$F7,$DE,$8C ;
  DEFB $09,$00,$FF,$FF,$FE,$4C ;
  DEFB $05,$00,$FF,$B6,$EC,$40 ;
  DEFB $0F,$05,$FF,$5B,$DC,$88 ;
  DEFB $05,$00,$FF,$B6,$FE,$94 ;
  DEFB $09,$00,$FF,$4C,$9C,$08 ;
  DEFB $1F,$09,$FF,$1D,$B8,$10 ;
  DEFB $09,$00,$1D,$08,$7C,$28 ;
  DEFB $00,$00,$4B,$01,$B8,$10 ;
  DEFB $00,$00,$E1,$40,$10,$00 ;
  DEFB $00,$00,$40,$00,$00,$00 ;

; Sprite for graphic 124
;
; 24 by 28 pixels.
SPRITE124:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$0C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3E,$0C,$00,$00 ; bottom row first
  DEFB $00,$00,$FF,$36,$80,$00 ;
  DEFB $01,$00,$FF,$EF,$C0,$80 ;
  DEFB $00,$00,$FF,$7F,$E0,$C0 ;
  DEFB $03,$00,$FF,$1F,$F0,$E0 ;
  DEFB $07,$03,$DF,$87,$E0,$C0 ;
  DEFB $0F,$05,$DF,$87,$E0,$C0 ;
  DEFB $1F,$07,$FF,$1B,$C0,$80 ;
  DEFB $3F,$1A,$FF,$FF,$F0,$40 ;
  DEFB $1F,$05,$FF,$F7,$F8,$70 ;
  DEFB $0F,$03,$FF,$F3,$FC,$B8 ;
  DEFB $1F,$0B,$FF,$A3,$FC,$B8 ;
  DEFB $1F,$0B,$FF,$03,$FC,$B8 ;
  DEFB $1F,$0A,$FF,$0B,$FC,$B8 ;
  DEFB $1F,$0A,$FF,$2F,$FC,$B8 ;
  DEFB $1F,$0B,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$0B,$FF,$F7,$F0,$E0 ;
  DEFB $0F,$07,$FF,$A7,$F0,$E0 ;
  DEFB $0F,$03,$FF,$97,$F0,$C0 ;
  DEFB $07,$03,$FF,$37,$F8,$B0 ;
  DEFB $03,$01,$FF,$FF,$F0,$00 ;
  DEFB $01,$00,$FF,$3E,$E0,$C0 ;
  DEFB $01,$00,$FF,$C1,$F0,$E0 ;
  DEFB $01,$00,$FF,$DB,$E0,$00 ;
  DEFB $01,$00,$FF,$D9,$80,$00 ;
  DEFB $01,$00,$DD,$88,$00,$00 ;
  DEFB $00,$00,$88,$00,$00,$00 ;

; Sprite for graphic 125
;
; 24 by 28 pixels.
SPRITE125:
  DEFB $03,$1C            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$01,$00,$80,$00 ; bottom row first
  DEFB $00,$00,$07,$01,$C0,$80 ;
  DEFB $00,$00,$1F,$06,$F0,$C0 ;
  DEFB $02,$00,$3F,$1D,$F8,$F0 ;
  DEFB $1F,$02,$1F,$0F,$FC,$F8 ;
  DEFB $7F,$1B,$CF,$03,$FE,$FC ;
  DEFB $FF,$77,$FF,$C0,$FE,$FC ;
  DEFB $7F,$3F,$FF,$18,$FC,$F8 ;
  DEFB $3F,$0E,$FF,$FC,$F8,$20 ;
  DEFB $0F,$01,$FF,$F5,$E0,$C0 ;
  DEFB $07,$03,$FF,$D5,$F0,$E0 ;
  DEFB $07,$03,$FF,$C2,$F0,$E0 ;
  DEFB $0F,$06,$FF,$8A,$F0,$E0 ;
  DEFB $0F,$06,$FF,$2B,$F0,$60 ;
  DEFB $0F,$06,$FF,$6F,$F0,$60 ;
  DEFB $0F,$06,$FF,$7F,$F8,$F0 ;
  DEFB $0F,$07,$FF,$F7,$F0,$E0 ;
  DEFB $0F,$07,$FF,$A7,$F0,$E0 ;
  DEFB $07,$03,$FF,$97,$F0,$C0 ;
  DEFB $07,$03,$FF,$37,$F8,$B0 ;
  DEFB $03,$01,$FF,$FF,$F0,$00 ;
  DEFB $01,$00,$FF,$3E,$E0,$C0 ;
  DEFB $01,$00,$FF,$C1,$F0,$E0 ;
  DEFB $01,$00,$FF,$DB,$E0,$00 ;
  DEFB $01,$00,$FF,$D9,$80,$00 ;
  DEFB $01,$00,$DD,$88,$00,$00 ;
  DEFB $00,$00,$88,$00,$00,$00 ;

; Sprite for graphic 121
;
; 24 by 26 pixels.
SPRITE121:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$F0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $01,$00,$FE,$F0,$00,$00 ; bottom row first
  DEFB $01,$00,$FF,$7E,$00,$00 ;
  DEFB $01,$00,$FF,$39,$C0,$00 ;
  DEFB $07,$01,$FF,$06,$E0,$C0 ;
  DEFB $0F,$06,$FF,$7D,$F0,$60 ;
  DEFB $0F,$05,$FF,$FD,$F0,$A0 ;
  DEFB $07,$03,$FF,$FD,$F8,$B0 ;
  DEFB $0F,$03,$FF,$FD,$F8,$B0 ;
  DEFB $1F,$0B,$FF,$FF,$F8,$B0 ;
  DEFB $1F,$0B,$FF,$CF,$F8,$F0 ;
  DEFB $1F,$0D,$FF,$17,$F0,$E0 ;
  DEFB $0F,$05,$FF,$47,$F0,$E0 ;
  DEFB $0F,$07,$FF,$8D,$E0,$C0 ;
  DEFB $0F,$07,$FF,$F8,$E0,$C0 ;
  DEFB $07,$03,$FF,$9E,$F0,$E0 ;
  DEFB $07,$03,$FF,$BF,$F8,$F0 ;
  DEFB $03,$01,$FF,$BF,$FC,$F8 ;
  DEFB $01,$00,$FF,$FF,$FC,$38 ;
  DEFB $01,$00,$FF,$FE,$3C,$18 ;
  DEFB $03,$01,$FE,$E0,$1C,$08 ;
  DEFB $03,$01,$E0,$C0,$08,$00 ;
  DEFB $03,$01,$C0,$80,$00,$00 ;
  DEFB $03,$01,$C0,$80,$00,$00 ;
  DEFB $01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$80,$00,$00,$00 ;

; Sprite for graphic 120
;
; 24 by 26 pixels.
SPRITE120:
  DEFB $03,$1A            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3E,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$7F,$3E,$00,$00 ;
  DEFB $1E,$00,$3F,$19,$C0,$00 ;
  DEFB $3F,$1E,$7F,$06,$E0,$C0 ;
  DEFB $3F,$1E,$FF,$7D,$F0,$60 ;
  DEFB $1F,$05,$FF,$FD,$F0,$A0 ;
  DEFB $07,$03,$FF,$FD,$F8,$B0 ;
  DEFB $0F,$03,$FF,$FD,$F8,$B0 ;
  DEFB $1F,$0B,$FF,$FF,$F8,$B0 ;
  DEFB $1F,$0B,$FF,$CF,$F8,$F0 ;
  DEFB $1F,$0D,$FF,$17,$F0,$E0 ;
  DEFB $0F,$05,$FF,$47,$F0,$E0 ;
  DEFB $0F,$07,$FF,$8D,$E0,$C0 ;
  DEFB $0F,$07,$FF,$F8,$E0,$C0 ;
  DEFB $07,$03,$FF,$9E,$F0,$E0 ;
  DEFB $07,$03,$FF,$BF,$F8,$F0 ;
  DEFB $03,$01,$FF,$BF,$FC,$F8 ;
  DEFB $01,$00,$FF,$FF,$FC,$38 ;
  DEFB $01,$00,$FF,$FE,$3C,$18 ;
  DEFB $03,$01,$FE,$E0,$1C,$08 ;
  DEFB $03,$01,$E0,$C0,$08,$00 ;
  DEFB $03,$01,$C0,$80,$00,$00 ;
  DEFB $03,$01,$C0,$80,$00,$00 ;
  DEFB $01,$00,$C0,$80,$00,$00 ;
  DEFB $00,$00,$80,$00,$00,$00 ;

; Sprite for graphic 117
;
; 24 by 29 pixels.
SPRITE117:
  DEFB $03,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$61,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$F7,$61,$B0,$00 ; bottom row first
  DEFB $00,$00,$7F,$37,$F8,$30 ;
  DEFB $00,$00,$3F,$1E,$F0,$E0 ;
  DEFB $0B,$00,$1F,$0F,$F0,$E0 ;
  DEFB $1F,$0B,$BF,$0F,$E0,$C0 ;
  DEFB $1F,$0D,$FF,$B7,$C0,$80 ;
  DEFB $0F,$06,$FF,$7B,$E0,$C0 ;
  DEFB $07,$01,$FF,$FB,$F0,$E0 ;
  DEFB $07,$02,$FF,$1F,$F0,$E0 ;
  DEFB $0F,$04,$FF,$4F,$F8,$F0 ;
  DEFB $0F,$00,$FF,$67,$FC,$F8 ;
  DEFB $0F,$04,$FF,$E3,$FC,$F8 ;
  DEFB $1F,$0C,$FF,$01,$FC,$F8 ;
  DEFB $1F,$0D,$FF,$E1,$FC,$F8 ;
  DEFB $1F,$0B,$FF,$7F,$FC,$F8 ;
  DEFB $0F,$07,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$09,$FF,$C7,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$B3,$F0,$E0 ;
  DEFB $0F,$06,$FF,$33,$FC,$D0 ;
  DEFB $0F,$05,$FF,$03,$FE,$BC ;
  DEFB $07,$03,$FF,$67,$FC,$58 ;
  DEFB $0F,$04,$FF,$7E,$F8,$E0 ;
  DEFB $07,$03,$FF,$C1,$F8,$F0 ;
  DEFB $03,$00,$FF,$FF,$F0,$00 ;
  DEFB $00,$00,$FF,$5B,$C0,$80 ;
  DEFB $00,$00,$FF,$48,$E0,$C0 ;
  DEFB $00,$00,$5C,$08,$C0,$00 ;
  DEFB $00,$00,$08,$00,$00,$00 ;

; Sprite for graphic 116
;
; 24 by 29 pixels.
SPRITE116:
  DEFB $03,$1D            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$31,$00,$00,$00 ; bottom row first
  DEFB $04,$00,$7B,$31,$90,$00 ;
  DEFB $0E,$04,$3F,$1B,$F8,$10 ;
  DEFB $1F,$06,$9F,$0F,$F8,$F0 ;
  DEFB $3F,$1B,$FF,$8F,$F8,$F0 ;
  DEFB $1F,$0D,$FF,$B3,$F0,$E0 ;
  DEFB $0F,$06,$FF,$7B,$E0,$C0 ;
  DEFB $07,$01,$FF,$FB,$F0,$E0 ;
  DEFB $07,$02,$FF,$1F,$F0,$E0 ;
  DEFB $0F,$04,$FF,$4F,$F8,$F0 ;
  DEFB $0F,$00,$FF,$67,$FC,$F8 ;
  DEFB $0F,$04,$FF,$E3,$FC,$F8 ;
  DEFB $1F,$0C,$FF,$01,$FC,$F8 ;
  DEFB $1F,$0D,$FF,$E1,$FC,$F8 ;
  DEFB $1F,$0B,$FF,$7F,$FC,$F8 ;
  DEFB $0F,$07,$FF,$7F,$F8,$F0 ;
  DEFB $1F,$09,$FF,$C7,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$B3,$F0,$E0 ;
  DEFB $0F,$06,$FF,$33,$FC,$D0 ;
  DEFB $0F,$05,$FF,$03,$FE,$BC ;
  DEFB $07,$03,$FF,$67,$FC,$58 ;
  DEFB $0F,$04,$FF,$7E,$F8,$E0 ;
  DEFB $07,$03,$FF,$C1,$F8,$F0 ;
  DEFB $03,$00,$FF,$FF,$F0,$00 ;
  DEFB $00,$00,$FF,$5B,$C0,$80 ;
  DEFB $00,$00,$FF,$48,$E0,$C0 ;
  DEFB $00,$00,$5C,$08,$C0,$00 ;
  DEFB $00,$00,$08,$00,$00,$00 ;

; Sprite for graphic 112
;
; 24 by 31 pixels.
SPRITE112:
  DEFB $03,$1F            ; Width in bytes, and height in rows
  DEFB $00,$00,$1C,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$3F,$1C,$00,$00 ; bottom row first
  DEFB $03,$00,$7F,$3F,$80,$00 ;
  DEFB $07,$03,$FF,$03,$C0,$80 ;
  DEFB $0F,$04,$FF,$FC,$E0,$40 ;
  DEFB $1F,$0B,$FF,$FF,$C0,$80 ;
  DEFB $0F,$07,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$E8,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$FC,$E8 ;
  DEFB $3F,$00,$FF,$3F,$FE,$F4 ;
  DEFB $7F,$21,$FF,$1F,$FE,$F4 ;
  DEFB $7F,$31,$FF,$8F,$FF,$F2 ;
  DEFB $7F,$20,$FF,$05,$FE,$D0 ;
  DEFB $7F,$1F,$FF,$C1,$FE,$D4 ;
  DEFB $FF,$7F,$FF,$F9,$FF,$E6 ;
  DEFB $7F,$3F,$FF,$FD,$FE,$F0 ;
  DEFB $3F,$07,$FF,$FD,$FE,$F4 ;
  DEFB $3F,$18,$FF,$04,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$4A,$FC,$F8 ;
  DEFB $3F,$1E,$FF,$DA,$FC,$78 ;
  DEFB $3F,$1E,$FF,$02,$FE,$3C ;
  DEFB $3F,$1D,$FF,$27,$FE,$3C ;
  DEFB $7F,$1C,$FF,$FE,$3E,$1C ;
  DEFB $FC,$58,$FF,$76,$3E,$1C ;
  DEFB $7C,$38,$7F,$32,$1E,$0C ;
  DEFB $7E,$1C,$72,$20,$3E,$0C ;
  DEFB $FE,$7C,$20,$00,$7E,$3C ;
  DEFB $7C,$18,$00,$00,$3E,$1C ;
  DEFB $78,$30,$00,$00,$7E,$34 ;
  DEFB $30,$00,$00,$00,$34,$00 ;

; Sprite for graphic 113
;
; 24 by 31 pixels.
SPRITE113:
  DEFB $03,$1F            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1E,$00,$00,$00 ; bottom row first
  DEFB $0F,$00,$3F,$1E,$80,$00 ;
  DEFB $1F,$0F,$FF,$03,$C0,$80 ;
  DEFB $3F,$1C,$FF,$FC,$E0,$40 ;
  DEFB $1F,$0B,$FF,$FF,$C0,$80 ;
  DEFB $0F,$07,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$E8,$C0 ;
  DEFB $1F,$0F,$FF,$FF,$FC,$E8 ;
  DEFB $3F,$00,$FF,$3F,$FE,$F4 ;
  DEFB $7F,$21,$FF,$1F,$FE,$F4 ;
  DEFB $7F,$31,$FF,$8F,$FF,$F2 ;
  DEFB $7F,$20,$FF,$05,$FE,$D0 ;
  DEFB $7F,$1F,$FF,$C1,$FE,$D4 ;
  DEFB $FF,$7F,$FF,$F9,$FF,$E6 ;
  DEFB $7F,$3F,$FF,$FD,$FE,$E0 ;
  DEFB $3F,$07,$FF,$FD,$FE,$F4 ;
  DEFB $1F,$08,$FF,$05,$FC,$F0 ;
  DEFB $1F,$0E,$FF,$4A,$F8,$F0 ;
  DEFB $1F,$0E,$FF,$DA,$FC,$F8 ;
  DEFB $1F,$0E,$FF,$02,$FC,$78 ;
  DEFB $0F,$07,$FF,$27,$FC,$78 ;
  DEFB $0F,$07,$FF,$FE,$FC,$38 ;
  DEFB $2F,$07,$FF,$76,$F8,$30 ;
  DEFB $7F,$27,$FF,$32,$F8,$70 ;
  DEFB $3F,$1E,$73,$20,$F0,$60 ;
  DEFB $1F,$06,$27,$03,$F8,$F0 ;
  DEFB $3F,$1B,$83,$00,$F8,$50 ;
  DEFB $1F,$06,$01,$00,$F8,$D0 ;
  DEFB $06,$00,$00,$00,$D0,$00 ;

; Sprite for graphics 100-101, 146-147
;
; 24 by 34 pixels.
SPRITE100:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $01,$00,$FE,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$01,$FF,$B6,$80,$00 ; bottom row first
  DEFB $0F,$03,$FF,$B7,$E0,$80 ;
  DEFB $1F,$0E,$FF,$BF,$F0,$60 ;
  DEFB $3F,$1E,$FF,$BF,$F8,$70 ;
  DEFB $1F,$0E,$FF,$FF,$FC,$78 ;
  DEFB $1F,$0F,$FF,$FB,$FE,$FC ;
  DEFB $0F,$05,$FF,$F5,$FF,$F6 ;
  DEFB $0F,$07,$FF,$65,$E6,$E0 ;
  DEFB $0F,$06,$FF,$AD,$E0,$C0 ;
  DEFB $07,$02,$FF,$DD,$C0,$80 ;
  DEFB $07,$02,$FF,$ED,$C0,$80 ;
  DEFB $07,$02,$FF,$F5,$E0,$C0 ;
  DEFB $07,$02,$FF,$FB,$E0,$C0 ;
  DEFB $07,$02,$FF,$FD,$E0,$C0 ;
  DEFB $07,$02,$FF,$FE,$E0,$C0 ;
  DEFB $0F,$06,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$06,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$06,$FF,$43,$F0,$E0 ;
  DEFB $0F,$07,$FF,$BB,$F0,$E0 ;
  DEFB $1F,$0F,$FF,$FF,$E0,$C0 ;
  DEFB $1F,$0F,$FF,$DF,$C0,$80 ;
  DEFB $1F,$0F,$FF,$8F,$80,$00 ;
  DEFB $0F,$07,$FF,$03,$C0,$80 ;
  DEFB $07,$01,$FF,$03,$C0,$80 ;
  DEFB $03,$01,$FF,$0B,$C0,$80 ;
  DEFB $03,$01,$FF,$5B,$C0,$80 ;
  DEFB $03,$01,$FF,$63,$E0,$C0 ;
  DEFB $03,$01,$FF,$03,$E0,$C0 ;
  DEFB $01,$00,$FF,$C7,$E0,$C0 ;
  DEFB $00,$00,$FF,$3F,$F0,$E0 ;
  DEFB $00,$00,$3F,$01,$F8,$F0 ;
  DEFB $00,$00,$01,$00,$F8,$70 ;
  DEFB $00,$00,$00,$00,$70,$00 ;

; Sprite for graphics 102-103
;
; 24 by 34 pixels.
SPRITE102:
  DEFB $03,$22            ; Width in bytes, and height in rows
  DEFB $63,$00,$F8,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $FF,$63,$FF,$D0,$00,$00 ; bottom row first
  DEFB $7F,$3C,$FF,$ED,$C0,$00 ;
  DEFB $3F,$1F,$FF,$6D,$F0,$C0 ;
  DEFB $1F,$07,$FF,$B6,$F8,$D0 ;
  DEFB $07,$03,$FF,$D6,$FC,$B8 ;
  DEFB $03,$01,$FF,$DA,$FE,$BC ;
  DEFB $03,$01,$FF,$EB,$FC,$B8 ;
  DEFB $03,$01,$FF,$EF,$F8,$F0 ;
  DEFB $01,$00,$FF,$EF,$F8,$F0 ;
  DEFB $01,$00,$FF,$FF,$F8,$F0 ;
  DEFB $01,$00,$FF,$FF,$F8,$F0 ;
  DEFB $00,$00,$FF,$7F,$F0,$E0 ;
  DEFB $00,$00,$FF,$7F,$E0,$C0 ;
  DEFB $00,$00,$FF,$7F,$E0,$C0 ;
  DEFB $00,$00,$FF,$7F,$F0,$E0 ;
  DEFB $01,$00,$FF,$DF,$F0,$E0 ;
  DEFB $01,$00,$FF,$DF,$F0,$E0 ;
  DEFB $01,$00,$FF,$DF,$F8,$F0 ;
  DEFB $03,$01,$FF,$DF,$F8,$F0 ;
  DEFB $03,$01,$FF,$BF,$F8,$F0 ;
  DEFB $03,$01,$FF,$BF,$F8,$F0 ;
  DEFB $03,$01,$FF,$BF,$F0,$E0 ;
  DEFB $01,$00,$FF,$FF,$E0,$80 ;
  DEFB $00,$00,$FF,$7F,$E0,$C0 ;
  DEFB $01,$00,$FF,$FF,$F0,$E0 ;
  DEFB $07,$01,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$07,$FF,$FF,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$F8,$F0 ;
  DEFB $0F,$03,$FF,$FF,$F0,$E0 ;
  DEFB $03,$00,$FF,$7F,$E0,$C0 ;
  DEFB $00,$00,$7F,$07,$C0,$80 ;
  DEFB $00,$00,$07,$00,$80,$00 ;

; Sprite for graphics 33, 37
;
; 24 by 24 pixels.
SPRITE33:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$0E,$00,$00,$00 ;
  DEFB $0E,$00,$3F,$0E,$F8,$20 ;
  DEFB $3F,$0E,$FF,$3F,$FC,$B8 ;
  DEFB $7F,$3D,$FF,$DF,$FC,$88 ;
  DEFB $FF,$7B,$FF,$FF,$F8,$D0 ;
  DEFB $FF,$63,$FF,$FE,$FC,$38 ;
  DEFB $63,$01,$FF,$F9,$F8,$C0 ;
  DEFB $01,$00,$FF,$F7,$F0,$E0 ;
  DEFB $00,$00,$FF,$6F,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $00,$00,$FF,$37,$F8,$F0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $01,$00,$FF,$E7,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$F0,$E0 ;
  DEFB $00,$00,$3F,$1D,$E0,$C0 ;
  DEFB $00,$00,$1F,$06,$C0,$80 ;
  DEFB $00,$00,$07,$01,$80,$00 ;

; Sprite for graphics 42, 44
;
; 24 by 25 pixels.
SPRITE42:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $07,$03,$80,$00,$00,$00 ;
  DEFB $0F,$07,$80,$00,$00,$00 ;
  DEFB $0F,$07,$80,$00,$00,$00 ;
  DEFB $1F,$0E,$38,$00,$04,$00 ;
  DEFB $1F,$0E,$FF,$38,$0E,$04 ;
  DEFB $3F,$18,$FF,$FF,$9F,$0E ;
  DEFB $3F,$17,$FF,$7F,$FE,$1C ;
  DEFB $1F,$0F,$FF,$7E,$FC,$E8 ;
  DEFB $1F,$0F,$FF,$FE,$F8,$E0 ;
  DEFB $0F,$07,$FF,$FF,$E0,$C0 ;
  DEFB $07,$00,$FF,$31,$E0,$C0 ;
  DEFB $07,$03,$FF,$C6,$C0,$80 ;
  DEFB $0F,$06,$FF,$46,$C0,$00 ;
  DEFB $0F,$06,$FF,$55,$E0,$40 ;
  DEFB $0F,$06,$FF,$5B,$E0,$40 ;
  DEFB $0F,$06,$FF,$40,$E0,$40 ;
  DEFB $07,$03,$FF,$7C,$E0,$C0 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$36,$00,$00 ;
  DEFB $00,$00,$3E,$08,$00,$00 ;

; Sprite for graphic 38
;
; 24 by 24 pixels.
SPRITE38:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $0F,$00,$0E,$00,$20,$00 ;
  DEFB $3F,$0F,$BF,$0E,$F0,$20 ;
  DEFB $7F,$3E,$FF,$BF,$F0,$A0 ;
  DEFB $7F,$35,$FF,$DF,$F8,$B0 ;
  DEFB $3F,$03,$FF,$DF,$FC,$C8 ;
  DEFB $07,$03,$FF,$FF,$F8,$F0 ;
  DEFB $03,$00,$FF,$FE,$F8,$10 ;
  DEFB $01,$00,$FF,$3E,$F0,$E0 ;
  DEFB $03,$01,$FF,$C5,$F8,$F0 ;
  DEFB $03,$01,$FF,$B3,$F8,$F0 ;
  DEFB $01,$00,$FF,$53,$F8,$F0 ;
  DEFB $00,$00,$FF,$63,$F8,$F0 ;
  DEFB $00,$00,$7F,$0F,$F8,$F0 ;
  DEFB $01,$00,$FF,$77,$F8,$F0 ;
  DEFB $03,$01,$FF,$E7,$F0,$E0 ;
  DEFB $01,$00,$FF,$E7,$F0,$E0 ;
  DEFB $00,$00,$FF,$77,$E0,$C0 ;
  DEFB $00,$00,$7F,$3B,$C0,$80 ;
  DEFB $00,$00,$3F,$0D,$80,$00 ;
  DEFB $00,$00,$0F,$02,$00,$00 ;

; Sprite for graphic 32
;
; 24 by 24 pixels.
SPRITE32:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$1C,$00 ;
  DEFB $00,$00,$0E,$00,$7E,$1C ;
  DEFB $18,$00,$7F,$0E,$FE,$7C ;
  DEFB $3D,$18,$FF,$7F,$FE,$A8 ;
  DEFB $3F,$1D,$FF,$BF,$FE,$84 ;
  DEFB $7F,$3B,$FF,$DF,$FC,$D8 ;
  DEFB $7F,$37,$FF,$FE,$FC,$38 ;
  DEFB $F7,$63,$FF,$F9,$F8,$C0 ;
  DEFB $F3,$61,$FF,$F7,$F0,$E0 ;
  DEFB $61,$00,$FF,$6F,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $00,$00,$FF,$37,$F8,$F0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $01,$00,$FF,$E7,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$F0,$E0 ;
  DEFB $00,$00,$3F,$1D,$E0,$C0 ;
  DEFB $00,$00,$1F,$06,$C0,$80 ;
  DEFB $00,$00,$07,$01,$80,$00 ;

; Sprite for graphic 35
;
; 24 by 24 pixels.
SPRITE35:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $03,$00,$80,$00,$00,$00 ;
  DEFB $0F,$03,$CE,$80,$00,$00 ;
  DEFB $1F,$0F,$FF,$8E,$80,$00 ;
  DEFB $3F,$1C,$FF,$6F,$C0,$80 ;
  DEFB $3F,$11,$FF,$EF,$E0,$C0 ;
  DEFB $13,$01,$FF,$EF,$F0,$E0 ;
  DEFB $01,$00,$FF,$FE,$F0,$20 ;
  DEFB $01,$00,$FF,$F9,$E0,$C0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$FF,$6F,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $00,$00,$FF,$37,$F8,$F0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $01,$00,$FF,$E7,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$F0,$E0 ;
  DEFB $00,$00,$3F,$1D,$E0,$C0 ;
  DEFB $00,$00,$1F,$06,$C0,$80 ;
  DEFB $00,$00,$07,$01,$80,$00 ;

; Sprite for graphics 34, 36
;
; 24 by 24 pixels.
SPRITE34:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $07,$00,$0E,$00,$60,$00 ;
  DEFB $1F,$07,$DF,$0E,$F0,$60 ;
  DEFB $3F,$1E,$FF,$5F,$F0,$A0 ;
  DEFB $7F,$39,$FF,$DF,$F8,$90 ;
  DEFB $7F,$23,$FF,$DF,$F0,$E0 ;
  DEFB $23,$01,$FF,$FE,$F8,$30 ;
  DEFB $01,$00,$FF,$F9,$F0,$C0 ;
  DEFB $01,$00,$FF,$F7,$F0,$E0 ;
  DEFB $00,$00,$FF,$6F,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $01,$00,$FF,$CF,$F8,$F0 ;
  DEFB $00,$00,$FF,$37,$F8,$F0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $01,$00,$FF,$E7,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$F0,$E0 ;
  DEFB $00,$00,$3F,$1D,$E0,$C0 ;
  DEFB $00,$00,$1F,$06,$C0,$80 ;
  DEFB $00,$00,$07,$01,$80,$00 ;

; Sprite for graphic 43
;
; 24 by 25 pixels.
SPRITE43:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $01,$00,$C0,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$01,$E0,$C0,$00,$00 ; bottom row first
  DEFB $07,$03,$C0,$80,$00,$00 ;
  DEFB $0F,$07,$80,$00,$00,$00 ;
  DEFB $0F,$07,$B8,$00,$00,$00 ;
  DEFB $1F,$0F,$FF,$38,$08,$00 ;
  DEFB $1F,$0C,$FF,$7F,$9C,$08 ;
  DEFB $0F,$03,$FF,$BF,$BE,$1C ;
  DEFB $1F,$0F,$FF,$BE,$FC,$B8 ;
  DEFB $1F,$0F,$FF,$FE,$F8,$D0 ;
  DEFB $0F,$07,$FF,$FF,$F0,$C0 ;
  DEFB $07,$03,$FF,$F1,$E0,$C0 ;
  DEFB $03,$00,$FF,$00,$C0,$80 ;
  DEFB $07,$03,$FF,$C6,$80,$00 ;
  DEFB $0F,$06,$FF,$46,$C0,$00 ;
  DEFB $0F,$06,$FF,$55,$E0,$40 ;
  DEFB $0F,$06,$FF,$5B,$E0,$40 ;
  DEFB $0F,$06,$FF,$40,$E0,$40 ;
  DEFB $07,$03,$FF,$7C,$E0,$C0 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$36,$00,$00 ;
  DEFB $00,$00,$3E,$08,$00,$00 ;

; Sprite for graphic 40
;
; 24 by 25 pixels.
SPRITE40:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $0C,$00,$00,$00,$00,$00 ;
  DEFB $1E,$0C,$00,$00,$06,$00 ;
  DEFB $3E,$1C,$38,$00,$0F,$06 ;
  DEFB $3C,$18,$FF,$38,$3F,$0E ;
  DEFB $7F,$38,$FF,$FF,$FE,$3C ;
  DEFB $7F,$37,$FF,$FF,$FC,$58 ;
  DEFB $7F,$2F,$FF,$7E,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$FE,$F8,$F0 ;
  DEFB $3F,$1F,$FF,$FF,$F0,$E0 ;
  DEFB $1F,$07,$FF,$F1,$E0,$C0 ;
  DEFB $07,$00,$FF,$00,$C0,$80 ;
  DEFB $07,$03,$FF,$C6,$80,$00 ;
  DEFB $0F,$06,$FF,$46,$C0,$00 ;
  DEFB $0F,$06,$FF,$55,$E0,$40 ;
  DEFB $0F,$06,$FF,$5B,$E0,$40 ;
  DEFB $0F,$06,$FF,$40,$E0,$40 ;
  DEFB $07,$03,$FF,$7C,$E0,$C0 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$36,$00,$00 ;
  DEFB $00,$00,$3E,$08,$00,$00 ;

; Sprite for graphics 41, 45
;
; 24 by 25 pixels.
SPRITE41:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $06,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $0F,$06,$00,$00,$00,$00 ;
  DEFB $1F,$0E,$00,$00,$06,$00 ;
  DEFB $3E,$1C,$38,$00,$1F,$06 ;
  DEFB $3E,$1C,$FF,$38,$3F,$1E ;
  DEFB $3F,$18,$FF,$FF,$FF,$3E ;
  DEFB $7F,$36,$FF,$FF,$FE,$58 ;
  DEFB $3F,$0F,$FF,$7E,$F8,$E0 ;
  DEFB $3F,$1F,$FF,$FE,$F8,$F0 ;
  DEFB $1F,$0F,$FF,$FF,$F0,$E0 ;
  DEFB $0F,$07,$FF,$F1,$E0,$C0 ;
  DEFB $07,$00,$FF,$00,$C0,$80 ;
  DEFB $07,$03,$FF,$C6,$80,$00 ;
  DEFB $0F,$06,$FF,$46,$C0,$00 ;
  DEFB $0F,$06,$FF,$55,$E0,$40 ;
  DEFB $0F,$06,$FF,$5B,$E0,$40 ;
  DEFB $0F,$06,$FF,$40,$E0,$40 ;
  DEFB $07,$03,$FF,$7C,$E0,$C0 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$36,$00,$00 ;
  DEFB $00,$00,$3E,$08,$00,$00 ;

; Sprite for graphic 39
;
; 24 by 25 pixels.
SPRITE39:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$0E,$00,$20,$00 ;
  DEFB $0E,$00,$3F,$0E,$F8,$20 ;
  DEFB $3F,$0E,$FF,$3F,$FC,$B8 ;
  DEFB $7F,$3D,$FF,$DF,$FC,$88 ;
  DEFB $FF,$7B,$FF,$DF,$F8,$D0 ;
  DEFB $FF,$63,$FF,$C1,$FC,$F8 ;
  DEFB $63,$01,$FF,$9E,$F8,$30 ;
  DEFB $01,$00,$FF,$7F,$F0,$A0 ;
  DEFB $01,$00,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$9F,$E0,$C0 ;
  DEFB $03,$01,$FF,$9F,$F0,$E0 ;
  DEFB $03,$01,$FF,$9F,$F8,$F0 ;
  DEFB $03,$01,$FF,$CF,$F8,$F0 ;
  DEFB $01,$00,$FF,$EF,$F8,$F0 ;
  DEFB $01,$00,$FF,$EF,$F0,$E0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$37,$E0,$C0 ;
  DEFB $00,$00,$3F,$1B,$C0,$00 ;
  DEFB $00,$00,$1F,$04,$00,$00 ;

; Sprite for graphic 46
;
; 24 by 25 pixels.
SPRITE46:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $07,$03,$80,$00,$00,$00 ;
  DEFB $0F,$07,$80,$00,$00,$00 ;
  DEFB $1F,$0E,$38,$00,$04,$00 ;
  DEFB $1F,$0E,$FF,$38,$0E,$04 ;
  DEFB $3F,$18,$FF,$FF,$9F,$0E ;
  DEFB $3F,$17,$FF,$7F,$FE,$1C ;
  DEFB $1F,$0F,$FF,$7E,$FC,$E8 ;
  DEFB $1F,$0F,$FF,$FE,$F8,$E0 ;
  DEFB $0F,$07,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$F1,$E0,$C0 ;
  DEFB $03,$01,$FF,$CE,$C0,$00 ;
  DEFB $03,$00,$FF,$1D,$C0,$80 ;
  DEFB $07,$02,$FF,$1C,$E0,$C0 ;
  DEFB $0F,$06,$FF,$9C,$E0,$C0 ;
  DEFB $0F,$05,$FF,$BC,$E0,$C0 ;
  DEFB $07,$00,$FF,$3C,$E0,$C0 ;
  DEFB $07,$03,$FF,$FD,$E0,$C0 ;
  DEFB $0F,$07,$FF,$F9,$C0,$80 ;
  DEFB $0F,$07,$FF,$FB,$C0,$80 ;
  DEFB $07,$03,$FF,$F7,$80,$00 ;
  DEFB $03,$01,$FF,$EE,$00,$00 ;
  DEFB $01,$00,$FE,$D8,$00,$00 ;
  DEFB $00,$00,$F8,$20,$00,$00 ;

; Sprite for graphic 47
;
; 24 by 25 pixels.
SPRITE47:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $03,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $07,$03,$80,$00,$00,$00 ;
  DEFB $0F,$07,$80,$00,$00,$00 ;
  DEFB $1F,$0E,$38,$00,$00,$00 ;
  DEFB $3F,$1E,$FF,$38,$18,$00 ;
  DEFB $3F,$11,$FF,$7F,$FC,$18 ;
  DEFB $3F,$0F,$FF,$7F,$FE,$7C ;
  DEFB $3F,$1F,$FF,$BE,$FC,$B8 ;
  DEFB $1F,$0F,$FF,$FE,$F8,$C0 ;
  DEFB $0F,$03,$FF,$FF,$E0,$C0 ;
  DEFB $03,$00,$FF,$01,$C0,$80 ;
  DEFB $03,$01,$FF,$F0,$80,$00 ;
  DEFB $07,$02,$FF,$78,$E0,$00 ;
  DEFB $0F,$06,$FF,$7C,$F0,$60 ;
  DEFB $0F,$06,$FF,$7C,$F0,$A0 ;
  DEFB $0F,$06,$FF,$7C,$E0,$C0 ;
  DEFB $0F,$06,$FF,$7E,$C0,$00 ;
  DEFB $07,$03,$FF,$7F,$C0,$00 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$3F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$DF,$80,$00 ;
  DEFB $00,$00,$FF,$6E,$00,$00 ;
  DEFB $00,$00,$7E,$18,$00,$00 ;

; Sprite for graphic 30
;
; 24 by 25 pixels.
SPRITE30:
  DEFB $03,$19            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$38,$00,$00,$00 ;
  DEFB $02,$00,$FF,$38,$00,$00 ;
  DEFB $1F,$02,$FF,$FF,$80,$00 ;
  DEFB $3F,$1B,$FF,$7F,$E8,$00 ;
  DEFB $3F,$1B,$FF,$7F,$FC,$68 ;
  DEFB $7F,$37,$FF,$FE,$FC,$E8 ;
  DEFB $7F,$37,$FF,$FF,$FE,$DC ;
  DEFB $FF,$63,$FF,$F1,$FE,$CC ;
  DEFB $FF,$60,$FF,$00,$CF,$86 ;
  DEFB $6F,$03,$FF,$C6,$8F,$06 ;
  DEFB $0F,$06,$FF,$46,$C6,$00 ;
  DEFB $0F,$06,$FF,$55,$E0,$40 ;
  DEFB $0F,$06,$FF,$5B,$E0,$40 ;
  DEFB $0F,$06,$FF,$40,$E0,$40 ;
  DEFB $07,$03,$FF,$7C,$E0,$C0 ;
  DEFB $07,$03,$FF,$7F,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$E0,$C0 ;
  DEFB $03,$01,$FF,$BF,$C0,$80 ;
  DEFB $01,$00,$FF,$CF,$80,$00 ;
  DEFB $00,$00,$FF,$36,$00,$00 ;
  DEFB $00,$00,$3E,$08,$00,$00 ;

; Sprite for graphic 22
;
; 24 by 24 pixels.
SPRITE22:
  DEFB $03,$18            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$0E,$00,$00,$00 ;
  DEFB $00,$00,$3F,$0E,$80,$00 ;
  DEFB $0F,$00,$FF,$3F,$E8,$80 ;
  DEFB $1F,$0D,$FF,$DF,$FC,$E8 ;
  DEFB $3F,$1D,$FF,$DF,$FE,$F4 ;
  DEFB $7F,$3F,$FF,$FE,$FF,$36 ;
  DEFB $FF,$7B,$FF,$F9,$FF,$C6 ;
  DEFB $FB,$70,$FF,$F7,$FF,$E3 ;
  DEFB $F0,$60,$FF,$6F,$FF,$F2 ;
  DEFB $F1,$60,$FF,$CF,$FA,$F0 ;
  DEFB $61,$00,$FF,$CF,$F8,$F0 ;
  DEFB $00,$00,$FF,$37,$F8,$F0 ;
  DEFB $00,$00,$FF,$67,$F8,$F0 ;
  DEFB $01,$00,$FF,$E7,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F8,$F0 ;
  DEFB $00,$00,$FF,$77,$F0,$E0 ;
  DEFB $00,$00,$7F,$3B,$F0,$E0 ;
  DEFB $00,$00,$3F,$1D,$E0,$C0 ;
  DEFB $00,$00,$1F,$06,$C0,$80 ;
  DEFB $00,$00,$07,$01,$80,$00 ;

; Sprite for graphic 19
;
; 24 by 16 pixels.
SPRITE19:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$E0,$00 ;
  DEFB $00,$00,$03,$00,$F0,$E0 ;
  DEFB $06,$00,$07,$03,$F0,$E0 ;
  DEFB $0F,$06,$0F,$07,$F0,$E0 ;
  DEFB $3F,$0F,$9F,$0E,$E0,$00 ;
  DEFB $7F,$3F,$8F,$01,$E0,$C0 ;
  DEFB $FF,$78,$0F,$00,$C0,$80 ;
  DEFB $7F,$06,$5F,$0D,$C0,$00 ;
  DEFB $0F,$06,$FF,$4D,$E0,$C0 ;
  DEFB $0F,$06,$FF,$ED,$F0,$A0 ;
  DEFB $0F,$05,$FF,$75,$F0,$A0 ;
  DEFB $07,$03,$FF,$B7,$E0,$40 ;
  DEFB $03,$01,$FF,$DF,$E0,$C0 ;
  DEFB $01,$00,$F1,$71,$E0,$C0 ;

; Sprite for graphics 18, 20
;
; 24 by 16 pixels.
SPRITE18:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$C0,$00,$00,$00 ;
  DEFB $03,$00,$E3,$C0,$80,$00 ;
  DEFB $07,$03,$FF,$E3,$C0,$80 ;
  DEFB $0F,$07,$FF,$EF,$C0,$80 ;
  DEFB $1F,$0F,$FF,$1E,$C0,$00 ;
  DEFB $0F,$00,$FF,$F1,$80,$00 ;
  DEFB $01,$00,$FF,$C6,$C0,$00 ;
  DEFB $01,$00,$FF,$B6,$E0,$C0 ;
  DEFB $03,$00,$FF,$76,$E0,$C0 ;
  DEFB $07,$03,$FF,$B6,$F0,$E0 ;
  DEFB $07,$03,$FF,$B6,$F0,$E0 ;
  DEFB $03,$01,$FF,$DF,$F0,$A0 ;
  DEFB $01,$00,$FF,$7F,$E0,$40 ;
  DEFB $00,$00,$71,$31,$E0,$C0 ;

; Sprite for graphics 17, 21
;
; 24 by 16 pixels.
SPRITE17:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$18,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$7C,$18,$00,$00 ;
  DEFB $00,$00,$FE,$7C,$00,$00 ;
  DEFB $01,$00,$FE,$FC,$00,$00 ;
  DEFB $03,$01,$FF,$E2,$00,$00 ;
  DEFB $01,$00,$FF,$1A,$00,$00 ;
  DEFB $01,$00,$FF,$32,$00,$00 ;
  DEFB $03,$01,$FE,$64,$80,$00 ;
  DEFB $03,$01,$FF,$56,$C0,$80 ;
  DEFB $01,$00,$FF,$B6,$E0,$80 ;
  DEFB $03,$01,$FF,$D5,$F0,$A0 ;
  DEFB $01,$00,$FF,$D5,$E0,$40 ;
  DEFB $01,$00,$FF,$DF,$E0,$C0 ;
  DEFB $00,$00,$FF,$7F,$E0,$C0 ;
  DEFB $00,$00,$F1,$71,$E0,$C0 ;

; Sprite for graphic 16
;
; 24 by 16 pixels.
SPRITE16:
  DEFB $03,$10            ; Width in bytes, and height in rows
  DEFB $00,$00,$06,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$1F,$06,$00,$00 ; bottom row first
  DEFB $00,$00,$3F,$1F,$80,$00 ;
  DEFB $00,$00,$7F,$3F,$80,$00 ;
  DEFB $00,$00,$FF,$70,$00,$00 ;
  DEFB $00,$00,$7F,$06,$00,$00 ;
  DEFB $00,$00,$FE,$0C,$00,$00 ;
  DEFB $01,$00,$FC,$D8,$00,$00 ;
  DEFB $03,$01,$FF,$D0,$00,$00 ;
  DEFB $07,$03,$FF,$8B,$80,$00 ;
  DEFB $03,$00,$FF,$5B,$E0,$00 ;
  DEFB $01,$00,$FF,$DD,$F0,$60 ;
  DEFB $03,$00,$FF,$ED,$F0,$60 ;
  DEFB $07,$03,$FF,$3F,$F0,$60 ;
  DEFB $07,$03,$FF,$DF,$E0,$C0 ;
  DEFB $03,$00,$F1,$F1,$E0,$C0 ;

; Sprite for graphic 27
;
; 24 by 17 pixels.
SPRITE27:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$38,$00 ;
  DEFB $00,$00,$00,$00,$FC,$38 ;
  DEFB $07,$00,$03,$00,$FC,$F8 ;
  DEFB $1F,$07,$87,$03,$F8,$F0 ;
  DEFB $3F,$1E,$0F,$07,$F0,$C0 ;
  DEFB $7E,$3C,$07,$03,$C0,$00 ;
  DEFB $FF,$70,$03,$01,$C0,$80 ;
  DEFB $FF,$6F,$B3,$00,$E0,$C0 ;
  DEFB $7F,$12,$FF,$B3,$F0,$20 ;
  DEFB $1F,$05,$FF,$B6,$E0,$40 ;
  DEFB $1F,$0D,$FF,$B6,$F0,$60 ;
  DEFB $3F,$1E,$FF,$FC,$E0,$C0 ;
  DEFB $1F,$06,$FF,$FF,$E0,$C0 ;
  DEFB $07,$03,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$C7,$C7,$80,$00 ;

; Sprite for graphics 26, 28
;
; 24 by 17 pixels.
SPRITE26:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$E0,$00,$E0,$00 ;
  DEFB $03,$00,$F3,$E0,$F0,$E0 ;
  DEFB $07,$03,$EF,$C3,$E0,$C0 ;
  DEFB $FF,$07,$DF,$8F,$C0,$80 ;
  DEFB $1F,$0F,$9F,$0F,$80,$00 ;
  DEFB $1F,$0C,$FF,$00,$00,$00 ;
  DEFB $0F,$03,$FE,$B0,$00,$00 ;
  DEFB $03,$00,$FF,$36,$C0,$00 ;
  DEFB $07,$01,$FF,$B6,$E0,$C0 ;
  DEFB $0F,$06,$FF,$B6,$E0,$C0 ;
  DEFB $0F,$06,$FF,$DE,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$C0,$80 ;
  DEFB $03,$01,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$C7,$C7,$80,$00 ;

; Sprite for graphics 25, 29
;
; 24 by 17 pixels.
SPRITE25:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$00,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$38,$00,$00,$00 ;
  DEFB $00,$00,$FC,$38,$00,$00 ;
  DEFB $03,$00,$FB,$F0,$80,$00 ;
  DEFB $07,$03,$FF,$E3,$C0,$80 ;
  DEFB $07,$03,$FF,$CF,$80,$00 ;
  DEFB $07,$02,$FF,$3C,$00,$00 ;
  DEFB $03,$01,$FC,$88,$00,$00 ;
  DEFB $03,$01,$FE,$30,$00,$00 ;
  DEFB $03,$00,$FF,$B6,$80,$00 ;
  DEFB $07,$02,$FF,$B6,$C0,$80 ;
  DEFB $07,$02,$FF,$BE,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$80,$00 ;
  DEFB $07,$03,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$C7,$C7,$80,$00 ;

; Sprite for graphic 24
;
; 24 by 17 pixels.
SPRITE24:
  DEFB $03,$11            ; Width in bytes, and height in rows
  DEFB $00,$00,$00,$00,$00,$00 ; Mask and image bytes, a pair per cell, the
  DEFB $00,$00,$0F,$00,$00,$00 ; bottom row first
  DEFB $00,$00,$7F,$0F,$80,$00 ;
  DEFB $00,$00,$FF,$7E,$00,$00 ;
  DEFB $01,$00,$FE,$FC,$00,$00 ;
  DEFB $01,$00,$FC,$E0,$00,$00 ;
  DEFB $00,$00,$F8,$50,$00,$00 ;
  DEFB $03,$00,$FE,$B8,$00,$00 ;
  DEFB $07,$03,$FF,$C6,$00,$00 ;
  DEFB $07,$02,$FF,$36,$00,$00 ;
  DEFB $07,$01,$FF,$B7,$80,$00 ;
  DEFB $0F,$05,$FF,$AD,$C0,$80 ;
  DEFB $1F,$0E,$FF,$AD,$C0,$80 ;
  DEFB $0F,$06,$FF,$FB,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$C0,$80 ;
  DEFB $07,$03,$FF,$FF,$80,$00 ;
  DEFB $03,$01,$C7,$C7,$80,$00 ;

; Tiles 0, 42
;
; 16 by 56 pixels.
TILE0:
  DEFB $38                ; Height in rows
  DEFB $3F,$F2            ; Two bytes a row, the bottom row first
  DEFB $FF,$CE            ;
  DEFB $FF,$3E            ;
  DEFB $FC,$DE            ;
  DEFB $F3,$1E            ;
  DEFB $CC,$9E            ;
  DEFB $D1,$5E            ;
  DEFB $D2,$9E            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4A            ;
  DEFB $DA,$AA            ;
  DEFB $E9,$4E            ;
  DEFB $EA,$AE            ;
  DEFB $E9,$4E            ;
  DEFB $EA,$AE            ;
  DEFB $E9,$4A            ;
  DEFB $6A,$AA            ;
  DEFB $69,$4A            ;
  DEFB $6A,$9A            ;
  DEFB $69,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $A9,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $A9,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $AA,$AE            ;
  DEFB $A5,$4F            ;
  DEFB $AA,$AF            ;
  DEFB $A5,$4E            ;
  DEFB $AA,$A9            ;
  DEFB $D5,$47            ;
  DEFB $D2,$9F            ;
  DEFB $D5,$79            ;
  DEFB $D0,$FB            ;
  DEFB $D3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $9F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $FC,$00            ;
  DEFB $70,$00            ;
  DEFB $C0,$00            ;

; Tile 1
;
; 16 by 56 pixels.
TILE1:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CB            ;
  DEFB $FF,$33            ;
  DEFB $FC,$C3            ;
  DEFB $F3,$0B            ;
  DEFB $CC,$53            ;
  DEFB $0A,$AB            ;
  DEFB $E9,$53            ;
  DEFB $EA,$AB            ;
  DEFB $E9,$55            ;
  DEFB $EA,$A5            ;
  DEFB $E9,$55            ;
  DEFB $D2,$AA            ;
  DEFB $D5,$52            ;
  DEFB $D2,$AA            ;
  DEFB $D5,$53            ;
  DEFB $D2,$AB            ;
  DEFB $D5,$53            ;
  DEFB $EA,$AB            ;
  DEFB $E9,$53            ;
  DEFB $EA,$A9            ;
  DEFB $E9,$55            ;
  DEFB $6A,$A9            ;
  DEFB $69,$55            ;
  DEFB $6A,$A9            ;
  DEFB $A9,$55            ;
  DEFB $AA,$AB            ;
  DEFB $B5,$53            ;
  DEFB $B4,$AB            ;
  DEFB $95,$53            ;
  DEFB $94,$AB            ;
  DEFB $D5,$53            ;
  DEFB $D4,$AB            ;
  DEFB $D5,$53            ;
  DEFB $D4,$A7            ;
  DEFB $95,$57            ;
  DEFB $B4,$A7            ;
  DEFB $B5,$53            ;
  DEFB $B4,$AB            ;
  DEFB $A9,$53            ;
  DEFB $AA,$AB            ;
  DEFB $A9,$53            ;
  DEFB $6A,$AB            ;
  DEFB $69,$52            ;
  DEFB $6A,$A9            ;
  DEFB $69,$47            ;
  DEFB $EA,$BE            ;
  DEFB $E8,$7F            ;
  DEFB $E9,$FF            ;
  DEFB $E3,$FC            ;
  DEFB $9F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $7C,$00            ;
  DEFB $70,$00            ;
  DEFB $C0,$00            ;

; Tile 2
;
; 16 by 56 pixels.
TILE2:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CB            ;
  DEFB $FF,$33            ;
  DEFB $FC,$CB            ;
  DEFB $F3,$1B            ;
  DEFB $CC,$BB            ;
  DEFB $31,$3B            ;
  DEFB $CA,$7B            ;
  DEFB $14,$E3            ;
  DEFB $A9,$D9            ;
  DEFB $53,$A1            ;
  DEFB $AB,$A9            ;
  DEFB $53,$51            ;
  DEFB $A7,$4B            ;
  DEFB $57,$3B            ;
  DEFB $AE,$FB            ;
  DEFB $49,$FB            ;
  DEFB $A7,$E3            ;
  DEFB $4F,$CB            ;
  DEFB $3F,$3B            ;
  DEFB $7C,$EB            ;
  DEFB $F3,$8B            ;
  DEFB $CE,$0B            ;
  DEFB $3A,$0B            ;
  DEFB $E2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$3B            ;
  DEFB $82,$CB            ;
  DEFB $83,$0B            ;
  DEFB $8E,$0B            ;
  DEFB $B2,$0B            ;
  DEFB $C2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$3B            ;
  DEFB $82,$CB            ;
  DEFB $83,$0B            ;
  DEFB $8E,$0B            ;
  DEFB $B2,$0B            ;
  DEFB $C2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0A            ;
  DEFB $82,$39            ;
  DEFB $80,$E7            ;
  DEFB $83,$9E            ;
  DEFB $8E,$7F            ;
  DEFB $B9,$FF            ;
  DEFB $E3,$FC            ;
  DEFB $8F,$F0            ;
  DEFB $3F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 3
;
; 16 by 56 pixels.
TILE3:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CC            ;
  DEFB $FF,$31            ;
  DEFB $FC,$CA            ;
  DEFB $F3,$15            ;
  DEFB $CC,$AA            ;
  DEFB $11,$55            ;
  DEFB $C0,$2A            ;
  DEFB $DF,$D5            ;
  DEFB $DF,$EA            ;
  DEFB $DF,$F5            ;
  DEFB $C0,$F2            ;
  DEFB $D5,$78            ;
  DEFB $D2,$B3            ;
  DEFB $D5,$0F            ;
  DEFB $D2,$3F            ;
  DEFB $D1,$FC            ;
  DEFB $C7,$F3            ;
  DEFB $DF,$CF            ;
  DEFB $DF,$39            ;
  DEFB $DC,$E1            ;
  DEFB $D3,$C1            ;
  DEFB $CE,$41            ;
  DEFB $D8,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$43            ;
  DEFB $D0,$4D            ;
  DEFB $D0,$71            ;
  DEFB $D0,$C1            ;
  DEFB $F3,$41            ;
  DEFB $FC,$41            ;
  DEFB $F0,$41            ;
  DEFB $F0,$41            ;
  DEFB $F0,$43            ;
  DEFB $F0,$4D            ;
  DEFB $F0,$71            ;
  DEFB $D0,$C1            ;
  DEFB $D3,$41            ;
  DEFB $DC,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$41            ;
  DEFB $90,$43            ;
  DEFB $90,$4E            ;
  DEFB $90,$79            ;
  DEFB $D0,$E7            ;
  DEFB $D3,$9E            ;
  DEFB $DE,$7F            ;
  DEFB $D9,$FF            ;
  DEFB $C7,$FC            ;
  DEFB $9F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $7C,$00            ;
  DEFB $70,$00            ;
  DEFB $C0,$00            ;

; Tile 47
;
; 16 by 64 pixels.
TILE47:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FC            ;
  DEFB $0E,$73            ;
  DEFB $3F,$CD            ;
  DEFB $FF,$32            ;
  DEFB $FC,$C5            ;
  DEFB $FB,$2A            ;
  DEFB $C4,$55            ;
  DEFB $1A,$AA            ;
  DEFB $D5,$55            ;
  DEFB $D2,$AA            ;
  DEFB $D5,$55            ;
  DEFB $C0,$2A            ;
  DEFB $DF,$D5            ;
  DEFB $DF,$EA            ;
  DEFB $DF,$F5            ;
  DEFB $C0,$F2            ;
  DEFB $D5,$78            ;
  DEFB $D2,$B3            ;
  DEFB $D5,$0F            ;
  DEFB $D2,$3F            ;
  DEFB $D1,$FC            ;
  DEFB $C7,$F3            ;
  DEFB $DF,$CF            ;
  DEFB $DF,$39            ;
  DEFB $DC,$E1            ;
  DEFB $D3,$C1            ;
  DEFB $CE,$41            ;
  DEFB $D8,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$43            ;
  DEFB $D0,$4D            ;
  DEFB $F0,$71            ;
  DEFB $F0,$C1            ;
  DEFB $F3,$41            ;
  DEFB $FC,$41            ;
  DEFB $F0,$41            ;
  DEFB $F0,$41            ;
  DEFB $F0,$43            ;
  DEFB $F0,$4D            ;
  DEFB $F0,$71            ;
  DEFB $D0,$C1            ;
  DEFB $D3,$41            ;
  DEFB $DC,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$41            ;
  DEFB $D0,$41            ;
  DEFB $90,$43            ;
  DEFB $90,$4E            ;
  DEFB $90,$79            ;
  DEFB $D0,$E7            ;
  DEFB $D3,$9E            ;
  DEFB $DE,$7F            ;
  DEFB $D9,$FF            ;
  DEFB $C7,$FC            ;
  DEFB $9F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $7C,$FF            ;
  DEFB $73,$FF            ;
  DEFB $CF,$FC            ;

; Tile 48
;
; 16 by 64 pixels.
TILE48:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FC            ;
  DEFB $0F,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$33            ;
  DEFB $FC,$C3            ;
  DEFB $F3,$2B            ;
  DEFB $CC,$53            ;
  DEFB $32,$AB            ;
  DEFB $C5,$5B            ;
  DEFB $2A,$BB            ;
  DEFB $55,$3B            ;
  DEFB $AA,$7B            ;
  DEFB $54,$E3            ;
  DEFB $A9,$D1            ;
  DEFB $53,$A1            ;
  DEFB $AB,$A9            ;
  DEFB $53,$51            ;
  DEFB $A7,$4B            ;
  DEFB $57,$3B            ;
  DEFB $AE,$FB            ;
  DEFB $49,$FB            ;
  DEFB $A7,$E3            ;
  DEFB $4F,$CB            ;
  DEFB $3F,$3B            ;
  DEFB $7C,$EB            ;
  DEFB $F3,$8B            ;
  DEFB $CE,$0B            ;
  DEFB $3A,$0B            ;
  DEFB $E2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$3B            ;
  DEFB $82,$CB            ;
  DEFB $83,$0B            ;
  DEFB $8E,$0B            ;
  DEFB $B2,$0B            ;
  DEFB $C2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$3B            ;
  DEFB $82,$CB            ;
  DEFB $83,$0B            ;
  DEFB $8E,$0B            ;
  DEFB $B2,$0B            ;
  DEFB $C2,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0B            ;
  DEFB $82,$0A            ;
  DEFB $82,$39            ;
  DEFB $80,$E7            ;
  DEFB $83,$9E            ;
  DEFB $8E,$7F            ;
  DEFB $B9,$FF            ;
  DEFB $E3,$FC            ;
  DEFB $8F,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $73,$FF            ;
  DEFB $EF,$FC            ;

; Tile 4
;
; 16 by 56 pixels.
TILE4:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CF            ;
  DEFB $FF,$37            ;
  DEFB $FC,$CB            ;
  DEFB $F3,$13            ;
  DEFB $C6,$AB            ;
  DEFB $35,$53            ;
  DEFB $F4,$AB            ;
  DEFB $F5,$53            ;
  DEFB $74,$AB            ;
  DEFB $69,$53            ;
  DEFB $6A,$AB            ;
  DEFB $69,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AB            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AB            ;
  DEFB $7A,$57            ;
  DEFB $7A,$A7            ;
  DEFB $7A,$57            ;
  DEFB $7A,$A7            ;
  DEFB $3A,$57            ;
  DEFB $3A,$A7            ;
  DEFB $3D,$57            ;
  DEFB $3D,$27            ;
  DEFB $3D,$57            ;
  DEFB $3D,$27            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$2F            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$2F            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$27            ;
  DEFB $3B,$57            ;
  DEFB $3A,$A7            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AA            ;
  DEFB $7A,$51            ;
  DEFB $7A,$A7            ;
  DEFB $7A,$1E            ;
  DEFB $F8,$FE            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $3F,$F0            ;
  DEFB $FF,$C0            ;
  DEFB $CF,$00            ;
  DEFB $DC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 5
;
; 16 by 64 pixels.
TILE5:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $20,$00            ;
  DEFB $E8,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $C5,$00            ;
  DEFB $2A,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $C5,$00            ;
  DEFB $2A,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $C5,$00            ;
  DEFB $2A,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $C5,$00            ;
  DEFB $2A,$80            ;
  DEFB $E9,$40            ;
  DEFB $EC,$A0            ;
  DEFB $ED,$50            ;
  DEFB $EE,$AA            ;
  DEFB $EB,$55            ;
  DEFB $E9,$88            ;
  DEFB $C8,$E7            ;
  DEFB $28,$3D            ;
  DEFB $E8,$03            ;
  DEFB $E8,$0E            ;
  DEFB $E8,$39            ;
  DEFB $E8,$E7            ;
  DEFB $EB,$9F            ;
  DEFB $EE,$3F            ;
  DEFB $C9,$BF            ;
  DEFB $27,$BF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$BC            ;
  DEFB $FF,$B3            ;
  DEFB $FF,$8F            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 6
;
; 16 by 64 pixels.
TILE6:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$04            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$04            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$04            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$04            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$17            ;
  DEFB $00,$17            ;
  DEFB $00,$17            ;
  DEFB $00,$17            ;
  DEFB $00,$37            ;
  DEFB $00,$34            ;
  DEFB $00,$33            ;
  DEFB $00,$77            ;
  DEFB $00,$57            ;
  DEFB $00,$D7            ;
  DEFB $00,$97            ;
  DEFB $01,$97            ;
  DEFB $03,$17            ;
  DEFB $06,$14            ;
  DEFB $0C,$13            ;
  DEFB $18,$37            ;
  DEFB $B0,$E7            ;
  DEFB $63,$9F            ;
  DEFB $CE,$7F            ;
  DEFB $B9,$FF            ;
  DEFB $E5,$FF            ;
  DEFB $9D,$FF            ;
  DEFB $7D,$FC            ;
  DEFB $FD,$F3            ;
  DEFB $FD,$CF            ;
  DEFB $FD,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 7
;
; 16 by 64 pixels.
TILE7:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $C0,$00            ;
  DEFB $E0,$00            ;
  DEFB $D4,$00            ;
  DEFB $EA,$00            ;
  DEFB $15,$00            ;
  DEFB $CA,$00            ;
  DEFB $D0,$00            ;
  DEFB $C8,$00            ;
  DEFB $D4,$00            ;
  DEFB $CA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $D4,$00            ;
  DEFB $CA,$00            ;
  DEFB $D4,$00            ;
  DEFB $CA,$00            ;
  DEFB $D4,$00            ;
  DEFB $EA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $E4,$00            ;
  DEFB $EA,$00            ;
  DEFB $D4,$00            ;
  DEFB $CA,$00            ;
  DEFB $D4,$01            ;
  DEFB $CA,$01            ;
  DEFB $C4,$03            ;
  DEFB $D2,$03            ;
  DEFB $DA,$03            ;
  DEFB $DD,$03            ;
  DEFB $DE,$83            ;
  DEFB $DE,$E3            ;
  DEFB $CF,$7B            ;
  DEFB $C7,$9B            ;
  DEFB $D3,$E3            ;
  DEFB $C9,$F3            ;
  DEFB $D4,$FB            ;
  DEFB $CA,$7B            ;
  DEFB $D4,$1B            ;
  DEFB $CA,$00            ;
  DEFB $D4,$03            ;
  DEFB $CA,$0F            ;
  DEFB $D4,$3F            ;
  DEFB $C8,$FF            ;
  DEFB $D3,$FC            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 8
;
; 16 by 64 pixels.
TILE8:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$00            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$03            ;
  DEFB $00,$0B            ;
  DEFB $00,$0B            ;
  DEFB $00,$1B            ;
  DEFB $00,$1B            ;
  DEFB $00,$3B            ;
  DEFB $00,$7B            ;
  DEFB $00,$7B            ;
  DEFB $00,$F3            ;
  DEFB $81,$F3            ;
  DEFB $C1,$EB            ;
  DEFB $C3,$DB            ;
  DEFB $D3,$DB            ;
  DEFB $D7,$9B            ;
  DEFB $CF,$33            ;
  DEFB $DE,$70            ;
  DEFB $DE,$63            ;
  DEFB $DC,$C7            ;
  DEFB $D9,$9F            ;
  DEFB $D3,$7F            ;
  DEFB $C4,$FF            ;
  DEFB $D3,$FC            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 9
;
; 16 by 64 pixels.
TILE9:
  DEFB $40                ; Height in rows
  DEFB $00,$01            ; Two bytes a row, the bottom row first
  DEFB $00,$0D            ;
  DEFB $00,$3D            ;
  DEFB $00,$F9            ;
  DEFB $01,$E1            ;
  DEFB $0C,$01            ;
  DEFB $38,$39            ;
  DEFB $F8,$F9            ;
  DEFB $F8,$F8            ;
  DEFB $F0,$F9            ;
  DEFB $E0,$FB            ;
  DEFB $CE,$F3            ;
  DEFB $3E,$C3            ;
  DEFB $7E,$33            ;
  DEFB $7E,$F8            ;
  DEFB $79,$F8            ;
  DEFB $37,$F8            ;
  DEFB $07,$E3            ;
  DEFB $3B,$CB            ;
  DEFB $38,$3B            ;
  DEFB $78,$BB            ;
  DEFB $78,$B8            ;
  DEFB $7B,$B1            ;
  DEFB $7B,$89            ;
  DEFB $FB,$95            ;
  DEFB $FB,$A9            ;
  DEFB $F3,$95            ;
  DEFB $F7,$A3            ;
  DEFB $F7,$8F            ;
  DEFB $77,$BD            ;
  DEFB $77,$B1            ;
  DEFB $73,$89            ;
  DEFB $7B,$95            ;
  DEFB $0B,$A9            ;
  DEFB $E3,$95            ;
  DEFB $F3,$A9            ;
  DEFB $F3,$95            ;
  DEFB $F7,$A3            ;
  DEFB $F7,$8F            ;
  DEFB $E7,$BD            ;
  DEFB $E7,$B1            ;
  DEFB $F3,$89            ;
  DEFB $F3,$95            ;
  DEFB $FB,$A9            ;
  DEFB $FB,$94            ;
  DEFB $FB,$A3            ;
  DEFB $73,$8F            ;
  DEFB $03,$BF            ;
  DEFB $CF,$BC            ;
  DEFB $EF,$B1            ;
  DEFB $EF,$81            ;
  DEFB $EF,$19            ;
  DEFB $EC,$3C            ;
  DEFB $E0,$3C            ;
  DEFB $F3,$79            ;
  DEFB $E7,$7B            ;
  DEFB $EF,$7B            ;
  DEFB $0F,$78            ;
  DEFB $8F,$B3            ;
  DEFB $E7,$8F            ;
  DEFB $F7,$3F            ;
  DEFB $F4,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 10
;
; 16 by 64 pixels.
TILE10:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$2F            ;
  DEFB $00,$EE            ;
  DEFB $03,$E0            ;
  DEFB $07,$E3            ;
  DEFB $27,$CF            ;
  DEFB $F7,$9F            ;
  DEFB $F0,$3F            ;
  DEFB $F7,$3F            ;
  DEFB $F7,$BF            ;
  DEFB $F7,$9C            ;
  DEFB $F7,$99            ;
  DEFB $F3,$03            ;
  DEFB $E1,$8F            ;
  DEFB $87,$DF            ;
  DEFB $3F,$DE            ;
  DEFB $FF,$CC            ;
  DEFB $FF,$83            ;
  DEFB $FF,$0F            ;
  DEFB $F0,$DF            ;
  DEFB $E1,$DF            ;
  DEFB $CD,$DE            ;
  DEFB $1D,$DE            ;
  DEFB $DD,$CF            ;
  DEFB $DD,$EF            ;
  DEFB $D1,$EF            ;
  DEFB $C9,$EF            ;
  DEFB $15,$EF            ;
  DEFB $AB,$CC            ;
  DEFB $95,$C0            ;
  DEFB $A1,$C1            ;
  DEFB $8D,$CD            ;
  DEFB $BD,$CD            ;
  DEFB $F1,$C1            ;
  DEFB $C1,$ED            ;
  DEFB $81,$ED            ;
  DEFB $81,$EC            ;
  DEFB $81,$EC            ;
  DEFB $81,$CC            ;
  DEFB $81,$CE            ;
  DEFB $81,$CF            ;
  DEFB $8D,$CF            ;
  DEFB $BD,$C7            ;
  DEFB $F1,$C7            ;
  DEFB $C1,$F7            ;
  DEFB $81,$F7            ;
  DEFB $81,$F0            ;
  DEFB $81,$F3            ;
  DEFB $81,$F3            ;
  DEFB $8D,$C3            ;
  DEFB $3D,$13            ;
  DEFB $FC,$77            ;
  DEFB $F1,$C7            ;
  DEFB $C7,$97            ;
  DEFB $16,$33            ;
  DEFB $70,$F3            ;
  DEFB $F9,$F0            ;
  DEFB $FD,$E3            ;
  DEFB $F1,$CF            ;
  DEFB $8D,$3F            ;
  DEFB $3C,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 11
;
; 16 by 64 pixels.
TILE11:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$03            ;
  DEFB $00,$31            ;
  DEFB $00,$F0            ;
  DEFB $00,$F8            ;
  DEFB $08,$F8            ;
  DEFB $3A,$FC            ;
  DEFB $F6,$F8            ;
  DEFB $F7,$62            ;
  DEFB $EF,$8F            ;
  DEFB $CF,$8F            ;
  DEFB $1F,$DF            ;
  DEFB $7F,$DF            ;
  DEFB $7F,$DE            ;
  DEFB $7F,$9E            ;
  DEFB $7E,$0E            ;
  DEFB $7D,$DE            ;
  DEFB $3B,$DE            ;
  DEFB $03,$D8            ;
  DEFB $3B,$C2            ;
  DEFB $FB,$CE            ;
  DEFB $F9,$9E            ;
  DEFB $F0,$1E            ;
  DEFB $63,$9E            ;
  DEFB $07,$DE            ;
  DEFB $6F,$D8            ;
  DEFB $EF,$D3            ;
  DEFB $EF,$C7            ;
  DEFB $EF,$CF            ;
  DEFB $6F,$CF            ;
  DEFB $0F,$86            ;
  DEFB $67,$00            ;
  DEFB $F7,$78            ;
  DEFB $F7,$7E            ;
  DEFB $E6,$7E            ;
  DEFB $C0,$3E            ;
  DEFB $01,$DE            ;
  DEFB $79,$DC            ;
  DEFB $FD,$C0            ;
  DEFB $FD,$EE            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FF,$03            ;
  DEFB $FF,$33            ;
  DEFB $7E,$7B            ;
  DEFB $18,$F8            ;
  DEFB $63,$F8            ;
  DEFB $73,$FC            ;
  DEFB $7B,$F9            ;
  DEFB $7B,$F3            ;
  DEFB $79,$F7            ;
  DEFB $78,$37            ;
  DEFB $39,$87            ;
  DEFB $9B,$E7            ;
  DEFB $C7,$F3            ;
  DEFB $F3,$F0            ;
  DEFB $FB,$F3            ;
  DEFB $F9,$CF            ;
  DEFB $F8,$3F            ;
  DEFB $F0,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 12
;
; 16 by 64 pixels.
TILE12:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0E            ;
  DEFB $00,$3E            ;
  DEFB $00,$FE            ;
  DEFB $03,$FE            ;
  DEFB $0F,$FE            ;
  DEFB $2F,$FD            ;
  DEFB $EF,$FD            ;
  DEFB $EF,$FD            ;
  DEFB $EF,$FB            ;
  DEFB $CF,$FB            ;
  DEFB $0F,$FB            ;
  DEFB $CF,$F0            ;
  DEFB $EF,$C7            ;
  DEFB $EF,$37            ;
  DEFB $CC,$F7            ;
  DEFB $00,$F7            ;
  DEFB $F8,$F7            ;
  DEFB $FE,$F7            ;
  DEFB $FE,$F7            ;
  DEFB $FC,$F7            ;
  DEFB $F0,$F7            ;
  DEFB $66,$F7            ;
  DEFB $1E,$F7            ;
  DEFB $7E,$F7            ;
  DEFB $FC,$F7            ;
  DEFB $F0,$F7            ;
  DEFB $0C,$F0            ;
  DEFB $3E,$C7            ;
  DEFB $7C,$37            ;
  DEFB $F0,$F7            ;
  DEFB $C3,$F7            ;
  DEFB $0F,$F7            ;
  DEFB $EF,$F7            ;
  DEFB $EF,$F0            ;
  DEFB $CF,$C7            ;
  DEFB $8F,$37            ;
  DEFB $6C,$F7            ;
  DEFB $60,$F7            ;
  DEFB $F6,$F7            ;
  DEFB $E6,$F7            ;
  DEFB $4E,$F7            ;
  DEFB $1E,$F7            ;
  DEFB $7C,$F7            ;
  DEFB $7C,$F7            ;
  DEFB $F8,$F7            ;
  DEFB $F0,$F0            ;
  DEFB $04,$CB            ;
  DEFB $7C,$3B            ;
  DEFB $78,$FD            ;
  DEFB $63,$FD            ;
  DEFB $8F,$FE            ;
  DEFB $CF,$FE            ;
  DEFB $EF,$FE            ;
  DEFB $EF,$FE            ;
  DEFB $4F,$FE            ;
  DEFB $2F,$FF            ;
  DEFB $EF,$FC            ;
  DEFB $EF,$F3            ;
  DEFB $EF,$CF            ;
  DEFB $EF,$3F            ;
  DEFB $CC,$FF            ;
  DEFB $C3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 13
;
; 16 by 64 pixels.
TILE13:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$07            ;
  DEFB $00,$33            ;
  DEFB $00,$F8            ;
  DEFB $00,$FC            ;
  DEFB $08,$FE            ;
  DEFB $3C,$FE            ;
  DEFB $FD,$F0            ;
  DEFB $FD,$C2            ;
  DEFB $F9,$8F            ;
  DEFB $80,$3F            ;
  DEFB $3C,$7C            ;
  DEFB $7E,$F3            ;
  DEFB $FE,$CF            ;
  DEFB $FE,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $73,$FF            ;
  DEFB $0F,$FF            ;
  DEFB $DF,$FC            ;
  DEFB $DF,$F3            ;
  DEFB $DF,$CF            ;
  DEFB $1F,$3F            ;
  DEFB $1C,$FF            ;
  DEFB $1B,$C3            ;
  DEFB $C7,$3C            ;
  DEFB $F0,$BC            ;
  DEFB $FD,$BC            ;
  DEFB $7D,$BC            ;
  DEFB $7D,$BC            ;
  DEFB $3D,$BF            ;
  DEFB $19,$BC            ;
  DEFB $E1,$BC            ;
  DEFB $FD,$BE            ;
  DEFB $3D,$BE            ;
  DEFB $8D,$BF            ;
  DEFB $E1,$BF            ;
  DEFB $F9,$BF            ;
  DEFB $F9,$DF            ;
  DEFB $00,$DF            ;
  DEFB $1E,$EF            ;
  DEFB $7E,$EF            ;
  DEFB $7E,$77            ;
  DEFB $78,$7B            ;
  DEFB $63,$3D            ;
  DEFB $0F,$9E            ;
  DEFB $7F,$C7            ;
  DEFB $7F,$99            ;
  DEFB $3E,$3E            ;
  DEFB $B8,$BF            ;
  DEFB $83,$BF            ;
  DEFB $DF,$BE            ;
  DEFB $FF,$18            ;
  DEFB $FC,$43            ;
  DEFB $F0,$E7            ;
  DEFB $C3,$F7            ;
  DEFB $13,$F7            ;
  DEFB $73,$F7            ;
  DEFB $F9,$F0            ;
  DEFB $F9,$F3            ;
  DEFB $FC,$CF            ;
  DEFB $FC,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 14
;
; 16 by 64 pixels.
TILE14:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$07            ;
  DEFB $00,$33            ;
  DEFB $00,$F3            ;
  DEFB $00,$F8            ;
  DEFB $09,$FE            ;
  DEFB $39,$FE            ;
  DEFB $F1,$F8            ;
  DEFB $F0,$F2            ;
  DEFB $E6,$07            ;
  DEFB $CF,$8F            ;
  DEFB $1F,$CF            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$37            ;
  DEFB $7C,$DB            ;
  DEFB $33,$D8            ;
  DEFB $0F,$D8            ;
  DEFB $3F,$D9            ;
  DEFB $FF,$D9            ;
  DEFB $FF,$D9            ;
  DEFB $FF,$0B            ;
  DEFB $FC,$F7            ;
  DEFB $F3,$C7            ;
  DEFB $CF,$2F            ;
  DEFB $3D,$60            ;
  DEFB $FD,$63            ;
  DEFB $FB,$67            ;
  DEFB $FB,$6F            ;
  DEFB $F3,$6F            ;
  DEFB $E3,$66            ;
  DEFB $23,$60            ;
  DEFB $23,$6E            ;
  DEFB $23,$6E            ;
  DEFB $2F,$6E            ;
  DEFB $33,$6E            ;
  DEFB $E3,$6E            ;
  DEFB $23,$64            ;
  DEFB $27,$60            ;
  DEFB $26,$EE            ;
  DEFB $26,$DF            ;
  DEFB $26,$DF            ;
  DEFB $2E,$DF            ;
  DEFB $2D,$BF            ;
  DEFB $9D,$BF            ;
  DEFB $FB,$8F            ;
  DEFB $FB,$67            ;
  DEFB $F7,$7B            ;
  DEFB $EE,$FC            ;
  DEFB $DD,$FC            ;
  DEFB $B9,$FD            ;
  DEFB $76,$FB            ;
  DEFB $EF,$37            ;
  DEFB $DF,$07            ;
  DEFB $9E,$07            ;
  DEFB $1C,$E7            ;
  DEFB $8D,$F3            ;
  DEFB $81,$F0            ;
  DEFB $39,$F3            ;
  DEFB $FD,$CF            ;
  DEFB $FC,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 15
;
; 16 by 64 pixels.
TILE15:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0E            ;
  DEFB $00,$3E            ;
  DEFB $00,$FF            ;
  DEFB $03,$FC            ;
  DEFB $0F,$F3            ;
  DEFB $3F,$CB            ;
  DEFB $FF,$3B            ;
  DEFB $FC,$D3            ;
  DEFB $F3,$AB            ;
  DEFB $CD,$53            ;
  DEFB $2A,$A8            ;
  DEFB $ED,$53            ;
  DEFB $EA,$8C            ;
  DEFB $ED,$30            ;
  DEFB $E8,$C8            ;
  DEFB $E3,$0C            ;
  DEFB $CC,$4C            ;
  DEFB $30,$AB            ;
  DEFB $C3,$31            ;
  DEFB $11,$11            ;
  DEFB $91,$2A            ;
  DEFB $AA,$AA            ;
  DEFB $AA,$64            ;
  DEFB $A4,$46            ;
  DEFB $C6,$66            ;
  DEFB $E6,$99            ;
  DEFB $99,$98            ;
  DEFB $98,$99            ;
  DEFB $99,$95            ;
  DEFB $95,$56            ;
  DEFB $D6,$22            ;
  DEFB $A2,$23            ;
  DEFB $A3,$55            ;
  DEFB $D5,$4C            ;
  DEFB $CC,$C8            ;
  DEFB $C8,$CC            ;
  DEFB $CC,$CB            ;
  DEFB $CB,$33            ;
  DEFB $B3,$11            ;
  DEFB $91,$32            ;
  DEFB $B2,$AA            ;
  DEFB $EA,$A4            ;
  DEFB $E4,$43            ;
  DEFB $E4,$4F            ;
  DEFB $D6,$3F            ;
  DEFB $99,$FF            ;
  DEFB $C3,$FE            ;
  DEFB $CF,$F9            ;
  DEFB $BF,$E7            ;
  DEFB $7F,$9F            ;
  DEFB $BE,$7E            ;
  DEFB $D9,$F9            ;
  DEFB $E7,$E7            ;
  DEFB $9F,$9F            ;
  DEFB $7E,$7F            ;
  DEFB $F9,$FF            ;
  DEFB $E7,$FC            ;
  DEFB $9F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 16
;
; 16 by 64 pixels.
TILE16:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FC            ;
  DEFB $0F,$F3            ;
  DEFB $3F,$C7            ;
  DEFB $FF,$37            ;
  DEFB $FC,$E7            ;
  DEFB $73,$57            ;
  DEFB $CE,$A7            ;
  DEFB $15,$54            ;
  DEFB $DA,$A3            ;
  DEFB $D5,$4F            ;
  DEFB $DA,$3F            ;
  DEFB $D4,$FF            ;
  DEFB $D3,$FF            ;
  DEFB $CF,$FF            ;
  DEFB $30,$7C            ;
  DEFB $C2,$03            ;
  DEFB $0E,$33            ;
  DEFB $19,$4B            ;
  DEFB $C8,$83            ;
  DEFB $49,$4B            ;
  DEFB $CE,$33            ;
  DEFB $AE,$33            ;
  DEFB $19,$4B            ;
  DEFB $18,$83            ;
  DEFB $29,$4B            ;
  DEFB $AE,$33            ;
  DEFB $6E,$33            ;
  DEFB $49,$4B            ;
  DEFB $68,$83            ;
  DEFB $99,$4B            ;
  DEFB $9E,$3B            ;
  DEFB $9E,$33            ;
  DEFB $99,$4B            ;
  DEFB $58,$83            ;
  DEFB $29,$43            ;
  DEFB $2E,$3B            ;
  DEFB $5E,$33            ;
  DEFB $49,$4B            ;
  DEFB $C8,$83            ;
  DEFB $C9,$4B            ;
  DEFB $CE,$33            ;
  DEFB $3E,$33            ;
  DEFB $19,$4B            ;
  DEFB $30,$82            ;
  DEFB $88,$41            ;
  DEFB $3F,$C7            ;
  DEFB $FF,$9F            ;
  DEFB $FE,$7E            ;
  DEFB $F9,$F9            ;
  DEFB $E7,$E7            ;
  DEFB $9F,$9F            ;
  DEFB $7E,$7F            ;
  DEFB $F9,$FF            ;
  DEFB $E7,$FC            ;
  DEFB $9F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 17
;
; 16 by 64 pixels.
TILE17:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$07            ;
  DEFB $00,$37            ;
  DEFB $00,$FB            ;
  DEFB $0B,$F9            ;
  DEFB $27,$FC            ;
  DEFB $EF,$F8            ;
  DEFB $EF,$E0            ;
  DEFB $EF,$8F            ;
  DEFB $C6,$0F            ;
  DEFB $01,$DF            ;
  DEFB $7F,$DF            ;
  DEFB $7F,$9F            ;
  DEFB $7F,$3F            ;
  DEFB $7E,$7E            ;
  DEFB $7E,$FE            ;
  DEFB $00,$FE            ;
  DEFB $1E,$78            ;
  DEFB $3F,$62            ;
  DEFB $FF,$0E            ;
  DEFB $FE,$3E            ;
  DEFB $FC,$7E            ;
  DEFB $73,$7E            ;
  DEFB $07,$3E            ;
  DEFB $77,$BE            ;
  DEFB $F7,$86            ;
  DEFB $F7,$80            ;
  DEFB $F6,$6B            ;
  DEFB $61,$EB            ;
  DEFB $07,$EB            ;
  DEFB $5F,$EB            ;
  DEFB $DE,$6A            ;
  DEFB $D8,$68            ;
  DEFB $D8,$6B            ;
  DEFB $18,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$E8            ;
  DEFB $DC,$E8            ;
  DEFB $1C,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $5C,$EB            ;
  DEFB $1C,$6A            ;
  DEFB $58,$68            ;
  DEFB $58,$68            ;
  DEFB $59,$E9            ;
  DEFB $5F,$EB            ;
  DEFB $1F,$97            ;
  DEFB $DE,$67            ;
  DEFB $D9,$87            ;
  DEFB $06,$37            ;
  DEFB $C0,$F3            ;
  DEFB $F3,$F0            ;
  DEFB $FB,$F3            ;
  DEFB $FB,$CF            ;
  DEFB $F9,$3F            ;
  DEFB $F0,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 18
;
; 16 by 64 pixels.
TILE18:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$01            ;
  DEFB $00,$07            ;
  DEFB $00,$1F            ;
  DEFB $00,$7C            ;
  DEFB $21,$F5            ;
  DEFB $EB,$C5            ;
  DEFB $EB,$15            ;
  DEFB $EB,$65            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $CB,$55            ;
  DEFB $2B,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EA,$55            ;
  DEFB $C9,$95            ;
  DEFB $2B,$55            ;
  DEFB $EA,$55            ;
  DEFB $E9,$95            ;
  DEFB $EA,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $CB,$55            ;
  DEFB $2B,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$55            ;
  DEFB $EB,$2D            ;
  DEFB $EB,$AE            ;
  DEFB $EB,$AE            ;
  DEFB $E9,$8E            ;
  DEFB $C5,$DF            ;
  DEFB $2C,$FF            ;
  DEFB $EA,$FF            ;
  DEFB $EE,$7F            ;
  DEFB $ED,$3F            ;
  DEFB $EE,$8F            ;
  DEFB $EF,$63            ;
  DEFB $EF,$98            ;
  DEFB $CD,$E7            ;
  DEFB $2C,$F9            ;
  DEFB $EC,$7F            ;
  DEFB $EC,$3E            ;
  DEFB $EC,$F9            ;
  DEFB $EF,$E7            ;
  DEFB $EF,$9F            ;
  DEFB $EE,$3F            ;
  DEFB $C9,$BF            ;
  DEFB $27,$BF            ;
  DEFB $FF,$BF            ;
  DEFB $FF,$BC            ;
  DEFB $FF,$B3            ;
  DEFB $FF,$8F            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 19
;
; 16 by 64 pixels.
TILE19:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$17            ;
  DEFB $00,$77            ;
  DEFB $01,$F7            ;
  DEFB $07,$F7            ;
  DEFB $1F,$34            ;
  DEFB $7C,$33            ;
  DEFB $F9,$B7            ;
  DEFB $CA,$B7            ;
  DEFB $0A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $8A,$B7            ;
  DEFB $2A,$B7            ;
  DEFB $6A,$B4            ;
  DEFB $6A,$B3            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B4            ;
  DEFB $6A,$B3            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B7            ;
  DEFB $6A,$B4            ;
  DEFB $6A,$A3            ;
  DEFB $6A,$A7            ;
  DEFB $6A,$67            ;
  DEFB $6A,$67            ;
  DEFB $6D,$57            ;
  DEFB $6D,$57            ;
  DEFB $6C,$B7            ;
  DEFB $6E,$B4            ;
  DEFB $6F,$B3            ;
  DEFB $6F,$77            ;
  DEFB $9F,$77            ;
  DEFB $9E,$F7            ;
  DEFB $5E,$F7            ;
  DEFB $3D,$F7            ;
  DEFB $7B,$B7            ;
  DEFB $F7,$34            ;
  DEFB $EE,$33            ;
  DEFB $DC,$F7            ;
  DEFB $BB,$E7            ;
  DEFB $7F,$9F            ;
  DEFB $FE,$7F            ;
  DEFB $F9,$FF            ;
  DEFB $E5,$FF            ;
  DEFB $9D,$FF            ;
  DEFB $7D,$FC            ;
  DEFB $FD,$F3            ;
  DEFB $FD,$CF            ;
  DEFB $FD,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 20
;
; 16 by 64 pixels.
TILE20:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$37            ;
  DEFB $00,$F7            ;
  DEFB $03,$F2            ;
  DEFB $0F,$F0            ;
  DEFB $3F,$F1            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F6            ;
  DEFB $FF,$F0            ;
  DEFB $FF,$C0            ;
  DEFB $7F,$02            ;
  DEFB $3C,$36            ;
  DEFB $12,$76            ;
  DEFB $0E,$F6            ;
  DEFB $1E,$F6            ;
  DEFB $1E,$F6            ;
  DEFB $1E,$F6            ;
  DEFB $1E,$F0            ;
  DEFB $1E,$32            ;
  DEFB $1E,$0E            ;
  DEFB $1E,$3E            ;
  DEFB $1E,$FC            ;
  DEFB $1E,$F1            ;
  DEFB $1E,$C7            ;
  DEFB $1E,$0F            ;
  DEFB $1E,$2F            ;
  DEFB $1C,$EF            ;
  DEFB $13,$EF            ;
  DEFB $0F,$EF            ;
  DEFB $1F,$EC            ;
  DEFB $1F,$E0            ;
  DEFB $1F,$C6            ;
  DEFB $1F,$3E            ;
  DEFB $1C,$FE            ;
  DEFB $12,$CE            ;
  DEFB $0E,$0C            ;
  DEFB $1E,$63            ;
  DEFB $1E,$E7            ;
  DEFB $1E,$E7            ;
  DEFB $1E,$EF            ;
  DEFB $1E,$EF            ;
  DEFB $1E,$E7            ;
  DEFB $1E,$F7            ;
  DEFB $1E,$07            ;
  DEFB $1E,$33            ;
  DEFB $1C,$F0            ;
  DEFB $13,$F1            ;
  DEFB $0F,$F7            ;
  DEFB $1F,$F7            ;
  DEFB $1F,$F7            ;
  DEFB $3F,$F7            ;
  DEFB $3F,$F7            ;
  DEFB $7F,$F7            ;
  DEFB $7F,$F4            ;
  DEFB $FF,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 22
;
; 16 by 56 pixels.
TILE22:
  DEFB $38                ; Height in rows
  DEFB $7F,$F8            ; Two bytes a row, the bottom row first
  DEFB $7F,$E3            ;
  DEFB $7F,$8F            ;
  DEFB $7E,$0F            ;
  DEFB $78,$8F            ;
  DEFB $63,$CF            ;
  DEFB $0F,$CF            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$CC            ;
  DEFB $FF,$C0            ;
  DEFB $FF,$C3            ;
  DEFB $FF,$0F            ;
  DEFB $FC,$3F            ;
  DEFB $F0,$FF            ;
  DEFB $C3,$FF            ;
  DEFB $0F,$FF            ;
  DEFB $0F,$FF            ;
  DEFB $CF,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $CF,$FC            ;
  DEFB $CF,$C3            ;
  DEFB $CF,$03            ;
  DEFB $CC,$33            ;
  DEFB $C0,$F3            ;
  DEFB $C3,$F3            ;
  DEFB $0F,$F3            ;
  DEFB $3F,$F3            ;
  DEFB $FF,$F3            ;
  DEFB $FF,$F0            ;
  DEFB $FF,$F0            ;
  DEFB $FF,$C3            ;
  DEFB $FF,$0F            ;
  DEFB $FC,$3F            ;
  DEFB $F0,$BF            ;
  DEFB $C3,$BF            ;
  DEFB $0F,$BF            ;
  DEFB $3F,$BF            ;
  DEFB $1F,$BF            ;
  DEFB $47,$BC            ;
  DEFB $29,$B3            ;
  DEFB $54,$0F            ;
  DEFB $2A,$9F            ;
  DEFB $55,$47            ;
  DEFB $2A,$A9            ;
  DEFB $15,$50            ;
  DEFB $8A,$A8            ;
  DEFB $E5,$50            ;
  DEFB $F8,$A8            ;
  DEFB $FE,$50            ;
  DEFB $FF,$88            ;
  DEFB $FF,$E8            ;
  DEFB $FF,$F8            ;
  DEFB $7F,$E0            ;
  DEFB $1F,$80            ;
  DEFB $06,$00            ;

; Tile 21
;
; 16 by 64 pixels.
TILE21:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$02            ;
  DEFB $00,$0E            ;
  DEFB $00,$3E            ;
  DEFB $00,$FE            ;
  DEFB $03,$FE            ;
  DEFB $0F,$FE            ;
  DEFB $3F,$FE            ;
  DEFB $7F,$F8            ;
  DEFB $7F,$E3            ;
  DEFB $7F,$8F            ;
  DEFB $7E,$0F            ;
  DEFB $78,$8F            ;
  DEFB $63,$CF            ;
  DEFB $0F,$CF            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$CC            ;
  DEFB $FF,$C0            ;
  DEFB $FF,$C3            ;
  DEFB $FF,$0F            ;
  DEFB $FC,$3F            ;
  DEFB $F0,$FF            ;
  DEFB $C3,$FF            ;
  DEFB $0F,$FF            ;
  DEFB $0F,$FF            ;
  DEFB $CF,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $CF,$F0            ;
  DEFB $CF,$C3            ;
  DEFB $CF,$0F            ;
  DEFB $CC,$3F            ;
  DEFB $C0,$7F            ;
  DEFB $C2,$7F            ;
  DEFB $0E,$7F            ;
  DEFB $3E,$7F            ;
  DEFB $FE,$7F            ;
  DEFB $FE,$7C            ;
  DEFB $FE,$70            ;
  DEFB $FE,$43            ;
  DEFB $FE,$07            ;
  DEFB $FC,$27            ;
  DEFB $F0,$E7            ;
  DEFB $C3,$E7            ;
  DEFB $07,$E7            ;
  DEFB $27,$E7            ;
  DEFB $E7,$E7            ;
  DEFB $E7,$E4            ;
  DEFB $E7,$E0            ;
  DEFB $E7,$C3            ;
  DEFB $E7,$0F            ;
  DEFB $E4,$3F            ;
  DEFB $E0,$7F            ;
  DEFB $C2,$7F            ;
  DEFB $0E,$7F            ;
  DEFB $3E,$7C            ;
  DEFB $FE,$70            ;
  DEFB $FE,$42            ;
  DEFB $FE,$0E            ;
  DEFB $FC,$3E            ;
  DEFB $F0,$FE            ;
  DEFB $C3,$FE            ;
  DEFB $0F,$FE            ;
  DEFB $3F,$FC            ;

; Tile 24
;
; 16 by 64 pixels.
TILE24:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$60            ;
  DEFB $01,$F4            ;
  DEFB $03,$3B            ;
  DEFB $02,$DB            ;
  DEFB $02,$DB            ;
  DEFB $02,$BB            ;
  DEFB $03,$77            ;
  DEFB $0D,$CF            ;
  DEFB $3E,$1F            ;
  DEFB $FD,$E6            ;
  DEFB $F3,$31            ;
  DEFB $C6,$D5            ;
  DEFB $35,$D6            ;
  DEFB $F5,$D7            ;
  DEFB $EF,$B7            ;
  DEFB $EE,$6F            ;
  DEFB $F7,$DE            ;
  DEFB $FB,$9E            ;
  DEFB $FC,$6E            ;
  DEFB $FC,$F1            ;
  DEFB $F1,$F9            ;
  DEFB $CB,$AA            ;
  DEFB $3B,$6B            ;
  DEFB $FA,$DB            ;
  DEFB $FB,$B7            ;
  DEFB $FB,$6F            ;
  DEFB $FD,$DE            ;
  DEFB $FE,$1E            ;
  DEFB $FE,$E9            ;
  DEFB $F1,$F3            ;
  DEFB $CB,$35            ;
  DEFB $36,$D6            ;
  DEFB $F5,$B7            ;
  DEFB $F5,$AF            ;
  DEFB $F5,$EF            ;
  DEFB $F7,$DE            ;
  DEFB $FB,$1E            ;
  DEFB $FC,$E1            ;
  DEFB $F1,$F5            ;
  DEFB $CB,$36            ;
  DEFB $3A,$F7            ;
  DEFB $F6,$D7            ;
  DEFB $F7,$B7            ;
  DEFB $F6,$6E            ;
  DEFB $FB,$DE            ;
  DEFB $FC,$09            ;
  DEFB $FD,$F3            ;
  DEFB $F3,$F9            ;
  DEFB $CB,$DA            ;
  DEFB $37,$DB            ;
  DEFB $F7,$D7            ;
  DEFB $F7,$37            ;
  DEFB $FB,$EE            ;
  DEFB $FD,$9D            ;
  DEFB $FC,$3B            ;
  DEFB $F3,$C0            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 25
;
; 16 by 64 pixels.
TILE25:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $03,$01            ;
  DEFB $0F,$A3            ;
  DEFB $19,$D9            ;
  DEFB $16,$DE            ;
  DEFB $16,$DF            ;
  DEFB $15,$DE            ;
  DEFB $1B,$BD            ;
  DEFB $0E,$7D            ;
  DEFB $00,$FB            ;
  DEFB $0F,$37            ;
  DEFB $19,$8F            ;
  DEFB $36,$AF            ;
  DEFB $2E,$B7            ;
  DEFB $2E,$B8            ;
  DEFB $7D,$BB            ;
  DEFB $73,$7A            ;
  DEFB $3E,$F7            ;
  DEFB $1C,$F7            ;
  DEFB $03,$77            ;
  DEFB $07,$8F            ;
  DEFB $0F,$CF            ;
  DEFB $1D,$56            ;
  DEFB $1B,$59            ;
  DEFB $16,$DB            ;
  DEFB $1D,$BB            ;
  DEFB $1B,$7B            ;
  DEFB $0E,$F7            ;
  DEFB $00,$F7            ;
  DEFB $07,$4F            ;
  DEFB $0F,$9F            ;
  DEFB $19,$AE            ;
  DEFB $36,$B5            ;
  DEFB $2D,$BB            ;
  DEFB $2D,$7B            ;
  DEFB $2F,$7B            ;
  DEFB $3E,$F7            ;
  DEFB $18,$F7            ;
  DEFB $07,$0F            ;
  DEFB $0F,$AF            ;
  DEFB $19,$B6            ;
  DEFB $17,$B9            ;
  DEFB $36,$BB            ;
  DEFB $3D,$BB            ;
  DEFB $33,$77            ;
  DEFB $1E,$F7            ;
  DEFB $00,$4F            ;
  DEFB $0F,$9F            ;
  DEFB $1F,$CF            ;
  DEFB $1E,$D4            ;
  DEFB $3E,$DA            ;
  DEFB $3E,$BA            ;
  DEFB $39,$BA            ;
  DEFB $1F,$77            ;
  DEFB $0C,$E8            ;
  DEFB $11,$D3            ;
  DEFB $1E,$0F            ;
  DEFB $3F,$3F            ;
  DEFB $3C,$FF            ;
  DEFB $73,$FF            ;
  DEFB $CF,$FC            ;

; Tile 50
;
; 16 by 64 pixels.
TILE50:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $20,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $EA,$00            ;
  DEFB $E5,$00            ;
  DEFB $E2,$00            ;
  DEFB $EA,$00            ;
  DEFB $EB,$80            ;
  DEFB $ED,$C0            ;
  DEFB $EE,$E0            ;
  DEFB $EF,$3C            ;
  DEFB $EF,$C2            ;
  DEFB $EF,$FF            ;
  DEFB $EF,$FC            ;
  DEFB $EF,$F3            ;
  DEFB $EF,$CF            ;
  DEFB $EF,$3F            ;
  DEFB $EC,$FF            ;
  DEFB $E3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $3F,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 51
;
; 16 by 64 pixels.
TILE51:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$03            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$07            ;
  DEFB $00,$17            ;
  DEFB $00,$17            ;
  DEFB $00,$17            ;
  DEFB $00,$37            ;
  DEFB $00,$37            ;
  DEFB $00,$37            ;
  DEFB $00,$77            ;
  DEFB $00,$77            ;
  DEFB $00,$F7            ;
  DEFB $00,$F7            ;
  DEFB $01,$F4            ;
  DEFB $03,$F3            ;
  DEFB $07,$CF            ;
  DEFB $0F,$3F            ;
  DEFB $3C,$FF            ;
  DEFB $73,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $3F,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 23
;
; 16 by 64 pixels.
TILE23:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $01,$C3            ;
  DEFB $07,$6F            ;
  DEFB $0E,$F3            ;
  DEFB $1D,$DF            ;
  DEFB $1B,$B5            ;
  DEFB $1A,$6E            ;
  DEFB $1F,$DF            ;
  DEFB $6F,$BF            ;
  DEFB $F6,$0F            ;
  DEFB $F1,$F7            ;
  DEFB $CB,$78            ;
  DEFB $36,$DA            ;
  DEFB $F5,$DA            ;
  DEFB $ED,$B7            ;
  DEFB $EE,$6F            ;
  DEFB $F7,$DF            ;
  DEFB $F0,$1F            ;
  DEFB $CD,$EF            ;
  DEFB $3B,$33            ;
  DEFB $F6,$14            ;
  DEFB $F4,$D6            ;
  DEFB $E9,$96            ;
  DEFB $EB,$36            ;
  DEFB $EC,$6F            ;
  DEFB $EF,$DF            ;
  DEFB $F6,$1F            ;
  DEFB $C9,$EF            ;
  DEFB $3B,$33            ;
  DEFB $F6,$D5            ;
  DEFB $ED,$B6            ;
  DEFB $EB,$AE            ;
  DEFB $DE,$6E            ;
  DEFB $DF,$DF            ;
  DEFB $EF,$BF            ;
  DEFB $C6,$3F            ;
  DEFB $39,$C7            ;
  DEFB $F7,$E3            ;
  DEFB $ED,$B4            ;
  DEFB $DB,$D6            ;
  DEFB $DB,$B6            ;
  DEFB $D8,$6F            ;
  DEFB $EF,$DF            ;
  DEFB $F7,$3F            ;
  DEFB $C8,$0F            ;
  DEFB $3B,$F7            ;
  DEFB $F7,$F9            ;
  DEFB $EF,$3A            ;
  DEFB $EE,$EA            ;
  DEFB $ED,$DA            ;
  DEFB $EF,$37            ;
  DEFB $EE,$EF            ;
  DEFB $F7,$9F            ;
  DEFB $C8,$7C            ;
  DEFB $3F,$B3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 26
;
; 16 by 64 pixels.
TILE26:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$01            ;
  DEFB $00,$07            ;
  DEFB $00,$1F            ;
  DEFB $00,$7F            ;
  DEFB $01,$FC            ;
  DEFB $07,$CF            ;
  DEFB $1D,$BF            ;
  DEFB $3F,$7F            ;
  DEFB $FC,$FF            ;
  DEFB $FF,$FF            ;
  DEFB $FE,$3C            ;
  DEFB $FD,$F3            ;
  DEFB $F9,$CF            ;
  DEFB $F7,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$DB            ;
  DEFB $CF,$EB            ;
  DEFB $3F,$EF            ;
  DEFB $F2,$F3            ;
  DEFB $F7,$D7            ;
  DEFB $DA,$7C            ;
  DEFB $F9,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$37            ;
  DEFB $FC,$F7            ;
  DEFB $F3,$CA            ;
  DEFB $CF,$FF            ;
  DEFB $3F,$3B            ;
  DEFB $FE,$EC            ;
  DEFB $E6,$F3            ;
  DEFB $FB,$CF            ;
  DEFB $E3,$3F            ;
  DEFB $9C,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$CB            ;
  DEFB $3F,$37            ;
  DEFB $FB,$EF            ;
  DEFB $D7,$FC            ;
  DEFB $FD,$F3            ;
  DEFB $D9,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$C4            ;
  DEFB $3F,$B7            ;
  DEFB $FF,$BF            ;
  DEFB $FE,$6C            ;
  DEFB $F1,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $1F,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $3F,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 27
;
; 16 by 64 pixels.
TILE27:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$03            ;
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FC            ;
  DEFB $03,$F3            ;
  DEFB $0F,$CE            ;
  DEFB $3F,$33            ;
  DEFB $FC,$F7            ;
  DEFB $F3,$F7            ;
  DEFB $CE,$EE            ;
  DEFB $3D,$EE            ;
  DEFB $DD,$F3            ;
  DEFB $FE,$FF            ;
  DEFB $FF,$7C            ;
  DEFB $FF,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FF            ;
  DEFB $39,$FF            ;
  DEFB $F6,$FF            ;
  DEFB $F6,$FC            ;
  DEFB $ED,$F3            ;
  DEFB $F3,$CF            ;
  DEFB $FF,$3E            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$7F            ;
  DEFB $CF,$67            ;
  DEFB $3E,$FF            ;
  DEFB $EE,$FF            ;
  DEFB $FA,$FC            ;
  DEFB $DD,$73            ;
  DEFB $FF,$CF            ;
  DEFB $FF,$3C            ;
  DEFB $FC,$E7            ;
  DEFB $F3,$DF            ;
  DEFB $CF,$BF            ;
  DEFB $3D,$7F            ;
  DEFB $F3,$FF            ;
  DEFB $C7,$FC            ;
  DEFB $FB,$B3            ;
  DEFB $E3,$CC            ;
  DEFB $5F,$3F            ;
  DEFB $EC,$F9            ;
  DEFB $F3,$F7            ;
  DEFB $CF,$F7            ;
  DEFB $3D,$DF            ;
  DEFB $DE,$BC            ;
  DEFB $EF,$73            ;
  DEFB $D9,$CF            ;
  DEFB $FB,$3F            ;
  DEFB $EC,$FF            ;
  DEFB $F3,$FC            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 28
;
; 16 by 64 pixels.
TILE28:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$01            ;
  DEFB $00,$07            ;
  DEFB $0E,$1F            ;
  DEFB $3B,$7F            ;
  DEFB $77,$9F            ;
  DEFB $EE,$AF            ;
  DEFB $DD,$AF            ;
  DEFB $D3,$77            ;
  DEFB $FE,$FB            ;
  DEFB $7D,$FC            ;
  DEFB $30,$7D            ;
  DEFB $0F,$BB            ;
  DEFB $1B,$C7            ;
  DEFB $36,$D7            ;
  DEFB $2E,$D7            ;
  DEFB $6D,$BB            ;
  DEFB $73,$7B            ;
  DEFB $3E,$FB            ;
  DEFB $00,$FC            ;
  DEFB $0F,$FD            ;
  DEFB $19,$9B            ;
  DEFB $30,$A7            ;
  DEFB $26,$B7            ;
  DEFB $4C,$B7            ;
  DEFB $59,$B7            ;
  DEFB $63,$7B            ;
  DEFB $7E,$FB            ;
  DEFB $30,$FC            ;
  DEFB $0F,$7E            ;
  DEFB $19,$9D            ;
  DEFB $36,$AB            ;
  DEFB $6D,$B7            ;
  DEFB $5D,$77            ;
  DEFB $F3,$77            ;
  DEFB $FE,$FB            ;
  DEFB $7D,$FB            ;
  DEFB $31,$FC            ;
  DEFB $0E,$3D            ;
  DEFB $3F,$1B            ;
  DEFB $6D,$A7            ;
  DEFB $DE,$B7            ;
  DEFB $DD,$B7            ;
  DEFB $C3,$7B            ;
  DEFB $7E,$FB            ;
  DEFB $39,$FC            ;
  DEFB $00,$7E            ;
  DEFB $1F,$BD            ;
  DEFB $3F,$CB            ;
  DEFB $79,$D7            ;
  DEFB $77,$57            ;
  DEFB $6E,$D7            ;
  DEFB $79,$BB            ;
  DEFB $76,$7D            ;
  DEFB $3C,$FE            ;
  DEFB $43,$E3            ;
  DEFB $EF,$8F            ;
  DEFB $F6,$3F            ;
  DEFB $78,$FF            ;
  DEFB $23,$FF            ;
  DEFB $0F,$FC            ;

; Tile 30
;
; 16 by 64 pixels.
TILE30:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$03            ;
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FF            ;
  DEFB $0F,$F9            ;
  DEFB $3F,$ED            ;
  DEFB $FF,$8D            ;
  DEFB $FE,$6D            ;
  DEFB $F9,$DD            ;
  DEFB $E7,$DD            ;
  DEFB $9F,$DD            ;
  DEFB $7F,$ED            ;
  DEFB $FF,$F0            ;
  DEFB $FF,$F5            ;
  DEFB $FF,$CD            ;
  DEFB $FF,$1D            ;
  DEFB $FC,$DD            ;
  DEFB $F3,$DD            ;
  DEFB $CF,$DD            ;
  DEFB $3F,$1D            ;
  DEFB $FC,$1D            ;
  DEFB $F0,$1C            ;
  DEFB $C8,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$DD            ;
  DEFB $1B,$DD            ;
  DEFB $1F,$1D            ;
  DEFB $3C,$1C            ;
  DEFB $F8,$1D            ;
  DEFB $D8,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$DD            ;
  DEFB $1B,$DD            ;
  DEFB $1F,$1D            ;
  DEFB $3C,$1C            ;
  DEFB $F8,$1D            ;
  DEFB $D8,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$1D            ;
  DEFB $18,$7D            ;
  DEFB $19,$FD            ;
  DEFB $07,$FC            ;
  DEFB $1F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FC            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 29
;
; 16 by 64 pixels.
TILE29:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$03            ;
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FE            ;
  DEFB $0F,$F9            ;
  DEFB $3F,$E7            ;
  DEFB $FF,$9F            ;
  DEFB $FE,$7F            ;
  DEFB $F9,$F7            ;
  DEFB $E7,$FF            ;
  DEFB $9F,$FF            ;
  DEFB $BF,$FF            ;
  DEFB $7C,$FC            ;
  DEFB $7B,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $BF,$3F            ;
  DEFB $DC,$FC            ;
  DEFB $E2,$30            ;
  DEFB $6E,$40            ;
  DEFB $EE,$A0            ;
  DEFB $EE,$50            ;
  DEFB $EE,$A0            ;
  DEFB $EE,$50            ;
  DEFB $AE,$A0            ;
  DEFB $EE,$53            ;
  DEFB $EE,$AF            ;
  DEFB $CE,$4C            ;
  DEFB $2E,$A0            ;
  DEFB $EE,$50            ;
  DEFB $EE,$A0            ;
  DEFB $EE,$50            ;
  DEFB $EE,$A0            ;
  DEFB $AE,$50            ;
  DEFB $EE,$A3            ;
  DEFB $EE,$4F            ;
  DEFB $CE,$AC            ;
  DEFB $2E,$50            ;
  DEFB $EE,$A0            ;
  DEFB $EE,$50            ;
  DEFB $EE,$A0            ;
  DEFB $CE,$50            ;
  DEFB $EE,$A0            ;
  DEFB $EE,$51            ;
  DEFB $6E,$A7            ;
  DEFB $EE,$1F            ;
  DEFB $CE,$7F            ;
  DEFB $2F,$FF            ;
  DEFB $EF,$FC            ;
  DEFB $EF,$F3            ;
  DEFB $EF,$CF            ;
  DEFB $EF,$3F            ;
  DEFB $EC,$FF            ;
  DEFB $E3,$FC            ;
  DEFB $CF,$F3            ;
  DEFB $3F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 31
;
; 16 by 56 pixels.
TILE31:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$C3            ;
  DEFB $FF,$31            ;
  DEFB $FC,$F0            ;
  DEFB $F0,$F8            ;
  DEFB $C8,$F8            ;
  DEFB $3A,$FC            ;
  DEFB $F6,$F8            ;
  DEFB $F7,$62            ;
  DEFB $EF,$8F            ;
  DEFB $CF,$8F            ;
  DEFB $1F,$DF            ;
  DEFB $7F,$DF            ;
  DEFB $7F,$DE            ;
  DEFB $7F,$9E            ;
  DEFB $7E,$0E            ;
  DEFB $7D,$DE            ;
  DEFB $3B,$DE            ;
  DEFB $03,$D8            ;
  DEFB $3B,$C2            ;
  DEFB $FB,$CE            ;
  DEFB $F9,$9E            ;
  DEFB $F0,$1E            ;
  DEFB $63,$9E            ;
  DEFB $07,$DE            ;
  DEFB $6F,$D8            ;
  DEFB $EF,$D3            ;
  DEFB $EF,$C7            ;
  DEFB $EF,$CF            ;
  DEFB $EF,$CF            ;
  DEFB $EF,$86            ;
  DEFB $E7,$00            ;
  DEFB $F7,$78            ;
  DEFB $F7,$7E            ;
  DEFB $E6,$7E            ;
  DEFB $C0,$3E            ;
  DEFB $01,$DE            ;
  DEFB $79,$DC            ;
  DEFB $FD,$C0            ;
  DEFB $FD,$EE            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FE,$EF            ;
  DEFB $FF,$03            ;
  DEFB $FF,$33            ;
  DEFB $7E,$7B            ;
  DEFB $18,$F8            ;
  DEFB $63,$F8            ;
  DEFB $73,$FC            ;
  DEFB $7B,$F0            ;
  DEFB $7B,$C0            ;
  DEFB $79,$00            ;
  DEFB $78,$00            ;
  DEFB $30,$00            ;
  DEFB $00,$00            ;

; Tile 32
;
; 16 by 64 pixels.
TILE32:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$07            ;
  DEFB $00,$37            ;
  DEFB $00,$F3            ;
  DEFB $00,$F8            ;
  DEFB $08,$F8            ;
  DEFB $3A,$FC            ;
  DEFB $F6,$F8            ;
  DEFB $F7,$62            ;
  DEFB $EF,$8F            ;
  DEFB $CF,$8F            ;
  DEFB $1F,$DF            ;
  DEFB $7F,$DF            ;
  DEFB $7F,$DE            ;
  DEFB $7F,$9E            ;
  DEFB $7E,$0E            ;
  DEFB $7D,$DE            ;
  DEFB $3B,$DE            ;
  DEFB $03,$D8            ;
  DEFB $3B,$C2            ;
  DEFB $FB,$CE            ;
  DEFB $F9,$9E            ;
  DEFB $F0,$1E            ;
  DEFB $67,$9E            ;
  DEFB $0F,$DE            ;
  DEFB $6F,$D8            ;
  DEFB $EF,$D3            ;
  DEFB $E7,$C7            ;
  DEFB $E7,$CF            ;
  DEFB $EF,$CE            ;
  DEFB $0F,$80            ;
  DEFB $6F,$14            ;
  DEFB $F4,$76            ;
  DEFB $F1,$F6            ;
  DEFB $C7,$E6            ;
  DEFB $1F,$9A            ;
  DEFB $7E,$7E            ;
  DEFB $79,$FA            ;
  DEFB $67,$FA            ;
  DEFB $5F,$FA            ;
  DEFB $3F,$E2            ;
  DEFB $9F,$A2            ;
  DEFB $C6,$22            ;
  DEFB $D8,$2A            ;
  DEFB $DC,$34            ;
  DEFB $CC,$65            ;
  DEFB $CF,$A5            ;
  DEFB $0E,$28            ;
  DEFB $67,$28            ;
  DEFB $73,$93            ;
  DEFB $79,$E7            ;
  DEFB $78,$CF            ;
  DEFB $7A,$1F            ;
  DEFB $7B,$1F            ;
  DEFB $3B,$8F            ;
  DEFB $9B,$E7            ;
  DEFB $C7,$F3            ;
  DEFB $F3,$F0            ;
  DEFB $FB,$F3            ;
  DEFB $F9,$CF            ;
  DEFB $F8,$3F            ;
  DEFB $F0,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; Tile 33
;
; 16 by 56 pixels.
TILE33:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CF            ;
  DEFB $FF,$33            ;
  DEFB $FC,$E8            ;
  DEFB $F3,$53            ;
  DEFB $CE,$83            ;
  DEFB $2D,$3C            ;
  DEFB $E8,$F8            ;
  DEFB $E3,$CC            ;
  DEFB $CF,$4C            ;
  DEFB $3C,$AB            ;
  DEFB $F3,$31            ;
  DEFB $D1,$11            ;
  DEFB $11,$2A            ;
  DEFB $2A,$AA            ;
  DEFB $2A,$64            ;
  DEFB $24,$46            ;
  DEFB $46,$66            ;
  DEFB $66,$99            ;
  DEFB $19,$98            ;
  DEFB $18,$99            ;
  DEFB $19,$95            ;
  DEFB $15,$56            ;
  DEFB $56,$22            ;
  DEFB $22,$23            ;
  DEFB $23,$55            ;
  DEFB $55,$4C            ;
  DEFB $4C,$C8            ;
  DEFB $48,$CC            ;
  DEFB $4C,$CB            ;
  DEFB $4B,$33            ;
  DEFB $33,$11            ;
  DEFB $11,$32            ;
  DEFB $32,$AA            ;
  DEFB $6A,$A4            ;
  DEFB $64,$43            ;
  DEFB $64,$4F            ;
  DEFB $56,$3F            ;
  DEFB $18,$FF            ;
  DEFB $43,$FE            ;
  DEFB $4F,$F9            ;
  DEFB $3F,$E7            ;
  DEFB $7F,$9F            ;
  DEFB $BE,$7E            ;
  DEFB $D9,$F9            ;
  DEFB $E7,$E7            ;
  DEFB $9F,$9F            ;
  DEFB $7E,$7F            ;
  DEFB $F9,$FF            ;
  DEFB $E7,$FC            ;
  DEFB $9F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 34
;
; 16 by 56 pixels.
TILE34:
  DEFB $38                ; Height in rows
  DEFB $3F,$F3            ; Two bytes a row, the bottom row first
  DEFB $FF,$CF            ;
  DEFB $FF,$37            ;
  DEFB $FC,$D7            ;
  DEFB $F3,$A7            ;
  DEFB $CD,$57            ;
  DEFB $3A,$A7            ;
  DEFB $D5,$57            ;
  DEFB $EA,$A7            ;
  DEFB $CF,$AB            ;
  DEFB $3F,$FC            ;
  DEFB $F2,$7F            ;
  DEFB $CE,$33            ;
  DEFB $19,$4B            ;
  DEFB $C8,$83            ;
  DEFB $49,$4B            ;
  DEFB $CE,$33            ;
  DEFB $AE,$33            ;
  DEFB $19,$4B            ;
  DEFB $18,$83            ;
  DEFB $29,$4B            ;
  DEFB $AE,$33            ;
  DEFB $6E,$33            ;
  DEFB $49,$4B            ;
  DEFB $68,$83            ;
  DEFB $99,$4B            ;
  DEFB $9E,$3B            ;
  DEFB $9E,$33            ;
  DEFB $99,$4B            ;
  DEFB $58,$83            ;
  DEFB $29,$43            ;
  DEFB $2E,$3B            ;
  DEFB $5E,$33            ;
  DEFB $49,$4B            ;
  DEFB $C8,$83            ;
  DEFB $C9,$4B            ;
  DEFB $CE,$33            ;
  DEFB $3E,$33            ;
  DEFB $19,$4B            ;
  DEFB $30,$82            ;
  DEFB $88,$41            ;
  DEFB $3F,$C7            ;
  DEFB $FF,$9F            ;
  DEFB $FE,$7E            ;
  DEFB $F9,$F9            ;
  DEFB $E7,$E7            ;
  DEFB $9F,$9F            ;
  DEFB $7E,$7F            ;
  DEFB $F9,$FF            ;
  DEFB $E7,$FC            ;
  DEFB $9F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 35
;
; 16 by 56 pixels.
TILE35:
  DEFB $38                ; Height in rows
  DEFB $3F,$F1            ; Two bytes a row, the bottom row first
  DEFB $FF,$C3            ;
  DEFB $FF,$13            ;
  DEFB $FC,$7B            ;
  DEFB $F0,$FB            ;
  DEFB $C6,$FB            ;
  DEFB $1E,$F8            ;
  DEFB $78,$F8            ;
  DEFB $77,$F8            ;
  DEFB $07,$E1            ;
  DEFB $3B,$C3            ;
  DEFB $38,$37            ;
  DEFB $7B,$F7            ;
  DEFB $7B,$F0            ;
  DEFB $7B,$F1            ;
  DEFB $7B,$E3            ;
  DEFB $FB,$DB            ;
  DEFB $F8,$3B            ;
  DEFB $F1,$BA            ;
  DEFB $F7,$B9            ;
  DEFB $F7,$A5            ;
  DEFB $77,$8B            ;
  DEFB $77,$95            ;
  DEFB $73,$A9            ;
  DEFB $7B,$95            ;
  DEFB $0B,$A9            ;
  DEFB $E3,$95            ;
  DEFB $F3,$A3            ;
  DEFB $F3,$8F            ;
  DEFB $F7,$BD            ;
  DEFB $F7,$B1            ;
  DEFB $E7,$89            ;
  DEFB $E7,$95            ;
  DEFB $F3,$A9            ;
  DEFB $F3,$95            ;
  DEFB $FB,$A9            ;
  DEFB $FB,$94            ;
  DEFB $FB,$A3            ;
  DEFB $73,$8F            ;
  DEFB $03,$BF            ;
  DEFB $CF,$BC            ;
  DEFB $EF,$B1            ;
  DEFB $EF,$81            ;
  DEFB $EF,$19            ;
  DEFB $EC,$3C            ;
  DEFB $E0,$3C            ;
  DEFB $F3,$79            ;
  DEFB $E7,$7B            ;
  DEFB $EF,$7B            ;
  DEFB $0F,$78            ;
  DEFB $8F,$B0            ;
  DEFB $E7,$80            ;
  DEFB $F7,$00            ;
  DEFB $F4,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 36
;
; 16 by 56 pixels.
TILE36:
  DEFB $38                ; Height in rows
  DEFB $3F,$F0            ; Two bytes a row, the bottom row first
  DEFB $FF,$C7            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$7C            ;
  DEFB $F1,$F9            ;
  DEFB $C3,$E3            ;
  DEFB $00,$0F            ;
  DEFB $7E,$1F            ;
  DEFB $FE,$1E            ;
  DEFB $F8,$CC            ;
  DEFB $F7,$E3            ;
  DEFB $EF,$EF            ;
  DEFB $E7,$DF            ;
  DEFB $CF,$DF            ;
  DEFB $8F,$9F            ;
  DEFB $1F,$1F            ;
  DEFB $EE,$0F            ;
  DEFB $F4,$6F            ;
  DEFB $F1,$EF            ;
  DEFB $C5,$EF            ;
  DEFB $1D,$EF            ;
  DEFB $5D,$CC            ;
  DEFB $DD,$C0            ;
  DEFB $D9,$C0            ;
  DEFB $C5,$CC            ;
  DEFB $AB,$CC            ;
  DEFB $55,$C0            ;
  DEFB $AB,$EC            ;
  DEFB $95,$EC            ;
  DEFB $A1,$EC            ;
  DEFB $81,$EC            ;
  DEFB $81,$CC            ;
  DEFB $8D,$CE            ;
  DEFB $BD,$CF            ;
  DEFB $F1,$CF            ;
  DEFB $C1,$C7            ;
  DEFB $81,$C7            ;
  DEFB $81,$F7            ;
  DEFB $81,$F2            ;
  DEFB $81,$F0            ;
  DEFB $81,$F3            ;
  DEFB $81,$F3            ;
  DEFB $8D,$C3            ;
  DEFB $3D,$13            ;
  DEFB $FC,$77            ;
  DEFB $F1,$E7            ;
  DEFB $C7,$97            ;
  DEFB $16,$33            ;
  DEFB $70,$F3            ;
  DEFB $F9,$F0            ;
  DEFB $FD,$E0            ;
  DEFB $F1,$C0            ;
  DEFB $8D,$00            ;
  DEFB $3C,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 37
;
; 16 by 56 pixels.
TILE37:
  DEFB $38                ; Height in rows
  DEFB $3F,$F2            ; Two bytes a row, the bottom row first
  DEFB $FF,$CE            ;
  DEFB $FF,$3E            ;
  DEFB $FC,$FE            ;
  DEFB $F3,$FE            ;
  DEFB $CF,$FD            ;
  DEFB $0F,$FD            ;
  DEFB $0F,$FD            ;
  DEFB $CF,$FB            ;
  DEFB $EF,$FB            ;
  DEFB $EF,$FB            ;
  DEFB $EF,$F0            ;
  DEFB $EF,$C7            ;
  DEFB $EF,$37            ;
  DEFB $6C,$F7            ;
  DEFB $00,$F7            ;
  DEFB $FC,$F7            ;
  DEFB $FC,$F7            ;
  DEFB $F8,$F7            ;
  DEFB $60,$F7            ;
  DEFB $1C,$F7            ;
  DEFB $7C,$F7            ;
  DEFB $FC,$F7            ;
  DEFB $E0,$F0            ;
  DEFB $0C,$C7            ;
  DEFB $FC,$37            ;
  DEFB $F8,$F7            ;
  DEFB $F3,$F7            ;
  DEFB $83,$F7            ;
  DEFB $7B,$F7            ;
  DEFB $7B,$F0            ;
  DEFB $FB,$C7            ;
  DEFB $F3,$37            ;
  DEFB $40,$F7            ;
  DEFB $1C,$F7            ;
  DEFB $7C,$F7            ;
  DEFB $7C,$F7            ;
  DEFB $F8,$F7            ;
  DEFB $F0,$F7            ;
  DEFB $06,$F7            ;
  DEFB $7E,$F0            ;
  DEFB $7E,$CB            ;
  DEFB $7E,$3B            ;
  DEFB $98,$FD            ;
  DEFB $C3,$FD            ;
  DEFB $EF,$FE            ;
  DEFB $EF,$FE            ;
  DEFB $4F,$FE            ;
  DEFB $2F,$FF            ;
  DEFB $EF,$FC            ;
  DEFB $EF,$F0            ;
  DEFB $EF,$C0            ;
  DEFB $EF,$00            ;
  DEFB $CC,$00            ;
  DEFB $C0,$00            ;
  DEFB $C0,$00            ;

; Tile 38
;
; 16 by 56 pixels.
TILE38:
  DEFB $38                ; Height in rows
  DEFB $3F,$F0            ; Two bytes a row, the bottom row first
  DEFB $FF,$C0            ;
  DEFB $FF,$33            ;
  DEFB $FC,$F7            ;
  DEFB $F3,$F7            ;
  DEFB $CF,$F7            ;
  DEFB $3F,$F6            ;
  DEFB $FF,$F0            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$F7            ;
  DEFB $FF,$CF            ;
  DEFB $7F,$1C            ;
  DEFB $3C,$00            ;
  DEFB $12,$1E            ;
  DEFB $0E,$FE            ;
  DEFB $1E,$FE            ;
  DEFB $1E,$71            ;
  DEFB $1E,$07            ;
  DEFB $1E,$3F            ;
  DEFB $1E,$FF            ;
  DEFB $1E,$FE            ;
  DEFB $1E,$F1            ;
  DEFB $1E,$C7            ;
  DEFB $1E,$1F            ;
  DEFB $1C,$DF            ;
  DEFB $13,$DC            ;
  DEFB $0F,$C3            ;
  DEFB $1F,$DF            ;
  DEFB $1F,$DE            ;
  DEFB $1F,$C0            ;
  DEFB $1F,$0E            ;
  DEFB $1C,$7E            ;
  DEFB $12,$7C            ;
  DEFB $0E,$F3            ;
  DEFB $1E,$CF            ;
  DEFB $1E,$3F            ;
  DEFB $1E,$FF            ;
  DEFB $1E,$FF            ;
  DEFB $1E,$7C            ;
  DEFB $1E,$01            ;
  DEFB $1E,$33            ;
  DEFB $1C,$F3            ;
  DEFB $1B,$F7            ;
  DEFB $0F,$F7            ;
  DEFB $1F,$F7            ;
  DEFB $1F,$F7            ;
  DEFB $3F,$F3            ;
  DEFB $3F,$F0            ;
  DEFB $7F,$F0            ;
  DEFB $7F,$C0            ;
  DEFB $FF,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 39
;
; 16 by 56 pixels.
TILE39:
  DEFB $38                ; Height in rows
  DEFB $3F,$F0            ; Two bytes a row, the bottom row first
  DEFB $FF,$CE            ;
  DEFB $FF,$1E            ;
  DEFB $FC,$1E            ;
  DEFB $F3,$9E            ;
  DEFB $CF,$DF            ;
  DEFB $3F,$EF            ;
  DEFB $7F,$E6            ;
  DEFB $7F,$E1            ;
  DEFB $7F,$C7            ;
  DEFB $3F,$1F            ;
  DEFB $8C,$7F            ;
  DEFB $C1,$FC            ;
  DEFB $C7,$F3            ;
  DEFB $DF,$CF            ;
  DEFB $1F,$3F            ;
  DEFB $9C,$FF            ;
  DEFB $DB,$C3            ;
  DEFB $C7,$3C            ;
  DEFB $F0,$BC            ;
  DEFB $FD,$BC            ;
  DEFB $FD,$BC            ;
  DEFB $19,$BC            ;
  DEFB $E1,$BF            ;
  DEFB $FD,$BC            ;
  DEFB $3D,$BC            ;
  DEFB $8D,$BE            ;
  DEFB $E1,$BE            ;
  DEFB $F9,$BF            ;
  DEFB $F9,$BF            ;
  DEFB $C1,$BF            ;
  DEFB $1D,$DF            ;
  DEFB $7C,$DF            ;
  DEFB $7E,$EF            ;
  DEFB $78,$EF            ;
  DEFB $62,$77            ;
  DEFB $0F,$7B            ;
  DEFB $7F,$3D            ;
  DEFB $7F,$9E            ;
  DEFB $3E,$07            ;
  DEFB $38,$B9            ;
  DEFB $81,$BE            ;
  DEFB $DF,$BE            ;
  DEFB $FF,$1C            ;
  DEFB $FC,$43            ;
  DEFB $F0,$E7            ;
  DEFB $C3,$F7            ;
  DEFB $13,$F7            ;
  DEFB $73,$F7            ;
  DEFB $F9,$F0            ;
  DEFB $F9,$F0            ;
  DEFB $FC,$C0            ;
  DEFB $FC,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 40
;
; 16 by 56 pixels.
TILE40:
  DEFB $38                ; Height in rows
  DEFB $3F,$F2            ; Two bytes a row, the bottom row first
  DEFB $FF,$C7            ;
  DEFB $FF,$1F            ;
  DEFB $FC,$3F            ;
  DEFB $F0,$3F            ;
  DEFB $C6,$3F            ;
  DEFB $1F,$3F            ;
  DEFB $FF,$3F            ;
  DEFB $FF,$1E            ;
  DEFB $FF,$04            ;
  DEFB $FE,$31            ;
  DEFB $F8,$D9            ;
  DEFB $71,$D9            ;
  DEFB $67,$DB            ;
  DEFB $1F,$DB            ;
  DEFB $7F,$0B            ;
  DEFB $FC,$F3            ;
  DEFB $F3,$C0            ;
  DEFB $CF,$23            ;
  DEFB $3D,$67            ;
  DEFB $FD,$6F            ;
  DEFB $FB,$6F            ;
  DEFB $FB,$66            ;
  DEFB $F3,$60            ;
  DEFB $E3,$6E            ;
  DEFB $23,$6E            ;
  DEFB $23,$6E            ;
  DEFB $23,$6E            ;
  DEFB $2F,$6E            ;
  DEFB $33,$64            ;
  DEFB $E3,$60            ;
  DEFB $23,$66            ;
  DEFB $27,$6F            ;
  DEFB $26,$EF            ;
  DEFB $26,$CF            ;
  DEFB $26,$DF            ;
  DEFB $2E,$DF            ;
  DEFB $2C,$8F            ;
  DEFB $9D,$A7            ;
  DEFB $FB,$BB            ;
  DEFB $FB,$3C            ;
  DEFB $F7,$7C            ;
  DEFB $EE,$7D            ;
  DEFB $DC,$7B            ;
  DEFB $B9,$37            ;
  DEFB $73,$07            ;
  DEFB $E6,$07            ;
  DEFB $CC,$E7            ;
  DEFB $8D,$F3            ;
  DEFB $01,$F0            ;
  DEFB $39,$F0            ;
  DEFB $FD,$C0            ;
  DEFB $FC,$00            ;
  DEFB $FC,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 41
;
; 16 by 56 pixels.
TILE41:
  DEFB $38                ; Height in rows
  DEFB $3F,$F0            ; Two bytes a row, the bottom row first
  DEFB $FF,$CF            ;
  DEFB $FF,$0F            ;
  DEFB $FC,$DF            ;
  DEFB $F7,$DF            ;
  DEFB $DF,$9F            ;
  DEFB $3F,$3F            ;
  DEFB $7E,$7E            ;
  DEFB $7E,$FE            ;
  DEFB $00,$FE            ;
  DEFB $1E,$78            ;
  DEFB $3F,$62            ;
  DEFB $FF,$0E            ;
  DEFB $FE,$3E            ;
  DEFB $FC,$7E            ;
  DEFB $73,$7E            ;
  DEFB $07,$3E            ;
  DEFB $77,$BE            ;
  DEFB $F7,$86            ;
  DEFB $F7,$90            ;
  DEFB $F6,$6B            ;
  DEFB $61,$EB            ;
  DEFB $07,$EB            ;
  DEFB $5F,$EB            ;
  DEFB $DE,$6A            ;
  DEFB $D8,$68            ;
  DEFB $D8,$6B            ;
  DEFB $18,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$E8            ;
  DEFB $DC,$E8            ;
  DEFB $1C,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $DC,$EB            ;
  DEFB $5C,$EB            ;
  DEFB $1C,$6A            ;
  DEFB $58,$68            ;
  DEFB $58,$68            ;
  DEFB $59,$E9            ;
  DEFB $5F,$EB            ;
  DEFB $1F,$97            ;
  DEFB $DE,$67            ;
  DEFB $D9,$07            ;
  DEFB $06,$37            ;
  DEFB $C0,$F3            ;
  DEFB $F3,$F0            ;
  DEFB $FB,$F0            ;
  DEFB $FB,$C0            ;
  DEFB $F9,$00            ;
  DEFB $F0,$00            ;
  DEFB $F0,$00            ;
  DEFB $C0,$00            ;

; Tile 43
;
; 16 by 64 pixels.
TILE43:
  DEFB $40                ; Height in rows
  DEFB $00,$00            ; Two bytes a row, the bottom row first
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $08,$00            ;
  DEFB $3A,$00            ;
  DEFB $7B,$00            ;
  DEFB $7B,$C0            ;
  DEFB $7B,$F7            ;
  DEFB $7B,$F7            ;
  DEFB $73,$D7            ;
  DEFB $49,$F7            ;
  DEFB $3A,$77            ;
  DEFB $7B,$87            ;
  DEFB $7B,$B0            ;
  DEFB $7B,$BF            ;
  DEFB $61,$B9            ;
  DEFB $1A,$10            ;
  DEFB $7B,$8F            ;
  DEFB $7B,$E0            ;
  DEFB $7B,$E9            ;
  DEFB $71,$AE            ;
  DEFB $48,$EF            ;
  DEFB $3A,$6A            ;
  DEFB $7B,$87            ;
  DEFB $7B,$D0            ;
  DEFB $7B,$1F            ;
  DEFB $60,$99            ;
  DEFB $1A,$59            ;
  DEFB $7B,$13            ;
  DEFB $7B,$CC            ;
  DEFB $7B,$90            ;
  DEFB $79,$58            ;
  DEFB $60,$D0            ;
  DEFB $02,$00            ;
  DEFB $71,$80            ;
  DEFB $7A,$40            ;
  DEFB $7B,$00            ;
  DEFB $7B,$00            ;
  DEFB $7A,$00            ;
  DEFB $25,$00            ;
  DEFB $1D,$00            ;
  DEFB $3E,$80            ;
  DEFB $1F,$40            ;
  DEFB $0E,$90            ;
  DEFB $45,$E3            ;
  DEFB $E3,$F7            ;
  DEFB $F3,$F7            ;
  DEFB $F9,$E7            ;
  DEFB $FC,$EF            ;
  DEFB $FC,$0F            ;
  DEFB $F8,$1F            ;
  DEFB $F3,$9E            ;
  DEFB $CF,$C0            ;
  DEFB $0F,$FF            ;
  DEFB $63,$FF            ;
  DEFB $F8,$F8            ;
  DEFB $FE,$63            ;
  DEFB $FE,$0F            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $0F,$FC            ;

; Tile 44
;
; 16 by 64 pixels.
TILE44:
  DEFB $40                ; Height in rows
  DEFB $00,$02            ; Two bytes a row, the bottom row first
  DEFB $00,$0E            ;
  DEFB $00,$3E            ;
  DEFB $00,$3E            ;
  DEFB $00,$3E            ;
  DEFB $00,$38            ;
  DEFB $00,$A6            ;
  DEFB $00,$9E            ;
  DEFB $00,$BE            ;
  DEFB $01,$BE            ;
  DEFB $01,$BE            ;
  DEFB $00,$38            ;
  DEFB $01,$26            ;
  DEFB $03,$1E            ;
  DEFB $02,$3E            ;
  DEFB $14,$3E            ;
  DEFB $64,$3E            ;
  DEFB $F4,$3E            ;
  DEFB $C6,$3C            ;
  DEFB $D4,$32            ;
  DEFB $B0,$0E            ;
  DEFB $C8,$3E            ;
  DEFB $30,$3E            ;
  DEFB $60,$3E            ;
  DEFB $50,$3E            ;
  DEFB $69,$38            ;
  DEFB $53,$26            ;
  DEFB $45,$1E            ;
  DEFB $0C,$3E            ;
  DEFB $A9,$3E            ;
  DEFB $28,$3E            ;
  DEFB $2C,$3C            ;
  DEFB $C0,$32            ;
  DEFB $00,$0E            ;
  DEFB $70,$3E            ;
  DEFB $20,$3E            ;
  DEFB $40,$3E            ;
  DEFB $00,$3E            ;
  DEFB $00,$3E            ;
  DEFB $00,$00            ;
  DEFB $00,$3C            ;
  DEFB $00,$3C            ;
  DEFB $00,$7C            ;
  DEFB $00,$79            ;
  DEFB $00,$39            ;
  DEFB $00,$CB            ;
  DEFB $00,$F3            ;
  DEFB $01,$F7            ;
  DEFB $01,$E7            ;
  DEFB $02,$E7            ;
  DEFB $07,$47            ;
  DEFB $0F,$93            ;
  DEFB $2F,$BB            ;
  DEFB $EF,$39            ;
  DEFB $F6,$3C            ;
  DEFB $F0,$FC            ;
  DEFB $F9,$FC            ;
  DEFB $F9,$F0            ;
  DEFB $F3,$C3            ;
  DEFB $C7,$0F            ;
  DEFB $0F,$3F            ;
  DEFB $1C,$FF            ;
  DEFB $13,$FF            ;
  DEFB $CF,$FC            ;

; Tile 45
;
; 16 by 64 pixels.
TILE45:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3E            ;
  DEFB $00,$FE            ;
  DEFB $03,$FC            ;
  DEFB $0F,$F2            ;
  DEFB $3F,$CE            ;
  DEFB $FF,$2E            ;
  DEFB $FC,$DE            ;
  DEFB $73,$1E            ;
  DEFB $EC,$5E            ;
  DEFB $C2,$9E            ;
  DEFB $15,$5E            ;
  DEFB $D2,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4A            ;
  DEFB $DA,$AA            ;
  DEFB $E9,$4E            ;
  DEFB $EA,$AE            ;
  DEFB $E9,$4A            ;
  DEFB $EA,$AE            ;
  DEFB $E9,$4A            ;
  DEFB $6A,$AA            ;
  DEFB $69,$4A            ;
  DEFB $6A,$9A            ;
  DEFB $69,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $A9,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $A9,$5E            ;
  DEFB $AA,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$9E            ;
  DEFB $D5,$5E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $D2,$AE            ;
  DEFB $D5,$4E            ;
  DEFB $AA,$AE            ;
  DEFB $A5,$4F            ;
  DEFB $AA,$AF            ;
  DEFB $A5,$4E            ;
  DEFB $AA,$A9            ;
  DEFB $D5,$47            ;
  DEFB $D2,$9F            ;
  DEFB $D5,$79            ;
  DEFB $D0,$FB            ;
  DEFB $D3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $9F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $FC,$FF            ;
  DEFB $73,$FF            ;
  DEFB $CF,$FC            ;

; Tile 46
;
; 16 by 64 pixels.
TILE46:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0E            ;
  DEFB $00,$3E            ;
  DEFB $00,$FF            ;
  DEFB $03,$BF            ;
  DEFB $0E,$3C            ;
  DEFB $3C,$F3            ;
  DEFB $F3,$CB            ;
  DEFB $EF,$33            ;
  DEFB $7E,$C3            ;
  DEFB $E1,$2B            ;
  DEFB $96,$53            ;
  DEFB $48,$AB            ;
  DEFB $E9,$53            ;
  DEFB $EA,$AB            ;
  DEFB $E9,$53            ;
  DEFB $EA,$AB            ;
  DEFB $E9,$55            ;
  DEFB $EA,$A5            ;
  DEFB $E9,$55            ;
  DEFB $D2,$AA            ;
  DEFB $D5,$52            ;
  DEFB $D2,$AA            ;
  DEFB $D5,$53            ;
  DEFB $D2,$AB            ;
  DEFB $D5,$53            ;
  DEFB $EA,$AB            ;
  DEFB $E9,$53            ;
  DEFB $EA,$A9            ;
  DEFB $E9,$55            ;
  DEFB $6A,$A9            ;
  DEFB $69,$55            ;
  DEFB $6A,$A9            ;
  DEFB $A9,$55            ;
  DEFB $AA,$AB            ;
  DEFB $B5,$53            ;
  DEFB $B4,$AB            ;
  DEFB $95,$53            ;
  DEFB $94,$AB            ;
  DEFB $D5,$53            ;
  DEFB $D4,$AB            ;
  DEFB $D5,$53            ;
  DEFB $D4,$A7            ;
  DEFB $95,$57            ;
  DEFB $B4,$A7            ;
  DEFB $B5,$53            ;
  DEFB $B4,$AB            ;
  DEFB $A9,$53            ;
  DEFB $AA,$AB            ;
  DEFB $A9,$53            ;
  DEFB $6A,$AB            ;
  DEFB $69,$52            ;
  DEFB $6A,$A9            ;
  DEFB $69,$47            ;
  DEFB $EA,$BE            ;
  DEFB $E8,$7F            ;
  DEFB $E9,$FF            ;
  DEFB $E3,$FC            ;
  DEFB $9F,$F3            ;
  DEFB $7F,$CF            ;
  DEFB $FF,$3F            ;
  DEFB $7C,$FF            ;
  DEFB $73,$FF            ;
  DEFB $CF,$FC            ;

; Tile 49
;
; 16 by 64 pixels.
TILE49:
  DEFB $40                ; Height in rows
  DEFB $00,$03            ; Two bytes a row, the bottom row first
  DEFB $00,$0F            ;
  DEFB $00,$3F            ;
  DEFB $00,$FF            ;
  DEFB $03,$FC            ;
  DEFB $0F,$F3            ;
  DEFB $3F,$C7            ;
  DEFB $FF,$07            ;
  DEFB $FC,$57            ;
  DEFB $F1,$27            ;
  DEFB $CD,$57            ;
  DEFB $3A,$AB            ;
  DEFB $FA,$53            ;
  DEFB $F4,$AB            ;
  DEFB $F5,$53            ;
  DEFB $F4,$AB            ;
  DEFB $F5,$53            ;
  DEFB $74,$AB            ;
  DEFB $69,$53            ;
  DEFB $6A,$AB            ;
  DEFB $69,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $75,$53            ;
  DEFB $74,$AB            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AB            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AB            ;
  DEFB $7A,$57            ;
  DEFB $7A,$A7            ;
  DEFB $7A,$57            ;
  DEFB $7A,$A7            ;
  DEFB $3A,$57            ;
  DEFB $3A,$A7            ;
  DEFB $3D,$57            ;
  DEFB $3D,$27            ;
  DEFB $3D,$57            ;
  DEFB $3D,$27            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$2F            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$2F            ;
  DEFB $3D,$4F            ;
  DEFB $3D,$27            ;
  DEFB $3B,$57            ;
  DEFB $3A,$A7            ;
  DEFB $7A,$53            ;
  DEFB $7A,$AA            ;
  DEFB $7A,$51            ;
  DEFB $7A,$A7            ;
  DEFB $7A,$1E            ;
  DEFB $F8,$FE            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;
  DEFB $3F,$F3            ;
  DEFB $FF,$CF            ;
  DEFB $CF,$3F            ;
  DEFB $DC,$FF            ;
  DEFB $F3,$FF            ;
  DEFB $CF,$FC            ;

; The border's characters
BORDER_CHARS:
  DEFB $06                ; Character 0
  DEFB $05                ;
  DEFB $03                ;
  DEFB $07                ;
  DEFB $0E                ;
  DEFB $1C                ;
  DEFB $38                ;
  DEFB $70                ;
  DEFB $E0                ; Character 1
  DEFB $C0                ;
  DEFB $A0                ;
  DEFB $60                ;
  DEFB $70                ;
  DEFB $38                ;
  DEFB $1C                ;
  DEFB $0E                ;
  DEFB $70                ; Character 2
  DEFB $38                ;
  DEFB $1C                ;
  DEFB $0E                ;
  DEFB $06                ;
  DEFB $01                ;
  DEFB $03                ;
  DEFB $07                ;
  DEFB $0E                ; Character 3
  DEFB $1C                ;
  DEFB $38                ;
  DEFB $70                ;
  DEFB $E0                ;
  DEFB $C0                ;
  DEFB $A0                ;
  DEFB $60                ;
  DEFB $00                ; Character 4
  DEFB $01                ;
  DEFB $03                ;
  DEFB $07                ;
  DEFB $0E                ;
  DEFB $DC                ;
  DEFB $B8                ;
  DEFB $70                ;
  DEFB $00                ; Character 5
  DEFB $80                ;
  DEFB $C0                ;
  DEFB $E0                ;
  DEFB $70                ;
  DEFB $39                ;
  DEFB $1B                ;
  DEFB $07                ;
  DEFB $E0                ; Character 6
  DEFB $D8                ;
  DEFB $9C                ;
  DEFB $0E                ;
  DEFB $07                ;
  DEFB $03                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $0E                ; Character 7
  DEFB $1D                ;
  DEFB $3B                ;
  DEFB $70                ;
  DEFB $E0                ;
  DEFB $C0                ;
  DEFB $80                ;
  DEFB $00                ;
  DEFB $00                ; Character 8
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $07                ;
  DEFB $07                ;
  DEFB $06                ;
  DEFB $00                ; Character 9
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $00                ;
  DEFB $06                ; Character 10
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $00                ; Character 11
  DEFB $7F                ;
  DEFB $7F                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $00                ; Character 12
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $E0                ;
  DEFB $E0                ;
  DEFB $60                ;
  DEFB $00                ; Character 13
  DEFB $FE                ;
  DEFB $FE                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $60                ; Character 14
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $06                ; Character 15
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $FE                ;
  DEFB $FE                ;
  DEFB $00                ;
  DEFB $00                ; Character 16
  DEFB $FF                ;
  DEFB $FF                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $60                ; Character 17
  DEFB $E0                ;
  DEFB $E0                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $06                ; Character 18
  DEFB $07                ;
  DEFB $07                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $60                ; Character 19
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $7F                ;
  DEFB $7F                ;
  DEFB $00                ;

; Game variables and the object records
;
; Cleared from here at the first start (START), and from CELL_LOOKED_UP at
; every new game (NEW_GAME), so only the random number, the font base, the
; saved stack pointer and the two control bytes survive from one game to the
; next; the turn counter is outside the cleared part too, but is set again from
; FRAMES at every new game. The snapshot's bytes here are what the tape's block
; held: none of them is ever read before it is written.
;
; The 23 object records from KNIGHT on are 16 bytes each, updated in turn every
; turn by the main loop through UPDATES: +0 the graphic, which picks the update
; routine (0 an empty record); +1 and +2 U, a word whose high byte is the
; town's column and low byte the place across the cell; +3 and +4 V the same,
; the high byte the row; +5 the speed (for a find, the type of cell it came
; from, SPAWN_FIND); +6 the facing in bits 6 and 7 (bit 6 along U rather than
; V, bit 7 backwards), and in the low bits a count -- for the knight bits 0-2,
; his turning; for a monster or a find bits 0-5, the turns before it next
; changes direction (WANDER_STEP, STEER); +7 the flags -- bit 0 stopped by a
; wall this turn (MOVE_CLIPPED), bit 1 drawn this turn (DRAW_SPRITE, cleared by
; the sound routines that play only for things on the screen), bit 5 a monster
; that makes for the knight when it turns (STEER), bit 6 its sprite mirrored
; and bit 7 upside down (TURN_SPRITE); +8 and +9 the half-size in U and V,
; centre to edge; +A and +B this turn's step in U and V, signed; +C and +D the
; drawing offset, added to where it projects on the screen; +E and +F where it
; was last drawn.
RANDOM:
  DEFB $00,$00            ; The random number, stirred with R and the turn
                          ; counter after every record's update and at every
                          ; random choice (NEXT_TURN)
FONT_BASE:
  DEFB $00,$00            ; The address of character code 0 for the printer
                          ; (PRINT_CHAR): each routine that prints sets it
                          ; first -- but see PRINT_PERCENTAGE
SAVED_SP:
  DEFB $00,$00            ; The stack pointer, kept while the drawing and the
                          ; clearing of the buffers borrow SP (SHOW_PLAY_AREA)
CONTROL:
  DEFB $00                ; Control method: bits 1-2 keyboard, Kempston,
                          ; cursor, Interface II; bit 3 directional control
                          ; (MENU)
LAST_CONTROL:
  DEFB $1E                ; The control method before the last key on the menu
TURNS:
  DEFB $00,$00            ; The turn counter: FRAMES at every new game
                          ; (NEW_GAME), one more each turn (NEXT_TURN); its low
                          ; byte paces the finds (SPAWN_FIND), the monsters
                          ; (SPAWN_MONSTER) and the creature (SPAWN_CREATURE)
CELL_LOOKED_UP:
  DEFB $00,$0F            ; The column and row last looked up on the map
                          ; (LOOK_UP_CELL)
DRAW_X:
  DEFB $00,$3F            ; Where on the screen a thing or a building is drawn:
                          ; x
DRAW_Y:
  DEFB $1E,$80            ; ...and y
VIEW:
  DEFB $00                ; Bit 0: the town is seen turned round, from the
                          ; other side (Z or SYMBOL SHIFT, TURN_TOWN); the
                          ; panel's heading says south instead of north
                          ; (PRINT_HEADING)
COLUMNS_DRAWN:
  DEFB $1F,$0F            ; A bit for each column of the screen a building has
                          ; been drawn in this turn (DRAW_WALL_COLUMN)
KEY_LATCH:
  DEFB $FF                ; Set while a key that acts once a press is held
TOP_SPEED:
  DEFB $03                ; The knight's top speed: 10, and 18 while a bonus's
                          ; faster walk lasts (SPEED_BONUS)
MENU_SHOWN:
  DEFB $C0                ; Set once the menu's frame has been drawn
                          ; (DISPLAY_MENU)
CELL_TYPE:
  DEFB $80                ; The type of the cell being drawn (DRAW_WALLS)
TUNE_PLAYED:
  DEFB $3F                ; Set once the menu's tune has played
                          ; (PLAY_TUNE_ONCE); cleared with the rest at every
                          ; new game, so it plays again after each
SPRITE_WIDTH:
  DEFB $1C                ; The width of the sprite being drawn
SPRITE_ROWS:
  DEFB $FF                ; The rows of it that are drawn
DRAW_LIST_AT:
  DEFB $FC,$E0            ; Pointers into the list of things to draw
                          ; (SORT_AND_DRAW_THINGS)
DRAW_LIST_NEXT:
  DEFB $40,$1F
FIRE_DELAY:
  DEFB $0B                ; Turns before the knight can throw again
                          ; (KNIGHT_THROWS)
SCORE:
  DEFB $FF                ; The score, BCD, highest first: the top two digits,
                          ; of which only the lower is printed (ADD_SCORE)
  DEFB $FF                ; The next two, where a villain's 250000 goes
SCORE_LOW:
  DEFB $C0                ; The next two, the hundreds and thousands, where
                          ; everything else scores
SCORE_ZEROS:
  DEFB $80                ; Printed as the score's last two digits, and never
                          ; written: so every score ends 00
LIVES:
  DEFB $0F                ; Lives in hand besides the one being played: six at
                          ; a new game, from the code at LIVES_BYTE (NEW_GAME),
                          ; and one taken as each life starts, the first
                          ; included; none left to take is game over (NEW_LIFE)
STOCKS:
  DEFB $07,$FF,$FF,$E0,$C0,$1F ; How many more finds the cells of each type
  DEFB $0F,$FF,$FF,$E0,$C0,$1F ; have, by type, shared by every cell of it:
  DEFB $0F,$FF,$FF,$E8,$C0,$1F ; types 2 on get 16-31 at every new game
  DEFB $0F,$FF,$FF,$FC,$E8,$3F ; (STOCK_BUILDINGS), types 0 and 1 none; one is
  DEFB $00,$FF,$3F,$FE,$F4,$7F ; taken as a find appears (SPAWN_FIND) and put
  DEFB $21,$FF,$1F,$FE,$F4,$7F ; back if it is left behind (FIND_WANDER)
DRAW_PASS:
  DEFB $31                ; Which of a building's two faces is being drawn
HITS:
  DEFB $FF                ; Hits the knight can still take in this life: 3 at
                          ; each life and at the cure (HITS_BONUS), one fewer
                          ; for each monster or creature that touches him
                          ; (WANDERING_MONSTER); his colour shows them
                          ; (KNIGHT_COLOURS)
THROW_TOGGLE:
  DEFB $8F                ; Which antibody record the next throw replaces
                          ; (KNIGHT_THROWS)
SPEED_TIME:
  DEFB $FF                ; Turns left of the faster walk a bonus gives
                          ; (SPEED_BONUS, UPDATE_KNIGHT)
LAST_CELL:
  DEFB $F2,$7F            ; The cell the knight was last in, column and row
                          ; (VISIT_CELL)
FOOTSTEPS:
  DEFB $20                ; Counts the knight's footsteps (FOOTSTEP)
EFFECT_TIME:
  DEFB $FF                ; Notes left of the sound effect under way, one a
                          ; turn (EFFECT_NOTE); in the ending, a count the
                          ; ending's note rises from (ENDING_BEEP)
EFFECT:
  DEFB $05                ; Which sound effect (EFFECT_TABLE): 0 a new cell
                          ; with a building, 1 the faster walk, 2 the cure, 3
                          ; an object taken up
FLASH:
  DEFB $FE                ; The paper colour of the play area, flashed when a
                          ; villain dies (VILLAIN_DYING), and back to black at
                          ; the end of every turn (NEW_GAME)
LAST_FLASH:
  DEFB $D0                ; The paper this turn's play area was cleared to:
                          ; FLASH as the last turn ended, which the knight's
                          ; and the buildings' colours keep (COLOUR_KNIGHT)
PERCENT:
  DEFB $7F                ; The percentage of the game done, BCD: the hundreds
                          ; (PERCENTAGE)
PERCENT_LOW:
  DEFB $1F                ; ...and the tens and units
ENDING:
  DEFB $FF                ; Set while the ending plays (GAME_OVER): the main
                          ; loop then only updates the records
ENDING_COLOUR:
  DEFB $C1                ; The colour the ending's pictures are drawn in
CONTROLS:
  DEFB $FE                ; What the controls say this turn: bits 0-1 turn, 2
                          ; walk, 3 throw, 4 down, 5 turn the town round
                          ; (READ_CONTROLS)
ARRIVING:
  DEFB $D4                ; Counts up by two a turn from 40 while the knight
                          ; appears at a new life, and is $70 once he has
                          ; (UPDATE_KNIGHT): until then nothing touches him and
                          ; no find or monster comes (TOUCHING_KNIGHT)
CARRIED:
  DEFB $FF,$7F,$FF,$F9,$FF ; The things carried, in the order taken up: 1-4 the
  DEFB $E6,$7F,$3F,$FF,$FD ; four objects, 5-8 the four kinds of antibody, 0 an
                           ; empty place (PICK_UP_THING); each has its place on
                           ; the panel, from the bottom up (COLOUR_CARRIED)
CARRIED_LAST:
  DEFB $FE                ; The eleventh; the knight throws the last thing he
                          ; took up first (KNIGHT_THROWS)
VISITED:
  DEFB $E0,$3F,$07,$FF    ; A bit for each cell of the town the knight has been
  DEFB $FD,$FE,$F4,$1F    ; in, a row of the town to a line: a byte for eight
  DEFB $08,$FF,$05,$FC    ; columns, the column's low three bits the bit
  DEFB $F0,$1F,$0E,$FF    ; (VISIT_CELL); counted for the percentage
  DEFB $4A,$F8,$F0,$1F    ; (PERCENTAGE)
  DEFB $0E,$FF,$DA,$FC    ;
  DEFB $F8,$1F,$0E,$FF    ;
  DEFB $02,$FC,$78,$0F    ;
  DEFB $07,$FF,$27,$FC    ;
  DEFB $78,$0F,$07,$FF    ;
  DEFB $FE,$FC,$38,$2F    ;
  DEFB $07,$FF,$76,$F8    ;
  DEFB $30,$7F,$27,$FF    ;
  DEFB $32,$F8,$70,$3F    ;
  DEFB $1E,$73,$20,$F0    ;
  DEFB $60,$1F,$06,$27    ;
  DEFB $03,$F8,$F0,$3F    ;
  DEFB $1B,$83,$00,$F8    ;
  DEFB $50,$1F,$06,$01    ;
  DEFB $00,$F8,$D0,$06    ;
  DEFB $00,$00,$00,$D0    ;
  DEFB $00,$03,$22,$01    ;
  DEFB $00,$FE,$00,$00    ;
  DEFB $00,$03,$01,$FF    ;
  DEFB $B6,$80,$00,$0F    ;
  DEFB $03,$FF,$B7,$E0    ;
  DEFB $80,$1F,$0E,$FF    ;
  DEFB $BF,$F0,$60,$3F    ;
  DEFB $1E,$FF,$BF,$F8    ;
  DEFB $70,$1F,$0E,$FF    ;
  DEFB $FF,$FC,$78,$1F    ;
  DEFB $0F,$FF,$FB,$FE    ;
KNIGHT:
  DEFB $FC                ; The knight's legs, +0: graphics 16-21 and 24-29 as
                          ; he walks, 12-15 as he vanishes, and 0 for a new
                          ; life (NEW_LIFE)
KNIGHT_U:
  DEFB $0F                ; +1: U within the cell
KNIGHT_COLUMN:
  DEFB $05                ; +2: the column
KNIGHT_V:
  DEFB $FF                ; +3: V within the cell
KNIGHT_ROW:
  DEFB $F5                ; +4: the row
KNIGHT_SPEED:
  DEFB $FF                ; +5: speed, up to TOP_SPEED
KNIGHT_FACING:
  DEFB $F6                ; +6: facing, bits 6-7
KNIGHT_FLAGS:
  DEFB $0F                ; +7: flags
  DEFB $07,$FF            ; +8 to +F: half-sizes in U and V; this turn's steps;
  DEFB $65,$E6            ; the drawing offset; where he was drawn
  DEFB $E0,$0F            ;
  DEFB $06,$FF            ;
KNIGHT_TOP:
  DEFB $AD,$E0,$C0,$07,$02,$FF,$DD,$C0 ; The knight's top half (graphics 22, 30
  DEFB $80,$07,$02,$FF,$ED,$C0,$80,$07 ; and 32-47), kept on his legs by
                                       ; UPDATE_TOP
ANTIBODIES:
  DEFB $02,$FF,$F5,$E0,$C0,$07,$02,$FF ; The first antibody in flight (graphics
  DEFB $FB,$E0,$C0,$07,$02,$FF,$FD,$E0 ; 80-95): the only one that can strike
                                       ; anything (ANTIBODY_STRIKE)
  DEFB $C0,$07,$02,$FF,$FE,$E0,$C0,$0F ; The second, used while the first is
  DEFB $06,$FF,$FF,$F0,$E0,$0F,$06,$FF ; busy (KNIGHT_THROWS)
FINDS:
  DEFB $FF,$F0,$E0,$0F,$06,$FF,$43,$F0 ; A find in a building (graphics 48-63,
  DEFB $E0,$0F,$07,$FF,$BB,$F0,$E0,$1F ; SPAWN_FIND); when a villain dies all
                                       ; four records hold its sparkles instead
                                       ; (140-143, drawn with the finds'
                                       ; sprites, VILLAIN_SPARKLES)
  DEFB $0F,$FF,$FF,$E0,$C0,$1F,$0F,$FF ; A second find, or sparkles
  DEFB $DF,$C0,$80,$1F,$0F,$FF,$8F,$80 ;
  DEFB $00,$0F,$07,$FF,$03,$C0,$80,$07 ; A third
  DEFB $01,$FF,$03,$C0,$80,$03,$01,$FF ;
  DEFB $0B,$C0,$80,$03,$01,$FF,$5B,$C0 ; A fourth
  DEFB $80,$03,$01,$FF,$63,$E0,$C0,$03 ;
BONUS:
  DEFB $01,$FF,$03,$E0,$C0,$01,$00,$FF ; A bonus (PLACE_BONUS): graphic 2 a
  DEFB $C7,$E0,$C0,$00,$00,$FF,$3F,$F0 ; faster walk, 3 the hits back
OBJECTS:
  DEFB $E0,$00,$00,$3F,$01,$F8,$F0,$00 ; The object that kills the villain in
  DEFB $00,$01,$00,$F8,$70,$00,$00,$00 ; record 0: graphic 7 lying, 11 thrown
                                       ; (PLACE_OBJECTS)
  DEFB $00,$70,$00,$03,$22,$63,$00,$F8 ; The object for villain 1: graphic 6
  DEFB $00,$00,$00,$FF,$63,$FF,$D0,$00 ; lying, 10 thrown
  DEFB $00,$7F,$3C,$FF,$ED,$C0,$00,$3F ; For villain 2: 5 and 9
  DEFB $1F,$FF,$6D,$F0,$C0,$1F,$07,$FF ;
  DEFB $B6,$F8,$D0,$07,$03,$FF,$D6,$FC ; For villain 3: 4 and 8
  DEFB $B8,$03,$01,$FF,$DA,$FE,$BC,$03 ;
VILLAINS:
  DEFB $01,$FF,$EB,$FC,$B8,$03,$01,$FF ; Villain 0 (graphics 108-111), panel
  DEFB $EF,$F8,$F0,$01,$00,$FF,$EF,$F8 ; colour cyan (PLACE_VILLAINS); every
                                       ; villain is 132-135 as it dies, drawn
                                       ; as a puff
  DEFB $F0,$01,$00,$FF,$FF,$F8,$F0,$01 ; Villain 1 (104-107), green
  DEFB $00,$FF,$FF,$F8,$F0,$00,$00,$FF ;
  DEFB $7F,$F0,$E0,$00,$00,$FF,$7F,$E0 ; Villain 2 (100-103), magenta
  DEFB $C0,$00,$00,$FF,$7F,$E0,$C0,$00 ;
  DEFB $00,$FF,$7F,$F0,$E0,$01,$00,$FF ; Villain 3 (96-99), red
  DEFB $DF,$F0,$E0,$01,$00,$FF,$DF,$F0 ;
MONSTERS:
  DEFB $E0,$01,$00,$FF,$DF,$F8,$F0,$03 ; A monster (SPAWN_MONSTER): appearing
  DEFB $01,$FF,$DF,$F8,$F0,$03,$01,$FF ; (128-131), then of graphics 64-79 or
                                       ; 112-127; or the creature (136-139,
                                       ; SPAWN_CREATURE), which always takes
                                       ; the first record it can
  DEFB $BF,$F8,$F0,$03,$01,$FF,$BF,$F8 ; A second monster
  DEFB $F0,$03,$01,$FF,$BF,$F0,$E0,$01 ;
  DEFB $00,$FF,$FF,$E0,$80,$00,$00,$FF ; A third
  DEFB $7F,$E0,$C0,$01,$00,$FF,$FF,$F0 ;
  DEFB $E0,$07,$01,$FF,$FF,$F0,$E0,$1F ; A fourth
  DEFB $07,$FF,$FF,$F8,$F0,$3F,$1F,$FF ;
  DEFB $FF,$F8,$F0,$1F,$0F,$FF,$FF,$F8 ; A fifth
  DEFB $F0,$0F,$03,$FF,$FF,$F0,$E0,$03 ;
  DEFB $00,$FF,$7F,$E0,$C0,$00,$00,$7F ; A sixth
  DEFB $07,$C0,$80,$00,$00,$07,$00,$80 ;

; The start: the first protection check, and every variable cleared
;
; Used by the routine at ENTRY.
;
; Entered from ENTRY. The first of the game's three protection checks: FRAMES'
; middle byte must still be $63, as the tape's last block left it, or the RET
; goes back to BASIC -- the loader's PRINT USR is what called it. A copy that
; loads the code some other way, without that block, or lets the interrupts run
; on for a few seconds before starting it, gets no further. Then the stack is
; put below the game, the variables and all 23 object records are cleared, and
; the set-up of a new game follows (NEW_GAME).
;
; This is the only place SP is set. GAME_OVER is jumped into from routines that
; were called, and leaves by jumping to NEW_GAME or MAIN_LOOP, so every game
; over leaves two bytes on the stack and every ending four. The stack creeps
; down through the BASIC program towards the system variables, and after 156
; game overs in one sitting it has overwritten NMIADD: the next game's first
; update jumps into the screen and the machine crashes. Measured: 156 games
; started and ended at once in the simulator left SP at the menu two bytes
; lower after each, until after the 156th NMIADD held part of a return address;
; the 157th game ran off into the screen and the printer buffer (the loader's
; code ran again) and hung.
START:
  LD A,(FRAMES_MIDDLE)    ; protection check 1: back to BASIC unless FRAMES'
  CP $63                  ; middle byte is $63
  RET NZ                  ;
  LD SP,ENTRY             ; the stack below the game, growing into the BASIC
                          ; program
  LD HL,RANDOM            ; clear all 596 bytes from RANDOM to the last
  LD BC,$0254             ; monster's record, and join the new game
  JR NEW_GAME_0           ;

; Set up a new game, then run the main loop
;
; Used by the routines at GAME_OVER and ENDING_PIT_FRONT.
;
; Entered from START the first time and from GAME_OVER after each game and
; after the ending (ENDING_PIT_FRONT). The variables from CELL_LOOKED_UP on are
; cleared, the turn counter taken from FRAMES, the screen cleared and the
; lookup tables built, and the menu run until a game is started (MENU); then
; the start tune, the panel (the frame, the heading over the score, the score,
; the compass and the heading of the view), six lives, a random cell to start
; in, the first life, the villains and the objects placed, the villains drawn
; on the panel, and the buildings stocked -- with the third protection check at
; the end of that (STOCK_BUILDINGS).
;
; The number of lives is not written in the code as a number. It is the opcode
; of the JR that closes the main loop, at LIVES_BYTE: $18, shifted right twice,
; is six. A search for a load of six finds nothing, and a poke to that byte
; breaks the loop; whether it was meant as a guard is not known, but it works
; as one.
;
; MAIN_LOOP is one turn. Every object record, knight first, is updated by the
; routine UPDATES gives for its graphic, through the dispatcher and NMIADD; the
; random number is stirred after each. Then the turn is counted, and unless the
; ending is under way: a find may appear, a monster, the creature, a bonus;
; this turn's note of the sound effect; the carried things coloured on the
; panel; the town and everything in it drawn into the buffer; the knight
; coloured by his hits; a new life if his record has emptied; the ending if the
; villains are gone. At END_OF_TURN the buffers go to the screen and are
; cleared, the flash is kept for the next turn and ended, and the pause key is
; read.
NEW_GAME:
  LD HL,CELL_LOOKED_UP    ; clear from CELL_LOOKED_UP to the last monster's
  LD BC,$024A             ; record
; This entry point is used by the routine at START.
NEW_GAME_0:
  CALL CLEAR_MEMORY       ; clear
  LD HL,(FRAMES)          ; the turn counter starts from FRAMES, which never
  LD (TURNS),HL           ; changes once the game runs
  CALL CLEAR_SCREEN       ; clear the screen, border black
  CALL MAKE_TABLES        ; build the tables for drawing mirrored and shifted
  CALL MENU               ; the menu, until 0 starts a game
  LD DE,TUNE_GAME_START   ; the tune as a game starts
  CALL PLAY_TUNE          ;
  CALL CLEAR_SCREEN       ; clear the screen again
  CALL DRAW_PLAY_FRAME    ; the border and the panel's frame
  CALL DRAW_PANEL_FRAME   ;
  LD HL,$0F38             ; the heading over the score (SCORE_TEXT)
  LD DE,SCORE_TEXT        ;
  CALL PRINT_TEXT         ;
  CALL PRINT_SCORE        ; the score
  CALL PRINT_COMPASS      ; the compass
  CALL PRINT_HEADING      ; north, or south
  CALL CLEAR_BUFFER       ; clear the play area's buffers
  LD A,$0A                ; top speed 10
  LD (TOP_SPEED),A        ;
  LD A,(LIVES_BYTE)       ; six lives: the JR's opcode at LIVES_BYTE, $18,
  SRL A                   ; shifted right twice
  SRL A                   ;
  LD (LIVES),A            ;
  CALL RANDOM_START_CELL  ; a random cell to start in, anything but solid
  LD A,$40                ; facing along U, forward
  LD (START_FACING),A     ;
  CALL FIRST_LIFE         ; the first life: the knight's records, and a life
                          ; taken
  CALL PLACE_VILLAINS     ; the villains
  CALL PLACE_OBJECTS      ; the objects
  CALL DRAW_VILLAINS      ; the villains on the panel
  CALL STOCK_BUILDINGS    ; stock the buildings, and protection check 3
; This entry point is used by the routine at GAME_OVER.
MAIN_LOOP:
  LD IX,KNIGHT            ; MAIN_LOOP: from the knight's legs
NEXT_OBJECT:
  LD A,(IX+$00)           ; update the record, by its graphic, through NMIADD
  LD BC,UPDATES           ;
  CALL DISPATCH           ;
  CALL STIR_RANDOM        ; stir the random number after every record
  LD BC,$0010             ; on to the next, until past the last monster's
  ADD IX,BC               ;
  PUSH IX                 ;
  POP HL                  ;
  LD BC,START             ;
  AND A                   ;
  SBC HL,BC               ;
  JR C,NEXT_OBJECT        ;
  CALL NEXT_TURN          ; count the turn
  LD A,(ENDING)           ; while the ending plays, nothing else
  AND A                   ;
  JP NZ,END_OF_TURN       ;
  CALL SPAWN_FIND         ; a find, every sixteenth turn
  CALL SPAWN_MONSTER      ; a monster, every fourth
  CALL SPAWN_CREATURE     ; the creature, every 256th
  CALL PLACE_BONUS        ; a bonus, when there is none
  CALL EFFECT_NOTE        ; this turn's note of the sound effect
  CALL COLOUR_CARRIED     ; colour the carried things on the panel
  CALL DRAW_CELLS         ; draw the town round the knight, and what is in it
  LD A,(HITS)             ; colour the knight by his hits (KNIGHT_COLOURS):
  LD HL,KNIGHT_COLOURS    ; four rows of two cells in the middle of the play
  CALL ADD_HL_A           ; area
  LD A,(HL)               ;
  EX AF,AF'               ;
  LD HL,$7070             ;
  CALL ATTR_ADDRESS       ;
  LD B,$04                ;
  EX AF,AF'               ;
  CALL COLOUR_KNIGHT      ;
  CALL NEW_LIFE           ; a new life, if his record is empty
  CALL CHECK_QUEST_DONE   ; the ending, if the villains are gone
END_OF_TURN:
  CALL SHOW_PLAY_AREA     ; END_OF_TURN: the buffers to the screen, and cleared
                          ; with this turn's flash
  LD A,(FLASH)            ; keep the flash for the colours of the next turn,
  LD (LAST_FLASH),A       ; and end it
  XOR A                   ;
  LD (FLASH),A            ;
  CALL PAUSE              ; the pause
LIVES_BYTE:
  JR MAIN_LOOP            ; LIVES_BYTE: round again; this JR's opcode is also
                          ; the number of lives

; Work out the percentage of the game done
;
; Used by the routine at GAME_OVER.
;
; Called by GAME_OVER after every game. A unit for every cell the knight has
; been in (every set bit of VISITED) and three for every villain record not
; holding a live villain (graphics 96-111): a destroyed villain's record is
; empty or dying. Each unit adds 10288 to a 16-bit fraction of which 65536 is
; one per cent, the carries counted in BCD; at the end 144 more, exactly what
; 637 units need to make 100. The town has 625 cells a knight can stand in, and
; three for each of four villains makes 637.
;
; The carries are counted with DAA, which wraps from 99 to 0 and leaves its own
; carry to be lost: past 637 units the count starts again. A knight cannot be
; in more than 625 cells, so it never does in play; setting every bit of
; VISITED (1024) gave 62% (measured, stage 1).
PERCENTAGE:
  LD HL,$0000             ; HL = how many cells he has been in: the set bits of
  LD DE,VISITED           ; VISITED
  LD C,$80                ;
PERCENTAGE_0:
  LD A,(DE)               ;
  INC DE                  ;
  LD B,$08                ;
PERCENTAGE_1:
  RRCA                    ;
  JR NC,PERCENTAGE_2      ;
  INC HL                  ;
PERCENTAGE_2:
  DJNZ PERCENTAGE_1       ;
  DEC C                   ;
  JR NZ,PERCENTAGE_0      ;
  LD IY,VILLAINS          ; three more for each villain record without a live
  LD B,$04                ; villain
PERCENTAGE_3:
  LD A,(IY+$00)           ;
  SUB $60                 ;
  CP $10                  ;
  JR C,PERCENTAGE_4       ;
  LD DE,$0003             ;
  ADD HL,DE               ;
PERCENTAGE_4:
  LD DE,$0010             ;
  ADD IY,DE               ;
  DJNZ PERCENTAGE_3       ;
  LD BC,$2830             ; add 10288 for each unit, the carries counted in BCD
  XOR A                   ; in A
  EX DE,HL                ;
  LD HL,$0000             ;
PERCENTAGE_5:
  ADD HL,BC               ;
  ADC A,$00               ;
  DAA                     ;
  PUSH AF                 ;
  DEC DE                  ;
  LD A,E                  ;
  OR D                    ;
  JR Z,PERCENTAGE_6       ;
  POP AF                  ;
  JR PERCENTAGE_5         ;
PERCENTAGE_6:
  POP AF                  ; 144 more, rounding 637 units up to exactly a
  LD BC,$0090             ; hundred
  ADD HL,BC               ;
  ADC A,$00               ;
  DAA                     ;
  LD (PERCENT_LOW),A      ; the tens and units, and the hundreds from the last
  LD A,$00                ; carry
  ADC A,$00               ;
  LD (PERCENT),A          ;
  RET                     ;

; Print the percentage
;
; Used by the routine at GAME_OVER.
;
; Called by GAME_OVER with HL the screen address and the attribute in A'. Under
; a hundred it prints the two digits a column in, through the whole of
; PRINT_BCD. At a hundred it prints three, but by jumping into that routine
; past the instructions that point FONT_BASE at the digits (FONT); GAME_OVER
; has just printed text, which leaves FONT_BASE at the text font's base, 384
; bytes lower, where codes 0 and 1 are bytes of a building's graphics. So a
; game finished at 100% shows three meaningless characters where the figure
; should be. Measured: the build's quest session run to the moment after this
; call, with PERCENT holding 1 and 0 and FONT_BASE the text font's, left three
; characters on the screen that match no digit; the same call with FONT_BASE at
; the digits printed 100.
;
; HL the screen address
; A' the attribute
PRINT_PERCENTAGE:
  LD DE,PERCENT           ; one byte of digits; is the hundreds byte zero?
  LD B,$01                ;
  LD A,(DE)               ;
  AND A                   ;
  JR Z,PRINT_PERCENTAGE_0 ;
  INC B                   ; a hundred: three digits from the hundreds' low one
  JP PRINT_BCD_LOW        ; -- in whatever font was last used
PRINT_PERCENTAGE_0:
  INC L                   ; under a hundred: a column in, and the tens and
  INC DE                  ; units
  JP PRINT_BCD            ;

; Mark the knight's cell visited, and sound a new one with a building
;
; Used by the routine at WALK_ON.
;
; Called by WALK_ON as the knight walks. Nothing happens while he stays in
; LAST_CELL; in a new cell, it becomes LAST_CELL and its bit in VISITED is set.
; A cell with anything built on it (a type other than 0) that had not been
; visited before also starts sound effect 0, four notes. NEW_LIFE enters at
; ENTER_CELL to mark the cell a life starts in.
;
; MARK_VISITED writes the bit number into the BIT and SET instructions that
; test and set it -- the second byte of each is $46 or $C6 plus eight times the
; bit -- and returns with Z set if the cell is new: SET leaves the flags as BIT
; made them.
;
; IX the knight's legs record
VISIT_CELL:
  LD HL,(LAST_CELL)       ; still in the cell he was in: nothing to do
  LD A,(IX+$02)           ;
  CP L                    ;
  JR NZ,ENTER_CELL        ;
  LD A,(IX+$04)           ;
  CP H                    ;
  RET Z                   ;
; This entry point is used by the routine at NEW_LIFE.
ENTER_CELL:
  LD L,(IX+$02)           ; ENTER_CELL: the new cell, column and row, becomes
  LD H,(IX+$04)           ; LAST_CELL
  LD (LAST_CELL),HL       ;
  PUSH HL                 ; open ground (type 0): just mark it
  CALL TOWN_CELL          ;
  POP HL                  ;
  JR NZ,VISIT_CELL_0      ;
MARK_VISITED:
  LD A,L                  ; MARK_VISITED: HL = VISITED + 4 * row + column / 8
  LD L,H                  ;
  RLA                     ;
  RLA                     ;
  RLA                     ;
  LD H,A                  ;
  RLA                     ;
  RL L                    ;
  RLA                     ;
  RL L                    ;
  LD A,H                  ;
  LD H,$00                ;
  LD BC,VISITED           ;
  ADD HL,BC               ;
  AND $38                 ; write bit (column AND 7) into the next two
  OR $46                  ; instructions
  LD ($BF86),A            ;
  OR $80                  ;
  LD ($BF88),A            ;
  BIT 0,(HL)              ; BIT n,(HL): Z if the cell is new
  SET 0,(HL)              ; SET n,(HL), the flags as BIT left them
  RET                     ; Z for a new cell
VISIT_CELL_0:
  CALL MARK_VISITED       ; built on: mark it; visited before, and that is all
  RET NZ                  ;
  LD HL,$0004             ; a new one: sound effect 0, four notes
  LD (EFFECT_TIME),HL     ;
  RET                     ;

; Every 256 turns, bring the creature into the knight's cell
;
; Used by the routine at NEW_GAME.
;
; When the low byte of TURNS comes round to zero, the first monster record that
; is not in the knight's cell or next to it becomes the creature (graphic 136)
; -- empty or not: a monster further off is simply replaced. It is put in the
; knight's cell, at a random place 64-191 across it each way, with a half-size
; of 16 each way; if that place already touches him (TOUCHING_KNIGHT) it is a
; puff (graphic 12) instead, and harmless. If all six records are within a cell
; of him, the first becomes the creature wherever it is, with only its graphic
; changed.
;
; Measured: in a game left to run, a monster record held the creature every
; time the turn counter's low byte was zero; and with all six records empty and
; so at cell (0,0), next to a knight in cell (1,1), the first record got
; graphic 136 and nothing else.
SPAWN_CREATURE:
  LD A,(TURNS)            ; not the 256th turn: nothing
  AND A                   ;
  RET NZ                  ;
  LD IX,MONSTERS          ; the first monster record not within a cell of the
  LD DE,$0010             ; knight
  LD B,$06                ;
SPAWN_CREATURE_0:
  LD C,$02                ;
  CALL NEAR_KNIGHT        ;
  JR NC,SPAWN_CREATURE_1  ;
  ADD IX,DE               ;
  DJNZ SPAWN_CREATURE_0   ;
  LD A,$88                ; all six are: the first becomes the creature where
  LD (MONSTERS),A         ; it is
  RET                     ;
SPAWN_CREATURE_1:
  LD A,(RANDOM)           ; in the knight's cell, at a random place in it
  AND $7F                 ;
  ADD A,$40               ;
  LD (IX+$01),A           ;
  LD A,(KNIGHT_COLUMN)    ;
  LD (IX+$02),A           ;
  LD A,($BBAB)            ;
  AND $7F                 ;
  ADD A,$40               ;
  LD (IX+$03),A           ;
  LD A,(KNIGHT_ROW)       ;
  LD (IX+$04),A           ;
  LD (IX+$08),$10         ; half-size 16 each way; the drawing offset
  LD (IX+$09),$10         ;
  LD (IX+$0C),$F4         ;
  LD (IX+$0D),$04         ;
  CALL TOUCHING_KNIGHT    ; touching him already? a puff (12); otherwise the
  LD A,$0C                ; creature (136)
  JR C,SPAWN_CREATURE_2   ;
  ADD A,$7C               ;
SPAWN_CREATURE_2:
  LD (IX+$00),A           ;
  RET                     ;

; The update routine for the creature (graphics 136-139)
;
; It makes for the knight, two units a turn along U and along V
; (STEER_AT_KNIGHT), blipping while on the screen (BLIP_BY_TURN). A wall stops
; it dead: it bursts, for 1000 points -- the reward for leading it into one.
; More than two cells from the knight in column or row, it is left behind: the
; record is emptied. An antibody strikes it for 1000, both bursting (but only
; the first antibody record can, ANTIBODY_STRIKE); touching the knight, it
; bursts and takes one of his hits (WANDERING_MONSTER).
;
; IX the creature's record
CREATURE_UPDATE:
  CALL BLIP_BY_TURN       ; the blip, if it was drawn last turn
  CALL STEER_AT_KNIGHT    ; steps of two towards the knight
  CALL MOVE_SPLIT         ; is the way clear, along U and then V? (MOVE_SPLIT)
  BIT 0,(IX+$07)          ; a wall: it bursts, for 1000
  JR NZ,CREATURE_UPDATE_2 ;
  CALL APPLY_STEP         ; move by the steps
  CALL NEXT_FRAME_MOD4    ; the next frame of the four
  LD C,$03                ; three cells or more from him: left behind
  CALL NEAR_KNIGHT        ;
  JR NC,CREATURE_UPDATE_0 ;
  CALL ANTIBODY_STRIKE    ; struck by an antibody?
  JR C,CREATURE_UPDATE_1  ;
  CALL TOUCHING_KNIGHT    ; touching him: it bursts, and he loses a hit
  RET NC                  ;
  JP MONSTER_HITS_KNIGHT  ;
CREATURE_UPDATE_0:
  LD (IX+$00),$00         ; left behind: the record emptied (never ran in the
  RET                     ; sessions)
CREATURE_UPDATE_1:
  LD (IY+$00),$0C         ; the antibody bursts...
CREATURE_UPDATE_2:
  LD (IX+$00),$0C         ; ...and so does the creature
  LD BC,$0010             ; 1000
  JP ADD_SCORE            ;

; Step the thing at IX two units towards the knight along each axis
;
; Used by the routine at CREATURE_UPDATE.
;
; The creature's homing (CREATURE_UPDATE): its steps, +A and +B, become 2 or -2
; by the side of the knight it is on, comparing the whole 16-bit positions;
; level with him on an axis it still steps forward along it.
;
; IX the record
STEER_AT_KNIGHT:
  LD E,(IX+$01)           ; +A: 2 if he is further along U, or level; otherwise
  LD D,(IX+$02)           ; -2
  LD HL,(KNIGHT_U)        ;
  AND A                   ;
  SBC HL,DE               ;
  LD A,$02                ;
  JR NC,STEER_AT_KNIGHT_0 ;
  NEG                     ;
STEER_AT_KNIGHT_0:
  LD (IX+$0A),A           ;
  LD E,(IX+$03)           ; +B the same along V
  LD D,(IX+$04)           ;
  LD HL,(KNIGHT_V)        ;
  AND A                   ;
  SBC HL,DE               ;
  LD A,$02                ;
  JR NC,STEER_AT_KNIGHT_1 ;
  NEG                     ;
STEER_AT_KNIGHT_1:
  LD (IX+$0B),A           ;
  RET                     ;

; Empty the six monster records
;
; Used by the routine at NEW_LIFE.
;
; NEW_LIFE does this at every new life, so no monster, and no creature, is
; waiting where he appears.
CLEAR_MONSTERS:
  LD HL,MONSTERS          ; graphic 0 in all six
  LD DE,$0010             ;
  LD B,$06                ;
CLEAR_MONSTERS_0:
  LD (HL),$00             ;
  ADD HL,DE               ;
  DJNZ CLEAR_MONSTERS_0   ;
  RET                     ;

; The knight's colour by his hits
;
; Attributes indexed by HITS, which the main loop gives the four rows of two
; cells where the knight always stands, in the middle of the play area
; (NEW_GAME, through COLOUR_KNIGHT). All bright on black: green at one hit,
; yellow at two, white at three; the byte for none is seen only in the turn he
; dies. sna2ctl took the four bytes for text.
KNIGHT_COLOURS:
  DEFB $44                ; No hits left, one, two, three: green, green,
  DEFB $44                ; yellow, white
  DEFB $46                ;
  DEFB $47                ;

; Is the thing at IX less than C cells from the knight?
;
; Used by the routines at SPAWN_CREATURE, CREATURE_UPDATE, MONSTER112_UPDATE,
; HIT_SPLITS, COLOUR_CARRIED, WANDERING_MONSTER, SPEED_BONUS, HITS_BONUS and
; PLACE_BONUS.
;
; Compares cells only, the columns and the rows: carry if both differences are
; less than C. Used with C = 2 (his own cell or a neighbour), 3, 4 and 5, to
; decide what is near enough to matter -- and what is far enough to be
; forgotten.
;
;   IX the record
;   C the limit, in cells
; O:F carry if near
NEAR_KNIGHT:
  LD A,(KNIGHT_COLUMN)    ; the columns: not near, no carry
  SUB (IX+$02)            ;
  JP P,NEAR_KNIGHT_0      ;
  NEG                     ;
NEAR_KNIGHT_0:
  CP C                    ;
  RET NC                  ;
  LD A,(KNIGHT_ROW)       ; the rows: carry if near
  SUB (IX+$04)            ;
  JP P,NEAR_KNIGHT_1      ;
  NEG                     ;
NEAR_KNIGHT_1:
  CP C                    ;
  RET                     ;

; The update routine for a monster of graphics 112-127
;
; It walks at its speed the way it faces, warbling if it walks into a wall
; while on the screen (BUMP_SOUND), turning when it is stopped and every so
; often -- a monster with bit 5 of its flags set turns towards the knight
; (STEER) -- and takes its frame from its facing (FACING_PICTURE). Three cells
; or more from the knight it is forgotten: its record is emptied. Touching him
; it scores 2500 and takes one of his hits, bursting (WANDERING_MONSTER).
;
; Struck by an antibody (ANTIBODY_STRIKE), its fate depends on the two kinds
; together: a monster's kind is bits 2-3 of its graphic (112, 116, 120 or 124
; on), an antibody's the same bits of its (80, 84, 88 or 92 on), and their sum,
; four apart, picks a routine from MONSTER_HIT_TABLE: destroyed, changed into
; the next kind, split in two, or turned into a monster of 64-79. A monster's
; kind is that of the villain nearest where it appeared (APPEARING_UPDATE), so
; each villain's monsters are destroyed by one kind of antibody.
;
; IX the monster's record
MONSTER112_UPDATE:
  LD A,(IX+$05)           ; its steps, from its speed and facing; is the way
  CALL SET_STEP           ; clear?
  CALL MOVE_CLIPPED       ;
  BIT 0,(IX+$07)          ; a wall: the warble, if it is on the screen
  CALL NZ,BUMP_SOUND      ;
  RES 1,(IX+$07)          ; not yet drawn this turn
  CALL APPLY_STEP         ; move; perhaps turn; its frame
  CALL STEER              ;
  CALL FACING_PICTURE     ;
  LD C,$03                ; three cells or more from the knight: forgotten
  CALL NEAR_KNIGHT        ;
  JR NC,MONSTER_TOO_FAR   ;
  CALL ANTIBODY_STRIKE    ; struck by an antibody?
  JR C,STRIKE_OUTCOME     ;
  CALL TOUCHING_KNIGHT    ; touching the knight: 2500, it bursts, and he loses
  RET NC                  ; a hit
  LD BC,$0025             ;
  CALL ADD_SCORE          ;
  JP MONSTER_HITS_KNIGHT  ;
STRIKE_OUTCOME:
  LD A,(IX+$00)           ; STRIKE_OUTCOME: the two kinds added, four apart,
  SRL A                   ; pick what happens
  SRL A                   ;
  LD C,A                  ;
  LD A,(IY+$00)           ;
  SRL A                   ;
  SRL A                   ;
  ADD A,C                 ;
  AND $03                 ;
  LD BC,MONSTER_HIT_TABLE ;
  JP DISPATCH             ;

; What an antibody does to a monster of graphics 112-127
;
; By the monster's kind plus the antibody's, four apart (MONSTER112_UPDATE).
; Reached through the dispatcher, so through NMIADD.
MONSTER_HIT_TABLE:
  DEFW HIT_DESTROYS       ; 0: destroyed, 2500 (HIT_DESTROYS)
  DEFW HIT_CHANGES        ; 1: changed into the next kind, 2000 (HIT_CHANGES)
  DEFW HIT_SPLITS         ; 2: split in two, 1500 (HIT_SPLITS)
  DEFW HIT_DEMOTES        ; 3: turned into a monster of 64 or 68, 1000
                          ; (HIT_DEMOTES)

; Forget a monster that is too far from the knight
;
; Used by the routine at MONSTER112_UPDATE.
;
; The end of MONSTER112_UPDATE when the monster is three cells or more away:
; its record is emptied, silently.
MONSTER_TOO_FAR:
  LD (IX+$00),$00         ; graphic 0
  RET                     ;

; An antibody's strike that destroys the monster: 2500 points
;
; IX the monster
; IY the antibody
HIT_DESTROYS:
  LD (IX+$00),$0C         ; the monster bursts (graphic 12)
  LD BC,$0025             ; 2500
  CALL ADD_SCORE          ;
; This entry point is used by the routines at HIT_CHANGES and HIT_DEMOTES.
ANTIBODY_SPENT:
  LD (IY+$00),$0C         ; ANTIBODY_SPENT: the antibody bursts too
  RET

; An antibody's strike that changes the monster into the next kind: 2000 points
;
; Four graphics on, round from 124-127 to 112-115, its frame kept: a monster
; that needs another kind of antibody.
HIT_CHANGES:
  LD A,(IX+$00)           ; the next kind round
  ADD A,$04               ;
  AND $0F                 ;
  OR $70                  ;
  LD (IX+$00),A           ;
  LD BC,$0020             ; 2000
  CALL ADD_SCORE          ;
  JR ANTIBODY_SPENT       ; the antibody bursts

; An antibody's strike that splits the monster in two: 1500 points
;
; Meant, by the look of it, to copy the monster into an empty monster record
; and send the two off at right angles. What it does: the search loop tests IY
; for an empty record, but IY is the antibody's record (just made to burst) and
; then the records after it -- the second antibody, the finds, the bonus --
; while IX, which the nearness test reads, stays on the first monster record.
; So the monster is copied into the first monster record, whatever is there --
; another monster, the creature -- either when that record is not within a cell
; of the knight or, if it is, when the second antibody record or a find record
; is empty; only when none is does no split happen. A monster in the first
; record copies itself onto itself and its facing is turned one way and back:
; no split.
;
; Measured, calling it with a monster in the fourth record: with a monster far
; off in the first, that monster was replaced by the copy; with one beside the
; knight in the first and the second antibody record empty, the same; with it
; beside him and the five records after the antibody's all busy, no copy, and
; 1500 all the same (the only run of that branch: no session reached it).
;
; IX the monster
; IY the antibody
HIT_SPLITS:
  LD (IY+$00),$0C         ; the antibody bursts
  PUSH IX                 ; IX = the first monster record (the struck one
  LD IX,MONSTERS          ; saved); six tries
  LD DE,$0010             ;
  LD B,$06                ;
HIT_SPLITS_0:
  LD A,(IY+$00)           ; IY empty? split -- but IY is the antibody's record
  AND A                   ; and those after it
  JR Z,HIT_SPLITS_1       ;
  LD C,$02                ; IX, the first monster record, not beside the
  CALL NEAR_KNIGHT        ; knight? split
  JR NC,HIT_SPLITS_1      ;
  ADD IY,DE               ; the record after IY
  DJNZ HIT_SPLITS_0       ;
  POP IX                  ; no split: 1500 (never ran in the sessions)
  LD BC,$0015             ;
  JP ADD_SCORE            ;
HIT_SPLITS_1:
  PUSH IX                 ; the struck monster copied over the first monster
  POP DE                  ; record: IY the copy, IX the original
  PUSH DE                 ;
  POP IY                  ;
  POP HL                  ;
  PUSH HL                 ;
  POP IX                  ;
  LD BC,$0010             ;
  LDIR                    ;
  LD A,(IX+$06)           ; a quarter turn each way, with 31 turns before
  ADD A,$40               ; either turns again
  OR $1F                  ;
  LD (IX+$06),A           ;
  LD A,(IY+$06)           ;
  SUB $40                 ;
  OR $1F                  ;
  LD (IY+$06),A           ;
  LD BC,$0015             ; 1500
  JP ADD_SCORE            ;

; An antibody's strike that turns the monster into one of graphics 64-79: 1000
; points
;
; Graphic 64 or 68, by bit 2 of its own: kinds 0 and 2 become the first, 1 and
; 3 the second, whatever villain they came from. Those are the monsters of
; WANDERING_MONSTER, which any antibody destroys.
HIT_DEMOTES:
  LD A,(IX+$00)           ; graphic 64 or 68
  AND $04                 ;
  OR $40                  ;
  LD (IX+$00),A           ;
  LD BC,$0010             ; 1000
  CALL ADD_SCORE          ;
  JR ANTIBODY_SPENT       ; the antibody bursts

; The update routine for a monster appearing (graphics 128-131)
;
; Four turns of appearing, with a note that rises each turn it is on the screen
; (APPEAR_SOUND). Then it becomes a monster of the kind of the villain nearest
; it (NEAREST_VILLAIN): of graphics 112-127 or, as often, of 64-79 -- the
; random number decides. Graphic 76, the monster of the first villain's kind,
; is given a half-size of 24 in V.
;
; IX the record
APPEARING_UPDATE:
  BIT 1,(IX+$07)          ; the note, if it was drawn last turn
  RES 1,(IX+$07)          ;
  CALL NZ,APPEAR_SOUND    ;
  INC (IX+$00)            ; the next frame; after the fourth, a monster
  LD A,(IX+$00)           ;
  AND $03                 ;
  RET NZ                  ;
  LD A,(RANDOM)           ; which sort, by the random number
  CP $80                  ;
  JR C,APPEARING_UPDATE_0 ;
  CALL NEAREST_VILLAIN    ; one of 64-79, of the nearest villain's kind
  ADD A,A                 ;
  ADD A,A                 ;
  OR $40                  ;
  LD (IX+$00),A           ;
  CP $4C                  ; graphic 76 is 24 deep in V
  RET NZ                  ;
  LD (IX+$09),$18         ;
  RET                     ;
APPEARING_UPDATE_0:
  CALL NEAREST_VILLAIN    ; one of 112-127, of the nearest villain's kind
  ADD A,A                 ;
  ADD A,A                 ;
  OR $70                  ;
  LD (IX+$00),A           ;
  RET                     ;

; Which villain is nearest the thing at IX?
;
; Used by the routine at APPEARING_UPDATE.
;
; Nearest by the columns and the rows apart added together (VILLAIN_DISTANCE);
; the first found wins a tie. Returns 3 for the villain in the first record
; down to 0 for the last: the kind of the monsters that villain brings
; (APPEARING_UPDATE). With no villain left, 3.
;
;   IX the record
; O:A 3 - the nearest villain's record number
NEAREST_VILLAIN:
  LD IY,VILLAINS          ; IY = the first villain; the nearest so far none, at
  LD B,$04                ; 255
  LD DE,$04FF             ;
NEAREST_VILLAIN_0:
  CALL VILLAIN_DISTANCE   ; nearer? keep its distance, and B
  CP E                    ;
  JR NC,NEAREST_VILLAIN_1 ;
  LD E,A                  ;
  LD D,B                  ;
NEAREST_VILLAIN_1:
  PUSH DE                 ; the next villain
  LD DE,$0010             ;
  ADD IY,DE               ;
  POP DE                  ;
  DJNZ NEAREST_VILLAIN_0  ;
  LD A,D                  ; 3 for the first record, 0 for the last
  DEC A                   ;
  RET                     ;

; How far is the villain at IY from the thing at IX?
;
; Used by the routine at NEAREST_VILLAIN.
;
;   IX the thing
;   IY the villain's record
; O:A the columns apart plus the rows apart; 255 for an empty record
VILLAIN_DISTANCE:
  LD A,(IY+$00)            ; an empty record is 255 away
  AND A                    ;
  JR NZ,VILLAIN_DISTANCE_0 ;
  LD A,$FF                 ;
  RET                      ;
VILLAIN_DISTANCE_0:
  LD A,(IX+$02)           ; the columns apart
  SUB (IY+$02)            ;
  JP P,VILLAIN_DISTANCE_1 ;
  NEG                     ;
VILLAIN_DISTANCE_1:
  LD C,A                  ;
  LD A,(IX+$04)           ; plus the rows apart
  SUB (IY+$04)            ;
  JP P,VILLAIN_DISTANCE_2 ;
  NEG                     ;
VILLAIN_DISTANCE_2:
  ADD A,C                 ;
  RET                     ;

; Stock the buildings with finds, then the third protection check
;
; Used by the routine at NEW_GAME.
;
; At every new game each cell type from 2 to 35 is given 16-31 finds, the low
; four bits of bytes read from a random place in the first 4K of the ROM, plus
; 16 (STOCKS). Types 0, open ground, and 1 get none.
;
; Then the third protection check: bit 7 of R must be set. The refresh counter
; the Z80 keeps in R counts only its low seven bits, so bit 7 changes only when
; a program loads R, and the loader did (LOADER). A copy started by any other
; means has it clear, and falls into RESET, which jumps to address 0: the
; Spectrum starts again as if just switched on. NEW_LIFE jumps to RESET as well
; when its own check fails.
STOCK_BUILDINGS:
  CALL NEXT_TURN          ; count a turn, and stir the random number
  LD HL,(RANDOM)          ; HL = somewhere in the first 4K of the ROM
  LD A,H                  ;
  AND $0F                 ;
  LD H,A                  ;
  LD DE,$BBD0             ; 16-31 for each type from 2 to 35
  LD B,$22                ;
STOCK_BUILDINGS_0:
  LD A,(HL)               ;
  INC HL                  ;
  AND $0F                 ;
  OR $10                  ;
  LD (DE),A               ;
  INC DE                  ;
  DJNZ STOCK_BUILDINGS_0  ;
  LD A,R                  ; protection check 3: R's bit 7, the loader's mark,
  BIT 7,A                 ; still set: carry on
  RET NZ                  ;
; This entry point is used by the routine at NEW_LIFE.
RESET:
  XOR A                   ; RESET: start the Spectrum again (never ran in the
  LD L,A                  ; sessions)
  LD H,A                  ;
  JP (HL)                 ;

; Draw the four villains on the panel
;
; Used by the routines at NEW_GAME and OBJECT_FLIGHT.
;
; At a new game and whenever a villain is destroyed (OBJECT_FLIGHT). Each is
; drawn from the sprite of its first standing graphic -- 108, 104, 100 and 96
; for records 0 to 3 -- upwards from the bottom of the screen, three columns
; apart from column 15. A villain still about is drawn as the first byte of
; each of its sprite's pairs less the second, which comes out as its outline,
; in the panel's white; a destroyed one as the second bytes, its picture,
; coloured from THING_COLOURS -- the colour of the object that kills it. A
; sprite stored mirrored is turned back first (MIRROR_SPRITE).
;
; Measured: after a game starts, the four outlines in bright white; with record
; 0 emptied and this called again, that villain's picture, in bright cyan,
; three columns wide and six rows high.
DRAW_VILLAINS:
  LD IY,VILLAINS          ; IY = the first villain; DE = the bottom line of the
  LD DE,$57EF             ; screen, column 15
  LD B,$04                ;
DRAW_VILLAINS_0:
  PUSH BC                 ; HL = the sprite for graphic 108, 104, 100 or 96,
  PUSH DE                 ; the first record first
  LD A,B                  ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,$5C               ;
  LD BC,GRAPHICS          ;
  CALL TABLE_WORD         ;
  EX DE,HL                ; stored mirrored? turn it back
  LD A,(DE)               ;
  AND $40                 ;
  PUSH BC                 ;
  PUSH HL                 ;
  CALL NZ,MIRROR_SPRITE   ;
  POP HL                  ;
  POP BC                  ;
  EX DE,HL                ;
  LD A,(HL)               ; B = its width in bytes, C its height in lines; HL
  INC HL                  ; its rows
  AND $3F                 ;
  LD B,A                  ;
  LD C,(HL)               ;
  INC HL                  ;
  LD A,(IY+$00)           ; destroyed (not graphics 96-111)?
  SUB $60                 ;
  CP $10                  ;
  JR NC,DRAW_VILLAINS_4   ;
DRAW_VILLAINS_1:
  PUSH BC                 ; still about: the first byte of each pair less the
  PUSH DE                 ; second, line by line upwards
DRAW_VILLAINS_2:
  LD A,(HL)               ;
  INC HL                  ;
  CPL                     ;
  OR (HL)                 ;
  INC HL                  ;
  CPL                     ;
  LD (DE),A               ;
  INC E                   ;
  DJNZ DRAW_VILLAINS_2    ;
  POP DE                  ;
  POP BC                  ;
  CALL SCREEN_LINE_UP     ;
  DEC C                   ;
  JR NZ,DRAW_VILLAINS_1   ;
DRAW_VILLAINS_3:
  POP DE                  ; three columns on, and the next villain
  POP BC                  ;
  INC E                   ;
  INC E                   ;
  INC E                   ;
  PUSH DE                 ;
  LD DE,$0010             ;
  ADD IY,DE               ;
  POP DE                  ;
  DJNZ DRAW_VILLAINS_0    ;
  RET                     ;
DRAW_VILLAINS_4:
  PUSH BC                 ; destroyed: the second bytes, its picture
  PUSH DE                 ;
DRAW_VILLAINS_5:
  INC HL                  ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (DE),A               ;
  INC E                   ;
  DJNZ DRAW_VILLAINS_5    ;
  POP DE                  ;
  POP BC                  ;
  CALL SCREEN_LINE_UP     ;
  DEC C                   ;
  JR NZ,DRAW_VILLAINS_4   ;
  POP DE                  ; C = its colour (THING_COLOURS), by B
  POP BC                  ;
  PUSH BC                 ;
  PUSH DE                 ;
  LD A,B                  ;
  LD HL,THING_COLOURS     ;
  CALL ADD_HL_A           ;
  LD C,(HL)               ;
  EX DE,HL                ; HL = the attribute of the cell at the bottom
  LD A,H                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $03                 ;
  LD H,A                  ;
  LD DE,$5800             ;
  ADD HL,DE               ;
  LD DE,$FFDE             ; three wide and six high, upwards
  LD B,$06                ;
DRAW_VILLAINS_6:
  LD (HL),C               ;
  INC L                   ;
  LD (HL),C               ;
  INC L                   ;
  LD (HL),C               ;
  ADD HL,DE               ;
  DJNZ DRAW_VILLAINS_6    ;
  JR DRAW_VILLAINS_3      ;

; Move a screen address up one pixel line
;
; Used by the routine at DRAW_VILLAINS.
;
; Within a character cell the high byte goes down one. Out of the top of a cell
; the low byte goes up a character row, and the eight the high byte borrowed
; are put back -- unless that takes the address out of the top of a third of
; the screen, when the borrow is just what is needed.
;
;   DE a screen address
; O:DE the one a line above
SCREEN_LINE_UP:
  DEC D                   ; within the cell: done
  LD A,D                  ;
  CPL                     ;
  AND $07                 ;
  RET NZ                  ;
  LD A,E                  ; up a character row; out of the top of the third:
  SUB $20                 ; done
  LD E,A                  ;
  RET C                   ;
  LD A,D                  ; still in the third: the high byte back up by eight
  ADD A,$08               ;
  LD D,A                  ;
  RET                     ;

; Print the heading on the panel: north, or south with the town turned round
;
; Used by the routines at NEW_GAME and TURN_TOWN.
;
; Four characters, a word, from the panel's icons (PANEL_ICONS): north in cyan,
; or while VIEW's bit 0 is set south in magenta, which way the town is seen
; from. At a new game, and whenever it is turned round (TURN_TOWN).
PRINT_HEADING:
  PUSH DE                 ; which word, and its colour
  LD A,(VIEW)             ;
  AND $01                 ;
  JR NZ,PRINT_HEADING_2   ;
  LD HL,HEADING_CHARS     ;
  LD A,$45                ;
PRINT_HEADING_0:
  EX AF,AF'                ; its four characters in a row, bottom right of the
  LD (FONT_BASE),HL        ; panel
  LD HL,$50DB              ;
  LD DE,HEADING_ORDER      ;
  LD B,$04                 ;
PRINT_HEADING_1:
  LD A,(DE)                ;
  INC DE                   ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  DJNZ PRINT_HEADING_1     ;
  POP DE                   ;
  RET                      ;
PRINT_HEADING_2:
  LD HL,HEADING_TURNED_CHARS ; south
  LD A,$43                   ;
  JR PRINT_HEADING_0         ;

; The heading's characters, in the order printed
;
; 0, 1, 2 and 3: the order they are stored in (PRINT_HEADING).
HEADING_ORDER:
  DEFB $00,$01,$02,$03

; Draw the compass on the panel
;
; Used by the routine at NEW_GAME.
;
; Eight characters from the panel's icons (PANEL_ICONS), in yellow, as two
; blocks of two by two (PRINT_BLOCK). The characters are stored as the
; compass's two rows of four, so COMPASS_ORDER picks them out a block at a
; time. Drawn once, at a new game.
PRINT_COMPASS:
  LD HL,PANEL_ICONS       ; the compass's characters; where; yellow
  LD (FONT_BASE),HL       ;
  LD HL,$507B             ;
  LD DE,COMPASS_ORDER     ;
  LD A,$46                ;
  EX AF,AF'               ;
  CALL PRINT_BLOCK        ; the left half, and then the right
  INC L                   ;
  INC L                   ;
  JP PRINT_BLOCK          ;

; The compass's characters, a block of two by two at a time
COMPASS_ORDER:
  DEFB $00,$01,$04,$05    ; The left half, characters 0 and 1 over 4 and 5;
  DEFB $02,$03,$06,$07    ; then the right, 2 and 3 over 6 and 7

; The panel's heading, an attribute and then the text
SCORE_TEXT:
  DEFM $45                ; Attribute
  DEFM "SCOR",$C5         ; "SCORE"

; Add BC to the score, and print it
;
; Used by the routines at CREATURE_UPDATE, MONSTER112_UPDATE, HIT_DESTROYS,
; HIT_CHANGES, HIT_SPLITS, HIT_DEMOTES, WANDERING_MONSTER and OBJECT_FLIGHT.
;
; In BCD: B goes to the middle byte of SCORE and C to SCORE_LOW, carrying up.
; The score printed is seven digits: the lower digit of SCORE's first byte, the
; four of the next two, and the two zeros of SCORE_ZEROS, which nothing writes
; -- so what is shown is a hundred times what is added: C = $25 shows as 2500.
; Measured: from nothing, BC = $0025 printed 0002500 and BC = $2500 printed
; 0250000.
;
; What scores (from the callers): a villain destroyed, 250000 (OBJECT_FLIGHT);
; a monster of 112-127 destroyed by an antibody 2500, changed 2000, split 1500,
; turned into one of 64-79 1000 (MONSTER_HIT_TABLE); the creature struck or run
; into a wall, 1000 (CREATURE_UPDATE); a monster of 64-79 struck, 500
; (WANDERING_MONSTER). And a monster that touches the knight scores too, as it
; takes his hit: 2500 for one of 112-127, 500 for one of 64-79.
;
; PRINT_SCORE prints it where it stays on the panel, in yellow; GAME_OVER uses
; PRINT_SCORE_AT to print it after a game in its own place and colour.
;
; BC the points, BCD: B in tens of thousands, C in hundreds
ADD_SCORE:
  LD HL,SCORE_LOW         ; add, in BCD, carrying up
  LD A,(HL)               ;
  ADD A,C                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ;
  LD A,(HL)               ;
  ADC A,B                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ;
  LD A,(HL)               ;
  ADC A,$00               ;
  DAA                     ;
  LD (HL),A               ;
; This entry point is used by the routine at NEW_GAME.
PRINT_SCORE:
  LD A,$46                ; PRINT_SCORE: yellow, at the bottom of the panel
  EX AF,AF'               ;
  LD HL,$50E6             ;
; This entry point is used by the routine at GAME_OVER.
PRINT_SCORE_AT:
  LD DE,SCORE             ; PRINT_SCORE_AT: four bytes from SCORE, in the
  LD B,$04                ; digits' font, from the first byte's lower digit
  PUSH HL                 ;
  LD HL,FONT              ;
  LD (FONT_BASE),HL       ;
  POP HL                  ;
  JR PRINT_BCD_LOW        ;

; Print B bytes of BCD from DE, two digits a byte
;
; Used by the routine at PRINT_PERCENTAGE.
;
; With the digits' font (FONT), whose first character is 0, so a digit's value
; is its code. Each digit's cell is coloured with A' (PRINT_CHAR_COLOURED).
; PRINT_BCD_LOW starts with the first byte's lower digit, for an odd number of
; digits -- and without setting the font (see PRINT_PERCENTAGE).
;
; DE the first byte
; B how many bytes
; HL the screen address
; A' the attribute
PRINT_BCD:
  PUSH HL                 ; the digits' font
  LD HL,FONT              ;
  LD (FONT_BASE),HL       ;
  POP HL                  ;
PRINT_BCD_0:
  LD A,(DE)                ; the higher digit
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  AND $0F                  ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
; This entry point is used by the routines at PRINT_PERCENTAGE and ADD_SCORE.
PRINT_BCD_LOW:
  LD A,(DE)                ; PRINT_BCD_LOW: the lower digit
  AND $0F                  ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  INC DE                  ; the next byte
  DJNZ PRINT_BCD_0        ;
  RET                     ;

; The creature's blip: a note chosen by the turn counter
;
; Used by the routine at CREATURE_UPDATE.
;
; Twelve waves at a pitch from BLIP_PITCHES picked by the turn counter's low
; four bits, if the record was drawn last turn; the flag is cleared, so it
; sounds once for each time the thing is on the screen. The creature's update
; calls it (CREATURE_UPDATE). Pentagram has the same bytes, unused.
;
; The villains' update (VILLAIN_WANDER) enters at BLIP_FROM_TABLE, meaning to
; give each villain its own sixteen pitches from VILLAIN_PITCHES, and misses
; twice. It loads the table's address into HL, which this routine overwrites
; with the turn's four bits before adding BC; and the offset it puts in BC, the
; graphic turned left two bits and cut to its top four, keeps graphic bit 5 as
; well as the kind, so it is $80, $90, $A0 or $B0 rather than 0 to 48. So a
; villain's blip is pitched by bytes of the ROM, from $0080 to $00BF, and the
; four villains' tables are never read (range 4's simulator run saw the
; villains read their pitches at ROM addresses in each of those four sixteens).
;
; IX the record
BLIP_BY_TURN:
  LD BC,BLIP_PITCHES      ; the creature's pitches
; This entry point is used by the routine at VILLAIN_WANDER.
BLIP_FROM_TABLE:
  BIT 1,(IX+$07)          ; BLIP_FROM_TABLE: not drawn last turn, silent; the
  RES 1,(IX+$07)          ; flag cleared either way
  RET Z                   ;
  LD A,(TURNS)            ; twelve waves at the pitch for this turn of sixteen
  AND $0F                 ;
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,BC               ;
  LD B,(HL)               ;
  LD C,$0C                ;
  JP BEEP                 ;

; Pitches for the blips: the creature's, and four for the villains that are
; never read
;
; Five tables of sixteen half-wave counts for CLICK, multiples of 16 (the
; larger, the lower), one for each turn of sixteen (BLIP_BY_TURN). The
; creature's, counts rising in three steps over and over -- a falling figure in
; pitch, since larger counts are lower notes -- is the only one read.
; VILLAIN_PITCHES starts the villains', one for each kind of villain in graphic
; order, 96-99 first, described by their counts (in pitch each is the other way
; up): a climb from $20 to $90, the same falling back, a zigzag fall from $90
; to $20, and a pattern of eight twice. The villains' code loads the address
; and then loses it (see BLIP_BY_TURN), so none of the four sounds.
;
; The same 80 bytes as Pentagram's, where they were read, as there, as the
; first sixteen and then data no code reached. sna2ctl took some of them for
; text.
BLIP_PITCHES:
  DEFB $20,$20,$30,$40,$50,$20,$20,$30 ; The creature's; then villains 96-99,
  DEFB $40,$50,$20,$20,$30,$40,$50,$20 ; 100-103, 104-107 and 108-111 (two
VILLAIN_PITCHES:
  DEFB $20,$20,$30,$30,$40,$40,$50,$50 ; lines each)
  DEFB $60,$60,$70,$70,$80,$80,$90,$90 ;
  DEFB $90,$90,$80,$80,$70,$70,$60,$60 ;
  DEFB $50,$50,$40,$40,$30,$30,$20,$20 ;
  DEFB $90,$80,$70,$80,$70,$60,$70,$60 ;
  DEFB $50,$60,$50,$40,$50,$40,$30,$20 ;
  DEFB $40,$40,$40,$30,$50,$50,$50,$50 ;
  DEFB $40,$40,$40,$30,$50,$50,$50,$50 ;

; A note for the ending, a little lower each time
;
; Used by the routine at ENDING_VILLAIN.
;
; Played by the update routine of the ending's pictures (ENDING_VILLAIN), which
; resets EFFECT_TIME when a picture has finished. EFFECT_TIME counts up one
; each time and the pitch is it plus 64: twelve waves, lower as the count
; grows. The same bytes as Pentagram's pause beep, put to another use;
; Nightshade's pause (PAUSE) is silent.
ENDING_BEEP:
  LD HL,EFFECT_TIME       ; one more on the count; the pitch 64 on from it
  INC (HL)                ;
  LD A,(HL)               ;
  ADD A,$40               ;
  LD B,A                  ;
  LD C,$0C                ; twelve waves
  JP BEEP                 ;

; The bump: a warble as something walks into a wall
;
; Used by the routines at MONSTER112_UPDATE and UPDATE_TOP.
;
; Sixteen single waves whose half-wave count is scrambled from the step count,
; (C XOR $A5) + C: the same routine as Pentagram's jump warble. Only if the
; record was drawn last turn (the flag is left for the caller): a monster of
; 112-127 meeting a wall (MONSTER112_UPDATE), and the knight (UPDATE_TOP).
;
; IX the record
BUMP_SOUND:
  BIT 1,(IX+$07)          ; not on the screen: silent
  RET Z                   ;
  LD C,$10                ; for C = 16 down to 1: one wave at (C XOR $A5) + C
BUMP_SOUND_0:
  LD A,C                  ;
  XOR $A5                 ;
  ADD A,C                 ;
  LD B,A                  ;
  CALL CLICK              ;
  DEC C                   ;
  JR NZ,BUMP_SOUND_0      ;
  RET                     ;

; Play this turn's note of the sound effect under way
;
; Used by the routine at NEW_GAME.
;
; Called by the main loop every turn. EFFECT_TIME is how many notes are left,
; EFFECT which effect. While the count is not zero, this takes one off and
; plays twelve waves at the pitch found at the effect's address in EFFECT_TABLE
; plus the count before it was taken: the notes run backwards from the end, and
; the byte at the effect's address is never played. The same routine as
; Pentagram's.
EFFECT_NOTE:
  LD HL,EFFECT_TIME       ; nothing under way: done
  LD A,(HL)               ;
  AND A                   ;
  RET Z                   ;
  DEC (HL)                ; one note fewer; keep the count before
  EX AF,AF'               ;
  INC HL                  ; HL = the effect's notes
  LD A,(HL)               ;
  LD BC,EFFECT_TABLE      ;
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
; first (EFFECT_NOTE), so the byte at each effect's address is the previous
; effect's first note. Effect 0, four notes, a new cell with a building in it
; (VISIT_CELL); 1, five, the faster walk (SPEED_BONUS); 2, seven, the hits back
; (HITS_BONUS); 3, four, an object taken up (OBJECT_LYING) -- whose first note
; is read from past the table, the first byte of FIRE_SOUND's code, a very
; short half-wave (14, about 7850 Hz where the table's own notes run from 48 to
; 128): a squeak before three ordinary notes. Pentagram has the same table but
; starts only effects 0 and 1; here effects 2 and 3 are played, so the squeak
; is heard.
EFFECT_TABLE:
  DEFW $C3E0              ; Where each effect's notes start: effects 0 to 3
  DEFW $C3E4              ;
  DEFW $C3E9              ;
  DEFW $C3F0              ;
  DEFB $40,$70,$40,$70    ; The notes: effect 0 plays the four after the first
  DEFB $50,$70,$60,$50    ; byte, 1 the five after the fifth, 2 the seven after
  DEFB $40,$40,$50,$60    ; the tenth, 3 the three after the seventeenth and
  DEFB $70,$80,$80,$80    ; the first byte of code
  DEFB $30,$60,$30,$60    ;

; The sound of a throw
;
; Used by the routine at KNIGHT_THROWS.
;
; 32 single waves; each half-wave count is the step count less the one before,
; so the counts alternate between a short one and a long one: a high note and a
; low one, interleaved. KNIGHT_THROWS plays it as an antibody or an object
; leaves the knight's hand, B being 11 less the place on the panel it came
; from, counted from the bottom place as 0 (measured for the sounds page).
; Pentagram's bolt firing.
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
; Used by the routine at WALK_ON.
;
; WALK_ON calls this for every step of the knight's walk; FOOTSTEPS counts
; them. Walking (speed under 12) every fourth plays four waves, at a half-wave
; count of 64 and 96 by turns; at the faster speed a bonus gives, every second,
; so the steps come twice as often. Pentagram's footstep plays two waves, and
; has no faster half.
;
; IX the knight's legs
FOOTSTEP:
  LD HL,FOOTSTEPS         ; one more step; how fast is he going?
  INC (HL)                ;
  LD A,(IX+$05)           ;
  CP $0C                  ;
  JR NC,FOOTSTEP_1        ;
  LD A,(HL)               ; walking: every fourth step, four waves at 64...
  BIT 2,A                 ;
  JR Z,FOOTSTEP_0         ;
  AND $03                 ;
  RET NZ                  ;
  LD BC,$4004             ;
  JR BEEP                 ;
FOOTSTEP_0:
  AND $03                 ; ...or at 96
  RET NZ                  ;
  LD BC,$6004             ;
  JR BEEP                 ;
FOOTSTEP_1:
  LD A,(HL)               ; faster: every second, at 64...
  BIT 1,A                 ;
  JR Z,FOOTSTEP_2         ;
  AND $01                 ;
  RET NZ                  ;
  LD BC,$4004             ;
  JR BEEP                 ;
FOOTSTEP_2:
  AND $01                 ; ...or at 96
  RET NZ                  ;
  LD BC,$6004             ;
  JR BEEP                 ;

; The sound of a puff
;
; Used by the routine at VANISHING.
;
; Sixteen single waves at pitches read from the ROM, as Pentagram's puff and
; Knight Lore's crashes are: the random number with its high byte cut to five
; bits is an address in the first 8K, and each byte there, less its top bit, is
; a half-wave count. VANISHING plays it as a puff (graphics 12-15) ends, if it
; was drawn last turn; the flag is cleared.
;
; IX the record
PUFF_SOUND:
  BIT 1,(IX+$07)          ; not drawn last turn: silent; the flag cleared
  RES 1,(IX+$07)          ; either way
  RET Z                   ;
  LD HL,(RANDOM)          ; HL = somewhere in the first 8K of the ROM; sixteen
  LD A,H                  ; waves
  AND $1F                 ;
  LD H,A                  ;
  LD E,$10                ;
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

; A monster appearing: a note pitched by its graphic
;
; Used by the routine at APPEARING_UPDATE.
;
; Six waves, the half-wave count the complement of the graphic turned right
; three bits, the top three kept: $E0, $C0, $A0 and $80 for graphics 128-131,
; so the note rises as the monster appears (APPEARING_UPDATE). Pentagram has
; these bytes left over as data.
;
; IX the record
APPEAR_SOUND:
  LD A,(IX+$00)           ; the pitch from the graphic
  CPL                     ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $E0                 ;
  LD B,A                  ;
  LD C,$06                ; six waves
  JR BEEP                 ;

; The knight appearing: a note that rises
;
; Used by the routine at UPDATE_KNIGHT.
;
; Eight waves, the half-wave count the complement of ARRIVING, which climbs by
; two a turn while he appears (UPDATE_KNIGHT): the note rises with it. BEEP,
; the rest, plays C waves at one pitch for most of the sounds here. The same
; code as the second half of Pentagram's unused beeps, which pitch it from a
; spare byte.
;
; B (at BEEP) the half-wave count
; C (at BEEP) the number of waves
ARRIVE_SOUND:
  LD A,(ARRIVING)         ; the pitch from ARRIVING; eight waves
  CPL                     ;
  LD B,A                  ;
  LD C,$08                ;
; This entry point is used by the routines at BLIP_BY_TURN, ENDING_BEEP,
; EFFECT_NOTE, FOOTSTEP, PUFF_SOUND and APPEAR_SOUND.
BEEP:
  CALL CLICK              ; BEEP: C waves at half-wave count B
  DEC C                   ;
  JR NZ,BEEP              ;
  RET                     ;

; One wave
;
; Used by the routines at BUMP_SOUND, FIRE_SOUND and ARRIVE_SOUND.
;
; Speaker bit on for B turns of a 13 T-state loop, then off for as long, with
; the border black throughout. The same routine as Knight Lore's, Alien 8's and
; Pentagram's.
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

; Taking up a find: which kind of antibody it gives
;
; Used by the routine at PICK_UP_THING.
;
; Part of PICK_UP_THING: a find of graphics 48-63 is carried as thing 5-8, by
; bits 2-3 of its graphic -- the low two bits of the type of cell it was found
; in (SPAWN_FIND).
PICK_UP_FIND:
  RRA                     ; things 5-8
  RRA                     ;
  AND $03                 ;
  ADD A,$05               ;
  JR PICK_UP_THING_2      ; carried as an object is

; Take up a thing the knight touches, if he has room
;
; Used by the routines at OBJECT_LYING and FIND_WANDER.
;
; Called by the update routines of an object lying in the street (OBJECT_LYING)
; and of a find (FIND_WANDER) when it touches him. The thing goes into the
; first empty place of the eleven in CARRIED -- an object as 1-4, its graphic
; less 3, a find as 5-8 -- its record is emptied, and its icon is drawn in its
; place on the panel, the first place at the bottom and each above the last.
; With all eleven full nothing is taken, and the thing stays where it is.
;
; KNIGHT_THROWS enters at DRAW_CARRIED to draw a place again after a throw,
; with 0, the blank icon, for an empty place.
;
; IX the thing's record
PICK_UP_THING:
  LD HL,CARRIED           ; the first empty place; none: nothing is taken
  LD B,$0B                ;
PICK_UP_THING_0:
  LD A,(HL)               ;
  AND A                   ;
  JR Z,PICK_UP_THING_1    ;
  INC HL                  ;
  DJNZ PICK_UP_THING_0    ;
  RET                     ;
PICK_UP_THING_1:
  LD A,(IX+$00)           ; an object (graphics 4-7) is thing 1-4; a find goes
  CP $30                  ; to PICK_UP_FIND
  JR NC,PICK_UP_FIND      ;
  SUB $03                 ;
; This entry point is used by the routine at PICK_UP_FIND.
PICK_UP_THING_2:
  LD (HL),A               ; carried; the record emptied
  LD (IX+$00),$00         ;
; This entry point is used by the routine at KNIGHT_THROWS.
DRAW_CARRIED:
  EX DE,HL                ; DRAW_CARRIED: DE = the place; the icons' characters
  LD HL,ICONS             ; (ICONS)
  LD (FONT_BASE),HL       ;
  LD A,B                  ; the place's number (11 - B) sets the height: 16
  NEG                     ; pixels a place up from the bottom, 16 in
  ADD A,$0B               ;
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $F0                 ;
  ADD A,$17               ;
  LD H,A                  ;
  LD L,$10                ;
  CALL CALC_VRAM_ADDR     ;
  LD A,(DE)               ; the thing's four characters, two over two
  ADD A,A                 ;
  ADD A,A                 ;
  PUSH AF                 ;
  CALL PRINT_CODE         ;
  POP AF                  ;
  INC A                   ;
  INC L                   ;
  PUSH AF                 ;
  CALL PRINT_CODE         ;
  DEC L                   ;
  CALL NEXT_CHAR_ROW      ;
  POP AF                  ;
  INC A                   ;
  PUSH AF                 ;
  CALL PRINT_CODE         ;
  POP AF                  ;
  INC A                   ;
  INC L                   ;
  JP PRINT_CODE           ;

; Colour the carried things on the panel, flashing an object near its villain
;
; Used by the routine at NEW_GAME.
;
; Every turn. Each carried thing's icon is given its colour from THING_COLOURS,
; two by two, from the bottom of the panel up to the first empty place: an
; object in the colour its villain is drawn in once destroyed (DRAW_VILLAINS),
; the four kinds of antibody magenta, green, cyan and yellow. An object whose
; villain is less than five cells from the knight in column and row flashes
; through the antibody colours instead, one a turn: the game's sign that the
; villain it kills is near.
COLOUR_CARRIED:
  LD BC,THING_COLOURS     ; in the second register set: the colours, and the
  LD HL,$5AC2             ; attribute of the lowest place
  EXX                     ;
  LD DE,CARRIED           ; the eleven places, as far as the first empty one
  LD B,$0B                ;
COLOUR_CARRIED_0:
  LD A,(DE)               ;
  AND A                   ;
  RET Z                   ;
  CP $05                  ; an object? is its villain near?
  JR C,COLOUR_CARRIED_2   ;
COLOUR_CARRIED_1:
  EXX                     ; the thing's colour
  EX DE,HL                ;
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  EX DE,HL                ; two attributes, and the two above; HL on up to the
  LD (HL),A               ; next place
  INC HL                  ;
  LD (HL),A               ;
  LD DE,$FFDF             ;
  ADD HL,DE               ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  ADD HL,DE               ;
  EXX                     ; the next place
  INC DE                  ;
  DJNZ COLOUR_CARRIED_0   ;
  RET                     ;
COLOUR_CARRIED_2:
  PUSH AF                 ; IX = the villain object n kills: record 4 - n; less
  PUSH DE                 ; than five cells away?
  CPL                     ;
  ADD A,$05               ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  LD E,A                  ;
  LD D,$00                ;
  LD IX,VILLAINS          ;
  ADD IX,DE               ;
  LD C,$05                ;
  CALL NEAR_KNIGHT        ;
  JR C,COLOUR_CARRIED_3   ;
  POP DE                  ; no: its own colour
  POP AF                  ;
  JR COLOUR_CARRIED_1     ;
COLOUR_CARRIED_3:
  POP DE                  ; yes: an antibody's colour, a different one each
  POP AF                  ; turn
  LD A,(TURNS)            ;
  AND $03                 ;
  ADD A,$05               ;
  JR COLOUR_CARRIED_1     ;

; Colours of the carried things and of the destroyed villains
;
; An attribute for each thing by its number, all bright on black: 1-4 the
; objects, red, magenta, green and cyan; 5-8 the antibodies, magenta, green,
; cyan and yellow. DRAW_VILLAINS colours the picture of the villain in record n
; with the byte for thing 4 - n, the object that kills it, so the two share a
; colour. The first byte, for thing 0, is never read. sna2ctl took the first
; byte for spare space and the rest for text.
THING_COLOURS:
  DEFB $00                ; Thing 0: never read
  DEFB $42,$43,$44,$45    ; Things 1-4, the objects; 5-8, the antibodies
  DEFB $43,$44,$45,$46    ;

; Is the thing at IX struck by an antibody?
;
; Used by the routines at CREATURE_UPDATE, MONSTER112_UPDATE and
; WANDERING_MONSTER.
;
; Meant to try both antibody records against the thing at IX, returning with
; carry set and IY on the antibody that touches it. But the loop loads the size
; of a record into DE and never adds it to IY, so it tries the first record
; twice and never the second: an antibody thrown while another is still in
; flight goes through monsters and the creature without harming them. Used by
; the creature (CREATURE_UPDATE), the monsters of 112-127 (MONSTER112_UPDATE)
; and those of 64-79 (WANDERING_MONSTER).
;
; Measured: with an antibody on a monster in the first record, carry; the same
; antibody in the second record, no carry, IY still on the first.
;
;   IX the thing
; O:F carry if struck
; O:IY the first antibody record
ANTIBODY_STRIKE:
  LD IY,ANTIBODIES        ; IY = the first antibody record; two tries
  LD B,$02                ;
ANTIBODY_STRIKE_0:
  PUSH BC                 ; touching? carry
  CALL ANTIBODY_TOUCHING  ;
  POP BC                  ;
  RET C                   ;
  LD DE,$0010             ; the step to the next record is loaded, but never
  DJNZ ANTIBODY_STRIKE_0  ; added
  RET

; Does the antibody at IY touch the thing at IX?
;
; Used by the routine at ANTIBODY_STRIKE.
;
;   IX the thing
;   IY an antibody record
; O:F carry if it does
ANTIBODY_TOUCHING:
  LD A,(IY+$00)           ; not an antibody in flight (graphics 80-95): no
  SUB $50                 ;
  CP $10                  ;
  RET NC                  ;
  JR TOUCH_TEST           ; the overlap test

; Does a thrown object touch its villain?
;
; Used by the routine at OBJECT_FLIGHT.
;
; For OBJECT_FLIGHT, the update routine of a thrown object. Its villain is the
; record 64 bytes on from its own -- the object and villain records are in the
; same order (RANDOM) -- and this is the only test made, so an object passes
; through the other three villains harmlessly.
;
;   IX the object's record
; O:F carry if it touches its villain
OBJECT_STRIKE:
  PUSH IX                 ; IY = its villain; the overlap test
  POP IY                  ;
  LD DE,$0040             ;
  ADD IY,DE               ;
  JR TOUCH_TEST           ;

; Does the thing at IX touch the knight?
;
; Used by the routines at SPAWN_CREATURE, CREATURE_UPDATE, MONSTER112_UPDATE,
; WANDERING_MONSTER, SPEED_BONUS, HITS_BONUS, OBJECT_LYING, VILLAIN_WANDER and
; FIND_WANDER.
;
; Never while he is appearing (ARRIVING short of $70), nor unless his legs are
; standing or walking (graphics 16-47): not while he vanishes. TOUCH_TEST, the
; rest, is the overlap test every touching test in the game ends with, IX
; against IY: along U the distance between them, the whole 16-bit positions,
; must be less than IX's half-size plus half of IY's; the same along V; carry
; if both. The positions carry the cell, so things in neighbouring cells meet
; across the line between them.
;
;   IX the thing
; O:F carry if touching
TOUCHING_KNIGHT:
  LD A,(ARRIVING)         ; still appearing: no
  SUB $70                 ;
  AND A                   ;
  RET NZ                  ;
  LD IY,KNIGHT            ; IY = his legs; not standing or walking: no
  LD A,(IY+$00)           ;
  SUB $10                 ;
  CP $20                  ;
  RET NC                  ;
; This entry point is used by the routines at ANTIBODY_TOUCHING and
; OBJECT_STRIKE.
TOUCH_TEST:
  LD A,(IY+$08)           ; TOUCH_TEST: C = half IY's half-size in U, plus IX's
  SRL A                   ;
  ADD A,(IX+$08)          ;
  LD C,A                  ;
  LD B,$00                ;
  LD L,(IX+$01)           ; HL = how far apart they are along U, made positive
  LD H,(IX+$02)           ;
  LD E,(IY+$01)           ;
  LD D,(IY+$02)           ;
  AND A                   ;
  SBC HL,DE               ;
  CALL C,NEGATE_HL        ;
  AND A                   ; not closer than C: no
  SBC HL,BC               ;
  RET NC                  ;
  LD A,(IY+$09)           ; the same along V; carry if closer
  SRL A                   ;
  ADD A,(IX+$09)          ;
  LD C,A                  ;
  LD B,$00                ;
  LD L,(IX+$03)           ;
  LD H,(IX+$04)           ;
  LD E,(IY+$03)           ;
  LD D,(IY+$04)           ;
  AND A                   ;
  SBC HL,DE               ;
  CALL C,NEGATE_HL        ;
  AND A                   ;
  SBC HL,BC               ;
  RET                     ;

; Count a turn, and stir the random number
;
; Used by the routines at NEW_GAME, STOCK_BUILDINGS, MENU, PLACE_OBJECTS and
; PLACE_VILLAINS.
;
; NEXT_TURN adds one to TURNS, once a turn in the main loop and at a few points
; of a new game's set-up. STIR_RANDOM, the rest, is called after every record's
; update and before most random choices. The random number's low byte becomes R
; plus itself plus the turn counter's low byte, with the carry; its high byte
; just adds the turn counter's high byte, with no carry from the low. R counts
; the instructions run, which depends on all the game has done, so the low byte
; is hard to predict; the high byte is not -- a fixed step, the same for 256
; turns at a time, added once a stir.
NEXT_TURN:
  LD HL,(TURNS)           ; one more turn
  INC HL                  ;
  LD (TURNS),HL           ;
; This entry point is used by the routines at NEW_GAME, RANDOM_START_CELL,
; SPAWN_MONSTER and PLACE_BONUS.
STIR_RANDOM:
  LD HL,(TURNS)           ; STIR_RANDOM: the low byte from R, itself and the
  LD DE,(RANDOM)          ; counter's low byte; the high byte plus the
  LD A,R                  ; counter's high byte
  ADD A,E                 ;
  ADC A,L                 ;
  LD L,A                  ;
  LD A,D                  ;
  ADD A,H                 ;
  LD H,A                  ;
  LD (RANDOM),HL          ; kept
  RET                     ;

; Every sixteen turns, a find in the knight's cell if its type has any left
;
; Used by the routine at NEW_GAME.
;
; Not while he is appearing. If a find record is free and the type of cell he
; stands in still has finds in STOCKS, one is taken from the stock and a find
; (graphic 48, 52, 56 or 60, by the type's low two bits) put in his cell at a
; random place 64-191 across it each way, half-size 8. The stock is shared by
; every cell of the type, and the find keeps the type at +5 so that FIND_WANDER
; can put it back if he leaves it behind. Open ground, type 0, has no stock:
; finds come only in cells with buildings.
SPAWN_FIND:
  LD A,(ARRIVING)         ; not while he appears
  CP $70                  ;
  RET NZ                  ;
  LD A,(TURNS)            ; one turn in sixteen
  AND $0F                 ;
  RET NZ                  ;
  LD IY,FINDS             ; the first empty find record; none: no find
  LD DE,$0010             ;
  LD B,$04                ;
SPAWN_FIND_0:
  LD A,(IY+$00)           ;
  AND A                   ;
  JR Z,SPAWN_FIND_1       ;
  ADD IY,DE               ;
  DJNZ SPAWN_FIND_0       ;
  RET                     ;
SPAWN_FIND_1:
  LD A,(KNIGHT_COLUMN)    ; his cell, and its type from the map
  LD L,A                  ;
  LD A,(KNIGHT_ROW)       ;
  LD H,A                  ;
  LD E,L                  ;
  LD D,H                  ;
  CALL TOWN_CELL          ;
  LD C,A                  ; none left of that type: no find
  LD B,$00                ;
  LD HL,STOCKS            ;
  ADD HL,BC               ;
  LD A,(HL)               ;
  AND A                   ;
  RET Z                   ;
  DEC (HL)                ; one fewer; the find in his cell, its type kept at
  LD (IY+$02),E           ; +5
  LD (IY+$04),D           ;
  LD (IY+$05),C           ;
  LD A,C                  ; graphic 48, 52, 56 or 60 by the type's low two bits
  AND $03                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  OR $30                  ;
  LD (IY+$00),A           ;
  LD HL,(RANDOM)          ; a random place in the cell, 64-191 each way
  LD A,L                  ;
  AND $7F                 ;
  ADD A,$40               ;
  LD (IY+$01),A           ;
  LD A,H                  ;
  AND $7F                 ;
  ADD A,$40               ;
  LD (IY+$03),A           ;
  LD A,$08                ; half-size 8 each way; the drawing offset
  LD (IY+$08),A           ;
  LD (IY+$09),A           ;
  LD (IY+$0C),$F8         ;
  LD (IY+$0D),$04         ;
  RET                     ;

; Play the menu's tune at DE, once, until a key is pressed
;
; Used by the routine at MENU.
;
; The menu (MENU) calls this every time round its loop. TUNE_PLAYED remembers
; that the tune has been played, so it plays only the first time; a new game
; clears it with the rest of the variables, so it plays again when the menu
; comes back. Before each note the whole keyboard is read, and any key stops
; the tune at once. The same routine as Alien 8's and Pentagram's.
;
; DE the tune
PLAY_TUNE_ONCE:
  LD HL,TUNE_PLAYED       ; played already: done
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
; Used by the routines at NEW_GAME, MENU, NEW_LIFE, GAME_OVER and
; ENDING_PIT_FRONT.
;
; Plays the whole tune and returns; nothing else happens meanwhile. Used by
; NEW_GAME as a game starts, NEW_LIFE at each new life after the first,
; GAME_OVER after a game and ENDING_PIT_FRONT at the end of the ending.
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
  RET                     ; DE is left at the $FF

; Play one note
;
; Used by the routines at PLAY_TUNE_ONCE and PLAY_TUNE.
;
; A note byte's low six bits index NOTES, with 0 a rest; its top two bits are
; its length less one, one to four units. The note's three bytes are two loop
; counts that time each half of a wave and how many waves make one unit, and
; the wave count rises with the pitch, which keeps every unit close to the same
; length whatever the note. The speaker is driven directly, off for one
; half-wave and on for the other, with the border black.
;
; The routine and NOTES are byte for byte Knight Lore's (play_note there),
; Alien 8's and Pentagram's, at other addresses.
;
; A the note byte
; DE the address of the note byte; on exit, the next one
PLAY_NOTE:
  AND $3F                 ; index 0 is a rest
  JR Z,NOTE_REST          ;
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
  POP BC                  ; speaker on; wait
  PUSH BC                 ;
  LD A,$10                ;
  OUT ($FE),A             ;
PLAY_NOTE_4:
  DJNZ PLAY_NOTE_4        ;
  DEC C                   ;
  JR NZ,PLAY_NOTE_4       ;
  POP BC                  ; until all the waves are done
  DEC HL                  ;
  LD A,H                  ;
  OR L                    ;
  JR NZ,PLAY_NOTE_2       ;
  INC DE                  ; on to the next note byte
  RET                     ;
NOTE_REST:
  LD A,(DE)               ; NOTE_REST: a rest, one to four units...
  INC DE                  ;
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  INC A                   ;
  LD L,A                  ; ...each 17163 turns of a 26 T-state loop, about
  LD BC,$430B             ; 0.127 seconds (no tune has a rest, and this never
PLAY_NOTE_5:
  PUSH BC                 ; ran)
PLAY_NOTE_6:
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,PLAY_NOTE_6       ;
  POP BC                  ;
  DEC L                   ;
  JR NZ,PLAY_NOTE_5       ;
  RET                     ;

; The notes: two loop counts and a length for each
;
; Three bytes a note, looked up by PLAY_NOTE at three times the note number: B
; and C, the two counts of the timing loop that holds the speaker off and then
; on for half a cycle each, and the number of cycles one unit of the note
; lasts. A half cycle is B + 256 * (C - 1) passes of the loop, so note 1 is the
; lowest; each note's count is the one before's divided by very nearly the
; twelfth root of two (2548 and 2405 for notes 1 and 2), so the sixty notes are
; semitones, five octaves. The third byte grows as the pitch rises, so that a
; unit lasts about the same time whatever the note -- about forty-one thousand
; passes of the loop, a little under a sixth of a second.
;
; Note 0 is a rest: PLAY_NOTE goes to a fixed delay instead and never reads its
; three zeros.
NOTES:
  DEFB $00,$00,$00        ; Note 0: a rest, which PLAY_NOTE does not look up
  DEFB $F4,$0A,$08        ; Note 1: loop counts 244 and 10; 8 cycles a unit
  DEFB $65,$0A,$09        ; Note 2: loop counts 101 and 10; 9 cycles a unit
  DEFB $DE,$09,$09        ; Note 3: loop counts 222 and 9; 9 cycles a unit
  DEFB $5E,$09,$0A        ; Note 4: loop counts 94 and 9; 10 cycles a unit
  DEFB $E7,$08,$0A        ; Note 5: loop counts 231 and 8; 10 cycles a unit
  DEFB $75,$08,$0B        ; Note 6: loop counts 117 and 8; 11 cycles a unit
  DEFB $0A,$08,$0C        ; Note 7: loop counts 10 and 8; 12 cycles a unit
  DEFB $A5,$07,$0C        ; Note 8: loop counts 165 and 7; 12 cycles a unit
  DEFB $45,$07,$0D        ; Note 9: loop counts 69 and 7; 13 cycles a unit
  DEFB $EB,$06,$0E        ; Note 10: loop counts 235 and 6; 14 cycles a unit
  DEFB $96,$06,$0F        ; Note 11: loop counts 150 and 6; 15 cycles a unit
  DEFB $46,$06,$0F        ; Note 12: loop counts 70 and 6; 15 cycles a unit
  DEFB $FA,$05,$10        ; Note 13: loop counts 250 and 5; 16 cycles a unit
  DEFB $B3,$05,$11        ; Note 14: loop counts 179 and 5; 17 cycles a unit
  DEFB $6F,$05,$12        ; Note 15: loop counts 111 and 5; 18 cycles a unit
  DEFB $2F,$05,$13        ; Note 16: loop counts 47 and 5; 19 cycles a unit
  DEFB $F3,$04,$15        ; Note 17: loop counts 243 and 4; 21 cycles a unit
  DEFB $F3,$04,$16        ; Note 18: loop counts 243 and 4; 22 cycles a unit
  DEFB $85,$04,$17        ; Note 19: loop counts 133 and 4; 23 cycles a unit
  DEFB $52,$04,$19        ; Note 20: loop counts 82 and 4; 25 cycles a unit
  DEFB $23,$04,$1A        ; Note 21: loop counts 35 and 4; 26 cycles a unit
  DEFB $F6,$03,$1C        ; Note 22: loop counts 246 and 3; 28 cycles a unit
  DEFB $CB,$03,$1D        ; Note 23: loop counts 203 and 3; 29 cycles a unit
  DEFB $A3,$03,$1F        ; Note 24: loop counts 163 and 3; 31 cycles a unit
  DEFB $7D,$03,$21        ; Note 25: loop counts 125 and 3; 33 cycles a unit
  DEFB $59,$03,$23        ; Note 26: loop counts 89 and 3; 35 cycles a unit
  DEFB $38,$03,$25        ; Note 27: loop counts 56 and 3; 37 cycles a unit
  DEFB $18,$03,$27        ; Note 28: loop counts 24 and 3; 39 cycles a unit
  DEFB $FA,$02,$29        ; Note 29: loop counts 250 and 2; 41 cycles a unit
  DEFB $DD,$02,$2C        ; Note 30: loop counts 221 and 2; 44 cycles a unit
  DEFB $C2,$02,$2E        ; Note 31: loop counts 194 and 2; 46 cycles a unit
  DEFB $A9,$02,$31        ; Note 32: loop counts 169 and 2; 49 cycles a unit
  DEFB $91,$02,$34        ; Note 33: loop counts 145 and 2; 52 cycles a unit
  DEFB $7B,$02,$37        ; Note 34: loop counts 123 and 2; 55 cycles a unit
  DEFB $66,$02,$3A        ; Note 35: loop counts 102 and 2; 58 cycles a unit
  DEFB $51,$02,$3E        ; Note 36: loop counts 81 and 2; 62 cycles a unit
  DEFB $3F,$02,$41        ; Note 37: loop counts 63 and 2; 65 cycles a unit
  DEFB $2D,$02,$45        ; Note 38: loop counts 45 and 2; 69 cycles a unit
  DEFB $1C,$02,$49        ; Note 39: loop counts 28 and 2; 73 cycles a unit
  DEFB $0C,$02,$4E        ; Note 40: loop counts 12 and 2; 78 cycles a unit
  DEFB $FD,$01,$52        ; Note 41: loop counts 253 and 1; 82 cycles a unit
  DEFB $EF,$01,$57        ; Note 42: loop counts 239 and 1; 87 cycles a unit
  DEFB $E2,$01,$5D        ; Note 43: loop counts 226 and 1; 93 cycles a unit
  DEFB $D5,$01,$62        ; Note 44: loop counts 213 and 1; 98 cycles a unit
  DEFB $C9,$01,$68        ; Note 45: loop counts 201 and 1; 104 cycles a unit
  DEFB $BD,$01,$6E        ; Note 46: loop counts 189 and 1; 110 cycles a unit
  DEFB $B3,$01,$75        ; Note 47: loop counts 179 and 1; 117 cycles a unit
  DEFB $A9,$01,$7B        ; Note 48: loop counts 169 and 1; 123 cycles a unit
  DEFB $9F,$01,$83        ; Note 49: loop counts 159 and 1; 131 cycles a unit
  DEFB $96,$01,$8B        ; Note 50: loop counts 150 and 1; 139 cycles a unit
  DEFB $8E,$01,$93        ; Note 51: loop counts 142 and 1; 147 cycles a unit
  DEFB $86,$01,$9C        ; Note 52: loop counts 134 and 1; 156 cycles a unit
  DEFB $7E,$01,$A5        ; Note 53: loop counts 126 and 1; 165 cycles a unit
  DEFB $77,$01,$AF        ; Note 54: loop counts 119 and 1; 175 cycles a unit
  DEFB $71,$01,$B9        ; Note 55: loop counts 113 and 1; 185 cycles a unit
  DEFB $6A,$01,$C4        ; Note 56: loop counts 106 and 1; 196 cycles a unit
  DEFB $64,$01,$D0        ; Note 57: loop counts 100 and 1; 208 cycles a unit
  DEFB $5F,$01,$DC        ; Note 58: loop counts 95 and 1; 220 cycles a unit
  DEFB $59,$01,$E9        ; Note 59: loop counts 89 and 1; 233 cycles a unit
  DEFB $54,$01,$F7        ; Note 60: loop counts 84 and 1; 247 cycles a unit

; Tune: the menu's tune
;
; 131 notes.
;
; A byte a note: bits 0-5 the note in NOTES (0 would be a rest, and no tune has
; one), bits 6-7 its length in units less one; $FF ends the tune. PLAY_TUNE
; plays a tune through; PLAY_TUNE_ONCE plays this one, the first time the menu
; comes up after the start or a game, and stops at a key.
TUNE_MENU:
  DEFB $19,$1E,$21,$1E,$19,$1E,$21,$1E ; Notes
  DEFB $1D,$20,$23,$20,$1D,$20,$23,$20 ;
  DEFB $1E,$21,$25,$21,$1E,$21,$25,$21 ;
  DEFB $20,$23,$26,$23,$20,$23,$26,$23 ;
  DEFB $21,$25,$28,$25,$21,$25,$28,$25 ;
  DEFB $23,$26,$29,$26,$23,$26,$29,$26 ;
  DEFB $25,$2A,$2D,$2A,$25,$2A,$2D,$2A ;
  DEFB $26,$29,$2C,$29,$26,$29,$2C,$29 ;
  DEFB $2A,$2D,$31,$2D,$2A,$2D,$31,$2D ;
  DEFB $29,$2C,$2F,$2C,$29,$2C,$2F,$2C ;
  DEFB $2A,$2D,$2A,$2D,$2A,$2D,$2A,$2D ;
  DEFB $2C,$2F,$2C,$2F,$2C,$2F,$2C,$2F ;
  DEFB $31,$2D,$2A,$2D,$2A,$25,$2A,$25 ;
  DEFB $21,$25,$21,$1E,$21,$1E,$19,$1A ;
  DEFB $1E,$21,$19,$1E,$21,$18,$1E,$21 ;
  DEFB $17,$1D,$20,$1E,$1D,$1E,$12,$15 ;
  DEFB $19,$1D,$5E                     ;
  DEFB $FF                ; End of the tune

; Tune: a control method chosen
;
; 3 notes.
;
; Played by MENU when a key on the menu changes the control method or
; directional control; Alien 8's menu beeps there instead.
TUNE_CONTROL_CHOSEN:
  DEFB $2A,$2D,$31        ; Notes
  DEFB $FF                ; End of the tune

; Tune: a game starting
;
; 10 notes.
;
; Played by NEW_GAME when 0 is pressed on the menu, before the play screen is
; drawn.
TUNE_GAME_START:
  DEFB $25,$2A,$2D,$2A,$2D,$31,$25,$27 ; Notes
  DEFB $29,$2A                         ;
  DEFB $FF                ; End of the tune

; Tune: game over
;
; 22 notes.
;
; Played by GAME_OVER once the percentage and the score are on the screen.
TUNE_GAME_OVER:
  DEFB $2D,$2A,$25,$2A,$25,$21,$25,$21 ; Notes
  DEFB $1E,$21,$1E,$19,$1A,$1E,$21,$19 ;
  DEFB $1E,$21,$20,$1E,$1D,$1E         ;
  DEFB $FF                ; End of the tune

; Tune: the end of the ending
;
; 30 notes.
;
; Played by ENDING_PIT_FRONT when the last villain has sunk into the pit,
; before the menu.
TUNE_ENDING:
  DEFB $2C,$2A,$2D,$2D,$2C,$28,$25,$2C ; Notes
  DEFB $2A,$26,$23,$2A,$2A,$25,$21,$23 ;
  DEFB $25,$2A,$2D,$2D,$2C,$28,$25,$24 ;
  DEFB $25,$23,$21,$20,$5E,$1E         ;
  DEFB $FF                ; End of the tune

; Tune: a new life
;
; 5 notes.
;
; Played by NEW_LIFE when a life ends and there is another; not for the first
; life of a game, and not when none are left.
TUNE_NEW_LIFE:
  DEFB $25,$24,$23,$22,$61 ; Notes
  DEFB $FF                ; End of the tune

; Draw the frame round the carried things
;
; Used by the routine at NEW_GAME.
;
; The panel down the left of the screen: two uprights in character columns 1
; and 4, from the top row to the bottom, joined along the bottom row, in bright
; magenta. The eleven things the knight carries are drawn between them, a
; picture two characters square each, one above the other (PICK_UP_THING). The
; five pieces are the characters at PANEL_CHARS, in this order: 0 the top of an
; upright, 1 an upright, 2 the bottom left corner, 3 the bar, 4 the bottom
; right corner -- so the foot is printed 2, 3, 3, 4. Called once a game, by
; NEW_GAME.
DRAW_PANEL_FRAME:
  LD A,$43                ; bright magenta into A'
  EX AF,AF'               ;
  LD HL,PANEL_CHARS       ; the five pieces are codes 0-4
  LD (FONT_BASE),HL       ;
  LD HL,$4001              ; column 1: its top, on the top row
  XOR A                    ;
  CALL PRINT_CHAR_COLOURED ;
  CALL NEXT_CHAR_ROW       ;
  LD A,$01                ; then 22 uprights, down to row 22
  LD B,$16                ;
  CALL PANEL_UPRIGHTS     ;
  LD A,$02                 ; row 23: the left corner, two lengths of bar, the
  CALL PRINT_CHAR_COLOURED ; right corner
  INC L                    ;
  LD A,$03                 ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  LD A,$03                 ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  LD A,$04                 ;
  CALL PRINT_CHAR_COLOURED ;
  LD HL,$4004              ; column 4: its top
  XOR A                    ;
  CALL PRINT_CHAR_COLOURED ;
  CALL NEXT_CHAR_ROW       ;
  LD A,$01                ; and 22 uprights, by running into the loop
  LD B,$16                ;
PANEL_UPRIGHTS:
  PUSH AF                  ; B pieces A, one below the other
  CALL PRINT_CHAR_COLOURED ;
  CALL NEXT_CHAR_ROW       ;
  POP AF                   ;
  DJNZ PANEL_UPRIGHTS      ;
  RET                      ;

; Colour a strip two cells wide in the play area's attributes
;
; Used by the routine at COLOUR_WALL.
;
; Writes the colour, with the play area's paper this turn (LAST_FLASH) mixed
; in, into two neighbouring cells of each of B rows of the attribute buffer, 24
; bytes a row. COLOUR_WALL colours the buildings' walls with it; running a
; strip down to the bottom row of the buffer writes one byte beyond it
; (ATTR_SPILL).
;
; A the colour
; HL the first cell in the attribute buffer (ATTR_BUFFER)
; B how many rows
COLOUR_STRIP:
  LD E,A                  ; the colour with this turn's paper
  LD A,(LAST_FLASH)       ;
  OR E                    ;
  LD DE,$0017             ; two cells a row, B rows
COLOUR_STRIP_0:
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  ADD HL,DE               ;
  DJNZ COLOUR_STRIP_0     ;
  RET                     ;

; Colour the knight by the hits he has left
;
; Used by the routine at NEW_GAME.
;
; Called every turn by NEW_GAME with the knight's place in the middle of the
; play area: bright white with three hits left, yellow with two, green with
; one. Four rows of two cells: the left one of each row bright and the right
; one not, with the play area's paper this turn mixed into both. Nothing is
; coloured while his record is empty, between one life and the next.
;
; A the colour (from the list at KNIGHT_COLOURS, by HITS)
; HL his place in the attribute buffer
; B how many rows (4)
COLOUR_KNIGHT:
  EX AF,AF'               ; nothing while his legs' record is empty
  LD A,(KNIGHT)           ;
  AND A                   ;
  RET Z                   ;
  EX AF,AF'               ;
  LD E,A                  ; the colour with this turn's paper
  LD A,(LAST_FLASH)       ;
  OR E                    ;
  LD DE,$0017             ;
COLOUR_KNIGHT_0:
  OR $40                  ; each row: the left cell bright, the right one not
  LD (HL),A               ; bright and not flashing
  INC HL                  ;
  AND $3F                 ;
  LD (HL),A               ;
  ADD HL,DE               ;
  DJNZ COLOUR_KNIGHT_0    ;
  RET                     ;

; Fill a rectangle of the play area's attributes
;
; Used by the routine at ENDING_PIT_FRONT.
;
; As Pentagram's FILL_RECT, but for the attribute buffer, 24 bytes a row, and
; with the play area's paper this turn (LAST_FLASH) mixed into the colour. The
; ending's pictures are coloured with it (ENDING_PIT_FRONT).
;
; A the colour
; HL the top-left cell's address in the attribute buffer
; B the width, in cells
; C the height, in rows
FILL_ATTR_RECT:
  LD E,A                  ; the colour with this turn's paper
  LD A,(LAST_FLASH)       ;
  OR E                    ;
  EX AF,AF'               ; DE = 24 - B, from the end of one row to the start
  LD A,$18                ; of the next
  SUB B                   ;
  LD E,A                  ;
  LD D,$00                ;
  EX AF,AF'               ;
FILL_ATTR_RECT_0:
  PUSH BC                 ; B cells a row, C rows
FILL_ATTR_RECT_1:
  LD (HL),A               ;
  INC HL                  ;
  DJNZ FILL_ATTR_RECT_1   ;
  ADD HL,DE               ;
  POP BC                  ;
  DEC C                   ;
  JR NZ,FILL_ATTR_RECT_0  ;
  RET                     ;

; The menu
;
; Used by the routine at NEW_GAME.
;
; Called by NEW_GAME before every game, after the screen has been cleared. It
; clears MENU_SHOWN, so that the first time the text is printed the border is
; drawn round it, stops every line's flash, clears the play area's buffers (the
; second half of SHOW_PLAY_AREA), draws the menu (DISPLAY_MENU) and flashes the
; lines chosen (FLASH_MENU). Then round a loop: print the text again (which
; rewrites the attributes, and so the flashing), play the menu's tune the first
; time round (PLAY_TUNE_ONCE, which a key cuts short), and read the keys.
;
; Keys 1 to 4 set bits 1 and 2 of CONTROL to 0 keyboard, 1 Kempston, 2 cursor,
; 3 Interface II; if several are held the highest wins, since each is applied
; in turn. Key 5 toggles bit 3, directional control, once a press (KEY_LATCH).
; A change to CONTROL plays a short tune (TUNE_CONTROL_CHOSEN). Key 0 starts
; the game. Every pass counts the turn counter on and stirs the random number
; with R (NEXT_TURN), so the time spent on the menu decides where the knight
; starts (RANDOM_START_CELL).
;
; Alien 8's MENU, key 5 and all, but for the tune where Alien 8 beeps, the
; random number where Alien 8 counts a seed, and the clearing of the buffers.
MENU:
  XOR A                   ; no text printed yet: the first printing draws the
  LD (MENU_SHOWN),A       ; border
  LD HL,MENU_COLOURS      ; no line flashing: all eight colours in MENU_COLOURS
  LD B,$08                ;
MENU_0:
  RES 7,(HL)              ;
  INC HL                  ;
  DJNZ MENU_0             ;
  CALL CLEAR_BUFFER       ; a clear buffer; the menu and its border; the lines
  CALL DISPLAY_MENU       ; chosen
  CALL FLASH_MENU         ;
MENU_LOOP:
  CALL DISPLAY_MENU       ; the text again; the tune, once
  LD DE,TUNE_MENU         ;
  CALL PLAY_TUNE_ONCE     ;
  LD A,$F7                ; E = keys 1-5, key 1 in bit 0
  CALL READ_KEYS          ;
  LD E,A                  ; A = CONTROL, and as it was into LAST_CONTROL
  LD A,(CONTROL)          ;
  LD (LAST_CONTROL),A     ;
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
  LD HL,KEY_LATCH         ; key 5 not held: clear its latch (at the end)
  BIT 4,E                 ;
  JR Z,MENU_KEY5_RELEASED ;
  BIT 0,(HL)                 ; still held since the last pass: nothing
  JR NZ,MENU_TUNE_IF_CHANGED ;
  SET 0,(HL)              ; a new press: latch it, and toggle directional
  LD A,(CONTROL)          ; control
  XOR $08                 ;
  LD (CONTROL),A          ;
MENU_TUNE_IF_CHANGED:
  LD HL,LAST_CONTROL        ; A is the new CONTROL whichever way this is
  CP (HL)                   ; reached: the tune if it has changed
  LD DE,TUNE_CONTROL_CHOSEN ;
  CALL NZ,PLAY_TUNE         ;
  LD A,$EF                ; key 0 (bit 0 of the 6-0 half-row): start the game
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  RET NZ                  ;
  CALL NEXT_TURN          ; the turn counter on, and the random number stirred
  CALL FLASH_MENU         ; flash the choice; round again
  JP MENU_LOOP            ;
MENU_KEY5_RELEASED:
  RES 0,(HL)              ; key 5 is up: clear the latch
  JR MENU_TUNE_IF_CHANGED ;

; Flash the chosen lines on the menu
;
; Used by the routine at MENU.
;
; Sets the FLASH bit on the colour of the line for the method in bits 1-2 of
; CONTROL and clears it on the other three (TOGGLE_SELECTED), then sets or
; clears it on the next colour -- the directional-control line's -- to match
; bit 3 of CONTROL. The colours are MENU_COLOURS's, from the second; the
; title's is left alone. As Knight Lore's, Alien 8's and Pentagram's,
; instruction for instruction.
FLASH_MENU:
  LD HL,MENU_CONTROL_COLOURS ; the four method lines: flash the one for bits
  LD A,(CONTROL)             ; 1-2
  RRCA                       ;
  AND $03                    ;
  LD B,$04                   ;
  CALL TOGGLE_SELECTED       ;
  RES 7,(HL)              ; HL is now on the directional-control line's colour:
  LD A,(CONTROL)          ; flash it if bit 3 is set
  AND $08                 ;
  RET Z                   ;
  SET 7,(HL)              ;
  RET                     ;

; The menu: colours, places and text
;
; DISPLAY_MENU prints the menu's eight lines from three lists: an attribute
; each (bit 7, the flash, is set on the lines chosen, FLASH_MENU), where each
; goes on the screen, and the text.
;
; The positions are x and y in pixels, y counting up from the bottom of the
; screen, as CALC_VRAM_ADDR takes them. The layout is Alien 8's and
; Pentagram's: the title, the four control methods and directional control, the
; start line and the copyright line. The colours: bright magenta for the title,
; bright green for the methods, bright cyan for directional control, bright
; white for the last two.
MENU_COLOURS:
  DEFB $43                ; Line 0: magenta
MENU_CONTROL_COLOURS:
  DEFB $44                ; Line 1: green
  DEFB $44                ; Line 2: green
  DEFB $44                ; Line 3: green
  DEFB $44                ; Line 4: green
  DEFB $45                ; Line 5: cyan
  DEFB $47                ; Line 6: white
  DEFB $47                ; Line 7: white
MENU_PLACES:
  DEFB $58                ; Line 0: x 88, y 159
  DEFB $9F                ;
  DEFB $30                ; Line 1: x 48, y 143
  DEFB $8F                ;
  DEFB $30                ; Line 2: x 48, y 127
  DEFB $7F                ;
  DEFB $30                ; Line 3: x 48, y 111
  DEFB $6F                ;
  DEFB $30                ; Line 4: x 48, y 95
  DEFB $5F                ;
  DEFB $30                ; Line 5: x 48, y 79
  DEFB $4F                ;
  DEFB $30                ; Line 6: x 48, y 63
  DEFB $3F                ;
  DEFB $50                ; Line 7: x 80, y 31
  DEFB $1F                ;

; The menu's text
;
; ASCII from the font's first character (code $30), with bit 7 set on each
; string's last character. The copyright line reads on the screen as a
; copyright sign, 1985 and A.C.G. with full stops: the font draws a copyright
; sign for the semicolon's code and a full stop for the colon's (drawn from the
; font's bytes, FONT).
MENU_TEXT:
  DEFM "NIGHT SHAD",$C5   ; "NIGHT SHADE"
  DEFM "1 KEYBOAR",$C4    ; "1 KEYBOARD"
  DEFM "2 KEMPSTON JOYSTIC",$CB ; "2 KEMPSTON JOYSTICK"
  DEFM "3 CURSOR JOYSTIC",$CB ; "3 CURSOR JOYSTICK"
  DEFM "4 INTERFACE I",$C9 ; "4 INTERFACE II"
  DEFM "5 DIRECTIONAL CONTRO",$CC ; "5 DIRECTIONAL CONTROL"
  DEFM "0 START GAM",$C5  ; "0 START GAME"
  DEFM "; 1985 A:C:G",$BA ; "(c) 1985 A.C.G."

; Print a string in one colour
;
; Used by the routine at DISPLAY_MENU.
;
; Prints straight onto the screen in the font (FONT), colouring each
; character's cell as it goes (PRINT_CHAR_COLOURED). The rest is in PRINT_TEXT.
; The menu's lines are printed with it (DISPLAY_MENU). Unlike Alien 8's
; printer, which draws into its screen buffer, Nightshade's text goes straight
; to the display: the play area is the only part of the screen it buffers.
;
;   HL the position: L = x, H = y, in pixels, y counting up from the bottom of
;      the screen
;   DE the string, ASCII with bit 7 set on the last character
;   A' the colour
; O:DE the byte after the string
PRINT_TEXT_SINGLE_COLOUR:
  PUSH HL                 ; the text font: FONT_BASE 384 bytes below the font,
  LD HL,$6B5E             ; so that a letter's code lands on its character
  LD (FONT_BASE),HL       ;
  POP HL                  ;
  CALL CALC_VRAM_ADDR     ; HL = the screen address of the position
  JR PRINT_TEXT_CHAR      ; (CALC_VRAM_ADDR); print

; Print a string whose first byte is its colour
;
; Used by the routines at NEW_GAME and GAME_OVER.
;
; As PRINT_TEXT_SINGLE_COLOUR, but the colour is the string's own first byte.
; The panel's heading (SCORE_TEXT) and the four lines after a game (END_TEXT)
; are printed with it.
;
;   HL the position: L = x, H = y, in pixels, y counting up from the bottom
;   DE the colour byte, then the string, bit 7 set on its last character
; O:DE the byte after the string
PRINT_TEXT:
  PUSH HL                 ; the text font; HL = the screen address
  LD HL,$6B5E             ;
  LD (FONT_BASE),HL       ;
  POP HL                  ;
  CALL CALC_VRAM_ADDR     ;
  LD A,(DE)               ; the colour, from the string's first byte, into A'
  INC DE                  ;
  EX AF,AF'               ;
; This entry point is used by the routine at PRINT_TEXT_SINGLE_COLOUR.
PRINT_TEXT_CHAR:
  LD A,(DE)               ; bit 7 marks the last character
  INC DE                  ;
  BIT 7,A                 ;
  JR NZ,PRINT_TEXT_LAST   ;
  CALL PRINT_CHAR_COLOURED ; print it and colour its cell; one cell right
  INC L                    ;
  JR PRINT_TEXT_CHAR       ;
PRINT_TEXT_LAST:
  AND $7F                 ; the last character, without its end marker
  JP PRINT_CHAR_COLOURED  ;

; Flash one of B attributes, and steady the rest
;
; Used by the routine at FLASH_MENU.
;
; Sets bit 7, FLASH, on the A'th of B attribute bytes from HL and clears it on
; the others; HL comes back just past the last. FLASH_MENU marks the chosen
; control method with it. This entry deals with the first byte; the loop is
; FLASH_NEXT_ONE. Alien 8's and Pentagram's TOGGLE_SELECTED.
;
; HL the first attribute
; B how many
; A which one flashes, counting from 0
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
; Prints the menu's eight lines from the three lists at MENU_COLOURS -- a
; colour, a position and a string each -- and, the first time after MENU_SHOWN
; was cleared, draws the border round the screen (PRINT_BORDER). Called when
; the menu starts and on every pass of its loop (MENU); printing the same text
; over itself changes nothing but the attributes, which is how the flashing
; lines change. Alien 8's DISPLAY_MENU and its DISPLAY_TEXT_LIST in one, since
; Nightshade prints no other list.
DISPLAY_MENU:
  LD DE,MENU_COLOURS      ; DE' = the colours
  EXX                     ;
  LD HL,MENU_PLACES       ; HL = the positions, DE = the strings; eight lines
  LD DE,MENU_TEXT         ;
  LD B,$08                ;
DISPLAY_MENU_LINE:
  LD A,(HL)               ; L = x, H = y; HL moved on to the next pair and kept
  INC HL                  ;
  INC HL                  ;
  PUSH HL                 ;
  DEC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  EXX                     ; this line's colour into A', from DE'
  LD A,(DE)               ;
  INC DE                  ;
  EX AF,AF'               ;
  EXX                     ;
  CALL PRINT_TEXT_SINGLE_COLOUR ; print it, and loop
  POP HL                        ;
  DJNZ DISPLAY_MENU_LINE        ;
  LD A,(MENU_SHOWN)       ; the border has been drawn already
  AND A                   ;
  RET NZ                  ;
  INC A                   ; the first time: say so, and draw it
  LD (MENU_SHOWN),A       ;
  JP PRINT_BORDER         ;

; Draw the frame round the play area
;
; Used by the routine at NEW_GAME.
;
; Yellow on red, in the border's pieces (BORDER_CHARS) as FRAME_PIECES arranges
; them: corners two characters square at rows 0 and 16 and columns 5 and 29;
; eleven lengths of edge along the top and the bottom between them, from column
; 7; seven lengths of side down each side, from row 2. The play area is what it
; encloses, character rows 2-15 and columns 7-28. Called once a game, by
; NEW_GAME.
DRAW_PLAY_FRAME:
  LD A,$16                ; yellow on red; the border's pieces; the frame's
  EX AF,AF'               ; layout
  LD HL,BORDER_CHARS      ;
  LD (FONT_BASE),HL       ;
  LD DE,FRAME_PIECES      ;
  LD HL,$4005             ; the four corners, taking four codes each
  CALL PRINT_BLOCK        ;
  LD HL,$401D             ;
  CALL PRINT_BLOCK        ;
  LD HL,$5005             ;
  CALL PRINT_BLOCK        ;
  LD HL,$501D             ;
  CALL PRINT_BLOCK        ;
  LD HL,$4007             ; the top and the bottom, the same four codes for
  LD B,$0B                ; every length
  CALL PRINT_BLOCK_ROW    ;
  LD HL,$5007             ;
  LD B,$0B                ;
  CALL PRINT_BLOCK_ROW    ;
  INC DE                  ; past the edges' codes to the sides'
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  LD HL,$4045             ; the left and the right side
  LD B,$07                ;
  CALL PRINT_BLOCK_COLUMN ;
  LD HL,$405D             ;
  LD B,$07                ;
  JP PRINT_BLOCK_COLUMN   ;

; Draw the border round the screen
;
; Used by the routines at DISPLAY_MENU and GAME_OVER.
;
; Bright yellow on blue, in the same pieces and layout as the play area's frame
; (DRAW_PLAY_FRAME), but round the whole screen: corners at rows 0 and 22 and
; columns 0 and 30, fourteen lengths of edge along the top and the bottom from
; column 2, ten lengths of side down each side from row 2. Round the menu
; (DISPLAY_MENU) and the screen after a game (GAME_OVER).
PRINT_BORDER:
  LD A,$4E                ; bright yellow on blue; the border's pieces; the
  EX AF,AF'               ; layout
  LD HL,BORDER_CHARS      ;
  LD (FONT_BASE),HL       ;
  LD DE,FRAME_PIECES      ;
  LD HL,$4000             ; the four corners
  CALL PRINT_BLOCK        ;
  LD HL,$401E             ;
  CALL PRINT_BLOCK        ;
  LD HL,$50C0             ;
  CALL PRINT_BLOCK        ;
  LD HL,$50DE             ;
  CALL PRINT_BLOCK        ;
  LD HL,$4002             ; the top and the bottom
  LD B,$0E                ;
  CALL PRINT_BLOCK_ROW    ;
  LD HL,$50C2             ;
  LD B,$0E                ;
  CALL PRINT_BLOCK_ROW    ;
  INC DE                  ; past the edges' codes to the sides'
  INC DE                  ;
  INC DE                  ;
  INC DE                  ;
  LD HL,$4040             ; the left and the right side
  LD B,$0A                ;
  CALL PRINT_BLOCK_COLUMN ;
  LD HL,$405E             ;
  LD B,$0A                ;
  JP PRINT_BLOCK_COLUMN   ;

; The layout of the frames, in the border's characters
;
; Codes into the border's characters (BORDER_CHARS), four to a piece two
; characters square: the top row's left and right, then the bottom row's. Read
; in this order by DRAW_PLAY_FRAME and PRINT_BORDER, a piece at a time with
; PRINT_BLOCK.
FRAME_PIECES:
  DEFB $08,$09,$0A,$0B    ; The corners: top left, top right, bottom left,
  DEFB $09,$0C,$0D,$0E    ; bottom right
  DEFB $0A,$13,$12,$10    ;
  DEFB $0F,$0E,$10,$11    ;
  DEFB $04,$05,$06,$07    ; A length of the top or the bottom edge; a length of
  DEFB $00,$01,$02,$03    ; a side

; Print a piece several times along a row
;
; Used by the routines at DRAW_PLAY_FRAME and PRINT_BORDER.
;
; Each two characters to the right of the one before, with the same four codes.
;
;   HL the screen address of the first
;   DE its four codes
;   B how many
;   A' the colour
; O:HL two characters past the last
PRINT_BLOCK_ROW:
  PUSH BC                 ; a piece; two characters right; the same codes again
  PUSH DE                 ;
  CALL PRINT_BLOCK        ;
  INC L                   ;
  INC L                   ;
  POP DE                  ;
  POP BC                  ;
  DJNZ PRINT_BLOCK_ROW    ;
  RET                     ;

; Print a piece several times down a column
;
; Used by the routines at DRAW_PLAY_FRAME and PRINT_BORDER.
;
; Each two character rows below the one before, with the same four codes.
;
; HL the screen address of the first
; DE its four codes
; B how many
; A' the colour
PRINT_BLOCK_COLUMN:
  PUSH BC                 ; a piece; two rows down; the same codes again
  PUSH DE                 ;
  CALL PRINT_BLOCK        ;
  CALL NEXT_CHAR_ROW      ;
  CALL NEXT_CHAR_ROW      ;
  POP DE                  ;
  POP BC                  ;
  DJNZ PRINT_BLOCK_COLUMN ;
  RET                     ;

; Print a character on the screen
;
; Used by the routine at PRINT_CHAR_COLOURED.
;
; Copies the character's eight bytes, from FONT_BASE plus eight times the code,
; onto the eight pixel rows of the cell, and gives HL back as it was. A space
; is printed as code $3C, a blank character in the font; the icons come in at
; PRINT_CODE, where a code of $20 is a character like any other. Alien 8's
; PRINT_CHAR drew into a buffer and moved HL on; this one draws on the screen
; and does not.
;
; A the code
; HL the screen address of its top row
PRINT_CHAR:
  CP $20                  ; a space is $3C, blank in the font
  JR NZ,PRINT_CODE        ;
  LD A,$3C                ;
; This entry point is used by the routine at PICK_UP_THING.
PRINT_CODE:
  PUSH BC                 ; DE = FONT_BASE + 8 * the code
  PUSH DE                 ;
  PUSH HL                 ;
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD DE,(FONT_BASE)       ;
  ADD HL,DE               ;
  EX DE,HL                ;
  POP HL                  ; eight rows, each 256 bytes on in the screen's
  LD B,$08                ; layout
PRINT_CHAR_0:
  LD A,(DE)               ;
  INC DE                  ;
  LD (HL),A               ;
  INC H                   ;
  DJNZ PRINT_CHAR_0       ;
  POP DE                  ; back up to the top row
  POP BC                  ;
  LD A,H                  ;
  SUB $08                 ;
  LD H,A                  ;
  RET                     ;

; Print four characters as a piece two characters square
;
; Used by the routines at PRINT_COMPASS, DRAW_PLAY_FRAME, PRINT_BORDER,
; PRINT_BLOCK_ROW, PRINT_BLOCK_COLUMN and PRINT_LIFE_ICON.
;
; Each character is coloured as it is printed (PRINT_CHAR_COLOURED). HL comes
; back as it was. The frames are made of these (FRAME_PIECES), and so are the
; compass (PRINT_COMPASS) and the lives (PRINT_LIFE_ICON).
;
;   HL the screen address of the top-left
;   DE the four codes: top left, top right, bottom left, bottom right
;   A' the colour
; O:DE past the four codes
PRINT_BLOCK:
  PUSH HL                  ; the top row's two
  LD A,(DE)                ;
  INC DE                   ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  LD A,(DE)                ;
  INC DE                   ;
  CALL PRINT_CHAR_COLOURED ;
  DEC L                   ; back to the left, a character row down
  CALL NEXT_CHAR_ROW      ;
  LD A,(DE)                ; the bottom row's two
  INC DE                   ;
  CALL PRINT_CHAR_COLOURED ;
  INC L                    ;
  LD A,(DE)                ;
  INC DE                   ;
  CALL PRINT_CHAR_COLOURED ;
  POP HL                   ;
  RET                      ;

; Print a character and colour its cell
;
; Used by the routines at PRINT_HEADING, PRINT_BCD, DRAW_PANEL_FRAME,
; PRINT_TEXT and PRINT_BLOCK.
;
; Prints with PRINT_CHAR and writes A' into the cell's attribute byte, which is
; at the same column and row in the attribute file: the third of the screen
; (bits 3-4 of H) picks the attribute page, and L is the same in both. A' is
; kept for the next character.
;
; A the code
; HL the screen address of its top row
; A' the colour
PRINT_CHAR_COLOURED:
  CALL PRINT_CHAR         ; print it
  PUSH DE                 ; HL = the attribute address: page $58 plus the third
  PUSH HL                 ;
  LD A,H                  ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $03                 ;
  LD H,A                  ;
  LD DE,$5800             ;
  ADD HL,DE               ;
  EX AF,AF'               ; colour it, keeping the colour in A'
  LD (HL),A               ;
  EX AF,AF'               ;
  POP HL
  POP DE
  RET

; Move a screen address down a character row
;
; Used by the routines at PICK_UP_THING, DRAW_PANEL_FRAME, PRINT_BLOCK_COLUMN,
; PRINT_BLOCK and PRINT_LIFE_ICON.
;
; 32 on, and into the next third of the screen (8 pages on) when that carries
; out of L.
;
; HL the screen address
NEXT_CHAR_ROW:
  LD A,L
  ADD A,$20
  LD L,A
  RET NC
  LD A,H
  ADD A,$08
  LD H,A
  RET

; Choose the cell a new game starts in
;
; Used by the routine at NEW_GAME.
;
; Called by NEW_GAME at every new game. The random number, stirred (NEXT_TURN),
; gives a cell of the town map at random; if it is solid (types 1 and 2) the
; next cell in the map is tried, and the next, until one is not. Its column and
; row go into the start records (START_RECORDS), where NEW_LIFE takes them
; from; he starts in the middle of the cell. Only the cells a knight can stand
; in are chosen, but not all equally: a cell just after a run of solid ones in
; the map is chosen for the whole run as well as for itself.
RANDOM_START_CELL:
  CALL STIR_RANDOM        ; stir the random number with R
  LD DE,(RANDOM)          ; DE = a cell, 0-1023: the row in bits 5-9, the
RANDOM_START_CELL_0:
  LD A,D                  ; column in bits 0-4
  AND $03                 ;
  LD D,A                  ;
  LD HL,TOWN                ; is it solid, type 1 or 2?
  ADD HL,DE                 ;
  LD A,(HL)                 ;
  DEC A                     ;
  CP $02                    ;
  JR NC,RANDOM_START_CELL_1 ;
  INC DE                  ; then the next one
  JR RANDOM_START_CELL_0  ;
RANDOM_START_CELL_1:
  LD A,E                  ; the column
  AND $1F                 ;
  LD (START_U_CELL),A     ;
  RL E                    ; and the row, from bits 5-9
  RL D                    ;
  RL E                    ;
  RL D                    ;
  RL E                    ;
  RL D                    ;
  LD A,D                  ;
  AND $1F                 ;
  LD (START_V_CELL),A     ;
  RET

; Start a new life when the knight's record is empty
;
; Used by the routine at NEW_GAME.
;
; Called every turn by NEW_GAME; it does nothing until the knight's legs'
; record is empty, which happens when a life ends and his vanishing (graphic
; 12) has run its four turns.
;
; Then it checks its own code. The byte at TAKE_LIFE, the instruction that
; takes a life, must still be $35, DEC (HL); if it is anything else the game
; jumps to RESET (in STOCK_BUILDINGS), address 0, and the Spectrum starts again
; from its copyright message. So the obvious infinite-lives poke -- a NOP over
; that DEC -- resets the machine at the first death instead. It is the fourth
; of the game's protections, and the only one aimed at a player rather than a
; copier.
;
; With lives left it plays the new-life tune (TUNE_NEW_LIFE), copies the start
; records (START_RECORDS) over the knight's two records -- at a new game
; NEW_GAME comes in at FIRST_LIFE, without the tune -- sets him appearing
; (ARRIVING) with three hits, and takes a life: with none to take, the game is
; over (GAME_OVER). Otherwise the monsters are cleared away (CLEAR_MONSTERS),
; his cell is marked visited (VISIT_CELL), and the lives are drawn on the
; panel: five places at character row 18 from column 5, a bright white knight
; for each life left and a blue one for each lost.
NEW_LIFE:
  LD A,(KNIGHT)           ; his legs' record still in use: nothing to do
  AND A                   ;
  RET NZ                  ;
  LD A,(TAKE_LIFE)        ; the check: DEC (HL) at TAKE_LIFE, or reset the
  CP $35                  ; machine
  JP NZ,RESET             ;
  LD A,(LIVES)            ; a life to come: the new-life tune
  AND A                   ;
  JR Z,FIRST_LIFE         ;
  LD DE,TUNE_NEW_LIFE     ;
  CALL PLAY_TUNE          ;
; This entry point is used by the routine at NEW_GAME.
FIRST_LIFE:
  LD HL,START_RECORDS     ; the start records over the knight's legs and top
  LD DE,KNIGHT            ;
  LD BC,$0020             ;
  LDIR                    ;
  LD A,$28                ; appearing: ARRIVING counts up from here to $70,
  LD (ARRIVING),A         ; when he is there
  LD A,$03                ; three hits
  LD (HITS),A             ;
  LD HL,LIVES             ; the lives
TAKE_LIFE:
  DEC (HL)                ; take one (the instruction the check reads)
  JP M,GAME_OVER          ; none left: game over
  CALL CLEAR_MONSTERS     ; no monsters
  LD IX,KNIGHT            ; his cell visited, with IX on his record
  CALL ENTER_CELL         ;
  LD HL,LIFE_CHARS        ; the life picture's eight characters, 16 into
  LD (FONT_BASE),HL       ; PANEL_ICONS; bright white
  LD A,$47                ;
  EX AF,AF'               ;
  LD DE,LIFE_ICON_CODES   ; codes 0-7; row 18, column 5
  LD HL,$5045             ;
  LD A,(LIVES)            ; B = lives left, C = 5 - B lost
  LD B,A                  ;
  NEG                     ;
  ADD A,$05               ;
  LD C,A                  ;
NEW_LIFE_0:
  LD A,B                  ; B white knights, two columns apart
  AND A                   ;
  JR Z,NEW_LIFE_1         ;
  CALL PRINT_LIFE_ICON    ;
  INC L                   ;
  INC L                   ;
  DJNZ NEW_LIFE_0         ;
NEW_LIFE_1:
  LD A,$41                ; then blue
  EX AF,AF'               ;
  LD A,C                  ;
  AND A                   ;
  RET Z                   ;
  LD B,A                  ; for the C lost
NEW_LIFE_2:
  CALL PRINT_LIFE_ICON    ;
  INC L                   ;
  INC L                   ;
  DJNZ NEW_LIFE_2         ;
  RET                     ;
; LIVES counts the lives besides the one being played. A new game sets it to 6,
; from the opcode of the JR at LIVES_BYTE (in NEW_GAME), and the first life
; takes one, so the panel starts with five.

; Print a life's picture on the panel
;
; Used by the routine at NEW_LIFE.
;
; Two pieces two characters square (PRINT_BLOCK), one above the other: a knight
; two characters wide and four tall. HL and DE come back as they were.
;
; HL the screen address of its top-left
; DE its eight codes (LIFE_ICON_CODES)
; A' the colour
PRINT_LIFE_ICON:
  PUSH DE                 ; the top half; two rows down; the bottom half
  PUSH HL                 ;
  CALL PRINT_BLOCK        ;
  CALL NEXT_CHAR_ROW      ;
  CALL NEXT_CHAR_ROW      ;
  CALL PRINT_BLOCK        ;
  POP HL                  ;
  POP DE                  ;
  RET                     ;

; The codes of a life's picture
;
; The eight characters from the life picture in the panel's icons
; (PANEL_ICONS), in the order PRINT_LIFE_ICON prints them.
LIFE_ICON_CODES:
  DEFB $00,$01,$02,$03    ; The top half's four, then the bottom half's
  DEFB $04,$05,$06,$07    ;

; The knight's two records at a new life
;
; Copied over the first two object records by NEW_LIFE. The game writes his
; cell here: a random one at a new game (RANDOM_START_CELL), and the one he
; died in at a death (WANDERING_MONSTER).
;
; He starts in the middle of the cell, U and V's low bytes 128. At a new game
; NEW_GAME turns him to face $40 (START_FACING) and RANDOM_START_CELL writes a
; random cell; at a death WANDERING_MONSTER writes the cell he died in and the
; facing and flags he had, so the next life starts where the last ended. The
; top's position is left at 0 here and set by its own update.
START_RECORDS:
  DEFB $18                ; Legs+0 graphic: 24
START_U_LOW:
  DEFB $80                ; Legs+1 U, low byte: 128
START_U_CELL:
  DEFB $00                ; Legs+2 U, high byte (the cell): 0
START_V_LOW:
  DEFB $80                ; Legs+3 V, low byte: 128
START_V_CELL:
  DEFB $00                ; Legs+4 V, high byte (the cell): 0
  DEFB $00                ; Legs+5 speed: 0
START_FACING:
  DEFB $40                ; Legs+6 facing and turn count: 64
START_FLAGS:
  DEFB $00                ; Legs+7 flags: 0
  DEFB $10                ; Legs+8 half-size in U: 16
  DEFB $10                ; Legs+9 half-size in V: 16
  DEFB $00                ; Legs+A step in U: 0
  DEFB $00                ; Legs+B step in V: 0
  DEFB $F4                ; Legs+C drawing offset x: 244
  DEFB $02                ; Legs+D drawing offset y: 2
  DEFB $00                ; Legs+E screen x: 0
  DEFB $00                ; Legs+F screen y: 0
  DEFB $20                ; Top+0 graphic: 32
  DEFB $00                ; Top+1 U, low byte: 0
  DEFB $00                ; Top+2 U, high byte (the cell): 0
  DEFB $00                ; Top+3 V, low byte: 0
  DEFB $00                ; Top+4 V, high byte (the cell): 0
  DEFB $00                ; Top+5 speed: 0
  DEFB $00                ; Top+6 facing and turn count: 0
  DEFB $00                ; Top+7 flags: 0
  DEFB $10                ; Top+8 half-size in U: 16
  DEFB $10                ; Top+9 half-size in V: 16
  DEFB $00                ; Top+A step in U: 0
  DEFB $00                ; Top+B step in V: 0
  DEFB $F4                ; Top+C drawing offset x: 244
  DEFB $0D                ; Top+D drawing offset y: 13
  DEFB $00                ; Top+E screen x: 0
  DEFB $00                ; Top+F screen y: 0

; Game over: the percentage and the score, then the menu, or the ending if the
; villains are gone
;
; Used by the routines at NEW_LIFE and CHECK_QUEST_DONE.
;
; Reached when the last life is taken (NEW_LIFE) and when the fourth villain's
; sparkles have finished (CHECK_QUEST_DONE). Works out the percentage
; (PERCENTAGE), clears the screen, draws the border round it (PRINT_BORDER) and
; prints the four lines of END_TEXT, the percentage after the third and the
; score after the fourth, then plays the game-over tune and waits half a
; second.
;
; If any of the four villains is still alive (graphics 96-111) it is back to
; the menu, by way of NEW_GAME. If none is, the ending: every object record is
; emptied (CLEAR_OBJECTS), ten are filled from ENDING_RECORDS, the screen is
; cleared again, ENDING is set and the main loop is entered; with ENDING set
; the main loop only updates the records, and the ending's routines
; (ENDING_PIT_FRONT, ENDING_VILLAIN) do the rest.
GAME_OVER:
  CALL PERCENTAGE         ; the percentage
  CALL CLEAR_SCREEN       ; a clear screen, and the border round it
  CALL PRINT_BORDER       ;
  LD HL,$8758             ; the first line at (88, 135), in its own colour
  LD DE,END_TEXT          ;
  CALL PRINT_TEXT         ;
  LD HL,$6F38             ; the next three, each at its place, DE running on
  CALL PRINT_TEXT         ; through the text
  LD HL,$5F48             ;
  CALL PRINT_TEXT         ;
  LD HL,$4748             ;
  CALL PRINT_TEXT         ;
  LD HL,$4894             ; the percentage after COMPLETED, at row 12, column
  LD A,$45                ; 20, in cyan
  EX AF,AF'               ;
  CALL PRINT_PERCENTAGE   ;
  LD HL,$48F0             ; the score after SCORE, at row 15, column 16, in
  LD A,$46                ; yellow
  EX AF,AF'               ;
  CALL PRINT_SCORE_AT     ;
  LD DE,TUNE_GAME_OVER    ; the game-over tune
  CALL PLAY_TUNE          ;
  LD B,$04                ; a pause (the B it sets is not used)
  CALL GAME_OVER_PAUSE    ;
  LD HL,VILLAINS          ; a villain still alive (96-111): the menu and a new
  LD DE,$0010             ; game
  LD B,$04                ;
GAME_OVER_0:
  LD A,(HL)               ;
  SUB $60                 ;
  CP $10                  ;
  JP C,NEW_GAME           ;
  ADD HL,DE               ;
  DJNZ GAME_OVER_0        ;
  CALL CLEAR_OBJECTS      ; the ending: every record empty, then ten from the
  LD IX,KNIGHT            ; ending's list
  LD HL,ENDING_RECORDS    ;
  LD DE,$0010             ;
  LD B,$0A                ;
GAME_OVER_1:
  LD A,(HL)               ; the graphic, and the screen x and y in the step
  INC HL                  ; bytes
  LD (IX+$00),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$0A),A           ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (IX+$0B),A           ;
  XOR A                   ; no flags, no drawing offset
  LD (IX+$07),A           ;
  LD (IX+$0C),A           ;
  LD (IX+$0D),A           ;
  ADD IX,DE               ;
  DJNZ GAME_OVER_1        ;
  CALL CLEAR_SCREEN       ; a clear screen; ENDING set; a clear buffer
  LD A,$01                ;
  LD (ENDING),A           ;
  CALL CLEAR_BUFFER       ;
  JP MAIN_LOOP            ; and the main loop, which with ENDING set only
                          ; updates the records
; It is jumped to from inside routines the main loop calls, and ends by jumping
; to NEW_GAME or to MAIN_LOOP in it, which never set the stack pointer again
; (only START does): every game over leaves two bytes on the stack, and every
; ending four. Measured over four games and an ending, the stack pointer at the
; menu went down by exactly that each time. It would take about 150 games in
; one sitting for the stack to grow down through the rest of the BASIC program
; into the system variables and over NMIADD, the JP (HL) every update goes
; through.

; The ending's ten records
;
; A graphic and the screen x and y for each, copied into the object records by
; GAME_OVER when the four villains are gone.
;
; The x and y go into each record's step bytes (+A and +B), which the ending's
; routines use as a place in the play area, y counting up from its bottom.
; Records 0-4 are the back of a pit, five pictures side by side (graphics
; 153-157, drawn in white by ENDING_PIT_FRONT); records 5-8 are the four
; villains (graphics 144, 146, 148 and 150, the pictures of the villains of 96,
; 100, 104 and 108), waiting at the left and right edges (ENDING_VILLAIN);
; record 9 is the front of the pit (graphic 152), updated last and so drawn
; over whatever is sinking into it.
ENDING_RECORDS:
  DEFB $99                ; Record 0: graphic 153 at x 80, y 96
  DEFB $50                ;
  DEFB $60                ;
  DEFB $9A                ; Record 1: graphic 154 at x 96, y 96
  DEFB $60                ;
  DEFB $60                ;
  DEFB $9B                ; Record 2: graphic 155 at x 112, y 96
  DEFB $70                ;
  DEFB $60                ;
  DEFB $9C                ; Record 3: graphic 156 at x 128, y 96
  DEFB $80                ;
  DEFB $60                ;
  DEFB $9D                ; Record 4: graphic 157 at x 144, y 96
  DEFB $90                ;
  DEFB $60                ;
  DEFB $90                ; Record 5: graphic 144 at x 16, y 128
  DEFB $10                ;
  DEFB $80                ;
  DEFB $92                ; Record 6: graphic 146 at x 208, y 128
  DEFB $D0                ;
  DEFB $80                ;
  DEFB $94                ; Record 7: graphic 148 at x 16, y 128
  DEFB $10                ;
  DEFB $80                ;
  DEFB $96                ; Record 8: graphic 150 at x 208, y 128
  DEFB $D0                ;
  DEFB $80                ;
  DEFB $98                ; Record 9: graphic 152 at x 96, y 72
  DEFB $60                ;
  DEFB $48                ;

; Empty all 23 object records
;
; Used by the routine at GAME_OVER.
;
; Writes 0, the empty graphic, into the first byte of each; the rest of each
; record is left as it was. Before the ending (GAME_OVER).
CLEAR_OBJECTS:
  LD HL,KNIGHT            ; 23 records, 16 bytes apart
  LD DE,$0010             ;
  LD B,$17                ;
CLEAR_OBJECTS_0:
  LD (HL),$00             ;
  ADD HL,DE               ;
  DJNZ CLEAR_OBJECTS_0    ;
  RET                     ;

; The ending: the front of the pit (graphic 152), and the end of the ending
;
; The update routine for graphic 152 (UPDATES), in the ending's last record.
; While the record before it -- the last villain's -- is in use, the picture is
; drawn in white; when that empties, the last villain has sunk out of sight,
; and the tune for the end plays (TUNE_ENDING) and it is back to the menu by
; way of NEW_GAME.
;
; ENDING_PICTURE is the update routine for graphics 153-157, the back of the
; pit, drawn in white every turn. DRAW_ENDING_PICTURE draws any of the ending's
; pictures: the screen position from the step bytes, the sprite (DRAW_SPRITE),
; and a rectangle of attributes over it in the colour in ENDING_COLOUR
; (FILL_ATTR_RECT).
;
; IX the record (the tenth)
ENDING_PIT_FRONT:
  LD A,(IX-$10)           ; the last villain gone: the end
  AND A                   ;
  JR Z,ENDING_OVER        ;
ENDING_PICTURE:
  LD A,$47                ; white
  LD (ENDING_COLOUR),A    ;
; This entry point is used by the routine at ENDING_VILLAIN.
DRAW_ENDING_PICTURE:
  LD A,(IX+$0A)           ; where to draw it: the step bytes, which hold its
  LD (IX+$0E),A           ; place in the ending
  LD A,(IX+$0B)           ;
  LD (IX+$0F),A           ;
  CALL DRAW_SPRITE_AT     ; draw it
  LD L,(IX+$0E)           ; HL = its place in the attribute buffer
  LD H,(IX+$0F)           ; (ATTR_ADDRESS)
  CALL ATTR_ADDRESS       ;
  LD A,(SPRITE_ROWS)      ; C = the character rows it covers, from its height
  LD C,A                  ; and y
  LD A,(IX+$0B)           ;
  AND $07                 ;
  ADD A,C                 ;
  ADD A,$05               ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD C,A                  ;
  LD A,(SPRITE_WIDTH)     ; B = its width; colour them
  LD B,A                  ;
  LD A,(ENDING_COLOUR)    ;
  JP FILL_ATTR_RECT       ;
ENDING_OVER:
  LD DE,TUNE_ENDING       ; the tune for the end, and the menu
  CALL PLAY_TUNE          ;
  JP NEW_GAME             ;

; The ending: a villain carried over the pit and sunk into it (graphics
; 144-151)
;
; Each of the four waits, unseen, while the record before it holds a villain
; still on its way (144-151), so they go one at a time. Then it moves across,
; at most four a turn, to four to the right of the pit's front picture (record
; 9's x), and then sinks four a turn until its y is below 48, when it is gone
; and its record emptied. It swaps between its two frames every turn, and is
; drawn in its own colour -- red, magenta, green and cyan for the villains of
; 96, 100, 104 and 108 -- with a rising sound (ENDING_BEEP) all the while it
; moves.
;
; IX the record
ENDING_VILLAIN:
  LD A,(IX+$00)           ; the other of its two frames
  XOR $01                 ;
  LD (IX+$00),A           ;
  LD A,(IX-$10)           ; the one before still on its way: wait
  SUB $90                 ;
  CP $08                  ;
  RET C                   ;
  CALL ENDING_BEEP        ; the sound, a little higher each turn
  LD A,($BD28)            ; how far across from four right of the pit's front,
  ADD A,$04               ; at most four
  CALL STEP_TOWARDS_X     ;
  AND A                    ; not there yet: across
  JR Z,SINK_ENDING_VILLAIN ;
  ADD A,(IX+$0A)           ;
  LD (IX+$0A),A            ;
DRAW_ENDING_VILLAIN:
  LD A,(IX+$00)           ; its colour, $42 to $45 by bits 1-2 of the graphic,
  RRCA                    ; and draw it
  AND $03                 ;
  ADD A,$42               ;
  LD (ENDING_COLOUR),A    ;
  JP DRAW_ENDING_PICTURE  ;
SINK_ENDING_VILLAIN:
  LD A,(IX+$0B)             ; over the pit: down four, and drawn until y is
  SUB $04                   ; below 48
  LD (IX+$0B),A             ;
  CP $30                    ;
  JR NC,DRAW_ENDING_VILLAIN ;
  XOR A                   ; gone: the sound off, the record empty
  LD (EFFECT_TIME),A      ;
  LD (IX+$00),A           ;
  RET                     ;

; How far an ending picture should move across this turn
;
; Used by the routine at ENDING_VILLAIN.
;
;   A where it is going (x)
;   IX its record
; O:A the difference from its x, kept to -4..4
STEP_TOWARDS_X:
  SUB (IX+$0A)            ; at or to the right of it: 0-4
  JR C,STEP_TOWARDS_X_0   ;
  CP $04                  ;
  RET C                   ;
  LD A,$04                ;
  RET                     ;
STEP_TOWARDS_X_0:
  CP $FC                  ; to the left: -4 to -1
  RET NC                  ;
  LD A,$FC                ;
  RET                     ;

; The text after a game
;
; Each an attribute and then the text, printed in turn by GAME_OVER.
;
; The four lines' places are in GAME_OVER: GAME OVER at the top, the percentage
; line, then COMPLETED with the percentage after it, and SCORE with the score
; after it.
END_TEXT:
  DEFM $47                ; Attribute
  DEFM "GAME  OVE",$D2    ; "GAME  OVER"
  DEFB $45                ; Attribute
  DEFM "PERCENTAGE OF GAM",$C5 ; "PERCENTAGE OF GAME"
  DEFB $45                ; Attribute
  DEFM "COMPLETED ",$BD   ; "COMPLETED ="
  DEFB $46                ; Attribute
  DEFM "SCOR",$C5         ; "SCORE"

; Wait about half a second
;
; Used by the routine at GAME_OVER.
;
; Counts HL down through all its values, some sixty-five thousand passes of 26
; T-states. GAME_OVER sets B to 4 before calling, perhaps meaning four of
; these, but nothing here reads it.
GAME_OVER_PAUSE:
  LD HL,$0000
GAME_OVER_PAUSE_0:
  DEC HL
  LD A,H
  OR L
  JR NZ,GAME_OVER_PAUSE_0
  RET

; Bring a monster into a cell next to the knight's
;
; Used by the routine at NEW_GAME.
;
; Called by NEW_GAME every turn but during the ending. Once the knight has
; finished appearing, every fourth turn (bits 0-1 of TURNS both set), the first
; empty monster record (MONSTERS) gets MONSTER_RECORD, a monster appearing
; (graphic 128). Its cell is the knight's or one of the eight round it, a
; column and a row each chosen from a third of the random number's range. It
; goes at a random place in that cell, at least 32 from each edge; one that
; appears in the first half of every 256 turns gets bit 5 of its flags, which
; makes a monster of 112-127 turn towards the knight when it chooses a way to
; go (STEER). After four turns APPEARING_UPDATE makes it a monster of 64-79 or
; 112-127.
;
; If the cell chosen is solid (types 1 and 2) the routine returns there -- but
; the record has already been filled, so it keeps its monster, in the corner of
; the town, cell 0,0, which is solid. Measured: a spawn with the knight's cell
; set to the corner, where every cell round it is solid, left graphic 128 at U
; 0 and V 0. Away from the corner it does no harm: after its four turns of
; appearing its own update finds it more than two cells from the knight and
; empties the record (WANDERING_MONSTER, MONSTER112_UPDATE), so it only keeps
; the record from a real monster for those turns. Near the top-left corner it
; lives: with the knight in cell 1,1 the strays walk off the map to column or
; row 255, which the byte subtraction of the nearness test counts as close, and
; for 1463 of 1500 turns three or four of the six monster records held them
; (measured for the bugs page). Only types 1 and 2 are refused, so a monster is
; often put inside a building's cell, where it is never drawn and walks on the
; spot; with the knight standing still the six records fill with these and no
; new monster appears (measured for the animations page).
SPAWN_MONSTER:
  LD A,(ARRIVING)         ; the knight still appearing: none
  CP $70                  ;
  RET NZ                  ;
  LD A,(TURNS)            ; only when bits 0-1 of TURNS are both set
  CPL                     ;
  AND $03                 ;
  RET NZ                  ;
  LD IY,MONSTERS          ; the first empty monster record; none, none
  LD DE,$0010             ;
  LD B,$06                ;
SPAWN_MONSTER_0:
  LD A,(IY+$00)           ;
  AND A                   ;
  JR Z,SPAWN_MONSTER_1    ;
  ADD IY,DE               ;
  DJNZ SPAWN_MONSTER_0    ;
  RET                     ;
SPAWN_MONSTER_1:
  LD HL,MONSTER_RECORD    ; a monster appearing, in it
  PUSH IY                 ;
  POP DE                  ;
  LD BC,$0010             ;
  LDIR                    ;
  LD A,(KNIGHT_COLUMN)    ; HL = the knight's column and row
  LD L,A                  ;
  LD A,(KNIGHT_ROW)       ;
  LD H,A                  ;
  LD A,(RANDOM)           ; the random number's low byte: below $55 the same
  CP $55                  ; column, below $AA the next, else the one before
  JR C,SPAWN_MONSTER_3    ;
  CP $AA                  ;
  JR C,SPAWN_MONSTER_2    ;
  DEC L                   ;
  DEC L                   ;
SPAWN_MONSTER_2:
  INC L                   ;
SPAWN_MONSTER_3:
  LD A,($BBAB)            ; its high byte chooses the row the same way
  CP $55                  ;
  JR C,SPAWN_MONSTER_5    ;
  CP $AA                  ;
  JR C,SPAWN_MONSTER_4    ;
  DEC H                   ;
  DEC H                   ;
SPAWN_MONSTER_4:
  INC H                   ;
SPAWN_MONSTER_5:
  LD A,L                  ; in the town, 0-31
  AND $1F                 ;
  LD L,A                  ;
  LD A,H                  ;
  AND $1F                 ;
  LD H,A                  ;
  PUSH HL                 ; a solid cell: leave it (the record keeps its
  CALL TOWN_CELL          ; monster, at the corner)
  POP HL                  ;
  DEC A                   ;
  CP $02                  ;
  RET C                   ;
  LD (IY+$02),L           ; its cell
  LD (IY+$04),H           ;
  CALL STIR_RANDOM        ; stir the random number
  LD A,(RANDOM)           ; U within the cell: 32-223
  CP $C0                  ;
  JR C,SPAWN_MONSTER_6    ;
  SUB $40                 ;
SPAWN_MONSTER_6:
  ADD A,$20               ;
  LD (IY+$01),A           ;
  LD A,($BBAB)            ; V the same, from the high byte
  CP $C0                  ;
  JR C,SPAWN_MONSTER_7    ;
  SUB $40                 ;
SPAWN_MONSTER_7:
  ADD A,$20               ;
  LD (IY+$03),A           ;
  LD A,(TURNS)            ; born in the first half of 256 turns: bit 5, heading
  CP $80                  ; for the knight
  RET NC                  ;
  SET 5,(IY+$07)          ;
  RET                     ;

; What a monster starts as
;
; Copied into a free monster record by SPAWN_MONSTER, which writes the cell and
; the place in it: graphic 128, a monster appearing, speed 6, 16 by 16 units.
MONSTER_RECORD:
  DEFB $80                ; Monster+0 graphic: 128
  DEFB $00                ; Monster+1 U, low byte: 0
  DEFB $00                ; Monster+2 U, high byte (the cell): 0
  DEFB $00                ; Monster+3 V, low byte: 0
  DEFB $00                ; Monster+4 V, high byte (the cell): 0
  DEFB $06                ; Monster+5 speed: 6
  DEFB $00                ; Monster+6 facing and turn count: 0
  DEFB $00                ; Monster+7 flags: 0
  DEFB $10                ; Monster+8 half-size in U: 16
  DEFB $10                ; Monster+9 half-size in V: 16
  DEFB $00                ; Monster+A step in U: 0
  DEFB $00                ; Monster+B step in V: 0
  DEFB $F4                ; Monster+C drawing offset x: 244
  DEFB $04                ; Monster+D drawing offset y: 4
  DEFB $00                ; Monster+E screen x: 0
  DEFB $00                ; Monster+F screen y: 0

; The monsters of graphics 64-79: wander, and hurt the knight
;
; The update routine for graphics 64-79 (UPDATES): four kinds of four frames,
; the kind chosen when it appears by the villain nearest to it
; (APPEARING_UPDATE). It wanders: a new random step at random times
; (WANDER_STEP, each way up to 14 a turn), turned to face its step and tested
; against the walls (MOVE_SPLIT), moved (APPLY_STEP), and its frame stepped on
; (NEXT_FRAME_MOD4); drawn mirrored when the town is turned round. More than
; two cells from the knight either way, it is gone.
;
; An antibody that touches it (ANTIBODY_STRIKE) vanishes with it, and 5 goes on
; the score. If it touches the knight (TOUCHING_KNIGHT, not while he is
; appearing) the score gets 5 as well and the monster vanishes, but it takes
; one of his hits; at the last, his life ends. Monsters of 112-127
; (MONSTER112_UPDATE) and the creature of 136-139 (CREATURE_UPDATE) come in at
; MONSTER_HITS_KNIGHT, and a villain (VILLAIN_WANDER) at KNIGHT_KILLED,
; whatever his hits.
;
; IX the record
WANDERING_MONSTER:
  LD B,$07                ; a new step now and then, up to 14 each way
  CALL WANDER_STEP        ;
  CALL MOVE_SPLIT         ; face it, against the walls; move; the next frame
  CALL APPLY_STEP         ;
  CALL NEXT_FRAME_MOD4    ;
  LD A,(VIEW)             ; bit 6 of its flags, drawn mirrored, set when the
  RRCA                    ; town is turned round
  RRCA                    ;
  AND $40                 ;
  LD C,A                  ;
  LD A,(IX+$07)           ;
  AND $BF                 ;
  OR C                    ;
  LD (IX+$07),A           ;
  LD C,$03                   ; more than two cells from the knight: gone
  CALL NEAR_KNIGHT           ;
  JR NC,MONSTER_OUT_OF_RANGE ;
  CALL ANTIBODY_STRIKE    ; struck by an antibody
  JR C,MONSTER_SHOT       ;
  CALL TOUCHING_KNIGHT    ; not touching the knight
  RET NC                  ;
  CALL MONSTER_SCORE      ; touching him: 5 on the score, and...
; This entry point is used by the routines at CREATURE_UPDATE and
; MONSTER112_UPDATE.
MONSTER_HITS_KNIGHT:
  LD (IX+$00),$0C         ; ...it vanishes, and he loses a hit; with some left,
  LD HL,HITS              ; that is all
  DEC (HL)                ;
  RET NZ                  ;
; This entry point is used by the routine at VILLAIN_WANDER.
KNIGHT_KILLED:
  LD A,(KNIGHT_COLUMN)    ; his life ends: his cell, facing and flags into the
  LD (START_U_CELL),A     ; start records, so the next life starts here
  LD A,(KNIGHT_ROW)       ;
  LD (START_V_CELL),A     ;
  LD A,(KNIGHT_FACING)    ;
  LD (START_FACING),A     ;
  LD A,(KNIGHT_FLAGS)     ;
  LD (START_FLAGS),A      ;
  LD A,$0C                ; both his records vanish; NEW_LIFE starts the next
  LD (KNIGHT),A           ; life when that has run
  LD (KNIGHT_TOP),A       ;
  RET                     ;
MONSTER_SHOT:
  LD (IY+$00),$0C         ; the antibody and the monster both vanish
  LD (IX+$00),$0C         ;
MONSTER_SCORE:
  LD BC,$0005             ; 5 on the score
  JP ADD_SCORE            ;
MONSTER_OUT_OF_RANGE:
  LD (IX+$00),$00         ; the record empty
  RET                     ;
; The score's digits end in two that nothing adds to (the byte after SCORE_LOW,
; cleared at each game and printed with the rest by ADD_SCORE), so 5 shows as
; 500.

; Step an object through four frames
;
; Used by the routines at CREATURE_UPDATE, WANDERING_MONSTER, SPARKLE_FLY,
; ANTIBODY_FLIGHT and FIND_WANDER.
;
; Counts bits 0-1 of the graphic round 0-3, leaving the rest: the four frames
; of a monster's or the creature's walk (WANDERING_MONSTER, CREATURE_UPDATE),
; the sparkles (SPARKLE_FLY) and others. Knight Lore's next_graphic_no_mod_4
; and Alien 8's NEXT_FRAME_MOD4 do the same.
;
; IX the record
NEXT_FRAME_MOD4:
  LD A,(IX+$00)
  LD C,A
  INC A
  AND $03
  LD B,A
  LD A,C
  AND $FC
  OR B
  LD (IX+$00),A
  RET

; Draw the cells round the knight, back to front
;
; Used by the routine at NEW_GAME.
;
; Called every turn by NEW_GAME. The view shows the knight's cell and the eight
; round it; they are drawn back to front, the back ones in an order that
; depends on which of them are built on. Everything here is in the view's
; coordinates: with the town turned round (VIEW) his cell is turned round first
; (TURN_CELL), and the map is read through the view (LOOK_UP_CELL), so U-1 is
; always further back.
;
; Five cells lie behind or beside his: U-1 V+1, U-1, V+1, U-1 V-1 and U+1 V+1.
; A bit for each that is not open ground, bits 0 to 4 in that order, picks one
; of 32 records of five steps in DRAW_ORDER. Each step byte gives a cell as an
; offset from his -- bits 4-5 for U, bits 6-7 for V: bit 5 (or 7) the same, bit
; 4 (or 6) one more, neither one less -- and in bits 0-1 what to draw there: 0
; the things in it (LIST_THINGS_IN_CELL, SORT_AND_DRAW_THINGS), 1 its walls
; (DRAW_WALLS), 2 its walls by DRAW_OUTLINE, 3 nothing.
;
; Every record gives the five cells, each with action 1 if it is built on and 0
; if not: actions 2 and 3 are in no record, and their instructions never ran.
; Last come his own cell and the three in front of it, V-1, U+1 and U+1 V-1,
; each with its walls by DRAW_OUTLINE -- the routine action 2 would have used
; -- and then the things in it.
DRAW_CELLS:
  LD HL,$E001             ; no columns drawn yet this turn (DRAW_WALL_COLUMN)
  LD (COLUMNS_DRAWN),HL   ;
  LD A,(KNIGHT_COLUMN)    ; HL = his cell, as the view sees it
  LD L,A                  ;
  LD A,(KNIGHT_ROW)       ;
  LD H,A                  ;
  CALL TURN_CELL          ;
  PUSH HL                 ; kept, for every step
  LD E,$00                ; bit 0: U-1 V+1 not open
  DEC L                   ;
  INC H                   ;
  CALL LOOK_UP_CELL       ;
  JR Z,DRAW_CELLS_0       ;
  SET 0,E                 ;
DRAW_CELLS_0:
  POP HL                  ; bit 1: U-1
  PUSH HL                 ;
  DEC L                   ;
  CALL LOOK_UP_CELL       ;
  JR Z,DRAW_CELLS_1       ;
  SET 1,E                 ;
DRAW_CELLS_1:
  POP HL                  ; bit 2: V+1
  PUSH HL                 ;
  INC H                   ;
  CALL LOOK_UP_CELL       ;
  JR Z,DRAW_CELLS_2       ;
  SET 2,E                 ;
DRAW_CELLS_2:
  POP HL                  ; bit 3: U-1 V-1
  PUSH HL                 ;
  DEC L                   ;
  DEC H                   ;
  CALL LOOK_UP_CELL       ;
  JR Z,DRAW_CELLS_3       ;
  SET 3,E                 ;
DRAW_CELLS_3:
  POP HL                  ; bit 4: U+1 V+1
  PUSH HL                 ;
  INC L                   ;
  INC H                   ;
  CALL LOOK_UP_CELL       ;
  JR Z,DRAW_CELLS_4       ;
  SET 4,E                 ;
DRAW_CELLS_4:
  LD D,$00                ; DE = the drawing order's record for them, five
  LD A,E                  ; bytes each; five steps
  EX DE,HL                ;
  LD E,L                  ;
  LD D,H                  ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,DE               ;
  LD DE,DRAW_ORDER        ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD B,$05                ;
DRAW_STEP:
  POP HL                  ; his cell again; the step's byte
  PUSH HL                 ;
  LD A,(DE)               ;
  INC DE                  ;
  BIT 5,A                 ; U: bit 5 the same, bit 4 one more, neither one less
  JR NZ,DRAW_CELLS_6      ;
  BIT 4,A                 ;
  JR Z,DRAW_CELLS_5       ;
  INC L                   ;
  INC L                   ;
DRAW_CELLS_5:
  DEC L                   ;
DRAW_CELLS_6:
  BIT 7,A                 ; V: bit 7 the same, bit 6 one more, neither one less
  JR NZ,DRAW_CELLS_8      ;
  BIT 6,A                 ;
  JR Z,DRAW_CELLS_7       ;
  INC H                   ;
  INC H                   ;
DRAW_CELLS_7:
  DEC H                   ;
DRAW_CELLS_8:
  AND $03                 ; the action; the count and the record kept, and
  PUSH BC                 ; DRAW_STEP_DONE to return to
  PUSH DE                 ;
  LD DE,DRAW_STEP_DONE    ;
  PUSH DE                 ;
  JP Z,DRAW_CELL_THINGS   ; 0: the things in it
  DEC A                   ; 1: its walls
  JP Z,DRAW_WALLS         ;
  DEC A                   ; 2: its outline on the ground by DRAW_OUTLINE (no
  JP Z,DRAW_OUTLINE       ; record has it; never ran)
  POP DE                  ; 3: nothing -- the return address dropped (never ran
                          ; either)
DRAW_STEP_DONE:
  POP DE                  ; the next step
  POP BC                  ;
  DJNZ DRAW_STEP          ;
  POP HL                  ; his own cell
  PUSH HL                 ;
  CALL DRAW_FRONT_CELL    ;
  POP HL                  ; V-1
  PUSH HL                 ;
  DEC H                   ;
  CALL DRAW_FRONT_CELL    ;
  POP HL                  ; U+1
  PUSH HL                 ;
  INC L                   ;
  CALL DRAW_FRONT_CELL    ;
  POP HL                  ; U+1 V-1, whose RET ends the routine
  INC L                   ;
  DEC H                   ;
DRAW_FRONT_CELL:
  PUSH HL                 ; a front cell: its walls by DRAW_OUTLINE, if it is
  CALL DRAW_OUTLINE       ; built on...
  POP HL                  ;
DRAW_CELL_THINGS:
  CALL LIST_THINGS_IN_CELL ; ...then the things in it: listed
  JR SORT_AND_DRAW_THINGS  ; (LIST_THINGS_IN_CELL), and drawn in depth order
                           ; (SORT_AND_DRAW_THINGS)

; List the things in a cell
;
; Used by the routine at DRAW_CELLS.
;
; The first half of drawing the things in one cell of the town (the drawing
; order at DRAW_CELLS calls it for every cell whose things are drawn, and
; SORT_AND_DRAW_THINGS follows it). Every object record from KNIGHT to the end
; of the records whose graphic is not 0 and whose column and row -- the high
; bytes of U and V, +2 and +4 -- are this cell's has its address put on
; DRAW_LIST, which a zero word then ends.
;
; The cell comes in the drawing order's terms, which are turned round with the
; town (TURN_CELL), and the records keep the town's own; TURN_CELL is its own
; inverse, so it turns the cell back. Nothing counts the entries: the list has
; room for fifteen, and the most measured in the simulator, at 1748 stops here
; over thirty random cells of play, was four.
;
; HL the cell as the drawing order sees it: L the column, H the row
LIST_THINGS_IN_CELL:
  LD IY,DRAW_LIST         ; IY at the start of the list, IX at the first record
  LD IX,KNIGHT            ;
  CALL TURN_CELL          ; The cell in the town's own terms, into DE: E the
  EX DE,HL                ; column, D the row
LIST_THINGS_IN_CELL_0:
  LD A,(IX+$00)              ; An empty record is not drawn
  AND A                      ;
  JR Z,LIST_THINGS_IN_CELL_1 ;
  LD A,E                      ; Is the record in this cell: its U's high byte
  CP (IX+$02)                 ; this column, its V's this row?
  JR NZ,LIST_THINGS_IN_CELL_1 ;
  LD A,D                      ;
  CP (IX+$04)                 ;
  JR NZ,LIST_THINGS_IN_CELL_1 ;
  PUSH IX                 ; It is: its address onto the list
  POP HL                  ;
  LD (IY+$00),L           ;
  LD (IY+$01),H           ;
  INC IY                  ;
  INC IY                  ;
LIST_THINGS_IN_CELL_1:
  LD BC,$0010                ; The next record, until the end of the records at
  ADD IX,BC                  ; START
  PUSH IX                    ;
  POP HL                     ;
  LD BC,START                ;
  AND A                      ;
  SBC HL,BC                  ;
  JR C,LIST_THINGS_IN_CELL_0 ;
  XOR A                   ; A zero word ends the list
  LD (IY+$00),A           ;
  LD (IY+$01),A           ;
  RET                     ;

; Draw the listed things, furthest back first
;
; Used by the routine at DRAW_CELLS.
;
; The second half: the things LIST_THINGS_IN_CELL listed are drawn one at a
; time, each chosen by a pass along the list. The first entry not yet drawn is
; the candidate (IX). Every later entry not yet drawn (IY) is compared with it,
; and the outcome goes through DEPTH_TABLE: either the candidate stays, or IY
; is further back and becomes the candidate, and the pass carries on from IY.
; At the end of the list the candidate is drawn (DRAW_SPRITE) and its entry
; marked drawn by clearing bit 7 of its high byte -- every record's address has
; it set -- and the next pass starts; DRAW_LIST_AT keeps the place just past
; the candidate's entry, DRAW_LIST_NEXT just past IY's. The list is empty of
; undrawn things when a pass finds none, and the routine returns.
;
; The comparison is two-dimensional: a record is a box in U and V (its position
; at +1 and +3, its half-sizes at +8 and +9) and nothing in the town has a
; height. On each axis each side of the box is worked out as (the low byte of
; the position plus or minus the half-size) / 2 + 64 -- only the low bytes,
; since the things listed share a cell, and RRA shifting the carry of the 9-bit
; sum back in, so a side from 128 below the cell to 128 past it becomes a byte
; from 0 to 255. Then 0 if the candidate is wholly beyond IY on that axis (its
; low side at or above IY's high side), 2 if IY is wholly beyond the candidate,
; 1 if they overlap: U counts once, V three times, and the town turned round
; adds 9, which reverses what "further back" means. Further back is smaller U
; and larger V, as in Knight Lore and Alien 8: higher up the screen
; (PROJECT_CELL).
;
; A new candidate is not compared with the entries the pass has already gone
; by, so an order among three things can come out wrong; but a pass never goes
; back to the top, so it cannot go round in a circle, and Filmation's chain of
; candidates is not needed.
SORT_AND_DRAW_THINGS:
  LD HL,DRAW_LIST         ; From the top of the list
SORT_AND_DRAW_THINGS_0:
  LD E,(HL)               ; The next entry; the zero at the end: everything is
  INC HL                  ; drawn
  LD D,(HL)               ;
  INC HL                  ;
  LD A,D                  ;
  OR E                    ;
  RET Z                   ;
  BIT 7,D                     ; Bit 7 of the high byte clear: drawn already
  JR Z,SORT_AND_DRAW_THINGS_0 ;
  LD (DRAW_LIST_AT),HL    ; The first thing not yet drawn is the candidate, in
  PUSH DE                 ; IX
  POP IX                  ;
SORT_AND_DRAW_THINGS_1:
  LD E,(HL)                   ; The next entry; at the end of the list, draw
  INC HL                      ; the candidate
  LD D,(HL)                   ;
  INC HL                      ;
  LD A,D                      ;
  OR E                        ;
  JP Z,SORT_AND_DRAW_THINGS_7 ;
  BIT 7,D                     ; Drawn already: pass it by
  JR Z,SORT_AND_DRAW_THINGS_1 ;
  LD (DRAW_LIST_NEXT),HL  ; IY the thing to compare with the candidate
  PUSH DE                 ;
  POP IY                  ;
  LD C,$00                     ; U: 0 if the candidate's low side is at or
  LD A,(IY+$01)                ; above IY's high side
  ADD A,(IY+$08)               ;
  RRA                          ;
  ADD A,$40                    ;
  LD B,A                       ;
  LD A,(IX+$01)                ;
  SUB (IX+$08)                 ;
  RRA                          ;
  ADD A,$40                    ;
  SUB B                        ;
  JR NC,SORT_AND_DRAW_THINGS_3 ;
  LD A,(IX+$01)               ; Otherwise 2 if IY's low side is at or above the
  ADD A,(IX+$08)              ; candidate's high side, and 1 if they overlap
  RRA                         ;
  ADD A,$40                   ;
  LD B,A                      ;
  LD A,(IY+$01)               ;
  SUB (IY+$08)                ;
  RRA                         ;
  ADD A,$40                   ;
  SUB B                       ;
  JR C,SORT_AND_DRAW_THINGS_2 ;
  INC C                       ;
SORT_AND_DRAW_THINGS_2:
  INC C                       ;
SORT_AND_DRAW_THINGS_3:
  LD A,(IY+$03)                ; V the same, adding 0...
  ADD A,(IY+$09)               ;
  RRA                          ;
  ADD A,$40                    ;
  LD B,A                       ;
  LD A,(IX+$03)                ;
  SUB (IX+$09)                 ;
  RRA                          ;
  ADD A,$40                    ;
  SUB B                        ;
  LD A,C                       ;
  JR NC,SORT_AND_DRAW_THINGS_5 ;
  LD A,(IX+$03)               ; ...3 if they overlap, or 6 if IY is wholly
  ADD A,(IX+$09)              ; beyond
  RRA                         ;
  ADD A,$40                   ;
  LD B,A                      ;
  LD A,(IY+$03)               ;
  SUB (IY+$09)                ;
  RRA                         ;
  ADD A,$40                   ;
  SUB B                       ;
  LD A,C                      ;
  JR C,SORT_AND_DRAW_THINGS_4 ;
  ADD A,$03                   ;
SORT_AND_DRAW_THINGS_4:
  ADD A,$03                   ;
SORT_AND_DRAW_THINGS_5:
  LD C,A                      ; Plus 9 with the town turned round
  LD A,(VIEW)                 ;
  AND $01                     ;
  JR Z,SORT_AND_DRAW_THINGS_6 ;
  LD A,C                      ;
  ADD A,$09                   ;
  LD C,A                      ;
SORT_AND_DRAW_THINGS_6:
  LD A,C                  ; The outcome, through DEPTH_TABLE: the candidate
  LD BC,DEPTH_TABLE       ; stays, or IY takes its place
  CALL DISPATCH           ;
  LD HL,(DRAW_LIST_NEXT)    ; On along the list from IY
  JP SORT_AND_DRAW_THINGS_1 ;
SORT_AND_DRAW_THINGS_7:
  LD HL,(DRAW_LIST_AT)    ; The end of the list: the candidate's entry marked
  DEC HL                  ; drawn
  RES 7,(HL)              ;
  CALL DRAW_SPRITE        ; Draw it, and the next pass
  JP SORT_AND_DRAW_THINGS ;

; Routines for the depth sort's outcomes
;
; Indexed by SORT_AND_DRAW_THINGS's comparison of the candidate with another
; thing: the U outcome (0 the candidate wholly at larger U, 1 overlapping, 2
; wholly at smaller U), plus three times the V outcome (0 the candidate at
; larger V, 1 overlapping, 2 at smaller V), plus 9 with the town turned round.
; In the usual view smaller U and larger V are further back; turned round,
; larger U and smaller V. DEPTH_KEEP keeps the candidate, DEPTH_SWAP makes the
; other thing the candidate, and DEPTH_BY_CORNERS settles boxes that overlap on
; both axes. Where each box is further back along one axis and nearer along the
; other (0, 8, 9 and 17), the order does not matter, and the candidate stays.
DEPTH_TABLE:
  DEFW DEPTH_KEEP         ; 0: the candidate at larger U and larger V -- no
                          ; order: it stays
  DEFW DEPTH_KEEP         ; 1: the same U, the candidate at larger V, so
                          ; further back: it stays
  DEFW DEPTH_KEEP         ; 2: the candidate at smaller U and larger V, further
                          ; back on both: it stays
  DEFW DEPTH_SWAP         ; 3: the candidate at larger U, the same V: the other
                          ; is further back
  DEFW DEPTH_BY_CORNERS   ; 4: overlapping on both axes: by their nearest
                          ; corners
  DEFW DEPTH_KEEP         ; 5: the candidate at smaller U, the same V: it stays
  DEFW DEPTH_SWAP         ; 6: the candidate at larger U and smaller V: the
                          ; other is further back on both
  DEFW DEPTH_SWAP         ; 7: the same U, the candidate at smaller V: the
                          ; other is further back
  DEFW DEPTH_KEEP         ; 8: the candidate at smaller U and smaller V -- no
                          ; order: it stays
  DEFW DEPTH_KEEP         ; 9: turned round, the candidate at larger U and
                          ; larger V -- no order: it stays
  DEFW DEPTH_SWAP         ; 10: turned round, the same U, the candidate at
                          ; larger V: the other is further back
  DEFW DEPTH_SWAP         ; 11: turned round, the candidate at smaller U and
                          ; larger V: the other is further back on both
  DEFW DEPTH_KEEP         ; 12: turned round, the candidate at larger U, the
                          ; same V: it stays
  DEFW DEPTH_BY_CORNERS   ; 13: turned round, overlapping on both axes: by
                          ; their nearest corners
  DEFW DEPTH_SWAP         ; 14: turned round, the candidate at smaller U, the
                          ; same V: the other is further back
  DEFW DEPTH_KEEP         ; 15: turned round, the candidate at larger U and
                          ; smaller V, further back on both: it stays
  DEFW DEPTH_KEEP         ; 16: turned round, the same U, the candidate at
                          ; smaller V: it stays
  DEFW DEPTH_KEEP         ; 17: turned round, the candidate at smaller U and
                          ; smaller V -- no order: it stays

; The candidate stays
;
; Reached through DEPTH_TABLE when the candidate is further back than the thing
; it was compared with, or when neither has to go first: on to the next entry.
DEPTH_KEEP:
  RET

; The other thing becomes the candidate
;
; Used by the routine at DEPTH_BY_CORNERS.
;
; Reached through DEPTH_TABLE, and from DEPTH_BY_CORNERS, when the thing
; compared (IY) is further back than the candidate: it becomes the candidate,
; and DRAW_LIST_AT moves to just past its entry, which is the one
; SORT_AND_DRAW_THINGS will mark drawn.
;
; IY the thing further back
DEPTH_SWAP:
  LD HL,(DRAW_LIST_NEXT)  ; DRAW_LIST_AT = DRAW_LIST_NEXT; IX = IY
  LD (DRAW_LIST_AT),HL    ;
  PUSH IY                 ;
  POP IX                  ;
  RET                     ;

; Order two things whose boxes overlap on both axes
;
; Index 4 (13 turned round) of DEPTH_TABLE. With the boxes overlapping in U and
; in V, neither is simply behind the other, so each is placed by its nearest
; corner -- in the usual view the corner at the high side of U and the low side
; of V -- and how far back that corner is, which is how high up the screen it
; is: V less U. The candidate stays if its nearest corner is as far back as the
; other's, or further; otherwise the other becomes the candidate (DEPTH_SWAP).
; Turned round, the nearest corner is at the low side of U and the high side of
; V, and the test the other way about.
;
; The sides are the half-unit bytes of SORT_AND_DRAW_THINGS; each difference
; has 256 added and is halved, to keep it positive, which does not change the
; order.
;
; IX the candidate
; IY the other thing
DEPTH_BY_CORNERS:
  LD A,(VIEW)              ; Turned round: the other corners
  AND $01                  ;
  JR NZ,DEPTH_BY_CORNERS_1 ;
  LD A,(IY+$01)           ; DE = how far back the other thing's nearest corner
  ADD A,(IY+$08)          ; is: its low V side less its high U side
  RRA                     ;
  ADD A,$40               ;
  LD C,A                  ;
  LD B,$00                ;
  LD A,(IY+$03)           ;
  SUB (IY+$09)            ;
  RRA                     ;
  ADD A,$40               ;
  LD L,A                  ;
  LD H,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  LD BC,$0100             ;
  ADD HL,BC               ;
  SRL H                   ;
  RR L                    ;
  EX DE,HL                ;
  LD A,(IX+$01)           ; The candidate's the same...
  ADD A,(IX+$08)          ;
  RRA                     ;
  ADD A,$40               ;
  LD C,A                  ;
  LD B,$00                ;
  LD A,(IX+$03)           ;
  SUB (IX+$09)            ;
DEPTH_BY_CORNERS_0:
  RRA                     ; ...into HL
  ADD A,$40               ;
  LD L,A                  ;
  LD H,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  LD BC,$0100             ;
  ADD HL,BC               ;
  SRL H                   ;
  RR L                    ;
  AND A                   ; The candidate's corner as far back or further: it
  SBC HL,DE               ; stays
  RET NC                  ;
  JP DEPTH_SWAP           ; Otherwise the other takes its place
DEPTH_BY_CORNERS_1:
  LD A,(IX+$01)           ; Turned round: DE = the candidate's high V side less
  SUB (IX+$08)            ; its low U side
  RRA                     ;
  ADD A,$40               ;
  LD C,A                  ;
  LD B,$00                ;
  LD A,(IX+$03)           ;
  ADD A,(IX+$09)          ;
  RRA                     ;
  ADD A,$40               ;
  LD L,A                  ;
  LD H,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  LD BC,$0100             ;
  ADD HL,BC               ;
  SRL H                   ;
  RR L                    ;
  EX DE,HL                ;
  LD A,(IY+$01)           ; The other's the same, into HL; the candidate stays
  SUB (IY+$08)            ; if the other's corner is as near as its own or
  RRA                     ; nearer
  ADD A,$40               ;
  LD C,A                  ;
  LD B,$00                ;
  LD A,(IY+$03)           ;
  ADD A,(IY+$09)          ;
  JR DEPTH_BY_CORNERS_0   ;

; The things in a cell, to be drawn
;
; The addresses of the object records in one cell of the town, filled by
; LIST_THINGS_IN_CELL and ended by a zero word; SORT_AND_DRAW_THINGS sorts and
; draws them, clearing bit 7 of each entry's high byte as it draws it. 32
; bytes: fifteen addresses and the zero. Nothing checks the count -- a
; sixteenth thing in one cell would put the zero over the first bytes of
; TURN_CELL -- but the most measured was four (LIST_THINGS_IN_CELL). sna2ctl
; took the zeros on the tape for an unused gap.
DRAW_LIST:
  DEFS $20

; Turn a cell round with the town
;
; Used by the routines at DRAW_CELLS and LIST_THINGS_IN_CELL.
;
; With the town turned round (bit 0 of VIEW) it is seen from the other side,
; which is the same as the map read from its far corner: column c becomes 31 -
; c and row r becomes 31 - r. Doing it twice gives the cell back, so the same
; routine turns a cell from the town's terms to the view's (DRAW_CELLS) and
; back again (LIST_THINGS_IN_CELL). In the usual view, nothing.
;
;   L the column
;   H the row
; O:HL the column and row, turned if the town is
TURN_CELL:
  LD A,(VIEW)             ; The usual view: as they are
  AND $01                 ;
  RET Z                   ;
  LD A,L                  ; Otherwise each complemented, within 0-31
  CPL                     ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,H                  ;
  CPL                     ;
  AND $1F                 ;
  LD H,A                  ;
  RET                     ;

; Turn a position round with the town
;
; Used by the routine at PROJECT_THING.
;
; The same for a position along U or V, whose high byte is the cell and low
; byte the place in it: turned round, it becomes the distance from the far edge
; of the town, 8191 less it. Used by PROJECT_THING for a thing's U and V.
;
;   HL a U or a V
; O:HL the same, turned if the town is
TURN_POSITION:
  LD A,(VIEW)             ; The usual view: as it is
  AND $01                 ;
  RET Z                   ;
  LD A,L                  ; Otherwise both bytes complemented, the high one
  CPL                     ; within 0-31
  LD L,A                  ;
  LD A,H                  ;
  CPL                     ;
  AND $1F                 ;
  LD H,A                  ;
  RET                     ;

; Draw a building's outline on the ground
;
; Used by the routine at DRAW_CELLS.
;
; What stands in front of the knight is not drawn as walls, which would hide
; him: the drawing order (DRAW_CELLS) calls this for his own cell and the three
; nearer the viewer -- one less in V, one more in U, and both -- and for those
; only the line where the building's walls meet the ground is drawn, all the
; way round. The two near faces come from the building definition for this view
; (OUTLINE_NEAR_FACES), and the two far ones from the definition for the other
; view, which describes those same walls seen from the other side: from the
; right-hand corner leftwards, up the screen along one face and down along the
; other, each column's edge through DRAW_EDGE with C set to 1. Each tile has an
; edge picture under it (TILE_EDGES): a plain line for a wall, or a stub at one
; end for a tile with an archway, and C = 1 swaps which end's stub, since those
; faces are seen from behind. An archway in a wall so leaves a gap in its
; outline.
;
; Open ground (type 0) has no building. Drawn with OR, and not through the
; column claims of DRAW_WALLS's walls. Measured: with this routine made to
; return at once, the white lines on the ground in front of the knight were
; gone, and with DRAW_WALLS returning at once instead, the walls behind him.
;
; HL the cell, as the drawing order sees it
DRAW_OUTLINE:
  CALL LOOK_UP_CELL       ; The cell's type; open ground: nothing
  RET Z                   ;
  ADD A,A                 ; The type times two, the building table's index for
  PUSH AF                 ; the usual view; DRAW_X and DRAW_Y the cell's corner
  CALL PROJECT_CELL       ; on the screen (PROJECT_CELL)
  POP AF                  ;
  PUSH AF                 ;
  LD HL,VIEW              ; Which way round?
  BIT 0,(HL)              ;
  JR NZ,DRAW_OUTLINE_2    ;
  CALL OUTLINE_NEAR_FACES ; The usual way: the near faces from the usual view's
  POP AF                  ; definition, and then the far ones from the turned
  OR $01                  ; one's (index plus 1)
OUTLINE_FAR_FACES:
  LD HL,(DRAW_X)          ; A column back to the left: the far faces start from
  LD DE,$FFF0             ; the right-hand corner, where the near faces ended
  ADD HL,DE               ;
  LD (DRAW_X),HL          ;
  LD BC,BUILDING_TABLE    ; IY = the other view's definition (BUILDING_TABLE)
  CALL TABLE_WORD         ;
  PUSH HL                 ;
  POP IY                  ;
  XOR A                   ; Its first face, unmirrored: eight columns leftwards
  LD (DRAW_PASS),A        ; and up the screen, C = 1
  LD BC,$0801             ;
DRAW_OUTLINE_0:
  CALL DRAW_EDGE          ;
  CALL EDGE_LEFT_UP       ;
  DJNZ DRAW_OUTLINE_0     ;
  LD HL,(DRAW_Y)          ; Down 8 lines for the second face, which slopes the
  LD DE,$FFF8             ; other way
  ADD HL,DE               ;
  LD (DRAW_Y),HL          ;
  LD A,$01                ; The second face, mirrored: eight columns leftwards
  LD (DRAW_PASS),A        ; and down
  LD BC,$0801             ;
DRAW_OUTLINE_1:
  CALL DRAW_EDGE          ;
  CALL EDGE_LEFT_DOWN     ;
  DJNZ DRAW_OUTLINE_1     ;
  RET
DRAW_OUTLINE_2:
  OR $01                  ; Turned round: the turned definition's faces are the
  CALL OUTLINE_NEAR_FACES ; near ones, and the usual view's the far ones
  POP AF                  ;
  JR OUTLINE_FAR_FACES    ;

; Draw the edges of a building definition's two faces
;
; Used by the routine at DRAW_OUTLINE.
;
; The two faces of a building definition, eight columns each, drawn left to
; right from the cell's corner at DRAW_X and DRAW_Y -- the first down the
; screen, the second, mirrored, up it -- as edge pictures only (DRAW_EDGE, with
; C = 0). Used by DRAW_OUTLINE for a building's near faces. Leaves DRAW_X and
; DRAW_Y at the right-hand corner.
;
; A the building table's index: the cell's type times two, plus 1 for the
;   turned view
OUTLINE_NEAR_FACES:
  LD BC,BUILDING_TABLE    ; IY = the definition (BUILDING_TABLE)
  CALL TABLE_WORD         ;
  PUSH HL                 ;
  POP IY                  ;
  XOR A                   ; The first face, unmirrored, C = 0
  LD (DRAW_PASS),A        ;
  LD BC,$0800             ;
OUTLINE_NEAR_FACES_0:
  CALL DRAW_EDGE            ; Eight columns' edges, rightwards and down the
  CALL EDGE_RIGHT_DOWN      ; screen
  DJNZ OUTLINE_NEAR_FACES_0 ;
  LD HL,(DRAW_Y)          ; Up 8 lines for the second face, which slopes the
  LD DE,$0008             ; other way
  ADD HL,DE               ;
  LD (DRAW_Y),HL          ;
  LD A,$01                ; Mirrored
  LD (DRAW_PASS),A        ;
  LD BC,$0800             ;
OUTLINE_NEAR_FACES_1:
  CALL DRAW_EDGE            ; Eight columns, rightwards and up
  CALL EDGE_RIGHT_UP        ;
  DJNZ OUTLINE_NEAR_FACES_1 ;
  RET                       ;

; Move the drawing position a column right and up
;
; Used by the routine at DRAW_WALLS.
;
; Sixteen pixels right and 8 lines up the screen: along a building's second
; face, the way DRAW_WALLS steps. The pair of tiles is moved past by
; DRAW_WALL_COLUMN itself.
STEP_RIGHT_UP:
  LD DE,$0008             ; 8 lines up; the column across
  JR STEP_ACROSS          ;

; Move the drawing position a column right and up, past the column's tiles
;
; Used by the routine at OUTLINE_NEAR_FACES.
;
; The same with IY moved past the column's two tiles (DRAW_EDGE does not), for
; a face's edges in OUTLINE_NEAR_FACES. STEP_ACROSS, the common tail, moves
; DRAW_Y by DE and DRAW_X 16 pixels right.
EDGE_RIGHT_UP:
  LD DE,$0008             ; 8 lines up
; This entry point is used by the routine at EDGE_RIGHT_DOWN.
EDGE_RIGHT_UP_0:
  INC IY                  ; Past the column's two tiles
  INC IY                  ;
; This entry point is used by the routines at STEP_RIGHT_UP and
; STEP_RIGHT_DOWN.
STEP_ACROSS:
  LD HL,(DRAW_Y)          ; DRAW_Y moved by DE
  ADD HL,DE               ;
  LD (DRAW_Y),HL          ;
  LD HL,(DRAW_X)          ; DRAW_X 16 pixels right
  LD DE,$0010             ;
  ADD HL,DE               ;
  LD (DRAW_X),HL          ;
  RET                     ;

; Move the drawing position a column right and down, past the column's tiles
;
; Used by the routine at OUTLINE_NEAR_FACES.
;
; Along a first face's edges (OUTLINE_NEAR_FACES).
EDGE_RIGHT_DOWN:
  LD DE,$FFF8             ; 8 lines down; past the tiles, and across
  JR EDGE_RIGHT_UP_0      ;

; Move the drawing position a column right and down
;
; Used by the routine at DRAW_WALLS.
;
; Along a building's first face, the way DRAW_WALLS steps.
STEP_RIGHT_DOWN:
  LD DE,$FFF8             ; 8 lines down; across
  JR STEP_ACROSS          ;

; Move the drawing position a column left and up, past the column's tiles
;
; Used by the routine at DRAW_OUTLINE.
;
; For the far faces of an outline, drawn from right to left (DRAW_OUTLINE).
; STEP_BACK, the common tail, moves IY past the column's tiles, DRAW_Y by DE
; and DRAW_X 16 pixels left.
EDGE_LEFT_UP:
  LD DE,$0008             ; 8 lines up
; This entry point is used by the routine at EDGE_LEFT_DOWN.
STEP_BACK:
  INC IY                  ; Past the column's two tiles
  INC IY                  ;
  LD HL,(DRAW_Y)          ; DRAW_Y moved by DE
  ADD HL,DE               ;
  LD (DRAW_Y),HL          ;
  LD HL,(DRAW_X)          ; DRAW_X 16 pixels left
  LD DE,$FFF0             ;
  ADD HL,DE               ;
  LD (DRAW_X),HL          ;
  RET                     ;

; Move the drawing position a column left and down, past the column's tiles
;
; Used by the routine at DRAW_OUTLINE.
;
; For the second far face of an outline (DRAW_OUTLINE).
EDGE_LEFT_DOWN:
  LD DE,$FFF8             ; 8 lines down; past the tiles, and back
  JR STEP_BACK            ;

; Draw the edge picture under one column of a building
;
; Used by the routines at DRAW_OUTLINE and OUTLINE_NEAR_FACES.
;
; The column's lower tile (the number at IY) picks its edge picture from
; TILE_EDGES -- 0 a whole line, 2 and 3 a stub at one end or the other of a
; tile with an archway -- and C, 1 for a face seen from behind, is XORed in to
; swap the stubs; EDGE_TABLE gives the picture, and PUT_EDGE ORs it into the
; buffer at DRAW_X and DRAW_Y, mirrored on a second face (DRAW_PASS). Only a
; column that starts inside the buffer's width (x from 17 to 207) and at a y
; from 0 to 255 is drawn.
;
; IY the column's pair of tiles in a building definition
; C 0, or 1 to swap the stubs at an archway
DRAW_EDGE:
  LD DE,(DRAW_X)          ; x from 17 to 207, or nothing
  LD HL,$00CF             ;
  AND A                   ;
  SBC HL,DE               ;
  RET C                   ;
  LD HL,$0010             ;
  SBC HL,DE               ;
  RET NC                  ;
  LD HL,(DRAW_Y)          ; y from 0 to 255, or nothing; D = y, E = x
  LD A,H                  ;
  AND A                   ;
  RET NZ                  ;
  LD D,L                  ;
  LD A,C                  ; The tile's edge number, XOR C
  PUSH BC                 ;
  LD C,(IY+$00)           ;
  LD B,$00                ;
  LD HL,TILE_EDGES        ;
  ADD HL,BC               ;
  XOR (HL)                ;
  LD BC,EDGE_TABLE        ; HL = the picture (EDGE_TABLE)
  CALL TABLE_WORD         ;
  CALL PUT_EDGE           ; ORed into the buffer
  POP BC                  ;
  RET                     ;

; Draw an edge picture that starts below the play area
;
; Used by the routine at PUT_EDGE.
;
; The start of PUT_EDGE when the picture's bottom row is below the bottom of
; the play area (line $48, counting up the screen): its rows below it are
; skipped, and the rest drawn from the bottom line up. All of it below:
; nothing.
;
; A the picture's y less $48, negative
; E its x
; HL the picture
CLIP_EDGE:
  NEG                     ; C = the rows below the play area; A = the rows
  LD C,A                  ; above it, if any
  LD A,(HL)               ;
  INC HL                  ;
  SUB C                   ;
  RET M                   ;
  RET Z                   ;
  LD B,$00                ; Past the rows below; from the bottom line
  ADD HL,BC               ;
  ADD HL,BC               ;
  LD D,$48                ;
  JR PUT_EDGE_1           ;

; OR a 16-pixel picture into the buffer
;
; Used by the routine at DRAW_EDGE.
;
; Draws an edge picture -- a height byte, then two bytes a row, the bottom row
; first -- at a pixel x and a line y, ORed into the screen buffer (BUFFER). The
; buffer's lines run up the screen, 24 bytes apiece: line $48 is the bottom of
; the play area and $B7 its top, and BUFFER_ADDRESS turns x and y into an
; address. Rows above the top are cut; rows below the bottom are skipped by
; CLIP_EDGE.
;
; SP reads the picture, a row a POP, the real stack pointer kept in SAVED_SP;
; the game never enables interrupts. Four cases: x a multiple of 8 or not (bits
; 1 and 2 of x; bit 0 is ignored, so things move in steps of two pixels), and
; the first face or the second (DRAW_PASS), which is drawn mirrored. A shifted
; row covers three buffer bytes, through a pair of pages built by MAKE_TABLES:
; the part of each picture byte that stays in its buffer byte and the part that
; falls into the next. The pages at SHIFT_TABLES shift; the ones at
; MIRROR_TABLES reverse a byte and shift it, for the mirrored face, which also
; takes the row's two bytes the other way round. An aligned mirrored row
; reverses each byte through REVERSE_TABLE.
;
; D the y of its bottom row
; E its x
; HL the picture
PUT_EDGE:
  LD A,D                  ; Starting below the play area: CLIP_EDGE
  SUB $48                 ;
  JR C,CLIP_EDGE          ;
  SUB $70                 ; At or above its top: nothing
  RET NC                  ;
  NEG                     ; A = the rows: the height, or as many as fit below
  CP (HL)                 ; the top
  JR C,PUT_EDGE_0         ;
  LD A,(HL)               ;
PUT_EDGE_0:
  INC HL                  ;
; This entry point is used by the routine at CLIP_EDGE.
PUT_EDGE_1:
  EX AF,AF'               ; The count into A'; DE = the buffer address
  EX DE,HL                ; (BUFFER_ADDRESS)
  CALL BUFFER_ADDRESS     ;
  EX DE,HL                ;
  LD (SAVED_SP),SP        ; SP onto the picture's rows
  LD SP,HL                ;
  LD A,(DRAW_X)           ; Aligned: the plain cases
  AND $06                 ;
  JR Z,PUT_EDGE_6         ;
  OR $F0                  ; H = $F2, $F4 or $F6, the reversing and shifting
  LD H,A                  ; pages for a shift of 2, 4 or 6 pixels
  LD A,(DRAW_PASS)        ; The second face is mirrored
  AND A                   ;
  JR NZ,PUT_EDGE_4        ;
  SET 3,H                 ; The first: H = $FA, $FC or $FE, the shifting pages
  EX AF,AF'               ;
PUT_EDGE_2:
  EX AF,AF'               ; A row: the first byte's part that stays, into the
  POP BC                  ; first buffer byte
  LD L,C                  ;
  LD A,(DE)               ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ;
  INC H                   ; The part that falls out of it and the second byte's
  LD A,(DE)               ; part that stays, into the second
  OR (HL)                 ;
  DEC H                   ;
  LD L,B                  ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ; The part that falls out of the second, into the
  INC H                   ; third
  LD A,(DE)               ;
  OR (HL)                 ;
  LD (DE),A               ;
  DEC H                   ;
  EX DE,HL                ; Up a line, 24 bytes on from the first; until the
  LD BC,$0016             ; rows run out
  ADD HL,BC               ;
  EX DE,HL                ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_EDGE_2        ;
PUT_EDGE_3:
  LD SP,(SAVED_SP)        ; The real stack pointer back
  RET                     ;
PUT_EDGE_4:
  EX AF,AF'               ; Mirrored: the same, with the row's second byte
PUT_EDGE_5:
  EX AF,AF'               ; first, through the reversing pages
  POP BC                  ;
  LD L,B                  ;
  LD A,(DE)               ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ;
  INC H                   ;
  LD A,(DE)               ;
  OR (HL)                 ;
  DEC H                   ;
  LD L,C                  ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ;
  INC H                   ;
  LD A,(DE)               ;
  OR (HL)                 ;
  LD (DE),A               ;
  DEC H                   ;
  EX DE,HL                ;
  LD BC,$0016             ;
  ADD HL,BC               ;
  EX DE,HL                ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_EDGE_5        ;
  JR PUT_EDGE_3           ;
PUT_EDGE_6:
  EX DE,HL                ; Aligned: the two bytes ORed in as they are
  LD A,(DRAW_PASS)        ;
  AND A                   ;
  JR NZ,PUT_EDGE_8        ;
  LD BC,$0017             ;
  EX AF,AF'               ;
PUT_EDGE_7:
  EX AF,AF'               ;
  POP DE                  ;
  LD A,(HL)               ;
  OR E                    ;
  LD (HL),A               ;
  INC HL                  ;
  LD A,(HL)               ;
  OR D                    ;
  LD (HL),A               ;
  ADD HL,BC               ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_EDGE_7        ;
  JR PUT_EDGE_3           ;
PUT_EDGE_8:
  LD B,$F9                ; Aligned and mirrored: each byte reversed
  EX AF,AF'               ; (REVERSE_TABLE), the second first
PUT_EDGE_9:
  EX AF,AF'               ;
  POP DE                  ;
  LD C,D                  ;
  LD A,(BC)               ;
  OR (HL)                 ;
  LD (HL),A               ;
  INC HL                  ;
  LD C,E                  ;
  LD A,(BC)               ;
  OR (HL)                 ;
  LD (HL),A               ;
  LD DE,$0017             ;
  ADD HL,DE               ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_EDGE_9        ;
  JR PUT_EDGE_3           ;

; Colour a column of wall up to the top of the play area
;
; Used by the routine at DRAW_WALL_COLUMN.
;
; A wall hides everything above it on the screen, so its colour runs from the
; attribute row holding its bottom line to the top of the play area: two
; attribute bytes a row, filled by COLOUR_STRIP in the attribute buffer
; (ATTR_BUFFER, 24 bytes a row, the bottom row first). The ink is bright green,
; cyan, yellow or white by the two low bits of the cell's type (CELL_TYPE); the
; paper is this turn's, LAST_FLASH, which a dying villain flashes. Nothing for
; a wall standing at or above line $B8.
;
; The pair of bytes runs one past the end of a row when the column's x is in
; the last byte of the row: into the first byte of the next row, part of the
; two-byte margin at the left of the buffer that is never copied to the screen
; (COPY_ATTR_BUFFER shows 22 of each row's 24 bytes), and on the top row one
; past the attribute buffer altogether, into ATTR_SPILL. Measured: 28 of 752
; fills in a random tour reached it, each at the right-hand edge; and over 877
; calls the lowest wall bottom was line 126, so a fill never starts below the
; attribute buffer.
;
; D the y of the wall's bottom line
; E its x
COLOUR_WALL:
  LD A,D                  ; At or above line $BF: nothing
  SUB $BF                 ;
  RET NC                  ;
  NEG                     ; The attribute rows from its own up to the top: (191
  SRL A                   ; - y) / 8; none, nothing
  SRL A                   ;
  SRL A                   ;
  RET Z                   ;
  LD B,A                  ; B = the rows; HL = the attribute byte
  EX DE,HL                ; (ATTR_ADDRESS)
  CALL ATTR_ADDRESS       ;
  LD A,(CELL_TYPE)        ; Bright, with the ink from the cell type
  AND $03                 ;
  OR $44                  ;
  JP COLOUR_STRIP         ; Fill the rows, with this turn's paper
                          ; (COLOUR_STRIP)

; Draw a building's walls
;
; Used by the routine at DRAW_CELLS.
;
; For a cell behind the knight -- the five the drawing order (DRAW_CELLS) draws
; walls for, one less in U or one more in V -- the building on it is drawn as
; two walls standing on its near edges: the definition for the cell's type and
; the view (BUILDING_TABLE, type times two plus VIEW) gives each face eight
; columns of a lower and an upper tile, and DRAW_WALL_COLUMN draws each column
; from the cell's corner (PROJECT_CELL) rightwards, down the screen along the
; first face and then, mirrored, up it along the second.
;
; Walls are drawn nearest first among themselves, and each claims the screen
; columns it covers (COLUMNS_DRAWN): a tile is written over what is under it,
; and a wall and its colour reach from its bottom to the top of the play area,
; so nothing behind it in the same column could show. A wall further back only
; fills the columns still unclaimed, and as soon as all sixteen are claimed the
; routine stops. The drawing order puts the things in an open cell after the
; walls that stand behind it and before those in front of it, which cover them.
;
; HL the cell, as the drawing order sees it
DRAW_WALLS:
  CALL LOOK_UP_CELL       ; The cell's type (LOOK_UP_CELL); open ground:
  RET Z                   ; nothing
  LD (CELL_TYPE),A        ; Kept for the colour (COLOUR_WALL)
  ADD A,A                 ; IY = the building definition: the type times two,
  LD HL,VIEW              ; plus 1 turned round
  OR (HL)                 ;
  LD BC,BUILDING_TABLE    ;
  CALL TABLE_WORD         ;
  PUSH HL                 ;
  POP IY                  ;
  CALL PROJECT_CELL       ; DRAW_X and DRAW_Y = the cell's corner on the screen
  XOR A                   ; The first face, unmirrored: eight columns
  LD (DRAW_PASS),A        ;
  LD B,$08                ;
DRAW_WALLS_0:
  CALL DRAW_WALL_COLUMN   ; A column; with every screen column claimed, stop
  LD HL,(COLUMNS_DRAWN)   ;
  LD A,L                  ;
  AND H                   ;
  CPL                     ;
  AND A                   ;
  RET Z                   ;
  CALL STEP_RIGHT_DOWN    ; Right and down the screen to the next
  DJNZ DRAW_WALLS_0       ;
  LD HL,(DRAW_Y)          ; Up 8 lines for the second face, which slopes the
  LD DE,$0008             ; other way
  ADD HL,DE               ;
  LD (DRAW_Y),HL          ;
  LD A,$01                ; Mirrored: eight columns
  LD (DRAW_PASS),A        ;
  LD B,$08                ;
DRAW_WALLS_1:
  CALL DRAW_WALL_COLUMN   ; The same, rightwards and up
  LD HL,(COLUMNS_DRAWN)   ;
  LD A,L                  ;
  AND H                   ;
  CPL                     ;
  AND A                   ;
  RET Z                   ;
  CALL STEP_RIGHT_UP      ;
  DJNZ DRAW_WALLS_1       ;
  RET

; Draw one column of a wall, unless a nearer wall has it
;
; Used by the routine at DRAW_WALLS.
;
; The screen is taken as sixteen columns 16 pixels wide, x / 16, a bit each in
; COLUMNS_DRAWN (bit 7 of x picking the byte). Every tile column in a turn lies
; at the same x within its 16 pixels, since the cells' corners are 128 pixels
; apart, so a column of wall and a screen column always coincide. The column's
; bit is patched into the BIT at TEST_COLUMN and the SET at CLAIM_COLUMN.
; DRAW_CELLS starts each turn with the first column (left of the buffer) and
; the last three (right of it) already claimed, so walls are clipped at the
; sides here.
;
; An unclaimed column is claimed, then drawn: the lower tile with its bottom
; row at DRAW_Y (PUT_TILE), its colour up to the top (COLOUR_WALL), and the
; upper tile 64 lines above it. A column off the screen's 0-255 range in x or y
; is skipped, and IY moved past its two tiles either way.
;
;   IY the column's pair of tiles in the building definition
; O:IY the next column's
DRAW_WALL_COLUMN:
  LD HL,(DRAW_X)           ; x off the 0-255 range: skip it
  LD A,H                   ;
  AND A                    ;
  JR NZ,DRAW_WALL_COLUMN_1 ;
  LD A,L                    ; The column's bit, bits 4-6 of x, patched into the
  LD E,A                    ; BIT and the SET below
  RRCA                      ;
  AND $38                   ;
  OR $46                    ;
  LD (TEST_COLUMN+$0001),A  ;
  OR $80                    ;
  LD (CLAIM_COLUMN+$0001),A ;
  LD A,L                  ; HL = COLUMNS_DRAWN, or its second byte for x of 128
  RLCA                    ; up
  AND $01                 ;
  LD HL,COLUMNS_DRAWN     ;
  JR Z,TEST_COLUMN        ;
  INC HL                  ;
TEST_COLUMN:
  BIT 0,(HL)               ; Patched BIT: claimed already by a nearer wall,
  JR NZ,DRAW_WALL_COLUMN_1 ; skip it
CLAIM_COLUMN:
  SET 0,(HL)              ; Patched SET: claim it (before y is looked at)
  LD HL,(DRAW_Y)           ; y off the 0-255 range: skip it; D = y, E = x
  LD A,H                   ;
  AND A                    ;
  JR NZ,DRAW_WALL_COLUMN_1 ;
  LD D,L                   ;
  PUSH BC                 ; The lower tile (PUT_TILE)
  PUSH DE                 ;
  CALL PUT_TILE           ;
  POP DE                  ; The wall's colour (COLOUR_WALL)
  PUSH DE                 ;
  CALL COLOUR_WALL        ;
  POP DE                  ; The upper tile...
  INC IY                  ;
  LD HL,(DRAW_Y)           ; ...64 lines up, if that is still in range
  LD BC,$0040              ;
  ADD HL,BC                ;
  LD A,H                   ;
  AND A                    ;
  JR NZ,DRAW_WALL_COLUMN_0 ;
  LD D,L                  ; Draw it
  CALL PUT_TILE           ;
DRAW_WALL_COLUMN_0:
  POP BC                  ; Past the upper tile
  INC IY                  ;
  RET                     ;
DRAW_WALL_COLUMN_1:
  INC IY                  ; Skipped: past both tiles
  INC IY                  ;
  RET                     ;

; Draw a tile that starts below the play area
;
; Used by the routine at PUT_TILE.
;
; The start of PUT_TILE when the tile's bottom row is below the bottom of the
; play area (line $48): its rows below it are skipped, and the rest drawn from
; the bottom line up. All of it below: nothing. CLIP_EDGE is the same for an
; edge picture.
;
; A the tile's y less $48, negative
; E its x
; HL the tile
CLIP_TILE:
  NEG                     ; C = the rows below the play area; A = the rows
  LD C,A                  ; above it, if any
  LD A,(HL)               ;
  INC HL                  ;
  SUB C                   ;
  RET M                   ;
  RET Z                   ;
  LD B,$00                ; Past the rows below; from the bottom line
  ADD HL,BC               ;
  ADD HL,BC               ;
  LD D,$48                ;
  JR PUT_TILE_1           ;

; Draw a tile of wall
;
; Used by the routine at DRAW_WALL_COLUMN.
;
; The number at IY picks the tile from TILE_TABLE: a height byte, then two
; bytes a row, the bottom row first. It is drawn at DRAW_X and the line in D
; exactly as PUT_EDGE draws an edge picture -- the same four cases, the same
; pages, the second face mirrored -- except that a tile is solid: its 16 pixels
; are written over what is under them rather than ORed in. A shifted row covers
; three buffer bytes; the middle one is wholly the tile's, and in the first and
; the last the pixels outside the tile are kept by AND masks. The masks come
; from TILE_MASKS by the shift and are patched into the four ANDs
; (TILE_MASK_FIRST, TILE_MASK_LAST, and the same in the mirrored run), the
; first byte's mask keeping the pixels to the left of the tile and its
; complement those to the right.
;
; IY the tile's number in a building definition
; D the y of its bottom row
; E its x
PUT_TILE:
  LD A,(IY+$00)           ; HL = the tile (TILE_TABLE)
  LD BC,TILE_TABLE        ;
  CALL TABLE_WORD         ;
  LD A,D                  ; Starting below the play area: CLIP_TILE
  SUB $48                 ;
  JR C,CLIP_TILE          ;
  SUB $70                 ; At or above its top, nothing; A = the rows, the
  RET NC                  ; height or as many as fit below the top
  NEG                     ;
  CP (HL)                 ;
  JR C,PUT_TILE_0         ;
  LD A,(HL)               ;
PUT_TILE_0:
  INC HL                  ;
; This entry point is used by the routine at CLIP_TILE.
PUT_TILE_1:
  EX AF,AF'               ; The count into A'; DE = the buffer address
  EX DE,HL                ; (BUFFER_ADDRESS)
  CALL BUFFER_ADDRESS     ;
  EX DE,HL                ;
  PUSH HL                 ; The shift's mask from TILE_MASKS: x / 2, bits 0-1
  LD A,(DRAW_X)           ;
  RRCA                    ;
  AND $03                 ;
  LD HL,TILE_MASKS        ;
  CALL ADD_HL_A           ;
  LD A,(HL)                           ; Into the first byte's two ANDs...
  LD (TILE_MASK_FIRST+$0001),A        ;
  LD (TILE_MASK_FIRST_TURNED+$0001),A ;
  CPL                                ; ...and its complement into the last
  LD (TILE_MASK_LAST+$0001),A        ; byte's
  LD (TILE_MASK_LAST_TURNED+$0001),A ;
  POP HL                  ; SP onto the tile's rows, the real one in SAVED_SP
  LD (SAVED_SP),SP        ;
  LD SP,HL                ;
  LD A,(DRAW_X)           ; Aligned: the plain cases
  AND $06                 ;
  JR Z,PUT_TILE_6         ;
  OR $F0                  ; H = the shift's pages: $F2, $F4 or $F6 mirrored
  LD H,A                  ; (the second face), $FA, $FC or $FE not
  LD A,(DRAW_PASS)        ;
  AND A                   ;
  JR NZ,PUT_TILE_4        ;
  SET 3,H                 ;
  EX AF,AF'               ; A row: the first buffer byte kept left of the tile
PUT_TILE_2:
  EX AF,AF'               ; (patched mask), the tile's first part put in
  POP BC                  ;
  LD L,C                  ;
  LD A,(DE)               ;
TILE_MASK_FIRST:
  AND $00                 ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ; The middle byte wholly the tile's
  INC H                   ;
  LD A,(HL)               ;
  DEC H                   ;
  LD L,B                  ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ; The last kept right of the tile (patched mask), the
  INC H                   ; tile's last part put in
  LD A,(DE)               ;
TILE_MASK_LAST:
  AND $00                 ;
  OR (HL)                 ;
  LD (DE),A               ;
  DEC H                   ;
  EX DE,HL                ; Up a line, until the rows run out
  LD BC,$0016             ;
  ADD HL,BC               ;
  EX DE,HL                ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_TILE_2        ;
PUT_TILE_3:
  LD SP,(SAVED_SP)        ; The real stack pointer back
  RET                     ;
PUT_TILE_4:
  EX AF,AF'               ; Mirrored: the same, the row's second byte first,
PUT_TILE_5:
  EX AF,AF'               ; through the reversing pages
  POP BC                  ;
  LD L,B                  ;
  LD A,(DE)               ;
TILE_MASK_FIRST_TURNED:
  AND $00                 ;
  OR (HL)                 ;
  LD (DE),A               ;
  INC DE                  ;
  INC H                   ;
  LD B,(HL)               ;
  DEC H                   ;
  LD L,C                  ;
  LD A,(HL)               ;
  OR B                    ;
  LD (DE),A               ;
  INC DE                  ;
  INC H                   ;
  LD A,(DE)               ;
TILE_MASK_LAST_TURNED:
  AND $00                 ;
  OR (HL)                 ;
  LD (DE),A               ;
  DEC H                   ;
  EX DE,HL                ;
  LD BC,$0016             ;
  ADD HL,BC               ;
  EX DE,HL                ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_TILE_5        ;
  JR PUT_TILE_3           ;
PUT_TILE_6:
  EX DE,HL                ; Aligned: the two bytes written in as they are
  LD A,(DRAW_PASS)        ;
  AND A                   ;
  JR NZ,PUT_TILE_8        ;
  LD BC,$0017             ;
  EX AF,AF'               ;
PUT_TILE_7:
  EX AF,AF'               ;
  POP DE                  ;
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  ADD HL,BC               ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_TILE_7        ;
  JR PUT_TILE_3           ;
PUT_TILE_8:
  LD B,$F9                ; Aligned and mirrored: each reversed
  EX AF,AF'               ; (REVERSE_TABLE), the second first
PUT_TILE_9:
  EX AF,AF'               ;
  POP DE                  ;
  LD C,D                  ;
  LD A,(BC)               ;
  LD (HL),A               ;
  INC HL                  ;
  LD C,E                  ;
  LD A,(BC)               ;
  LD (HL),A               ;
  LD DE,$0017             ;
  ADD HL,DE               ;
  EX AF,AF'               ;
  DEC A                   ;
  JR NZ,PUT_TILE_9        ;
  JR PUT_TILE_3           ;

; Masks for a shifted tile's first byte
;
; By the tile's shift in pixels (PUT_TILE): the pixels of the buffer's first
; byte that lie to the left of the tile, and so are kept. The complement keeps
; those right of it in the last byte. An aligned tile needs neither.
TILE_MASKS:
  DEFB $00,$C0,$F0,$FC    ; Shifts of 0, 2, 4 and 6 pixels

; Where a thing is on the screen
;
; Used by the routine at DRAW_SPRITE.
;
; Projects an object record's U and V (+1 to +4) onto the screen at DRAW_X and
; DRAW_Y, turned round with the town if it is (TURN_POSITION), by
; PROJECT_CELL's formula. Used by the sprite drawing (DRAW_SPRITE).
;
; IX the object record
PROJECT_THING:
  LD L,(IX+$03)           ; Its V, turned if the town is, saved
  LD H,(IX+$04)           ;
  CALL TURN_POSITION      ;
  PUSH HL                 ;
  LD L,(IX+$01)           ; Its U, the same; on to the projection
  LD H,(IX+$02)           ;
  CALL TURN_POSITION      ;
  JR PROJECT_POINT        ;

; Where a cell's corner is on the screen
;
; Used by the routines at DRAW_OUTLINE and DRAW_WALLS.
;
; The projection, and the scrolling: everything is placed relative to the
; knight, who therefore stays at the middle of the screen while the town moves
; under him. For a point at U and V, with dU and dV its distance from the
; knight's U and V (both turned round with the town if it is): DRAW_X = (dU +
; dV + $F0) / 2 and DRAW_Y = (dV - dU + $1B0) / 4, signed. So U runs right and
; down the screen and V right and up, 256 units a cell: a cell is a diamond 256
; pixels wide and 128 lines high, bigger than the play area, and the knight's
; own point is at x 120, the middle of the part of the buffer that is shown,
; and line 108. DRAW_Y counts up the screen, as the buffer's lines do. It is
; Filmation's projection, x from U + V and y from V - U, at half the scale and
; with no height.
;
; PROJECT_CELL projects the corner of the cell last looked up (CELL_LOOKED_UP,
; in the view's terms): its lowest U and V, where the wall along its first face
; starts. PROJECT_POINT, entered from PROJECT_THING with a U in HL and a V
; pushed, both turned already if the town is, projects any point.
PROJECT_CELL:
  LD A,($BBB5)            ; V = the cell's row times 256, saved
  LD L,$00                ;
  LD H,A                  ;
  PUSH HL                 ;
  LD A,(CELL_LOOKED_UP)   ; U = its column times 256
  LD L,$00                ;
  LD H,A                  ;
; This entry point is used by the routine at PROJECT_THING.
PROJECT_POINT:
  LD DE,(KNIGHT_U)        ; The knight's U, turned if the town is
  LD A,(VIEW)             ;
  AND $01                 ;
  JR Z,PROJECT_CELL_0     ;
  LD A,E                  ;
  CPL                     ;
  LD E,A                  ;
  LD A,D                  ;
  CPL                     ;
  AND $1F                 ;
  LD D,A                  ;
PROJECT_CELL_0:
  AND A                   ; DE = dU
  SBC HL,DE               ;
  EX DE,HL                ;
  POP HL                  ; The knight's V, the same
  LD BC,(KNIGHT_V)        ;
  LD A,(VIEW)             ;
  AND $01                 ;
  JR Z,PROJECT_CELL_1     ;
  LD A,C                  ;
  CPL                     ;
  LD C,A                  ;
  LD A,B                  ;
  CPL                     ;
  AND $1F                 ;
  LD B,A                  ;
PROJECT_CELL_1:
  AND A                   ; HL = dV
  SBC HL,BC               ;
  PUSH HL                 ;
  LD BC,$00F0             ; DRAW_X = (dU + dV + $F0) / 2
  ADD HL,DE               ;
  ADD HL,BC               ;
  SRA H                   ;
  RR L                    ;
  LD (DRAW_X),HL          ;
  POP HL                  ; DRAW_Y = (dV - dU + $1B0) / 4
  AND A                   ;
  SBC HL,DE               ;
  LD BC,$01B0             ;
  ADD HL,BC               ;
  SRA H                   ;
  RR L                    ;
  SRA H                   ;
  RR L                    ;
  LD (DRAW_Y),HL          ;
  RET

; The type of a cell of the town
;
; Used by the routines at DRAW_CELLS, DRAW_OUTLINE, DRAW_WALLS, PLACE_OBJECTS
; and PLACE_VILLAINS.
;
; Reads a cell from the map (TOWN, 32 rows of 32 bytes) and keeps its column
; and row in CELL_LOOKED_UP for PROJECT_CELL. The cell comes in the view's
; terms: with the town turned round the offset into the map is complemented and
; added to the address one past its end, which reads the map backwards from its
; last byte -- the same as turning the cell round with TURN_CELL. The listing
; would otherwise call that address DRAW_ORDER, the table that follows the map.
;
;   L the column
;   H the row
; O:A the cell's type: 0 open ground, 1 and 2 solid, 3 up built on
; O:F Z for open ground
LOOK_UP_CELL:
  LD (CELL_LOOKED_UP),HL  ; Kept for the projection
  LD A,L                  ; HL = the row times 32, plus the column
  LD L,H                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  OR L                    ;
  LD L,A                  ;
  LD BC,TOWN              ; Turned round?
  LD A,(VIEW)             ;
  AND $01                 ;
  JR Z,LOOK_UP_CELL_0     ;
  LD A,L                  ; The offset complemented, from one past the map's
  CPL                     ; end: the map read backwards
  LD L,A                  ;
  LD A,H                  ;
  CPL                     ;
  LD H,A                  ;
  LD BC,TOWN+$0400        ;
LOOK_UP_CELL_0:
  ADD HL,BC               ; The type; Z if open
  LD A,(HL)               ;
  AND A                   ;
  RET                     ;

; Look up a word in a table
;
; Used by the routines at DRAW_VILLAINS, EFFECT_NOTE, DRAW_OUTLINE,
; OUTLINE_NEAR_FACES, DRAW_EDGE, DRAW_WALLS, PUT_TILE, DISPATCH, HIT_BOXES_U,
; HIT_BOXES_V and TURN_SPRITE.
;
; HL = the word at BC + 2 * A. As Pentagram's TABLE_WORD.
;
;   A the index
;   BC the table
; O:HL the word
TABLE_WORD:
  LD L,A                  ; HL = BC + 2 * A
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD A,(HL)               ; The word there
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  RET                     ;

; Jump to the routine a table gives for A
;
; Used by the routines at NEW_GAME, MONSTER112_UPDATE, SORT_AND_DRAW_THINGS,
; KNIGHT_WALKS, STEER and MOVE_CLIPPED.
;
; The second piece of the tape's protection. Every table of routines in the
; game is reached through here -- the main loop's update of each object record
; by its graphic (UPDATES), the depth sort's outcomes (DEPTH_TABLE), a monster
; struck by an antibody (MONSTER_HIT_TABLE), and three small tables by the
; knight's facing (COAST_TABLE, TURN_TO_KNIGHT_TABLE, MOVE_TABLE) -- and the
; jump is not made here: the routine's address goes into HL and the game jumps
; to NMIADD, the system variable NMIADD, which holds JP (HL) only because the
; tape loaded that one byte there.
;
; The ROM leaves NMIADD at zero. Without the tape's byte the jump would run the
; system variables' own bytes as code, and the game would crash at the first
; update of its first turn: a copy that got past the check at START but left
; out the byte would still not play.
;
; The routine returns to DISPATCH's caller, or, where DISPATCH was jumped to,
; to its caller's caller.
;
; A the index
; BC the table
DISPATCH:
  CALL TABLE_WORD         ; HL = the routine (TABLE_WORD)
  JP NMIADD               ; JP (HL), by way of the tape's byte in NMIADD

; Update routines, by graphic
;
; 158 words, a routine for each graphic number, laid out by
; scripts/nightshade_data.py: the main loop (NEW_GAME) takes each object
; record's graphic (+0) and calls the routine the table gives through DISPATCH,
; with IX on the record. The graphics come in runs for one kind of thing, four
; frames or directions apiece, and a run shares its routine: 0 and 1, an empty
; record, and 23 and 31 do nothing (NO_UPDATE); 2 and 3 the two bonuses
; (SPEED_BONUS, HITS_BONUS); 4-7 an object lying (OBJECT_LYING) and 8-11 thrown
; (OBJECT_FLIGHT); 12-15 something vanishing (VANISHING); 16-21 and 24-29 the
; knight's legs (UPDATE_KNIGHT), 22 and 30 his top (UPDATE_TOP) and 32-47 his
; top as well, entered 21 bytes into it; 48-63 what is found in buildings
; (FIND_WANDER); 64-79 one kind of monster (WANDERING_MONSTER), 80-95
; antibodies in flight (ANTIBODY_FLIGHT), 96-111 the villains (VILLAIN_WANDER),
; 112-127 the other monsters (MONSTER112_UPDATE), 128-131 a monster appearing
; (APPEARING_UPDATE), 132-135 a villain dying (VILLAIN_DYING), drawn with the
; pictures of 12-15, 136-139 the creature (CREATURE_UPDATE), 140-143 a dead
; villain's sparkles (SPARKLE_FLY), drawn with the first pictures of the four
; kinds of find, those of 48, 52, 56 and 60; 144-157 the ending's pictures
; (ENDING_VILLAIN, ENDING_PIT_FRONT, the last five entered six bytes into it).
UPDATES:
  DEFW NO_UPDATE          ; Graphic 0
  DEFW NO_UPDATE          ; Graphic 1
  DEFW SPEED_BONUS        ; Graphic 2
  DEFW HITS_BONUS         ; Graphic 3
  DEFW OBJECT_LYING       ; Graphic 4
  DEFW OBJECT_LYING       ; Graphic 5
  DEFW OBJECT_LYING       ; Graphic 6
  DEFW OBJECT_LYING       ; Graphic 7
  DEFW OBJECT_FLIGHT      ; Graphic 8
  DEFW OBJECT_FLIGHT      ; Graphic 9
  DEFW OBJECT_FLIGHT      ; Graphic 10
  DEFW OBJECT_FLIGHT      ; Graphic 11
  DEFW VANISHING          ; Graphic 12
  DEFW VANISHING          ; Graphic 13
  DEFW VANISHING          ; Graphic 14
  DEFW VANISHING          ; Graphic 15
  DEFW UPDATE_KNIGHT      ; Graphic 16
  DEFW UPDATE_KNIGHT      ; Graphic 17
  DEFW UPDATE_KNIGHT      ; Graphic 18
  DEFW UPDATE_KNIGHT      ; Graphic 19
  DEFW UPDATE_KNIGHT      ; Graphic 20
  DEFW UPDATE_KNIGHT      ; Graphic 21
  DEFW UPDATE_TOP         ; Graphic 22
  DEFW NO_UPDATE          ; Graphic 23
  DEFW UPDATE_KNIGHT      ; Graphic 24
  DEFW UPDATE_KNIGHT      ; Graphic 25
  DEFW UPDATE_KNIGHT      ; Graphic 26
  DEFW UPDATE_KNIGHT      ; Graphic 27
  DEFW UPDATE_KNIGHT      ; Graphic 28
  DEFW UPDATE_KNIGHT      ; Graphic 29
  DEFW UPDATE_TOP         ; Graphic 30
  DEFW NO_UPDATE          ; Graphic 31
  DEFW TOP_FOLLOWS        ; Graphic 32
  DEFW TOP_FOLLOWS        ; Graphic 33
  DEFW TOP_FOLLOWS        ; Graphic 34
  DEFW TOP_FOLLOWS        ; Graphic 35
  DEFW TOP_FOLLOWS        ; Graphic 36
  DEFW TOP_FOLLOWS        ; Graphic 37
  DEFW TOP_FOLLOWS        ; Graphic 38
  DEFW TOP_FOLLOWS        ; Graphic 39
  DEFW TOP_FOLLOWS        ; Graphic 40
  DEFW TOP_FOLLOWS        ; Graphic 41
  DEFW TOP_FOLLOWS        ; Graphic 42
  DEFW TOP_FOLLOWS        ; Graphic 43
  DEFW TOP_FOLLOWS        ; Graphic 44
  DEFW TOP_FOLLOWS        ; Graphic 45
  DEFW TOP_FOLLOWS        ; Graphic 46
  DEFW TOP_FOLLOWS        ; Graphic 47
  DEFW FIND_WANDER        ; Graphic 48
  DEFW FIND_WANDER        ; Graphic 49
  DEFW FIND_WANDER        ; Graphic 50
  DEFW FIND_WANDER        ; Graphic 51
  DEFW FIND_WANDER        ; Graphic 52
  DEFW FIND_WANDER        ; Graphic 53
  DEFW FIND_WANDER        ; Graphic 54
  DEFW FIND_WANDER        ; Graphic 55
  DEFW FIND_WANDER        ; Graphic 56
  DEFW FIND_WANDER        ; Graphic 57
  DEFW FIND_WANDER        ; Graphic 58
  DEFW FIND_WANDER        ; Graphic 59
  DEFW FIND_WANDER        ; Graphic 60
  DEFW FIND_WANDER        ; Graphic 61
  DEFW FIND_WANDER        ; Graphic 62
  DEFW FIND_WANDER        ; Graphic 63
  DEFW WANDERING_MONSTER  ; Graphic 64
  DEFW WANDERING_MONSTER  ; Graphic 65
  DEFW WANDERING_MONSTER  ; Graphic 66
  DEFW WANDERING_MONSTER  ; Graphic 67
  DEFW WANDERING_MONSTER  ; Graphic 68
  DEFW WANDERING_MONSTER  ; Graphic 69
  DEFW WANDERING_MONSTER  ; Graphic 70
  DEFW WANDERING_MONSTER  ; Graphic 71
  DEFW WANDERING_MONSTER  ; Graphic 72
  DEFW WANDERING_MONSTER  ; Graphic 73
  DEFW WANDERING_MONSTER  ; Graphic 74
  DEFW WANDERING_MONSTER  ; Graphic 75
  DEFW WANDERING_MONSTER  ; Graphic 76
  DEFW WANDERING_MONSTER  ; Graphic 77
  DEFW WANDERING_MONSTER  ; Graphic 78
  DEFW WANDERING_MONSTER  ; Graphic 79
  DEFW ANTIBODY_FLIGHT    ; Graphic 80
  DEFW ANTIBODY_FLIGHT    ; Graphic 81
  DEFW ANTIBODY_FLIGHT    ; Graphic 82
  DEFW ANTIBODY_FLIGHT    ; Graphic 83
  DEFW ANTIBODY_FLIGHT    ; Graphic 84
  DEFW ANTIBODY_FLIGHT    ; Graphic 85
  DEFW ANTIBODY_FLIGHT    ; Graphic 86
  DEFW ANTIBODY_FLIGHT    ; Graphic 87
  DEFW ANTIBODY_FLIGHT    ; Graphic 88
  DEFW ANTIBODY_FLIGHT    ; Graphic 89
  DEFW ANTIBODY_FLIGHT    ; Graphic 90
  DEFW ANTIBODY_FLIGHT    ; Graphic 91
  DEFW ANTIBODY_FLIGHT    ; Graphic 92
  DEFW ANTIBODY_FLIGHT    ; Graphic 93
  DEFW ANTIBODY_FLIGHT    ; Graphic 94
  DEFW ANTIBODY_FLIGHT    ; Graphic 95
  DEFW VILLAIN_WANDER     ; Graphic 96
  DEFW VILLAIN_WANDER     ; Graphic 97
  DEFW VILLAIN_WANDER     ; Graphic 98
  DEFW VILLAIN_WANDER     ; Graphic 99
  DEFW VILLAIN_WANDER     ; Graphic 100
  DEFW VILLAIN_WANDER     ; Graphic 101
  DEFW VILLAIN_WANDER     ; Graphic 102
  DEFW VILLAIN_WANDER     ; Graphic 103
  DEFW VILLAIN_WANDER     ; Graphic 104
  DEFW VILLAIN_WANDER     ; Graphic 105
  DEFW VILLAIN_WANDER     ; Graphic 106
  DEFW VILLAIN_WANDER     ; Graphic 107
  DEFW VILLAIN_WANDER     ; Graphic 108
  DEFW VILLAIN_WANDER     ; Graphic 109
  DEFW VILLAIN_WANDER     ; Graphic 110
  DEFW VILLAIN_WANDER     ; Graphic 111
  DEFW MONSTER112_UPDATE  ; Graphic 112
  DEFW MONSTER112_UPDATE  ; Graphic 113
  DEFW MONSTER112_UPDATE  ; Graphic 114
  DEFW MONSTER112_UPDATE  ; Graphic 115
  DEFW MONSTER112_UPDATE  ; Graphic 116
  DEFW MONSTER112_UPDATE  ; Graphic 117
  DEFW MONSTER112_UPDATE  ; Graphic 118
  DEFW MONSTER112_UPDATE  ; Graphic 119
  DEFW MONSTER112_UPDATE  ; Graphic 120
  DEFW MONSTER112_UPDATE  ; Graphic 121
  DEFW MONSTER112_UPDATE  ; Graphic 122
  DEFW MONSTER112_UPDATE  ; Graphic 123
  DEFW MONSTER112_UPDATE  ; Graphic 124
  DEFW MONSTER112_UPDATE  ; Graphic 125
  DEFW MONSTER112_UPDATE  ; Graphic 126
  DEFW MONSTER112_UPDATE  ; Graphic 127
  DEFW APPEARING_UPDATE   ; Graphic 128
  DEFW APPEARING_UPDATE   ; Graphic 129
  DEFW APPEARING_UPDATE   ; Graphic 130
  DEFW APPEARING_UPDATE   ; Graphic 131
  DEFW VILLAIN_DYING      ; Graphic 132
  DEFW VILLAIN_DYING      ; Graphic 133
  DEFW VILLAIN_DYING      ; Graphic 134
  DEFW VILLAIN_DYING      ; Graphic 135
  DEFW CREATURE_UPDATE    ; Graphic 136
  DEFW CREATURE_UPDATE    ; Graphic 137
  DEFW CREATURE_UPDATE    ; Graphic 138
  DEFW CREATURE_UPDATE    ; Graphic 139
  DEFW SPARKLE_FLY        ; Graphic 140
  DEFW SPARKLE_FLY        ; Graphic 141
  DEFW SPARKLE_FLY        ; Graphic 142
  DEFW SPARKLE_FLY        ; Graphic 143
  DEFW ENDING_VILLAIN     ; Graphic 144
  DEFW ENDING_VILLAIN     ; Graphic 145
  DEFW ENDING_VILLAIN     ; Graphic 146
  DEFW ENDING_VILLAIN     ; Graphic 147
  DEFW ENDING_VILLAIN     ; Graphic 148
  DEFW ENDING_VILLAIN     ; Graphic 149
  DEFW ENDING_VILLAIN     ; Graphic 150
  DEFW ENDING_VILLAIN     ; Graphic 151
  DEFW ENDING_PIT_FRONT   ; Graphic 152
  DEFW ENDING_PICTURE     ; Graphic 153
  DEFW ENDING_PICTURE     ; Graphic 154
  DEFW ENDING_PICTURE     ; Graphic 155
  DEFW ENDING_PICTURE     ; Graphic 156
  DEFW ENDING_PICTURE     ; Graphic 157

; An update routine that does nothing
;
; For graphics 0 and 1 -- an empty record, and the empty sprite -- and 23 and
; 31 (UPDATES). As Alien 8's NO_UPDATE.
NO_UPDATE:
  RET

; Send four sparkles out from a villain destroyed
;
; Used by the routine at OBJECT_FLIGHT.
;
; Called by the thrown object's update (OBJECT_FLIGHT) when it strikes its
; villain. The four records at FINDS become sparkles, graphic 140 (SPARKLE_FLY
; moves them), at the villain's U and V, each facing a different way so that
; they fly apart: a speed of 12, half-sizes of 16 and the drawing offset things
; of that size have. Graphics 140-143 share their sprites with the first frames
; of the four kinds of find (48, 52, 56 and 60), so the sparkles show the
; finds' pictures. Whatever the four records held -- things found in buildings
; and not yet picked up -- is lost. The flags (+7), the step (+A, +B) and where
; each was drawn (+E, +F) are left as they were. The ending waits for the
; sparkles to finish (CHECK_QUEST_DONE).
;
; IY the villain's record
VILLAIN_SPARKLES:
  LD HL,FINDS             ; The four records at FINDS
  LD B,$04                ;
VILLAIN_SPARKLES_0:
  LD (HL),$8C             ; Graphic 140
  INC HL                   ; U and V (+1 to +4), the villain's
  PUSH IY                  ;
  POP DE                   ;
  INC DE                   ;
  LD C,$04                 ;
VILLAIN_SPARKLES_1:
  LD A,(DE)                ;
  INC DE                   ;
  LD (HL),A                ;
  INC HL                   ;
  DEC C                    ;
  JR NZ,VILLAIN_SPARKLES_1 ;
  LD (HL),$0C             ; Speed (+5) 12
  INC HL                  ; Facing (+6, bits 6-7): 3, 2, 1 and 0 for the four
  LD A,B                  ; records, so they fly apart
  DEC A                   ;
  RRCA                    ;
  RRCA                    ;
  AND $C0                 ;
  LD (HL),A               ;
  INC HL                  ; Half-sizes (+8, +9) 16 and 16
  INC HL                  ;
  LD (HL),$10             ;
  INC HL                  ;
  LD (HL),$10             ;
  INC HL                  ; Drawing offset (+C, +D): 12 left and 4 up
  INC HL                  ;
  INC HL                  ;
  LD (HL),$F4             ;
  INC HL                  ;
  LD (HL),$04             ;
  INC HL                  ; On to the next record
  INC HL                  ;
  INC HL                  ;
  DJNZ VILLAIN_SPARKLES_0 ;
  RET                     ;

; The update routine for a sparkle from a destroyed villain (graphics 140-143)
;
; The four records at FINDS become sparkles when a villain is struck by its
; object (VILLAIN_SPARKLES sets them up: each at the villain's place, speed 12,
; one facing each way). Each flies straight on at its speed, cycling through
; its four pictures -- the four kinds of antibody's first frames, which the
; graphic table gives graphics 140-143 -- until it meets a wall, where it
; vanishes. The quest ends only when no sparkle is still on the screen
; (CHECK_QUEST_DONE).
;
; IX The sparkle's record
SPARKLE_FLY:
  RES 1,(IX+$07)          ; Clear the drawn flag: the drawing sets it again if
                          ; the sparkle is still on the screen, which
                          ; CHECK_QUEST_DONE waits for
  LD A,(IX+$05)           ; Take the step from the speed and the facing, trim
  CALL SET_STEP           ; it against the town's walls and move
  CALL MOVE_CLIPPED       ;
  CALL APPLY_STEP         ;
  CALL NEXT_FRAME_MOD4    ; Next picture of the four
  BIT 0,(IX+$07)          ; Done unless the move was stopped by a wall...
  RET Z                   ;
  LD (IX+$00),$0C         ; ...in which case it vanishes (VANISHING)
  RET                     ;

; The update routine for the bonus of graphic 2: a faster walk
;
; A bonus lies only while the knight is within three cells of it, in both
; directions; further away it is gone, and PLACE_BONUS will place another.
; Touched, it gives him a top speed of 18 for 255 of his turns (SPEED_TIME,
; counted down by UPDATE_KNIGHT) and sound effect 1 for five turns.
;
; IX The bonus's record (BONUS)
SPEED_BONUS:
  LD C,$04                ; Is the knight within three cells of it (fewer than
  CALL NEAR_KNIGHT        ; four columns and four rows away)?
  JR C,SPEED_BONUS_0      ;
  LD (IX+$00),$00         ; No: the bonus is gone, without a trace
  RET                     ;
SPEED_BONUS_0:
  CALL TOUCHING_KNIGHT    ; Yes: done unless he is touching it
  RET NC                  ;
  LD (IX+$00),$0C         ; Touched: it vanishes (VANISHING)
  LD A,$FF                ; The faster walk lasts 255 turns
  LD (SPEED_TIME),A       ;
  LD A,$12                ; Top speed 18 instead of 10
  LD (TOP_SPEED),A        ;
  LD HL,$0105             ; Sound effect 1, for five turns
  LD (EFFECT_TIME),HL     ;
  RET                     ;

; The update routine for the bonus of graphic 3: all three hits back
;
; The same as SPEED_BONUS, except that touching it gives the knight back all
; three hits of this life (HITS), with sound effect 2 for seven turns. Drawn by
; the build, the picture is a flask.
;
; IX The bonus's record (BONUS)
HITS_BONUS:
  LD C,$04                ; Is the knight within three cells of it?
  CALL NEAR_KNIGHT        ;
  JR C,HITS_BONUS_0       ;
  LD (IX+$00),$00         ; No: the bonus is gone
  RET                     ;
HITS_BONUS_0:
  CALL TOUCHING_KNIGHT    ; Yes: done unless he is touching it
  RET NC                  ;
  LD (IX+$00),$0C         ; Touched: it vanishes (VANISHING)
  LD A,$03                ; Three hits again
  LD (HITS),A             ;
  LD HL,$0207             ; Sound effect 2, for seven turns
  LD (EFFECT_TIME),HL     ;
  RET                     ;

; Put a bonus near the knight when there is none
;
; Used by the routine at NEW_GAME.
;
; Called by the main loop every turn (NEW_GAME). When the bonus record is empty
; it picks a cell: the knight's own column or the one four to its right (the
; random number's bits 0-2 masked with $FC leave only 0 or 4), and a row from
; four above his to three below. If that cell is not solid (types 1 and 2) and
; is not within one cell of the knight, the bonus goes there, at a random place
; in the middle half of the cell, as graphic 2 or 3 by whether the turn count
; is even or odd.
;
; So a bonus is almost always about: the moment one is taken, or left behind by
; more than three cells (SPEED_BONUS), the next turn tries again. One placed
; four columns to the right is outside the three cells SPEED_BONUS keeps it
; within, so it goes again on its first update, unless the knight has moved
; towards it; so does one placed four rows up. Measured in the simulator with
; the knight standing in cell (16,16): of 330 placements only those in his own
; column two or three rows away outlasted their first update, and a bonus was
; there in every one of 300 turns left alone.
;
; The column is wrapped to the town's 32 but the row is looked up before it is
; wrapped, so a knight in the top four or bottom three rows has the bonus's
; cell looked up outside the map (PLACE_IN_CELL, from offset 41, adds the row
; times 32 to the map's address as it is); only the stored row is wrapped.
PLACE_BONUS:
  LD IX,BONUS             ; Nothing to do while there is a bonus (or its
  LD A,(IX+$00)           ; vanishing)
  AND A                   ;
  RET NZ                  ;
  CALL STIR_RANDOM        ; Stir the random number
  LD A,(KNIGHT_COLUMN)    ; L=the knight's column, H=his row
  LD L,A                  ;
  LD A,(KNIGHT_ROW)       ;
  LD H,A                  ;
  LD A,(RANDOM)           ; Column: his own or four to the right, wrapped to
  AND $07                 ; 0-31
  AND $FC                 ;
  ADD A,L                 ;
  AND $1F                 ;
  LD L,A                  ;
  LD (IX+$02),A           ;
  LD A,($BBAB)            ; Row: four above his to three below; the stored row
  AND $07                 ; is wrapped, H is not
  ADD A,$FC               ;
  ADD A,H                 ;
  LD H,A                  ;
  AND $1F                 ;
  LD (IX+$04),A           ;
  CALL TOWN_CELL          ; Look the cell up (L column, H row); no bonus in a
  DEC A                   ; solid cell (type 1 or 2)
  CP $02                  ;
  RET C                   ;
  LD C,$02                ; None within one cell of the knight, either
  CALL NEAR_KNIGHT        ;
  RET C                   ;
  LD A,(TURNS)            ; Graphic 2 on an even turn, 3 on an odd one
  AND $01                 ;
  OR $02                  ;
  LD (IX+$00),A           ;
  LD A,(RANDOM)           ; A random place in the middle half of the cell, U
  AND $7F                 ; and V 64-191
  ADD A,$40               ;
  LD (IX+$01),A           ;
  LD A,($BBAB)            ;
  AND $7F                 ;
  ADD A,$40               ;
  LD (IX+$03),A           ;
  LD (IX+$08),$10         ; Half-size 16 each way
  LD (IX+$09),$10         ;
  LD (IX+$0C),$F4         ; The drawing offset
  LD (IX+$0D),$04         ;
  RET                     ;

; The update routine for something vanishing (graphics 12-15)
;
; Whatever is taken up, destroyed or killed -- a bonus, a find, an object
; thrown at nothing, the knight himself -- becomes graphic 12, a small cloud,
; and goes through graphics 12 to 15 one a turn; after 15 its record is empty.
; If the last frame was on the screen, PUFF_SOUND makes the crackle of its
; going.
;
; IX The record
VANISHING:
  INC (IX+$00)            ; Next frame; after 15 the low two bits come round to
  LD A,(IX+$00)           ; 0...
  AND $03                 ;
  JR NZ,VANISHING_0       ;
  LD (IX+$00),A           ; ...and the record is emptied (A is 0), with the
  JP PUFF_SOUND           ; crackle if it was seen
VANISHING_0:
  RES 1,(IX+$07)          ; Clear the drawn flag, which the drawing sets again
  RET                     ;

; The update routine for an antibody in flight (graphics 80-95)
;
; An antibody thrown by the knight (KNIGHT_THROWS) flies straight on at speed
; 12, moving twice a turn, and vanishes at the first wall. It does not look for
; its targets: the monsters' own routines test for an antibody touching them
; (MONSTER112_UPDATE, WANDERING_MONSTER, CREATURE_UPDATE). Its four frames
; animate through the low two bits of the graphic.
;
; The second move is made from MOVE_CLIPPED's second entry, which does not
; clear the wall flag, so a wall met on the first move still ends it.
;
; IX The antibody's record (ANTIBODIES)
ANTIBODY_FLIGHT:
  LD A,(IX+$05)           ; The step from the speed and the facing
  CALL SET_STEP           ;
  CALL NEXT_FRAME_MOD4    ; Next frame
  CALL MOVE_CLIPPED       ; Move, trimmed at a wall...
  CALL APPLY_STEP         ;
  CALL MOVE_CLIPPED_AGAIN ; ...and again, keeping the wall flag
  CALL APPLY_STEP         ;
  BIT 0,(IX+$07)          ; Done unless it met a wall...
  RET Z                   ;
  LD (IX+$00),$0C         ; ...where it vanishes
  RET                     ;

; The update routine for a thrown object (graphics 8-11)
;
; An object the knight has thrown (KNIGHT_THROWS) flies straight on at speed
; 12, twice a turn like an antibody, until it strikes a villain or a wall. The
; only villain it can strike is the one in the record 64 bytes on from its own
; (OBJECT_STRIKE): the object in record n of OBJECTS and the villain in record
; n of VILLAINS are a pair, and the other three pass through each other. A wall
; leaves the object lying where it stopped (graphics 4-7, the same object), to
; be taken up again.
;
; A strike turns the villain into graphic 132, dying (VILLAIN_DYING), and the
; object into the vanishing cloud; scores 250000 (BC = $2500, shown with the
; score's two dead zeros); lets out the four sparkles from the villain's place
; (VILLAIN_SPARKLES); and redraws the villains on the panel (DRAW_VILLAINS),
; where the dead one is now drawn as a picture in the colour of the object that
; killed it, not an outline (seen in the quest run: the skeleton in cyan after
; the first kill).
;
; IX The object's record (OBJECTS)
OBJECT_FLIGHT:
  LD A,(IX+$05)           ; The step from the speed and the facing
  CALL SET_STEP           ;
  CALL MOVE_CLIPPED       ; Move twice, trimmed at a wall, the wall flag kept
  CALL APPLY_STEP         ; from the first
  CALL MOVE_CLIPPED_AGAIN ;
  CALL APPLY_STEP         ;
  CALL OBJECT_STRIKE      ; Is it touching its own villain, four records on?
  JR C,OBJECT_FLIGHT_0    ; (IY points to that record)
  BIT 0,(IX+$07)          ; No: done unless it met a wall
  RET Z                   ;
  LD A,(IX+$00)           ; At a wall it falls: graphic 8-11 becomes 4-7, the
  AND $03                 ; same object lying
  OR $04                  ;
  LD (IX+$00),A           ;
  RET                     ;
OBJECT_FLIGHT_0:
  LD (IY+$00),$84         ; Struck: the villain is dying
  LD (IX+$00),$0C         ; The object vanishes
  LD BC,$2500             ; 250000 points as shown
  CALL ADD_SCORE          ;
  CALL VILLAIN_SPARKLES   ; Four sparkles from where the villain was
  JP DRAW_VILLAINS        ; Redraw the panel's villains, the dead one blanked

; The update routine for a dying villain (graphics 132-135)
;
; Flashes the play area's paper through all eight colours, one a turn, for as
; long as it lasts (FLASH is cleared at the end of every turn, so the flash
; stops when this does), and steps through its four frames on odd turns only:
; struck on an even turn it shows 132 and then two turns each of 133-135, seven
; turns; struck on an odd one it goes straight to 133, six (measured in both
; parities). The record is empty the turn after. The graphic table draws
; 132-135 with the vanishing cloud's pictures.
;
; IX The villain's record (VILLAINS)
VILLAIN_DYING:
  LD A,(TURNS)            ; The paper colour from the turn count's low three
  RLCA                    ; bits
  RLCA                    ;
  RLCA                    ;
  AND $38                 ;
  LD (FLASH),A            ;
  LD A,(TURNS)            ; A new frame only on odd turns
  AND $01                 ;
  RET Z                   ;
  INC (IX+$00)            ; Next frame; after 135 the low two bits come round
  LD A,(IX+$00)           ; to 0...
  AND $03                 ;
  RET NZ                  ;
  LD (IX+$00),A           ; ...and the record is emptied
  RET                     ;

; End the game when the four villains are gone and their sparkles have left the
; screen
;
; Used by the routine at NEW_GAME.
;
; Called by the main loop every turn (NEW_GAME). Returns while any villain
; record is in use (a dying villain counts), or while any sparkle (SPARKLE_FLY)
; was drawn this turn; otherwise the game is over with the quest done, and
; GAME_OVER plays the ending. A sparkle off the screen is not waited for.
CHECK_QUEST_DONE:
  LD HL,VILLAINS          ; Any of the four villain records in use? Then not
  LD DE,$0010             ; yet
  LD B,$04                ;
  XOR A                   ;
CHECK_QUEST_DONE_0:
  OR (HL)                 ;
  ADD HL,DE               ;
  DJNZ CHECK_QUEST_DONE_0 ;
  RET NZ                  ;
  LD IX,FINDS             ; Look through the four sparkle records
  LD B,$04                ;
CHECK_QUEST_DONE_1:
  LD A,(IX+$00)            ; Is this one a sparkle, graphic 140-143?
  SUB $8C                  ;
  CP $04                   ;
  JR NC,CHECK_QUEST_DONE_2 ;
  BIT 1,(IX+$07)          ; Still on the screen: not yet
  RET NZ                  ;
CHECK_QUEST_DONE_2:
  ADD IX,DE               ; Next record
  DJNZ CHECK_QUEST_DONE_1 ;
  JP GAME_OVER            ; The villains are gone: game over, with the ending

; Put the four objects in random cells at a new game
;
; Used by the routine at NEW_GAME.
;
; Called at a new game (NEW_GAME). The random number's low 12 bits give an
; address in the ROM, and the bytes from there are read in pairs as a column
; and a row (each masked to 0-31) until one is a cell a knight can stand in --
; not type 1 or 2. Each object gets a copy of OBJECT_RECORD, the cell, and its
; graphic: 7, 6, 5 and 4 for records 0 to 3, so that thing 1 (PICK_UP_THING
; takes graphic 4 as thing 1) is the object in record 3. Nothing stops two
; objects, or an object and a villain, sharing a cell.
PLACE_OBJECTS:
  CALL NEXT_TURN          ; Advance the turn count and stir the random number
  LD IY,OBJECTS           ; Four records from OBJECTS
  LD B,$04                ;
  LD DE,(RANDOM)          ; DE: an address in the ROM, from the random number
  LD A,D                  ;
  AND $0F                 ;
  LD D,A                  ;
PLACE_OBJECTS_0:
  LD A,(DE)               ; Read a column and a row from it
  INC DE                  ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,(DE)               ;
  INC DE                  ;
  AND $1F                 ;
  LD H,A                  ;
  PUSH BC                 ; Look the cell up; try the next pair if it is solid
  PUSH HL                 ; (type 1 or 2)
  CALL LOOK_UP_CELL       ;
  POP HL                  ;
  POP BC                  ;
  DEC A                   ;
  CP $02                  ;
  JR C,PLACE_OBJECTS_0    ;
  PUSH BC                 ; Copy OBJECT_RECORD into the record, and point IY at
  PUSH DE                 ; the next one
  PUSH HL                 ;
  LD HL,OBJECT_RECORD     ;
  LD BC,$0010             ;
  PUSH IY                 ;
  POP DE                  ;
  ADD IY,BC               ;
  LDIR                    ;
  POP HL                  ; Graphic 3 plus the count: 7 for record 0 down to 4
  POP DE                  ; for record 3
  POP BC                  ;
  LD A,B                  ;
  ADD A,$03               ;
  LD (IY-$10),A           ;
  LD (IY-$0E),L           ; The cell's column and row, at its middle (the low
  LD (IY-$0C),H           ; bytes are 128 from the copy)
  DJNZ PLACE_OBJECTS_0    ; Next record
  RET                     ;

; What each of the four objects starts as
;
; Copied into each object's record by PLACE_OBJECTS, which then gives it its
; graphic and cell: the middle of the cell, standing still, half-size 8 each
; way. A thrown object is a copy of the knight's legs' record instead
; (KNIGHT_THROWS).
OBJECT_RECORD:
  DEFB $00                ; Object+0 graphic: 0
  DEFB $80                ; Object+1 U, low byte: 128
  DEFB $00                ; Object+2 U, high byte (the cell): 0
  DEFB $80                ; Object+3 V, low byte: 128
  DEFB $00                ; Object+4 V, high byte (the cell): 0
  DEFB $00                ; Object+5 speed: 0
  DEFB $00                ; Object+6 facing and turn count: 0
  DEFB $00                ; Object+7 flags: 0
  DEFB $08                ; Object+8 half-size in U: 8
  DEFB $08                ; Object+9 half-size in V: 8
  DEFB $00                ; Object+A step in U: 0
  DEFB $00                ; Object+B step in V: 0
  DEFB $F4                ; Object+C drawing offset x: 244
  DEFB $04                ; Object+D drawing offset y: 4
  DEFB $00                ; Object+E screen x: 0
  DEFB $00                ; Object+F screen y: 0

; Put the four villains in random cells at a new game
;
; Used by the routine at NEW_GAME.
;
; The same as PLACE_OBJECTS, with VILLAIN_RECORD and the villains' graphics:
; 108, 104, 100 and 96 for records 0 to 3 (four pictures each, FACING_PICTURE).
; Called just before it, and each call advances the turn count and stirs the
; random number, so the two start from different places in the ROM. A villain
; can be placed in the knight's first cell; he then dies there as he appears,
; as often as he comes back.
PLACE_VILLAINS:
  CALL NEXT_TURN          ; Advance the turn count and stir the random number
  LD IY,VILLAINS          ; Four records from VILLAINS
  LD B,$04                ;
  LD DE,(RANDOM)          ; DE: an address in the ROM, from the random number
  LD A,D                  ;
  AND $0F                 ;
  LD D,A                  ;
PLACE_VILLAINS_0:
  LD A,(DE)               ; Read a column and a row from it
  INC DE                  ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,(DE)               ;
  INC DE                  ;
  AND $1F                 ;
  LD H,A                  ;
  PUSH BC                 ; Look the cell up; try the next pair if it is solid
  PUSH HL                 ; (type 1 or 2)
  CALL LOOK_UP_CELL       ;
  POP HL                  ;
  POP BC                  ;
  DEC A                   ;
  CP $02                  ;
  JR C,PLACE_VILLAINS_0   ;
  PUSH BC                 ; Copy VILLAIN_RECORD into the record, and point IY
  PUSH DE                 ; at the next one
  PUSH HL                 ;
  LD HL,VILLAIN_RECORD    ;
  LD BC,$0010             ;
  PUSH IY                 ;
  POP DE                  ;
  ADD IY,BC               ;
  LDIR                    ;
  POP HL                  ; Graphic 4 times the count plus 92: 108 for record 0
  POP DE                  ; down to 96 for record 3
  POP BC                  ;
  LD A,B                  ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,$5C               ;
  LD (IY-$10),A           ;
  LD (IY-$0E),L           ; The cell's column and row
  LD (IY-$0C),H           ;
  DJNZ PLACE_VILLAINS_0   ; Next record
  RET                     ;

; What each of the four villains starts as
;
; Copied into each villain's record by PLACE_VILLAINS, which then gives it its
; graphic and cell: the middle of the cell, speed 4, facing +V, half-size 16
; each way. Its flags are 0 and nothing sets bit 5, so no villain ever homes in
; on the knight (STEER).
VILLAIN_RECORD:
  DEFB $00                ; Villain+0 graphic: 0
  DEFB $80                ; Villain+1 U, low byte: 128
  DEFB $00                ; Villain+2 U, high byte (the cell): 0
  DEFB $80                ; Villain+3 V, low byte: 128
  DEFB $00                ; Villain+4 V, high byte (the cell): 0
  DEFB $04                ; Villain+5 speed: 4
  DEFB $00                ; Villain+6 facing and turn count: 0
  DEFB $00                ; Villain+7 flags: 0
  DEFB $10                ; Villain+8 half-size in U: 16
  DEFB $10                ; Villain+9 half-size in V: 16
  DEFB $00                ; Villain+A step in U: 0
  DEFB $00                ; Villain+B step in V: 0
  DEFB $F4                ; Villain+C drawing offset x: 244
  DEFB $04                ; Villain+D drawing offset y: 4
  DEFB $00                ; Villain+E screen x: 0
  DEFB $00                ; Villain+F screen y: 0

; The update routine for an object lying in the town (graphics 4-7)
;
; Waits to be touched. Touched, it makes sound effect 3 for four turns and is
; taken up (PICK_UP_THING) into the first free place of the eleven the knight
; carries; with all eleven full, PICK_UP_THING returns without taking it and it
; stays where it lies.
;
; IX The object's record (OBJECTS)
OBJECT_LYING:
  CALL TOUCHING_KNIGHT    ; Done unless the knight is touching it
  RET NC                  ;
  LD HL,$0304             ; Sound effect 3, for four turns
  LD (EFFECT_TIME),HL     ;
  JP PICK_UP_THING        ; Take it up

; The update routine for a villain (graphics 96-111)
;
; A villain walks at speed 4, turning left or right at random when it meets a
; wall and every so often besides (STEER), and kills the knight at a touch: not
; a hit off his three but the whole life (WANDERING_MONSTER from offset 59,
; which also keeps his cell for the next life). Only its own object destroys it
; (OBJECT_FLIGHT).
;
; While it is on the screen it hums (BLIP_BY_TURN, from offset 3): twelve
; pulses a turn at a pitch read from a 16-byte table by the turn count. The
; table was meant to be one of the four that follow the creature's
; (BLIP_PITCHES), one per villain, but that routine builds the address from BC
; alone and throws away the table's address loaded into HL here; and the offset
; in BC is not 0, 16, 32 or 48 but 128, 144, 160 or 176, since the graphic's
; bit 5 lands in bit 7, which the AND $F0 keeps (AND $30 would have been
; right). So the pitches come from the ROM's bytes $0080-$00BF, and the four
; tables are never read. Measured in the simulator: with each villain put
; beside the knight, the pitch was read from $00BB, $00AD, $009F and $0081 for
; the villains of graphics 108, 104, 100 and 96.
;
; IX The villain's record (VILLAINS)
VILLAIN_WANDER:
  LD A,(IX+$00)           ; BC: the graphic's bits 2-3 times 16, plus 128 from
  RLCA                    ; its bit 5 (meant as an offset into the villains'
  RLCA                    ; tables)
  AND $F0                 ;
  LD C,A                  ;
  LD B,$00                ;
  LD HL,VILLAIN_PITCHES   ; The hum, if it was drawn last turn; the table's
  CALL BLIP_FROM_TABLE    ; address in HL is overwritten there, so BC alone is
                          ; the address: the ROM
  LD A,(IX+$05)           ; The step from the speed and the facing; trim it at
  CALL SET_STEP           ; a wall; move
  CALL MOVE_CLIPPED       ;
  CALL APPLY_STEP         ;
  CALL STEER              ; Decide whether to turn
  CALL FACING_PICTURE     ; Its picture for the facing
  CALL TOUCHING_KNIGHT    ; Done unless it touches the knight...
  RET NC                  ;
  JP KNIGHT_KILLED        ; ...who dies, and will start his next life where he
                          ; stands

; Set a villain's or a monster's picture for its facing
;
; Used by the routines at MONSTER112_UPDATE and VILLAIN_WANDER.
;
; A villain has two pictures, one for facing +V or -U and one for +U or -V (bit
; 1 of its graphic), and each is mirrored for the U facings (bit 6 of +7, from
; the facing's bit 6); bit 0 is toggled every turn, the walking frame. With the
; town turned round (VIEW) bit 1 is flipped, since the knight then sees the
; villain's other side. Used for the monsters of graphics 112-127 too
; (MONSTER112_UPDATE).
;
; IX The record
FACING_PICTURE:
  LD A,(VIEW)             ; B: 2 if the town is turned round
  ADD A,A                 ;
  LD B,A                  ;
  LD A,(IX+$06)           ; C: 2 for facing +V or -U, 0 for +U or -V
  SUB $40                 ;
  RLCA                    ;
  RLCA                    ;
  AND $02                 ;
  LD C,A                  ;
  LD A,(IX+$00)           ; Bit 1 of the graphic from C, flipped by the view;
  AND $FD                 ; bit 0 toggled
  OR C                    ;
  XOR $01                 ;
  XOR B                   ;
  LD (IX+$00),A           ;
  LD A,(IX+$06)           ; Mirrored when facing along U
  AND $40                 ;
  LD C,A                  ;
  LD A,(IX+$07)           ;
  AND $BF                 ;
  OR C                    ;
  LD (IX+$07),A           ;
  RET                     ;

; The update routine for a find in a building (graphics 48-63)
;
; A find is one of the four kinds of antibody (SPAWN_FIND makes it, from the
; cell's type), and is there only while the knight is in its cell. It wanders
; at random (WANDER_STEP, steps of up to 8 each way) and, touched, is taken up
; (PICK_UP_THING) as thing 5-8 and vanishes -- even with all eleven places
; full, when it is simply lost.
;
; If the knight leaves the cell, or dies, it vanishes and is given back to its
; cell type's stock (STOCKS), so it can be found there again. Its +5 holds the
; cell type, not a speed, and +6 its turns to the next change of course.
;
; IX The find's record (FINDS)
FIND_WANDER:
  LD A,(KNIGHT)           ; Is the knight alive (graphics 16-47)?
  SUB $10                 ;
  CP $20                  ;
  JR NC,FIND_WANDER_0     ;
  LD A,(KNIGHT_COLUMN)    ; And still in its cell?
  CP (IX+$02)             ;
  JR NZ,FIND_WANDER_1     ;
  LD A,(KNIGHT_ROW)       ;
  CP (IX+$04)             ;
  JR NZ,FIND_WANDER_1     ;
  LD B,$04                ; Yes: now and then a new random step, of up to 8
  CALL WANDER_STEP        ; each way
  CALL MOVE_SPLIT         ; Move along U and then V, trimmed at walls
  CALL APPLY_STEP         ;
  CALL NEXT_FRAME_MOD4    ; Next frame
  CALL TOUCHING_KNIGHT    ; Done unless the knight touches it
  RET NC                  ;
  CALL PICK_UP_THING      ; Take it up, and it vanishes (full or not)
  LD (IX+$00),$0C         ;
  RET                     ;
FIND_WANDER_0:
  LD (IX+$00),$0D         ; The knight is dead: vanish, from the second
  JR FIND_WANDER_2        ; frame...
FIND_WANDER_1:
  LD (IX+$00),$0C         ; He has left the cell: vanish
FIND_WANDER_2:
  LD C,(IX+$05)           ; Either way, one more to be found in a cell of its
  LD B,$00                ; type
  LD HL,STOCKS            ;
  ADD HL,BC               ;
  INC (HL)                ;
  RET                     ;

; The update routine for the knight's top (graphics 22, 30, 32-47)
;
; The knight is two records: his legs (KNIGHT), which walk and turn
; (UPDATE_KNIGHT), and his top here (KNIGHT_TOP), drawn over them. The top
; follows the legs: it takes their place each turn, and a picture matching
; theirs -- graphic 32-37 for the walking frames 16-21 seen from behind, 40-45
; for the ones from the front, 24-29, face showing. Now and then (one turn in
; 32 while he is not turning) it shows one of two other poses instead for two
; to nine turns: 38 or 39 from behind, 46 or 47 from the front.
;
; When his legs meet a wall the top shows graphic 22 or 30, arms thrown out,
; with the bump sound (BUMP_SOUND), and stays where it is. From graphic 22 or
; 30 the table enters at the start and checks the wall first; from 32-47 it
; enters at offset 21 (TOP_FOLLOWS), which copies the place first.
;
; IX The top's record; IX-16 the legs'
UPDATE_TOP:
  LD A,(IX-$09)           ; Did the legs meet a wall this turn?
  BIT 0,A                 ;
  JR Z,TOP_FOLLOWS        ;
  LD (IX+$07),A           ; Yes: the legs' flags, and graphic 22 or 30 by the
  LD A,(IX-$10)           ; legs' view (from behind or the front); stay put
  AND $F8                 ;
  OR $06                  ;
  LD (IX+$00),A           ;
  RET                     ;
TOP_FOLLOWS:
  PUSH IX                 ; Copy the legs' place and speed (+1 to +5): from 16
  POP DE                  ; bytes before the top's own +1
  INC DE                  ;
  LD HL,$FFF0             ;
  ADD HL,DE               ;
  LD BC,$0005             ;
  LDIR                    ;
  LD A,(IX-$0A)           ; Is he turning (the legs' turn delay)? If not,
  AND $07                 ; perhaps a pose
  JR Z,UPDATE_TOP_2       ;
UPDATE_TOP_0:
  LD A,(IX-$10)           ; The picture that matches the legs' frame: 16-21 to
  AND $0F                 ; 32-37, 24-29 to 40-45
  OR $20                  ;
  LD (IX+$00),A           ;
  LD (IX+$06),$00         ; No pose running; the legs' flags (the mirror)
  LD A,(IX-$09)           ;
  LD (IX+$07),A           ;
UPDATE_TOP_1:
  BIT 0,(IX-$09)          ; Done unless the legs met a wall
  RET Z                   ;
  LD A,(IX+$00)           ; The bump, unless the top already had its arms out
  AND $07                 ;
  CP $06                  ;
  CALL NZ,BUMP_SOUND      ;
  LD A,(IX-$10)           ; Arms out: graphic 22 or 30
  AND $F8                 ;
  OR $06                  ;
  LD (IX+$00),A           ;
  LD (IX+$06),$00         ;
  RET                     ;
UPDATE_TOP_2:
  LD A,(IX+$06)           ; A pose running?
  AND A                   ;
  JR NZ,UPDATE_TOP_3      ;
  LD A,(RANDOM)           ; None: one turn in 32 start one, otherwise follow
  CP $08                  ; the legs
  JR NC,UPDATE_TOP_0      ;
  AND $01                 ; Pose 38 or 39 from behind, 46 or 47 from the front
  LD C,A                  ;
  LD A,(IX-$10)           ;
  AND $08                 ;
  OR $26                  ;
  OR C                    ;
  LD (IX+$00),A           ;
  LD A,R                  ; For two to nine turns
  AND $07                 ;
  ADD A,$02               ;
  LD (IX+$06),A           ;
  LD A,(IX-$09)           ; The legs' flags
  LD (IX+$07),A           ;
  JR UPDATE_TOP_1         ;
UPDATE_TOP_3:
  DEC A                   ; A pose running: count it down, and follow the legs
  LD (IX+$06),A           ; again at the end
  JR Z,UPDATE_TOP_0       ;
  JR UPDATE_TOP_1         ;

; The update routine for the knight's legs (graphics 16-21, 24-29)
;
; The knight's own routine. At a new life ARRIVING counts up from 40 by two a
; turn while he appears; at 76 it is set to 112 and he is here. Until then he
; cannot move, and the sound of his arrival (ARRIVE_SOUND) plays. Once here:
; the faster walk counts down, and when it runs out his top speed is 10 again
; and his speed 8; then the controls are read (READ_CONTROLS) and acted on in
; turn -- turning the town round (TURN_TOWN), turning (TURN_KNIGHT), walking or
; coming to a stop (KNIGHT_WALKS) and throwing (KNIGHT_THROWS). E holds the
; controls through all of it.
;
; IX The legs' record (KNIGHT)
UPDATE_KNIGHT:
  RES 0,(IX+$07)          ; Clear the wall flag
  LD HL,ARRIVING          ; Still appearing?
  LD A,(HL)               ;
  ADD A,$02               ;
  LD (HL),A               ;
  CP $4C                  ;
  JR C,UPDATE_KNIGHT_1    ;
  LD (HL),$70             ; He is here
  LD HL,SPEED_TIME        ; Count the faster walk down, if there is one
  LD A,(HL)               ;
  AND A                   ;
  JR Z,UPDATE_KNIGHT_0    ;
  DEC (HL)                ;
  JR NZ,UPDATE_KNIGHT_0   ;
  LD A,$0A                ; Run out: top speed 10, speed 8
  LD (TOP_SPEED),A        ;
  LD (IX+$05),$08         ;
UPDATE_KNIGHT_0:
  CALL READ_CONTROLS      ; E: the controls
  LD E,C                  ;
  CALL TURN_TOWN          ; Turn the town round?
  CALL TURN_KNIGHT        ; Turn, or with directional control face the stick's
                          ; way
  PUSH DE                 ; Walk, or come to a stop on the grid
  CALL KNIGHT_WALKS       ;
  POP DE                  ;
  CALL KNIGHT_THROWS      ; Throw?
  RET                     ;
UPDATE_KNIGHT_1:
  CALL SET_KNIGHT_LOOK    ; Appearing: his picture for his facing, and the
  JP ARRIVE_SOUND         ; sound

; Throw the last thing taken up
;
; Used by the routine at UPDATE_KNIGHT.
;
; Fire throws what the knight took up last: the carried things (CARRIED) are
; searched from the eleventh back. An antibody (thing 5-8) goes into a free
; antibody record (ANTIBODIES) as graphic 80, 84, 88 or 92; with both in use,
; the record THROW_TOGGLE points at is ended instead if it is still an antibody
; in flight, and the throw waits for the next press. An object (thing 1-4) goes
; into its own record, record 4 minus the thing (so the pairs of OBJECT_FLIGHT
; hold), as graphic 8-11. Either way the thrown thing is a copy of the legs'
; record -- his place, facing and flags -- given speed 12, half-size 16 and a
; drawing offset; the thing's place on the panel is redrawn empty, and the
; throw's sound plays. Two turns must pass before the next throw.
;
; E The controls (bit 3 fire)
KNIGHT_THROWS:
  LD HL,FIRE_DELAY        ; Still waiting after the last throw: count down
  LD A,(HL)               ;
  AND A                   ;
  JR Z,KNIGHT_THROWS_0    ;
  DEC (HL)                ;
  RET                     ;
KNIGHT_THROWS_0:
  BIT 3,E                 ; Fire?
  RET Z                   ;
  LD HL,CARRIED_LAST      ; Find the last thing carried; B: its place plus one
  LD B,$0B                ;
KNIGHT_THROWS_1:
  LD A,(HL)               ;
  AND A                   ;
  JR NZ,KNIGHT_THROWS_2   ;
  DEC HL                  ;
  DJNZ KNIGHT_THROWS_1    ;
  RET                     ;
KNIGHT_THROWS_2:
  CP $05                  ; Things 1-4 are the objects
  JR C,KNIGHT_THROWS_6    ;
  LD IY,ANTIBODIES        ; An antibody: a free antibody record?
  LD DE,$0010             ;
  LD C,$02                ;
KNIGHT_THROWS_3:
  LD A,(IY+$00)           ;
  AND A                   ;
  JR Z,KNIGHT_THROWS_4    ;
  ADD IY,DE               ;
  DEC C                   ;
  JR NZ,KNIGHT_THROWS_3   ;
  LD HL,ANTIBODIES        ; Both in use: the one THROW_TOGGLE points at...
  LD A,(THROW_TOGGLE)     ;
  AND $10                 ;
  LD C,A                  ;
  LD B,$00                ;
  ADD HL,BC               ;
  LD A,(HL)               ; ...if it is still flying (graphic 80-95)...
  SUB $50                 ;
  CP $10                  ;
  RET NC                  ;
  LD (HL),$0C             ; ...vanishes; the thing is kept for the next press
  RET                     ;
KNIGHT_THROWS_4:
  LD A,(THROW_TOGGLE)     ; Flip which record a full pair loses next
  XOR $10                 ;
  LD (THROW_TOGGLE),A     ;
  PUSH BC                 ; Take the thing out of its place
  PUSH HL                 ;
  LD A,(HL)               ;
  LD (HL),$00             ;
  LD HL,KNIGHT            ; The antibody record: a copy of the legs'
  PUSH IY                 ;
  POP DE                  ;
  LD BC,$0010             ;
  LDIR                    ;
  ADD A,A                 ; Graphic 4 times the thing plus 60: 80, 84, 88, 92
  ADD A,A                 ;
  ADD A,$3C               ;
KNIGHT_THROWS_5:
  LD (IY+$00),A           ; The graphic; shared with the objects
  LD (IY+$05),$0C         ; Speed 12
  LD A,$10                ; Half-size 16 each way
  LD (IY+$08),A           ;
  LD (IY+$09),A           ;
  LD (IY+$0C),$F8         ; The drawing offset
  LD (IY+$0D),$04         ;
  LD A,$02                ; Two turns before the next throw
  LD (FIRE_DELAY),A       ;
  POP HL                  ; Redraw the place it was carried in, now empty
  POP BC                  ; (PICK_UP_THING counts the places from the other
  LD A,B                  ; end)
  NEG                     ;
  ADD A,$0C               ;
  LD B,A                  ;
  CALL DRAW_CARRIED       ;
  JP FIRE_SOUND           ; The throw's sound
KNIGHT_THROWS_6:
  PUSH BC                 ; An object: take it out of its place
  PUSH HL                 ;
  PUSH AF                 ;
  LD (HL),$00             ;
  NEG                     ; Its own record: OBJECTS plus 16 times (4 minus the
  ADD A,$04               ; thing)
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  LD HL,OBJECTS           ;
  CALL ADD_HL_A           ;
  PUSH HL                 ; A copy of the legs' record
  PUSH HL                 ;
  POP IY                  ;
  POP DE                  ;
  LD HL,KNIGHT            ;
  LD BC,$0010             ;
  LDIR                    ;
  POP AF                  ; Graphic the thing plus 7: 8-11, and on as for an
  ADD A,$07               ; antibody
  JR KNIGHT_THROWS_5      ;

; Turn the town round when its key is let go
;
; Used by the routine at UPDATE_KNIGHT.
;
; Z or SYMBOL SHIFT (bit 5 of the controls) turns the town round, to be seen
; from the other side, once a press: the key sets KEY_LATCH while held, and the
; turn happens when it is let go. The knight's facing gets a turn delay of two
; or three turns (bit 1 of +6), so a turn key held at the same time does not
; spin him while the view changes, and the panel's heading and compass are
; redrawn (PRINT_HEADING).
;
; E The controls
TURN_TOWN:
  LD HL,KEY_LATCH         ; Held: remember it and wait
  BIT 5,E                 ;
  JR Z,TURN_TOWN_0        ;
  LD (HL),$01             ;
  RET                     ;
TURN_TOWN_0:
  LD A,(HL)               ; Not held: done unless it was last turn
  AND A                   ;
  RET Z                   ;
  LD (HL),$00             ;
  LD HL,VIEW              ; Turn the town round
  LD A,(HL)               ;
  XOR $01                 ;
  LD (HL),A               ;
  LD A,(KNIGHT_FACING)    ; A turn delay for the knight
  OR $02                  ;
  LD (KNIGHT_FACING),A    ;
  JP PRINT_HEADING        ; Redraw the heading and the compass

; Turn the knight, by the controls
;
; Used by the routine at UPDATE_KNIGHT.
;
; The low three bits of his facing (+6) are a turn delay: while it is not 0 it
; counts down and he cannot turn. A turn sets it to 1, so a turn key held down
; turns him a quarter every other turn.
;
; With the keyboard, or a stick with rotational control, left and right turn
; him a quarter (left subtracts $40 from the facing, right adds it) and walking
; is left to KNIGHT_WALKS. With a stick and directional control (CONTROL bits
; 1-2 not 0, bit 3 set), the stick's direction is a facing -- up +V, right +U,
; down -V, left -U, turned round with the town (SWAP_STICK) -- and he turns a
; quarter towards it, a random way if it is behind him, walking (bit 2 of E)
; only once he faces it. The stick is read as up (unless left is held too),
; then right, down and left, so a diagonal counts as one of its two directions.
;
; Then, from offset 139 (SET_KNIGHT_LOOK, also the entry while he appears), his
; picture: FACING_LOOKS gives the mirror bit and whether he is seen from the
; front, by his facing and the view.
;
;   IX The legs' record
;   E The controls: bits 0-1 left and right, 2 walk (up), 3 fire, 4 down, 5
;     turn the town round
; O:E Bit 2 set if he walks this turn
TURN_KNIGHT:
  LD A,(IX+$06)           ; Turning delay still running: count it, and only set
  AND $07                 ; his picture
  JR Z,TURN_KNIGHT_0      ;
  DEC (IX+$06)            ;
  JR SET_KNIGHT_LOOK      ;
TURN_KNIGHT_0:
  LD HL,CONTROL           ; A stick with directional control?
  LD A,(HL)               ;
  AND $06                 ;
  JR Z,TURN_KNIGHT_10     ;
  BIT 3,(HL)              ;
  JR Z,TURN_KNIGHT_10     ;
  LD A,(VIEW)             ; Its directions turned round with the town
  AND $01                 ;
  CALL NZ,SWAP_STICK      ;
  BIT 0,E                 ; Up, unless left too
  JR NZ,TURN_KNIGHT_1     ;
  BIT 2,E                 ;
  JR NZ,TURN_KNIGHT_2     ;
TURN_KNIGHT_1:
  BIT 1,E                 ; Right
  JR NZ,TURN_KNIGHT_6     ;
  BIT 4,E                 ; Down
  JR NZ,TURN_KNIGHT_7     ;
  BIT 0,E                 ; Left
  JR NZ,TURN_KNIGHT_8     ;
  RES 2,E                 ; None: stand
  RET                     ;
TURN_KNIGHT_2:
  LD A,(IX+$06)           ; Up: +V, the facing itself
TURN_KNIGHT_3:
  AND $C0                 ; A: the facing less the stick's; no walking unless
  RES 2,E                 ; it is 0
  JR Z,TURN_KNIGHT_9      ;
  CP $40                  ; A quarter to the right of it: turn left
  JR Z,TURN_KNIGHT_4      ;
  CP $C0                  ; A quarter to the left: turn right
  JR Z,TURN_KNIGHT_5      ;
  LD A,(RANDOM)           ; Behind him: either way, at random
  CP $80                  ;
  JR C,TURN_KNIGHT_5      ;
TURN_KNIGHT_4:
  LD A,(IX+$06)           ; Turn left
  SUB $40                 ;
  JR TURN_KNIGHT_12       ;
TURN_KNIGHT_5:
  LD A,(IX+$06)           ; Turn right
  ADD A,$40               ;
  JR TURN_KNIGHT_12       ;
TURN_KNIGHT_6:
  LD A,(IX+$06)           ; Right: +U
  SUB $40                 ;
  JR TURN_KNIGHT_3        ;
TURN_KNIGHT_7:
  LD A,(IX+$06)           ; Down: -V
  SUB $80                 ;
  JR TURN_KNIGHT_3        ;
TURN_KNIGHT_8:
  LD A,(IX+$06)           ; Left: -U
  SUB $C0                 ;
  JR TURN_KNIGHT_3        ;
TURN_KNIGHT_9:
  SET 2,E                 ; Facing it already: walk
  RET                     ;
TURN_KNIGHT_10:
  LD A,(IX+$06)           ; Rotational control: left?
  BIT 0,E                 ;
  JR Z,TURN_KNIGHT_11     ;
  SUB $40                 ; Turn left, with a turn's delay
  OR $01                  ;
TURN_KNIGHT_11:
  BIT 1,E                 ; Right? Turn right
  JR Z,TURN_KNIGHT_13     ;
  ADD A,$40               ;
TURN_KNIGHT_12:
  OR $01                  ; A turn's delay
TURN_KNIGHT_13:
  LD (IX+$06),A           ; The new facing
; This entry point is used by the routine at UPDATE_KNIGHT.
SET_KNIGHT_LOOK:
  LD A,(IX+$06)           ; Index FACING_LOOKS by the facing, flipped with the
  RLCA                    ; town
  RLCA                    ;
  AND $03                 ;
  LD L,A                  ;
  LD A,(VIEW)             ;
  ADD A,A                 ;
  XOR L                   ;
  LD L,A                  ;
  LD H,$00                ;
  LD BC,FACING_LOOKS      ; Its bits 6-7 into the flags: the mirror
  ADD HL,BC               ;
  LD A,(HL)               ;
  AND $C0                 ;
  LD C,A                  ;
  LD A,(IX+$07)           ;
  AND $3F                 ;
  OR C                    ;
  LD (IX+$07),A           ;
  LD A,(HL)               ; Its bit 3 into the graphic: from behind (16-21) or
  AND $08                 ; the front (24-29)
  LD C,A                  ;
  LD A,(IX+$00)           ;
  AND $F7                 ;
  OR C                    ;
  LD (IX+$00),A           ;
  RET                     ;

; Turn a stick's directions round with the town
;
; Used by the routine at TURN_KNIGHT.
;
; With the town turned round the stick's directions are swapped end for end --
; left for right, up for down -- so that pushing it still means the same way on
; the screen. Fire is kept; the town-turning bit is dropped, having been used.
;
;   E The controls
; O:E The same, turned round
SWAP_STICK:
  LD A,E                  ; Keep fire
  AND $08                 ;
  BIT 0,E                 ; Left becomes right
  JR Z,SWAP_STICK_0       ;
  SET 1,A                 ;
SWAP_STICK_0:
  BIT 1,E                 ; Right becomes left
  JR Z,SWAP_STICK_1       ;
  SET 0,A                 ;
SWAP_STICK_1:
  BIT 2,E                 ; Up becomes down
  JR Z,SWAP_STICK_2       ;
  SET 4,A                 ;
SWAP_STICK_2:
  BIT 4,E                 ; Down becomes up
  JR Z,SWAP_STICK_3       ;
  SET 2,A                 ;
SWAP_STICK_3:
  LD E,A                  ; The new controls
  RET                     ;

; Walk, or come to a stop on the grid
;
; Used by the routine at UPDATE_KNIGHT.
;
; With the walk control (bit 2 of E, after TURN_KNIGHT) he walks on (WALK_ON).
; Without it he does not stop dead: COAST_TABLE's routine for his facing keeps
; him stepping until his place along it is a multiple of 8, so he always comes
; to rest on an eight-unit grid.
;
; E The controls
KNIGHT_WALKS:
  BIT 2,E                 ; Walking?
  JR NZ,WALK_ON           ;
  LD A,(IX+$06)           ; No: come to a stop, by the facing
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  LD BC,COAST_TABLE       ;
  JP DISPATCH             ;

; Routines for coming to a stop, by facing (KNIGHT_WALKS)
COAST_TABLE:
  DEFW COAST_PLUS_V       ; Facing +V
  DEFW COAST_PLUS_U       ; Facing +U
  DEFW COAST_MINUS_V      ; Facing -V
  DEFW COAST_MINUS_U      ; Facing -U

; Come to a stop facing +V
;
; The distance on to the next multiple of 8 along his facing is taken from the
; low three bits of V (here), U, or their negatives (COAST_PLUS_U,
; COAST_MINUS_V, COAST_MINUS_U); 0 and he stands (STAND_ON_GRID). Otherwise he
; steps 4 if it is 4 or more, 2 if 2 or 3, and 1 if 1, and walks the step as
; usual (WALK_ON from offset 13), so he slows down 4, 2, 1 into place.
;
; IX The legs' record
COAST_PLUS_V:
  LD A,(IX+$03)           ; V's low byte
; This entry point is used by the routines at COAST_PLUS_U and COAST_MINUS_V.
COAST_TO_GRID:
  AND $07                 ; On the grid: stand
  JR Z,STAND_ON_GRID      ;
  NEG                     ; A: how far to the next multiple of 8, 1-7
  ADD A,$08               ;
  LD C,$04                ; 4 or more: step 4
  CP C                    ;
  JR NC,COAST_PLUS_V_0    ;
  SRL C                   ; 2 or 3: step 2
  CP C                    ;
  JR NC,COAST_PLUS_V_0    ;
  LD C,A                  ; The last 1
COAST_PLUS_V_0:
  LD A,C                  ; Walk that step
  JR WALK_STEP            ;

; Come to a stop facing +U
;
; As COAST_PLUS_V, along U.
COAST_PLUS_U:
  LD A,(IX+$01)           ; U's low byte
  JR COAST_TO_GRID        ;

; Come to a stop facing -V
;
; As COAST_PLUS_V, with V negated, so the distance is back to the multiple of 8
; below.
COAST_MINUS_V:
  LD A,(IX+$03)           ; V's low byte
; This entry point is used by the routine at COAST_MINUS_U.
COAST_BACKWARDS:
  NEG                     ; Negated
  JR COAST_TO_GRID        ;

; Come to a stop facing -U
;
; As COAST_MINUS_V, along U.
COAST_MINUS_U:
  LD A,(IX+$01)           ; U's low byte, negated
  JR COAST_BACKWARDS      ;

; Stand still, on the grid
;
; Used by the routine at COAST_PLUS_V.
;
; Speed 0; the walking frame stays as it was.
STAND_ON_GRID:
  LD (IX+$05),$00         ; Speed 0
  RET                     ;

; Walk on, speeding up
;
; Used by the routine at KNIGHT_WALKS.
;
; His speed goes halfway to his top speed (TOP_SPEED) each turn, rounded down
; to an even number -- which means it never reaches it: from 0 with top speed
; 10 it goes 4, 6, 8 and stays at 8; with the bonus's 18 it goes 8, 12, 14, 16
; and stays at 16 (both measured in the simulator, walking held).
;
; From offset 13 (WALK_STEP, also where he comes to a stop, COAST_PLUS_V): the
; step from the speed and the facing, trimmed at walls, and moved; the visited
; cell and the percentage (VISIT_CELL); a footstep (FOOTSTEP); and the next of
; six walking frames.
;
; IX The legs' record
WALK_ON:
  LD A,(TOP_SPEED)        ; Halfway to the top speed, even
  SUB (IX+$05)            ;
  SRL A                   ;
  ADD A,(IX+$05)          ;
  AND $FE                 ;
; This entry point is used by the routine at COAST_PLUS_V.
WALK_STEP:
  LD (IX+$05),A           ; The speed
  CALL SET_STEP           ; Step, trimmed at walls, and move
  CALL MOVE_CLIPPED       ;
  CALL APPLY_STEP         ;
  CALL VISIT_CELL         ; A new cell visited?
  CALL FOOTSTEP           ; A footstep
  LD A,(IX+$00)           ; The next walking frame, 0-5 in the low three bits
  LD C,A                  ;
  INC A                   ;
  AND $07                 ;
  CP $06                  ;
  JR C,WALK_ON_0          ;
  XOR A                   ;
WALK_ON_0:
  LD B,A                  ; Keep the rest of the graphic (bit 3, from behind or
  LD A,C                  ; the front)
  AND $F8                 ;
  OR B                    ;
  LD (IX+$00),A           ;
  RET                     ;

; How the knight looks for each facing
;
; Indexed by the facing (0-3) with bit 1 flipped when the town is turned round
; (TURN_KNIGHT, from offset 139). Bits 6-7 go into the flags -- bit 6 mirrors
; the picture; bit 7, upside down, is never set -- and bit 3 into the graphic,
; the view from the front, his face showing (24-29 rather than 16-21, seen from
; behind). Facing +U or -V he comes towards the viewer, since further back is
; smaller U and larger V (DEPTH_TABLE); drawn by the game's own code, those two
; show his face.
FACING_LOOKS:
  DEFB $40                ; By facing: +V from behind, mirrored ($40); +U from
  DEFB $08                ; the front ($08); -V from the front, mirrored ($48);
  DEFB $48                ; -U from behind ($00)
  DEFB $00                ;

; Set a record's step from its speed and facing
;
; Used by the routines at MONSTER112_UPDATE, SPARKLE_FLY, ANTIBODY_FLIGHT,
; OBJECT_FLIGHT, VILLAIN_WANDER and WALK_ON.
;
; The step (+A, +B) is the speed along the one axis the record faces: U if bit
; 6 of the facing is set, V if not, negative if bit 7 is set. Only four
; directions; the random wanderers set their steps themselves (WANDER_STEP).
;
; A The speed
; IX The record
SET_STEP:
  LD H,$00                ; H (V) or L (U) the speed, the other 0
  LD L,A                  ;
  BIT 6,(IX+$06)          ;
  JR NZ,SET_STEP_0        ;
  LD H,A                  ;
  LD L,$00                ;
SET_STEP_0:
  BIT 7,(IX+$06)          ; Facing -V or -U: negate both
  JR Z,SET_STEP_1         ;
  LD A,L                  ;
  NEG                     ;
  LD L,A                  ;
  LD A,H                  ;
  NEG                     ;
  LD H,A                  ;
SET_STEP_1:
  LD (IX+$0A),L           ; The step
  LD (IX+$0B),H           ;
  RET                     ;

; Move a record by its step
;
; Used by the routines at CREATURE_UPDATE, MONSTER112_UPDATE,
; WANDERING_MONSTER, SPARKLE_FLY, ANTIBODY_FLIGHT, OBJECT_FLIGHT,
; VILLAIN_WANDER, FIND_WANDER and WALK_ON.
;
; Adds the step, two signed bytes, to U and V. Called after the step has been
; trimmed at the walls (MOVE_CLIPPED).
;
; IX The record
APPLY_STEP:
  LD A,(IX+$0A)           ; U plus the U step, sign-extended
  CALL SIGN_EXTEND_A      ;
  LD C,(IX+$01)           ;
  LD B,(IX+$02)           ;
  ADD HL,BC               ;
  LD (IX+$01),L           ;
  LD (IX+$02),H           ;
  LD A,(IX+$0B)           ; V plus the V step
  CALL SIGN_EXTEND_A      ;
  LD C,(IX+$03)           ;
  LD B,(IX+$04)           ;
  ADD HL,BC               ;
  LD (IX+$03),L           ;
  LD (IX+$04),H           ;
  RET                     ;

; Decide whether a walker turns: at a wall, when its count runs out, or towards
; the knight
;
; Used by the routines at MONSTER112_UPDATE and VILLAIN_WANDER.
;
; Used by the villains (VILLAIN_WANDER) and the monsters of graphics 112-127
; (MONSTER112_UPDATE). Stopped by a wall, it turns a quarter left or right at
; random and starts a new count of up to 63 turns. Otherwise the count (the low
; bits of the facing byte) goes down each turn, and when its low five bits
; reach 0: with bit 5 of the flags clear it turns at random the same way; with
; it set it turns towards the knight (KNIGHT_DIRECTION, TURN_TO_KNIGHT_TABLE)
; and starts a count of 1-16.
;
; Bit 5 is set only for a monster spawned in the first half of a 256-turn cycle
; (SPAWN_MONSTER); the villains never have it, so they wander and never chase.
; The counts are set from the random number's high byte and tested on only five
; bits, so a count of 32-63 runs out after the count less 32.
;
; IX The record
STEER:
  BIT 0,(IX+$07)          ; Stopped by a wall: turn
  JR NZ,STEER_0           ;
  DEC (IX+$06)            ; Count down; done unless the low five bits are 0
  LD A,(IX+$06)           ;
  AND $1F                 ;
  RET NZ                  ;
  BIT 5,(IX+$07)          ; A chaser turns towards the knight
  JR NZ,STEER_3           ;
STEER_0:
  LD A,(RANDOM)           ; Turn left or right at random
  CP $80                  ;
  LD A,(IX+$06)           ;
  JR NC,STEER_2           ;
  ADD A,$40               ; Right
STEER_1:
  LD C,A                  ; A new count, the random number's high byte's low
  LD A,($BBAB)            ; six bits ORed with what was left of the old one
  AND $3F                 ;
  OR C                    ;
  LD (IX+$06),A           ;
  RET                     ;
STEER_2:
  SUB $40                 ; Left
  JR STEER_1              ;
STEER_3:
  CALL KNIGHT_DIRECTION   ; A: the knight's direction, 0-3
  LD C,A                  ;
  LD A,(IX+$06)           ; Where it is compared with the facing: 0 ahead, 1 to
  RLCA                    ; the left, 2 behind, 3 to the right
  RLCA                    ;
  SUB C                   ;
  AND $03                 ;
  LD BC,TURN_TO_KNIGHT_TABLE ; Turn by it (TURN_TO_KNIGHT_TABLE)
  JP DISPATCH                ;

; Routines to turn a chaser towards the knight, by where he is (STEER)
;
; Indexed by the knight's direction from the chaser (KNIGHT_DIRECTION) less its
; facing. Three of the four enter STEER_EITHER part way.
TURN_TO_KNIGHT_TABLE:
  DEFW STEER_ON           ; Ahead: keep on
  DEFW STEER_LEFT         ; A quarter to the left: turn left
  DEFW STEER_EITHER       ; Behind: either way, at random
  DEFW STEER_RIGHT        ; A quarter to the right: turn right

; Turn a chaser towards the knight
;
; Four entries, reached through TURN_TO_KNIGHT_TABLE: here (the knight behind
; it) a quarter left or right at random; at offset 7 (STEER_LEFT) a quarter
; left; at offset 15 (STEER_ON) no turn; at offset 32 (STEER_RIGHT) a quarter
; right. Each then starts a new count of 1-16 turns in the facing's low bits.
;
; IX The record
STEER_EITHER:
  LD A,($BBAB)            ; Behind: left or right at random
  CP $80                  ;
  JR C,STEER_RIGHT        ;
STEER_LEFT:
  LD A,(IX+$06)           ; Turn left (facing less $40)
  SUB $40                 ;
STEER_EITHER_0:
  LD (IX+$06),A           ; The new facing
STEER_ON:
  LD A,(IX+$06)           ; A new count of 1-16, from the random number
  AND $C0                 ;
  LD C,A                  ;
  LD A,(RANDOM)           ;
  AND $0F                 ;
  INC A                   ;
  OR C                    ;
  LD (IX+$06),A           ;
  RET                     ;
STEER_RIGHT:
  LD A,(IX+$06)           ; Turn right (facing plus $40)
  ADD A,$40               ;
  JR STEER_EITHER_0       ;

; Which way is the knight from a record?
;
; Used by the routine at STEER.
;
; The facing that points most nearly at the knight: along V if he is at least
; as far away in V as in U, along U if further in U, the sign from the
; difference.
;
;   IX The record
; O:A 0 +V, 1 +U, 2 -V, 3 -U: the facing towards him, divided by $40
KNIGHT_DIRECTION:
  LD HL,(KNIGHT_U)        ; His U less its U; DE its size
  LD E,(IX+$01)           ;
  LD D,(IX+$02)           ;
  AND A                   ;
  SBC HL,DE               ;
  PUSH HL                 ;
  BIT 7,H                 ;
  CALL NZ,NEGATE_HL       ;
  EX DE,HL                ; His V less its V; HL its size
  LD HL,(KNIGHT_V)        ;
  LD C,(IX+$03)           ;
  LD B,(IX+$04)           ;
  AND A                   ;
  SBC HL,BC               ;
  PUSH HL                 ;
  BIT 7,H                 ;
  CALL NZ,NEGATE_HL       ;
  AND A                   ; Further in V (or as far)? A=0, HL the V difference
  SBC HL,DE               ;
  LD A,$00                ;
  POP HL                  ;
  POP DE                  ;
  JR NC,KNIGHT_DIRECTION_0
  INC A                   ; Further in U: A=1, HL the U difference
  EX DE,HL                ;
KNIGHT_DIRECTION_0:
  BIT 7,H                 ; Negative: 2 on
  RET Z                   ;
  ADD A,$02               ;
  RET                     ;

; Now and then give a wanderer a new random step
;
; Used by the routines at WANDERING_MONSTER and FIND_WANDER.
;
; For the finds (FIND_WANDER, B=4) and the monsters of graphics 64-79
; (WANDERING_MONSTER, B=7). The low six bits of +6 count turns down; when they
; run out, or when the step has become 0 both ways, a new step is drawn for U
; and V from the random number's two bytes (RANDOM_STEP: up to twice B either
; way, those near B likeliest) and a new count of 0-63 from R. The facing's top
; two bits are set again from the step by MOVE_SPLIT, which follows.
;
; B The number of random bits to a step
; IX The record
WANDER_STEP:
  DEC (IX+$06)            ; Count down; a new step when the count runs out...
  LD A,(IX+$06)           ;
  AND $3F                 ;
  JR Z,WANDER_STEP_0      ;
  LD A,(IX+$0A)           ; ...or when the old one is 0 both ways
  OR (IX+$0B)             ;
  RET NZ                  ;
WANDER_STEP_0:
  LD A,(RANDOM)           ; The U step, from the random number's low byte
  LD C,A                  ;
  CALL RANDOM_STEP        ;
  LD (IX+$0A),A           ;
  LD A,($BBAB)            ; The V step, from its high byte
  LD C,A                  ;
  CALL RANDOM_STEP        ;
  LD (IX+$0B),A           ;
  LD A,R                  ; A new count of 0-63
  AND $3F                 ;
  LD (IX+$06),A           ;
  RET                     ;

; A random step from the bits of a byte
;
; Used by the routine at WANDER_STEP.
;
; Two for each 0 among the low B bits of C, negative if the next bit is 0: a
; step of 0 to twice B either way, those near B likeliest, as the count of
; zeros among B random bits is.
;
;   B The number of bits
;   C Random bits
; O:A The step
RANDOM_STEP:
  PUSH BC                 ; A=0
  XOR A                   ;
RANDOM_STEP_0:
  RR C                    ; Two for each 0 bit
  JR C,RANDOM_STEP_1      ;
  ADD A,$02               ;
RANDOM_STEP_1:
  DJNZ RANDOM_STEP_0      ;
  RR C                    ; The next bit: 1 positive, 0 negative
  POP BC                  ;
  RET C                   ;
  NEG                     ;
  RET                     ;

; Trim a two-way step at the walls, one axis at a time
;
; Used by the routines at CREATURE_UPDATE, WANDERING_MONSTER and FIND_WANDER.
;
; The clipping routines (MOVE_TABLE) handle a step along the facing only, so a
; wanderer's step, which can go both ways at once, is taken in two: the U part,
; facing +U or -U by its sign, with the V part set aside; then the V part,
; facing +V or -V, with the U part set aside. The facing ends as the V part's,
; if there is one. The second clip does not clear the wall flag, so it says
; whether either part met a wall.
;
; IX The record
MOVE_SPLIT:
  LD A,(IX+$0A)           ; Any U step?
  AND A                   ;
  JR Z,MOVE_SPLIT_1       ;
  LD A,$40                ; Face +U, or -U if it is negative
  JP P,MOVE_SPLIT_0       ;
  OR $80                  ;
MOVE_SPLIT_0:
  LD C,A                  ;
  LD A,(IX+$06)           ;
  AND $3F                 ;
  OR C                    ;
  LD (IX+$06),A           ;
  LD A,(IX+$0B)           ; Trim the U step, with the V step put aside
  PUSH AF                 ;
  LD (IX+$0B),$00         ;
  CALL MOVE_CLIPPED       ;
  POP AF                  ;
  LD (IX+$0B),A           ;
MOVE_SPLIT_1:
  LD A,(IX+$0B)           ; Any V step?
  AND A                   ;
  RET Z                   ;
  LD A,$00                ; Face +V, or -V if it is negative
  JP P,MOVE_SPLIT_2       ;
  OR $80                  ;
MOVE_SPLIT_2:
  LD C,A                  ;
  LD A,(IX+$06)           ;
  AND $3F                 ;
  OR C                    ;
  LD (IX+$06),A           ;
  LD A,(IX+$0A)           ; Trim the V step, with the U step put aside, keeping
  PUSH AF                 ; the wall flag
  LD (IX+$0A),$00         ;
  CALL MOVE_CLIPPED_AGAIN ;
  POP AF                  ;
  LD (IX+$0A),A           ;
  RET                     ;

; Trim a record's step at the town's walls
;
; Used by the routines at MONSTER112_UPDATE, SPARKLE_FLY, ANTIBODY_FLIGHT,
; OBJECT_FLIGHT, VILLAIN_WANDER, WALK_ON and MOVE_SPLIT.
;
; Clears the wall flag (bit 0 of +7) and jumps to MOVE_TABLE's routine for the
; facing, which trims the step so that the record stops against a wall instead
; of in it, and sets the flag if it had to. From offset 4 (MOVE_CLIPPED_AGAIN)
; the flag is left as it is, for a second move in the same turn. The step is
; only trimmed here: APPLY_STEP makes the move.
;
; IX The record
MOVE_CLIPPED:
  RES 0,(IX+$07)          ; No wall met yet
; This entry point is used by the routines at ANTIBODY_FLIGHT, OBJECT_FLIGHT
; and MOVE_SPLIT.
MOVE_CLIPPED_AGAIN:
  LD A,(IX+$06)           ; By the facing
  RLCA                    ;
  RLCA                    ;
  AND $03                 ;
  LD BC,MOVE_TABLE        ;
  JP DISPATCH             ;

; Routines to trim a step at the walls, by facing (MOVE_CLIPPED)
;
; Each finds the town cells that the record's front edge is in, and will be in
; after the step, and tests the record against every box of each cell's type
; (the box lists, through BOX_TABLE).
MOVE_TABLE:
  DEFW CLIP_PLUS_V        ; Facing +V
  DEFW CLIP_PLUS_U        ; Facing +U
  DEFW CLIP_MINUS_V       ; Facing -V
  DEFW CLIP_MINUS_U       ; Facing -U

; Trim a step along +V at the walls
;
; The record's front edge is at V plus its half-size in V (+9), from U less its
; half-size in U (+8) to U plus it. The cell under each front corner is tested
; (CUT_STEP_PLUS_V: the record, moved by its step, against the boxes of that
; cell's type); the second only if it is a different cell from the first. Then,
; if the step carries the front edge into the next row of cells, the cells it
; goes into are tested too. The first test to find a box in the way trims the V
; step to touch it, sets the wall flag, and returns with carry set.
;
; Only the cells under the front edge are chosen; which boxes are hit is
; decided by the whole record against the whole box, so a box reaching into the
; cell from its side still counts. CLIP_PLUS_U and CLIP_MINUS_V are the same
; for +U and -V, and CLIP_MINUS_U for -U.
;
;   IX The record
; O:F Carry set if a wall trimmed the step
CLIP_PLUS_V:
  LD L,(IX+$01)           ; DE: U less the half-size, the left of the front
  LD H,(IX+$02)           ; edge
  LD C,(IX+$08)           ;
  LD B,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  EX DE,HL                ;
  LD L,(IX+$03)           ; HL: V plus the half-size, the front edge
  LD H,(IX+$04)           ;
  LD C,(IX+$09)           ;
  ADD HL,BC               ;
  PUSH DE                 ; Test the cell under the front left corner; done if
  PUSH HL                 ; a wall
  CALL CUT_STEP_PLUS_V    ;
  POP DE                  ;
  POP HL                  ;
  RET C                   ;
  PUSH HL                 ; The right corner, U plus the half-size: in the same
  PUSH DE                 ; cell?
  LD C,(IX+$08)           ;
  SLA C                   ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  JR Z,CLIP_PLUS_V_0      ;
  EX DE,HL                ; No: test its cell too
  CALL CUT_STEP_PLUS_V    ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  LD C,(IX+$0B)           ; Does the step take the front edge into the next row
  LD B,$00                ; of cells? Done if not
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  PUSH DE                 ; Yes: test the cell the left corner goes into...
  PUSH HL                 ;
  CALL CUT_STEP_PLUS_V    ;
  POP DE                  ;
  POP HL                  ;
  RET C                   ;
  LD C,(IX+$08)           ; ...and the one the right corner goes into
  SLA C                   ;
  LD B,$00                ;
  ADD HL,BC               ;
  EX DE,HL                ;
  JP CUT_STEP_PLUS_V      ;
CLIP_PLUS_V_0:
  POP HL                  ; Both corners in one cell: test only the cell the
  POP DE                  ; step goes into, if another
  LD C,(IX+$0B)           ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  JP CUT_STEP_PLUS_V      ;

; Trim a step along +U at the walls
;
; As CLIP_PLUS_V, with U and V exchanged: the front edge is at U plus the
; half-size in U, the corners at V less and plus the half-size in V, and
; CUT_STEP_PLUS_U trims the U step.
;
;   IX The record
; O:F Carry set if a wall trimmed the step
CLIP_PLUS_U:
  LD L,(IX+$01)           ; DE: U plus the half-size, the front edge
  LD H,(IX+$02)           ;
  LD C,(IX+$08)           ;
  LD B,$00                ;
  ADD HL,BC               ;
  EX DE,HL                ;
  LD L,(IX+$03)           ; HL: V less the half-size
  LD H,(IX+$04)           ;
  LD C,(IX+$09)           ;
  AND A                   ;
  SBC HL,BC               ;
  PUSH DE                 ; Test the cell under the one front corner; done if a
  PUSH HL                 ; wall
  CALL CUT_STEP_PLUS_U    ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  PUSH DE                 ; The other corner, V plus the half-size: in the same
  PUSH HL                 ; cell?
  LD C,(IX+$09)           ;
  SLA C                   ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  JR Z,CLIP_PLUS_U_0      ;
  CALL CUT_STEP_PLUS_U    ; No: test its cell too
  POP DE                  ;
  POP HL                  ;
  RET C                   ;
  LD C,(IX+$0A)           ; Does the step take the front edge into the next
  LD B,$00                ; column of cells? Done if not
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  EX DE,HL                ; Yes: test the cells the two corners go into
  PUSH DE                 ;
  PUSH HL                 ;
  CALL CUT_STEP_PLUS_U    ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  LD C,(IX+$09)           ;
  SLA C                   ;
  LD B,$00                ;
  ADD HL,BC               ;
  JP CUT_STEP_PLUS_U      ;
CLIP_PLUS_U_0:
  POP DE                  ; Both corners in one cell: test only the cell the
  POP HL                  ; step goes into, if another
  LD C,(IX+$0A)           ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  EX DE,HL                ;
  JP CUT_STEP_PLUS_U      ;

; Trim a step along -V at the walls
;
; As CLIP_PLUS_V, with the front edge at V less the half-size, the step taken
; as negative (B=$FF), and CUT_STEP_MINUS_V trimming it.
;
;   IX The record
; O:F Carry set if a wall trimmed the step
CLIP_MINUS_V:
  LD L,(IX+$01)           ; DE: U less the half-size
  LD H,(IX+$02)           ;
  LD C,(IX+$08)           ;
  LD B,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  EX DE,HL                ;
  LD L,(IX+$03)           ; HL: V less the half-size, the front edge
  LD H,(IX+$04)           ;
  LD C,(IX+$09)           ;
  AND A                   ;
  SBC HL,BC               ;
  PUSH DE                 ; Test the cell under the one front corner; done if a
  PUSH HL                 ; wall
  CALL CUT_STEP_MINUS_V   ;
  POP DE                  ;
  POP HL                  ;
  RET C                   ;
  PUSH HL                 ; The other corner, U plus the half-size: in the same
  PUSH DE                 ; cell?
  LD C,(IX+$08)           ;
  SLA C                   ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  JR Z,CLIP_MINUS_V_0     ;
  EX DE,HL                ; No: test its cell too
  CALL CUT_STEP_MINUS_V   ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  LD C,(IX+$0B)           ; Does the step (negative: B=$FF) take the front edge
  LD B,$FF                ; into the row of cells before? Done if not
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  PUSH DE                 ; Yes: test the cells the two corners go into
  PUSH HL                 ;
  CALL CUT_STEP_MINUS_V   ;
  POP DE                  ;
  POP HL                  ;
  RET C                   ;
  LD C,(IX+$08)           ;
  SLA C                   ;
  LD B,$00                ;
  ADD HL,BC               ;
  EX DE,HL                ;
  JP CUT_STEP_MINUS_V     ;
CLIP_MINUS_V_0:
  POP HL                  ; Both corners in one cell: test only the cell the
  POP DE                  ; step goes into, if another
  LD C,(IX+$0B)           ;
  LD B,$FF                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  JP CUT_STEP_MINUS_V     ;

; Cut a step in -U short at the boxes of the cells ahead
;
; The last of the four routines of MOVE_TABLE, for an object facing -U (bits
; 6-7 of +6 = 3). The object's footprint is its U and V plus or minus its
; half-sizes (+8, +9); its leading edge is at U less the half-size in U. The
; cells to test are the ones that edge's two corners stand in now, and, if this
; turn's step in U (+A, negative) takes the edge into the next column, the ones
; its corners reach there -- at most four, each tested once. For each,
; CUT_STEP_MINUS_U checks the object's box, moved by the step, against the
; cell's boxes and cuts the step short at the first it runs into; the first cut
; ends the search, with carry set.
;
; The corners only choose which cells to look in: the box test itself works
; from the object's own position and step (PLACE_IN_CELL), so a cell tested
; twice or one the object is nowhere near costs time but cannot give a wrong
; answer.
;
;   IX The object
; O:F Carry set if the step was cut (and bit 0 of +7 set)
CLIP_MINUS_U:
  LD L,(IX+$01)           ; DE = U less the half-size in U: the leading edge
  LD H,(IX+$02)           ;
  LD C,(IX+$08)           ;
  LD B,$00                ;
  AND A                   ;
  SBC HL,BC               ;
  EX DE,HL                ;
  LD L,(IX+$03)           ; HL = V less the half-size in V: the edge's low
  LD H,(IX+$04)           ; corner
  LD C,(IX+$09)           ;
  AND A                   ;
  SBC HL,BC               ;
  PUSH DE                 ; Test the cell under that corner; stop if the step
  PUSH HL                 ; was cut
  CALL CUT_STEP_MINUS_U   ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  PUSH DE                 ; HL = V plus the half-size: the other corner; if it
  PUSH HL                 ; is in the same row, its cell has just been tested
  LD C,(IX+$09)           ;
  SLA C                   ;
  LD B,$00                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  JR Z,CLIP_MINUS_U_0     ;
  CALL CUT_STEP_MINUS_U   ; Test the cell under the other corner. DE and HL
  POP DE                  ; come back swapped: HL the edge's U, DE the low V
  POP HL                  ;
  RET C                   ;
  LD C,(IX+$0A)           ; Add the step in U, negative, B = $FF sign-extending
  LD B,$FF                ; it; if the edge stays in its column there is no new
  LD A,H                  ; cell. A step of 0 reads as -256 here, so a still
  ADD HL,BC               ; object tests the column behind as well, to no
  CP H                    ; effect
  RET Z                   ;
  EX DE,HL                ; Test the cell the moved edge reaches, at the low V
  PUSH DE                 ; corner...
  PUSH HL                 ;
  CALL CUT_STEP_MINUS_U   ;
  POP HL                  ;
  POP DE                  ;
  RET C                   ;
  LD C,(IX+$09)           ; ...and at the high one
  SLA C                   ;
  LD B,$00                ;
  ADD HL,BC               ;
  JP CUT_STEP_MINUS_U     ;
CLIP_MINUS_U_0:
  POP DE                  ; Both corners in one row: only the cell the moved
  POP HL                  ; edge reaches, if it is in a new column
  LD C,(IX+$0A)           ;
  LD B,$FF                ;
  LD A,H                  ;
  ADD HL,BC               ;
  CP H                    ;
  RET Z                   ;
  EX DE,HL                ;
  JP CUT_STEP_MINUS_U     ;

; Cut a step in +V short at a box of a cell
;
; Used by the routine at CLIP_PLUS_V.
;
; Called by the +V routine (CLIP_PLUS_V) for each cell its object's leading
; edge covers. If the object's box, moved by this turn's step, overlaps one of
; the cell's boxes (HIT_BOXES_V), the step in V (+B) is cut by the overlap, so
; that the move ends with the object against the box's face; bit 0 of the flags
; (+7) is set to say it was stopped, and carry is returned.
;
; The entry point CUT_STEP_V adds twice A, the overlap in half units, to the
; step; MARK_BLOCKED sets the flag. CUT_STEP_MINUS_V, CUT_STEP_PLUS_U and
; CUT_STEP_MINUS_U are the same for -V, +U and -U.
;
;   D The column of the cell to test (the high byte of a U in it)
;   H Its row (the high byte of a V in it)
;   IX The object
; O:F Carry set if the step was cut
CUT_STEP_PLUS_V:
  CALL HIT_BOXES_V        ; Test the cell's boxes; nothing in the way returns
  RET NC                  ; with carry clear
; This entry point is used by the routine at CUT_STEP_MINUS_V.
CUT_STEP_V:
  ADD A,A                 ; CUT_STEP_V: A is minus the overlap, in half units;
  ADD A,(IX+$0B)          ; twice it added to a positive step ends the move at
  LD (IX+$0B),A           ; the box
; This entry point is used by the routine at CUT_STEP_PLUS_U.
MARK_BLOCKED:
  SET 0,(IX+$07)          ; MARK_BLOCKED: bit 0 of the flags says the object
  SCF                     ; was stopped; return with carry set
  RET                     ;

; Cut a step in -V short at a box of a cell
;
; Used by the routine at CLIP_MINUS_V.
;
; As CUT_STEP_PLUS_V, for the -V routine (CLIP_MINUS_V): the overlap is made
; positive, so that it shortens a negative step.
;
;   D The column of the cell to test
;   H Its row
;   IX The object
; O:F Carry set if the step was cut
CUT_STEP_MINUS_V:
  CALL HIT_BOXES_V        ; Test the cell's boxes; nothing in the way returns
  RET NC                  ; with carry clear
  NEG                     ; Plus the overlap, and cut the step
  JR CUT_STEP_V           ;

; Cut a step in +U short at a box of a cell
;
; Used by the routine at CLIP_PLUS_U.
;
; As CUT_STEP_PLUS_V, for the step in U (+A) and the +U routine (CLIP_PLUS_U);
; the overlap in U comes from HIT_BOXES_U. The entry point CUT_STEP_U adds
; twice A to the step.
;
;   D The column of the cell to test
;   H Its row
;   IX The object
; O:F Carry set if the step was cut
CUT_STEP_PLUS_U:
  CALL HIT_BOXES_U        ; Test the cell's boxes; nothing in the way returns
  RET NC                  ; with carry clear
; This entry point is used by the routine at CUT_STEP_MINUS_U.
CUT_STEP_U:
  ADD A,A                 ; CUT_STEP_U: twice minus the overlap added to the
  ADD A,(IX+$0A)          ; step in U; then mark the object stopped
  LD (IX+$0A),A           ;
  JR MARK_BLOCKED         ;

; Cut a step in -U short at a box of a cell
;
; Used by the routine at CLIP_MINUS_U.
;
; As CUT_STEP_PLUS_U, for the -U routine (CLIP_MINUS_U): the overlap is made
; positive, so that it shortens a negative step.
;
;   D The column of the cell to test
;   H Its row
;   IX The object
; O:F Carry set if the step was cut
CUT_STEP_MINUS_U:
  CALL HIT_BOXES_U        ; Test the cell's boxes; nothing in the way returns
  RET NC                  ; with carry clear
  NEG                     ; Plus the overlap, and cut the step
  JR CUT_STEP_U           ;

; Look up a cell of the town, and where the object is in it
;
; Used by the routines at HIT_BOXES_U and HIT_BOXES_V.
;
; Takes the cell at column D and row H -- the high bytes of any U and V in it
; -- and returns its type from the map (TOWN), and the object's position in
; that cell's own frame, in the units its boxes are measured in: the object's U
; and V less the cell's corner, halved, plus 64. A cell is 256 units a side, so
; it runs from 64 to 191 in these half units, and a position half a cell beyond
; it either way still fits in a byte; only the low byte of the halved
; difference is kept, which is right for anything within that distance.
;
; The entry point TOWN_CELL does only the look-up, for a column in L and a row
; in H; the finds (SPAWN_FIND), the visited cells (VISIT_CELL), the monsters
; (SPAWN_MONSTER) and the bonus (PLACE_BONUS) use it. The map is 32 cells a
; row, and nothing here checks that the column or the row is less than 32.
;
;   D The column (the high byte of a U)
;   H The row (the high byte of a V)
;   IX The object
; O:A The cell's type, with Z set if it is 0 (nothing there)
; O:HL The cell's address in the map
; O:E The object's U in the cell, in half units from 64
; O:D The object's V in the cell, likewise
PLACE_IN_CELL:
  LD B,H                  ; Keep the row and the column
  LD C,D                  ;
  PUSH BC                 ;
  LD C,$00                ; E = (U less the cell's first U) halved, plus 64
  LD E,C                  ;
  LD L,(IX+$01)           ;
  LD H,(IX+$02)           ;
  AND A                   ;
  SBC HL,DE               ;
  SRL H                   ;
  RR L                    ;
  LD A,L                  ;
  ADD A,$40               ;
  LD E,A                  ;
  LD L,(IX+$03)           ; D = (V less the cell's first V) halved, plus 64
  LD H,(IX+$04)           ;
  AND A                   ;
  SBC HL,BC               ;
  SRL H                   ;
  RR L                    ;
  LD A,L                  ;
  ADD A,$40               ;
  LD D,A                  ;
  POP HL                  ; H = the row, L = the column
; This entry point is used by the routines at VISIT_CELL, SPAWN_FIND,
; SPAWN_MONSTER and PLACE_BONUS.
TOWN_CELL:
  LD A,L                  ; TOWN_CELL: HL = the row times 32, plus the column
  LD L,H                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  OR L                    ;
  LD L,A                  ;
  LD BC,TOWN              ; A = the cell's type from the map, Z set if the cell
  ADD HL,BC               ; is empty
  LD A,(HL)               ;
  AND A                   ;
  RET                     ;

; Does the moved object run into a box of a cell? Give the overlap in U
;
; Used by the routines at CUT_STEP_PLUS_U and CUT_STEP_MINUS_U.
;
; The cell's boxes come from BOX_TABLE by its type: four bytes a box -- its
; centre in U and V and its half-sizes in U and V, in the cell's half units
; (PLACE_IN_CELL) -- and a list ends at a 0. A box is hit when the object's
; footprint, moved by this turn's step, overlaps it in V (OVERLAP_V) and in U
; (OVERLAP_U). The first box hit returns carry, with A minus the depth of the
; overlap in U, in half units. HIT_BOXES_V is the same with the two tests the
; other way round, to give the overlap in V.
;
;   D The column of the cell
;   H Its row
;   IX The object
; O:A Minus the overlap in U, in half units (when carry is set)
; O:F Carry set if a box is hit
HIT_BOXES_U:
  CALL PLACE_IN_CELL      ; Find the cell's type and the object's place in it
  LD BC,BOX_TABLE         ; IY = the type's list of boxes
  CALL TABLE_WORD         ;
  PUSH HL                 ;
  POP IY                  ;
HIT_BOXES_U_0:
  LD A,(IY+$00)           ; A 0 ends the list: nothing hit, carry clear
  AND A                   ;
  RET Z                   ;
  CALL OVERLAP_V          ; Overlapping this box in V?
  JR NC,HIT_BOXES_U_1     ;
  CALL OVERLAP_U          ; ...and in U: then return carry, with the overlap in
  RET C                   ; U
HIT_BOXES_U_1:
  INC IY                  ; The next box
  INC IY                  ;
  INC IY                  ;
  INC IY                  ;
  JR HIT_BOXES_U_0        ;

; Do the moved object and a box overlap in U?
;
; Used by the routines at HIT_BOXES_U and HIT_BOXES_V.
;
; A = |the object's U + half its step - the box's centre| less (half the
; object's half-size + the box's half-size), all in the cell's half units. That
; is negative, with carry set, when the two overlap, and it is then minus the
; depth of the overlap.
;
;   E The object's U in the cell (PLACE_IN_CELL)
;   IX The object
;   IY The box
; O:A The gap between them, negative for an overlap
; O:F Carry set if they overlap
OVERLAP_U:
  LD A,(IX+$08)           ; C = the object's half-size in U, halved, plus the
  SRL A                   ; box's
  ADD A,(IY+$02)          ;
  LD C,A                  ;
  LD A,(IX+$0A)           ; The object's U after half its step, less the box's
  SRA A                   ; centre
  ADD A,E                 ;
  SUB (IY+$00)            ;
  JP P,OVERLAP_U_0        ; Made positive
  NEG                     ;
OVERLAP_U_0:
  SUB C                   ; Less the two half-sizes: carry if they overlap
  RET                     ;

; Does the moved object run into a box of a cell? Give the overlap in V
;
; Used by the routines at CUT_STEP_PLUS_V and CUT_STEP_MINUS_V.
;
; As HIT_BOXES_U, but testing U first and V second, so that the overlap it
; returns is in V: for the steps in V (CUT_STEP_PLUS_V, CUT_STEP_MINUS_V).
;
;   D The column of the cell
;   H Its row
;   IX The object
; O:A Minus the overlap in V, in half units (when carry is set)
; O:F Carry set if a box is hit
HIT_BOXES_V:
  CALL PLACE_IN_CELL      ; Find the cell's type and the object's place in it
  LD BC,BOX_TABLE         ; IY = the type's list of boxes
  CALL TABLE_WORD         ;
  PUSH HL                 ;
  POP IY                  ;
HIT_BOXES_V_0:
  LD A,(IY+$00)           ; A 0 ends the list: nothing hit, carry clear
  AND A                   ;
  RET Z                   ;
  CALL OVERLAP_U          ; Overlapping this box in U?
  JR NC,HIT_BOXES_V_1     ;
  CALL OVERLAP_V          ; ...and in V: then return carry, with the overlap in
  RET C                   ; V
HIT_BOXES_V_1:
  INC IY                  ; The next box
  INC IY                  ;
  INC IY                  ;
  INC IY                  ;
  JR HIT_BOXES_V_0        ;

; Do the moved object and a box overlap in V?
;
; Used by the routines at HIT_BOXES_U and HIT_BOXES_V.
;
; As OVERLAP_U, in V: the object's half-size +9 and step +B, the box's centre
; and half-size at +1 and +3.
;
;   D The object's V in the cell (PLACE_IN_CELL)
;   IX The object
;   IY The box
; O:A The gap between them, negative for an overlap
; O:F Carry set if they overlap
OVERLAP_V:
  LD A,(IX+$09)           ; C = the object's half-size in V, halved, plus the
  SRL A                   ; box's
  ADD A,(IY+$03)          ;
  LD C,A                  ;
  LD A,(IX+$0B)           ; The object's V after half its step, less the box's
  SRA A                   ; centre
  ADD A,D                 ;
  SUB (IY+$01)            ;
  JP P,OVERLAP_V_0        ; Made positive
  NEG                     ;
OVERLAP_V_0:
  SUB C                   ; Less the two half-sizes: carry if they overlap
  RET                     ;

; HL = -HL
;
; Used by the routines at TOUCHING_KNIGHT and KNIGHT_DIRECTION.
;
; Complements both bytes and adds one. Used by TOUCHING_KNIGHT and
; KNIGHT_DIRECTION.
;
;   HL A number
; O:HL Its negative
; O:A What was H complemented
NEGATE_HL:
  LD A,L
  CPL
  LD L,A
  LD A,H
  CPL
  LD H,A
  INC HL
  RET

; HL = A, read as a signed number
;
; Used by the routine at APPLY_STEP.
;
; H is 0, or 255 when bit 7 of A is set. Used by APPLY_STEP.
;
;   A A signed byte
; O:HL The same number as a word
; O:A H
SIGN_EXTEND_A:
  LD L,A
  XOR A
  BIT 7,L
  JR Z,SIGN_EXTEND_A_0
  CPL
SIGN_EXTEND_A_0:
  LD H,A
  RET

; HL = DE * A
;
; Used by the routine at TURN_SPRITE.
;
; A shift-and-add multiply, a bit of A at a time from the top; the result keeps
; its low 16 bits. A goes round eight places back to itself, and B ends at 0.
; The only caller is the upside-down half of TURN_SPRITE, which never runs, so
; neither does this. Alien 8's routine of the same name is the same idea.
;
;   A One factor
;   DE The other
; O:HL The product
HL_EQUALS_DE_X_A:
  LD HL,$0000             ; HL = 0; eight bits
  LD B,$08                ;
HL_EQUALS_DE_X_A_0:
  ADD HL,HL                ; Double HL; add DE when the next bit of A, from the
  RLCA                     ; top, is set
  JR NC,HL_EQUALS_DE_X_A_1 ;
  ADD HL,DE                ;
HL_EQUALS_DE_X_A_1:
  DJNZ HL_EQUALS_DE_X_A_0  ;
  RET                     ; A is back as it was; B is 0

; Build the drawing tables
;
; Used by the routine at NEW_GAME.
;
; Run at every new game (NEW_GAME). Fills the six pages from MIRROR_TABLES, the
; six from SHIFT_TABLES, and REVERSE_TABLE with the tables the drawing of
; sprites and tiles reads to put a byte at any even pixel.
;
; The six pages from SHIFT_TABLES up are every byte value shifted right two,
; four and six places, in pairs: page $FA holds a byte shifted right two, the
; part that stays in its own byte, and page $FB the two bits that fall out into
; the next byte; $FC and $FD the same for four places, $FE and $FF for six. The
; loop builds them the other way about: it shifts each value left across two
; bytes, two places at a time, and stores the pair after each shift from the
; top page down, so the high byte of a shift left by eight less s is the shift
; right by s. The six from MIRROR_TABLES are the same for every value with its
; bits reversed first, for tiles drawn mirrored; and REVERSE_TABLE is every
; value reversed, for mirroring sprites (TURN_SPRITE) and tiles on a byte
; boundary.
;
; Only even shifts are built because nothing is drawn at an odd pixel: the
; drawing ignores bit 0 of x. Knight Lore, Alien 8 and Pentagram build seven
; shifts, complemented; these are three, and plain. Checked in the simulator:
; after this routine every byte of the thirteen pages is as described, and the
; page between them, UNUSED_F800, is not touched.
MAKE_TABLES:
  LD L,$00                ; For each value L: DE = L, starting at the top page
MAKE_TABLES_0:
  LD D,$00                ;
  LD E,L                  ;
  LD H,$FF                ;
  LD B,$03                ;
MAKE_TABLES_1:
  SLA E                   ; Shift DE left two places; the low byte to page H
  RL D                    ; and the high to the page below; three times, for
  SLA E                   ; pages $FF down to $FA
  RL D                    ;
  LD (HL),E               ;
  DEC H                   ;
  LD (HL),D               ;
  DEC H                   ;
  DJNZ MAKE_TABLES_1      ;
  INC L                   ; The next value
  JR NZ,MAKE_TABLES_0     ;
  LD L,$00                ; Again with the value's bits reversed first: C = L
MAKE_TABLES_2:
  LD D,$00                ; back to front
  LD B,$08                ;
  LD A,L                  ;
MAKE_TABLES_3:
  RRCA                    ;
  RL C                    ;
  DJNZ MAKE_TABLES_3      ;
  LD E,C                  ;
  LD H,$F7                ; ...shifted and stored the same way on pages $F7
  LD B,$03                ; down to $F2
MAKE_TABLES_4:
  SLA E                   ;
  RL D                    ;
  SLA E                   ;
  RL D                    ;
  LD (HL),E               ;
  DEC H                   ;
  LD (HL),D               ;
  DEC H                   ;
  DJNZ MAKE_TABLES_4      ;
  INC L                   ; The next value
  JR NZ,MAKE_TABLES_2     ;
  LD HL,REVERSE_TABLE     ; Page $F9: each value's bits in reverse order
MAKE_TABLES_5:
  LD D,L                  ;
  LD B,$08                ;
MAKE_TABLES_6:
  SRL D                   ;
  RL E                    ;
  DJNZ MAKE_TABLES_6      ;
  LD (HL),E               ;
  INC L                   ;
  JR NZ,MAKE_TABLES_5     ;
  RET                     ; Done

; Copy the play area's pixels from the buffer to the screen
;
; Used by the routine at SHOW_PLAY_AREA.
;
; The buffer's row 0 is the bottom line of the play area, since the game's y
; counts upwards, so the copy starts there, at line 127 of the screen, and
; works up to line 16. It uses the stack: SP is pointed just past the end of a
; screen line, each PUSH puts two buffer bytes onto it, and eleven of them fill
; the 22 columns 7 to 28, while HL reads the buffer backwards. Only bytes 2 to
; 23 of each 24-byte buffer row are copied: the first two are a margin that
; sprites at the left edge are drawn into unseen (DRAW_SPRITE). Interrupts are
; off throughout the game, so nothing else uses the stack meanwhile. Checked in
; the simulator: buffer row 0 goes to line 127, row 111 to line 16, and byte 2
; of a row to column 7.
COPY_BUFFER:
  LD (SAVED_SP),SP        ; Keep SP; point it just past column 28 of line 127,
  LD SP,$4FFD             ; the play area's bottom line
  LD B,$70                ; 112 lines, from the last byte of the buffer's row 0
  LD HL,$E5DB             ;
COPY_BUFFER_0:
  LD D,(HL)               ; Push the row's last 22 bytes onto the line, right
  DEC HL                  ; to left
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  PUSH DE                 ;
  EX DE,HL                ; HL = SP less 234: the same columns a pixel line up,
  LD HL,$FF16             ; as far as moving within a character cell goes
  ADD HL,SP               ;
  LD A,H                  ; That is right unless the low bits of H became 7:
  CPL                     ; the line was the top of a character cell
  AND $07                 ;
  JP NZ,COPY_BUFFER_1     ;
  LD A,L                  ; Then a character row up: L less 32, and H back up
  SUB $20                 ; by 8 unless that crossed into the third above
  LD L,A                  ;
  JP C,COPY_BUFFER_1      ;
  LD A,H                  ;
  ADD A,$08               ;
  LD H,A                  ;
COPY_BUFFER_1:
  LD SP,HL                ; Point SP there; HL = the end of the next buffer row
  LD HL,$002D             ; (45 on from byte 2 of this one)
  ADD HL,DE               ;
  DJNZ COPY_BUFFER_0      ;
  LD SP,(SAVED_SP)        ; Restore SP
  RET                     ;

; Copy the play area's attributes from the buffer to the screen
;
; Used by the routine at SHOW_PLAY_AREA.
;
; As COPY_BUFFER, a character row at a time: the attribute buffer's row 0, the
; play area's bottom row, goes to row 15 of the screen and its row 13 to row 2,
; bytes 2 to 23 of each to columns 7 to 28.
COPY_ATTR_BUFFER:
  LD (SAVED_SP),SP        ; Keep SP; point it just past column 28 of attribute
  LD SP,$59FD             ; row 15; 14 rows, from the end of the buffer's row 0
  LD B,$0E                ;
  LD HL,$F05B             ;
COPY_ATTR_BUFFER_0:
  LD D,(HL)               ; Push the row's last 22 bytes
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  DEC HL                  ;
  PUSH DE                 ;
  LD D,(HL)               ;
  DEC HL                  ;
  LD E,(HL)               ;
  PUSH DE                 ;
  EX DE,HL                ; SP up a row: 10 more to make 32; HL to the end of
  LD HL,$FFF6             ; the next buffer row
  ADD HL,SP               ;
  LD SP,HL                ;
  LD HL,$002D             ;
  ADD HL,DE               ;
  DJNZ COPY_ATTR_BUFFER_0 ;
  LD SP,(SAVED_SP)        ; Restore SP
  RET                     ;

; Show this turn's play area, and clear the buffers for the next
;
; Used by the routine at NEW_GAME.
;
; Called at the end of every turn (NEW_GAME): copies the pixels and the
; attributes to the screen (COPY_BUFFER, COPY_ATTR_BUFFER), and goes on into
; CLEAR_BUFFER.
;
; The entry point CLEAR_BUFFER, also used at a new game (NEW_GAME), by the menu
; (MENU) and at the end of a game (GAME_OVER), fills the attribute buffer with
; bright white ink on the paper colour in FLASH -- black but for the turn after
; a villain dies -- and the pixel buffer with zeros, both with PUSHes from the
; top down. The fill of the attributes starts just below ATTR_SPILL, so that
; byte is never written here.
;
; FILL_BELOW_HL is the fill: B rows of 24 bytes, ending at HL, all DE.
;
; O:HL The lowest address filled (the buffer's start)
SHOW_PLAY_AREA:
  CALL COPY_BUFFER        ; Copy the pixels and the attributes to the screen
  CALL COPY_ATTR_BUFFER   ;
; This entry point is used by the routines at NEW_GAME, MENU and GAME_OVER.
CLEAR_BUFFER:
  LD HL,ATTR_SPILL        ; CLEAR_BUFFER: the attributes, 14 rows of 24 bytes
  LD A,(FLASH)            ; below ATTR_SPILL, each FLASH's paper with bright
  OR $47                  ; white ink
  LD E,A                  ;
  LD D,A                  ;
  LD B,$0E                ;
  CALL FILL_BELOW_HL      ;
  LD HL,ATTR_BUFFER       ; Then the pixels, 112 rows of 24 bytes below
  LD DE,$0000             ; ATTR_BUFFER, all zeros
  LD B,$70                ;
FILL_BELOW_HL:
  LD (SAVED_SP),SP        ; FILL_BELOW_HL: keep SP and point it at the end of
  LD SP,HL                ; the area
SHOW_PLAY_AREA_0:
  PUSH DE                 ; Twelve pushes a row
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  DJNZ SHOW_PLAY_AREA_0   ;
  LD HL,$0000             ; HL = the lowest byte filled; restore SP
  ADD HL,SP               ;
  LD SP,(SAVED_SP)        ;
  RET                     ;

; Read a half-row of the keyboard
;
; Used by the routines at PLAY_TUNE_ONCE, MENU, READ_CONTROLS and PAUSE.
;
; Knight Lore's, Alien 8's and Pentagram's routine, byte for byte. IN A,($FE)
; puts A on the top half of the address bus, so each 0 bit in A selects a
; half-row, and two or more can be read at once; the CPL turns the active-low
; bits the right way up, so a key held is a 1, and Z is set when none of the
; five is held.
;
; The OUT before it is not needed for the read. It writes A to port A*256+$FD,
; which nothing on a 48K Spectrum answers. A 128K machine's paging port would
; decode it whenever A has bit 7 clear, and READ_CONTROLS sends $7F with the
; keyboard and $7E with every method, every turn, as PAUSE does: in 128 mode
; that would page RAM 7 or 6 over the top 16K, where the game's code and tables
; are, show the other screen and lock the paging. Read, not tried on a 128K;
; Pentagram's identical routine was tried and reset the machine at the first
; turn of play.
;
;   A The half-rows to read: a 0 bit for each
; O:A Bits 0-4 the keys held, 1 for held
; O:F Z set if none is held
READ_KEYS:
  OUT ($FD),A             ; The OUT that a 128K would take for paging (see
                          ; above)
  IN A,($FE)              ; Read the half-rows; held keys as 1s
  CPL                     ;
  AND $1F                 ;
  RET                     ;

; Read the controls into CONTROLS
;
; Used by the routine at UPDATE_KNIGHT.
;
; Called once a turn by the knight's controls (UPDATE_KNIGHT). Reads the
; keyboard or a joystick, by the method in bits 1-2 of CONTROL, into one byte,
; CONTROLS: bit 0 left, 1 right, 2 up, 3 fire, 4 down, 5 turn the town round --
; what each does is the knight's controls' business (UPDATE_KNIGHT). Bits 6 and
; 7 are never set.
;
; The keyboard: X, V, B and M left, C and N right; the whole of the A-G and
; H-ENTER rows up; the whole of the Q-T and Y-P rows fire; any number key down.
; The bottom row is not alternate keys, as Pentagram's is (Z, C, M and B one
; way, X, V, SYMBOL SHIFT and N the other): here Z and SYMBOL SHIFT are the key
; that turns the town round, and of the rest X, V, B and M turn one way and C
; and N the other.
;
; A joystick: the Kempston stick from port 31; the cursor keys, 5 left, 8
; right, 7 up, 6 down and 0 fire; Interface II, the 6-0 keys for one stick (6
; left, 7 right, 8 down, 9 up, 0 fire) and 1-5 for the other, read together.
; With any method, Z or SYMBOL SHIFT sets bit 5 (half-rows $7F and $FE read
; together: bit 1 is either). SPACE and CAPS SHIFT do nothing here: PAUSE reads
; them for the pause.
;
; Measured in the simulator, a key or a stick direction at a time for each
; method: every key and direction sets the bits above and nothing else.
;
; O:A The controls, as stored in CONTROLS
READ_CONTROLS:
  LD A,(CONTROL)          ; Bits 1-2 of CONTROL: 0 the keyboard, 1 Kempston, 2
  RRCA                    ; the cursor keys, 3 Interface II
  AND $03                 ;
  JP Z,READ_CONTROLS_17   ;
  DEC A                   ;
  JR Z,READ_CONTROLS_6    ;
  DEC A                   ;
  JR Z,READ_CONTROLS_12   ;
  LD A,$F7                ; Interface II: the 1-5 half-row, turned end for end
  CALL READ_KEYS          ; so that 5 is bit 0 and 1 bit 4, as 0 and 6 are in
  PUSH BC                 ; the 6-0 half-row
  LD B,$05                ;
READ_CONTROLS_0:
  RRA                     ;
  RL C                    ;
  DJNZ READ_CONTROLS_0    ;
  LD A,C                  ;
  POP BC                  ;
  LD C,A                  ;
  LD A,$EF                ; ...ORed with the 6-0 half-row: bit 0 fire (0 or 5),
  CALL READ_KEYS          ; 1 up (9 or 4), 2 down (8 or 3), 3 right (7 or 2), 4
  OR C                    ; left (6 or 1)
  LD C,$00                ; Rearranged into the controls' bits
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_1    ;
  SET 3,C                 ;
READ_CONTROLS_1:
  BIT 1,A                 ;
  JR Z,READ_CONTROLS_2    ;
  SET 2,C                 ;
READ_CONTROLS_2:
  BIT 2,A                 ;
  JR Z,READ_CONTROLS_3    ;
  SET 4,C                 ;
READ_CONTROLS_3:
  BIT 3,A                 ;
  JR Z,READ_CONTROLS_4    ;
  SET 1,C                 ;
READ_CONTROLS_4:
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_5    ;
  SET 0,C                 ;
READ_CONTROLS_5:
  JP READ_CONTROLS_24     ; On to the key that turns the town round
READ_CONTROLS_6:
  IN A,($1F)              ; Kempston: bit 0 right, 1 left, 2 down, 3 up, 4
  LD C,$00                ; fire, rearranged
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_7    ;
  SET 1,C                 ;
READ_CONTROLS_7:
  BIT 1,A                 ;
  JR Z,READ_CONTROLS_8    ;
  SET 0,C                 ;
READ_CONTROLS_8:
  BIT 2,A                 ;
  JR Z,READ_CONTROLS_9    ;
  SET 4,C                 ;
READ_CONTROLS_9:
  BIT 3,A                 ;
  JR Z,READ_CONTROLS_10   ;
  SET 2,C                 ;
READ_CONTROLS_10:
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_11   ;
  SET 3,C                 ;
READ_CONTROLS_11:
  JP READ_CONTROLS_24     ; On to the key that turns the town round
READ_CONTROLS_12:
  LD C,$00                ; The cursor keys: 5 left
  LD A,$F7                ;
  CALL READ_KEYS          ;
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_13   ;
  SET 0,C                 ;
READ_CONTROLS_13:
  LD A,$EF                ; 0 fire, 7 up, 8 right, 6 down
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,READ_CONTROLS_14   ;
  SET 3,C                 ;
READ_CONTROLS_14:
  BIT 3,A                 ;
  JR Z,READ_CONTROLS_15   ;
  SET 2,C                 ;
READ_CONTROLS_15:
  BIT 2,A                 ;
  JR Z,READ_CONTROLS_16   ;
  SET 1,C                 ;
READ_CONTROLS_16:
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_24   ;
  SET 4,C                 ;
  JR READ_CONTROLS_24     ;
READ_CONTROLS_17:
  LD A,$FE                ; The keyboard: X and V left, C right, from the CAPS
  CALL READ_KEYS          ; SHIFT-V half-row turned two places
  RRCA                    ;
  RRCA                    ;
  BIT 2,A                 ;
  JR Z,READ_CONTROLS_18   ;
  SET 0,A                 ;
READ_CONTROLS_18:
  AND $03                 ;
  LD C,A                  ;
  LD A,$7F                ; M and B left, N right
  CALL READ_KEYS          ;
  BIT 2,A                 ;
  JR Z,READ_CONTROLS_19   ;
  SET 0,C                 ;
READ_CONTROLS_19:
  BIT 3,A                 ;
  JR Z,READ_CONTROLS_20   ;
  SET 1,C                 ;
READ_CONTROLS_20:
  BIT 4,A                 ;
  JR Z,READ_CONTROLS_21   ;
  SET 0,C                 ;
READ_CONTROLS_21:
  LD A,$BD                ; A-G and H-ENTER: up
  CALL READ_KEYS          ;
  JR Z,READ_CONTROLS_22   ;
  SET 2,C                 ;
READ_CONTROLS_22:
  LD A,$DB                ; Q-T and Y-P: fire
  CALL READ_KEYS          ;
  JR Z,READ_CONTROLS_23   ;
  SET 3,C                 ;
READ_CONTROLS_23:
  LD A,$E7                ; 1-5 and 6-0: down
  CALL READ_KEYS          ;
  JR Z,READ_CONTROLS_24   ;
  SET 4,C                 ;
READ_CONTROLS_24:
  LD A,$7E                ; Every method: Z or SYMBOL SHIFT turns the town
  CALL READ_KEYS          ; round (bit 5)
  BIT 1,A                 ;
  JR Z,READ_CONTROLS_25   ;
  SET 5,C                 ;
READ_CONTROLS_25:
  LD A,C                  ; Store the controls
  LD (CONTROLS),A         ;
  RET                     ;

; Pause, when SPACE or CAPS SHIFT is pressed on its own
;
; Used by the routine at NEW_GAME.
;
; Called once a turn by the main loop, at the end of the turn (NEW_GAME).
; Half-rows $7F and $FE are read together, so bit 0 is SPACE or CAPS SHIFT and
; bits 1-4 are the other eight keys of the two rows; the pause needs bit 0 and
; none of the others, so no key that plays the game starts one. It waits for
; the key to be let go, then for a press and a release, and the game goes on.
;
; Pentagram's pause (and Alien 8's) is the same test and the same waits, but
; beeps as it pauses and as it goes on, and turns interrupts on while it waits;
; Nightshade's is silent and leaves them off.
PAUSE:
  LD A,$7E                ; Not SPACE or CAPS SHIFT, or another key of those
  CALL READ_KEYS          ; two rows with it: no pause
  BIT 0,A                 ;
  RET Z                   ;
  AND $1E                 ;
  RET NZ                  ;
PAUSE_0:
  LD A,$7E                ; Wait for the key to be let go...
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,PAUSE_0           ;
PAUSE_1:
  LD A,$7E                ; ...pressed again...
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR Z,PAUSE_1            ;
PAUSE_2:
  LD A,$7E                ; ...and let go
  CALL READ_KEYS          ;
  BIT 0,A                 ;
  JR NZ,PAUSE_2           ;
  RET                     ;

; Find an object's sprite, and turn its stored data the way the object wants it
;
; Used by the routine at DRAW_SPRITE.
;
; The graphic (+0) indexes GRAPHICS for the sprite. A sprite is a width byte --
; bits 0-3 the width in bytes, bit 7 set while its data is stored upside down,
; bit 6 while it is stored mirrored -- a height byte, and then a mask byte and
; an image byte for each byte of each row, the bottom row first. Bits 7 and 6
; of the object's flags (+7) say how it wants to be drawn. Where they differ
; from the sprite's, the data is turned in place and the sprite's bit toggled,
; so an object that keeps facing one way costs nothing after the first time,
; while two objects sharing a sprite and facing opposite ways turn it back and
; forth every time each is drawn.
;
; Upside down swaps whole rows end for end, the first with the last, working
; inwards. Mirroring (MIRROR_SPRITE_DATA, also entered by MIRROR_SPRITE)
; reverses the order of each row's mask and image pairs and the bits of every
; byte, through REVERSE_TABLE: a row's pairs are read, reversed, onto the stack
; and popped back in the opposite order.
;
; Nothing in the game sets bit 7 of a record's flags. Every write to that byte
; was read: the records are cleared or copied from templates that hold 0 there;
; the rest set or clear bits 0, 1 and 5, set bit 6 from the view or the facing,
; take bits 6 and 7 from a table whose four bytes have bit 7 clear
; (FACING_LOOKS), or copy another record's flags. So the upside-down half, and
; the multiply it uses (HL_EQUALS_DE_X_A), never run -- which the build's
; sessions agree with -- and every sprite's bit 7 stays clear. Knight Lore's
; objects do turn upside down; Pentagram's routine is the same as this one, and
; Alien 8's nearly so.
;
;   IX The object
; O:DE The sprite (its width byte)
TURN_SPRITE:
  LD A,(IX+$00)           ; DE = the sprite, kept on the stack
  LD BC,GRAPHICS          ;
  CALL TABLE_WORD         ;
  EX DE,HL                ;
  PUSH DE                 ;
  LD A,(DE)               ; Stored the way up the object wants?
  XOR (IX+$07)            ;
  AND $80                 ;
  JR Z,TURN_SPRITE_2      ;
  LD A,(DE)               ; No (it never happens): toggle the sprite's
  XOR $80                 ; upside-down bit
  LD (DE),A               ;
  RLCA                    ; B = the bytes in a row, twice the width
  AND $1E                 ;
  LD B,A                  ;
  INC DE                  ; C = the height; DE on to the data
  LD A,(DE)               ;
  LD C,A                  ;
  INC DE                  ;
  PUSH DE                 ;
  LD E,B                  ; DE = the end of the data: the height times a row's
  LD D,$00                ; bytes on from its start
  CALL HL_EQUALS_DE_X_A   ;
  POP DE                  ;
  ADD HL,DE               ;
  EX DE,HL                ;
  LD A,B                  ; HL = the last byte of the first row, DE the last
  CALL ADD_HL_A           ; byte of the last; C = half the height, the pairs of
  DEC DE                  ; rows to swap
  DEC HL                  ;
  SRL C                   ;
TURN_SPRITE_0:
  PUSH BC                 ; Swap a row with its partner, byte for byte from
TURN_SPRITE_1:
  LD A,(DE)               ; their ends
  LD C,(HL)               ;
  LD (HL),A               ;
  LD A,C                  ;
  LD (DE),A               ;
  DEC HL                  ;
  DEC DE                  ;
  DJNZ TURN_SPRITE_1      ;
  POP BC                  ; HL on to the end of the next row up; DE is already
  LD A,B                  ; at the end of the row below its last
  CALL ADD_HL_A           ;
  LD A,B                  ;
  CALL ADD_HL_A           ;
  DEC C                   ; Until the middle
  JR NZ,TURN_SPRITE_0     ;
TURN_SPRITE_2:
  POP DE                  ; Stored mirrored or not as the object wants?
  PUSH DE                 ;
  LD A,(DE)               ;
  XOR (IX+$07)            ;
  AND $40                 ;
  JR Z,TURN_SPRITE_5      ;
; This entry point is used by the routine at MIRROR_SPRITE.
MIRROR_SPRITE_DATA:
  LD A,(DE)               ; No, or entered here (MIRROR_SPRITE_DATA): toggle
  XOR $40                 ; the sprite's mirrored bit; B and C = the width
  LD (DE),A               ;
  AND $0F                 ;
  LD B,A                  ;
  LD C,A                  ;
  INC DE                  ; A' = the height; HL at the data, and HL' too, with
  LD A,(DE)               ; B' the page of REVERSE_TABLE
  EX AF,AF'               ;
  INC DE                  ;
  EX DE,HL                ;
  PUSH HL                 ;
  EXX                     ;
  POP HL                  ;
  LD B,$F9                ;
  EXX                     ;
TURN_SPRITE_3:
  EXX                     ; Read a row's pairs onto the stack, each byte's bits
  LD C,(HL)               ; reversed
  LD A,(BC)               ;
  LD E,A                  ;
  INC HL                  ;
  LD C,(HL)               ;
  LD A,(BC)               ;
  LD D,A                  ;
  INC HL                  ;
  PUSH DE                 ;
  EXX                     ;
  DJNZ TURN_SPRITE_3      ;
  LD B,C                  ; Pop them back over the same row, the last pair
TURN_SPRITE_4:
  POP DE                  ; first
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  INC HL                  ;
  DJNZ TURN_SPRITE_4      ;
  EX AF,AF'               ; The next row, until the height is done
  DEC A                   ;
  JR Z,TURN_SPRITE_5      ;
  EX AF,AF'               ;
  LD B,C                  ;
  JR TURN_SPRITE_3        ;
TURN_SPRITE_5:
  POP DE                  ; Return the sprite in DE
  RET                     ;

; Mirror a sprite's data, whichever way it is stored now
;
; Used by the routine at DRAW_VILLAINS.
;
; Used only by the panel's villains (DRAW_VILLAINS), which copies the villains'
; sprites straight onto the screen and so needs them the right way round: it
; calls this when a sprite's mirrored bit is set, to turn it back. It never ran
; in the build's sessions, where no villain's sprite was stored mirrored when
; the panel was drawn. The stage-1 journal listed it with the upside-down flip;
; it is the mirroring half of TURN_SPRITE, which does run.
;
;   DE The sprite
; O:DE The same
MIRROR_SPRITE:
  PUSH DE                 ; Push DE for the routine's end to pop; mirror the
  JR MIRROR_SPRITE_DATA   ; sprite

; Draw one object from the draw list
;
; Used by the routine at SORT_AND_DRAW_THINGS.
;
; Called by the depth sort (SORT_AND_DRAW_THINGS) for each object in turn, back
; to front. The projection (PROJECT_THING) gives the object's place relative to
; the knight's in DRAW_X and DRAW_Y; adding the drawing offsets (+C, +D) gives
; the pixel x and y of the sprite's bottom left corner, which are kept in +E
; and +F. The game's y counts upwards: the play area is 112 lines, from y 72 at
; the bottom (line 127 of the screen) to 183 (line 16), and its buffer 24 bytes
; a row from x 16, of which the first two bytes are a margin never shown
; (COPY_BUFFER).
;
; An object is not drawn at all if its x is below 16 or above 202, or its y is
; 184 or more, or either high byte from the projection is not 0. If its bottom
; is below the play area, only its rows from y 72 up are drawn; if its top is
; above, only those below. The knight's graphics (16 to 47, legs and top) are
; cut instead at ARRIVING lines above the bottom, which counts up to 112 as he
; appears at a new life (UPDATE_KNIGHT), so he is shown from the ground up. The
; entry point DRAW_SPRITE_AT draws at +E and +F as they are, with no projection
; and no checks at the sides; the ending's pictures use it (ENDING_PIT_FRONT).
;
; The row loop is unrolled for a sprite five bytes wide, twice: a plain run for
; a sprite whose x is on a byte boundary (SPRITE_ALIGNED_RUN), and a shifted
; run that reads its bytes through the tables of SHIFT_TABLES and touches one
; byte more a row (SPRITE_SHIFTED_RUN). This routine patches the offset of the
; JR in SPRITE_ROW to enter the right run as many units from its end as the
; sprite is wide, and the operand of the ADD at SPRITE_NEXT_ROW
; (SPRITE_SHIFTED_FOUR) with the step from the last byte drawn in a row to the
; first of the row above. Bits 1 and 2 of x choose the shift, 0 (the plain
; run), 2, 4 or 6 pixels; bit 0 is ignored, so things move across in steps of
; two pixels. The stack pointer reads the sprite: SP is pointed at the data and
; each POP DE fetches a mask into E and its image into D, the real SP kept in
; SAVED_SP meanwhile.
;
; On the way out SPRITE_WIDTH holds the bytes drawn a row (one more than the
; sprite's width when shifted), SPRITE_ROWS the rows drawn, and bit 1 of the
; object's flags (+7) is set. Checked in the simulator, drawing a monster's
; sprite into an empty buffer at a range of places: the rows land from y less
; 72 up, the clipping at the bottom, the top and ARRIVING comes out as
; described, and the patched offsets and steps are the ones worked out here.
;
; Nothing is clipped at the sides beyond the tests on x. A sprite starting in a
; row's last byte runs on into the first bytes of the row above: the two margin
; bytes hide two of them, but a four-byte sprite drawn shifted there would put
; its last two into the visible columns 2 and 3 of the row above (the simulator
; shows the run-on; whether it is ever seen in play is not known).
;
; IX The object
DRAW_SPRITE:
  CALL PROJECT_THING      ; Project the object into DRAW_X and DRAW_Y
  LD HL,(DRAW_X)          ; x = DRAW_X plus the offset +C; not drawn unless
  LD A,H                  ; DRAW_X's high byte is 0 and x is 16 to 202
  AND A                   ;
  RET NZ                  ;
  LD A,L                  ;
  ADD A,(IX+$0C)          ;
  CP $CB                  ;
  RET NC                  ;
  CP $10                  ;
  RET C                   ;
  LD (IX+$0E),A           ; Keep x in +E
  LD HL,(DRAW_Y)          ; y = DRAW_Y plus +D; not drawn unless the high byte
  LD A,H                  ; is 0 and y is below 184
  AND A                   ;
  RET NZ                  ;
  LD A,L                  ;
  ADD A,(IX+$0D)          ;
  CP $B8                  ;
  RET NC                  ;
  LD (IX+$0F),A           ; Keep y in +F
; This entry point is used by the routine at ENDING_PIT_FRONT.
DRAW_SPRITE_AT:
  CALL TURN_SPRITE        ; DRAW_SPRITE_AT: find the sprite, turned the right
                          ; way; DE = its width byte
  LD A,(IX+$0E)           ; Bits 1-2 of x: 0 for a sprite on a byte boundary
  AND $06                 ;
  JP Z,DRAW_SPRITE_6      ;
  OR $F8                  ; H = the first page of the shift's pair: $FA, $FC or
  LD H,A                  ; $FE for 2, 4 or 6 pixels
  LD A,(DE)               ; B and SPRITE_WIDTH = the width plus one: a shifted
  INC DE                  ; row touches one byte more
  AND $07                 ;
  INC A                   ;
  LD B,A                  ;
  LD (SPRITE_WIDTH),A     ;
  DEC A                   ; The JR offset into the shifted run: 18 bytes a
  AND $07                 ; unit, entered as many units from the end as the
  ADD A,A                 ; sprite is wide
  LD C,A                  ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,A                 ;
  ADD A,C                 ;
  NEG                     ;
  ADD A,$5A               ;
DRAW_SPRITE_0:
  LD ($E4CC),A            ; Patch it into the JR in SPRITE_ROW, for either run
  LD A,B                  ; The step from the last byte drawn in a row to the
  CPL                     ; first of the next: 25 less the bytes a row; patched
  ADD A,$1A               ; into SPRITE_NEXT_ROW
  LD ($E52A),A            ;
  EX DE,HL                ; HL = the height byte
  LD A,(IX+$00)           ; C = how far up from the bottom may be drawn: the
  SUB $10                 ; whole 112 lines, but ARRIVING for the knight's legs
  CP $20                  ; and top (graphics 16 to 47)
  LD A,$70                ;
  JR NC,DRAW_SPRITE_1     ;
  LD A,(ARRIVING)         ;
DRAW_SPRITE_1:
  LD C,A                  ;
  LD A,(IX+$0F)           ; y less 72: the lines above the play area's bottom;
  SUB $48                 ; below it, clip there
  JR C,DRAW_SPRITE_4      ;
  SUB C                   ; Nothing to draw if it starts at or above the limit
  RET NC                  ;
  NEG                     ; The rows: the lines up to the limit, or the height
  CP (HL)                 ; if fewer; HL on to the data
  JR C,DRAW_SPRITE_2      ;
  LD A,(HL)               ;
DRAW_SPRITE_2:
  INC HL                  ;
  LD (SPRITE_ROWS),A      ;
DRAW_SPRITE_3:
  EX DE,HL                ; BC = the buffer address of the sprite's bottom left
  PUSH HL                 ; byte (BUFFER_ADDRESS), from +E and +F; HL = the
  LD L,(IX+$0E)           ; table page again
  LD H,(IX+$0F)           ;
  CALL BUFFER_ADDRESS     ;
  LD C,L                  ;
  LD B,H                  ;
  POP HL                  ;
  LD (SAVED_SP),SP        ; Keep SP, and point it at the data
  EX DE,HL                ;
  LD SP,HL                ;
  EX DE,HL                ;
  SET 1,(IX+$07)          ; Mark the object drawn
  LD A,(SPRITE_ROWS)      ; A = the rows; into the row loop
  JR SPRITE_ROW           ;
DRAW_SPRITE_4:
  NEG                     ; Below the bottom: C = the lines under it; the rows
  LD C,A                  ; left above it, if any
  LD A,(HL)               ;
  SUB C                   ;
  RET M                   ;
  RET Z                   ;
  LD (SPRITE_ROWS),A      ;
  LD B,$00                ; Skip C rows of the data, twice the width a row, and
  DEC HL                  ; start at the bottom line
  LD A,(HL)               ;
  AND $3F                 ;
  INC HL                  ;
  INC HL                  ;
  SLA C                   ;
  RL B                    ;
DRAW_SPRITE_5:
  ADD HL,BC               ;
  DEC A                   ;
  JR NZ,DRAW_SPRITE_5     ;
  LD (IX+$0F),$48         ;
  JR DRAW_SPRITE_3        ; Draw
DRAW_SPRITE_6:
  LD A,(DE)               ; On a byte boundary: B and SPRITE_WIDTH = the width
  INC DE                  ;
  AND $0F                 ;
  LD (SPRITE_WIDTH),A     ;
  LD B,A                  ;
  ADD A,A                 ; The JR offset into the plain run: 8 bytes a unit,
  ADD A,A                 ; entered as many units from the end as the sprite is
  ADD A,A                 ; wide
  NEG                     ;
  SUB $06                 ;
  JR DRAW_SPRITE_0        ;

; The unrolled row of a byte-aligned sprite
;
; Entered by the JR in SPRITE_ROW, as many 8-byte units from the end as the
; sprite is wide. Each unit takes the next mask and image off the stack and
; does one buffer byte: cleared under the mask (CPL, OR E, CPL), the image ORed
; in, stored. The last unit has no INC BC, so a row leaves BC on its last byte,
; which the step patched in at SPRITE_NEXT_ROW allows for.
;
; This first unit is for a fifth byte, and no sprite in the game is wider than
; four (graphics 2, 76 to 79 and 152 are four; read from the graphic table): it
; can never run, which is why the code map took it for data. Knight Lore, Alien
; 8 and Pentagram unroll the same five units.
SPRITE_ALIGNED_RUN:
  POP DE                  ; The unit for the fifth byte from the end
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;

; The rest of the byte-aligned run
;
; The units from the fourth byte from the end, the way in for a sprite four
; bytes wide, to the last, which jumps on to the step to the next row
; (SPRITE_NEXT_ROW, in SPRITE_SHIFTED_FOUR).
SPRITE_ALIGNED_FOUR:
  POP DE                  ; The fourth byte from the end: the next mask and
  LD A,(BC)               ; image; the buffer byte cleared under the mask, the
  CPL                     ; image put in; on to the next byte
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; The third
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; The second
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  INC BC                  ;
  POP DE                  ; The last, with no INC BC
  LD A,(BC)               ;
  CPL                     ;
  OR E                    ;
  CPL                     ;
  OR D                    ;
  LD (BC),A               ;
  JP SPRITE_NEXT_ROW      ; To the step to the next row

; Start a row of a sprite
;
; Used by the routines at DRAW_SPRITE and SPRITE_SHIFTED_FOUR.
;
; The row count goes to A', and A takes the row's first buffer byte: the
; shifted units of SPRITE_SHIFTED_FOUR expect the byte they are finishing to be
; in A already. The JR's offset is patched by DRAW_SPRITE for every sprite,
; into the plain run at SPRITE_ALIGNED_RUN or the shifted one at
; SPRITE_SHIFTED_RUN; as it stands in the listing, an offset of $FE, it is a JR
; to itself.
SPRITE_ROW:
  EX AF,AF'               ; The row count to A'; the row's first buffer byte
  LD A,(BC)               ;
SPRITE_ROW_0:
  JR SPRITE_ROW_0         ; The patched JR into one of the runs

; The unrolled row of a shifted sprite
;
; Entered by the JR in SPRITE_ROW, as many 18-byte units from the end as the
; sprite is wide. H is the first of the pair of pages MAKE_TABLES built for the
; shift: page H gives a byte shifted right, the part that stays in its own
; buffer byte, and page H + 1 the bits that fall out into the next. Each unit
; finishes the buffer byte in A -- cleared under the shifted mask (CPL, OR,
; CPL) and the shifted image ORed in -- stores it, and begins the next byte
; with the parts of the mask and image that fall into it, left in A for the
; next unit. The byte the last unit begins is stored after it.
;
; Pentagram's tables are complemented and its unit ANDs and XORs; Nightshade's
; are plain and the unit complements around the OR, as the byte-aligned run
; does. This first unit is for a fifth byte and never runs (see
; SPRITE_ALIGNED_RUN); the code map took it for data.
SPRITE_SHIFTED_RUN:
  CPL                     ; The unit for the fifth byte from the end
  POP DE                  ;
  LD L,E                  ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  DEC H                   ;

; The rest of the shifted run, and the step to the next row
;
; The units from the fourth byte from the end, the way in for a sprite four
; bytes wide, then the store of the byte the last one began. SPRITE_NEXT_ROW,
; where the byte-aligned run joins, steps BC on to the next row up by the
; amount DRAW_SPRITE patched into the ADD, and goes round again from SPRITE_ROW
; until the rows counted in A' are done. Then the real stack pointer comes back
; from SAVED_SP, and the RET is the return from DRAW_SPRITE.
SPRITE_SHIFTED_FOUR:
  CPL                     ; The fourth byte from the end: finish the byte in A,
  POP DE                  ; cleared under the mask's part from page H and the
  LD L,E                  ; image's part ORed in; store it; on to the next byte
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ; Begin the next: that buffer byte cleared under the
  LD L,E                  ; mask's bits from page H + 1, and the image's ORed
  LD A,(BC)               ; in; left in A
  CPL                     ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  DEC H                   ;
  CPL                     ; The third byte from the end
  POP DE                  ;
  LD L,E                  ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  DEC H                   ;
  CPL                     ; The second
  POP DE                  ;
  LD L,E                  ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  DEC H                   ;
  CPL                     ; The last
  POP DE                  ;
  LD L,E                  ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  LD (BC),A               ;
  INC BC                  ;
  INC H                   ;
  LD L,E                  ;
  LD A,(BC)               ;
  CPL                     ;
  OR (HL)                 ;
  CPL                     ;
  LD L,D                  ;
  OR (HL)                 ;
  DEC H                   ;
  LD (BC),A               ; Store the byte the last unit began
; This entry point is used by the routine at SPRITE_ALIGNED_FOUR.
SPRITE_NEXT_ROW:
  LD A,C                  ; SPRITE_NEXT_ROW: BC on to the first byte of the row
  ADD A,$00               ; above; the ADD's operand is patched by DRAW_SPRITE
  LD C,A                  ;
  LD A,B                  ;
  ADC A,$00               ;
  LD B,A                  ;
  EX AF,AF'               ; Count a row, and draw the next
  DEC A                   ;
  JP NZ,SPRITE_ROW        ;
  LD SP,(SAVED_SP)        ; Restore SP
  RET                     ;

; The buffer address of a pixel position
;
; Used by the routines at PUT_EDGE, PUT_TILE and DRAW_SPRITE.
;
; The buffer's rows are 24 bytes, row 0 the play area's bottom line at y 72,
; and x 16 the start of a row, so a position's byte is at BUFFER plus (y - 72)
; * 24 plus x / 8 - 2. It is worked here as y * 24 plus x / 8 plus a constant,
; the buffer's start less 72 rows and 2 bytes -- which happens to be an address
; in the code, and means nothing as one. Used by the drawing of sprites
; (DRAW_SPRITE) and of the town's tiles (PUT_EDGE, PUT_TILE).
;
;   L x
;   H y
; O:HL The address in the buffer
BUFFER_ADDRESS:
  PUSH BC                 ; A = the byte's column, x / 8
  SRL L                   ;
  SRL L                   ;
  SRL L                   ;
  LD A,L                  ;
  LD L,H                  ; HL = y times 24
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD C,L                  ;
  LD B,H                  ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD C,A                  ; Plus the column
  LD B,$00                ;
  ADD HL,BC               ;
  LD BC,$DF02             ; Plus the buffer's start less 72 rows and 2 bytes
  ADD HL,BC               ;
  POP BC                  ;
  RET                     ;

; Display address of a pixel position
;
; Used by the routines at PICK_UP_THING, PRINT_TEXT_SINGLE_COLOUR and
; PRINT_TEXT.
;
; For drawing straight onto the screen: the carried things (PICK_UP_THING) and
; the text printer's two ways in (PRINT_TEXT_SINGLE_COLOUR, PRINT_TEXT). The y
; here counts up from the screen's bottom line, 0 at line 191. Turns it into
; the display's line counted from the top by complementing it: 255 - y is that
; line plus 64, one third of the screen too many in the top bits, which is
; taken back by adding 56 rather than 64 to the high byte. The same as Knight
; Lore's and Pentagram's routine of this name.
;
;   L x
;   H y, upwards from the screen's bottom line
; O:HL The display address
CALC_VRAM_ADDR:
  PUSH DE                 ; E = x, D = y; DE kept
  EX DE,HL                ;
  LD A,E                  ; L's low five bits: the column, x / 8
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,D                  ; L's top three: the character row within the third,
  CPL                     ; from 255 - y
  RLCA                    ;
  RLCA                    ;
  AND $E0                 ;
  OR L                    ;
  LD L,A                  ;
  LD A,D                  ; H's third
  CPL                     ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $18                 ;
  LD H,A                  ;
  LD A,D                  ; H's pixel line within the cell; adding 56 takes
  CPL                     ; back the extra third
  AND $07                 ;
  OR H                    ;
  ADD A,$38               ;
  LD H,A                  ;
  POP DE                  ; Restore DE
  RET                     ;

; The attribute buffer address of a pixel position
;
; Used by the routines at NEW_GAME, ENDING_PIT_FRONT and COLOUR_WALL.
;
; The attribute buffer's rows are 24 bytes, row 0 the play area's bottom
; character row, so the attribute of a position is at ATTR_BUFFER plus (y - 72)
; / 8 * 24 plus x / 8 - 2. Worked as (y / 8) * 24 plus x / 8 plus a constant,
; the buffer's start less 9 rows and 2 bytes. Used for the knight's colour
; (NEW_GAME), the buildings' (COLOUR_WALL) and the ending's pictures'
; (ENDING_PIT_FRONT).
;
;   L x
;   H y
; O:HL The address in the attribute buffer
ATTR_ADDRESS:
  PUSH BC                 ; HL = y with its low three bits cleared, times
  LD C,L                  ; three: the character row times 24
  LD A,H                  ;
  AND $F8                 ;
  LD L,A                  ;
  LD H,$00                ;
  LD A,C                  ;
  LD C,L                  ;
  LD B,H                  ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  SRL A                   ; Plus x / 8
  SRL A                   ;
  SRL A                   ;
  LD C,A                  ;
  LD B,$00                ;
  ADD HL,BC               ;
  LD BC,$EF6A             ; Plus the buffer's start less 9 rows and 2 bytes
  ADD HL,BC               ;
  POP BC                  ;
  RET                     ;

; HL = HL + A
;
; Used by the routines at NEW_GAME, DRAW_VILLAINS, PLAY_NOTE, PUT_TILE,
; KNIGHT_THROWS and TURN_SPRITE.
;
; A is treated as unsigned. A is left holding H. The same as the earlier
; games'.
;
;   A The number to add
;   HL The number to add it to
; O:HL The sum
ADD_HL_A:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; Clear the screen
;
; Used by the routines at NEW_GAME and GAME_OVER.
;
; The pixels to 0, every attribute to bright white ink on black paper, and the
; border black. At a new game (NEW_GAME) and at the end of one (GAME_OVER).
CLEAR_SCREEN:
  CALL CLR_BITMAP_MEMORY    ; The pixels, then the attributes
  CALL CLR_ATTRIBUTE_MEMORY ;
  LD A,$00                ; A black border
  OUT ($FE),A             ;
  RET                     ;

; Clear the display's pixels
;
; Used by the routine at CLEAR_SCREEN.
;
; All 6144 bytes, through CLEAR_MEMORY.
CLR_BITMAP_MEMORY:
  LD HL,$4000
  LD BC,$1800
  JR CLEAR_MEMORY

; Set the display's attributes to bright white ink on black paper
;
; Used by the routine at CLEAR_SCREEN.
;
; All 768, through the fill at CLEAR_MEMORY.
CLR_ATTRIBUTE_MEMORY:
  LD HL,$5800
  LD BC,$0300
  LD E,$47
  JR FILL_MEMORY

; Clear BC bytes from HL
;
; Used by the routines at NEW_GAME and CLR_BITMAP_MEMORY.
;
; The entry point FILL_MEMORY fills them with E instead. Also used at the start
; and at every new game (START, NEW_GAME) to clear the variables and the object
; records.
;
;   HL The first byte
;   BC How many
; O:BC 0
CLEAR_MEMORY:
  LD E,$00                ; The fill byte, 0
; This entry point is used by the routine at CLR_ATTRIBUTE_MEMORY.
FILL_MEMORY:
  LD (HL),E               ; FILL_MEMORY: BC bytes from HL, all E
  INC HL                  ;
  DEC BC                  ;
  LD A,B                  ;
  OR C                    ;
  JR NZ,FILL_MEMORY       ;
  RET                     ;

; The screen buffer: the play area's pixels
;
; 24 bytes by 112 lines, running on through LOADER_LEFTOVER and BUFFER_REST to
; the attribute buffer (ATTR_BUFFER). The town and the objects are drawn into
; it each turn (PUT_TILE, DRAW_SPRITE), and at the end of the turn it is copied
; to the screen (COPY_BUFFER) and cleared (SHOW_PLAY_AREA). Row 0 is the play
; area's bottom line, y 72, since the game's y counts upwards; only bytes 2 to
; 23 of each row are shown, in columns 7 to 28 of the screen, the first two
; being a margin that sprites at the left edge are drawn into unseen.
;
; These first 60 bytes are the end of the game block as the loader moved it
; (LOADER): zeros, loaded with the game but never anything but the buffer's.
BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The tail of the loaded block, left behind by the move (inside the buffer)
;
; The tape loaded the game block 512 bytes higher than it runs, and the loader
; unscrambled it there and moved it down to ENTRY (LOADER). A move leaves its
; source behind where the two do not overlap, so these 512 bytes are a second
; copy of the game's last 512: from the operand of the first CALL in
; DRAW_SPRITE_AT (DRAW_SPRITE) to the end of the buffer's first 60 bytes --
; byte for byte the same (compared in the snapshot). Part of the buffer:
; cleared before it is read (SHOW_PLAY_AREA), and never run.
LOADER_LEFTOVER:
  DEFB $53,$E3,$DD,$7E,$0E,$E6,$06,$CA,$8E,$E4,$F6,$F8,$67,$1A,$13,$E6
  DEFB $07,$3C,$47,$32,$C2,$BB,$3D,$E6,$07,$87,$4F,$87,$87,$87,$81,$ED
  DEFB $44,$C6,$5A,$32,$CC,$E4,$78,$2F,$C6,$1A,$32,$2A,$E5,$EB,$DD,$7E
  DEFB $00,$D6,$10,$FE,$20,$3E,$70,$30,$03,$3A,$02,$BC,$4F,$DD,$7E,$0F
  DEFB $D6,$48,$38,$2A,$91,$D0,$ED,$44,$BE,$38,$01,$7E,$23,$32,$C3,$BB
  DEFB $EB,$E5,$DD,$6E,$0E,$DD,$66,$0F,$CD,$3A,$E5,$4D,$44,$E1,$ED,$73
  DEFB $AE,$BB,$EB,$F9,$EB,$DD,$CB,$07,$CE,$3A,$C3,$BB,$18,$5B,$ED,$44
  DEFB $4F,$7E,$91,$F8,$C8,$32,$C3,$BB,$06,$00,$2B,$7E,$E6,$3F,$23,$23
  DEFB $CB,$21,$CB,$10,$09,$3D,$20,$FC,$DD,$36,$0F,$48,$18,$C2,$1A,$13
  DEFB $E6,$0F,$32,$C2,$BB,$47,$87,$87,$87,$ED,$44,$D6,$06,$18,$84,$D1
  DEFB $0A,$2F,$B3,$2F,$B2,$02,$03,$D1,$0A,$2F,$B3,$2F,$B2,$02,$03,$D1
  DEFB $0A,$2F,$B3,$2F,$B2,$02,$03,$D1,$0A,$2F,$B3,$2F,$B2,$02,$03,$D1
  DEFB $0A,$2F,$B3,$2F,$B2,$02,$C3,$28,$E5,$08,$0A,$18,$FE,$2F,$D1,$6B
  DEFB $B6,$2F,$6A,$B6,$02,$03,$24,$6B,$0A,$2F,$B6,$2F,$6A,$B6,$25,$2F
  DEFB $D1,$6B,$B6,$2F,$6A,$B6,$02,$03,$24,$6B,$0A,$2F,$B6,$2F,$6A,$B6
  DEFB $25,$2F,$D1,$6B,$B6,$2F,$6A,$B6,$02,$03,$24,$6B,$0A,$2F,$B6,$2F
  DEFB $6A,$B6,$25,$2F,$D1,$6B,$B6,$2F,$6A,$B6,$02,$03,$24,$6B,$0A,$2F
  DEFB $B6,$2F,$6A,$B6,$25,$2F,$D1,$6B,$B6,$2F,$6A,$B6,$02,$03,$24,$6B
  DEFB $0A,$2F,$B6,$2F,$6A,$B6,$25,$02,$79,$C6,$00,$4F,$78,$CE,$00,$47
  DEFB $08,$3D,$C2,$C9,$E4,$ED,$7B,$AE,$BB,$C9,$C5,$CB,$3D,$CB,$3D,$CB
  DEFB $3D,$7D,$6C,$26,$00,$29,$29,$29,$4D,$44,$29,$09,$4F,$06,$00,$09
  DEFB $01,$02,$DF,$09,$C1,$C9,$D5,$EB,$7B,$0F,$0F,$0F,$E6,$1F,$6F,$7A
  DEFB $2F,$07,$07,$E6,$E0,$B5,$6F,$7A,$2F,$0F,$0F,$0F,$E6,$18,$67,$7A
  DEFB $2F,$E6,$07,$B4,$C6,$38,$67,$D1,$C9,$C5,$4D,$7C,$E6,$F8,$6F,$26
  DEFB $00,$79,$4D,$44,$29,$09,$CB,$3F,$CB,$3F,$CB,$3F,$4F,$06,$00,$09
  DEFB $01,$6A,$EF,$09,$C1,$C9,$85,$6F,$7C,$CE,$00,$67,$C9,$CD,$A8,$E5
  DEFB $CD,$B0,$E5,$3E,$00,$D3,$FE,$C9,$21,$00,$40,$01,$00,$18,$18,$0A
  DEFB $21,$00,$58,$01,$00,$03,$1E,$47,$18,$02,$1E,$00,$73,$23,$0B,$78
  DEFB $B1,$20,$F9,$C9,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The rest of the screen buffer
;
; Zeros in the snapshot: the tape loaded nothing here.
BUFFER_REST:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The play area's attributes
;
; 24 bytes by 14 rows, row 0 the play area's bottom character row, two listing
; lines to a row. Filled each turn with bright white ink on the FLASH paper
; (SHOW_PLAY_AREA), coloured where the buildings stand (COLOUR_WALL) and round
; the knight (NEW_GAME), and copied to the screen (COPY_ATTR_BUFFER), bytes 2
; to 23 of each row to columns 7 to 28.
ATTR_BUFFER:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; One byte past the attribute buffer
;
; Written by COLOUR_STRIP when a building's colour, which runs from a wall's
; foot up to the top of the play area, is filled in a row's last byte: the
; attribute rows count up the screen, so the top row's last byte is the
; buffer's last, and the fill goes one past it (measured: 28 of 752 colour
; fills in a run reached it, all at the right-hand edge; none started below the
; buffer). Nothing reads it, and the buffer's own fill (SHOW_PLAY_AREA) starts
; below it.
ATTR_SPILL:
  DEFB $00

; Unused
;
; Neither read nor written in a run measured by stage 1 from the start through
; the menu, play, a new cell and more play (every access from BUFFER up
; recorded in SkoolKit's simulator): the snapshot's zeros. Nothing in the code
; addresses it: the attribute buffer ends below it and the tables start at
; MIRROR_TABLES.
UNUSED_F195:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Lookup tables for drawing mirrored tiles at an even pixel
;
; Six pages built by MAKE_TABLES at every new game: every byte value with its
; bits reversed, then shifted right two, four and six places across two bytes.
; Page $F2 holds the part that stays in a byte for a shift of two and $F3 the
; bits that fall out into the next; $F4 and $F5 the same for four, $F6 and $F7
; for six. The tile drawing (PUT_TILE) reads a pair when it draws a building's
; other face (DRAW_PASS non-zero), mirrored; the sprites are mirrored in place
; instead (TURN_SPRITE). Zeros in the snapshot.
MIRROR_TABLES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Unused
;
; Between the two sets of tables, and neither read nor written in stage 1's
; measured run: the snapshot's zeros. It is where the tables' addressing --
; page $F0 or $F8 plus bits 1 and 2 of x -- would put a shift of 0, which is
; never looked up: a sprite or tile on a byte boundary takes a path of its own
; (DRAW_SPRITE, PUT_TILE). The mirrored set's page for 0 would be $F0, inside
; the attribute buffer.
UNUSED_F800:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Each byte with its bits in reverse order
;
; Built by MAKE_TABLES at every new game. Sprites are mirrored through it
; (TURN_SPRITE), and the tiles of a building's other face on a byte boundary
; (PUT_TILE). Zeros in the snapshot.
REVERSE_TABLE:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Lookup tables for drawing at an even pixel
;
; Six pages built by MAKE_TABLES at every new game: every byte value shifted
; right two, four and six places across two bytes. Page $FA holds the part that
; stays in a byte for a shift of two and $FB the bits that fall out into the
; next; $FC and $FD the same for four, $FE and $FF for six. The sprite drawing
; (SPRITE_SHIFTED_FOUR) and the tile drawing (PUT_TILE) read a pair, page $F8
; plus bits 1 and 2 of x and the page above it.
;
; Until the game builds them, these pages hold what the machine left there
; before the tape loaded, all overwritten before the game reads any of it
; (measured by stage 1): zeros; below RAMTOP, what the ROM's stack held as the
; BASIC loader ran -- among it ERR_SP's return into the ROM's main loop, and
; the end marker of the GOSUB stack at RAMTOP itself; and in the last 168 bytes
; the ROM's user-defined graphics, the letters A to U as the ROM sets them up.
SHIFT_TABLES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
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
  DEFB $E4,$50,$1D,$17,$DC,$0A,$CE,$0B,$E7,$50,$1A,$17,$DB,$02,$4D,$00
  DEFB $A3,$52,$00,$00,$2A,$3F,$DB,$02,$B7,$2D,$34,$5E,$2F,$5E,$80,$5B
  DEFB $2B,$2D,$65,$33,$00,$00,$ED,$10,$0D,$00,$53,$00,$2F,$20,$ED,$1F
  DEFB $DB,$1F,$76,$1B,$03,$13,$00,$3E,$00,$3C,$42,$42,$7E,$42,$42,$00
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

