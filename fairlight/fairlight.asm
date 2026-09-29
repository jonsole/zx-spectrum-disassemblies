    DEVICE ZXSPECTRUM48
; The object record's fields: the (IX+n) offsets named in the listing.
OBJ_SCREEN_X EQU $00
OBJ_SCREEN_Y EQU $01
OBJ_WIDTH EQU $02
OBJ_ROWS EQU $03
OBJ_SPRITE EQU $04
OBJ_X EQU $06
OBJ_TOP EQU $07
OBJ_Z EQU $08
OBJ_LEN_X EQU $09
OBJ_HEIGHT EQU $0A
OBJ_LEN_Z EQU $0B
OBJ_KIND EQU $0C
OBJ_DIRECTION EQU $0D
OBJ_STATE EQU $0E
OBJ_COUNT EQU $0F
OBJ_WEIGHT EQU $10
OBJ_FRAME EQU $11
OBJ_COURSE EQU $12
OBJ_NUMBER EQU $13
OBJ_SIZE EQU $14
; The variables' base, which IY holds: (IY+ROOM-V) is ROOM.
V EQU $FF80
  ORG $5B00

; Sprite, 8 by 8 (the template for type 51)
SPRITE5B00:
  DEFB $18                ; Image, the top row first
  DEFB $0C                ;
  DEFB $34                ;
  DEFB $26                ;
  DEFB $2A                ;
  DEFB $34                ;
  DEFB $42                ;
  DEFB $00                ;
  DEFB $E7                ; Mask: a bit set where the background shows through
  DEFB $F3                ;
  DEFB $C3                ;
  DEFB $C1                ;
  DEFB $C1                ;
  DEFB $C1                ;
  DEFB $BD                ;
  DEFB $FF                ;

; Sprite, 8 by 8
;
; Seen on an object in the build's sessions.
SPRITE5B10:
  DEFB $10                ; Image, the top row first
  DEFB $18                ;
  DEFB $38                ;
  DEFB $2C                ;
  DEFB $44                ;
  DEFB $50                ;
  DEFB $3C                ;
  DEFB $18                ;
  DEFB $EF                ; Mask: a bit set where the background shows through
  DEFB $E7                ;
  DEFB $C7                ;
  DEFB $C3                ;
  DEFB $83                ;
  DEFB $83                ;
  DEFB $C3                ;
  DEFB $E7                ;

; Sprite, 8 by 8
;
; Seen on an object in the build's sessions.
SPRITE5B20:
  DEFB $02                ; Image, the top row first
  DEFB $0E                ;
  DEFB $1C                ;
  DEFB $3D                ;
  DEFB $33                ;
  DEFB $42                ;
  DEFB $66                ;
  DEFB $1C                ;
  DEFB $FD                ; Mask: a bit set where the background shows through
  DEFB $F1                ;
  DEFB $E3                ;
  DEFB $C2                ;
  DEFB $C0                ;
  DEFB $81                ;
  DEFB $81                ;
  DEFB $E3                ;

; Sprite, 16 by 23 (the template for type 52)
SPRITE5B30:
  DEFB $0F,$E0            ; Image, the top row first
  DEFB $18,$30            ;
  DEFB $23,$18            ;
  DEFB $24,$38            ;
  DEFB $33,$D0            ;
  DEFB $18,$38            ;
  DEFB $1E,$48            ;
  DEFB $2B,$98            ;
  DEFB $10,$10            ;
  DEFB $1C,$08            ;
  DEFB $0E,$48            ;
  DEFB $0B,$90            ;
  DEFB $05,$18            ;
  DEFB $02,$18            ;
  DEFB $02,$30            ;
  DEFB $03,$30            ;
  DEFB $02,$60            ;
  DEFB $04,$C0            ;
  DEFB $05,$C0            ;
  DEFB $07,$00            ;
  DEFB $03,$00            ;
  DEFB $0E,$00            ;
  DEFB $0C,$00            ;
  DEFB $E0,$0F            ; Mask: a bit set where the background shows through
  DEFB $C3,$87            ;
  DEFB $CC,$63            ;
  DEFB $CB,$83            ;
  DEFB $C4,$27            ;
  DEFB $C3,$C3            ;
  DEFB $C1,$03            ;
  DEFB $C4,$43            ;
  DEFB $C3,$E7            ;
  DEFB $C3,$D3            ;
  DEFB $E0,$33            ;
  DEFB $E4,$67            ;
  DEFB $E2,$E3            ;
  DEFB $F9,$A3            ;
  DEFB $F9,$47            ;
  DEFB $F8,$C7            ;
  DEFB $F9,$8F            ;
  DEFB $F3,$1F            ;
  DEFB $F0,$1F            ;
  DEFB $F0,$7F            ;
  DEFB $F8,$7F            ;
  DEFB $E0,$FF            ;
  DEFB $E1,$FF            ;

; Sprite, 16 by 23
;
; Seen on an object in the build's sessions.
SPRITE5B8C:
  DEFB $02,$C0            ; Image, the top row first
  DEFB $07,$E0            ;
  DEFB $1E,$30            ;
  DEFB $3B,$98            ;
  DEFB $30,$48            ;
  DEFB $08,$98            ;
  DEFB $2E,$34            ;
  DEFB $27,$EC            ;
  DEFB $33,$98            ;
  DEFB $10,$38            ;
  DEFB $38,$70            ;
  DEFB $2E,$E0            ;
  DEFB $10,$60            ;
  DEFB $30,$C0            ;
  DEFB $30,$80            ;
  DEFB $19,$80            ;
  DEFB $1B,$80            ;
  DEFB $0E,$80            ;
  DEFB $04,$C0            ;
  DEFB $02,$C0            ;
  DEFB $01,$C0            ;
  DEFB $01,$80            ;
  DEFB $00,$C0            ;
  DEFB $F9,$1F            ; Mask: a bit set where the background shows through
  DEFB $F0,$0F            ;
  DEFB $C1,$87            ;
  DEFB $C4,$63            ;
  DEFB $CC,$93            ;
  DEFB $CB,$63            ;
  DEFB $D1,$C3            ;
  DEFB $D8,$13            ;
  DEFB $CC,$63            ;
  DEFB $C7,$C3            ;
  DEFB $C3,$87            ;
  DEFB $D1,$0F            ;
  DEFB $C7,$8F            ;
  DEFB $CB,$1F            ;
  DEFB $CE,$3F            ;
  DEFB $C6,$3F            ;
  DEFB $E0,$3F            ;
  DEFB $E1,$3F            ;
  DEFB $F3,$1F            ;
  DEFB $F9,$1F            ;
  DEFB $FC,$1F            ;
  DEFB $FC,$13            ;
  DEFB $FE,$1F            ;

; Sprite, 16 by 23
;
; Seen on an object in the build's sessions.
SPRITE5BE8:
  DEFB $03,$00            ; Image, the top row first
  DEFB $0C,$E0            ;
  DEFB $08,$38            ;
  DEFB $27,$8C            ;
  DEFB $2C,$4C            ;
  DEFB $38,$18            ;
  DEFB $2C,$3C            ;
  DEFB $24,$7C            ;
  DEFB $10,$DC            ;
  DEFB $10,$08            ;
  DEFB $08,$2C            ;
  DEFB $07,$68            ;
  DEFB $0C,$C8            ;
  DEFB $06,$18            ;
  DEFB $05,$10            ;
  DEFB $03,$30            ;
  DEFB $03,$F0            ;
  DEFB $05,$60            ;
  DEFB $06,$60            ;
  DEFB $02,$C0            ;
  DEFB $03,$80            ;
  DEFB $01,$80            ;
  DEFB $01,$80            ;
  DEFB $F8,$7F            ; Mask: a bit set where the background shows through
  DEFB $E0,$0F            ;
  DEFB $E3,$83            ;
  DEFB $C0,$63            ;
  DEFB $C0,$33            ;
  DEFB $C6,$63            ;
  DEFB $D3,$C3            ;
  DEFB $C8,$03            ;
  DEFB $C4,$23            ;
  DEFB $C3,$E3            ;
  DEFB $E1,$13            ;
  DEFB $F0,$13            ;
  DEFB $E3,$33            ;
  DEFB $F1,$63            ;
  DEFB $F2,$E7            ;
  DEFB $F8,$47            ;
  DEFB $F8,$07            ;
  DEFB $F2,$8F            ;
  DEFB $F1,$8F            ;
  DEFB $F9,$1F            ;
  DEFB $F8,$3F            ;
  DEFB $FC,$3F            ;
  DEFB $FC,$3F            ;

; Sprite, 8 by 16 (the template for type 53)
SPRITE5C44:
  DEFB $22                ; Image, the top row first
  DEFB $37                ;
  DEFB $7D                ;
  DEFB $6F                ;
  DEFB $6E                ;
  DEFB $3E                ;
  DEFB $2C                ;
  DEFB $78                ;
  DEFB $30                ;
  DEFB $70                ;
  DEFB $60                ;
  DEFB $60                ;
  DEFB $E0                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $80                ;
  DEFB $DD                ; Mask: a bit set where the background shows through
  DEFB $C8                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $81                ;
  DEFB $C1                ;
  DEFB $43                ;
  DEFB $87                ;
  DEFB $8F                ;
  DEFB $8F                ;
  DEFB $9F                ;
  DEFB $9F                ;
  DEFB $1F                ;
  DEFB $3F                ;
  DEFB $3F                ;
  DEFB $7F                ;

; Sprite, 8 by 16 (the template for type 54)
SPRITE5C64:
  DEFB $44                ; Image, the top row first
  DEFB $80                ;
  DEFB $BE                ;
  DEFB $F6                ;
  DEFB $76                ;
  DEFB $7C                ;
  DEFB $35                ;
  DEFB $1E                ;
  DEFB $0C                ;
  DEFB $0E                ;
  DEFB $06                ;
  DEFB $06                ;
  DEFB $07                ;
  DEFB $03                ;
  DEFB $03                ;
  DEFB $01                ;
  DEFB $BB                ; Mask: a bit set where the background shows through
  DEFB $13                ;
  DEFB $01                ;
  DEFB $01                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $C2                ;
  DEFB $E1                ;
  DEFB $F1                ;
  DEFB $F1                ;
  DEFB $F9                ;
  DEFB $F9                ;
  DEFB $F8                ;
  DEFB $FC                ;
  DEFB $FC                ;
  DEFB $FE                ;

; Sprite, 24 by 24 (the template for type 48)
SPRITE5C84:
  DEFB $00,$01,$00        ; Image, the top row first
  DEFB $00,$E2,$80        ;
  DEFB $01,$14,$4C        ;
  DEFB $02,$08,$52        ;
  DEFB $01,$4A,$62        ;
  DEFB $00,$9F,$42        ;
  DEFB $00,$63,$C6        ;
  DEFB $03,$DD,$EF        ;
  DEFB $04,$7E,$F7        ;
  DEFB $08,$5F,$F3        ;
  DEFB $08,$61,$E0        ;
  DEFB $04,$B3,$E1        ;
  DEFB $03,$7F,$E7        ;
  DEFB $00,$9F,$9B        ;
  DEFB $00,$84,$13        ;
  DEFB $00,$8A,$26        ;
  DEFB $00,$52,$26        ;
  DEFB $00,$31,$54        ;
  DEFB $00,$00,$8C        ;
  DEFB $00,$00,$28        ;
  DEFB $00,$00,$58        ;
  DEFB $00,$00,$B0        ;
  DEFB $00,$01,$60        ;
  DEFB $00,$03,$C0        ;
  DEFB $FF,$FE,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$1C,$7F        ;
  DEFB $FE,$08,$33        ;
  DEFB $FC,$00,$21        ;
  DEFB $FE,$00,$01        ;
  DEFB $FF,$00,$01        ;
  DEFB $FF,$80,$01        ;
  DEFB $FC,$00,$00        ;
  DEFB $F8,$00,$00        ;
  DEFB $F0,$00,$00        ;
  DEFB $F0,$00,$00        ;
  DEFB $F8,$00,$00        ;
  DEFB $FC,$00,$00        ;
  DEFB $FF,$00,$00        ;
  DEFB $FF,$00,$00        ;
  DEFB $FF,$04,$01        ;
  DEFB $FF,$8C,$01        ;
  DEFB $FF,$CE,$23        ;
  DEFB $FF,$FF,$63        ;
  DEFB $FF,$FF,$C7        ;
  DEFB $FF,$FF,$87        ;
  DEFB $FF,$FF,$0F        ;
  DEFB $FF,$FE,$1F        ;
  DEFB $FF,$FC,$3F        ;

; Frames 1 and 2 of object type 48, striking
;
; Two more 24 by 24 sprites, image then mask like every sprite, in the style of
; SPRITE5C84 (type 48's own sprite), which they follow directly: the same
; winged creature in two other poses.
;
; They are its strike. When the knight comes within reach in front of one of
; these creatures, the object dispatcher (CHE3D, at the author's I4) takes 3
; from LIFE and steps the creature's frames from SPRITE5C84 on, 144 bytes each
; (the animation step, the author's ANIM, inside KNIGHT_CONTROLS). Bits 3-5 of
; a type 48 object's +$11 give its last frame, and every one has $10 there
; (measured on those in room 45): frames 0 to 2, SPRITE5C84 and these two. The
; strike never happened in the build's sessions (that code never ran), nor in
; half a minute of play in room 45 tried for this description, so no object
; showed these frames and no generated entry lays them out. CHE3D describes the
; strike.
TYPE48_FRAMES:
  DEFB $00,$00,$00        ; Frame 1: the image, 24 rows of three bytes
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$10,$00        ;
  DEFB $0E,$28,$00        ;
  DEFB $11,$44,$00        ;
  DEFB $20,$87,$38        ;
  DEFB $12,$A7,$FC        ;
  DEFB $09,$F4,$6C        ;
  DEFB $07,$FC,$7E        ;
  DEFB $1E,$3E,$FE        ;
  DEFB $25,$9F,$76        ;
  DEFB $37,$FF,$76        ;
  DEFB $24,$FE,$3E        ;
  DEFB $2A,$1C,$6E        ;
  DEFB $17,$7E,$5C        ;
  DEFB $05,$F9,$BC        ;
  DEFB $04,$C1,$38        ;
  DEFB $02,$62,$50        ;
  DEFB $01,$9C,$B0        ;
  DEFB $00,$00,$A0        ;
  DEFB $00,$01,$60        ;
  DEFB $00,$01,$40        ;
  DEFB $00,$02,$C0        ;
  DEFB $FF,$FF,$FF        ; Frame 1: the mask
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $93,$EF,$FF        ;
  DEFB $F1,$C7,$FF        ;
  DEFB $E0,$83,$FF        ;
  DEFB $C0,$00,$C7        ;
  DEFB $E0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F8,$00,$01        ;
  DEFB $E0,$00,$01        ;
  DEFB $C0,$00,$01        ;
  DEFB $C0,$00,$01        ;
  DEFB $C0,$00,$01        ;
  DEFB $C0,$00,$01        ;
  DEFB $E8,$00,$03        ;
  DEFB $F8,$00,$43        ;
  DEFB $F8,$00,$C7        ;
  DEFB $FC,$01,$8F        ;
  DEFB $FE,$63,$0F        ;
  DEFB $FF,$FF,$1F        ;
  DEFB $FF,$FE,$1F        ;
  DEFB $FF,$FE,$3F        ;
  DEFB $FF,$FC,$3F        ;
  DEFB $00,$00,$00        ; Frame 2: the image
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $70,$80,$00        ;
  DEFB $89,$40,$00        ;
  DEFB $86,$20,$00        ;
  DEFB $A4,$20,$00        ;
  DEFB $4D,$23,$80        ;
  DEFB $7E,$6F,$C0        ;
  DEFB $67,$FF,$E0        ;
  DEFB $43,$FE,$F0        ;
  DEFB $93,$F8,$70        ;
  DEFB $EB,$A0,$38        ;
  DEFB $47,$A0,$38        ;
  DEFB $23,$20,$38        ;
  DEFB $43,$C0,$78        ;
  DEFB $EF,$40,$70        ;
  DEFB $16,$40,$90        ;
  DEFB $85,$81,$60        ;
  DEFB $78,$02,$C0        ;
  DEFB $FF,$FF,$FF        ; Frame 2: the mask
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $8F,$7F,$FF        ;
  DEFB $06,$3F,$FF        ;
  DEFB $00,$1F,$FF        ;
  DEFB $00,$1F,$FF        ;
  DEFB $80,$1C,$7F        ;
  DEFB $80,$10,$3F        ;
  DEFB $80,$00,$1F        ;
  DEFB $80,$01,$0F        ;
  DEFB $00,$07,$8F        ;
  DEFB $00,$1F,$C7        ;
  DEFB $80,$1F,$C7        ;
  DEFB $C0,$1F,$C7        ;
  DEFB $80,$3F,$87        ;
  DEFB $00,$3F,$8F        ;
  DEFB $80,$3F,$0F        ;
  DEFB $02,$7E,$1F        ;
  DEFB $87,$FC,$3F        ;

; Sprite, 24 by 14 (the template for type 50)
SPRITE5E34:
  DEFB $00,$0E,$00        ; Image, the top row first
  DEFB $00,$3F,$80        ;
  DEFB $00,$FA,$E0        ;
  DEFB $03,$E1,$B8        ;
  DEFB $0F,$94,$6C        ;
  DEFB $1E,$02,$18        ;
  DEFB $3A,$14,$68        ;
  DEFB $2D,$81,$8C        ;
  DEFB $2B,$66,$18        ;
  DEFB $35,$D8,$60        ;
  DEFB $19,$61,$80        ;
  DEFB $06,$46,$00        ;
  DEFB $01,$D8,$00        ;
  DEFB $00,$60,$00        ;
  DEFB $FF,$E1,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$80,$7F        ;
  DEFB $FE,$00,$1F        ;
  DEFB $F8,$00,$07        ;
  DEFB $E0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F8,$01,$FF        ;
  DEFB $FE,$07,$FF        ;
  DEFB $FF,$9F,$FF        ;

; Sprite, 16 by 32 (the template for type 45)
SPRITE5E88:
  DEFB $03,$00            ; Image, the top row first
  DEFB $04,$E0            ;
  DEFB $08,$10            ;
  DEFB $08,$08            ;
  DEFB $08,$E8            ;
  DEFB $11,$F4            ;
  DEFB $13,$D4            ;
  DEFB $12,$64            ;
  DEFB $11,$E8            ;
  DEFB $09,$E8            ;
  DEFB $08,$D0            ;
  DEFB $04,$C8            ;
  DEFB $0A,$44            ;
  DEFB $10,$44            ;
  DEFB $20,$54            ;
  DEFB $20,$14            ;
  DEFB $24,$E4            ;
  DEFB $25,$24            ;
  DEFB $22,$28            ;
  DEFB $10,$30            ;
  DEFB $10,$48            ;
  DEFB $19,$A8            ;
  DEFB $16,$A8            ;
  DEFB $10,$A8            ;
  DEFB $10,$88            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $08,$08            ;
  DEFB $08,$10            ;
  DEFB $04,$20            ;
  DEFB $03,$80            ;
  DEFB $FC,$FF            ; Mask: a bit set where the background shows through
  DEFB $F8,$1F            ;
  DEFB $F0,$0F            ;
  DEFB $F0,$07            ;
  DEFB $F0,$07            ;
  DEFB $E0,$03            ;
  DEFB $E0,$03            ;
  DEFB $E0,$03            ;
  DEFB $E0,$07            ;
  DEFB $F0,$07            ;
  DEFB $F0,$0F            ;
  DEFB $F8,$07            ;
  DEFB $F0,$03            ;
  DEFB $E0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $F0,$07            ;
  DEFB $F0,$0F            ;
  DEFB $F8,$1F            ;
  DEFB $FC,$7F            ;

; Sprite, 16 by 32
;
; Seen on an object in the build's sessions.
SPRITE5F08:
  DEFB $00,$C0            ; Image, the top row first
  DEFB $03,$20            ;
  DEFB $04,$10            ;
  DEFB $08,$10            ;
  DEFB $08,$10            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $20,$08            ;
  DEFB $20,$08            ;
  DEFB $12,$10            ;
  DEFB $0C,$10            ;
  DEFB $10,$20            ;
  DEFB $20,$50            ;
  DEFB $20,$08            ;
  DEFB $20,$04            ;
  DEFB $20,$04            ;
  DEFB $20,$04            ;
  DEFB $20,$44            ;
  DEFB $10,$24            ;
  DEFB $0C,$38            ;
  DEFB $13,$30            ;
  DEFB $10,$C8            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$08            ;
  DEFB $10,$10            ;
  DEFB $08,$10            ;
  DEFB $04,$20            ;
  DEFB $01,$C0            ;
  DEFB $FF,$3F            ; Mask: a bit set where the background shows through
  DEFB $FC,$1F            ;
  DEFB $F8,$0F            ;
  DEFB $F0,$0F            ;
  DEFB $F0,$0F            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $F0,$0F            ;
  DEFB $E0,$0F            ;
  DEFB $C0,$0F            ;
  DEFB $C0,$07            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$03            ;
  DEFB $F0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $F0,$0F            ;
  DEFB $F8,$1F            ;
  DEFB $FE,$3F            ;

; Sprite, 48 by 21 (the template for type 55)
SPRITE5F88:
  DEFB $00,$00,$16,$B8,$00,$00 ; Image, the top row first
  DEFB $00,$02,$C0,$06,$80,$00 ;
  DEFB $00,$50,$00,$00,$28,$00 ;
  DEFB $01,$00,$00,$00,$03,$00 ;
  DEFB $04,$00,$00,$00,$00,$C0 ;
  DEFB $00,$00,$00,$00,$00,$30 ;
  DEFB $10,$00,$00,$00,$00,$0C ;
  DEFB $20,$00,$00,$00,$00,$02 ;
  DEFB $40,$00,$00,$00,$00,$01 ;
  DEFB $40,$00,$00,$00,$00,$01 ;
  DEFB $40,$00,$00,$00,$00,$01 ;
  DEFB $60,$00,$00,$00,$00,$01 ;
  DEFB $60,$00,$00,$00,$00,$01 ;
  DEFB $20,$00,$00,$00,$00,$02 ;
  DEFB $20,$00,$00,$00,$00,$04 ;
  DEFB $10,$00,$00,$00,$00,$08 ;
  DEFB $0C,$00,$00,$00,$00,$30 ;
  DEFB $03,$00,$00,$00,$00,$C0 ;
  DEFB $00,$E0,$00,$00,$07,$00 ;
  DEFB $00,$1F,$00,$00,$F8,$00 ;
  DEFB $00,$00,$FF,$FF,$00,$00 ;
  DEFB $FF,$FF,$E0,$07,$FF,$FF ; Mask: a bit set where the background shows
  DEFB $FF,$FC,$00,$00,$7F,$FF ; through
  DEFB $FF,$80,$00,$00,$07,$FF ;
  DEFB $FE,$00,$00,$00,$00,$FF ;
  DEFB $F8,$00,$00,$00,$00,$3F ;
  DEFB $F0,$00,$00,$00,$00,$0F ;
  DEFB $E0,$00,$00,$00,$00,$03 ;
  DEFB $C0,$00,$00,$00,$00,$01 ;
  DEFB $80,$00,$00,$00,$00,$00 ;
  DEFB $80,$00,$00,$00,$00,$00 ;
  DEFB $80,$00,$00,$00,$00,$00 ;
  DEFB $80,$00,$00,$00,$00,$00 ;
  DEFB $80,$00,$00,$00,$00,$00 ;
  DEFB $C0,$00,$00,$00,$00,$01 ;
  DEFB $C0,$00,$00,$00,$00,$03 ;
  DEFB $E0,$00,$00,$00,$00,$07 ;
  DEFB $F0,$00,$00,$00,$00,$0F ;
  DEFB $FC,$00,$00,$00,$00,$3F ;
  DEFB $FF,$00,$00,$00,$00,$FF ;
  DEFB $FF,$E0,$00,$00,$07,$FF ;
  DEFB $FF,$FF,$00,$00,$FF,$FF ;

; Sprite, 16 by 32 (the template for type 56)
SPRITE6084:
  DEFB $03,$00            ; Image, the top row first
  DEFB $07,$80            ;
  DEFB $0E,$40            ;
  DEFB $09,$E0            ;
  DEFB $16,$20            ;
  DEFB $18,$60            ;
  DEFB $1A,$20            ;
  DEFB $18,$E0            ;
  DEFB $0D,$70            ;
  DEFB $0F,$D0            ;
  DEFB $0F,$F0            ;
  DEFB $11,$C8            ;
  DEFB $10,$18            ;
  DEFB $22,$14            ;
  DEFB $24,$04            ;
  DEFB $44,$0C            ;
  DEFB $44,$0C            ;
  DEFB $42,$10            ;
  DEFB $22,$A8            ;
  DEFB $15,$48            ;
  DEFB $08,$48            ;
  DEFB $10,$04            ;
  DEFB $10,$44            ;
  DEFB $10,$04            ;
  DEFB $10,$44            ;
  DEFB $10,$44            ;
  DEFB $10,$04            ;
  DEFB $10,$08            ;
  DEFB $08,$38            ;
  DEFB $07,$B8            ;
  DEFB $07,$9C            ;
  DEFB $01,$C0            ;
  DEFB $FC,$FF            ; Mask: a bit set where the background shows through
  DEFB $F0,$3F            ;
  DEFB $F0,$1F            ;
  DEFB $E0,$0F            ;
  DEFB $C0,$0F            ;
  DEFB $C0,$0F            ;
  DEFB $C0,$0F            ;
  DEFB $E0,$0F            ;
  DEFB $E0,$0F            ;
  DEFB $E0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $80,$03            ;
  DEFB $80,$03            ;
  DEFB $80,$03            ;
  DEFB $80,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$03            ;
  DEFB $F0,$03            ;
  DEFB $F0,$23            ;
  DEFB $FE,$3F            ;

; Sprite, 16 by 10 (the template for type 40)
SPRITE6104:
  DEFB $00,$80            ; Image, the top row first
  DEFB $08,$D0            ;
  DEFB $15,$4A            ;
  DEFB $44,$52            ;
  DEFB $23,$2A            ;
  DEFB $3A,$A5            ;
  DEFB $84,$A2            ;
  DEFB $24,$46            ;
  DEFB $15,$68            ;
  DEFB $1A,$00            ;
  DEFB $FF,$7F            ; Mask: a bit set where the background shows through
  DEFB $F7,$2F            ;
  DEFB $E2,$01            ;
  DEFB $80,$01            ;
  DEFB $80,$00            ;
  DEFB $80,$00            ;
  DEFB $00,$00            ;
  DEFB $C0,$01            ;
  DEFB $E0,$07            ;
  DEFB $E1,$FF            ;

; Sprite, 16 by 10
;
; Seen on an object in the build's sessions.
SPRITE612C:
  DEFB $03,$A0            ; Image, the top row first
  DEFB $09,$18            ;
  DEFB $36,$96            ;
  DEFB $44,$52            ;
  DEFB $AA,$6A            ;
  DEFB $36,$A5            ;
  DEFB $86,$92            ;
  DEFB $29,$06            ;
  DEFB $19,$68            ;
  DEFB $0A,$80            ;
  DEFB $FC,$1F            ; Mask: a bit set where the background shows through
  DEFB $F0,$07            ;
  DEFB $C0,$01            ;
  DEFB $80,$01            ;
  DEFB $40,$01            ;
  DEFB $C0,$00            ;
  DEFB $40,$01            ;
  DEFB $C0,$01            ;
  DEFB $E0,$03            ;
  DEFB $F0,$0F            ;

; Sprite, 16 by 10
;
; Seen on an object in the build's sessions.
SPRITE6154:
  DEFB $08,$A0            ; Image, the top row first
  DEFB $12,$D0            ;
  DEFB $15,$2C            ;
  DEFB $45,$CA            ;
  DEFB $22,$6A            ;
  DEFB $2E,$B5            ;
  DEFB $8C,$AE            ;
  DEFB $23,$46            ;
  DEFB $25,$64            ;
  DEFB $1A,$90            ;
  DEFB $F0,$1F            ; Mask: a bit set where the background shows through
  DEFB $E0,$0F            ;
  DEFB $E0,$03            ;
  DEFB $80,$01            ;
  DEFB $C0,$01            ;
  DEFB $C0,$00            ;
  DEFB $00,$01            ;
  DEFB $80,$01            ;
  DEFB $C0,$0B            ;
  DEFB $E0,$2F            ;

; Leftover source text, and the game's stack
;
; Part of the game's own source code, as text, left in memory when the tape was
; made: numbered lines (a two-byte line number, the text with tabs between the
; fields, a carriage return), here lines 6240-6670. They are the source of the
; end of the pick-up code in PICK_UP_LOOK_ON (the author's WEI3, and calls of
; routines he called ROMM, DOE, SRP and INFOR: SET_THING_ROOM, the instruction
; three bytes before it, REDRAW_OBJECT and SHOW_THING_IN_USE) and the start of
; the joystick and keyboard reading (KNIGHT_CONTROLS, his I88 onwards); the
; text goes on at MASTER_OBJECTS. The game never reads it.
;
; The top of it is the game's stack: START sets SP two bytes below the block's
; end, and in the build's sessions the stack reached down 150 bytes below that.
SOURCE_AND_STACK:
  DEFM $60,$18,$09,"LD",$09,"(IY+7),3",$0D,"j"
  DEFM $18,$09,"JR",$09,"DOE",$0D,"t",$18,"WEI3",$09
  DEFM "LD",$09,"(V+18),A",$0D,"~",$18,$09,"P"
  DEFM "USH",$09,"IX",$0D,$88,$18,$09,"POP",$09,"DE"
  DEFM $0D,$92,$18,$09,"LD",$09,"H,255",$0D,$9C,$18,$09
  DEFM "LD",$09,"L,(IY+30)",$0D,$A6,$18,$09
  DEFM "LD",$09,"(HL),E",$0D,$B0,$18,$09,"INC"
  DEFM $09,"HL",$0D,$BA,$18,$09,"LD",$09,"(HL),D"
  DEFM $0D,$C4,$18,$09,"SET",$09,"5,(IX+16"
  DEFM ")",$0D,$CE,$18,$09,"RES",$09,"7,(IX+1"
  DEFM "4)",$0D,$D8,$18,$09,"RES",$09,"1,(IY+"
  DEFM "17)",$0D,$E2,$18,$09,"LD",$09,"C,254",$0D
  DEFM $EC,$18,$09,"CALL",$09,"ROMM",$0D,$F6,$18,$09
  DEFM "PUSH",$09,"IX",$0D,$00,$19,$09,"CALL",$09
  DEFM "DOE",$0D,$0A,$19,$09,"POP",$09,"HL",$0D,$14,$19
  DEFM $09,"LD",$09,"A,(V+3)",$0D,$1E,$19,$09,"P"
  DEFM "USH",$09,"AF",$0D,"(",$19,$09,"LD",$09,"A,("
  DEFM "T+20)",$0D,"2",$19,$09,"LD",$09,"(V+3"
  DEFM "),A",$0D,"<",$19,$09,"PUSH",$09,"HL",$0D,"F"
  DEFM $19,$09,"CALL",$09,"SRP",$0D,"P",$19,$09,"PO"
  DEFM "P",$09,"HL",$0D,"Z",$19,$09,"CALL",$09,"INF"
  DEFM "OR",$0D,"d",$19,$09,"POP",$09,"AF",$0D,"n",$19,$09
  DEFM "LD",$09,"(V+3),A",$0D,"x",$19,$09,"LD"
  DEFM $09,"(IY+17),0",$0D,$82,$19,$09,"RE"
  DEFM "T",$0D,$8C,$19,"I88",$09,"CALL",$09,"IN3"
  DEFM "1",$0D,$96,$19,$09,"JR",$09,"Z,I80",$0D,$A0,$19
  DEFM "I89",$09,"RRA",$0D,$AA,$19,$09,"JR",$09,"NC"
  DEFM ",I82",$0D,$B4,$19,$09,"LD",$09,"C,8",$0D,$BE
  DEFM $19,"I82",$09,"RRA",$0D,$C8,$19,$09,"JR",$09,"N"
  DEFM "C,I83",$0D,$D2,$19,$09,"LD",$09,"C,4",$0D
  DEFM $DC,$19,"I83",$09,"RRA",$0D,$E6,$19,$09,"JR",$09
  DEFM "NC,I84",$0D,$F0,$19,$09,"LD",$09,"C,1"
  DEFM "28",$0D,$FA,$19,"I84",$09,"RRA",$0D,$04,$1A,$09
  DEFM "JR",$09,"NC,I85",$0D,$0E,$1A,$09,"L"
STACK_TOP:
  DEFB $44,$09            ; SP starts here, so the first word pushed goes just
                          ; below

; The master copy of the object table, the variables and the knight's record
;
; At start-up (START) the first 1200 bytes of the object table are copied here
; from OBJECTS, the variables from OBJECT_COUNT (61 bytes) and the knight's
; record from KNIGHT (20 bytes); a new game (TITLE_SCREEN) copies them back.
; The 1200 bytes hold the first 183 records and a piece of the 184th, which
; takes in all 163 six-byte records at the start of the table: the things whose
; room the game changes (SET_THING_ROOM finds a thing's record by its number,
; six bytes a number, which only works among those). The later records are not
; restored; whether the game ever changes one of them is not settled.
;
; On the tape these bytes are other things. The first 293 are more of the
; source text of SOURCE_AND_STACK (lines 6680-6890, more of the keyboard
; reading in KNIGHT_CONTROLS, to the author's INP5 and a little after). After
; them come bytes that are not text: machine code, by the look of it, whose
; calls and jumps go to addresses in this same block and which reads one of the
; ROM's system variables, so it ran at this address on the development machine;
; perhaps part of the development tools. Not identified.
MASTER_OBJECTS:
  DEFM "C,64",$0D,$18,$1A,"I85",$09,"RRA",$0D,"\""
  DEFM $1A,$09,"JR",$09,"C,INP59",$0D,",",$1A,$09
  DEFM "JR",$09,"INP5",$0D,"6",$1A,"I80",$09,"LD"
  DEFM $09,"A,223",$0D,"@",$1A,$09,"CALL",$09,"I"
  DEFM "NPUT",$0D,"J",$1A,$09,"JR",$09,"Z,INP"
  DEFM "2",$0D,"T",$1A,$09,"LD",$09,"C,8",$0D,$5E,$1A,"IN"
  DEFM "P2",$09,"LD",$09,"A,191",$0D,"h",$1A,$09,"C"
  DEFM "ALL",$09,"INPUT",$0D,"r",$1A,$09,"JR",$09
  DEFM "Z,INP3",$0D,"|",$1A,$09,"LD",$09,"C,4"
  DEFM $0D,$86,$1A,"INP3",$09,"LD",$09,"A,253"
  DEFM $0D,$90,$1A,$09,"CALL",$09,"INPUT",$0D,$9A
  DEFM $1A,$09,"JR",$09,"Z,INP4",$0D,$A4,$1A,$09,"L"
  DEFM "D",$09,"C,128",$0D,$AE,$1A,"INP4",$09,"L"
  DEFM "D",$09,"A,251",$0D,$B8,$1A,$09,"CALL",$09
  DEFM "INPUT",$0D,$C2,$1A,$09,"JR",$09,"Z,IN"
  DEFM "P5",$0D,$CC,$1A,$09,"LD",$09,"C,64",$0D,$D6,$1A
  DEFM "INP5",$09,"CALL",$09,"MIMAN",$0D
  DEFM $E0,$1A,$09,"LD",$09,"A,E",$0D,$EA,$1A,$09,"BIT"
  DEFM $09,"6,E",$0D,$F4,$1A,$09,"(",$13,$06,$0B,"!",$E6,"d",$BE
  DEFM "#(",$14,"#",$10,$F9,$E1,$E1,$D1,$C1,$FD,$E1,$C9,"!j\\"
  DEFM ">",$08,$AE,"w",$F1,$18,$98,"~",$18,$EC,$08,$18,$0C,$08,$0B,$0C
  DEFM $07,$03,$C6,"[",$C5,"]",$E2,"~",$C3,"|",$CD,"\\",$CC,"{",$CB,"}"
  DEFM ">",$7F,$DB,$FE,$1F,"?",$D0,">",$FE,$DB,$FE,$1F,"?",$C9,">_"
  DEFM $C3,$BD,"c*.e",$D9,$ED,"{,e",$FD,"!:\\",$FD
  DEFM "6",$00,$FF,$C1,$FB,$C9,$F3,$ED,"s,e",$D9,"\".e",$C9
  DEFM $82,"cX'",$FD,$E5,$E5,$06,$05,$FD,"!~e",$FD,$5E,$00
  DEFM $FD,"V",$01,$B7,$ED,"R0",$08,$19,$FD,"#",$FD,"#",$10,$EE,$04
  DEFM "ox",$CD,$88,"e",$E1,$FD,"!~e",$01,"0",$05,">0",$FD
  DEFM $5E,$00,$FD,"V",$01,$B7,$ED,"R8",$03,"<",$18,$F8,$19,$B9,"("
  DEFM $04,$CD,$BA,"c",$0D,$FD,"#",$FD,"#",$10,$E2,$FD,$E1,$B9,$C0,$C3
  DEFM $BA,"c",$10,"'",$E8,$03,"d",$00,$0A,$00,$01,$00,$95,$D0,$ED,"D"
  DEFM "G",$CD,$AD,"e",$10,$FB,$C9,$06,$03,$CD,$A9,"e",$10,$FB,"*",$C1
  DEFM "}}",$B4,$C8,"~#",$CD,$BA,"c",$FE,$0D," ",$F7,">",$0D,$18
  DEFM $02,"> ",$C3,$BA,"c>",$08,$C3,$BA,"c1",$9F,$7F,$CD,$FC
  DEFM "m",$FD,$CB,"0",$DE,"!x}",$06,"(6",$0D,"#",$10,$FB,">"
  DEFM $C9,"2",$BB,"}>,2",$AE,"}>",$0F,"2",$B8,"}!",$0A
  DEFM $00,"\"",$A2,"}\"",$A4,"}*",$B4,"}\"",$D3,"c!",$D8,"~"
  DEFM $CD,"5f1",$9F,$7F,$CD,$C3,"c",$CD,$A9,"e1",$9F,$7F,$CD
  DEFM $FC,"mgo\"",$A6,"}\"",$A8,"}",$CD,$03,"g \"!"
  DEFM $F8,"e",$E5,":",$A1,"}!",$00,"}",$06,$13,$BE,"(",$0D,$D6," "
  DEFM $BE,"(",$08,$C6," ###",$10,$F1,$C9,"#",$5E,"#V",$EB
  DEFM $E9,"!c}",$CD,"5f",$18,$C3,"~",$B7,$C8,$CD,$BA,"c#"
  DEFM $18,$F7,":",$AF,"}G>",$13,$B8,"8",$12,">",$0E,$B8,"8",$0D
  DEFM ">",$05,$B8,"8",$08,"x=> (",$02,">",$01,"2",$D1,"}"
  DEFM "7",$C9,$16,$06,"!",$0A,$7F,$0E,"A",$1E,$00,"> ",$92,"G",$DD
  DEFM $CB,$00,"N",$C0,$DD,$CB,$00,"f(",$0C,":",$D1,"}",$B8,"> "
  DEFM "8",$0F,$DD,$CB,$00,$A6,$DD,$CB,$00,"F(",$02,"~#",$CC,$0A
  DEFM "e",$FE,$09," ",$09,$DD,$CB,$00,$E6,$CD,"Bf",$18,$D6,$FE,$18
  DEFM " ",$0B,$1C,$1D,"(",$C9,$CD,$E7,"f ",$FB,$18,$BE,$FE,$03,$CA
  DEFM $A9,"e",$FE,$08," ",$07,$1C,$1D,$C4,$E7,"f",$18,$B2,$FE,$0D,"("
  DEFM $05,$FE," 8",$AA,"?",$DD,$CB,$00,"F ",$02,"w#",$F5,$CD
  DEFM $BA,"c",$F1,"?",$D8,$1C,$05,$0D,"(",$DC,$04,$05," ",$91,$DD,"5"
  DEFM $01,"B",$04,$05,"(",$85,$CD,$8D,"e",$18,$C0,"> ",$92,$B8," "
  DEFM $0A,"B",$04,$05,"(",$05,$CD,$B2,"e",$10,$FB,$04,$CD,$B2,"e",$DD
  DEFM $CB,$00,$A6,"+",$0C,$1D,$C9,">>",$CD,$BA,"c",$16,$01,$CD,$60
  DEFM "f!",$0A,$7F,$CD,$A3,"g2",$A1,"}",$C8,$CD,$D6,"g0",$1E
  DEFM $CD,$B1,"g",$C0,"\"",$AA,"}",$13,$1A,$FE,$0D," ",$0B,"\"",$A6,"}"
  DEFM "\"",$A8,"}",$CD,$07,"h",$AF,$C9,$13,$CD,$DC,"l",$AF,$C9,$CD,$A2
  DEFM "g",$C8,$B8,"(",$0F,$CD,$B1,"g",$C0,"\"",$A2,"}\"",$A6,"}",$EB
  DEFM $CD,$A2,"g",$C8,$B8," ",$F9,$CD,$A2,"g",$C8,$B8,"(",$0F,$CD,$B1
  DEFM "g",$C0,"\"",$A4,"}\"",$A8,"}",$EB,$CD,$A2,"g",$C8,$B8," ",$F9
  DEFM "H#~",$B9,"(",$11,$11,"x}",$CD,$87,"g8",$0A,$C8,"+"
  DEFM $CD,$A2,"g",$C8,$B8," ",$F9,"#",$11,$8C,"}",$06,$14,">",$0D,$D5
  DEFM $C5,$12,$13,$10,$FC,$C1,$D1,"~#",$B9," ",$02,"7",$C9,$FE,$0D
  DEFM $C8,$12,$13,$10,$F2,$C9,"#:",$AE,"}G~#",$FE," ("
  DEFM $FA,"+",$FE,$0D,$C9,$C5,$EB,"!",$00,$00,$1A,$CD,$D6,"g0",$0F
  DEFM $13,"DM))",$09,")",$06,$00,$E6,$0F,"O",$09,$18,$EB,$C1
  DEFM $1B,"|",$B5," ",$02,"<",$C9,$CB,"|",$C9,$FE,"0?",$D0,$FE,":"
  DEFM $C9,"*",$A2,"}\"",$AA,"}",$E5,$CD,$E2,"m",$CD,$5E,"f",$E1,$D0
  DEFM $E5,$CD,$D9,"l",$D1,"*",$A4,"}",$19,"|",$07,$D8,$18,$E6,$ED,"K"
  DEFM $A6,"}y",$B0,$C8,"*",$A8,"}}",$B4,$C9,$CD,$FA,"g",$C8,$E5
  DEFM $CD,$92,"m",$C1,$01,$00,$00,$B7,$02,$00,$02,$00,$E0,"P",$08,$9F
  DEFM "x",$A4,"x",$A2,"x",$01,$00,$05,$80,$DC,"z",$00,$07,$01,$08,$08
  DEFM "C",$00,$0F,"Q",$00,$00,$00,"<",$00,$00,$00,$00,"8",$00,$1B,$82
  DEFM $00,"@m",$00,$00,$00,$E4,$05,$FB,$14,".",$00,$00,$00,$01,$00
MASTER_VARIABLES:
  DEFM $01,$08,$1F,$00,$00,$00,$00,$00,"EX      "
  DEFM "                "
  DEFM "        ",$00,$00,$00,$00,$00,$00,$00,$00
  DEFM $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
MASTER_KNIGHT:
  DEFM $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFM $00,$00,$00,$00

; Unused
;
; Nineteen zeros between the master copy and the rooms (ROOM1). Nothing reads
; or writes them.
ZEROS_BEFORE_ROOMS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

; Room 1
ROOM1:
  DEFB $04,$00            ; Length: 4 bytes
  DEFB $06                ; Colour: yellow on black
  DEFB $E5                ; End

; Room 2
ROOM2:
  DEFB $42,$00            ; Length: 66 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $C9                ; Mode bit 6 on
  DEFB $8F,$B2            ; Point: row 143, column 178
  DEFB $E1,$03            ; Part 3 (PART3), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $5C,$37            ; Point: row 92, column 55
  DEFB $E1,$05            ; Part 5 (PART5), keeping the points
  DEFB $E1,$01            ; Part 1 (PART1), keeping the points
  DEFB $E1,$08            ; Part 8 (PART8), keeping the points
  DEFB $5A,$C8            ; Point: row 90, column 200
  DEFB $BF,$7F            ; Point: row 191, column 127
  DEFB $CF                ; Second point to the first
  DEFB $D2                ; Line between the points
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$00            ; $E4 $00: clean copy cleared; lines go into it
  DEFB $C7                ; Mode bit 5 on
  DEFB $C0,$BF,$7F        ; Second point: row 191, column 127
  DEFB $C3                ; Mode bit 2 on
  DEFB $8A,$7F            ; Point: row 138, column 127
  DEFB $80,$98            ; Point: row 128, column 152
  DEFB $B2,$98            ; Point: row 178, column 152
  DEFB $BF,$83            ; Point: row 191, column 131
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$82            ; Point: row 191, column 130
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $E4,$01            ; $E4 $01: lines onto the screen again
  DEFB $C7                ; Mode bit 5 on
  DEFB $C0,$B2,$98        ; Second point: row 178, column 152
  DEFB $80,$98            ; Point: row 128, column 152
  DEFB $E4,$04            ; Objects follow
  DEFB $E5                ; End

; Room 3
ROOM3:
  DEFB $53,$00            ; Length: 83 bytes
  DEFB $10                ; Colour: black on red
  DEFB $56,$04            ; Point: row 86, column 4
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $E1,$1F            ; Part 31 (PART31), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$5C            ; Point: row 64, column 92
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $4A,$18            ; Point: row 74, column 24
  DEFB $4F,$16            ; Point: row 79, column 22
  DEFB $56,$04            ; Point: row 86, column 4
  DEFB $61,$00            ; Point: row 97, column 0
  DEFB $C0,$BF,$9D        ; Second point: row 191, column 157
  DEFB $9F,$AF            ; Point: row 159, column 175
  DEFB $8B,$B5            ; Point: row 139, column 181
  DEFB $76,$AF            ; Point: row 118, column 175
  DEFB $6F,$C1            ; Point: row 111, column 193
  DEFB $66,$EC            ; Point: row 102, column 236
  DEFB $56,$FF            ; Point: row 86, column 255
  DEFB $C0,$2E,$FF        ; Second point: row 46, column 255
  DEFB $38,$E6            ; Point: row 56, column 230
  DEFB $3E,$CE            ; Point: row 62, column 206
  DEFB $31,$AF            ; Point: row 49, column 175
  DEFB $42,$8F            ; Point: row 66, column 143
  DEFB $48,$71            ; Point: row 72, column 113
  DEFB $3D,$51            ; Point: row 61, column 81
  DEFB $2B,$30            ; Point: row 43, column 48
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $41,$00            ; Point: row 65, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $78,$64            ; Point: row 120, column 100
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $E4,$04            ; Objects follow
  DEFB $F4                ; Patch 15
  DEFB $0C,$00,$1A,$82,$AE ; Object: type 12; +12 value 0, along 26, top 130,
                           ; across 174
  DEFB $2A,$00,$2A,$82,$3C ; Object: type 42; +12 value 0, along 42, top 130,
                           ; across 60
  DEFB $E5                ; End

; Room 4
ROOM4:
  DEFB $35,$00            ; Length: 53 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $20,$60            ; Point: row 32, column 96
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$A6            ; Point: row 0, column 166
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $70,$35            ; Point: row 112, column 53
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $1F,$2D            ; Point: row 31, column 45
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $81,$FF            ; Point: row 129, column 255
  DEFB $CA                ; Mode bit 6 off
  DEFB $C0,$24,$FF        ; Second point: row 36, column 255
  DEFB $19,$EF            ; Point: row 25, column 239
  DEFB $1F,$D3            ; Point: row 31, column 211
  DEFB $C0,$69,$FF        ; Second point: row 105, column 255
  DEFB $62,$F1            ; Point: row 98, column 241
  DEFB $6F,$CB            ; Point: row 111, column 203
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $00,$82            ; Point: row 0, column 130
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $F6                ; Patch 17
  DEFB $E5                ; End

; Room 5
ROOM5:
  DEFB $56,$00            ; Length: 86 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E1,$11            ; Part 17 (PART17), keeping the points
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $0D,$67            ; Point: row 13, column 103
  DEFB $0F,$7A            ; Point: row 15, column 122
  DEFB $16,$88            ; Point: row 22, column 136
  DEFB $10,$9B            ; Point: row 16, column 155
  DEFB $17,$A7            ; Point: row 23, column 167
  DEFB $C0,$8E,$58        ; Second point: row 142, column 88
  DEFB $92,$50            ; Point: row 146, column 80
  DEFB $85,$31            ; Point: row 133, column 49
  DEFB $9A,$00            ; Point: row 154, column 0
  DEFB $C0,$74,$00        ; Second point: row 116, column 0
  DEFB $69,$11            ; Point: row 105, column 17
  DEFB $5D,$2F            ; Point: row 93, column 47
  DEFB $56,$1C            ; Point: row 86, column 28
  DEFB $41,$00            ; Point: row 65, column 0
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$A8            ; Point: row 191, column 168
  DEFB $E1,$25            ; Part 37 (PART37), keeping the points
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$25            ; Part 37 (PART37), keeping the points
  DEFB $3F,$00            ; Point: row 63, column 0
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$00            ; Point: row 0, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $46,$FF            ; Point: row 70, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $F7                ; Patch 18
  DEFB $2A,$00,$00,$82,$00 ; Object: type 42; +12 value 0, along 0, top 130,
                           ; across 0
  DEFB $2A,$00,$14,$82,$AE ; Object: type 42; +12 value 0, along 20, top 130,
                           ; across 174
  DEFB $2A,$00,$94,$82,$DE ; Object: type 42; +12 value 0, along 148, top 130,
                           ; across 222
  DEFB $E5                ; End

; Room 6
ROOM6:
  DEFB $4A,$00            ; Length: 74 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E1,$1F            ; Part 31 (PART31), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $38,$5D            ; Point: row 56, column 93
  DEFB $C8                ; Mode bit 5 off
  DEFB $6A,$59            ; Point: row 106, column 89
  DEFB $C9                ; Mode bit 6 on
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $CA                ; Mode bit 6 off
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $28,$31            ; Point: row 40, column 49
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $84,$E2            ; Point: row 132, column 226
  DEFB $93,$D9            ; Point: row 147, column 217
  DEFB $BF,$D7            ; Point: row 191, column 215
  DEFB $C0,$6A,$5A        ; Second point: row 106, column 90
  DEFB $8D,$5C            ; Point: row 141, column 92
  DEFB $A9,$63            ; Point: row 169, column 99
  DEFB $B8,$77            ; Point: row 184, column 119
  DEFB $B4,$86            ; Point: row 180, column 134
  DEFB $AB,$8D            ; Point: row 171, column 141
  DEFB $82,$92            ; Point: row 130, column 146
  DEFB $C4                ; Mode bit 2 off
  DEFB $94,$5F            ; Point: row 148, column 95
  DEFB $C3                ; Mode bit 2 on
  DEFB $8D,$A5            ; Point: row 141, column 165
  DEFB $98,$AD            ; Point: row 152, column 173
  DEFB $BF,$AD            ; Point: row 191, column 173
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $BF,$C8            ; Point: row 191, column 200
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $A5,$8D            ; Point: row 165, column 141
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $E4,$04            ; Objects follow
  DEFB $F5                ; Patch 16
  DEFB $2A,$00,$BA,$82,$AC ; Object: type 42; +12 value 0, along 186, top 130,
                           ; across 172
  DEFB $E5                ; End

; Room 7
ROOM7:
  DEFB $41,$00            ; Length: 65 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E1,$1F            ; Part 31 (PART31), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $17,$63            ; Point: row 23, column 99
  DEFB $C0,$14,$FF        ; Second point: row 20, column 255
  DEFB $1E,$E1            ; Point: row 30, column 225
  DEFB $35,$B9            ; Point: row 53, column 185
  DEFB $2C,$98            ; Point: row 44, column 152
  DEFB $1A,$80            ; Point: row 26, column 128
  DEFB $C0,$71,$A7        ; Second point: row 113, column 167
  DEFB $A0,$A5            ; Point: row 160, column 165
  DEFB $BF,$A8            ; Point: row 191, column 168
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $C8                ; Mode bit 5 off
  DEFB $41,$00            ; Point: row 65, column 0
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $3A,$03            ; Point: row 58, column 3
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $19,$7F            ; Point: row 25, column 127
  DEFB $C8                ; Mode bit 5 off
  DEFB $71,$A8            ; Point: row 113, column 168
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $32,$FF            ; Point: row 50, column 255
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $0B,$00,$02,$82,$06 ; Object: type 11; +12 value 0, along 2, top 130,
                           ; across 6
  DEFB $E5                ; End

; Room 8
ROOM8:
  DEFB $8C,$00            ; Length: 140 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E1,$1F            ; Part 31 (PART31), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $BF,$A3            ; Point: row 191, column 163
  DEFB $C0,$8C,$B1        ; Second point: row 140, column 177
  DEFB $AE,$FF            ; Point: row 174, column 255
  DEFB $C0,$85,$C1        ; Second point: row 133, column 193
  DEFB $A2,$FF            ; Point: row 162, column 255
  DEFB $C0,$94,$FF        ; Second point: row 148, column 255
  DEFB $79,$C7            ; Point: row 121, column 199
  DEFB $C4                ; Mode bit 2 off
  DEFB $5A,$FF            ; Point: row 90, column 255
  DEFB $C3                ; Mode bit 2 on
  DEFB $74,$B4            ; Point: row 116, column 180
  DEFB $6D,$A5            ; Point: row 109, column 165
  DEFB $55,$C6            ; Point: row 85, column 198
  DEFB $3F,$FF            ; Point: row 63, column 255
  DEFB $C0,$17,$FF        ; Second point: row 23, column 255
  DEFB $22,$E0            ; Point: row 34, column 224
  DEFB $36,$B9            ; Point: row 54, column 185
  DEFB $47,$8F            ; Point: row 71, column 143
  DEFB $4D,$7D            ; Point: row 77, column 125
  DEFB $3A,$5A            ; Point: row 58, column 90
  DEFB $21,$83            ; Point: row 33, column 131
  DEFB $0F,$63            ; Point: row 15, column 99
  DEFB $C0,$8F,$A6        ; Second point: row 143, column 166
  DEFB $8D,$B0            ; Point: row 141, column 176
  DEFB $C0,$2E,$25        ; Second point: row 46, column 37
  DEFB $30,$2F            ; Point: row 48, column 47
  DEFB $2D,$36            ; Point: row 45, column 54
  DEFB $25,$38            ; Point: row 37, column 56
  DEFB $C0,$A5,$EC        ; Second point: row 165, column 236
  DEFB $9B,$FF            ; Point: row 155, column 255
  DEFB $C0,$A0,$DD        ; Second point: row 160, column 221
  DEFB $92,$F8            ; Point: row 146, column 248
  DEFB $C0,$9A,$CE        ; Second point: row 154, column 206
  DEFB $8B,$EC            ; Point: row 139, column 236
  DEFB $C0,$94,$BF        ; Second point: row 148, column 191
  DEFB $84,$DE            ; Point: row 132, column 222
  DEFB $C0,$8E,$B2        ; Second point: row 142, column 178
  DEFB $7D,$D1            ; Point: row 125, column 209
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $8D,$FF            ; Point: row 141, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $50,$FF            ; Point: row 80, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $09,$FF            ; Point: row 9, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $3D,$FF            ; Point: row 61, column 255
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $28,$33            ; Point: row 40, column 51
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $2A,$00,$32,$82,$08 ; Object: type 42; +12 value 0, along 50, top 130,
                           ; across 8
  DEFB $2A,$00,$A8,$82,$42 ; Object: type 42; +12 value 0, along 168, top 130,
                           ; across 66
  DEFB $2B,$00,$56,$82,$3C ; Object: type 43; +12 value 0, along 86, top 130,
                           ; across 60
  DEFB $2C,$00,$28,$82,$78 ; Object: type 44; +12 value 0, along 40, top 130,
                           ; across 120
  DEFB $E5                ; End

; Room 9
ROOM9:
  DEFB $0E,$00            ; Length: 14 bytes
  DEFB $10                ; Colour: black on red
  DEFB $8D,$9C            ; Point: row 141, column 156
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $6A,$E2            ; Point: row 106, column 226
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $E0,$24            ; Part 36 (PART36)
  DEFB $E5                ; End

; Room 10
ROOM10:
  DEFB $4F,$00            ; Length: 79 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $15,$59            ; Point: row 21, column 89
  DEFB $C8                ; Mode bit 5 off
  DEFB $40,$AF            ; Point: row 64, column 175
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$25            ; Part 37 (PART37), keeping the points
  DEFB $29,$11            ; Point: row 41, column 17
  DEFB $E1,$25            ; Part 37 (PART37), keeping the points
  DEFB $70,$00            ; Point: row 112, column 0
  DEFB $E1,$1E            ; Part 30 (PART30), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $C8                ; Mode bit 5 off
  DEFB $3E,$01            ; Point: row 62, column 1
  DEFB $E1,$25            ; Part 37 (PART37), keeping the points
  DEFB $6A,$00            ; Point: row 106, column 0
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $3A,$83            ; Point: row 58, column 131
  DEFB $40,$B7            ; Point: row 64, column 183
  DEFB $73,$C0            ; Point: row 115, column 192
  DEFB $8D,$BC            ; Point: row 141, column 188
  DEFB $C0,$41,$FF        ; Second point: row 65, column 255
  DEFB $22,$E9            ; Point: row 34, column 233
  DEFB $18,$EF            ; Point: row 24, column 239
  DEFB $0F,$FF            ; Point: row 15, column 255
  DEFB $C0,$42,$B7        ; Second point: row 66, column 183
  DEFB $14,$C0            ; Point: row 20, column 192
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $6E,$FF            ; Point: row 110, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $32,$AA            ; Point: row 50, column 170
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $46,$00            ; Point: row 70, column 0
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $2B,$00,$5A,$82,$78 ; Object: type 43; +12 value 0, along 90, top 130,
                           ; across 120
  DEFB $E5                ; End

; Room 11
ROOM11:
  DEFB $78,$00            ; Length: 120 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $1F,$64            ; Point: row 31, column 100
  DEFB $C8                ; Mode bit 5 off
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E0,$25            ; Part 37 (PART37)
  DEFB $24,$74            ; Point: row 36, column 116
  DEFB $0D,$A2            ; Point: row 13, column 162
  DEFB $24,$DA            ; Point: row 36, column 218
  DEFB $C0,$57,$FF        ; Second point: row 87, column 255
  DEFB $6B,$DD            ; Point: row 107, column 221
  DEFB $70,$B6            ; Point: row 112, column 182
  DEFB $C0,$30,$A7        ; Second point: row 48, column 167
  DEFB $32,$B8            ; Point: row 50, column 184
  DEFB $39,$BA            ; Point: row 57, column 186
  DEFB $6F,$BA            ; Point: row 111, column 186
  DEFB $C0,$11,$FF        ; Second point: row 17, column 255
  DEFB $19,$E8            ; Point: row 25, column 232
  DEFB $C0,$47,$FF        ; Second point: row 71, column 255
  DEFB $2A,$C5            ; Point: row 42, column 197
  DEFB $C0,$37,$FF        ; Second point: row 55, column 255
  DEFB $24,$D9            ; Point: row 36, column 217
  DEFB $C0,$47,$E0        ; Second point: row 71, column 224
  DEFB $39,$FE            ; Point: row 57, column 254
  DEFB $C0,$41,$D4        ; Second point: row 65, column 212
  DEFB $31,$F4            ; Point: row 49, column 244
  DEFB $C0,$3A,$C4        ; Second point: row 58, column 196
  DEFB $29,$E5            ; Point: row 41, column 229
  DEFB $C0,$33,$BA        ; Second point: row 51, column 186
  DEFB $57,$FE            ; Point: row 87, column 254
  DEFB $C0,$47,$FE        ; Second point: row 71, column 254
  DEFB $4E,$EF            ; Point: row 78, column 239
  DEFB $C0,$2E,$C7        ; Second point: row 46, column 199
  DEFB $C4                ; Mode bit 2 off
  DEFB $19,$E9            ; Point: row 25, column 233
  DEFB $35,$B9            ; Point: row 53, column 185
  DEFB $C8                ; Mode bit 5 off
  DEFB $30,$A6            ; Point: row 48, column 166
  DEFB $C9                ; Mode bit 6 on
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $C8                ; Mode bit 5 off
  DEFB $70,$49            ; Point: row 112, column 73
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $CA                ; Mode bit 6 off
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $46,$D2            ; Point: row 70, column 210
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $46,$64            ; Point: row 70, column 100
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $23,$FF            ; Point: row 35, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $2A,$00,$00,$82,$14 ; Object: type 42; +12 value 0, along 0, top 130,
                           ; across 20
  DEFB $E5                ; End

; Room 12
ROOM12:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $10                ; Colour: black on red
  DEFB $E1,$24            ; Part 36 (PART36), keeping the points
  DEFB $E5                ; End

; Room 13
ROOM13:
  DEFB $1A,$00            ; Length: 26 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $E0,$37            ; Part 55 (PART55)
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$C8            ; Point: row 100, column 200
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E0,$36            ; Part 54 (PART54)
  DEFB $E4,$05,$3C,$00,$00 ; $E4 $05: origin 60, 0, 0
  DEFB $E0,$36            ; Part 54 (PART54)
  DEFB $E5                ; End

; Room 14
ROOM14:
  DEFB $0D,$00            ; Length: 13 bytes
  DEFB $78                ; Colour: bright black on white
  DEFB $E0,$0F            ; Part 15 (PART15)
  DEFB $E4,$05,$EB,$00,$14 ; $E4 $05: origin 235, 0, 20
  DEFB $E0,$37            ; Part 55 (PART55)
  DEFB $E5                ; End

; Room 15
ROOM15:
  DEFB $14,$00            ; Length: 20 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E0,$26            ; Part 38 (PART38)
  DEFB $E4,$04            ; Objects follow
  DEFB $02,$10,$6E,$78,$A0 ; Object: type 2; +12 value 16, along 110, top 120,
                           ; across 160
  DEFB $02,$10,$AA,$78,$A0 ; Object: type 2; +12 value 16, along 170, top 120,
                           ; across 160
  DEFB $E5                ; End

; Room 16
ROOM16:
  DEFB $08,$00            ; Length: 8 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E0,$2B            ; Part 43 (PART43)
  DEFB $E5                ; End

; Room 17
ROOM17:
  DEFB $2B,$00            ; Length: 43 bytes
  DEFB $70                ; Colour: bright black on yellow
  DEFB $C0,$BF,$2F        ; Second point: row 191, column 47
  DEFB $C7                ; Mode bit 5 on
  DEFB $87,$2F            ; Point: row 135, column 47
  DEFB $CF                ; Second point to the first
  DEFB $A8,$6F            ; Point: row 168, column 111
  DEFB $CF                ; Second point to the first
  DEFB $BF,$6F            ; Point: row 191, column 111
  DEFB $BF,$40            ; Point: row 191, column 64
  DEFB $E0,$12            ; Part 18 (PART18)
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$64            ; Point: row 191, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $AA,$64            ; Point: row 170, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E4,$05,$22,$F5,$32 ; $E4 $05: origin 34, 245, 50
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$04            ; Repeat what follows 4 times
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E4,$05,$0E,$0A,$00 ; $E4 $05: origin 14, 10, 0
  DEFB $D6                ; End of the repeat
  DEFB $E5                ; End

; Room 18
ROOM18:
  DEFB $08,$00            ; Length: 8 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E0,$26            ; Part 38 (PART38)
  DEFB $E5                ; End

; Room 19
ROOM19:
  DEFB $22,$00            ; Length: 34 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$12            ; Part 18 (PART18)
  DEFB $E0,$2B            ; Part 43 (PART43)
  DEFB $E4,$05,$14,$00,$1E ; $E4 $05: origin 20, 0, 30
  DEFB $E0,$31            ; Part 49 (PART49)
  DEFB $E4,$05,$5A,$00,$00 ; $E4 $05: origin 90, 0, 0
  DEFB $E1,$2B            ; Part 43 (PART43), keeping the points
  DEFB $E4,$04            ; Objects follow
  DEFB $02,$34,$0A,$4C,$82 ; Object: type 2; +12 value 52, along 10, top 76,
                           ; across 130
  DEFB $02,$34,$32,$4C,$78 ; Object: type 2; +12 value 52, along 50, top 76,
                           ; across 120
  DEFB $E5                ; End

; Room 20
ROOM20:
  DEFB $15,$00            ; Length: 21 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $66,$4A            ; Point: row 102, column 74
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E1,$02            ; Part 2 (PART2), keeping the points
  DEFB $60,$00            ; Point: row 96, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $59,$F7            ; Point: row 89, column 247
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Room 21
ROOM21:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$0E            ; Part 14 (PART14)
  DEFB $E5                ; End

; Room 22
ROOM22:
  DEFB $43,$00            ; Length: 67 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $E1,$0F            ; Part 15 (PART15), keeping the points
  DEFB $C0,$63,$61        ; Second point: row 99, column 97
  DEFB $C7                ; Mode bit 5 on
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $C3                ; Mode bit 2 on
  DEFB $5B,$6E            ; Point: row 91, column 110
  DEFB $5D,$6F            ; Point: row 93, column 111
  DEFB $C0,$63,$61        ; Second point: row 99, column 97
  DEFB $61,$5B            ; Point: row 97, column 91
  DEFB $61,$58            ; Point: row 97, column 88
  DEFB $5E,$58            ; Point: row 94, column 88
  DEFB $5E,$5A            ; Point: row 94, column 90
  DEFB $60,$5B            ; Point: row 96, column 91
  DEFB $C0,$63,$61        ; Second point: row 99, column 97
  DEFB $57,$5A            ; Point: row 87, column 90
  DEFB $56,$5F            ; Point: row 86, column 95
  DEFB $5A,$5C            ; Point: row 90, column 92
  DEFB $C0,$56,$5F        ; Second point: row 86, column 95
  DEFB $54,$65            ; Point: row 84, column 101
  DEFB $55,$69            ; Point: row 85, column 105
  DEFB $51,$69            ; Point: row 81, column 105
  DEFB $53,$66            ; Point: row 83, column 102
  DEFB $C0,$52,$54        ; Second point: row 82, column 84
  DEFB $57,$5B            ; Point: row 87, column 91
  DEFB $C0,$5C,$5D        ; Second point: row 92, column 93
  DEFB $5F,$5B            ; Point: row 95, column 91
  DEFB $C0,$59,$63        ; Second point: row 89, column 99
  DEFB $56,$61            ; Point: row 86, column 97
  DEFB $E1,$32            ; Part 50 (PART50), keeping the points
  DEFB $E5                ; End

; Room 23
ROOM23:
  DEFB $08,$00            ; Length: 8 bytes
  DEFB $08                ; Colour: black on blue
  DEFB $E0,$32            ; Part 50 (PART50)
  DEFB $E0,$1B            ; Part 27 (PART27)
  DEFB $E5                ; End

; Room 24
ROOM24:
  DEFB $0D,$00            ; Length: 13 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$1B            ; Part 27 (PART27)
  DEFB $E4,$05,$4C,$1E,$32 ; $E4 $05: origin 76, 30, 50
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E5                ; End

; Room 25
ROOM25:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$0E            ; Part 14 (PART14)
  DEFB $E5                ; End

; Room 26
ROOM26:
  DEFB $16,$00            ; Length: 22 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $C0,$64,$DC        ; Second point: row 100, column 220
  DEFB $52,$FF            ; Point: row 82, column 255
  DEFB $D2                ; Line between the points
  DEFB $E1,$0E            ; Part 14 (PART14), keeping the points
  DEFB $E1,$10            ; Part 16 (PART16), keeping the points
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $CD                ; Mode bit 1 on
  DEFB $76,$FF            ; Point: row 118, column 255
  DEFB $D2                ; Line between the points
  DEFB $6E,$FF            ; Point: row 110, column 255
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E5                ; End

; Room 27
ROOM27:
  DEFB $B7,$00            ; Length: 183 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $28,$63            ; Point: row 40, column 99
  DEFB $C0,$56,$88        ; Second point: row 86, column 136
  DEFB $A2,$E6            ; Point: row 162, column 230
  DEFB $85,$E4            ; Point: row 133, column 228
  DEFB $C0,$B9,$BB        ; Second point: row 185, column 187
  DEFB $6E,$5C            ; Point: row 110, column 92
  DEFB $57,$2F            ; Point: row 87, column 47
  DEFB $BF,$30            ; Point: row 191, column 48
  DEFB $C0,$57,$2F        ; Second point: row 87, column 47
  DEFB $6F,$00            ; Point: row 111, column 0
  DEFB $C0,$97,$FF        ; Second point: row 151, column 255
  DEFB $B9,$BA            ; Point: row 185, column 186
  DEFB $BF,$BA            ; Point: row 191, column 186
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $1B,$4A            ; Point: row 27, column 74
  DEFB $76,$FF            ; Point: row 118, column 255
  DEFB $84,$E4            ; Point: row 132, column 228
  DEFB $56,$88            ; Point: row 86, column 136
  DEFB $C0,$6C,$5C        ; Second point: row 108, column 92
  DEFB $D2                ; Line between the points
  DEFB $C4                ; Mode bit 2 off
  DEFB $C5                ; Mode bit 3 on
  DEFB $C4                ; Mode bit 2 off
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$13            ; Repeat what follows 19 times
  DEFB $01,$00            ; Point: row 1, column 0
  DEFB $01,$00            ; Point: row 1, column 0
  DEFB $02,$05            ; Point: row 2, column 5
  DEFB $D6                ; End of the repeat
  DEFB $C8                ; Mode bit 5 off
  DEFB $C2                ; Mode bit 4 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $BE,$00            ; Point: row 190, column 0
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $78,$FF            ; Point: row 120, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $BE,$64            ; Point: row 190, column 100
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $59,$3F            ; Point: row 89, column 63
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E4,$04            ; Objects follow
  DEFB $E7                ; Patch 2
  DEFB $0A,$03,$8C,$34,$82 ; Object: type 10; +12 value 3, along 140, top 52,
                           ; across 130
  DEFB $0A,$03,$91,$36,$82 ; Object: type 10; +12 value 3, along 145, top 54,
                           ; across 130
  DEFB $0A,$03,$96,$38,$82 ; Object: type 10; +12 value 3, along 150, top 56,
                           ; across 130
  DEFB $0A,$03,$9B,$3A,$82 ; Object: type 10; +12 value 3, along 155, top 58,
                           ; across 130
  DEFB $0A,$03,$A0,$3C,$82 ; Object: type 10; +12 value 3, along 160, top 60,
                           ; across 130
  DEFB $0A,$03,$A5,$3E,$82 ; Object: type 10; +12 value 3, along 165, top 62,
                           ; across 130
  DEFB $0A,$03,$AA,$40,$82 ; Object: type 10; +12 value 3, along 170, top 64,
                           ; across 130
  DEFB $0A,$03,$AF,$42,$82 ; Object: type 10; +12 value 3, along 175, top 66,
                           ; across 130
  DEFB $0A,$03,$B4,$44,$82 ; Object: type 10; +12 value 3, along 180, top 68,
                           ; across 130
  DEFB $0A,$03,$B9,$46,$82 ; Object: type 10; +12 value 3, along 185, top 70,
                           ; across 130
  DEFB $0A,$03,$BE,$48,$82 ; Object: type 10; +12 value 3, along 190, top 72,
                           ; across 130
  DEFB $0A,$03,$C3,$4A,$82 ; Object: type 10; +12 value 3, along 195, top 74,
                           ; across 130
  DEFB $0A,$03,$C8,$4C,$82 ; Object: type 10; +12 value 3, along 200, top 76,
                           ; across 130
  DEFB $0A,$03,$CD,$4E,$82 ; Object: type 10; +12 value 3, along 205, top 78,
                           ; across 130
  DEFB $0A,$03,$D2,$50,$82 ; Object: type 10; +12 value 3, along 210, top 80,
                           ; across 130
  DEFB $0A,$03,$D7,$52,$82 ; Object: type 10; +12 value 3, along 215, top 82,
                           ; across 130
  DEFB $0A,$03,$DC,$54,$82 ; Object: type 10; +12 value 3, along 220, top 84,
                           ; across 130
  DEFB $0A,$03,$E1,$56,$82 ; Object: type 10; +12 value 3, along 225, top 86,
                           ; across 130
  DEFB $0A,$03,$E6,$58,$82 ; Object: type 10; +12 value 3, along 230, top 88,
                           ; across 130
  DEFB $E5                ; End

; Room 28
ROOM28:
  DEFB $15,$00            ; Length: 21 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $5C,$38            ; Point: row 92, column 56
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$FF            ; Point: row 100, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E0,$31            ; Part 49 (PART49)
  DEFB $E5                ; End

; Room 29
ROOM29:
  DEFB $97,$00            ; Length: 151 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $C0,$BF,$7F        ; Second point: row 191, column 127
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $4E,$7F            ; Point: row 78, column 127
  DEFB $67,$AF            ; Point: row 103, column 175
  DEFB $BF,$B0            ; Point: row 191, column 176
  DEFB $97,$FF            ; Point: row 151, column 255
  DEFB $C0,$BF,$BA        ; Second point: row 191, column 186
  DEFB $9D,$FF            ; Point: row 157, column 255
  DEFB $C0,$67,$B0        ; Second point: row 103, column 176
  DEFB $3F,$FF            ; Point: row 63, column 255
  DEFB $C0,$00,$81        ; Second point: row 0, column 129
  DEFB $41,$00            ; Point: row 65, column 0
  DEFB $C0,$34,$19        ; Second point: row 52, column 25
  DEFB $5C,$6B            ; Point: row 92, column 107
  DEFB $50,$7E            ; Point: row 80, column 126
  DEFB $C0,$5C,$6B        ; Second point: row 92, column 107
  DEFB $86,$6B            ; Point: row 134, column 107
  DEFB $5C,$18            ; Point: row 92, column 24
  DEFB $36,$18            ; Point: row 54, column 24
  DEFB $C0,$5D,$17        ; Second point: row 93, column 23
  DEFB $68,$00            ; Point: row 104, column 0
  DEFB $92,$55            ; Point: row 146, column 85
  DEFB $87,$6B            ; Point: row 135, column 107
  DEFB $C0,$91,$54        ; Second point: row 145, column 84
  DEFB $BA,$54            ; Point: row 186, column 84
  DEFB $BF,$4A            ; Point: row 191, column 74
  DEFB $BB,$4A            ; Point: row 187, column 74
  DEFB $C0,$BC,$4E        ; Second point: row 188, column 78
  DEFB $95,$00            ; Point: row 149, column 0
  DEFB $C0,$B9,$53        ; Second point: row 185, column 83
  DEFB $90,$00            ; Point: row 144, column 0
  DEFB $E1,$19            ; Part 25 (PART25), keeping the points
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$94,$00        ; Second point: row 148, column 0
  DEFB $91,$05            ; Point: row 145, column 5
  DEFB $C1                ; Mode bit 4 on
  DEFB $C5                ; Mode bit 3 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $05,$09            ; Point: row 5, column 9
  DEFB $06,$0C            ; Point: row 6, column 12
  DEFB $D6                ; End of the repeat
  DEFB $04,$0A            ; Point: row 4, column 10
  DEFB $C6                ; Mode bit 3 off
  DEFB $C2                ; Mode bit 4 off
  DEFB $C8                ; Mode bit 5 off
  DEFB $57,$8E            ; Point: row 87, column 142
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $88,$94            ; Point: row 136, column 148
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $50,$72            ; Point: row 80, column 114
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $64,$F9            ; Point: row 100, column 249
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $B1,$A1            ; Point: row 177, column 161
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $B1,$73            ; Point: row 177, column 115
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $81,$69            ; Point: row 129, column 105
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $95,$51            ; Point: row 149, column 81
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$0A            ; Point: row 100, column 10
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $63,$00            ; Point: row 99, column 0
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $0B,$00,$82,$82,$7E ; Object: type 11; +12 value 0, along 130, top 130,
                           ; across 126
  DEFB $0B,$00,$32,$5C,$96 ; Object: type 11; +12 value 0, along 50, top 92,
                           ; across 150
  DEFB $E5                ; End

; Room 30
ROOM30:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $E0,$13            ; Part 19 (PART19)
  DEFB $E5                ; End

; Room 31
ROOM31:
  DEFB $13,$00            ; Length: 19 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $C0,$00,$80        ; Second point: row 0, column 128
  DEFB $D2                ; Line between the points
  DEFB $5A,$C8            ; Point: row 90, column 200
  DEFB $E1,$0A            ; Part 10 (PART10), keeping the points
  DEFB $E0,$13            ; Part 19 (PART19)
  DEFB $5A,$D2            ; Point: row 90, column 210
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $E5                ; End

; Room 32
ROOM32:
  DEFB $1F,$00            ; Length: 31 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $77,$4E            ; Point: row 119, column 78
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $C0,$BF,$7F        ; Second point: row 191, column 127
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $80,$7F            ; Point: row 128, column 127
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $00,$81            ; Point: row 0, column 129
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$FF            ; Point: row 100, column 255
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $E5                ; End

; Room 33
ROOM33:
  DEFB $1A,$00            ; Length: 26 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $C0,$00,$80        ; Second point: row 0, column 128
  DEFB $C7                ; Mode bit 5 on
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E0,$26            ; Part 38 (PART38)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $E5                ; End

; Room 34
ROOM34:
  DEFB $38,$00            ; Length: 56 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $C7                ; Mode bit 5 on
  DEFB $C5                ; Mode bit 3 on
  DEFB $24,$94            ; Point: row 36, column 148
  DEFB $C0,$10,$BD        ; Second point: row 16, column 189
  DEFB $D2                ; Line between the points
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$09            ; Repeat what follows 9 times
  DEFB $01,$00            ; Point: row 1, column 0
  DEFB $01,$00            ; Point: row 1, column 0
  DEFB $02,$05            ; Point: row 2, column 5
  DEFB $D6                ; End of the repeat
  DEFB $C6                ; Mode bit 3 off
  DEFB $C2                ; Mode bit 4 off
  DEFB $C3                ; Mode bit 2 on
  DEFB $49,$BF            ; Point: row 73, column 191
  DEFB $2B,$86            ; Point: row 43, column 134
  DEFB $24,$94            ; Point: row 36, column 148
  DEFB $47,$BF            ; Point: row 71, column 191
  DEFB $C4                ; Mode bit 2 off
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $C9                ; Mode bit 6 on
  DEFB $81,$69            ; Point: row 129, column 105
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E1,$08            ; Part 8 (PART8), keeping the points
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$FF            ; Point: row 100, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $34,$99            ; Point: row 52, column 153
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Room 35
ROOM35:
  DEFB $21,$00            ; Length: 33 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$14            ; Part 20 (PART20)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C3                ; Mode bit 2 on
  DEFB $BF,$3F            ; Point: row 191, column 63
  DEFB $9F,$00            ; Point: row 159, column 0
  DEFB $C8                ; Mode bit 5 off
  DEFB $C9                ; Mode bit 6 on
  DEFB $33,$65            ; Point: row 51, column 101
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$32            ; Point: row 100, column 50
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $46,$64            ; Point: row 70, column 100
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E5                ; End

; Room 36
ROOM36:
  DEFB $14,$00            ; Length: 20 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $59,$79            ; Point: row 89, column 121
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $E0,$14            ; Part 20 (PART20)
  DEFB $7F,$00            ; Point: row 127, column 0
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $46,$64            ; Point: row 70, column 100
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E5                ; End

; Room 37
ROOM37:
  DEFB $6B,$00            ; Length: 107 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $59,$50            ; Point: row 89, column 80
  DEFB $E1,$0A            ; Part 10 (PART10), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C0,$87,$50        ; Second point: row 135, column 80
  DEFB $8A,$4C            ; Point: row 138, column 76
  DEFB $8F,$50            ; Point: row 143, column 80
  DEFB $92,$5B            ; Point: row 146, column 91
  DEFB $8A,$6D            ; Point: row 138, column 109
  DEFB $7F,$75            ; Point: row 127, column 117
  DEFB $75,$76            ; Point: row 117, column 118
  DEFB $76,$71            ; Point: row 118, column 113
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$1C,$C7        ; Second point: row 28, column 199
  DEFB $7F,$00            ; Point: row 127, column 0
  DEFB $38,$FF            ; Point: row 56, column 255
  DEFB $7C,$C7            ; Point: row 124, column 199
  DEFB $CF                ; Second point to the first
  DEFB $98,$FF            ; Point: row 152, column 255
  DEFB $BF,$42            ; Point: row 191, column 66
  DEFB $C0,$00,$80        ; Second point: row 0, column 128
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $82,$28            ; Point: row 130, column 40
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $67,$FA            ; Point: row 103, column 250
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $46,$64            ; Point: row 70, column 100
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $5F,$4C            ; Point: row 95, column 76
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $AD,$27            ; Point: row 173, column 39
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $23,$D9            ; Point: row 35, column 217
  DEFB $D6                ; End of the repeat
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $07,$00,$72,$8A,$7E ; Object: type 7; +12 value 0, along 114, top 138,
                           ; across 126
  DEFB $07,$00,$72,$8A,$96 ; Object: type 7; +12 value 0, along 114, top 138,
                           ; across 150
  DEFB $16,$00,$6C,$50,$AA ; Object: type 22; +12 value 0, along 108, top 80,
                           ; across 170
  DEFB $16,$00,$6C,$50,$78 ; Object: type 22; +12 value 0, along 108, top 80,
                           ; across 120
  DEFB $33,$80,$6E,$64,$46 ; Object: type 51; +12 value 128, along 110, top
                           ; 100, across 70
  DEFB $36,$00,$6E,$5A,$44 ; Object: type 54; +12 value 0, along 110, top 90,
                           ; across 68
  DEFB $E5                ; End

; Room 38
ROOM38:
  DEFB $43,$00            ; Length: 67 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E4,$05,$00,$00,$E0 ; $E4 $05: origin 0, 0, 224
  DEFB $E0,$38            ; Part 56 (PART56)
  DEFB $E4,$05,$00,$00,$46 ; $E4 $05: origin 0, 0, 70
  DEFB $E0,$38            ; Part 56 (PART56)
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $00,$81            ; Point: row 0, column 129
  DEFB $1F,$C0            ; Point: row 31, column 192
  DEFB $83,$C0            ; Point: row 131, column 192
  DEFB $A7,$7A            ; Point: row 167, column 122
  DEFB $C0,$1C,$C7        ; Second point: row 28, column 199
  DEFB $35,$94            ; Point: row 53, column 148
  DEFB $9A,$94            ; Point: row 154, column 148
  DEFB $BF,$47            ; Point: row 191, column 71
  DEFB $5B,$48            ; Point: row 91, column 72
  DEFB $C4                ; Mode bit 2 off
  DEFB $7F,$00            ; Point: row 127, column 0
  DEFB $82,$93            ; Point: row 130, column 147
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $46,$64            ; Point: row 70, column 100
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$AA            ; Point: row 100, column 170
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $BF,$1E            ; Point: row 191, column 30
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $A0,$5A            ; Point: row 160, column 90
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $E5                ; End

; Room 39
ROOM39:
  DEFB $0A,$00            ; Length: 10 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $81,$61            ; Point: row 129, column 97
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E5                ; End

; Room 40
ROOM40:
  DEFB $10,$00            ; Length: 16 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $C9                ; Mode bit 6 on
  DEFB $6E,$D8            ; Point: row 110, column 216
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $83,$65            ; Point: row 131, column 101
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $E0,$12            ; Part 18 (PART18)
  DEFB $E5                ; End

; Room 41
ROOM41:
  DEFB $1C,$00            ; Length: 28 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $5C,$36            ; Point: row 92, column 54
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $64,$FF            ; Point: row 100, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E0,$2E            ; Part 46 (PART46)
  DEFB $E4,$05,$6E,$0A,$32 ; $E4 $05: origin 110, 10, 50
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E5                ; End

; Room 42
ROOM42:
  DEFB $1C,$00            ; Length: 28 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $2F,$64            ; Point: row 47, column 100
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $42,$04            ; Point: row 66, column 4
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E0,$23            ; Part 35 (PART35)
  DEFB $E4,$04            ; Objects follow
  DEFB $02,$10,$32,$3E,$6E ; Object: type 2; +12 value 16, along 50, top 62,
                           ; across 110
  DEFB $02,$10,$40,$3E,$5C ; Object: type 2; +12 value 16, along 64, top 62,
                           ; across 92
  DEFB $E5                ; End

; Room 43
ROOM43:
  DEFB $39,$00            ; Length: 57 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $6B,$94            ; Point: row 107, column 148
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $6B,$C8            ; Point: row 107, column 200
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C0,$00,$7F        ; Second point: row 0, column 127
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $74,$68            ; Point: row 116, column 104
  DEFB $42,$CD            ; Point: row 66, column 205
  DEFB $0E,$65            ; Point: row 14, column 101
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$BB,$68        ; Second point: row 187, column 104
  DEFB $89,$00            ; Point: row 137, column 0
  DEFB $75,$68            ; Point: row 117, column 104
  DEFB $89,$CC            ; Point: row 137, column 204
  DEFB $CF                ; Second point to the first
  DEFB $43,$CC            ; Point: row 67, column 204
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $76,$6F            ; Point: row 118, column 111
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E4,$04            ; Objects follow
  DEFB $ED                ; Patch 8
  DEFB $E5                ; End

; Room 44
ROOM44:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $E0,$22            ; Part 34 (PART34)
  DEFB $E5                ; End

; Room 45
ROOM45:
  DEFB $66,$00            ; Length: 102 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $E4,$05,$1E,$00,$08 ; $E4 $05: origin 30, 0, 8
  DEFB $E0,$31            ; Part 49 (PART49)
  DEFB $E4,$05,$00,$00,$C9 ; $E4 $05: origin 0, 0, 201
  DEFB $E0,$2B            ; Part 43 (PART43)
  DEFB $47,$0B            ; Point: row 71, column 11
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C0,$29,$30        ; Second point: row 41, column 48
  DEFB $2D,$39            ; Point: row 45, column 57
  DEFB $45,$08            ; Point: row 69, column 8
  DEFB $54,$26            ; Point: row 84, column 38
  DEFB $3B,$58            ; Point: row 59, column 88
  DEFB $5C,$99            ; Point: row 92, column 153
  DEFB $33,$E8            ; Point: row 51, column 232
  DEFB $00,$81            ; Point: row 0, column 129
  DEFB $C0,$34,$E9        ; Second point: row 52, column 233
  DEFB $6B,$E9            ; Point: row 107, column 233
  DEFB $94,$99            ; Point: row 148, column 153
  DEFB $74,$59            ; Point: row 116, column 89
  DEFB $8B,$25            ; Point: row 139, column 37
  DEFB $7D,$08            ; Point: row 125, column 8
  DEFB $C5                ; Mode bit 3 on
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$B6,$08        ; Second point: row 182, column 8
  DEFB $46,$08            ; Point: row 70, column 8
  DEFB $54,$25            ; Point: row 84, column 37
  DEFB $3C,$58            ; Point: row 60, column 88
  DEFB $5D,$99            ; Point: row 93, column 153
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$09            ; Point: row 100, column 9
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$46            ; Point: row 100, column 70
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$C8            ; Point: row 100, column 200
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $32,$64            ; Point: row 50, column 100
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $E4,$04            ; Objects follow
  DEFB $EF                ; Patch 10
  DEFB $0B,$00,$5A,$64,$74 ; Object: type 11; +12 value 0, along 90, top 100,
                           ; across 116
  DEFB $0C,$00,$0A,$82,$74 ; Object: type 12; +12 value 0, along 10, top 130,
                           ; across 116
  DEFB $E5                ; End

; Room 46
ROOM46:
  DEFB $51,$00            ; Length: 81 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $E4,$05,$F6,$00,$C9 ; $E4 $05: origin 246, 0, 201
  DEFB $E0,$2B            ; Part 43 (PART43)
  DEFB $42,$54            ; Point: row 66, column 84
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $1C,$49            ; Point: row 28, column 73
  DEFB $21,$53            ; Point: row 33, column 83
  DEFB $04,$8C            ; Point: row 4, column 140
  DEFB $3E,$FF            ; Point: row 62, column 255
  DEFB $C0,$2D,$2C        ; Second point: row 45, column 44
  DEFB $81,$D4            ; Point: row 129, column 212
  DEFB $BF,$D4            ; Point: row 191, column 212
  DEFB $6A,$2B            ; Point: row 106, column 43
  DEFB $2B,$2B            ; Point: row 43, column 43
  DEFB $C0,$9C,$D4        ; Second point: row 156, column 212
  DEFB $8F,$EF            ; Point: row 143, column 239
  DEFB $C4                ; Mode bit 2 off
  DEFB $BF,$EF            ; Point: row 191, column 239
  DEFB $96,$FF            ; Point: row 150, column 255
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$C8            ; Point: row 100, column 200
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $64,$82            ; Point: row 100, column 130
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $AA,$FF            ; Point: row 170, column 255
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $AA,$E6            ; Point: row 170, column 230
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E4,$04            ; Objects follow
  DEFB $F0                ; Patch 11
  DEFB $0C,$00,$14,$82,$0C ; Object: type 12; +12 value 0, along 20, top 130,
                           ; across 12
  DEFB $01,$00,$46,$3C,$28 ; Object: type 1; +12 value 0, along 70, top 60,
                           ; across 40
  DEFB $E5                ; End

; Room 47
ROOM47:
  DEFB $27,$00            ; Length: 39 bytes
  DEFB $78                ; Colour: bright black on white
  DEFB $5B,$35            ; Point: row 91, column 53
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $5B,$38            ; Point: row 91, column 56
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $7B,$9B            ; Point: row 123, column 155
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $58,$E4            ; Point: row 88, column 228
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $74,$3E            ; Point: row 116, column 62
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $E0,$36            ; Part 54 (PART54)
  DEFB $E4,$05,$3C,$00,$00 ; $E4 $05: origin 60, 0, 0
  DEFB $E0,$36            ; Part 54 (PART54)
  DEFB $E5                ; End

; Room 48
ROOM48:
  DEFB $50,$00            ; Length: 80 bytes
  DEFB $78                ; Colour: bright black on white
  DEFB $E1,$36            ; Part 54 (PART54), keeping the points
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $E0,$35            ; Part 53 (PART53)
  DEFB $E4,$05,$0A,$05,$00 ; $E4 $05: origin 10, 5, 0
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $E0,$35            ; Part 53 (PART53)
  DEFB $E4,$05,$0A,$00,$00 ; $E4 $05: origin 10, 0, 0
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $E4,$05,$00,$00,$00 ; $E4 $05: origin 0, 0, 0
  DEFB $E4,$04            ; Objects follow
  DEFB $16,$00,$AA,$50,$52 ; Object: type 22; +12 value 0, along 170, top 80,
                           ; across 82
  DEFB $16,$00,$AA,$50,$8C ; Object: type 22; +12 value 0, along 170, top 80,
                           ; across 140
  DEFB $14,$00,$A4,$52,$6E ; Object: type 20; +12 value 0, along 164, top 82,
                           ; across 110
  DEFB $14,$00,$A4,$52,$82 ; Object: type 20; +12 value 0, along 164, top 82,
                           ; across 130
  DEFB $14,$00,$A4,$42,$8A ; Object: type 20; +12 value 0, along 164, top 66,
                           ; across 138
  DEFB $14,$00,$A4,$42,$64 ; Object: type 20; +12 value 0, along 164, top 66,
                           ; across 100
  DEFB $14,$00,$96,$42,$8A ; Object: type 20; +12 value 0, along 150, top 66,
                           ; across 138
  DEFB $05,$00,$A8,$4C,$70 ; Object: type 5; +12 value 0, along 168, top 76,
                           ; across 112
  DEFB $E5                ; End

; Room 49
ROOM49:
  DEFB $1F,$00            ; Length: 31 bytes
  DEFB $78                ; Colour: bright black on white
  DEFB $5B,$DF            ; Point: row 91, column 223
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $7E,$98            ; Point: row 126, column 152
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $5A,$CA            ; Point: row 90, column 202
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $62,$C3            ; Point: row 98, column 195
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $E0,$28            ; Part 40 (PART40)
  DEFB $E5                ; End

; Room 50
ROOM50:
  DEFB $1B,$00            ; Length: 27 bytes
  DEFB $78                ; Colour: bright black on white
  DEFB $5A,$35            ; Point: row 90, column 53
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $5B,$36            ; Point: row 91, column 54
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $6E,$40            ; Point: row 110, column 64
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $64,$C4            ; Point: row 100, column 196
  DEFB $F0                ; Fill with texture 10 (TEXTURE10)
  DEFB $E0,$29            ; Part 41 (PART41)
  DEFB $E5                ; End

; Room 51
ROOM51:
  DEFB $40,$00            ; Length: 64 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $90,$9F            ; Point: row 144, column 159
  DEFB $C0,$BF,$9F        ; Second point: row 191, column 159
  DEFB $71,$9F            ; Point: row 113, column 159
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $C0,$22,$FF        ; Second point: row 34, column 255
  DEFB $31,$E0            ; Point: row 49, column 224
  DEFB $00,$7F            ; Point: row 0, column 127
  DEFB $C0,$4F,$75        ; Second point: row 79, column 117
  DEFB $45,$89            ; Point: row 69, column 137
  DEFB $3B,$75            ; Point: row 59, column 117
  DEFB $45,$61            ; Point: row 69, column 97
  DEFB $4F,$75            ; Point: row 79, column 117
  DEFB $3C,$75            ; Point: row 60, column 117
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $48,$77            ; Point: row 72, column 119
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $E4,$05,$04,$00,$0C ; $E4 $05: origin 4, 0, 12
  DEFB $E0,$31            ; Part 49 (PART49)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $E5                ; End

; Room 52
ROOM52:
  DEFB $2C,$00            ; Length: 44 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $2F,$5C            ; Point: row 47, column 92
  DEFB $C0,$BF,$6F        ; Second point: row 191, column 111
  DEFB $39,$6F            ; Point: row 57, column 111
  DEFB $21,$3E            ; Point: row 33, column 62
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C0,$40,$3F        ; Second point: row 64, column 63
  DEFB $C4                ; Mode bit 2 off
  DEFB $BF,$3F            ; Point: row 191, column 63
  DEFB $5F,$00            ; Point: row 95, column 0
  DEFB $57,$6E            ; Point: row 87, column 110
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $BF,$41            ; Point: row 191, column 65
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $5A,$00            ; Point: row 90, column 0
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $E4,$04            ; Objects follow
  DEFB $F1                ; Patch 12
  DEFB $E5                ; End

; Room 53
ROOM53:
  DEFB $0D,$00            ; Length: 13 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $E4,$04            ; Objects follow
  DEFB $02,$10,$34,$3E,$96 ; Object: type 2; +12 value 16, along 52, top 62,
                           ; across 150
  DEFB $E5                ; End

; Room 54
ROOM54:
  DEFB $08,$00            ; Length: 8 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E0,$2D            ; Part 45 (PART45)
  DEFB $E5                ; End

; Room 55
ROOM55:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 56
ROOM56:
  DEFB $15,$00            ; Length: 21 bytes
  DEFB $38                ; Colour: black on white
  DEFB $5F,$27            ; Point: row 95, column 39
  DEFB $E1,$07            ; Part 7 (PART7), keeping the points
  DEFB $72,$4B            ; Point: row 114, column 75
  DEFB $E1,$07            ; Part 7 (PART7), keeping the points
  DEFB $E1,$2F            ; Part 47 (PART47), keeping the points
  DEFB $E4,$05,$00,$00,$22 ; $E4 $05: origin 0, 0, 34
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $E5                ; End

; Room 57
ROOM57:
  DEFB $11,$00            ; Length: 17 bytes
  DEFB $38                ; Colour: black on white
  DEFB $45,$08            ; Point: row 69, column 8
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $E4,$04            ; Objects follow
  DEFB $07,$00,$80,$6E,$6E ; Object: type 7; +12 value 0, along 128, top 110,
                           ; across 110
  DEFB $E5                ; End

; Room 58
ROOM58:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 59
ROOM59:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 60
ROOM60:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 61
ROOM61:
  DEFB $2F,$00            ; Length: 47 bytes
  DEFB $38                ; Colour: black on white
  DEFB $61,$32            ; Point: row 97, column 50
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $79,$63            ; Point: row 121, column 99
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $61,$32            ; Point: row 97, column 50
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $79,$63            ; Point: row 121, column 99
  DEFB $E1,$17            ; Part 23 (PART23), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $64,$5E            ; Point: row 100, column 94
  DEFB $E1,$18            ; Part 24 (PART24), keeping the points
  DEFB $E1,$02            ; Part 2 (PART2), keeping the points
  DEFB $32,$32            ; Point: row 50, column 50
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $E4,$05,$2A,$00,$00 ; $E4 $05: origin 42, 0, 0
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $E4,$05,$64,$00,$00 ; $E4 $05: origin 100, 0, 0
  DEFB $E0,$2C            ; Part 44 (PART44)
  DEFB $E5                ; End

; Room 62
ROOM62:
  DEFB $38,$00            ; Length: 56 bytes
  DEFB $68                ; Colour: bright black on cyan
  DEFB $88,$90            ; Point: row 136, column 144
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $4D,$58            ; Point: row 77, column 88
  DEFB $C8                ; Mode bit 5 off
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C7                ; Mode bit 5 on
  DEFB $97,$AF            ; Point: row 151, column 175
  DEFB $88,$CD            ; Point: row 136, column 205
  DEFB $BF,$CD            ; Point: row 191, column 205
  DEFB $C0,$97,$AF        ; Second point: row 151, column 175
  DEFB $BF,$AF            ; Point: row 191, column 175
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $31,$1E            ; Point: row 49, column 30
  DEFB $88,$CD            ; Point: row 136, column 205
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$C8            ; Point: row 191, column 200
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $E4,$04            ; Objects follow
  DEFB $F2                ; Patch 13
  DEFB $02,$10,$C8,$6E,$A0 ; Object: type 2; +12 value 16, along 200, top 110,
                           ; across 160
  DEFB $E5                ; End

; Room 63
ROOM63:
  DEFB $0C,$00            ; Length: 12 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $68,$7F            ; Point: row 104, column 127
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$22            ; Part 34 (PART34)
  DEFB $E5                ; End

; Room 64
ROOM64:
  DEFB $55,$00            ; Length: 85 bytes
  DEFB $38                ; Colour: black on white
  DEFB $83,$29            ; Point: row 131, column 41
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $C3                ; Mode bit 2 on
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C7                ; Mode bit 5 on
  DEFB $00,$80            ; Point: row 0, column 128
  DEFB $28,$D0            ; Point: row 40, column 208
  DEFB $C4                ; Mode bit 2 off
  DEFB $41,$9F            ; Point: row 65, column 159
  DEFB $C3                ; Mode bit 2 on
  DEFB $7E,$D0            ; Point: row 126, column 208
  DEFB $96,$9F            ; Point: row 150, column 159
  DEFB $C0,$96,$00        ; Second point: row 150, column 0
  DEFB $AA,$28            ; Point: row 170, column 40
  DEFB $C0,$90,$64        ; Second point: row 144, column 100
  DEFB $90,$64            ; Point: row 144, column 100
  DEFB $C8                ; Mode bit 5 off
  DEFB $C4                ; Mode bit 2 off
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $C3                ; Mode bit 2 on
  DEFB $CB                ; Mode bit 0 on
  DEFB $0D,$66            ; Point: row 13, column 102
  DEFB $C7                ; Mode bit 5 on
  DEFB $23,$63            ; Point: row 35, column 99
  DEFB $C0,$19,$4F        ; Second point: row 25, column 79
  DEFB $40,$9D            ; Point: row 64, column 157
  DEFB $C0,$44,$9E        ; Second point: row 68, column 158
  DEFB $97,$9E            ; Point: row 151, column 158
  DEFB $C8                ; Mode bit 5 off
  DEFB $CC                ; Mode bit 0 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $64,$B4            ; Point: row 100, column 180
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $B3,$46            ; Point: row 179, column 70
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $1E,$78            ; Point: row 30, column 120
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E0,$2D            ; Part 45 (PART45)
  DEFB $E4,$04            ; Objects follow
  DEFB $F3                ; Patch 14
  DEFB $02,$10,$34,$3C,$82 ; Object: type 2; +12 value 16, along 52, top 60,
                           ; across 130
  DEFB $02,$10,$5C,$3E,$6E ; Object: type 2; +12 value 16, along 92, top 62,
                           ; across 110
  DEFB $E5                ; End

; Room 65
ROOM65:
  DEFB $0C,$00            ; Length: 12 bytes
  DEFB $38                ; Colour: black on white
  DEFB $45,$08            ; Point: row 69, column 8
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $E0,$2D            ; Part 45 (PART45)
  DEFB $E5                ; End

; Room 66
ROOM66:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 67
ROOM67:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E1,$16            ; Part 22 (PART22), keeping the points
  DEFB $E5                ; End

; Room 68
ROOM68:
  DEFB $06,$00            ; Length: 6 bytes
  DEFB $38                ; Colour: black on white
  DEFB $E0,$2F            ; Part 47 (PART47)
  DEFB $E5                ; End

; Room 69
ROOM69:
  DEFB $52,$00            ; Length: 82 bytes
  DEFB $38                ; Colour: black on white
  DEFB $C0,$BF,$67        ; Second point: row 191, column 103
  DEFB $BF,$67            ; Point: row 191, column 103
  DEFB $D2                ; Line between the points
  DEFB $E0,$0F            ; Part 15 (PART15)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $96,$64            ; Point: row 150, column 100
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $E4,$05,$4C,$F5,$32 ; $E4 $05: origin 76, 245, 50
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E4,$05,$00,$0E,$00 ; $E4 $05: origin 0, 14, 0
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $E4,$05,$00,$00,$00 ; $E4 $05: origin 0, 0, 0
  DEFB $E4,$04            ; Objects follow
  DEFB $23,$00,$32,$50,$6E ; Object: type 35; +12 value 0, along 50, top 80,
                           ; across 110
  DEFB $23,$00,$32,$50,$76 ; Object: type 35; +12 value 0, along 50, top 80,
                           ; across 118
  DEFB $24,$00,$32,$50,$64 ; Object: type 36; +12 value 0, along 50, top 80,
                           ; across 100
  DEFB $24,$00,$32,$50,$7E ; Object: type 36; +12 value 0, along 50, top 80,
                           ; across 126
  DEFB $00,$00,$32,$40,$56 ; Object: type 0; +12 value 0, along 50, top 64,
                           ; across 86
  DEFB $00,$00,$32,$40,$6C ; Object: type 0; +12 value 0, along 50, top 64,
                           ; across 108
  DEFB $00,$00,$32,$40,$82 ; Object: type 0; +12 value 0, along 50, top 64,
                           ; across 130
  DEFB $00,$00,$32,$40,$98 ; Object: type 0; +12 value 0, along 50, top 64,
                           ; across 152
  DEFB $E5                ; End

; Room 70
ROOM70:
  DEFB $21,$00            ; Length: 33 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $27,$E4            ; Point: row 39, column 228
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $E0,$14            ; Part 20 (PART20)
  DEFB $41,$00            ; Point: row 65, column 0
  DEFB $BF,$3F            ; Point: row 191, column 63
  DEFB $C0,$BF,$3F        ; Second point: row 191, column 63
  DEFB $9F,$00            ; Point: row 159, column 0
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $8C,$00            ; Point: row 140, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $8C,$64            ; Point: row 140, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $3C,$64            ; Point: row 60, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Room 71
ROOM71:
  DEFB $16,$00            ; Length: 22 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $E4,$05,$2A,$00,$00 ; $E4 $05: origin 42, 0, 0
  DEFB $E0,$27            ; Part 39 (PART39)
  DEFB $E0,$1C            ; Part 28 (PART28)
  DEFB $E4,$05,$00,$00,$5C ; $E4 $05: origin 0, 0, 92
  DEFB $E0,$2E            ; Part 46 (PART46)
  DEFB $E5                ; End

; Room 72
ROOM72:
  DEFB $14,$00            ; Length: 20 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $E0,$1C            ; Part 28 (PART28)
  DEFB $E4,$05,$00,$00,$5C ; $E4 $05: origin 0, 0, 92
  DEFB $E0,$2E            ; Part 46 (PART46)
  DEFB $E4,$05,$00,$0E,$5C ; $E4 $05: origin 0, 14, 92
  DEFB $E0,$2E            ; Part 46 (PART46)
  DEFB $E5                ; End

; Room 73
ROOM73:
  DEFB $22,$00            ; Length: 34 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $75,$2F            ; Point: row 117, column 47
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $E0,$14            ; Part 20 (PART20)
  DEFB $7F,$00            ; Point: row 127, column 0
  DEFB $C0,$00,$7F        ; Second point: row 0, column 127
  DEFB $C3                ; Mode bit 2 on
  DEFB $20,$BF            ; Point: row 32, column 191
  DEFB $7E,$BF            ; Point: row 126, column 191
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$C8            ; Point: row 100, column 200
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $00,$8C            ; Point: row 0, column 140
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$32            ; Point: row 100, column 50
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Room 74
ROOM74:
  DEFB $44,$00            ; Length: 68 bytes
  DEFB $10                ; Colour: black on red
  DEFB $43,$04            ; Point: row 67, column 4
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $12,$25            ; Point: row 18, column 37
  DEFB $E1,$1D            ; Part 29 (PART29), keeping the points
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $97,$AD            ; Point: row 151, column 173
  DEFB $E1,$20            ; Part 32 (PART32), keeping the points
  DEFB $6F,$5C            ; Point: row 111, column 92
  DEFB $E1,$20            ; Part 32 (PART32), keeping the points
  DEFB $6D,$5C            ; Point: row 109, column 92
  DEFB $E1,$20            ; Part 32 (PART32), keeping the points
  DEFB $95,$75            ; Point: row 149, column 117
  DEFB $E1,$20            ; Part 32 (PART32), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $36,$5E            ; Point: row 54, column 94
  DEFB $C8                ; Mode bit 5 off
  DEFB $3F,$01            ; Point: row 63, column 1
  DEFB $C0,$27,$34        ; Second point: row 39, column 52
  DEFB $D2                ; Line between the points
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $A6,$DD            ; Point: row 166, column 221
  DEFB $BF,$E5            ; Point: row 191, column 229
  DEFB $C8                ; Mode bit 5 off
  DEFB $27,$34            ; Point: row 39, column 52
  DEFB $E0,$1E            ; Part 30 (PART30)
  DEFB $84,$F2            ; Point: row 132, column 242
  DEFB $8E,$FF            ; Point: row 142, column 255
  DEFB $E1,$1F            ; Part 31 (PART31), keeping the points
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $6A,$5E            ; Point: row 106, column 94
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $E4,$04            ; Objects follow
  DEFB $F5                ; Patch 16
  DEFB $E5                ; End

; Room 75
ROOM75:
  DEFB $13,$00            ; Length: 19 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $42,$3C            ; Point: row 66, column 60
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$23            ; Part 35 (PART35)
  DEFB $E4,$05,$FB,$00,$EB ; $E4 $05: origin 251, 0, 235
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E5                ; End

; Room 76
ROOM76:
  DEFB $12,$00            ; Length: 18 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $69,$7F            ; Point: row 105, column 127
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$1A            ; Part 26 (PART26)
  DEFB $74,$64            ; Point: row 116, column 100
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $94,$7D            ; Point: row 148, column 125
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E5                ; End

; Room 77
ROOM77:
  DEFB $10,$00            ; Length: 16 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $88,$32            ; Point: row 136, column 50
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $97,$2A            ; Point: row 151, column 42
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $97,$4B            ; Point: row 151, column 75
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $E5                ; End

; Room 78
ROOM78:
  DEFB $46,$00            ; Length: 70 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $5B,$62            ; Point: row 91, column 98
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $49,$89            ; Point: row 73, column 137
  DEFB $E1,$30            ; Part 48 (PART48), keeping the points
  DEFB $4B,$16            ; Point: row 75, column 22
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $60,$40            ; Point: row 96, column 64
  DEFB $20,$BF            ; Point: row 32, column 191
  DEFB $C4                ; Mode bit 2 off
  DEFB $00,$82            ; Point: row 0, column 130
  DEFB $C3                ; Mode bit 2 on
  DEFB $5F,$BF            ; Point: row 95, column 191
  DEFB $A0,$40            ; Point: row 160, column 64
  DEFB $C4                ; Mode bit 2 off
  DEFB $60,$40            ; Point: row 96, column 64
  DEFB $80,$00            ; Point: row 128, column 0
  DEFB $C0,$5F,$BF        ; Second point: row 95, column 191
  DEFB $7F,$FF            ; Point: row 127, column 255
  DEFB $C0,$00,$D1        ; Second point: row 0, column 209
  DEFB $17,$FF            ; Point: row 23, column 255
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $51,$46            ; Point: row 81, column 70
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $5C,$1C            ; Point: row 92, column 28
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $64,$78            ; Point: row 100, column 120
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $46,$FF            ; Point: row 70, column 255
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $E5                ; End

; Room 79
ROOM79:
  DEFB $7D,$00            ; Length: 125 bytes
  DEFB $30                ; Colour: black on yellow
  DEFB $C0,$8D,$3F        ; Second point: row 141, column 63
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $AE,$38            ; Point: row 174, column 56
  DEFB $B3,$56            ; Point: row 179, column 86
  DEFB $B5,$7D            ; Point: row 181, column 125
  DEFB $B2,$A8            ; Point: row 178, column 168
  DEFB $AE,$BD            ; Point: row 174, column 189
  DEFB $8D,$B6            ; Point: row 141, column 182
  DEFB $91,$7D            ; Point: row 145, column 125
  DEFB $8C,$3F            ; Point: row 140, column 63
  DEFB $C0,$8C,$4B        ; Second point: row 140, column 75
  DEFB $85,$33            ; Point: row 133, column 51
  DEFB $91,$3D            ; Point: row 145, column 61
  DEFB $C0,$9C,$3C        ; Second point: row 156, column 60
  DEFB $9A,$2F            ; Point: row 154, column 47
  DEFB $A6,$39            ; Point: row 166, column 57
  DEFB $C0,$9C,$B9        ; Second point: row 156, column 185
  DEFB $9A,$C6            ; Point: row 154, column 198
  DEFB $A6,$BC            ; Point: row 166, column 188
  DEFB $C0,$8E,$A8        ; Second point: row 142, column 168
  DEFB $85,$C1            ; Point: row 133, column 193
  DEFB $91,$B8            ; Point: row 145, column 184
  DEFB $C0,$BD,$02        ; Second point: row 189, column 2
  DEFB $BD,$FD            ; Point: row 189, column 253
  DEFB $02,$FD            ; Point: row 2, column 253
  DEFB $02,$02            ; Point: row 2, column 2
  DEFB $BD,$02            ; Point: row 189, column 2
  DEFB $C0,$64,$8D        ; Second point: row 100, column 141
  DEFB $5C,$9E            ; Point: row 92, column 158
  DEFB $64,$9E            ; Point: row 100, column 158
  DEFB $64,$8D            ; Point: row 100, column 141
  DEFB $C0,$5A,$7B        ; Second point: row 90, column 123
  DEFB $52,$8C            ; Point: row 82, column 140
  DEFB $52,$7B            ; Point: row 82, column 123
  DEFB $5A,$7B            ; Point: row 90, column 123
  DEFB $C0,$50,$7C        ; Second point: row 80, column 124
  DEFB $50,$8C            ; Point: row 80, column 140
  DEFB $48,$7B            ; Point: row 72, column 123
  DEFB $50,$7B            ; Point: row 80, column 123
  DEFB $C0,$3E,$9E        ; Second point: row 62, column 158
  DEFB $46,$9E            ; Point: row 70, column 158
  DEFB $3E,$8D            ; Point: row 62, column 141
  DEFB $3E,$9E            ; Point: row 62, column 158
  DEFB $C0,$4B,$81        ; Second point: row 75, column 129
  DEFB $42,$93            ; Point: row 66, column 147
  DEFB $C0,$4D,$86        ; Second point: row 77, column 134
  DEFB $44,$98            ; Point: row 68, column 152
  DEFB $C0,$57,$81        ; Second point: row 87, column 129
  DEFB $60,$93            ; Point: row 96, column 147
  DEFB $C0,$55,$86        ; Second point: row 85, column 134
  DEFB $5E,$98            ; Point: row 94, column 152
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $03,$04            ; Point: row 3, column 4
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E5                ; End

; Room 80
ROOM80:
  DEFB $32,$00            ; Length: 50 bytes
  DEFB $48                ; Colour: bright black on blue
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $51,$55            ; Point: row 81, column 85
  DEFB $4F,$3B            ; Point: row 79, column 59
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $4F,$1D            ; Point: row 79, column 29
  DEFB $BF,$1D            ; Point: row 191, column 29
  DEFB $C0,$4F,$1D        ; Second point: row 79, column 29
  DEFB $40,$3A            ; Point: row 64, column 58
  DEFB $BF,$3A            ; Point: row 191, column 58
  DEFB $C0,$40,$39        ; Second point: row 64, column 57
  DEFB $32,$1C            ; Point: row 50, column 28
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$28            ; Point: row 100, column 40
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $40,$0A            ; Point: row 64, column 10
  DEFB $EF                ; Fill with texture 9 (TEXTURE9)
  DEFB $E4,$04            ; Objects follow
  DEFB $F9                ; Patch 20
  DEFB $02,$10,$32,$3C,$A0 ; Object: type 2; +12 value 16, along 50, top 60,
                           ; across 160
  DEFB $E5                ; End

; Room 81
ROOM81:
  DEFB $04,$00            ; Length: 4 bytes
  DEFB $46                ; Colour: bright yellow on black
  DEFB $E5                ; End

; Part 1
PART1:
  DEFB $1D,$00            ; Length: 29 bytes
  DEFB $C0,$80,$7F        ; Second point: row 128, column 127
  DEFB $C7                ; Mode bit 5 on
  DEFB $BE,$7F            ; Point: row 190, column 127
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C0,$00,$7F        ; Second point: row 0, column 127
  DEFB $D2                ; Line between the points
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E1,$11            ; Part 17 (PART17), keeping the points
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $E5                ; End

; Part 2
PART2:
  DEFB $12,$00            ; Length: 18 bytes
  DEFB $C0,$BE,$7F        ; Second point: row 190, column 127
  DEFB $C7                ; Mode bit 5 on
  DEFB $7E,$FF            ; Point: row 126, column 255
  DEFB $7F,$00            ; Point: row 127, column 0
  DEFB $E0,$01            ; Part 1 (PART1)
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E5                ; End

; Part 3
PART3:
  DEFB $42,$00            ; Length: 66 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $B5,$15            ; Point: row 181, column 21
  DEFB $0B,$FE            ; Point: row 11, column 254
  DEFB $05,$FC            ; Point: row 5, column 252
  DEFB $02,$FB            ; Point: row 2, column 251
  DEFB $BF,$FA            ; Point: row 191, column 250
  DEFB $BB,$FC            ; Point: row 187, column 252
  DEFB $01,$04            ; Point: row 1, column 4
  DEFB $C4                ; Mode bit 2 off
  DEFB $04,$02            ; Point: row 4, column 2
  DEFB $BA,$01            ; Point: row 186, column 1
  DEFB $C0,$04,$04        ; Second point: row 4, column 4
  DEFB $BE,$01            ; Point: row 190, column 1
  DEFB $C0,$00,$02        ; Second point: row 0, column 2
  DEFB $BF,$02            ; Point: row 191, column 2
  DEFB $C0,$00,$01        ; Second point: row 0, column 1
  DEFB $00,$01            ; Point: row 0, column 1
  DEFB $C0,$BE,$03        ; Second point: row 190, column 3
  DEFB $BE,$03            ; Point: row 190, column 3
  DEFB $C0,$00,$02        ; Second point: row 0, column 2
  DEFB $BF,$02            ; Point: row 191, column 2
  DEFB $C0,$BE,$01        ; Second point: row 190, column 1
  DEFB $00,$01            ; Point: row 0, column 1
  DEFB $C0,$BB,$FB        ; Second point: row 187, column 251
  DEFB $03,$FD            ; Point: row 3, column 253
  DEFB $C0,$BB,$08        ; Second point: row 187, column 8
  DEFB $BE,$04            ; Point: row 190, column 4
  DEFB $E5                ; End

; Part 4
PART4:
  DEFB $1C,$00            ; Length: 28 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $28,$00            ; Point: row 40, column 0
  DEFB $0B,$17            ; Point: row 11, column 23
  DEFB $98,$00            ; Point: row 152, column 0
  DEFB $BF,$FD            ; Point: row 191, column 253
  DEFB $24,$00            ; Point: row 36, column 0
  DEFB $B8,$F0            ; Point: row 184, column 240
  DEFB $9C,$00            ; Point: row 156, column 0
  DEFB $08,$0E            ; Point: row 8, column 14
  DEFB $C4                ; Mode bit 2 off
  DEFB $00,$02            ; Point: row 0, column 2
  DEFB $22,$FE            ; Point: row 34, column 254
  DEFB $E5                ; End

; Part 5
PART5:
  DEFB $0A,$00            ; Length: 10 bytes
  DEFB $E0,$04            ; Part 4 (PART4)
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $B5,$FA            ; Point: row 181, column 250
  DEFB $F1                ; Fill with texture 11 (TEXTURE11)
  DEFB $E5                ; End

; Part 6
PART6:
  DEFB $21,$00            ; Length: 33 bytes
  DEFB $E0,$04            ; Part 4 (PART4)
  DEFB $C0,$15,$FB        ; Second point: row 21, column 251
  DEFB $B0,$F3            ; Point: row 176, column 243
  DEFB $04,$00            ; Point: row 4, column 0
  DEFB $C0,$B1,$01        ; Second point: row 177, column 1
  DEFB $AD,$FF            ; Point: row 173, column 255
  DEFB $04,$00            ; Point: row 4, column 0
  DEFB $C0,$0C,$03        ; Second point: row 12, column 3
  DEFB $07,$0B            ; Point: row 7, column 11
  DEFB $C3                ; Mode bit 2 on
  DEFB $04,$FE            ; Point: row 4, column 254
  DEFB $BB,$01            ; Point: row 187, column 1
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $01,$02            ; Point: row 1, column 2
  DEFB $F1                ; Fill with texture 11 (TEXTURE11)
  DEFB $E5                ; End

; Part 7
PART7:
  DEFB $3E,$00            ; Length: 62 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $BC,$F8            ; Point: row 188, column 248
  DEFB $1C,$00            ; Point: row 28, column 0
  DEFB $05,$09            ; Point: row 5, column 9
  DEFB $A3,$00            ; Point: row 163, column 0
  DEFB $04,$F9            ; Point: row 4, column 249
  DEFB $11,$00            ; Point: row 17, column 0
  DEFB $C4                ; Mode bit 2 off
  DEFB $07,$07            ; Point: row 7, column 7
  DEFB $B7,$F7            ; Point: row 183, column 247
  DEFB $C0,$AF,$FF        ; Second point: row 175, column 255
  DEFB $AD,$00            ; Point: row 173, column 0
  DEFB $C3                ; Mode bit 2 on
  DEFB $C0,$AE,$F9        ; Second point: row 174, column 249
  DEFB $BD,$FA            ; Point: row 189, column 250
  DEFB $02,$02            ; Point: row 2, column 2
  DEFB $14,$00            ; Point: row 20, column 0
  DEFB $BE,$FD            ; Point: row 190, column 253
  DEFB $0D,$00            ; Point: row 13, column 0
  DEFB $0B,$16            ; Point: row 11, column 22
  DEFB $B3,$00            ; Point: row 179, column 0
  DEFB $BE,$FE            ; Point: row 190, column 254
  DEFB $AB,$00            ; Point: row 171, column 0
  DEFB $00,$02            ; Point: row 0, column 2
  DEFB $B6,$00            ; Point: row 182, column 0
  DEFB $B6,$EB            ; Point: row 182, column 235
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $06,$07            ; Point: row 6, column 7
  DEFB $E7                ; Fill with texture 1 (TEXTURE1)
  DEFB $E5                ; End

; Part 8
PART8:
  DEFB $4F,$00            ; Length: 79 bytes
  DEFB $CB                ; Mode bit 0 on
  DEFB $C0,$80,$7F        ; Second point: row 128, column 127
  DEFB $C7                ; Mode bit 5 on
  DEFB $75,$94            ; Point: row 117, column 148
  DEFB $8C,$7F            ; Point: row 140, column 127
  DEFB $6D,$5A            ; Point: row 109, column 90
  DEFB $CC                ; Mode bit 0 off
  DEFB $C8                ; Mode bit 5 off
  DEFB $5F,$67            ; Point: row 95, column 103
  DEFB $C3                ; Mode bit 2 on
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$05            ; Repeat what follows 5 times
  DEFB $C8                ; Mode bit 5 off
  DEFB $12,$F1            ; Point: row 18, column 241
  DEFB $C7                ; Mode bit 5 on
  DEFB $03,$07            ; Point: row 3, column 7
  DEFB $B4,$18            ; Point: row 180, column 24
  DEFB $BD,$F9            ; Point: row 189, column 249
  DEFB $BC,$00            ; Point: row 188, column 0
  DEFB $0C,$E8            ; Point: row 12, column 232
  DEFB $04,$00            ; Point: row 4, column 0
  DEFB $B4,$17            ; Point: row 180, column 23
  DEFB $D6                ; End of the repeat
  DEFB $03,$08            ; Point: row 3, column 8
  DEFB $B4,$00            ; Point: row 180, column 0
  DEFB $AD,$DA            ; Point: row 173, column 218
  DEFB $C8                ; Mode bit 5 off
  DEFB $10,$13            ; Point: row 16, column 19
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $E4,$04            ; Objects follow
  DEFB $0A,$03,$8C,$36,$96 ; Object: type 10; +12 value 3, along 140, top 54,
                           ; across 150
  DEFB $0A,$03,$92,$38,$96 ; Object: type 10; +12 value 3, along 146, top 56,
                           ; across 150
  DEFB $0A,$03,$98,$3C,$96 ; Object: type 10; +12 value 3, along 152, top 60,
                           ; across 150
  DEFB $0A,$03,$9E,$3E,$96 ; Object: type 10; +12 value 3, along 158, top 62,
                           ; across 150
  DEFB $0A,$03,$A6,$42,$96 ; Object: type 10; +12 value 3, along 166, top 66,
                           ; across 150
  DEFB $E5                ; End

; Part 9 (no room draws it)
PART9:
  DEFB $03,$00            ; Length: 3 bytes
  DEFB $E5                ; End

; Part 10
PART10:
  DEFB $2A,$00            ; Length: 42 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $2C,$00            ; Point: row 44, column 0
  DEFB $06,$02            ; Point: row 6, column 2
  DEFB $03,$05            ; Point: row 3, column 5
  DEFB $BF,$08            ; Point: row 191, column 8
  DEFB $B9,$0C            ; Point: row 185, column 12
  DEFB $B9,$05            ; Point: row 185, column 5
  DEFB $B8,$01            ; Point: row 184, column 1
  DEFB $8F,$00            ; Point: row 143, column 0
  DEFB $0B,$00            ; Point: row 11, column 0
  DEFB $0C,$E7            ; Point: row 12, column 231
  DEFB $C4                ; Mode bit 2 off
  DEFB $BC,$F8            ; Point: row 188, column 248
  DEFB $34,$08            ; Point: row 52, column 8
  DEFB $C0,$B9,$0F        ; Second point: row 185, column 15
  DEFB $BB,$0F            ; Point: row 187, column 15
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $B1,$EF            ; Point: row 177, column 239
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E5                ; End

; Part 11 (no room draws it)
PART11:
  DEFB $2E,$00            ; Length: 46 bytes
  DEFB $E0,$0A            ; Part 10 (PART10)
  DEFB $C7                ; Mode bit 5 on
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$AC,$15        ; Second point: row 172, column 21
  DEFB $90,$1A            ; Point: row 144, column 26
  DEFB $BE,$0F            ; Point: row 190, column 15
  DEFB $50,$F9            ; Point: row 80, column 249
  DEFB $CF                ; Second point to the first
  DEFB $04,$08            ; Point: row 4, column 8
  DEFB $CF                ; Second point to the first
  DEFB $6D,$00            ; Point: row 109, column 0
  DEFB $6B,$D0            ; Point: row 107, column 208
  DEFB $CF                ; Second point to the first
  DEFB $BC,$F7            ; Point: row 188, column 247
  DEFB $CF                ; Second point to the first
  DEFB $A7,$31            ; Point: row 167, column 49
  DEFB $87,$CF            ; Point: row 135, column 207
  DEFB $CF                ; Second point to the first
  DEFB $BC,$07            ; Point: row 188, column 7
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $0C,$30            ; Point: row 12, column 48
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $26,$E5            ; Point: row 38, column 229
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $18,$00            ; Point: row 24, column 0
  DEFB $E7                ; Fill with texture 1 (TEXTURE1)
  DEFB $E5                ; End

; Part 12 (no room draws it)
PART12:
  DEFB $15,$00            ; Length: 21 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $1B,$05            ; Point: row 27, column 5
  DEFB $08,$06            ; Point: row 8, column 6
  DEFB $C0,$08,$06        ; Second point: row 8, column 6
  DEFB $B8,$FE            ; Point: row 184, column 254
  DEFB $C0,$B1,$14        ; Second point: row 177, column 20
  DEFB $04,$17            ; Point: row 4, column 23
  DEFB $E5                ; End

; Part 13
PART13:
  DEFB $2D,$00            ; Length: 45 bytes
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $C7                ; Mode bit 5 on
  DEFB $BF,$FD            ; Point: row 191, column 253
  DEFB $C0,$1B,$4A        ; Second point: row 27, column 74
  DEFB $76,$FF            ; Point: row 118, column 255
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C4                ; Mode bit 2 off
  DEFB $25,$61            ; Point: row 37, column 97
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BC,$08            ; Point: row 188, column 8
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $00,$FE            ; Point: row 0, column 254
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F3                ; Fill with texture 13 (TEXTURE13)
  DEFB $E4,$04            ; Objects follow
  DEFB $E7                ; Patch 2
  DEFB $33,$80,$6E,$64,$AC ; Object: type 51; +12 value 128, along 110, top
                           ; 100, across 172
  DEFB $35,$00,$6E,$5A,$AA ; Object: type 53; +12 value 0, along 110, top 90,
                           ; across 170
  DEFB $E5                ; End

; Part 14
PART14:
  DEFB $13,$00            ; Length: 19 bytes
  DEFB $86,$8A            ; Point: row 134, column 138
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $6E,$A5            ; Point: row 110, column 165
  DEFB $E1,$03            ; Part 3 (PART3), keeping the points
  DEFB $B6,$5F            ; Point: row 182, column 95
  DEFB $E1,$03            ; Part 3 (PART3), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E5                ; End

; Part 15
PART15:
  DEFB $28,$00            ; Length: 40 bytes
  DEFB $BF,$5F            ; Point: row 191, column 95
  DEFB $CF                ; Second point to the first
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $71,$60            ; Point: row 113, column 96
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $11,$5E            ; Point: row 17, column 94
  DEFB $40,$BC            ; Point: row 64, column 188
  DEFB $C4                ; Mode bit 2 off
  DEFB $70,$60            ; Point: row 112, column 96
  DEFB $BF,$BC            ; Point: row 191, column 188
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $C4                ; Mode bit 2 off
  DEFB $14,$64            ; Point: row 20, column 100
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $BF,$67            ; Point: row 191, column 103
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $E8                ; Patch 3
  DEFB $E5                ; End

; Part 16
PART16:
  DEFB $13,$00            ; Length: 19 bytes
  DEFB $E4,$00            ; $E4 $00: clean copy cleared; lines go into it
  DEFB $C0,$9B,$B7        ; Second point: row 155, column 183
  DEFB $C7                ; Mode bit 5 on
  DEFB $77,$FF            ; Point: row 119, column 255
  DEFB $BF,$B5            ; Point: row 191, column 181
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FD            ; Point: row 191, column 253
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E4,$01            ; $E4 $01: lines onto the screen again
  DEFB $E5                ; End

; Part 17
PART17:
  DEFB $36,$00            ; Length: 54 bytes
  DEFB $C7                ; Mode bit 5 on
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $C3                ; Mode bit 2 on
  DEFB $2F,$05            ; Point: row 47, column 5
  DEFB $2E,$08            ; Point: row 46, column 8
  DEFB $2C,$06            ; Point: row 44, column 6
  DEFB $24,$07            ; Point: row 36, column 7
  DEFB $21,$09            ; Point: row 33, column 9
  DEFB $1A,$08            ; Point: row 26, column 8
  DEFB $0E,$0C            ; Point: row 14, column 12
  DEFB $08,$0A            ; Point: row 8, column 10
  DEFB $05,$06            ; Point: row 5, column 6
  DEFB $07,$02            ; Point: row 7, column 2
  DEFB $11,$01            ; Point: row 17, column 1
  DEFB $0D,$0C            ; Point: row 13, column 12
  DEFB $C0,$05,$07        ; Second point: row 5, column 7
  DEFB $01,$63            ; Point: row 1, column 99
  DEFB $05,$67            ; Point: row 5, column 103
  DEFB $0D,$66            ; Point: row 13, column 102
  DEFB $00,$80            ; Point: row 0, column 128
  DEFB $C8                ; Mode bit 5 off
  DEFB $00,$00            ; Point: row 0, column 0
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $09,$08            ; Point: row 9, column 8
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $0D,$66            ; Point: row 13, column 102
  DEFB $C7                ; Mode bit 5 on
  DEFB $E5                ; End

; Part 18
PART18:
  DEFB $07,$00            ; Length: 7 bytes
  DEFB $E0,$0D            ; Part 13 (PART13)
  DEFB $E0,$10            ; Part 16 (PART16)
  DEFB $E5                ; End

; Part 19
PART19:
  DEFB $2A,$00            ; Length: 42 bytes
  DEFB $C0,$BF,$00        ; Second point: row 191, column 0
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $40,$FF            ; Point: row 64, column 255
  DEFB $C0,$BF,$BA        ; Second point: row 191, column 186
  DEFB $9D,$FF            ; Point: row 157, column 255
  DEFB $C0,$BF,$B1        ; Second point: row 191, column 177
  DEFB $98,$FF            ; Point: row 152, column 255
  DEFB $C0,$00,$7F        ; Second point: row 0, column 127
  DEFB $3F,$00            ; Point: row 63, column 0
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $E1,$19            ; Part 25 (PART25), keeping the points
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $FB                ; Fill with texture 21 (TEXTURE21)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $50,$FF            ; Point: row 80, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E4,$04            ; Objects follow
  DEFB $E6                ; Patch 1
  DEFB $E5                ; End

; Part 20
PART20:
  DEFB $22,$00            ; Length: 34 bytes
  DEFB $E4,$05,$00,$00,$14 ; $E4 $05: origin 0, 0, 20
  DEFB $E0,$38            ; Part 56 (PART56)
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $C7                ; Mode bit 5 on
  DEFB $00,$80            ; Point: row 0, column 128
  DEFB $C0,$BF,$3F        ; Second point: row 191, column 63
  DEFB $5F,$FF            ; Point: row 95, column 255
  DEFB $E1,$11            ; Part 17 (PART17), keeping the points
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $C0,$60,$3F        ; Second point: row 96, column 63
  DEFB $00,$FE            ; Point: row 0, column 254
  DEFB $E4,$04            ; Objects follow
  DEFB $E9                ; Patch 4
  DEFB $E5                ; End

; Part 21
PART21:
  DEFB $CD,$00            ; Length: 205 bytes
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $23,$63            ; Point: row 35, column 99
  DEFB $C0,$8A,$29        ; Second point: row 138, column 41
  DEFB $55,$29            ; Point: row 85, column 41
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $19,$4F            ; Point: row 25, column 79
  DEFB $41,$9E            ; Point: row 65, column 158
  DEFB $97,$9E            ; Point: row 151, column 158
  DEFB $BE,$4F            ; Point: row 190, column 79
  DEFB $AB,$29            ; Point: row 171, column 41
  DEFB $83,$29            ; Point: row 131, column 41
  DEFB $7B,$37            ; Point: row 123, column 55
  DEFB $C0,$4F,$84        ; Second point: row 79, column 132
  DEFB $42,$9D            ; Point: row 66, column 157
  DEFB $C0,$8F,$60        ; Second point: row 143, column 96
  DEFB $98,$4F            ; Point: row 152, column 79
  DEFB $BE,$4F            ; Point: row 190, column 79
  DEFB $C0,$97,$4F        ; Second point: row 151, column 79
  DEFB $83,$29            ; Point: row 131, column 41
  DEFB $C0,$3D,$59        ; Second point: row 61, column 89
  DEFB $55,$28            ; Point: row 85, column 40
  DEFB $C4                ; Mode bit 2 off
  DEFB $C0,$7B,$37        ; Second point: row 123, column 55
  DEFB $D0                ; Swap the points
  DEFB $C0,$8F,$60        ; Second point: row 143, column 96
  DEFB $D2                ; Line between the points
  DEFB $C1                ; Mode bit 4 on
  DEFB $C5                ; Mode bit 3 on
  DEFB $D5,$0C            ; Repeat what follows 12 times
  DEFB $BD,$FF            ; Point: row 189, column 255
  DEFB $BE,$04            ; Point: row 190, column 4
  DEFB $D6                ; End of the repeat
  DEFB $BD,$FF            ; Point: row 189, column 255
  DEFB $C0,$28,$B4        ; Second point: row 40, column 180
  DEFB $D0                ; Swap the points
  DEFB $C0,$3A,$E0        ; Second point: row 58, column 224
  DEFB $D2                ; Line between the points
  DEFB $D5,$0B            ; Repeat what follows 11 times
  DEFB $14,$28            ; Point: row 20, column 40
  DEFB $A7,$DB            ; Point: row 167, column 219
  DEFB $D6                ; End of the repeat
  DEFB $14,$28            ; Point: row 20, column 40
  DEFB $C0,$27,$B4        ; Second point: row 39, column 180
  DEFB $D0                ; Swap the points
  DEFB $C0,$24,$B6        ; Second point: row 36, column 182
  DEFB $D2                ; Line between the points
  DEFB $D5,$0C            ; Repeat what follows 12 times
  DEFB $13,$28            ; Point: row 19, column 40
  DEFB $A8,$DB            ; Point: row 168, column 219
  DEFB $D6                ; End of the repeat
  DEFB $13,$28            ; Point: row 19, column 40
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BD,$F9            ; Point: row 189, column 249
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $D5,$0C            ; Repeat what follows 12 times
  DEFB $05,$FD            ; Point: row 5, column 253
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $90,$3C            ; Point: row 144, column 60
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $90,$64            ; Point: row 144, column 100
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $00,$FF            ; Point: row 0, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $3C,$3A            ; Point: row 60, column 58
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $8A,$3A            ; Point: row 138, column 58
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $64,$41            ; Point: row 100, column 65
  DEFB $F4                ; Fill with texture 14 (TEXTURE14)
  DEFB $78,$34            ; Point: row 120, column 52
  DEFB $F4                ; Fill with texture 14 (TEXTURE14)
  DEFB $E4,$04            ; Objects follow
  DEFB $EB                ; Patch 6
  DEFB $0A,$02,$5A,$36,$80 ; Object: type 10; +12 value 2, along 90, top 54,
                           ; across 128
  DEFB $0A,$02,$5A,$3A,$83 ; Object: type 10; +12 value 2, along 90, top 58,
                           ; across 131
  DEFB $0A,$02,$5A,$3E,$86 ; Object: type 10; +12 value 2, along 90, top 62,
                           ; across 134
  DEFB $0A,$02,$5A,$42,$89 ; Object: type 10; +12 value 2, along 90, top 66,
                           ; across 137
  DEFB $0A,$02,$5A,$44,$8C ; Object: type 10; +12 value 2, along 90, top 68,
                           ; across 140
  DEFB $0A,$02,$5A,$48,$8F ; Object: type 10; +12 value 2, along 90, top 72,
                           ; across 143
  DEFB $0A,$02,$5A,$4C,$92 ; Object: type 10; +12 value 2, along 90, top 76,
                           ; across 146
  DEFB $0A,$02,$5A,$50,$95 ; Object: type 10; +12 value 2, along 90, top 80,
                           ; across 149
  DEFB $0A,$02,$5A,$54,$98 ; Object: type 10; +12 value 2, along 90, top 84,
                           ; across 152
  DEFB $0A,$02,$5A,$56,$9B ; Object: type 10; +12 value 2, along 90, top 86,
                           ; across 155
  DEFB $0A,$02,$5A,$5A,$9E ; Object: type 10; +12 value 2, along 90, top 90,
                           ; across 158
  DEFB $0A,$02,$5A,$5E,$A1 ; Object: type 10; +12 value 2, along 90, top 94,
                           ; across 161
  DEFB $0A,$02,$5A,$62,$A4 ; Object: type 10; +12 value 2, along 90, top 98,
                           ; across 164
  DEFB $E5                ; End

; Part 22
PART22:
  DEFB $23,$00            ; Length: 35 bytes
  DEFB $C3                ; Mode bit 2 on
  DEFB $7B,$28            ; Point: row 123, column 40
  DEFB $C7                ; Mode bit 5 on
  DEFB $71,$3B            ; Point: row 113, column 59
  DEFB $4D,$3B            ; Point: row 77, column 59
  DEFB $C0,$60,$3B        ; Second point: row 96, column 59
  DEFB $56,$28            ; Point: row 86, column 40
  DEFB $E1,$15            ; Part 21 (PART21), keeping the points
  DEFB $C7                ; Mode bit 5 on
  DEFB $CB                ; Mode bit 0 on
  DEFB $C0,$55,$28        ; Second point: row 85, column 40
  DEFB $C3                ; Mode bit 2 on
  DEFB $4C,$3B            ; Point: row 76, column 59
  DEFB $CC                ; Mode bit 0 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $64,$3A            ; Point: row 100, column 58
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $50,$3A            ; Point: row 80, column 58
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Part 23
PART23:
  DEFB $45,$00            ; Length: 69 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $B5,$EB            ; Point: row 181, column 235
  DEFB $1A,$00            ; Point: row 26, column 0
  DEFB $11,$03            ; Point: row 17, column 3
  DEFB $0B,$08            ; Point: row 11, column 8
  DEFB $BC,$07            ; Point: row 188, column 7
  DEFB $B5,$03            ; Point: row 181, column 3
  DEFB $A5,$00            ; Point: row 165, column 0
  DEFB $02,$FC            ; Point: row 2, column 252
  DEFB $1B,$00            ; Point: row 27, column 0
  DEFB $08,$FE            ; Point: row 8, column 254
  DEFB $04,$FC            ; Point: row 4, column 252
  DEFB $C0,$9A,$06        ; Second point: row 154, column 6
  DEFB $91,$F5            ; Point: row 145, column 245
  DEFB $C0,$07,$0A        ; Second point: row 7, column 10
  DEFB $0D,$02            ; Point: row 13, column 2
  DEFB $C0,$01,$0D        ; Second point: row 1, column 13
  DEFB $0B,$01            ; Point: row 11, column 1
  DEFB $C0,$01,$0D        ; Second point: row 1, column 13
  DEFB $0B,$01            ; Point: row 11, column 1
  DEFB $C0,$01,$0D        ; Second point: row 1, column 13
  DEFB $09,$04            ; Point: row 9, column 4
  DEFB $C0,$BE,$06        ; Second point: row 190, column 6
  DEFB $B3,$FC            ; Point: row 179, column 252
  DEFB $C0,$01,$0C        ; Second point: row 1, column 12
  DEFB $AE,$FC            ; Point: row 174, column 252
  DEFB $C0,$05,$10        ; Second point: row 5, column 16
  DEFB $B5,$01            ; Point: row 181, column 1
  DEFB $E5                ; End

; Part 24
PART24:
  DEFB $20,$00            ; Length: 32 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $0C,$18            ; Point: row 12, column 24
  DEFB $B5,$16            ; Point: row 181, column 22
  DEFB $B4,$E7            ; Point: row 180, column 231
  DEFB $0B,$EB            ; Point: row 11, column 235
  DEFB $C0,$BD,$05        ; Second point: row 189, column 5
  DEFB $07,$18            ; Point: row 7, column 24
  DEFB $B8,$10            ; Point: row 184, column 16
  DEFB $C0,$03,$F9        ; Second point: row 3, column 249
  DEFB $BC,$F9            ; Point: row 188, column 249
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $07,$F8            ; Point: row 7, column 248
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $E5                ; End

; Part 25
PART25:
  DEFB $12,$00            ; Length: 18 bytes
  DEFB $C0,$BC,$B6        ; Second point: row 188, column 182
  DEFB $C4                ; Mode bit 2 off
  DEFB $BF,$BA            ; Point: row 191, column 186
  DEFB $C1                ; Mode bit 4 on
  DEFB $C5                ; Mode bit 3 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $BB,$0A            ; Point: row 187, column 10
  DEFB $BA,$0B            ; Point: row 186, column 11
  DEFB $D6                ; End of the repeat
  DEFB $E5                ; End

; Part 26
PART26:
  DEFB $26,$00            ; Length: 38 bytes
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $50,$51            ; Point: row 80, column 81
  DEFB $C0,$40,$00        ; Second point: row 64, column 0
  DEFB $74,$68            ; Point: row 116, column 104
  DEFB $69,$7F            ; Point: row 105, column 127
  DEFB $34,$16            ; Point: row 52, column 22
  DEFB $3F,$01            ; Point: row 63, column 1
  DEFB $C0,$69,$7F        ; Second point: row 105, column 127
  DEFB $A7,$7F            ; Point: row 167, column 127
  DEFB $B2,$68            ; Point: row 178, column 104
  DEFB $C4                ; Mode bit 2 off
  DEFB $7E,$00            ; Point: row 126, column 0
  DEFB $75,$68            ; Point: row 117, column 104
  DEFB $C8                ; Mode bit 5 off
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E4,$04            ; Objects follow
  DEFB $EE                ; Patch 9
  DEFB $E5                ; End

; Part 27
PART27:
  DEFB $0B,$00            ; Length: 11 bytes
  DEFB $C9                ; Mode bit 6 on
  DEFB $B3,$CD            ; Point: row 179, column 205
  DEFB $E1,$03            ; Part 3 (PART3), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$0F            ; Part 15 (PART15)
  DEFB $E5                ; End

; Part 28
PART28:
  DEFB $14,$00            ; Length: 20 bytes
  DEFB $4D,$E4            ; Point: row 77, column 228
  DEFB $C9                ; Mode bit 6 on
  DEFB $E1,$06            ; Part 6 (PART6), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E0,$02            ; Part 2 (PART2)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $F6                ; Fill with texture 16 (TEXTURE16)
  DEFB $64,$FF            ; Point: row 100, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $E5                ; End

; Part 29
PART29:
  DEFB $10,$00            ; Length: 16 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $12,$04            ; Point: row 18, column 4
  DEFB $12,$FD            ; Point: row 18, column 253
  DEFB $C4                ; Mode bit 2 off
  DEFB $21,$04            ; Point: row 33, column 4
  DEFB $AA,$00            ; Point: row 170, column 0
  DEFB $E5                ; End

; Part 30
PART30:
  DEFB $16,$00            ; Length: 22 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $0C,$16            ; Point: row 12, column 22
  DEFB $05,$19            ; Point: row 5, column 25
  DEFB $12,$1B            ; Point: row 18, column 27
  DEFB $05,$0E            ; Point: row 5, column 14
  DEFB $08,$0B            ; Point: row 8, column 11
  DEFB $12,$1C            ; Point: row 18, column 28
  DEFB $0D,$27            ; Point: row 13, column 39
  DEFB $C2                ; Mode bit 4 off
  DEFB $E5                ; End

; Part 31
PART31:
  DEFB $19,$00            ; Length: 25 bytes
  DEFB $C0,$76,$00        ; Second point: row 118, column 0
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $93,$04            ; Point: row 147, column 4
  DEFB $A3,$11            ; Point: row 163, column 17
  DEFB $AA,$22            ; Point: row 170, column 34
  DEFB $AF,$36            ; Point: row 175, column 54
  DEFB $B6,$45            ; Point: row 182, column 69
  DEFB $BF,$6F            ; Point: row 191, column 111
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E5                ; End

; Part 32
PART32:
  DEFB $16,$00            ; Length: 22 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $09,$04            ; Point: row 9, column 4
  DEFB $04,$FE            ; Point: row 4, column 254
  DEFB $0F,$02            ; Point: row 15, column 2
  DEFB $C0,$0A,$0A        ; Second point: row 10, column 10
  DEFB $01,$07            ; Point: row 1, column 7
  DEFB $B2,$03            ; Point: row 178, column 3
  DEFB $11,$FE            ; Point: row 17, column 254
  DEFB $E5                ; End

; Part 33 (no room draws it)
PART33:
  DEFB $03,$00            ; Length: 3 bytes
  DEFB $E5                ; End

; Part 34
PART34:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $56,$2C            ; Point: row 86, column 44
  DEFB $E1,$04            ; Part 4 (PART4), keeping the points
  DEFB $E0,$1A            ; Part 26 (PART26)
  DEFB $64,$00            ; Point: row 100, column 0
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $AC,$6A            ; Point: row 172, column 106
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $E5                ; End

; Part 35
PART35:
  DEFB $27,$00            ; Length: 39 bytes
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $50,$20            ; Point: row 80, column 32
  DEFB $C4                ; Mode bit 2 off
  DEFB $1E,$86            ; Point: row 30, column 134
  DEFB $98,$20            ; Point: row 152, column 32
  DEFB $CF                ; Second point to the first
  DEFB $88,$00            ; Point: row 136, column 0
  DEFB $65,$86            ; Point: row 101, column 134
  DEFB $CF                ; Second point to the first
  DEFB $1E,$86            ; Point: row 30, column 134
  DEFB $CF                ; Second point to the first
  DEFB $0E,$66            ; Point: row 14, column 102
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $C8                ; Mode bit 5 off
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $EC                ; Fill with texture 6 (TEXTURE6)
  DEFB $51,$00            ; Point: row 81, column 0
  DEFB $ED                ; Fill with texture 7 (TEXTURE7)
  DEFB $E4,$04            ; Objects follow
  DEFB $EC                ; Patch 7
  DEFB $E5                ; End

; Part 36
PART36:
  DEFB $30,$00            ; Length: 48 bytes
  DEFB $E0,$11            ; Part 17 (PART17)
  DEFB $40,$00            ; Point: row 64, column 0
  DEFB $C0,$7C,$B0        ; Second point: row 124, column 176
  DEFB $6B,$D1            ; Point: row 107, column 209
  DEFB $C8                ; Mode bit 5 off
  DEFB $E4,$05,$F4,$00,$00 ; $E4 $05: origin 244, 0, 0
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$0A            ; Repeat what follows 10 times
  DEFB $E0,$33            ; Part 51 (PART51)
  DEFB $E4,$05,$0E,$00,$00 ; $E4 $05: origin 14, 0, 0
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $7D,$B0            ; Point: row 125, column 176
  DEFB $E1,$0A            ; Part 10 (PART10), keeping the points
  DEFB $BF,$FF            ; Point: row 191, column 255
  DEFB $F5                ; Fill with texture 15 (TEXTURE15)
  DEFB $43,$7D            ; Point: row 67, column 125
  DEFB $E6                ; Fill with texture 0 (TEXTURES)
  DEFB $E4,$04            ; Objects follow
  DEFB $F8                ; Patch 19
  DEFB $2F,$07,$AA,$0E,$32 ; Object: type 47; +12 value 7, along 170, top 14,
                           ; across 50
  DEFB $E5                ; End

; Part 37
PART37:
  DEFB $12,$00            ; Length: 18 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $B7,$0F            ; Point: row 183, column 15
  DEFB $BD,$15            ; Point: row 189, column 21
  DEFB $B3,$0D            ; Point: row 179, column 13
  DEFB $BA,$14            ; Point: row 186, column 20
  DEFB $B6,$12            ; Point: row 182, column 18
  DEFB $C2                ; Mode bit 4 off
  DEFB $E5                ; End

; Part 38
PART38:
  DEFB $3C,$00            ; Length: 60 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $06,$00,$32,$47,$76 ; Object: type 6; +12 value 0, along 50, top 71,
                           ; across 118
  DEFB $06,$00,$32,$52,$76 ; Object: type 6; +12 value 0, along 50, top 82,
                           ; across 118
  DEFB $06,$00,$32,$5D,$76 ; Object: type 6; +12 value 0, along 50, top 93,
                           ; across 118
  DEFB $06,$00,$32,$47,$98 ; Object: type 6; +12 value 0, along 50, top 71,
                           ; across 152
  DEFB $06,$00,$32,$52,$98 ; Object: type 6; +12 value 0, along 50, top 82,
                           ; across 152
  DEFB $06,$00,$32,$5D,$98 ; Object: type 6; +12 value 0, along 50, top 93,
                           ; across 152
  DEFB $05,$00,$32,$67,$92 ; Object: type 5; +12 value 0, along 50, top 103,
                           ; across 146
  DEFB $05,$00,$32,$67,$76 ; Object: type 5; +12 value 0, along 50, top 103,
                           ; across 118
  DEFB $05,$00,$32,$71,$84 ; Object: type 5; +12 value 0, along 50, top 113,
                           ; across 132
  DEFB $01,$00,$32,$3C,$76 ; Object: type 1; +12 value 0, along 50, top 60,
                           ; across 118
  DEFB $01,$00,$32,$3C,$98 ; Object: type 1; +12 value 0, along 50, top 60,
                           ; across 152
  DEFB $E5                ; End

; Part 39
PART39:
  DEFB $1E,$00            ; Length: 30 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $12,$00,$32,$42,$32 ; Object: type 18; +12 value 0, along 50, top 66,
                           ; across 50
  DEFB $12,$00,$40,$42,$32 ; Object: type 18; +12 value 0, along 64, top 66,
                           ; across 50
  DEFB $12,$00,$4E,$42,$32 ; Object: type 18; +12 value 0, along 78, top 66,
                           ; across 50
  DEFB $19,$00,$34,$40,$38 ; Object: type 25; +12 value 0, along 52, top 64,
                           ; across 56
  DEFB $19,$00,$50,$40,$38 ; Object: type 25; +12 value 0, along 80, top 64,
                           ; across 56
  DEFB $E5                ; End

; Part 40
PART40:
  DEFB $2D,$00            ; Length: 45 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $14,$00,$56,$42,$A2 ; Object: type 20; +12 value 0, along 86, top 66,
                           ; across 162
  DEFB $14,$00,$64,$42,$A2 ; Object: type 20; +12 value 0, along 100, top 66,
                           ; across 162
  DEFB $14,$00,$72,$42,$A2 ; Object: type 20; +12 value 0, along 114, top 66,
                           ; across 162
  DEFB $14,$00,$80,$42,$A2 ; Object: type 20; +12 value 0, along 128, top 66,
                           ; across 162
  DEFB $12,$00,$56,$44,$A2 ; Object: type 18; +12 value 0, along 86, top 68,
                           ; across 162
  DEFB $12,$00,$64,$44,$A2 ; Object: type 18; +12 value 0, along 100, top 68,
                           ; across 162
  DEFB $12,$00,$72,$44,$A2 ; Object: type 18; +12 value 0, along 114, top 68,
                           ; across 162
  DEFB $12,$00,$80,$44,$A2 ; Object: type 18; +12 value 0, along 128, top 68,
                           ; across 162
  DEFB $E5                ; End

; Part 41
PART41:
  DEFB $2D,$00            ; Length: 45 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $14,$00,$56,$42,$3E ; Object: type 20; +12 value 0, along 86, top 66,
                           ; across 62
  DEFB $14,$00,$64,$42,$3E ; Object: type 20; +12 value 0, along 100, top 66,
                           ; across 62
  DEFB $14,$00,$72,$42,$3E ; Object: type 20; +12 value 0, along 114, top 66,
                           ; across 62
  DEFB $14,$00,$80,$42,$3E ; Object: type 20; +12 value 0, along 128, top 66,
                           ; across 62
  DEFB $12,$00,$56,$44,$32 ; Object: type 18; +12 value 0, along 86, top 68,
                           ; across 50
  DEFB $12,$00,$64,$44,$32 ; Object: type 18; +12 value 0, along 100, top 68,
                           ; across 50
  DEFB $12,$00,$72,$44,$32 ; Object: type 18; +12 value 0, along 114, top 68,
                           ; across 50
  DEFB $12,$00,$80,$44,$32 ; Object: type 18; +12 value 0, along 128, top 68,
                           ; across 50
  DEFB $E5                ; End

; Part 42
PART42:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $05,$00,$50,$3C,$68 ; Object: type 5; +12 value 0, along 80, top 60,
                           ; across 104
  DEFB $05,$00,$50,$46,$68 ; Object: type 5; +12 value 0, along 80, top 70,
                           ; across 104
  DEFB $E5                ; End

; Part 43
PART43:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$04            ; Repeat what follows 4 times
  DEFB $E0,$2A            ; Part 42 (PART42)
  DEFB $E4,$05,$00,$00,$12 ; $E4 $05: origin 0, 0, 18
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $E5                ; End

; Part 44
PART44:
  DEFB $14,$00            ; Length: 20 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $26,$00,$32,$40,$32 ; Object: type 38; +12 value 0, along 50, top 64,
                           ; across 50
  DEFB $27,$00,$34,$3A,$36 ; Object: type 39; +12 value 0, along 52, top 58,
                           ; across 54
  DEFB $26,$00,$32,$40,$4E ; Object: type 38; +12 value 0, along 50, top 64,
                           ; across 78
  DEFB $E5                ; End

; Part 45
PART45:
  DEFB $0A,$00            ; Length: 10 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $02,$10,$6E,$78,$A0 ; Object: type 2; +12 value 16, along 110, top 120,
                           ; across 160
  DEFB $E5                ; End

; Part 46
PART46:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $C1                ; Mode bit 4 on
  DEFB $D5,$03            ; Repeat what follows 3 times
  DEFB $E0,$2C            ; Part 44 (PART44)
  DEFB $E4,$05,$28,$00,$00 ; $E4 $05: origin 40, 0, 0
  DEFB $D6                ; End of the repeat
  DEFB $C2                ; Mode bit 4 off
  DEFB $E5                ; End

; Part 47
PART47:
  DEFB $16,$00            ; Length: 22 bytes
  DEFB $58,$3F            ; Point: row 88, column 63
  DEFB $E1,$18            ; Part 24 (PART24), keeping the points
  DEFB $C9                ; Mode bit 6 on
  DEFB $6F,$88            ; Point: row 111, column 136
  DEFB $E1,$07            ; Part 7 (PART7), keeping the points
  DEFB $5D,$65            ; Point: row 93, column 101
  DEFB $E1,$07            ; Part 7 (PART7), keeping the points
  DEFB $CA                ; Mode bit 6 off
  DEFB $E1,$0F            ; Part 15 (PART15), keeping the points
  DEFB $64,$64            ; Point: row 100, column 100
  DEFB $F7                ; Fill with texture 17 (TEXTURE17)
  DEFB $E5                ; End

; Part 48
PART48:
  DEFB $45,$00            ; Length: 69 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C1                ; Mode bit 4 on
  DEFB $C7                ; Mode bit 5 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $05,$FC            ; Point: row 5, column 252
  DEFB $04,$FF            ; Point: row 4, column 255
  DEFB $0A,$FE            ; Point: row 10, column 254
  DEFB $0B,$00            ; Point: row 11, column 0
  DEFB $BB,$08            ; Point: row 187, column 8
  DEFB $BF,$08            ; Point: row 191, column 8
  DEFB $B2,$00            ; Point: row 178, column 0
  DEFB $BA,$FD            ; Point: row 186, column 253
  DEFB $BC,$FA            ; Point: row 188, column 250
  DEFB $1A,$00            ; Point: row 26, column 0
  DEFB $C0,$BF,$04        ; Second point: row 191, column 4
  DEFB $08,$07            ; Point: row 8, column 7
  DEFB $03,$01            ; Point: row 3, column 1
  DEFB $03,$03            ; Point: row 3, column 3
  DEFB $BA,$FE            ; Point: row 186, column 254
  DEFB $B7,$F9            ; Point: row 183, column 249
  DEFB $C0,$B1,$F8        ; Second point: row 177, column 248
  DEFB $A8,$F4            ; Point: row 168, column 244
  DEFB $C0,$03,$10        ; Second point: row 3, column 16
  DEFB $B7,$14            ; Point: row 183, column 20
  DEFB $C0,$24,$F3        ; Second point: row 36, column 243
  DEFB $2F,$F0            ; Point: row 47, column 240
  DEFB $02,$FE            ; Point: row 2, column 254
  DEFB $07,$00            ; Point: row 7, column 0
  DEFB $BA,$02            ; Point: row 186, column 2
  DEFB $BF,$00            ; Point: row 191, column 0
  DEFB $B2,$04            ; Point: row 178, column 4
  DEFB $E2                ; Keep a clean copy of the screen
  DEFB $B8,$05            ; Point: row 184, column 5
  DEFB $E9                ; Fill with texture 3 (TEXTURE3)
  DEFB $E5                ; End

; Part 49
PART49:
  DEFB $1E,$00            ; Length: 30 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $29,$00,$64,$50,$64 ; Object: type 41; +12 value 0, along 100, top 80,
                           ; across 100
  DEFB $29,$00,$64,$50,$72 ; Object: type 41; +12 value 0, along 100, top 80,
                           ; across 114
  DEFB $29,$00,$72,$50,$72 ; Object: type 41; +12 value 0, along 114, top 80,
                           ; across 114
  DEFB $29,$00,$72,$50,$64 ; Object: type 41; +12 value 0, along 114, top 80,
                           ; across 100
  DEFB $12,$00,$64,$52,$64 ; Object: type 18; +12 value 0, along 100, top 82,
                           ; across 100
  DEFB $E5                ; End

; Part 50
PART50:
  DEFB $0A,$00            ; Length: 10 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $27,$00,$32,$38,$98 ; Object: type 39; +12 value 0, along 50, top 56,
                           ; across 152
  DEFB $E5                ; End

; Part 51
PART51:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $12,$00,$36,$46,$64 ; Object: type 18; +12 value 0, along 54, top 70,
                           ; across 100
  DEFB $12,$00,$36,$46,$72 ; Object: type 18; +12 value 0, along 54, top 70,
                           ; across 114
  DEFB $E5                ; End

; Part 52 (no room draws it)
PART52:
  DEFB $1A,$00            ; Length: 26 bytes
  DEFB $CF                ; Second point to the first
  DEFB $C7                ; Mode bit 5 on
  DEFB $C1                ; Mode bit 4 on
  DEFB $C3                ; Mode bit 2 on
  DEFB $1E,$00            ; Point: row 30, column 0
  DEFB $0A,$14            ; Point: row 10, column 20
  DEFB $A1,$00            ; Point: row 161, column 0
  DEFB $B6,$EC            ; Point: row 182, column 236
  DEFB $C0,$05,$03        ; Second point: row 5, column 3
  DEFB $1D,$03            ; Point: row 29, column 3
  DEFB $07,$0E            ; Point: row 7, column 14
  DEFB $A8,$00            ; Point: row 168, column 0
  DEFB $B9,$F2            ; Point: row 185, column 242
  DEFB $E5                ; End

; Part 53
PART53:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $05,$00,$8A,$3C,$66 ; Object: type 5; +12 value 0, along 138, top 60,
                           ; across 102
  DEFB $05,$00,$8A,$3C,$78 ; Object: type 5; +12 value 0, along 138, top 60,
                           ; across 120
  DEFB $E5                ; End

; Part 54
PART54:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $10,$00,$50,$3E,$8C ; Object: type 16; +12 value 0, along 80, top 62,
                           ; across 140
  DEFB $10,$00,$50,$3E,$50 ; Object: type 16; +12 value 0, along 80, top 62,
                           ; across 80
  DEFB $E5                ; End

; Part 55
PART55:
  DEFB $32,$00            ; Length: 50 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $13,$00,$6E,$42,$5A ; Object: type 19; +12 value 0, along 110, top 66,
                           ; across 90
  DEFB $13,$00,$6E,$42,$68 ; Object: type 19; +12 value 0, along 110, top 66,
                           ; across 104
  DEFB $13,$00,$6E,$42,$76 ; Object: type 19; +12 value 0, along 110, top 66,
                           ; across 118
  DEFB $13,$00,$7C,$42,$5A ; Object: type 19; +12 value 0, along 124, top 66,
                           ; across 90
  DEFB $13,$00,$7C,$42,$68 ; Object: type 19; +12 value 0, along 124, top 66,
                           ; across 104
  DEFB $13,$00,$7C,$42,$76 ; Object: type 19; +12 value 0, along 124, top 66,
                           ; across 118
  DEFB $12,$00,$6E,$44,$68 ; Object: type 18; +12 value 0, along 110, top 68,
                           ; across 104
  DEFB $12,$00,$6E,$44,$76 ; Object: type 18; +12 value 0, along 110, top 68,
                           ; across 118
  DEFB $14,$00,$6E,$42,$58 ; Object: type 20; +12 value 0, along 110, top 66,
                           ; across 88
  DEFB $E5                ; End

; Part 56
PART56:
  DEFB $0F,$00            ; Length: 15 bytes
  DEFB $E4,$04            ; Objects follow
  DEFB $33,$80,$6E,$64,$70 ; Object: type 51; +12 value 128, along 110, top
                           ; 100, across 112
  DEFB $36,$00,$6E,$5A,$6E ; Object: type 54; +12 value 0, along 110, top 90,
                           ; across 110
  DEFB $E5                ; End

; Bytes after the parts
;
; 53 bytes between the last part (PART56) and the sprites, not identified. No
; room or part reaches them, and no address of any of them appears anywhere in
; the game.
;
; The first nine parse as drawing commands (two points, a mode bit, the second
; point, a point and a line), but what follows does not end with $E5. The last
; eighteen are six groups of a byte and a word, and every word is an address
; inside this block (four of them different, 4 to 20 bytes apart), so the block
; was made for this address; it may be a table left from an earlier version.
BYTES_AFTER_PARTS:
  DEFB $36,$02,$C5,$34,$02,$CF,$32,$01 ; Nine bytes that parse as drawing
  DEFB $D2                             ; commands; 26 more; six groups of a
  DEFB $6E,$00,$60,$63,$28,$26,$24,$22 ; byte and an address in this block
  DEFB $66,$20,$38,$36,$34,$32,$66,$2E ;
  DEFB $2C,$2A,$6A,$62,$64,$30,$68,$62 ;
  DEFB $64,$30                         ;
  DEFB $38,$D6,$7C                     ;
  DEFB $08,$D6,$7C                     ;
  DEFB $38,$DE,$7C                     ;
  DEFB $34,$E2,$7C                     ;
  DEFB $44,$E6,$7C                     ;
  DEFB $44,$EA,$7C                     ;

; Sprite, 40 by 34 (the template for type 0)
SPRITE7D00:
  DEFB $00,$03,$80,$00,$00 ; Image, the top row first
  DEFB $00,$0C,$40,$00,$00 ;
  DEFB $00,$30,$18,$00,$00 ;
  DEFB $00,$D0,$06,$00,$00 ;
  DEFB $01,$04,$01,$80,$00 ;
  DEFB $03,$01,$00,$20,$00 ;
  DEFB $0C,$80,$40,$18,$00 ;
  DEFB $10,$20,$00,$04,$00 ;
  DEFB $20,$0C,$04,$01,$80 ;
  DEFB $30,$02,$00,$00,$60 ;
  DEFB $26,$00,$00,$40,$18 ;
  DEFB $19,$80,$40,$00,$04 ;
  DEFB $06,$40,$00,$08,$1C ;
  DEFB $05,$98,$04,$02,$3C ;
  DEFB $01,$E4,$01,$01,$F8 ;
  DEFB $05,$D9,$80,$43,$F0 ;
  DEFB $01,$C6,$60,$0F,$70 ;
  DEFB $05,$C0,$90,$16,$F0 ;
  DEFB $05,$C0,$E6,$37,$70 ;
  DEFB $05,$C0,$B9,$F8,$F0 ;
  DEFB $05,$C0,$36,$E1,$70 ;
  DEFB $01,$C0,$05,$C0,$F0 ;
  DEFB $05,$C0,$05,$C1,$70 ;
  DEFB $05,$C0,$05,$C0,$F0 ;
  DEFB $05,$C0,$05,$C1,$70 ;
  DEFB $01,$80,$05,$C0,$F0 ;
  DEFB $00,$00,$05,$C1,$70 ;
  DEFB $00,$00,$05,$C0,$60 ;
  DEFB $00,$00,$05,$C0,$00 ;
  DEFB $00,$00,$05,$C0,$00 ;
  DEFB $00,$00,$01,$C0,$00 ;
  DEFB $00,$00,$05,$C0,$00 ;
  DEFB $00,$00,$05,$C0,$00 ;
  DEFB $00,$00,$01,$80,$00 ;
  DEFB $FF,$FC,$7F,$FF,$FF ; Mask: a bit set where the background shows through
  DEFB $FF,$F0,$1F,$FF,$FF ;
  DEFB $FF,$C0,$07,$FF,$FF ;
  DEFB $FF,$00,$01,$FF,$FF ;
  DEFB $FE,$00,$00,$7F,$FF ;
  DEFB $FC,$00,$00,$1F,$FF ;
  DEFB $F0,$00,$00,$07,$FF ;
  DEFB $E0,$00,$00,$01,$FF ;
  DEFB $C0,$00,$00,$00,$7F ;
  DEFB $C0,$00,$00,$00,$1F ;
  DEFB $C0,$00,$00,$00,$07 ;
  DEFB $E0,$00,$00,$00,$03 ;
  DEFB $F8,$00,$00,$00,$03 ;
  DEFB $F8,$00,$00,$00,$03 ;
  DEFB $F8,$00,$00,$00,$07 ;
  DEFB $F8,$20,$00,$00,$0F ;
  DEFB $F8,$38,$00,$00,$0F ;
  DEFB $F8,$3E,$00,$00,$0F ;
  DEFB $F8,$3F,$00,$00,$0F ;
  DEFB $F8,$3F,$00,$06,$0F ;
  DEFB $F8,$3F,$C8,$1E,$0F ;
  DEFB $F8,$3F,$F8,$3E,$0F ;
  DEFB $F8,$3F,$F8,$3E,$0F ;
  DEFB $F8,$3F,$F8,$3E,$0F ;
  DEFB $F8,$3F,$F8,$3E,$0F ;
  DEFB $FE,$7F,$F8,$3E,$0F ;
  DEFB $FF,$FF,$F8,$3E,$0F ;
  DEFB $FF,$FF,$F8,$3F,$9F ;
  DEFB $FF,$FF,$F8,$3F,$FF ;
  DEFB $FF,$FF,$F8,$3F,$FF ;
  DEFB $FF,$FF,$F8,$3F,$FF ;
  DEFB $FF,$FF,$F8,$3F,$FF ;
  DEFB $FF,$FF,$F8,$3F,$FF ;
  DEFB $FF,$FF,$FE,$7F,$FF ;

; Sprite, 16 by 13 (the template for type 3)
SPRITE7E54:
  DEFB $06,$20            ; Image, the top row first
  DEFB $10,$08            ;
  DEFB $00,$04            ;
  DEFB $20,$04            ;
  DEFB $38,$1C            ;
  DEFB $1F,$F8            ;
  DEFB $07,$E8            ;
  DEFB $12,$48            ;
  DEFB $15,$A8            ;
  DEFB $24,$34            ;
  DEFB $28,$14            ;
  DEFB $28,$14            ;
  DEFB $10,$08            ;
  DEFB $F8,$1F            ; Mask: a bit set where the background shows through
  DEFB $E0,$07            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$07            ;
  DEFB $F0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E2,$47            ;
  DEFB $C3,$C3            ;
  DEFB $C7,$E3            ;
  DEFB $C7,$E3            ;
  DEFB $EF,$F7            ;

; Sprite, 24 by 21 (the template for type 2)
SPRITE7E88:
  DEFB $00,$38,$00        ; Image, the top row first
  DEFB $01,$83,$00        ;
  DEFB $02,$00,$C0        ;
  DEFB $04,$40,$20        ;
  DEFB $08,$00,$10        ;
  DEFB $09,$00,$10        ;
  DEFB $12,$00,$08        ;
  DEFB $12,$00,$08        ;
  DEFB $24,$00,$08        ;
  DEFB $24,$00,$04        ;
  DEFB $20,$00,$04        ;
  DEFB $20,$00,$04        ;
  DEFB $10,$00,$04        ;
  DEFB $10,$00,$08        ;
  DEFB $10,$00,$48        ;
  DEFB $08,$00,$50        ;
  DEFB $08,$00,$90        ;
  DEFB $04,$00,$20        ;
  DEFB $03,$00,$40        ;
  DEFB $00,$80,$80        ;
  DEFB $00,$3A,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$00,$FF        ;
  DEFB $FC,$0A,$3F        ;
  DEFB $F8,$14,$1F        ;
  DEFB $F0,$0A,$8F        ;
  DEFB $F0,$15,$0F        ;
  DEFB $E0,$2A,$A7        ;
  DEFB $E1,$55,$47        ;
  DEFB $CA,$AA,$A3        ;
  DEFB $C5,$55,$53        ;
  DEFB $CA,$AA,$A3        ;
  DEFB $C5,$55,$53        ;
  DEFB $C2,$AA,$A3        ;
  DEFB $E5,$55,$07        ;
  DEFB $E2,$AA,$27        ;
  DEFB $F5,$54,$0F        ;
  DEFB $F2,$AA,$0F        ;
  DEFB $F8,$55,$1F        ;
  DEFB $FC,$2A,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$C1,$FF        ;

; Sprite, 24 by 14 (the template for type 4)
SPRITE7F06:
  DEFB $00,$18,$00        ; Image, the top row first
  DEFB $00,$AE,$00        ;
  DEFB $01,$59,$80        ;
  DEFB $0A,$E0,$60        ;
  DEFB $15,$80,$38        ;
  DEFB $2A,$00,$1C        ;
  DEFB $3C,$0E,$18        ;
  DEFB $2B,$07,$A8        ;
  DEFB $18,$C1,$CC        ;
  DEFB $0C,$3F,$58        ;
  DEFB $03,$0C,$F0        ;
  DEFB $00,$C9,$C0        ;
  DEFB $00,$3B,$00        ;
  DEFB $00,$0C,$00        ;
  DEFB $FF,$C7,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$FF        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $E0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$C0,$FF        ;
  DEFB $FF,$F3,$FF        ;

; Sprite, 32 by 24 (the template for type 5)
SPRITE7F5A:
  DEFB $00,$18,$00,$00    ; Image, the top row first
  DEFB $00,$66,$00,$00    ;
  DEFB $01,$81,$80,$00    ;
  DEFB $06,$00,$60,$00    ;
  DEFB $18,$00,$18,$00    ;
  DEFB $20,$00,$06,$00    ;
  DEFB $38,$00,$01,$80    ;
  DEFB $26,$00,$00,$60    ;
  DEFB $21,$80,$00,$18    ;
  DEFB $20,$60,$00,$04    ;
  DEFB $20,$18,$00,$1C    ;
  DEFB $20,$06,$00,$6C    ;
  DEFB $20,$01,$81,$D4    ;
  DEFB $20,$00,$66,$AC    ;
  DEFB $20,$00,$1D,$54    ;
  DEFB $18,$00,$0A,$AC    ;
  DEFB $06,$00,$0D,$54    ;
  DEFB $01,$80,$0A,$AC    ;
  DEFB $00,$60,$0D,$54    ;
  DEFB $00,$18,$0A,$B8    ;
  DEFB $00,$06,$0D,$60    ;
  DEFB $00,$01,$8B,$80    ;
  DEFB $00,$00,$6E,$00    ;
  DEFB $00,$00,$18,$00    ;
  DEFB $FF,$E7,$FF,$FF    ; Mask: a bit set where the background shows through
  DEFB $FF,$81,$FF,$FF    ;
  DEFB $FE,$00,$7F,$FF    ;
  DEFB $F8,$00,$1F,$FF    ;
  DEFB $E0,$00,$07,$FF    ;
  DEFB $C0,$00,$01,$FF    ;
  DEFB $C0,$00,$00,$7F    ;
  DEFB $C0,$00,$00,$1F    ;
  DEFB $C0,$00,$00,$07    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $C0,$00,$00,$03    ;
  DEFB $E0,$00,$00,$03    ;
  DEFB $F8,$00,$00,$03    ;
  DEFB $FE,$00,$00,$03    ;
  DEFB $FF,$80,$00,$03    ;
  DEFB $FF,$E0,$00,$07    ;
  DEFB $FF,$F8,$00,$1F    ;
  DEFB $FF,$FE,$00,$7F    ;
  DEFB $FF,$FF,$81,$FF    ;
  DEFB $FF,$FF,$E7,$FF    ;

; Sprite, 24 by 20 (the template for type 1)
SPRITE801A:
  DEFB $00,$18,$00        ; Image, the top row first
  DEFB $00,$66,$00        ;
  DEFB $01,$81,$80        ;
  DEFB $06,$00,$60        ;
  DEFB $18,$00,$18        ;
  DEFB $20,$00,$04        ;
  DEFB $38,$00,$1C        ;
  DEFB $26,$00,$6C        ;
  DEFB $21,$81,$D4        ;
  DEFB $20,$66,$AC        ;
  DEFB $20,$1D,$54        ;
  DEFB $20,$0A,$AC        ;
  DEFB $20,$0D,$54        ;
  DEFB $20,$0A,$AC        ;
  DEFB $20,$0D,$54        ;
  DEFB $18,$0A,$B8        ;
  DEFB $06,$0D,$60        ;
  DEFB $01,$8B,$80        ;
  DEFB $00,$6E,$00        ;
  DEFB $00,$18,$00        ;
  DEFB $FF,$E7,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$81,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $E0,$00,$07        ;
  DEFB $F8,$00,$1F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FF,$81,$FF        ;
  DEFB $FF,$E7,$FF        ;

; Sprite, 16 by 17 (the template for type 6)
SPRITE8092:
  DEFB $07,$C0            ; Image, the top row first
  DEFB $10,$10            ;
  DEFB $20,$08            ;
  DEFB $20,$08            ;
  DEFB $30,$18            ;
  DEFB $2E,$E8            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $29,$28            ;
  DEFB $19,$30            ;
  DEFB $07,$C0            ;
  DEFB $F8,$3F            ; Mask: a bit set where the background shows through
  DEFB $E0,$0F            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $F8,$3F            ;

; Sprite, 16 by 10 (the template for type 29)
SPRITE80D6:
  DEFB $00,$80            ; Image, the top row first
  DEFB $01,$40            ;
  DEFB $03,$60            ;
  DEFB $01,$C0            ;
  DEFB $02,$60            ;
  DEFB $06,$30            ;
  DEFB $04,$F0            ;
  DEFB $05,$70            ;
  DEFB $02,$E0            ;
  DEFB $01,$C0            ;
  DEFB $FE,$3F            ; Mask: a bit set where the background shows through
  DEFB $FE,$3F            ;
  DEFB $FC,$1F            ;
  DEFB $FC,$1F            ;
  DEFB $F8,$0F            ;
  DEFB $F8,$0F            ;
  DEFB $F8,$0F            ;
  DEFB $F8,$0F            ;
  DEFB $F8,$0F            ;
  DEFB $FC,$1F            ;

; Sprite, 16 by 9 (the template for type 30)
SPRITE80FE:
  DEFB $3C,$00            ; Image, the top row first
  DEFB $53,$00            ;
  DEFB $4C,$C0            ;
  DEFB $48,$30            ;
  DEFB $30,$C8            ;
  DEFB $0D,$04            ;
  DEFB $03,$1C            ;
  DEFB $00,$F8            ;
  DEFB $00,$00            ;
  DEFB $C1,$FF            ; Mask: a bit set where the background shows through
  DEFB $80,$7F            ;
  DEFB $80,$1F            ;
  DEFB $80,$0F            ;
  DEFB $80,$07            ;
  DEFB $C0,$03            ;
  DEFB $F0,$03            ;
  DEFB $FC,$07            ;
  DEFB $FF,$0F            ;

; Sprite, 16 by 10 (the template for type 31)
SPRITE8122:
  DEFB $03,$00            ; Image, the top row first
  DEFB $04,$C0            ;
  DEFB $0F,$60            ;
  DEFB $38,$50            ;
  DEFB $24,$30            ;
  DEFB $12,$18            ;
  DEFB $09,$2C            ;
  DEFB $09,$1C            ;
  DEFB $06,$78            ;
  DEFB $01,$E0            ;
  DEFB $F8,$7F            ; Mask: a bit set where the background shows through
  DEFB $F0,$1F            ;
  DEFB $E0,$0F            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$03            ;
  DEFB $F0,$03            ;
  DEFB $FC,$0F            ;

; Sprite, 24 by 13 (the template for type 32)
SPRITE814A:
  DEFB $00,$10,$00        ; Image, the top row first
  DEFB $00,$68,$00        ;
  DEFB $01,$88,$00        ;
  DEFB $06,$0C,$00        ;
  DEFB $0C,$23,$60        ;
  DEFB $0A,$80,$90        ;
  DEFB $0F,$03,$10        ;
  DEFB $06,$0C,$30        ;
  DEFB $01,$90,$E0        ;
  DEFB $00,$6B,$80        ;
  DEFB $00,$3E,$00        ;
  DEFB $00,$0C,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$8F,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$07,$FF        ;
  DEFB $F8,$07,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $E0,$00,$9F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$07        ;
  DEFB $F0,$00,$07        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$FF        ;
  DEFB $FF,$C1,$FF        ;
  DEFB $FF,$F3,$FF        ;

; Sprite, 24 by 29 (the template for type 8)
SPRITE8198:
  DEFB $00,$7E,$00        ; Image, the top row first
  DEFB $03,$81,$80        ;
  DEFB $04,$7E,$40        ;
  DEFB $09,$81,$A0        ;
  DEFB $0C,$00,$60        ;
  DEFB $13,$00,$F0        ;
  DEFB $12,$DB,$D0        ;
  DEFB $1A,$22,$B0        ;
  DEFB $1E,$20,$F0        ;
  DEFB $0F,$A3,$E8        ;
  DEFB $27,$FF,$C8        ;
  DEFB $21,$FE,$38        ;
  DEFB $24,$00,$28        ;
  DEFB $24,$21,$78        ;
  DEFB $24,$29,$A8        ;
  DEFB $34,$2D,$78        ;
  DEFB $34,$29,$28        ;
  DEFB $3C,$21,$78        ;
  DEFB $1F,$01,$F8        ;
  DEFB $2F,$FF,$F0        ;
  DEFB $27,$FF,$D8        ;
  DEFB $0A,$FD,$68        ;
  DEFB $12,$23,$B0        ;
  DEFB $1A,$21,$70        ;
  DEFB $1A,$21,$30        ;
  DEFB $08,$25,$60        ;
  DEFB $09,$22,$A0        ;
  DEFB $03,$27,$C0        ;
  DEFB $00,$7E,$00        ;
  DEFB $FF,$81,$FF        ; Mask: a bit set where the background shows through
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FF,$81,$FF        ;

; Sprite, 16 by 16 (the template for type 9)
SPRITE8246:
  DEFB $03,$C0            ; Image, the top row first
  DEFB $05,$60            ;
  DEFB $04,$90            ;
  DEFB $02,$68            ;
  DEFB $02,$68            ;
  DEFB $02,$50            ;
  DEFB $04,$20            ;
  DEFB $18,$10            ;
  DEFB $30,$28            ;
  DEFB $30,$1C            ;
  DEFB $2C,$3C            ;
  DEFB $35,$FC            ;
  DEFB $2A,$BC            ;
  DEFB $15,$78            ;
  DEFB $1A,$F8            ;
  DEFB $07,$E0            ;
  DEFB $FC,$3F            ; Mask: a bit set where the background shows through
  DEFB $F8,$1F            ;
  DEFB $F8,$0F            ;
  DEFB $FC,$07            ;
  DEFB $FC,$07            ;
  DEFB $FC,$0F            ;
  DEFB $F8,$1F            ;
  DEFB $E0,$0F            ;
  DEFB $C0,$07            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $F8,$1F            ;

; Sprite, 16 by 5 (the template for type 14)
SPRITE8286:
  DEFB $18,$00            ; Image, the top row first
  DEFB $3E,$00            ;
  DEFB $19,$E0            ;
  DEFB $00,$90            ;
  DEFB $00,$60            ;
  DEFB $C3,$FF            ; Mask: a bit set where the background shows through
  DEFB $C1,$FF            ;
  DEFB $C0,$0F            ;
  DEFB $FE,$0F            ;
  DEFB $FF,$0F            ;

; Sprite, 16 by 10 (the template for type 17)
SPRITE829A:
  DEFB $03,$F0            ; Image, the top row first
  DEFB $0C,$08            ;
  DEFB $03,$30            ;
  DEFB $01,$FC            ;
  DEFB $06,$30            ;
  DEFB $0A,$58            ;
  DEFB $10,$3C            ;
  DEFB $20,$5C            ;
  DEFB $20,$38            ;
  DEFB $0A,$E0            ;
  DEFB $FC,$0F            ; Mask: a bit set where the background shows through
  DEFB $F0,$07            ;
  DEFB $FC,$0F            ;
  DEFB $FE,$03            ;
  DEFB $F8,$0F            ;
  DEFB $F0,$07            ;
  DEFB $E0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$07            ;
  DEFB $F0,$1F            ;

; Sprite, 24 by 26 (the template for type 7)
SPRITE82C2:
  DEFB $07,$00,$00        ; Image, the top row first
  DEFB $18,$C0,$00        ;
  DEFB $08,$30,$00        ;
  DEFB $14,$0C,$00        ;
  DEFB $17,$83,$00        ;
  DEFB $12,$60,$C0        ;
  DEFB $1B,$F8,$30        ;
  DEFB $1A,$2E,$18        ;
  DEFB $18,$06,$E8        ;
  DEFB $12,$0C,$D8        ;
  DEFB $1B,$00,$E8        ;
  DEFB $13,$39,$58        ;
  DEFB $1A,$71,$68        ;
  DEFB $10,$51,$58        ;
  DEFB $12,$62,$68        ;
  DEFB $14,$82,$58        ;
  DEFB $12,$02,$68        ;
  DEFB $13,$B2,$58        ;
  DEFB $0C,$C6,$68        ;
  DEFB $07,$04,$58        ;
  DEFB $01,$F8,$68        ;
  DEFB $00,$60,$58        ;
  DEFB $00,$18,$68        ;
  DEFB $00,$06,$58        ;
  DEFB $00,$01,$F0        ;
  DEFB $00,$00,$40        ;
  DEFB $FC,$7F,$FF        ; Mask: a bit set where the background shows through
  DEFB $F0,$1F,$FF        ;
  DEFB $F0,$07,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$07        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $FF,$00,$03        ;
  DEFB $FF,$C0,$03        ;
  DEFB $FF,$F0,$03        ;
  DEFB $FF,$FC,$03        ;
  DEFB $FF,$FF,$07        ;
  DEFB $FF,$FF,$DF        ;

; Sprite, 24 by 41 (the template for type 22)
SPRITE835E:
  DEFB $02,$00,$00        ; Image, the top row first
  DEFB $05,$00,$00        ;
  DEFB $01,$00,$00        ;
  DEFB $06,$00,$00        ;
  DEFB $12,$0F,$00        ;
  DEFB $3A,$20,$80        ;
  DEFB $3E,$40,$C0        ;
  DEFB $32,$3F,$40        ;
  DEFB $32,$40,$C0        ;
  DEFB $32,$3C,$C0        ;
  DEFB $36,$00,$C0        ;
  DEFB $2A,$40,$C0        ;
  DEFB $2A,$43,$80        ;
  DEFB $12,$7F,$80        ;
  DEFB $12,$B6,$60        ;
  DEFB $02,$8B,$B0        ;
  DEFB $02,$90,$60        ;
  DEFB $02,$10,$90        ;
  DEFB $02,$90,$90        ;
  DEFB $02,$90,$90        ;
  DEFB $02,$A8,$90        ;
  DEFB $02,$68,$B8        ;
  DEFB $02,$D7,$E8        ;
  DEFB $02,$55,$90        ;
  DEFB $04,$EA,$90        ;
  DEFB $05,$41,$90        ;
  DEFB $04,$41,$90        ;
  DEFB $02,$48,$80        ;
  DEFB $02,$49,$20        ;
  DEFB $02,$79,$E0        ;
  DEFB $02,$5F,$A0        ;
  DEFB $02,$ED,$80        ;
  DEFB $02,$4E,$80        ;
  DEFB $02,$48,$80        ;
  DEFB $02,$08,$80        ;
  DEFB $02,$4A,$80        ;
  DEFB $02,$59,$80        ;
  DEFB $00,$8B,$00        ;
  DEFB $01,$11,$00        ;
  DEFB $00,$E2,$00        ;
  DEFB $00,$1C,$00        ;
  DEFB $FD,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $F8,$FF,$FF        ;
  DEFB $F8,$FF,$FF        ;
  DEFB $F8,$FF,$FF        ;
  DEFB $ED,$E0,$FF        ;
  DEFB $C5,$C0,$7F        ;
  DEFB $C1,$80,$3F        ;
  DEFB $C1,$80,$3F        ;
  DEFB $C1,$80,$3F        ;
  DEFB $C1,$80,$3F        ;
  DEFB $C1,$80,$3F        ;
  DEFB $C5,$80,$3F        ;
  DEFB $C5,$80,$7F        ;
  DEFB $ED,$80,$7F        ;
  DEFB $ED,$00,$1F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$0F        ;
  DEFB $FD,$00,$07        ;
  DEFB $FD,$00,$07        ;
  DEFB $FD,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F8,$80,$0F        ;
  DEFB $FD,$80,$1F        ;
  DEFB $FD,$80,$1F        ;
  DEFB $FD,$80,$1F        ;
  DEFB $FD,$80,$5F        ;
  DEFB $FD,$00,$7F        ;
  DEFB $FD,$80,$7F        ;
  DEFB $FD,$80,$7F        ;
  DEFB $FD,$80,$7F        ;
  DEFB $FD,$80,$7F        ;
  DEFB $FD,$80,$7F        ;
  DEFB $FF,$00,$FF        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FF,$11,$FF        ;
  DEFB $FF,$E3,$FF        ;

; Sprite, 24 by 21 (the template for type 23)
SPRITE8454:
  DEFB $03,$31,$80        ; Image, the top row first
  DEFB $0C,$B6,$60        ;
  DEFB $11,$78,$08        ;
  DEFB $14,$56,$44        ;
  DEFB $29,$9D,$34        ;
  DEFB $22,$99,$C0        ;
  DEFB $26,$FE,$00        ;
  DEFB $2F,$58,$40        ;
  DEFB $30,$3D,$20        ;
  DEFB $00,$1C,$80        ;
  DEFB $00,$1A,$20        ;
  DEFB $00,$7F,$20        ;
  DEFB $01,$D8,$80        ;
  DEFB $01,$FF,$40        ;
  DEFB $00,$AA,$80        ;
  DEFB $00,$D5,$80        ;
  DEFB $00,$AA,$80        ;
  DEFB $00,$55,$00        ;
  DEFB $00,$6B,$00        ;
  DEFB $00,$55,$00        ;
  DEFB $00,$1C,$00        ;
  DEFB $FC,$CE,$7F        ; Mask: a bit set where the background shows through
  DEFB $F0,$48,$1F        ;
  DEFB $E0,$00,$07        ;
  DEFB $E0,$20,$03        ;
  DEFB $C0,$62,$03        ;
  DEFB $C0,$66,$3F        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C0,$80,$3F        ;
  DEFB $CF,$C0,$1F        ;
  DEFB $FF,$E0,$1F        ;
  DEFB $FF,$E4,$1F        ;
  DEFB $FF,$80,$1F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$80,$FF        ;
  DEFB $FF,$80,$FF        ;
  DEFB $FF,$80,$FF        ;
  DEFB $FF,$C1,$FF        ;

; Sprite, 40 by 18 (the template for type 18, type 24)
SPRITE84D2:
  DEFB $00,$00,$10,$00,$00 ; Image, the top row first
  DEFB $00,$00,$6C,$00,$00 ;
  DEFB $00,$01,$83,$00,$00 ;
  DEFB $00,$06,$00,$C0,$00 ;
  DEFB $00,$18,$00,$30,$00 ;
  DEFB $00,$60,$00,$0C,$00 ;
  DEFB $01,$80,$00,$03,$00 ;
  DEFB $06,$00,$00,$00,$C0 ;
  DEFB $0C,$00,$00,$00,$E0 ;
  DEFB $0B,$00,$00,$03,$E0 ;
  DEFB $06,$C0,$00,$0F,$80 ;
  DEFB $01,$B0,$00,$3E,$00 ;
  DEFB $00,$6C,$00,$F8,$00 ;
  DEFB $00,$1B,$03,$E0,$00 ;
  DEFB $00,$06,$CF,$80,$00 ;
  DEFB $00,$01,$BE,$00,$00 ;
  DEFB $00,$00,$78,$00,$00 ;
  DEFB $00,$00,$10,$00,$00 ;
  DEFB $FF,$FF,$EF,$FF,$FF ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$83,$FF,$FF ;
  DEFB $FF,$FE,$00,$FF,$FF ;
  DEFB $FF,$F8,$00,$3F,$FF ;
  DEFB $FF,$E0,$00,$0F,$FF ;
  DEFB $FF,$80,$00,$03,$FF ;
  DEFB $FE,$00,$00,$00,$FF ;
  DEFB $F8,$00,$00,$00,$3F ;
  DEFB $F0,$00,$00,$00,$1F ;
  DEFB $F0,$00,$00,$00,$1F ;
  DEFB $F8,$00,$00,$00,$7F ;
  DEFB $FE,$00,$00,$01,$FF ;
  DEFB $FF,$80,$00,$07,$FF ;
  DEFB $FF,$E0,$00,$1F,$FF ;
  DEFB $FF,$F8,$00,$7F,$FF ;
  DEFB $FF,$FE,$01,$FF,$FF ;
  DEFB $FF,$FF,$87,$FF,$FF ;
  DEFB $FF,$FF,$EF,$FF,$FF ;

; Sprite, 24 by 24 (the template for type 19)
SPRITE8586:
  DEFB $0E,$00,$00        ; Image, the top row first
  DEFB $1D,$80,$00        ;
  DEFB $13,$60,$00        ;
  DEFB $10,$D8,$00        ;
  DEFB $10,$36,$00        ;
  DEFB $10,$0D,$80        ;
  DEFB $10,$03,$60        ;
  DEFB $10,$00,$D0        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $10,$00,$30        ;
  DEFB $0C,$00,$30        ;
  DEFB $03,$00,$30        ;
  DEFB $00,$C0,$30        ;
  DEFB $00,$30,$30        ;
  DEFB $00,$0C,$30        ;
  DEFB $00,$03,$30        ;
  DEFB $00,$00,$F0        ;
  DEFB $00,$00,$20        ;
  DEFB $F1,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $E0,$7F,$FF        ;
  DEFB $E0,$1F,$FF        ;
  DEFB $E0,$07,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FF,$00,$0F        ;
  DEFB $FF,$C0,$0F        ;
  DEFB $FF,$F0,$0F        ;
  DEFB $FF,$FC,$0F        ;
  DEFB $FF,$FF,$0F        ;
  DEFB $FF,$FF,$DF        ;

; Sprite, 24 by 24 (the template for type 20, type 46)
SPRITE8616:
  DEFB $00,$00,$E0        ; Image, the top row first
  DEFB $00,$03,$70        ;
  DEFB $00,$0D,$90        ;
  DEFB $00,$36,$10        ;
  DEFB $00,$D8,$10        ;
  DEFB $03,$60,$10        ;
  DEFB $0D,$80,$10        ;
  DEFB $16,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$10        ;
  DEFB $18,$00,$60        ;
  DEFB $18,$01,$80        ;
  DEFB $18,$06,$00        ;
  DEFB $18,$18,$00        ;
  DEFB $18,$60,$00        ;
  DEFB $19,$80,$00        ;
  DEFB $1E,$00,$00        ;
  DEFB $08,$00,$00        ;
  DEFB $FF,$FF,$1F        ; Mask: a bit set where the background shows through
  DEFB $FF,$FC,$0F        ;
  DEFB $FF,$F0,$0F        ;
  DEFB $FF,$C0,$0F        ;
  DEFB $FF,$00,$0F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$01,$FF        ;
  DEFB $E0,$07,$FF        ;
  DEFB $E0,$1F,$FF        ;
  DEFB $E0,$7F,$FF        ;
  DEFB $E1,$FF,$FF        ;
  DEFB $F7,$FF,$FF        ;

; Sprite, 24 by 24 (the template for type 49)
SPRITE86A6:
  DEFB $01,$C0,$C0        ; Image, the top row first
  DEFB $02,$21,$30        ;
  DEFB $04,$9A,$08        ;
  DEFB $04,$44,$84        ;
  DEFB $03,$23,$18        ;
  DEFB $0D,$24,$30        ;
  DEFB $11,$3E,$F8        ;
  DEFB $20,$D3,$64        ;
  DEFB $1D,$09,$02        ;
  DEFB $20,$89,$92        ;
  DEFB $46,$80,$89        ;
  DEFB $48,$84,$A1        ;
  DEFB $90,$41,$F2        ;
  DEFB $A6,$C1,$9A        ;
  DEFB $89,$E3,$0C        ;
  DEFB $70,$94,$88        ;
  DEFB $11,$08,$48        ;
  DEFB $21,$0C,$08        ;
  DEFB $21,$1F,$10        ;
  DEFB $18,$39,$20        ;
  DEFB $04,$33,$A0        ;
  DEFB $02,$77,$C0        ;
  DEFB $01,$FF,$80        ;
  DEFB $00,$76,$00        ;
  DEFB $FE,$3F,$3F        ; Mask: a bit set where the background shows through
  DEFB $FC,$1E,$0F        ;
  DEFB $F8,$04,$07        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$07        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $E0,$00,$01        ;
  DEFB $C0,$00,$01        ;
  DEFB $80,$00,$00        ;
  DEFB $80,$00,$00        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$03        ;
  DEFB $80,$00,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FF,$89,$FF        ;

; Bytes between two sprites
;
; 36 bytes between the sprites at SPRITE86A6 and SPRITE875A that no object
; showed in the sessions and no template or table points at. They are not a
; sprite at any width that divides them (8, 16, 24 or 48 pixels): at every
; width the image's bits fall where the mask says the background shows. Drawn
; 16 pixels wide they are diagonal stripes. Not identified.
BYTES_AFTER_TYPE49:
  DEFB $3F,$FF,$00,$00,$00,$FF,$FF,$C0
  DEFB $00,$03,$FF,$FF,$F0,$00,$0F,$FF
  DEFB $FF,$FC,$00,$3F,$FF,$FF,$FF,$00
  DEFB $FF,$FF,$FF,$FF,$C3,$FF,$FF,$FF
  DEFB $FF,$F7,$FF,$FF

; Sprite, 24 by 17 (the template for type 16)
SPRITE875A:
  DEFB $00,$FE,$00        ; Image, the top row first
  DEFB $03,$00,$C0        ;
  DEFB $08,$00,$10        ;
  DEFB $10,$00,$08        ;
  DEFB $10,$00,$08        ;
  DEFB $18,$00,$18        ;
  DEFB $0E,$00,$70        ;
  DEFB $07,$FF,$E0        ;
  DEFB $01,$FF,$80        ;
  DEFB $00,$18,$00        ;
  DEFB $00,$6E,$00        ;
  DEFB $00,$5F,$00        ;
  DEFB $00,$DB,$00        ;
  DEFB $01,$91,$80        ;
  DEFB $00,$20,$C0        ;
  DEFB $00,$20,$00        ;
  DEFB $00,$60,$00        ;
  DEFB $FE,$00,$7F        ; Mask: a bit set where the background shows through
  DEFB $F8,$00,$1F        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $E0,$00,$07        ;
  DEFB $F0,$00,$0F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FF,$C3,$FF        ;
  DEFB $FF,$00,$FF        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$04,$3F        ;
  DEFB $FF,$8E,$1F        ;
  DEFB $FF,$8F,$3F        ;
  DEFB $FF,$0F,$FF        ;

; Sprite, 24 by 8 (the template for type 21)
SPRITE87C0:
  DEFB $06,$18,$00        ; Image, the top row first
  DEFB $07,$BC,$00        ;
  DEFB $01,$F0,$00        ;
  DEFB $01,$F0,$00        ;
  DEFB $0F,$BC,$00        ;
  DEFB $06,$0F,$00        ;
  DEFB $00,$03,$C0        ;
  DEFB $00,$00,$C0        ;
  DEFB $F9,$E7,$FF        ; Mask: a bit set where the background shows through
  DEFB $F8,$43,$FF        ;
  DEFB $FE,$0F,$FF        ;
  DEFB $FE,$0F,$FF        ;
  DEFB $F0,$43,$FF        ;
  DEFB $F9,$F0,$FF        ;
  DEFB $FF,$FC,$3F        ;
  DEFB $FF,$FF,$3F        ;

; Sprite, 16 by 24 (the template for type 25)
SPRITE87F0:
  DEFB $00,$00            ; Image, the top row first
  DEFB $00,$C0            ;
  DEFB $03,$30            ;
  DEFB $0C,$0C            ;
  DEFB $10,$02            ;
  DEFB $1C,$0E            ;
  DEFB $13,$3E            ;
  DEFB $0C,$FC            ;
  DEFB $03,$F0            ;
  DEFB $07,$B8            ;
  DEFB $06,$F8            ;
  DEFB $06,$38            ;
  DEFB $04,$18            ;
  DEFB $02,$10            ;
  DEFB $01,$60            ;
  DEFB $02,$30            ;
  DEFB $09,$7C            ;
  DEFB $10,$E6            ;
  DEFB $1C,$0E            ;
  DEFB $13,$3E            ;
  DEFB $0C,$FC            ;
  DEFB $03,$70            ;
  DEFB $00,$C0            ;
  DEFB $00,$00            ;
  DEFB $FE,$7F            ; Mask: a bit set where the background shows through
  DEFB $F8,$1F            ;
  DEFB $E0,$07            ;
  DEFB $C0,$03            ;
  DEFB $80,$01            ;
  DEFB $80,$01            ;
  DEFB $80,$01            ;
  DEFB $C0,$03            ;
  DEFB $F0,$0F            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $E0,$07            ;
  DEFB $F0,$07            ;
  DEFB $F8,$1F            ;
  DEFB $E0,$07            ;
  DEFB $C0,$03            ;
  DEFB $80,$01            ;
  DEFB $80,$01            ;
  DEFB $80,$01            ;
  DEFB $C0,$03            ;
  DEFB $E0,$07            ;
  DEFB $F8,$1F            ;
  DEFB $FE,$7F            ;

; Sprite, 40 by 26 (the template for type $52)
SPRITE8850:
  DEFB $00,$00,$0C,$00,$00 ; Image, the top row first
  DEFB $00,$00,$3F,$00,$00 ;
  DEFB $00,$00,$FD,$C0,$00 ;
  DEFB $00,$03,$FE,$B0,$00 ;
  DEFB $00,$0F,$FD,$5C,$00 ;
  DEFB $00,$3F,$FE,$AB,$00 ;
  DEFB $00,$FF,$F3,$55,$C0 ;
  DEFB $03,$FF,$C0,$EA,$B0 ;
  DEFB $0F,$FF,$00,$35,$5C ;
  DEFB $3F,$FC,$00,$0E,$AA ;
  DEFB $FF,$F0,$00,$03,$57 ;
  DEFB $FF,$C0,$00,$00,$FD ;
  DEFB $BF,$00,$00,$00,$31 ;
  DEFB $8C,$00,$00,$00,$C1 ;
  DEFB $83,$00,$00,$03,$01 ;
  DEFB $80,$C0,$00,$0C,$01 ;
  DEFB $C0,$30,$00,$30,$06 ;
  DEFB $30,$0C,$00,$C0,$18 ;
  DEFB $0C,$03,$03,$00,$60 ;
  DEFB $03,$00,$CC,$01,$80 ;
  DEFB $00,$C0,$30,$06,$00 ;
  DEFB $00,$30,$10,$18,$00 ;
  DEFB $00,$0C,$10,$60,$00 ;
  DEFB $00,$03,$11,$80,$00 ;
  DEFB $00,$00,$D6,$00,$00 ;
  DEFB $00,$00,$38,$00,$00 ;
  DEFB $FF,$FF,$F3,$FF,$FF ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$C0,$FF,$FF ;
  DEFB $FF,$FF,$00,$3F,$FF ;
  DEFB $FF,$EC,$00,$1F,$FF ;
  DEFB $FF,$F0,$00,$03,$FF ;
  DEFB $FF,$C0,$00,$00,$FF ;
  DEFB $FF,$00,$0C,$00,$3F ;
  DEFB $FC,$00,$3F,$00,$0F ;
  DEFB $F0,$00,$FF,$C0,$03 ;
  DEFB $C0,$03,$FF,$F0,$01 ;
  DEFB $00,$0F,$FF,$FC,$00 ;
  DEFB $00,$3F,$FF,$FF,$00 ;
  DEFB $00,$FF,$FF,$FF,$C0 ;
  DEFB $03,$FF,$FF,$FF,$00 ;
  DEFB $00,$FF,$FF,$FC,$00 ;
  DEFB $00,$3F,$FF,$F0,$00 ;
  DEFB $00,$0F,$FF,$C0,$01 ;
  DEFB $C0,$03,$FF,$00,$07 ;
  DEFB $F0,$00,$FC,$00,$1F ;
  DEFB $FC,$00,$30,$00,$7F ;
  DEFB $FF,$00,$00,$01,$FF ;
  DEFB $FF,$C0,$00,$07,$FF ;
  DEFB $FF,$F0,$00,$1F,$FF ;
  DEFB $FF,$FC,$00,$7F,$FF ;
  DEFB $FF,$FF,$01,$FF,$FF ;
  DEFB $FF,$FF,$C7,$FF,$FF ;

; Sprite, 24 by 51 (the template for type $47)
SPRITE8954:
  DEFB $E0,$00,$00        ; Image, the top row first
  DEFB $F8,$00,$00        ;
  DEFB $9E,$00,$00        ;
  DEFB $87,$80,$00        ;
  DEFB $81,$E0,$00        ;
  DEFB $B0,$78,$00        ;
  DEFB $BC,$1E,$00        ;
  DEFB $B3,$07,$80        ;
  DEFB $B0,$C1,$E0        ;
  DEFB $B0,$30,$78        ;
  DEFB $B0,$0C,$1E        ;
  DEFB $B0,$03,$07        ;
  DEFB $B0,$00,$C3        ;
  DEFB $B0,$00,$33        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $B0,$00,$0B        ;
  DEFB $F0,$00,$0B        ;
  DEFB $30,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0B        ;
  DEFB $00,$00,$0F        ;
  DEFB $00,$00,$03        ;
  DEFB $1F,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $07,$FF,$FF        ;
  DEFB $01,$FF,$FF        ;
  DEFB $00,$7F,$FF        ;
  DEFB $00,$1F,$FF        ;
  DEFB $00,$07,$FF        ;
  DEFB $00,$01,$FF        ;
  DEFB $0C,$00,$7F        ;
  DEFB $0F,$00,$1F        ;
  DEFB $0F,$C0,$07        ;
  DEFB $0F,$F0,$01        ;
  DEFB $0F,$FC,$00        ;
  DEFB $0F,$FF,$00        ;
  DEFB $0F,$FF,$C0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $CF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F0        ;
  DEFB $FF,$FF,$F8        ;
  DEFB $FF,$FF,$FC        ;

; Sprite, 24 by 51 (the template for type $49)
SPRITE8A86:
  DEFB $00,$00,$07        ; Image, the top row first
  DEFB $00,$00,$1F        ;
  DEFB $00,$00,$79        ;
  DEFB $00,$01,$E1        ;
  DEFB $00,$07,$81        ;
  DEFB $00,$1E,$0D        ;
  DEFB $00,$78,$3D        ;
  DEFB $01,$E0,$CD        ;
  DEFB $07,$83,$0D        ;
  DEFB $1E,$0C,$0D        ;
  DEFB $78,$30,$0D        ;
  DEFB $E0,$C0,$0D        ;
  DEFB $C3,$00,$0D        ;
  DEFB $CC,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0D        ;
  DEFB $D0,$00,$0F        ;
  DEFB $D0,$00,$0C        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $D0,$00,$00        ;
  DEFB $F0,$00,$00        ;
  DEFB $C0,$00,$00        ;
  DEFB $FF,$FF,$F8        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$E0        ;
  DEFB $FF,$FF,$80        ;
  DEFB $FF,$FE,$00        ;
  DEFB $FF,$F8,$00        ;
  DEFB $FF,$E0,$00        ;
  DEFB $FF,$80,$00        ;
  DEFB $FE,$00,$30        ;
  DEFB $F8,$00,$F0        ;
  DEFB $E0,$03,$F0        ;
  DEFB $80,$0F,$F0        ;
  DEFB $00,$3F,$F0        ;
  DEFB $00,$FF,$F0        ;
  DEFB $03,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F0        ;
  DEFB $0F,$FF,$F3        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $0F,$FF,$FF        ;
  DEFB $1F,$FF,$FF        ;
  DEFB $3F,$FF,$FF        ;

; Sprite, 24 by 38 (the template for type 13)
SPRITE8BB8:
  DEFB $00,$C0,$00        ; Image, the top row first
  DEFB $05,$70,$00        ;
  DEFB $02,$EC,$00        ;
  DEFB $17,$58,$00        ;
  DEFB $0E,$E4,$00        ;
  DEFB $0D,$83,$C0        ;
  DEFB $16,$09,$E0        ;
  DEFB $0A,$43,$E0        ;
  DEFB $0C,$03,$C0        ;
  DEFB $12,$27,$C0        ;
  DEFB $11,$1F,$80        ;
  DEFB $18,$87,$80        ;
  DEFB $14,$7F,$00        ;
  DEFB $2A,$0F,$40        ;
  DEFB $34,$0E,$20        ;
  DEFB $2A,$9E,$20        ;
  DEFB $15,$5C,$40        ;
  DEFB $0A,$8D,$00        ;
  DEFB $0D,$05,$80        ;
  DEFB $0F,$8F,$80        ;
  DEFB $0F,$DF,$80        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FF,$00        ;
  DEFB $1F,$FF,$00        ;
  DEFB $1F,$FF,$80        ;
  DEFB $1F,$FF,$80        ;
  DEFB $1F,$FF,$C0        ;
  DEFB $1F,$CF,$C0        ;
  DEFB $0B,$CE,$80        ;
  DEFB $08,$88,$80        ;
  DEFB $11,$04,$60        ;
  DEFB $11,$04,$10        ;
  DEFB $08,$83,$20        ;
  DEFB $0A,$80,$C0        ;
  DEFB $07,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FA,$0F,$FF        ; Mask: a bit set where the background shows through
  DEFB $F0,$03,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $C0,$03,$FF        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $C0,$70,$0F        ;
  DEFB $C0,$70,$0F        ;
  DEFB $E0,$38,$0F        ;
  DEFB $E0,$3C,$1F        ;
  DEFB $F0,$3F,$3F        ;
  DEFB $F8,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 38
;
; Seen on an object in the build's sessions.
SPRITE8C9C:
  DEFB $00,$60,$00        ; Image, the top row first
  DEFB $00,$B8,$00        ;
  DEFB $03,$75,$00        ;
  DEFB $03,$AE,$00        ;
  DEFB $0F,$72,$00        ;
  DEFB $06,$C1,$00        ;
  DEFB $0B,$04,$80        ;
  DEFB $05,$23,$00        ;
  DEFB $06,$00,$98        ;
  DEFB $09,$11,$BC        ;
  DEFB $10,$8E,$7C        ;
  DEFB $1C,$42,$FC        ;
  DEFB $34,$3D,$F8        ;
  DEFB $2A,$03,$F0        ;
  DEFB $36,$07,$C0        ;
  DEFB $2A,$0F,$A0        ;
  DEFB $35,$1F,$20        ;
  DEFB $1A,$BC,$C0        ;
  DEFB $05,$71,$C0        ;
  DEFB $1A,$2F,$C0        ;
  DEFB $1C,$1F,$C0        ;
  DEFB $1E,$7F,$C0        ;
  DEFB $1F,$FF,$C0        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FF,$80        ;
  DEFB $07,$F7,$80        ;
  DEFB $07,$F7,$80        ;
  DEFB $07,$EF,$00        ;
  DEFB $07,$EF,$00        ;
  DEFB $07,$F2,$00        ;
  DEFB $03,$E1,$00        ;
  DEFB $02,$D0,$80        ;
  DEFB $04,$4A,$80        ;
  DEFB $04,$27,$00        ;
  DEFB $02,$10,$00        ;
  DEFB $01,$50,$00        ;
  DEFB $00,$E0,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$07,$FF        ; Mask: a bit set where the background shows through
  DEFB $FC,$02,$FF        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $E0,$00,$FF        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $F0,$00,$67        ;
  DEFB $F0,$00,$03        ;
  DEFB $E0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F8,$00,$FF        ;
  DEFB $FC,$07,$FF        ;
  DEFB $FE,$0F,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 38
;
; Seen on an object in the build's sessions.
SPRITE8D80:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$30,$00        ;
  DEFB $00,$5C,$00        ;
  DEFB $00,$BA,$00        ;
  DEFB $03,$D7,$80        ;
  DEFB $03,$B9,$00        ;
  DEFB $07,$60,$80        ;
  DEFB $05,$82,$40        ;
  DEFB $02,$90,$40        ;
  DEFB $07,$01,$80        ;
  DEFB $08,$88,$40        ;
  DEFB $1C,$44,$40        ;
  DEFB $16,$23,$80        ;
  DEFB $2B,$1E,$80        ;
  DEFB $36,$00,$98        ;
  DEFB $2A,$00,$7C        ;
  DEFB $35,$01,$FC        ;
  DEFB $1A,$07,$FC        ;
  DEFB $15,$1F,$F8        ;
  DEFB $1A,$7F,$C0        ;
  DEFB $1C,$FC,$00        ;
  DEFB $1C,$63,$80        ;
  DEFB $1E,$3F,$80        ;
  DEFB $0F,$FF,$00        ;
  DEFB $0F,$F7,$00        ;
  DEFB $07,$F6,$00        ;
  DEFB $07,$FC,$00        ;
  DEFB $03,$F0,$00        ;
  DEFB $04,$F8,$00        ;
  DEFB $03,$F8,$00        ;
  DEFB $00,$FC,$00        ;
  DEFB $00,$76,$00        ;
  DEFB $00,$21,$00        ;
  DEFB $00,$10,$80        ;
  DEFB $00,$13,$00        ;
  DEFB $00,$0E,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$CF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$27        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FF,$00,$FF        ;
  DEFB $FF,$80,$7F        ;
  DEFB $FF,$C0,$3F        ;
  DEFB $FF,$C0,$7F        ;
  DEFB $FF,$E0,$7F        ;
  DEFB $FF,$F1,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 38
;
; Seen on an object in the build's sessions.
SPRITE8E64:
  DEFB $00,$38,$00        ; Image, the top row first
  DEFB $02,$FD,$00        ;
  DEFB $03,$CE,$18        ;
  DEFB $0F,$7E,$3C        ;
  DEFB $06,$FB,$3C        ;
  DEFB $0F,$ED,$BC        ;
  DEFB $03,$DF,$3C        ;
  DEFB $07,$72,$3C        ;
  DEFB $02,$BE,$78        ;
  DEFB $07,$5A,$78        ;
  DEFB $0F,$FE,$78        ;
  DEFB $13,$39,$70        ;
  DEFB $10,$E0,$70        ;
  DEFB $10,$02,$70        ;
  DEFB $10,$05,$60        ;
  DEFB $20,$06,$90        ;
  DEFB $38,$05,$90        ;
  DEFB $38,$0A,$A0        ;
  DEFB $2C,$3D,$40        ;
  DEFB $2F,$F6,$80        ;
  DEFB $33,$C3,$80        ;
  DEFB $1C,$3F,$00        ;
  DEFB $1F,$FF,$00        ;
  DEFB $1F,$FF,$80        ;
  DEFB $0F,$FF,$C0        ;
  DEFB $0F,$FF,$C0        ;
  DEFB $0F,$FF,$80        ;
  DEFB $1F,$CF,$D0        ;
  DEFB $1F,$CF,$A8        ;
  DEFB $1F,$8E,$88        ;
  DEFB $0F,$84,$10        ;
  DEFB $11,$84,$20        ;
  DEFB $22,$44,$40        ;
  DEFB $20,$43,$80        ;
  DEFB $18,$80,$00        ;
  DEFB $07,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FD,$02,$FF        ; Mask: a bit set where the background shows through
  DEFB $F8,$00,$67        ;
  DEFB $F0,$00,$43        ;
  DEFB $E0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $E0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $E0,$00,$03        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$20,$03        ;
  DEFB $E0,$30,$03        ;
  DEFB $C0,$30,$0F        ;
  DEFB $C0,$10,$1F        ;
  DEFB $C0,$18,$3F        ;
  DEFB $C0,$3C,$7F        ;
  DEFB $E0,$7F,$FF        ;
  DEFB $F8,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 38
;
; Seen on an object in the build's sessions.
SPRITE8F48:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$60,$00        ;
  DEFB $09,$F8,$00        ;
  DEFB $07,$DE,$60        ;
  DEFB $0E,$BC,$F0        ;
  DEFB $1D,$F6,$F0        ;
  DEFB $0F,$9C,$F0        ;
  DEFB $1F,$FE,$F0        ;
  DEFB $0D,$E4,$F0        ;
  DEFB $0E,$FE,$F0        ;
  DEFB $1B,$B6,$70        ;
  DEFB $1D,$F9,$70        ;
  DEFB $17,$31,$70        ;
  DEFB $21,$C2,$B0        ;
  DEFB $20,$01,$48        ;
  DEFB $20,$02,$C8        ;
  DEFB $10,$02,$B0        ;
  DEFB $3C,$01,$60        ;
  DEFB $2E,$1F,$40        ;
  DEFB $37,$FD,$80        ;
  DEFB $39,$E3,$80        ;
  DEFB $1E,$1F,$80        ;
  DEFB $1F,$FF,$80        ;
  DEFB $0F,$FF,$00        ;
  DEFB $0F,$FF,$00        ;
  DEFB $07,$7F,$00        ;
  DEFB $0F,$BF,$00        ;
  DEFB $0F,$BF,$00        ;
  DEFB $0F,$DF,$80        ;
  DEFB $0F,$FF,$60        ;
  DEFB $07,$9D,$10        ;
  DEFB $04,$28,$20        ;
  DEFB $04,$50,$C0        ;
  DEFB $03,$8F,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$9F,$FF        ; Mask: a bit set where the background shows through
  DEFB $F6,$07,$FF        ;
  DEFB $E0,$01,$9F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F0,$00,$07        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FC,$70,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 38
;
; Seen on an object in the build's sessions.
SPRITE902C:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$C0,$00        ;
  DEFB $13,$F0,$00        ;
  DEFB $0F,$B8,$00        ;
  DEFB $1D,$68,$00        ;
  DEFB $33,$FC,$00        ;
  DEFB $1F,$3C,$00        ;
  DEFB $1F,$FE,$00        ;
  DEFB $0B,$CB,$00        ;
  DEFB $1B,$F7,$80        ;
  DEFB $2E,$EB,$80        ;
  DEFB $3B,$F1,$C0        ;
  DEFB $2E,$63,$F0        ;
  DEFB $23,$C6,$C8        ;
  DEFB $20,$05,$50        ;
  DEFB $20,$02,$A0        ;
  DEFB $18,$03,$60        ;
  DEFB $1E,$01,$A0        ;
  DEFB $0F,$0F,$40        ;
  DEFB $17,$FE,$C0        ;
  DEFB $18,$F1,$C0        ;
  DEFB $1F,$0F,$80        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FF,$00        ;
  DEFB $07,$FF,$00        ;
  DEFB $07,$FE,$00        ;
  DEFB $03,$7E,$00        ;
  DEFB $01,$FE,$00        ;
  DEFB $00,$FD,$00        ;
  DEFB $01,$FE,$00        ;
  DEFB $02,$1C,$00        ;
  DEFB $02,$50,$00        ;
  DEFB $02,$20,$00        ;
  DEFB $02,$10,$00        ;
  DEFB $01,$08,$00        ;
  DEFB $00,$F0,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$3F,$FF        ; Mask: a bit set where the background shows through
  DEFB $EC,$0F,$FF        ;
  DEFB $C0,$07,$FF        ;
  DEFB $E0,$03,$FF        ;
  DEFB $C0,$03,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C0,$00,$FF        ;
  DEFB $E0,$00,$7F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$03        ;
  DEFB $C0,$00,$07        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F8,$00,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $F8,$0F,$FF        ;
  DEFB $F8,$07,$FF        ;
  DEFB $FC,$03,$FF        ;
  DEFB $FE,$07,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE9110:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$FE,$00        ;
  DEFB $00,$FB,$00        ;
  DEFB $01,$E1,$00        ;
  DEFB $01,$C2,$00        ;
  DEFB $01,$D1,$00        ;
  DEFB $01,$C6,$00        ;
  DEFB $01,$EC,$00        ;
  DEFB $00,$E1,$00        ;
  DEFB $00,$5A,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $03,$F5,$80        ;
  DEFB $03,$0A,$80        ;
  DEFB $05,$15,$80        ;
  DEFB $05,$0A,$00        ;
  DEFB $05,$15,$00        ;
  DEFB $05,$09,$00        ;
  DEFB $04,$87,$00        ;
  DEFB $00,$DF,$00        ;
  DEFB $05,$8F,$80        ;
  DEFB $04,$D7,$80        ;
  DEFB $00,$F3,$80        ;
  DEFB $00,$F9,$80        ;
  DEFB $01,$FC,$80        ;
  DEFB $01,$F6,$00        ;
  DEFB $03,$E7,$00        ;
  DEFB $03,$C7,$80        ;
  DEFB $01,$E7,$E0        ;
  DEFB $00,$E7,$E0        ;
  DEFB $00,$63,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$01,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$08,$3F        ;
  DEFB $FC,$08,$1F        ;
  DEFB $FC,$08,$1F        ;
  DEFB $FC,$18,$0F        ;
  DEFB $FC,$08,$0F        ;
  DEFB $FE,$08,$0F        ;
  DEFB $FE,$08,$3F        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE91CA:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$FE,$00        ;
  DEFB $00,$FB,$00        ;
  DEFB $01,$E1,$00        ;
  DEFB $01,$C2,$00        ;
  DEFB $01,$D1,$00        ;
  DEFB $01,$C6,$00        ;
  DEFB $00,$EC,$00        ;
  DEFB $00,$61,$00        ;
  DEFB $00,$DA,$00        ;
  DEFB $01,$FF,$80        ;
  DEFB $03,$F5,$00        ;
  DEFB $06,$2A,$00        ;
  DEFB $04,$15,$40        ;
  DEFB $04,$2A,$40        ;
  DEFB $0A,$35,$40        ;
  DEFB $0A,$29,$00        ;
  DEFB $0A,$27,$40        ;
  DEFB $09,$BF,$40        ;
  DEFB $05,$3F,$80        ;
  DEFB $05,$1F,$80        ;
  DEFB $04,$CF,$80        ;
  DEFB $00,$67,$80        ;
  DEFB $00,$73,$00        ;
  DEFB $00,$79,$00        ;
  DEFB $00,$7D,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$3C,$00        ;
  DEFB $FF,$01,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FB,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE9284:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$FE,$00        ;
  DEFB $00,$FB,$00        ;
  DEFB $01,$E1,$00        ;
  DEFB $01,$C2,$00        ;
  DEFB $01,$D1,$00        ;
  DEFB $01,$C6,$00        ;
  DEFB $00,$EC,$00        ;
  DEFB $00,$61,$00        ;
  DEFB $00,$DA,$00        ;
  DEFB $00,$FF,$80        ;
  DEFB $03,$F5,$00        ;
  DEFB $0F,$2A,$40        ;
  DEFB $0C,$55,$40        ;
  DEFB $08,$AA,$40        ;
  DEFB $18,$55,$20        ;
  DEFB $18,$A9,$20        ;
  DEFB $14,$47,$10        ;
  DEFB $15,$7F,$10        ;
  DEFB $12,$7F,$80        ;
  DEFB $0A,$7F,$A0        ;
  DEFB $01,$9F,$00        ;
  DEFB $00,$4F,$00        ;
  DEFB $00,$66,$00        ;
  DEFB $00,$F2,$00        ;
  DEFB $00,$F8,$00        ;
  DEFB $00,$7C,$00        ;
  DEFB $00,$1E,$00        ;
  DEFB $00,$1F,$00        ;
  DEFB $00,$1F,$00        ;
  DEFB $00,$0E,$00        ;
  DEFB $FF,$01,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $FE,$00,$5F        ;
  DEFB $FF,$80,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FF,$80,$7F        ;
  DEFB $FF,$C0,$7F        ;
  DEFB $FF,$C0,$7F        ;
  DEFB $FF,$E0,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE933E:
  DEFB $00,$1E,$00        ; Image, the top row first
  DEFB $00,$3F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$FD,$00        ;
  DEFB $01,$42,$80        ;
  DEFB $01,$44,$80        ;
  DEFB $00,$4C,$C0        ;
  DEFB $01,$39,$40        ;
  DEFB $00,$31,$40        ;
  DEFB $02,$01,$00        ;
  DEFB $03,$01,$40        ;
  DEFB $02,$01,$C0        ;
  DEFB $02,$00,$80        ;
  DEFB $06,$00,$C0        ;
  DEFB $04,$00,$40        ;
  DEFB $05,$00,$40        ;
  DEFB $01,$1F,$80        ;
  DEFB $01,$FF,$80        ;
  DEFB $00,$F7,$80        ;
  DEFB $00,$F3,$80        ;
  DEFB $00,$E3,$C0        ;
  DEFB $00,$E3,$E0        ;
  DEFB $00,$FB,$C0        ;
  DEFB $00,$FB,$80        ;
  DEFB $00,$FB,$80        ;
  DEFB $00,$E0,$00        ;
  DEFB $FF,$C0,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$80,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$1F        ;
  DEFB $FE,$00,$1F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FE,$04,$3F        ;
  DEFB $FE,$0C,$1F        ;
  DEFB $FE,$0C,$0F        ;
  DEFB $FE,$04,$1F        ;
  DEFB $FE,$04,$1F        ;
  DEFB $FE,$04,$3F        ;
  DEFB $FF,$04,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE93F8:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$DF,$00        ;
  DEFB $00,$43,$80        ;
  DEFB $01,$62,$80        ;
  DEFB $02,$66,$80        ;
  DEFB $02,$6D,$C0        ;
  DEFB $00,$38,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $02,$40,$40        ;
  DEFB $02,$FC,$40        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$1E,$00        ;
  DEFB $FF,$80,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE94B2:
  DEFB $00,$1C,$00        ; Image, the top row first
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $01,$DD,$80        ;
  DEFB $01,$43,$80        ;
  DEFB $02,$46,$80        ;
  DEFB $02,$6C,$80        ;
  DEFB $04,$78,$40        ;
  DEFB $04,$30,$40        ;
  DEFB $08,$00,$60        ;
  DEFB $00,$00,$60        ;
  DEFB $08,$00,$60        ;
  DEFB $08,$00,$40        ;
  DEFB $08,$00,$40        ;
  DEFB $08,$00,$20        ;
  DEFB $06,$00,$20        ;
  DEFB $01,$80,$40        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$3F,$80        ;
  DEFB $00,$3F,$80        ;
  DEFB $00,$3E,$00        ;
  DEFB $00,$78,$00        ;
  DEFB $00,$7E,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7E,$00        ;
  DEFB $00,$3C,$00        ;
  DEFB $FF,$80,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $FE,$00,$1F        ;
  DEFB $FF,$80,$3F        ;
  DEFB $FF,$80,$3F        ;
  DEFB $FF,$80,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$FF        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$FF        ;
  DEFB $FF,$81,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE956C:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$07,$80        ;
  DEFB $00,$1F,$C0        ;
  DEFB $00,$1F,$C0        ;
  DEFB $00,$3F,$E0        ;
  DEFB $00,$3F,$20        ;
  DEFB $00,$FC,$40        ;
  DEFB $03,$ED,$20        ;
  DEFB $06,$58,$C0        ;
  DEFB $04,$2D,$00        ;
  DEFB $04,$56,$60        ;
  DEFB $04,$2B,$D0        ;
  DEFB $05,$55,$90        ;
  DEFB $02,$7B,$48        ;
  DEFB $06,$3E,$08        ;
  DEFB $01,$BF,$B8        ;
  DEFB $00,$1F,$A4        ;
  DEFB $01,$9F,$00        ;
  DEFB $01,$CF,$18        ;
  DEFB $00,$CE,$00        ;
  DEFB $00,$06,$00        ;
  DEFB $00,$27,$00        ;
  DEFB $00,$0F,$80        ;
  DEFB $00,$0F,$80        ;
  DEFB $00,$07,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$F8,$7F        ;
  DEFB $FF,$E0,$3F        ;
  DEFB $FF,$C0,$1F        ;
  DEFB $FF,$C0,$1F        ;
  DEFB $FF,$80,$0F        ;
  DEFB $FF,$00,$0F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$07        ;
  DEFB $F0,$00,$07        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$C3        ;
  DEFB $FC,$00,$43        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$67        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FF,$80,$7F        ;
  DEFB $FF,$80,$3F        ;
  DEFB $FF,$E0,$3F        ;
  DEFB $FF,$F0,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE9626:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$07,$80        ;
  DEFB $00,$0F,$C0        ;
  DEFB $00,$0F,$C0        ;
  DEFB $00,$1F,$E0        ;
  DEFB $00,$1F,$E0        ;
  DEFB $00,$0F,$C0        ;
  DEFB $00,$1F,$C0        ;
  DEFB $00,$27,$40        ;
  DEFB $00,$2D,$20        ;
  DEFB $00,$72,$00        ;
  DEFB $00,$84,$40        ;
  DEFB $00,$84,$80        ;
  DEFB $00,$08,$40        ;
  DEFB $01,$0C,$40        ;
  DEFB $01,$0C,$A0        ;
  DEFB $01,$0F,$20        ;
  DEFB $01,$0F,$D0        ;
  DEFB $00,$89,$C8        ;
  DEFB $01,$F1,$E0        ;
  DEFB $01,$C3,$E8        ;
  DEFB $03,$E3,$80        ;
  DEFB $03,$E0,$00        ;
  DEFB $07,$C0,$00        ;
  DEFB $03,$00,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$F8,$7F        ;
  DEFB $FF,$F0,$1F        ;
  DEFB $FF,$E0,$1F        ;
  DEFB $FF,$E0,$0F        ;
  DEFB $FF,$C0,$0F        ;
  DEFB $FF,$C0,$0F        ;
  DEFB $FF,$E0,$1F        ;
  DEFB $FF,$C0,$1F        ;
  DEFB $FF,$80,$1F        ;
  DEFB $FF,$80,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FC,$00,$07        ;
  DEFB $FE,$00,$03        ;
  DEFB $FC,$04,$03        ;
  DEFB $FC,$18,$03        ;
  DEFB $F8,$08,$1F        ;
  DEFB $F8,$0F,$FF        ;
  DEFB $F0,$1F,$FF        ;
  DEFB $F8,$3F,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE96E0:
  DEFB $00,$78,$00        ; Image, the top row first
  DEFB $01,$FC,$00        ;
  DEFB $01,$F6,$00        ;
  DEFB $03,$C2,$00        ;
  DEFB $03,$84,$00        ;
  DEFB $03,$A2,$00        ;
  DEFB $03,$8C,$00        ;
  DEFB $03,$D8,$00        ;
  DEFB $01,$C2,$00        ;
  DEFB $00,$B4,$00        ;
  DEFB $01,$FE,$00        ;
  DEFB $07,$EA,$00        ;
  DEFB $07,$54,$00        ;
  DEFB $0A,$2A,$00        ;
  DEFB $0A,$14,$00        ;
  DEFB $0A,$2A,$00        ;
  DEFB $0B,$0E,$00        ;
  DEFB $01,$17,$80        ;
  DEFB $05,$A0,$60        ;
  DEFB $05,$B8,$10        ;
  DEFB $02,$DF,$80        ;
  DEFB $01,$DC,$00        ;
  DEFB $03,$F8,$00        ;
  DEFB $03,$F8,$00        ;
  DEFB $01,$F0,$00        ;
  DEFB $00,$F0,$00        ;
  DEFB $00,$F8,$00        ;
  DEFB $00,$F8,$00        ;
  DEFB $00,$7C,$00        ;
  DEFB $00,$38,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$87,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$03,$FF        ;
  DEFB $FE,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FE,$01,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$01,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FE,$03,$FF        ;
  DEFB $FC,$07,$FF        ;
  DEFB $FC,$07,$FF        ;
  DEFB $FE,$0F,$FF        ;
  DEFB $FF,$0F,$FF        ;
  DEFB $FF,$07,$FF        ;
  DEFB $FF,$07,$FF        ;
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$C7,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE979A:
  DEFB $00,$F0,$00        ; Image, the top row first
  DEFB $03,$F8,$00        ;
  DEFB $03,$EC,$00        ;
  DEFB $07,$84,$00        ;
  DEFB $07,$08,$00        ;
  DEFB $07,$44,$00        ;
  DEFB $07,$18,$00        ;
  DEFB $07,$B0,$00        ;
  DEFB $03,$84,$00        ;
  DEFB $01,$68,$00        ;
  DEFB $01,$FC,$00        ;
  DEFB $07,$AA,$00        ;
  DEFB $07,$56,$E0        ;
  DEFB $0A,$2B,$10        ;
  DEFB $0A,$1C,$20        ;
  DEFB $0A,$28,$C0        ;
  DEFB $0B,$43,$00        ;
  DEFB $09,$4C,$00        ;
  DEFB $13,$BE,$00        ;
  DEFB $15,$FE,$00        ;
  DEFB $28,$FF,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $01,$FE,$00        ;
  DEFB $03,$FE,$00        ;
  DEFB $07,$DC,$00        ;
  DEFB $07,$BC,$00        ;
  DEFB $07,$BE,$00        ;
  DEFB $03,$9E,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FE,$0F,$FF        ; Mask: a bit set where the background shows through
  DEFB $FC,$03,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $FE,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$01,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $C0,$00,$FF        ;
  DEFB $C2,$00,$FF        ;
  DEFB $C2,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F8,$40,$FF        ;
  DEFB $FC,$61,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE9854:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$7E,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $00,$FF,$00        ;
  DEFB $00,$FE,$00        ;
  DEFB $01,$FA,$00        ;
  DEFB $02,$85,$08        ;
  DEFB $02,$89,$14        ;
  DEFB $00,$99,$94        ;
  DEFB $02,$72,$E4        ;
  DEFB $00,$62,$14        ;
  DEFB $04,$02,$08        ;
  DEFB $06,$02,$00        ;
  DEFB $04,$03,$D0        ;
  DEFB $04,$01,$00        ;
  DEFB $0C,$01,$80        ;
  DEFB $08,$00,$C0        ;
  DEFB $0A,$00,$C0        ;
  DEFB $02,$3F,$C0        ;
  DEFB $03,$FF,$C0        ;
  DEFB $00,$F7,$E0        ;
  DEFB $01,$F1,$F0        ;
  DEFB $01,$E1,$F0        ;
  DEFB $03,$C1,$E0        ;
  DEFB $03,$E1,$C0        ;
  DEFB $07,$C0,$00        ;
  DEFB $07,$80,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $FF,$81,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$FF        ;
  DEFB $F8,$00,$67        ;
  DEFB $F8,$00,$63        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$07        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FE,$00,$1F        ;
  DEFB $FE,$0E,$0F        ;
  DEFB $FC,$0E,$07        ;
  DEFB $FC,$0E,$0F        ;
  DEFB $F8,$1E,$1F        ;
  DEFB $F0,$1F,$FF        ;
  DEFB $F8,$7F,$FF        ;
  DEFB $FF,$FF,$FF        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE990E:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$FF,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$DF,$00        ;
  DEFB $00,$43,$80        ;
  DEFB $01,$62,$80        ;
  DEFB $02,$66,$80        ;
  DEFB $02,$6D,$C0        ;
  DEFB $00,$38,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $02,$40,$40        ;
  DEFB $02,$FC,$40        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$1E,$00        ;
  DEFB $FF,$80,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE99C8:
  DEFB $00,$1E,$00        ; Image, the top row first
  DEFB $00,$3F,$80        ;
  DEFB $00,$6F,$80        ;
  DEFB $00,$43,$C0        ;
  DEFB $00,$21,$C0        ;
  DEFB $00,$45,$C0        ;
  DEFB $00,$31,$C0        ;
  DEFB $00,$1B,$80        ;
  DEFB $00,$43,$00        ;
  DEFB $00,$2D,$80        ;
  DEFB $01,$FF,$80        ;
  DEFB $03,$F5,$00        ;
  DEFB $06,$2A,$00        ;
  DEFB $04,$15,$40        ;
  DEFB $04,$2A,$40        ;
  DEFB $0A,$35,$40        ;
  DEFB $0A,$29,$00        ;
  DEFB $0A,$27,$40        ;
  DEFB $09,$BF,$40        ;
  DEFB $05,$3F,$80        ;
  DEFB $05,$1F,$80        ;
  DEFB $04,$CF,$80        ;
  DEFB $00,$67,$80        ;
  DEFB $00,$73,$00        ;
  DEFB $00,$79,$00        ;
  DEFB $00,$7D,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$3C,$00        ;
  DEFB $FF,$80,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$80,$3F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$1F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FB,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 24 by 31
;
; Seen on an object in the build's sessions.
SPRITE9A82:
  DEFB $00,$3C,$00        ; Image, the top row first
  DEFB $00,$FE,$00        ;
  DEFB $00,$FE,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $01,$FF,$00        ;
  DEFB $00,$FE,$00        ;
  DEFB $00,$FB,$00        ;
  DEFB $01,$C2,$00        ;
  DEFB $01,$62,$80        ;
  DEFB $02,$66,$80        ;
  DEFB $02,$6D,$C0        ;
  DEFB $00,$38,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$C0        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $00,$00,$40        ;
  DEFB $02,$00,$40        ;
  DEFB $02,$40,$40        ;
  DEFB $02,$FC,$40        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$00        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$1E,$00        ;
  DEFB $FF,$81,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$00,$FF        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FE,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 16 by 23 (the template for type 34)
SPRITE9B3C:
  DEFB $03,$C0            ; Image, the top row first
  DEFB $18,$18            ;
  DEFB $20,$04            ;
  DEFB $20,$04            ;
  DEFB $38,$14            ;
  DEFB $27,$F8            ;
  DEFB $1B,$E8            ;
  DEFB $10,$08            ;
  DEFB $18,$18            ;
  DEFB $14,$28            ;
  DEFB $12,$48            ;
  DEFB $12,$48            ;
  DEFB $16,$A8            ;
  DEFB $1D,$58            ;
  DEFB $1A,$A8            ;
  DEFB $15,$58            ;
  DEFB $1A,$B8            ;
  DEFB $25,$64            ;
  DEFB $23,$CC            ;
  DEFB $10,$3C            ;
  DEFB $0D,$F8            ;
  DEFB $03,$E0            ;
  DEFB $00,$00            ;
  DEFB $F0,$0F            ; Mask: a bit set where the background shows through
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C8,$13            ;
  DEFB $CC,$33            ;
  DEFB $CC,$33            ;
  DEFB $C8,$13            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $C0,$03            ;
  DEFB $E0,$03            ;
  DEFB $F0,$0F            ;
  DEFB $FC,$3F            ;

; Sprite, 8 by 24 (the template for type 35)
SPRITE9B98:
  DEFB $64                ; Image, the top row first
  DEFB $1C                ;
  DEFB $08                ;
  DEFB $08                ;
  DEFB $14                ;
  DEFB $02                ;
  DEFB $26                ;
  DEFB $26                ;
  DEFB $18                ;
  DEFB $24                ;
  DEFB $46                ;
  DEFB $4E                ;
  DEFB $1C                ;
  DEFB $0E                ;
  DEFB $13                ;
  DEFB $23                ;
  DEFB $16                ;
  DEFB $2E                ;
  DEFB $44                ;
  DEFB $4E                ;
  DEFB $2D                ;
  DEFB $1B                ;
  DEFB $26                ;
  DEFB $1D                ;
  DEFB $83                ; Mask: a bit set where the background shows through
  DEFB $E3                ;
  DEFB $F7                ;
  DEFB $F7                ;
  DEFB $E3                ;
  DEFB $E1                ;
  DEFB $C1                ;
  DEFB $C1                ;
  DEFB $E7                ;
  DEFB $C3                ;
  DEFB $81                ;
  DEFB $81                ;
  DEFB $E3                ;
  DEFB $F1                ;
  DEFB $E0                ;
  DEFB $C0                ;
  DEFB $E1                ;
  DEFB $C1                ;
  DEFB $81                ;
  DEFB $81                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C1                ;
  DEFB $E2                ;

; Sprite, 8 by 24 (the template for type 36)
SPRITE9BC8:
  DEFB $04                ; Image, the top row first
  DEFB $15                ;
  DEFB $15                ;
  DEFB $0A                ;
  DEFB $0E                ;
  DEFB $09                ;
  DEFB $0A                ;
  DEFB $16                ;
  DEFB $1A                ;
  DEFB $2B                ;
  DEFB $52                ;
  DEFB $55                ;
  DEFB $55                ;
  DEFB $24                ;
  DEFB $51                ;
  DEFB $8A                ;
  DEFB $15                ;
  DEFB $84                ;
  DEFB $21                ;
  DEFB $48                ;
  DEFB $82                ;
  DEFB $50                ;
  DEFB $05                ;
  DEFB $20                ;
  DEFB $FB                ; Mask: a bit set where the background shows through
  DEFB $E0                ;
  DEFB $E0                ;
  DEFB $F1                ;
  DEFB $F1                ;
  DEFB $F0                ;
  DEFB $F1                ;
  DEFB $E0                ;
  DEFB $E0                ;
  DEFB $C0                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $00                ;
  DEFB $80                ;
  DEFB $DF                ;

; Sprite, 40 by 24 (the template for type 37)
SPRITE9BF8:
  DEFB $07,$00,$00,$00,$00 ; Image, the top row first
  DEFB $0E,$80,$00,$00,$00 ;
  DEFB $1D,$40,$00,$00,$00 ;
  DEFB $7C,$26,$00,$00,$00 ;
  DEFB $9C,$38,$E0,$00,$00 ;
  DEFB $9F,$4A,$10,$00,$00 ;
  DEFB $4F,$95,$90,$00,$00 ;
  DEFB $37,$A4,$78,$00,$00 ;
  DEFB $07,$24,$66,$00,$00 ;
  DEFB $08,$C4,$81,$80,$00 ;
  DEFB $08,$49,$00,$40,$00 ;
  DEFB $06,$09,$06,$A0,$00 ;
  DEFB $01,$8A,$08,$10,$00 ;
  DEFB $00,$74,$10,$8C,$04 ;
  DEFB $00,$06,$20,$42,$02 ;
  DEFB $00,$03,$20,$31,$2A ;
  DEFB $00,$00,$D0,$48,$51 ;
  DEFB $00,$00,$2C,$14,$49 ;
  DEFB $00,$00,$03,$82,$89 ;
  DEFB $00,$00,$00,$60,$89 ;
  DEFB $00,$00,$00,$38,$8A ;
  DEFB $00,$00,$00,$07,$56 ;
  DEFB $00,$00,$00,$00,$D0 ;
  DEFB $00,$00,$00,$00,$60 ;
  DEFB $F8,$FF,$FF,$FF,$FF ; Mask: a bit set where the background shows through
  DEFB $F0,$7F,$FF,$FF,$FF ;
  DEFB $E0,$3F,$FF,$FF,$FF ;
  DEFB $80,$19,$FF,$FF,$FF ;
  DEFB $00,$00,$1F,$FF,$FF ;
  DEFB $00,$00,$0F,$FF,$FF ;
  DEFB $80,$00,$0F,$FF,$FF ;
  DEFB $C0,$00,$07,$FF,$FF ;
  DEFB $F0,$00,$01,$FF,$FF ;
  DEFB $F0,$00,$00,$7F,$FF ;
  DEFB $F0,$00,$00,$3F,$FF ;
  DEFB $F8,$00,$00,$1F,$FF ;
  DEFB $FE,$00,$00,$0F,$FF ;
  DEFB $FF,$80,$00,$03,$FB ;
  DEFB $FF,$F8,$00,$01,$F1 ;
  DEFB $FF,$FC,$00,$00,$D1 ;
  DEFB $FF,$FF,$00,$00,$00 ;
  DEFB $FF,$FF,$C0,$00,$00 ;
  DEFB $FF,$FF,$FC,$00,$00 ;
  DEFB $FF,$FF,$FF,$80,$00 ;
  DEFB $FF,$FF,$FF,$C0,$01 ;
  DEFB $FF,$FF,$FF,$F8,$01 ;
  DEFB $FF,$FF,$FF,$FF,$0F ;
  DEFB $FF,$FF,$FF,$FF,$9F ;

; Sprite, 24 by 24 (the template for type 38)
SPRITE9CE8:
  DEFB $00,$00,$38        ; Image, the top row first
  DEFB $00,$00,$44        ;
  DEFB $00,$00,$5C        ;
  DEFB $00,$00,$4C        ;
  DEFB $00,$00,$4C        ;
  DEFB $00,$3F,$8C        ;
  DEFB $00,$60,$2C        ;
  DEFB $00,$9F,$EC        ;
  DEFB $39,$3F,$EC        ;
  DEFB $46,$7F,$CC        ;
  DEFB $5C,$FF,$4C        ;
  DEFB $4D,$FC,$4C        ;
  DEFB $4F,$F1,$AC        ;
  DEFB $4F,$C6,$6C        ;
  DEFB $4F,$19,$EC        ;
  DEFB $4C,$67,$B8        ;
  DEFB $4D,$9E,$00        ;
  DEFB $4E,$78,$00        ;
  DEFB $4D,$E0,$00        ;
  DEFB $4F,$80,$00        ;
  DEFB $4E,$00,$00        ;
  DEFB $4C,$00,$00        ;
  DEFB $4C,$00,$00        ;
  DEFB $38,$00,$00        ;
  DEFB $FF,$FF,$83        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$01        ;
  DEFB $FF,$FF,$01        ;
  DEFB $FF,$FF,$01        ;
  DEFB $FF,$C0,$01        ;
  DEFB $FF,$80,$01        ;
  DEFB $FF,$00,$01        ;
  DEFB $C6,$00,$01        ;
  DEFB $80,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$01        ;
  DEFB $00,$00,$03        ;
  DEFB $00,$00,$47        ;
  DEFB $00,$01,$FF        ;
  DEFB $00,$07,$FF        ;
  DEFB $00,$1F,$FF        ;
  DEFB $00,$7F,$FF        ;
  DEFB $01,$FF,$FF        ;
  DEFB $01,$FF,$FF        ;
  DEFB $83,$FF,$FF        ;

; Sprite, 40 by 24 (the template for type 39)
SPRITE9D78:
  DEFB $00,$07,$00,$00,$00 ; Image, the top row first
  DEFB $00,$18,$E0,$00,$00 ;
  DEFB $00,$60,$10,$00,$01 ;
  DEFB $01,$80,$08,$00,$01 ;
  DEFB $06,$00,$3E,$00,$01 ;
  DEFB $18,$00,$D5,$80,$01 ;
  DEFB $30,$03,$AA,$E0,$01 ;
  DEFB $2E,$0D,$55,$58,$00 ;
  DEFB $21,$3A,$AA,$AE,$00 ;
  DEFB $20,$D5,$55,$55,$80 ;
  DEFB $20,$6A,$AA,$AA,$E0 ;
  DEFB $18,$9D,$55,$55,$58 ;
  DEFB $06,$86,$AA,$AA,$A8 ;
  DEFB $01,$81,$D5,$55,$54 ;
  DEFB $00,$60,$6A,$AA,$E4 ;
  DEFB $00,$18,$1D,$55,$84 ;
  DEFB $00,$06,$06,$AE,$04 ;
  DEFB $00,$01,$81,$58,$18 ;
  DEFB $00,$00,$60,$A0,$60 ;
  DEFB $00,$00,$18,$41,$80 ;
  DEFB $00,$00,$06,$46,$00 ;
  DEFB $00,$00,$01,$98,$00 ;
  DEFB $00,$00,$00,$60,$00 ;
  DEFB $00,$00,$00,$00,$00 ;
  DEFB $FF,$F8,$FF,$FF,$FF ; Mask: a bit set where the background shows through
  DEFB $FF,$E0,$1F,$FF,$FF ;
  DEFB $FF,$80,$0F,$FF,$FF ;
  DEFB $FE,$00,$07,$FF,$FF ;
  DEFB $F8,$00,$01,$FF,$FF ;
  DEFB $E0,$00,$00,$7F,$FF ;
  DEFB $C0,$00,$00,$1F,$FF ;
  DEFB $C0,$00,$00,$07,$FF ;
  DEFB $C0,$00,$00,$01,$FF ;
  DEFB $C0,$00,$00,$00,$7F ;
  DEFB $C0,$00,$00,$00,$1F ;
  DEFB $E0,$00,$00,$00,$07 ;
  DEFB $F8,$00,$00,$00,$07 ;
  DEFB $FE,$00,$00,$00,$03 ;
  DEFB $FF,$80,$00,$00,$03 ;
  DEFB $FF,$E0,$00,$00,$03 ;
  DEFB $FF,$F8,$00,$00,$03 ;
  DEFB $FF,$FE,$00,$00,$07 ;
  DEFB $FF,$FF,$80,$00,$1F ;
  DEFB $FF,$FF,$E0,$00,$7F ;
  DEFB $FF,$FF,$F8,$01,$FF ;
  DEFB $FF,$FF,$FE,$07,$FF ;
  DEFB $FF,$FF,$FF,$9F,$FF ;
  DEFB $FF,$FF,$FF,$FF,$FF ;

; A sprite no object uses
;
; A 24 by 16 sprite, image then mask, between the sprites at SPRITE9D78 and
; SPRITE9EC8: a thick diagonal shaft, like a staff or a lance, lying from top
; left to bottom right. Image and mask agree, so it is a sprite, but no
; template, object or table points at it, and it is not a frame of its
; neighbours (they are other sizes). Perhaps the picture of a thing that was
; left out of the game.
DIAGONAL_SPRITE:
  DEFB $0C,$00,$00        ; The image, 16 rows of three bytes
  DEFB $3B,$00,$00        ;
  DEFB $C4,$C0,$00        ;
  DEFB $BB,$30,$00        ;
  DEFB $8C,$4C,$00        ;
  DEFB $83,$13,$00        ;
  DEFB $C0,$C4,$C0        ;
  DEFB $30,$33,$70        ;
  DEFB $0C,$0C,$0C        ;
  DEFB $03,$03,$13        ;
  DEFB $00,$C0,$CD        ;
  DEFB $00,$30,$3B        ;
  DEFB $00,$0C,$35        ;
  DEFB $00,$03,$2B        ;
  DEFB $00,$00,$FC        ;
  DEFB $00,$00,$30        ;
  DEFB $F3,$FF,$FF        ; The mask
  DEFB $C0,$FF,$FF        ;
  DEFB $00,$3F,$FF        ;
  DEFB $00,$0F,$FF        ;
  DEFB $00,$03,$FF        ;
  DEFB $00,$00,$FF        ;
  DEFB $00,$00,$3F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $F0,$00,$03        ;
  DEFB $FC,$00,$00        ;
  DEFB $FF,$00,$00        ;
  DEFB $FF,$C0,$00        ;
  DEFB $FF,$F0,$00        ;
  DEFB $FF,$FC,$00        ;
  DEFB $FF,$FF,$03        ;
  DEFB $FF,$FF,$CF        ;

; Sprite, 8 by 32 (the template for type 41)
SPRITE9EC8:
  DEFB $1C                ; Image, the top row first
  DEFB $63                ;
  DEFB $57                ;
  DEFB $4D                ;
  DEFB $49                ;
  DEFB $25                ;
  DEFB $2B                ;
  DEFB $2A                ;
  DEFB $2B                ;
  DEFB $4A                ;
  DEFB $45                ;
  DEFB $4D                ;
  DEFB $4D                ;
  DEFB $4D                ;
  DEFB $4B                ;
  DEFB $4B                ;
  DEFB $4A                ;
  DEFB $45                ;
  DEFB $45                ;
  DEFB $45                ;
  DEFB $47                ;
  DEFB $4D                ;
  DEFB $4A                ;
  DEFB $4B                ;
  DEFB $4A                ;
  DEFB $4B                ;
  DEFB $4D                ;
  DEFB $4D                ;
  DEFB $4B                ;
  DEFB $4D                ;
  DEFB $6B                ;
  DEFB $1C                ;
  DEFB $E3                ; Mask: a bit set where the background shows through
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $C0                ;
  DEFB $C0                ;
  DEFB $C1                ;
  DEFB $C0                ;
  DEFB $81                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $81                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $81                ;
  DEFB $80                ;
  DEFB $81                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $80                ;
  DEFB $E3                ;

; Sprite, 16 by 13 (the template for type 15)
SPRITE9F08:
  DEFB $04,$00            ; Image, the top row first
  DEFB $0E,$08            ;
  DEFB $2F,$28            ;
  DEFB $3F,$F8            ;
  DEFB $3F,$D8            ;
  DEFB $38,$98            ;
  DEFB $21,$08            ;
  DEFB $32,$08            ;
  DEFB $2C,$08            ;
  DEFB $30,$18            ;
  DEFB $24,$88            ;
  DEFB $18,$30            ;
  DEFB $07,$C0            ;
  DEFB $FB,$FF            ; Mask: a bit set where the background shows through
  DEFB $C0,$E7            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $C0,$07            ;
  DEFB $E0,$0F            ;
  DEFB $F8,$3F            ;

; Sprite, 24 by 26 (the template for type 26, type 33)
SPRITE9F3C:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$0C        ;
  DEFB $01,$23,$34        ;
  DEFB $01,$5D,$A8        ;
  DEFB $02,$BF,$58        ;
  DEFB $02,$FB,$60        ;
  DEFB $01,$4E,$C0        ;
  DEFB $01,$7F,$A0        ;
  DEFB $03,$FF,$60        ;
  DEFB $01,$3D,$E0        ;
  DEFB $06,$9F,$C0        ;
  DEFB $0F,$AF,$C0        ;
  DEFB $0F,$FF,$80        ;
  DEFB $1F,$F7,$80        ;
  DEFB $1B,$F7,$00        ;
  DEFB $14,$F7,$00        ;
  DEFB $0D,$B9,$00        ;
  DEFB $0F,$C7,$00        ;
  DEFB $1B,$FE,$00        ;
  DEFB $31,$FE,$00        ;
  DEFB $21,$EE,$00        ;
  DEFB $03,$8E,$00        ;
  DEFB $03,$C7,$80        ;
  DEFB $01,$C7,$80        ;
  DEFB $00,$06,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$F3        ;
  DEFB $FE,$00,$C3        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $C0,$00,$FF        ;
  DEFB $C4,$00,$FF        ;
  DEFB $CC,$00,$FF        ;
  DEFB $D8,$00,$7F        ;
  DEFB $F8,$10,$3F        ;
  DEFB $FC,$10,$3F        ;
  DEFB $FC,$30,$7F        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITE9FD8:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$0C        ;
  DEFB $01,$5D,$B4        ;
  DEFB $02,$BF,$28        ;
  DEFB $02,$FB,$58        ;
  DEFB $01,$4E,$60        ;
  DEFB $01,$7E,$C0        ;
  DEFB $03,$FF,$80        ;
  DEFB $01,$3F,$60        ;
  DEFB $06,$9F,$E0        ;
  DEFB $0F,$BF,$C0        ;
  DEFB $0F,$FF,$C0        ;
  DEFB $0F,$F7,$80        ;
  DEFB $0D,$F6,$00        ;
  DEFB $0B,$F7,$00        ;
  DEFB $04,$B9,$00        ;
  DEFB $05,$C7,$00        ;
  DEFB $0F,$FE,$00        ;
  DEFB $19,$FE,$00        ;
  DEFB $31,$EC,$00        ;
  DEFB $21,$FC,$00        ;
  DEFB $01,$CE,$00        ;
  DEFB $01,$E6,$00        ;
  DEFB $00,$60,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$F3        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$07        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$FF        ;
  DEFB $C0,$00,$FF        ;
  DEFB $C4,$01,$FF        ;
  DEFB $CC,$01,$FF        ;
  DEFB $DC,$00,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FE,$01,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA074:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$00        ;
  DEFB $01,$5D,$80        ;
  DEFB $02,$BF,$8C        ;
  DEFB $02,$FB,$34        ;
  DEFB $01,$4E,$28        ;
  DEFB $01,$7E,$58        ;
  DEFB $03,$FE,$E0        ;
  DEFB $01,$3D,$80        ;
  DEFB $06,$9F,$60        ;
  DEFB $07,$AF,$E0        ;
  DEFB $0F,$FF,$E0        ;
  DEFB $0F,$F7,$C0        ;
  DEFB $0F,$F6,$00        ;
  DEFB $0D,$F7,$00        ;
  DEFB $0B,$B9,$00        ;
  DEFB $04,$C7,$00        ;
  DEFB $05,$FE,$00        ;
  DEFB $0F,$FC,$00        ;
  DEFB $19,$F8,$00        ;
  DEFB $30,$F0,$00        ;
  DEFB $20,$60,$00        ;
  DEFB $00,$70,$00        ;
  DEFB $00,$78,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$33        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$07        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $C0,$03,$FF        ;
  DEFB $C6,$07,$FF        ;
  DEFB $CF,$0F,$FF        ;
  DEFB $DF,$07,$FF        ;
  DEFB $FF,$03,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA110:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$3B,$00        ;
  DEFB $01,$5D,$80        ;
  DEFB $02,$BF,$8C        ;
  DEFB $02,$FD,$34        ;
  DEFB $01,$7E,$28        ;
  DEFB $01,$72,$58        ;
  DEFB $03,$EE,$E0        ;
  DEFB $02,$3D,$80        ;
  DEFB $07,$FF,$60        ;
  DEFB $07,$F7,$E0        ;
  DEFB $0F,$F7,$E0        ;
  DEFB $0F,$FB,$C0        ;
  DEFB $0F,$FE,$00        ;
  DEFB $0F,$FF,$00        ;
  DEFB $0F,$F7,$00        ;
  DEFB $05,$DF,$00        ;
  DEFB $06,$7E,$00        ;
  DEFB $0F,$FC,$00        ;
  DEFB $19,$F8,$00        ;
  DEFB $30,$F0,$00        ;
  DEFB $21,$E8,$00        ;
  DEFB $01,$F8,$00        ;
  DEFB $00,$70,$00        ;
  DEFB $FF,$03,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$01,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$33        ;
  DEFB $F0,$00,$03        ;
  DEFB $F0,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F0,$00,$07        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $C0,$00,$0F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C0,$03,$FF        ;
  DEFB $C6,$07,$FF        ;
  DEFB $CC,$03,$FF        ;
  DEFB $DC,$03,$FF        ;
  DEFB $FE,$07,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA1AC:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$3B,$0C        ;
  DEFB $01,$5D,$B4        ;
  DEFB $02,$BF,$28        ;
  DEFB $02,$FD,$58        ;
  DEFB $01,$7E,$60        ;
  DEFB $01,$72,$C0        ;
  DEFB $03,$EF,$80        ;
  DEFB $02,$3F,$60        ;
  DEFB $07,$F7,$E0        ;
  DEFB $0F,$F7,$C0        ;
  DEFB $0F,$FB,$C0        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FE,$00        ;
  DEFB $0F,$F7,$00        ;
  DEFB $05,$DF,$00        ;
  DEFB $06,$7F,$00        ;
  DEFB $0F,$FE,$00        ;
  DEFB $19,$FC,$00        ;
  DEFB $31,$DC,$00        ;
  DEFB $21,$FC,$00        ;
  DEFB $01,$FE,$00        ;
  DEFB $01,$DE,$00        ;
  DEFB $00,$1C,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$F3        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$07        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C4,$01,$FF        ;
  DEFB $CC,$01,$FF        ;
  DEFB $DC,$00,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FC,$01,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA248:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$0C        ;
  DEFB $01,$3B,$34        ;
  DEFB $01,$5D,$A8        ;
  DEFB $02,$BF,$58        ;
  DEFB $02,$FD,$60        ;
  DEFB $01,$7E,$C0        ;
  DEFB $01,$73,$A0        ;
  DEFB $03,$EF,$60        ;
  DEFB $06,$3D,$E0        ;
  DEFB $0F,$F7,$C0        ;
  DEFB $0F,$F7,$C0        ;
  DEFB $0F,$FB,$80        ;
  DEFB $0F,$FF,$80        ;
  DEFB $0F,$FF,$00        ;
  DEFB $0F,$F7,$00        ;
  DEFB $05,$DF,$00        ;
  DEFB $0E,$7F,$00        ;
  DEFB $1B,$FE,$00        ;
  DEFB $31,$FE,$00        ;
  DEFB $21,$EE,$80        ;
  DEFB $03,$C7,$80        ;
  DEFB $07,$07,$80        ;
  DEFB $07,$87,$00        ;
  DEFB $03,$80,$00        ;
  DEFB $FF,$83,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$01,$F3        ;
  DEFB $FE,$00,$C3        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C4,$00,$7F        ;
  DEFB $CC,$00,$3F        ;
  DEFB $D8,$10,$3F        ;
  DEFB $F0,$30,$3F        ;
  DEFB $F0,$30,$7F        ;
  DEFB $F8,$38,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA2E4:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$30,$00        ;
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$0C        ;
  DEFB $01,$5D,$B4        ;
  DEFB $02,$BF,$28        ;
  DEFB $02,$FB,$58        ;
  DEFB $01,$4E,$60        ;
  DEFB $01,$7E,$C0        ;
  DEFB $03,$FF,$80        ;
  DEFB $01,$3F,$60        ;
  DEFB $06,$9F,$E0        ;
  DEFB $0F,$BF,$C0        ;
  DEFB $0F,$FF,$C0        ;
  DEFB $0F,$F7,$80        ;
  DEFB $0D,$F6,$00        ;
  DEFB $0B,$F7,$00        ;
  DEFB $04,$B9,$00        ;
  DEFB $05,$C7,$00        ;
  DEFB $0F,$FE,$00        ;
  DEFB $19,$FE,$00        ;
  DEFB $33,$F7,$80        ;
  DEFB $27,$FF,$C0        ;
  DEFB $01,$FF,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$CF,$FF        ;
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$F3        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$07        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F8,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $E0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $E0,$00,$FF        ;
  DEFB $C0,$00,$7F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $DE,$00,$3F        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA380:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$30,$00        ;
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$0C        ;
  DEFB $01,$5D,$B4        ;
  DEFB $02,$BF,$28        ;
  DEFB $02,$FB,$58        ;
  DEFB $01,$4E,$60        ;
  DEFB $01,$7E,$C0        ;
  DEFB $03,$FF,$80        ;
  DEFB $01,$3F,$00        ;
  DEFB $02,$9F,$00        ;
  DEFB $03,$BF,$00        ;
  DEFB $07,$F7,$80        ;
  DEFB $07,$FF,$C0        ;
  DEFB $0F,$FF,$E0        ;
  DEFB $03,$FF,$80        ;
  DEFB $00,$3C,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$CF,$FF        ;
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$E3        ;
  DEFB $FC,$00,$43        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $E0,$00,$0F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $FC,$00,$7F        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA41C:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$30,$00        ;
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$0C        ;
  DEFB $01,$5D,$B4        ;
  DEFB $02,$BF,$28        ;
  DEFB $02,$FB,$58        ;
  DEFB $01,$4E,$60        ;
  DEFB $07,$7F,$C0        ;
  DEFB $1F,$BF,$FC        ;
  DEFB $07,$FF,$E0        ;
  DEFB $00,$3E,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$CF,$FF        ;
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$F3        ;
  DEFB $FC,$00,$03        ;
  DEFB $FC,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $F8,$00,$03        ;
  DEFB $E0,$00,$07        ;
  DEFB $C0,$00,$03        ;
  DEFB $E0,$00,$03        ;
  DEFB $F8,$00,$1F        ;

; Sprite, 24 by 26 (the template for type 27, type 28)
SPRITEA4B8:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$00,$00        ;
  DEFB $00,$30,$00        ;
  DEFB $00,$5C,$00        ;
  DEFB $00,$BE,$00        ;
  DEFB $01,$23,$00        ;
  DEFB $01,$5D,$80        ;
  DEFB $02,$BF,$00        ;
  DEFB $02,$FF,$00        ;
  DEFB $01,$7E,$00        ;
  DEFB $01,$7E,$00        ;
  DEFB $01,$A6,$00        ;
  DEFB $00,$E0,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$FF,$FF        ;
  DEFB $FF,$CF,$FF        ;
  DEFB $FF,$83,$FF        ;
  DEFB $FF,$01,$FF        ;
  DEFB $FE,$00,$FF        ;
  DEFB $FC,$00,$7F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FC,$00,$FF        ;
  DEFB $FE,$01,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA554:
  DEFB $00,$00,$00        ; Image, the top row first
  DEFB $00,$C0,$00        ;
  DEFB $03,$A0,$00        ;
  DEFB $07,$D0,$00        ;
  DEFB $0C,$48,$18        ;
  DEFB $1B,$A8,$68        ;
  DEFB $1F,$D4,$50        ;
  DEFB $0D,$F4,$B0        ;
  DEFB $07,$28,$C0        ;
  DEFB $07,$E9,$00        ;
  DEFB $07,$FA,$00        ;
  DEFB $01,$FC,$00        ;
  DEFB $03,$CE,$00        ;
  DEFB $03,$CF,$00        ;
  DEFB $03,$7B,$00        ;
  DEFB $03,$77,$00        ;
  DEFB $07,$FF,$00        ;
  DEFB $05,$FE,$00        ;
  DEFB $07,$1C,$00        ;
  DEFB $0F,$FE,$00        ;
  DEFB $19,$FE,$00        ;
  DEFB $10,$FC,$00        ;
  DEFB $00,$78,$00        ;
  DEFB $01,$B0,$00        ;
  DEFB $01,$F0,$00        ;
  DEFB $00,$E0,$00        ;
  DEFB $FF,$FF,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$1F,$FF        ;
  DEFB $F8,$0F,$FF        ;
  DEFB $F0,$07,$E7        ;
  DEFB $E0,$03,$83        ;
  DEFB $C0,$03,$03        ;
  DEFB $C0,$01,$07        ;
  DEFB $E0,$00,$07        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $F8,$00,$FF        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $C0,$00,$FF        ;
  DEFB $C0,$00,$FF        ;
  DEFB $C6,$00,$FF        ;
  DEFB $EF,$01,$FF        ;
  DEFB $FC,$07,$FF        ;
  DEFB $FC,$07,$FF        ;
  DEFB $FE,$0F,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA5F0:
  DEFB $00,$60,$00        ; Image, the top row first
  DEFB $01,$D0,$00        ;
  DEFB $03,$E8,$00        ;
  DEFB $06,$24,$00        ;
  DEFB $0D,$D4,$00        ;
  DEFB $0F,$EA,$18        ;
  DEFB $06,$FA,$68        ;
  DEFB $03,$94,$50        ;
  DEFB $03,$F4,$B0        ;
  DEFB $03,$FE,$C0        ;
  DEFB $01,$F5,$00        ;
  DEFB $01,$FB,$00        ;
  DEFB $03,$FF,$80        ;
  DEFB $07,$CF,$80        ;
  DEFB $07,$4F,$80        ;
  DEFB $03,$7B,$00        ;
  DEFB $07,$F7,$00        ;
  DEFB $05,$FF,$00        ;
  DEFB $03,$1E,$00        ;
  DEFB $07,$FC,$00        ;
  DEFB $0D,$FC,$00        ;
  DEFB $09,$BC,$00        ;
  DEFB $01,$FC,$00        ;
  DEFB $03,$9C,$00        ;
  DEFB $03,$3C,$00        ;
  DEFB $00,$30,$00        ;
  DEFB $FE,$0F,$FF        ; Mask: a bit set where the background shows through
  DEFB $FC,$07,$FF        ;
  DEFB $F8,$03,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $E0,$01,$E7        ;
  DEFB $E0,$00,$C3        ;
  DEFB $F0,$00,$83        ;
  DEFB $F8,$00,$07        ;
  DEFB $F8,$00,$07        ;
  DEFB $F8,$00,$0F        ;
  DEFB $FC,$00,$3F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $F8,$01,$FF        ;
  DEFB $FC,$83,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA68C:
  DEFB $00,$30,$00        ; Image, the top row first
  DEFB $00,$E8,$00        ;
  DEFB $01,$F4,$00        ;
  DEFB $03,$12,$00        ;
  DEFB $06,$EB,$00        ;
  DEFB $07,$F5,$30        ;
  DEFB $03,$7D,$D0        ;
  DEFB $01,$CA,$A0        ;
  DEFB $01,$FB,$60        ;
  DEFB $01,$FF,$80        ;
  DEFB $00,$F6,$00        ;
  DEFB $03,$FE,$00        ;
  DEFB $07,$FF,$00        ;
  DEFB $07,$9F,$00        ;
  DEFB $07,$1F,$00        ;
  DEFB $03,$F7,$00        ;
  DEFB $03,$EE,$00        ;
  DEFB $07,$FC,$00        ;
  DEFB $07,$18,$00        ;
  DEFB $0F,$FC,$00        ;
  DEFB $1B,$FC,$00        ;
  DEFB $13,$BC,$00        ;
  DEFB $03,$8E,$00        ;
  DEFB $0F,$1E,$00        ;
  DEFB $0F,$1C,$00        ;
  DEFB $03,$00,$00        ;
  DEFB $FF,$07,$FF        ; Mask: a bit set where the background shows through
  DEFB $FE,$03,$FF        ;
  DEFB $FC,$01,$FF        ;
  DEFB $F8,$00,$FF        ;
  DEFB $F0,$00,$4F        ;
  DEFB $F0,$00,$07        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FC,$00,$0F        ;
  DEFB $FC,$00,$1F        ;
  DEFB $FC,$00,$7F        ;
  DEFB $F8,$00,$FF        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F0,$00,$7F        ;
  DEFB $F8,$00,$7F        ;
  DEFB $F8,$00,$FF        ;
  DEFB $F0,$01,$FF        ;
  DEFB $F0,$03,$FF        ;
  DEFB $E0,$01,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $C0,$01,$FF        ;
  DEFB $E0,$00,$FF        ;
  DEFB $E0,$00,$FF        ;
  DEFB $E0,$40,$FF        ;
  DEFB $F0,$63,$FF        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA728:
  DEFB $00,$0C,$00        ; Image, the top row first
  DEFB $00,$3A,$00        ;
  DEFB $00,$7D,$00        ;
  DEFB $00,$DC,$80        ;
  DEFB $01,$BA,$80        ;
  DEFB $31,$FD,$40        ;
  DEFB $2C,$BF,$40        ;
  DEFB $14,$7E,$80        ;
  DEFB $1A,$4E,$80        ;
  DEFB $07,$77,$C0        ;
  DEFB $01,$BC,$40        ;
  DEFB $06,$FF,$E0        ;
  DEFB $07,$EF,$E0        ;
  DEFB $07,$EF,$F0        ;
  DEFB $03,$DF,$F0        ;
  DEFB $00,$7F,$F0        ;
  DEFB $00,$FF,$F0        ;
  DEFB $00,$EF,$F0        ;
  DEFB $00,$FB,$A0        ;
  DEFB $00,$7E,$60        ;
  DEFB $00,$3F,$F0        ;
  DEFB $00,$1F,$98        ;
  DEFB $00,$0F,$0C        ;
  DEFB $00,$17,$84        ;
  DEFB $00,$1F,$80        ;
  DEFB $00,$0E,$00        ;
  DEFB $FF,$C1,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$80,$FF        ;
  DEFB $FF,$00,$7F        ;
  DEFB $FE,$00,$3F        ;
  DEFB $CC,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F0,$00,$07        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$0F        ;
  DEFB $FF,$00,$0F        ;
  DEFB $FF,$80,$07        ;
  DEFB $FF,$C0,$03        ;
  DEFB $FF,$E0,$63        ;
  DEFB $FF,$C0,$33        ;
  DEFB $FF,$C0,$3B        ;
  DEFB $FF,$E0,$7F        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA7C4:
  DEFB $00,$0C,$00        ; Image, the top row first
  DEFB $00,$3A,$00        ;
  DEFB $00,$7D,$00        ;
  DEFB $30,$DC,$80        ;
  DEFB $2D,$BA,$80        ;
  DEFB $14,$FD,$40        ;
  DEFB $1A,$BF,$40        ;
  DEFB $06,$7E,$80        ;
  DEFB $03,$4E,$80        ;
  DEFB $01,$F7,$C0        ;
  DEFB $06,$FC,$40        ;
  DEFB $07,$EF,$E0        ;
  DEFB $03,$EF,$F0        ;
  DEFB $03,$DF,$F0        ;
  DEFB $01,$FF,$F0        ;
  DEFB $00,$7F,$F0        ;
  DEFB $00,$EF,$F0        ;
  DEFB $00,$FB,$A0        ;
  DEFB $00,$FE,$60        ;
  DEFB $00,$7F,$F0        ;
  DEFB $00,$3F,$98        ;
  DEFB $00,$3B,$8C        ;
  DEFB $00,$3F,$84        ;
  DEFB $00,$7F,$80        ;
  DEFB $00,$7B,$80        ;
  DEFB $00,$38,$00        ;
  DEFB $FF,$E1,$FF        ; Mask: a bit set where the background shows through
  DEFB $FF,$80,$FF        ;
  DEFB $CF,$00,$7F        ;
  DEFB $C2,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$3F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F8,$00,$1F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F8,$00,$07        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$0F        ;
  DEFB $FE,$00,$0F        ;
  DEFB $FF,$00,$07        ;
  DEFB $FF,$80,$03        ;
  DEFB $FF,$80,$23        ;
  DEFB $FF,$80,$33        ;
  DEFB $FF,$00,$3B        ;
  DEFB $FF,$00,$3F        ;
  DEFB $FF,$80,$7F        ;

; Sprite, 24 by 26
;
; Seen on an object in the build's sessions.
SPRITEA860:
  DEFB $00,$0C,$00        ; Image, the top row first
  DEFB $00,$3A,$00        ;
  DEFB $30,$7D,$00        ;
  DEFB $2C,$DC,$80        ;
  DEFB $15,$BA,$80        ;
  DEFB $1A,$FD,$40        ;
  DEFB $06,$BF,$40        ;
  DEFB $03,$7E,$80        ;
  DEFB $05,$CE,$80        ;
  DEFB $06,$F7,$C0        ;
  DEFB $07,$BC,$60        ;
  DEFB $03,$EF,$F0        ;
  DEFB $03,$EF,$F0        ;
  DEFB $01,$DF,$F0        ;
  DEFB $01,$FF,$F0        ;
  DEFB $00,$FF,$F0        ;
  DEFB $00,$EF,$F0        ;
  DEFB $00,$FB,$A0        ;
  DEFB $00,$FE,$70        ;
  DEFB $00,$7F,$D8        ;
  DEFB $00,$7F,$8C        ;
  DEFB $01,$77,$84        ;
  DEFB $01,$E3,$C0        ;
  DEFB $01,$E0,$E0        ;
  DEFB $00,$E1,$E0        ;
  DEFB $00,$01,$C0        ;
  DEFB $FF,$C1,$FF        ; Mask: a bit set where the background shows through
  DEFB $CF,$80,$FF        ;
  DEFB $C3,$00,$7F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$3F        ;
  DEFB $C0,$00,$1F        ;
  DEFB $E0,$00,$1F        ;
  DEFB $F8,$00,$3F        ;
  DEFB $F0,$00,$3F        ;
  DEFB $F0,$00,$1F        ;
  DEFB $F0,$00,$0F        ;
  DEFB $F8,$00,$07        ;
  DEFB $F8,$00,$07        ;
  DEFB $FC,$00,$07        ;
  DEFB $FC,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$07        ;
  DEFB $FE,$00,$0F        ;
  DEFB $FE,$00,$07        ;
  DEFB $FF,$00,$03        ;
  DEFB $FE,$00,$03        ;
  DEFB $FC,$00,$13        ;
  DEFB $FC,$08,$1B        ;
  DEFB $FC,$0C,$0F        ;
  DEFB $FE,$0C,$0F        ;
  DEFB $FE,$1E,$1F        ;

; Leftover source text
;
; Assembler source text, the same kind as at SOURCE_AND_STACK: the end of line
; 3130, one of the DEFB lines of the object table's source; the text runs on at
; OBJECTS. Three of the code's addresses fall in it, six, five and three bytes
; below OBJECTS: bases to which a multiple of six is added, to reach a field of
; a record of the object table (SET_THING_ROOM, BUMPED, SAVE_OBJECT_POSITIONS).
SOURCE_BEFORE_OBJECTS:
  DEFM "18,74,230,150,94"
  DEFM ",21,0,52,150,8,9"
  DEFM "4",$0D,":",$0C,$09,"DEF"

; Where the object table is kept while the game runs
;
; The start-up (START) copies 3420 bytes here from OBJECTS_TAPE: the object
; table (381 records, 3157 bytes with the $FF that ends it) and 263 bytes of
; the leftover text that follows it on the tape. IY+$3A points here. On the
; tape these bytes are leftover source text: lines 3140-3920, the DEFB lines of
; the object table and comments between them, which the table copied over them
; repeats byte for byte; the game never reads the text.
;
; The source text is one run of lines through this part of memory, interrupted
; wherever the game's own bytes lie: SOURCE_BEFORE_OBJECTS (line 3130), here,
; SOURCE_BEFORE_TITLE, then (after the title page's routine) TEMPLATES (lines
; 3970-4180), then (after the font and the first seven records) RECORDS (lines
; 4300-4510), and the end of TUNE_VOICES (lines 4920-4940, the table's last
; line).
OBJECTS:
  DEFM "B",$09,"19,74,230,150,"
  DEFM "94,16,0,52,150,8"
  DEFM ",94",$0D,"D",$0C,$09,"DEFB",$09,"19,7"
  DEFM "4,50,150,94,15,0"
  DEFM ",230,150,4,94",$0D,"N",$0C
  DEFM $09,"DEFB",$09,"20,72,120,"
  DEFM "82,172,21,0,120,"
  DEFM "82,64,106",$0D,"X",$0C,$09,"DEF"
  DEFM "B",$09,"21,74,50,150,9"
  DEFM "4,18,0,230,150,4"
  DEFM ",94",$0D,"b",$0C,$09,"DEFB",$09,"21,7"
  DEFM "2,190,82,172,22,"
  DEFM "1,120,82,64,86",$0D,"l"
  DEFM $0C,$09,"DEFB",$09,"21,73,120"
  DEFM ",82,102,20,0,120"
  DEFM ",82,128,172",$0D,"v",$0C,$09,"D"
  DEFM "EFB",$09,"21,74,230,15"
  DEFM "0,94,25,0,52,150"
  DEFM ",8,94",$0D,$80,$0C,$09,"DEFB",$09,"22"
  DEFM ",73,120,82,84,21"
  DEFM ",1,190,82,128,17"
  DEFM "2",$0D,$8A,$0C,$09,"DEFB",$09,"23,73,"
  DEFM "120,82,84,25,1,1"
  DEFM "90,82,128,172",$0D,$94,$0C
  DEFM $09,"DEFB",$09,"24,73,120,"
  DEFM "82,84,26,1,190,8"
  DEFM "2,128,172",$0D,$9E,$0C,$09,"DEF"
  DEFM "B",$09,"25,72,190,82,1"
  DEFM "72,23,1,120,82,6"
  DEFM "4,86",$0D,$A8,$0C,$09,"DEFB",$09,"25,"
  DEFM "74,50,150,94,21,"
  DEFM "0,230,150,4,94",$0D,$B2
  DEFM $0C,$09,"DEFB",$09,"25,74,230"
  DEFM ",150,94,26,0,52,"
  DEFM "150,8,94",$0D,$BC,$0C,$09,"DEFB"
  DEFM $09,"26,72,190,82,17"
  DEFM "2,24,1,120,82,64"
  DEFM ",86",$0D,$C6,$0C,$09,"DEFB",$09,"26,7"
  DEFM "4,50,150,94,25,0"
  DEFM ",230,150,4,94",$0D,$D0,$0C
  DEFM $09,"DEFB",$09,"26,76,196,"
  DEFM "150,102,27,0,50,"
  DEFM "150,128,172",$0D,$DA,$0C,$09,"D"
  DEFM "EFB",$09,"27,76,50,150"
  DEFM ",174,26,0,196,15"
  DEFM "0,64,106",$0D,$E4,$0C,$09,"DEFB"
  DEFM $09,"27,78,180,116,1"
  DEFM "40,34,0,120,50,1"
  DEFM "6,60",$0D,$EE,$0C,$09,"DEFB",$09,"27,"
  DEFM "73,50,82,102,28,"
  DEFM "0,100,82,128,172"
  DEFM $0D,$F8,$0C,$09,"DEFB",$09,"28,72,1"
  DEFM "00,82,172,27,0,5"
  DEFM "0,82,64,104",$0D,$02,$0D,$09,"D"
  DEFM "EFB",$09,"29,75,50,150"
  DEFM ",48,30,0,50,150,"
  DEFM "128,172",$0D,$0C,$0D,$09,"DEFB",$09
  DEFM "29,71,50,122,152"
  DEFM ",34,0,172,98,4,1"
  DEFM "52",$0D,$16,$0D,$09,"DEFB",$09,"29,70"
  DEFM ",128,122,152,54,"
  DEFM "0,52,82,8,152",$0D," ",$0D
  DEFM $09,"DEFB",$09,"29,72,140,"
  DEFM "82,124,53,0,60,8"
  DEFM "2,64,104",$0D,"*",$0D,$09,"DEFB"
  DEFM $09,"30,75,50,150,48"
  DEFM ",31,0,50,150,128"
  DEFM ",172",$0D,"4",$0D,$09,"DEFB",$09,"30,"
  DEFM "75,50,150,174,29"
  DEFM ",0,50,150,64,52",$0D
  DEFM ">",$0D,$09,"DEFB",$09,"30,74,48"
  DEFM ",150,50,32,0,176"
  DEFM ",150,4,50",$0D,"H",$0D,$09,"DEF"
  DEFM "B",$09,"31,75,50,150,1"
  DEFM "74,30,0,50,150,6"
  DEFM "4,52",$0D,"R",$0D,$09,"DEFB",$09,"31,"
  DEFM "74,48,150,50,33,"
  DEFM "0,176,150,4,50",$0D,"\\"
  DEFM $0D,$09,"DEFB",$09,"31,81,176"
  DEFM ",100,70,81,8,60,"
  DEFM "100,8,128",$0D,"f",$0D,$09,"DEF"
  DEFM "B",$09,"32,75,50,150,4"
  DEFM "8,33,0,50,150,12"
  DEFM "8,172",$0D,"p",$0D,$09,"DEFB",$09,"32"
  DEFM ",74,178,150,50,3"
  DEFM "0,0,52,150,8,50",$0D
  DEFM "z",$0D,$09,"DEFB",$09,"33,81,50"
  DEFM ",100,128,37,0,11"
  DEFM "2,100,4,132",$0D,$84,$0D,$09,"D"
  DEFM "EFB",$09,"33,75,50,150"
  DEFM ",174,32,0,50,150"
  DEFM ",64,52",$0D,$8E,$0D,$09,"DEFB",$09,"3"
  DEFM "3,74,178,150,50,"
  DEFM "31,0,52,150,8,50"
  DEFM $0D,$98,$0D,$09,"DEFB",$09,"34,70,1"
  DEFM "76,98,152,29,0,5"
  DEFM "2,124,8,152",$0D,$A2,$0D,$09,"D"
  DEFM "EFB",$09,"34,71,50,82,"
  DEFM "80,35,0,110,82,4"
  DEFM ",86",$0D,$AC,$0D,$09,"DEFB",$09,"34,7"
  DEFM "8,100,52,50,27,0"
  DEFM ",170,116,32,130",$0D
  DEFM $B6,$0D,$09,"DEFB",$09,"35,70,11"
  DEFM "0,82,86,34,0,52,"
  DEFM "82,8,80",$0D,$C0,$0D,$09,"DEFB",$09
  DEFM "35,75,50,150,50,"
  DEFM "36,0,50,150,128,"
  DEFM "172",$0D,$CA,$0D,$09,"DEFB",$09,"36,7"
  DEFM "5,50,150,172,35,"
  DEFM "0,50,150,64,52",$0D,$D4
  DEFM $0D,$09,"DEFB",$09,"36,75,50,"
  DEFM "150,50,37,0,50,1"
  DEFM "50,128,172",$0D,$DE,$0D,$09,"DE"
  DEFM "FB",$09,"37,81,112,100"
  DEFM ",130,33,0,60,100"
  DEFM ",8,128",$0D,$E8,$0D,$09,"DEFB",$09,"3"
  DEFM "7,75,50,150,172,"
  DEFM "36,0,50,150,64,5"
  DEFM "2",$0D,$F2,$0D,$09,"DEFB",$09,"37,75,"
  DEFM "50,150,50,38,0,5"
  DEFM "0,150,128,172",$0D,$FC,$0D
  DEFM $09,"DEFB",$09,"37,71,50,8"
  DEFM "2,150,47,0,174,8"
  DEFM "2,4,100",$0D,$06,$0E,$09,"DEFB",$09
  DEFM "38,75,50,150,174"
  DEFM ",37,0,50,150,64,"
  DEFM "52",$0D,$10,$0E,$09,"DEFB",$09,"38,74"
  DEFM ",112,150,100,39,"
  DEFM "0,52,150,8,100",$0D,$1A
  DEFM $0E,$09,"DEFB",$09,"38,73,70,"
  DEFM "82,48,62,0,200,8"
  DEFM "2,128,172",$0D,"$",$0E,$09,"DEF"
  DEFM "B",$09,"39,74,50,150,1"
  DEFM "00,38,0,112,150,"
  DEFM "4,100",$0D,".",$0E,$09,"DEFB",$09,"39"
  DEFM ",74,230,150,100,"
  DEFM "40,0,52,150,8,10"
  DEFM "0",$0D,"8",$0E,$09,"DEFB",$09,"39,73,"
  DEFM "60,82,104,42,3,5"
  DEFM "0,82,128,172",$0D,"B",$0E,$09
  DEFM "DEFB",$09,"40,74,50,15"
  DEFM "0,100,39,0,230,1"
  DEFM "50,4,100",$0D,"L",$0E,$09,"DEFB"
  DEFM $09,"40,73,120,82,10"
  DEFM "4,41,0,100,82,12"
  DEFM "8,172",$0D,"V",$0E,$09,"DEFB",$09,"41"
  DEFM ",72,100,82,170,4"
  DEFM "0,0,120,82,64,10"
  DEFM "8",$0D,$60,$0E,$09,"DEFB",$09,"42,72,"
  DEFM "52,82,172,39,3,6"
  DEFM "0,82,64,108",$0D,"j",$0E,$09,"D"
  DEFM "EFB",$09,"42,70,78,82,"
  DEFM "108,43,0,52,82,8"
  DEFM ",108",$0D,"t",$0E,$09,"DEFB",$09,"42,"
  DEFM "73,54,82,76,45,3"
  DEFM ",60,82,128,172",$0D,"~"
  DEFM $0E,$09,"DEFB",$09,"43,71,50,"
  DEFM "82,108,42,0,78,8"
  DEFM "2,4,108",$0D,$88,$0E,$09,"DEFB",$09
  DEFM "43,72,90,82,78,4"
  DEFM "4,0,90,82,128,17"
  DEFM "2",$0D,$92,$0E,$09,"DEFB",$09,"44,72,"
  DEFM "90,82,172,43,0,9"
  DEFM "0,82,64,80",$0D,$9C,$0E,$09,"DE"
  DEFM "FB",$09,"45,74,54,150,"
  DEFM "50,46,0,174,150,"
  DEFM "4,50",$0D,$A6,$0E,$09,"DEFB",$09,"45,"
  DEFM "72,60,82,174,42,"
  DEFM "3,54,82,64,82",$0D,$B0,$0E
  DEFM $09,"DEFB",$09,"46,74,174,"
  DEFM "150,50,45,0,58,1"
  DEFM "50,8,50",$0D,$BA,$0E,$09,"DEFB",$09
  DEFM "46,72,90,82,132,"
  DEFM "57,6,80,82,64,10"
  DEFM "8",$0D,$C4,$0E,$09,"DEFB",$09,"46,81,"
  DEFM "58,100,106,52,0,"
  DEFM "80,100,4,114",$0D,$CE,$0E,$09
  DEFM "DEFB",$09,"47,72,100,8"
  DEFM "2,172,48,0,100,8"
  DEFM "2,64,52",$0D,$D8,$0E,$09,"DEFB",$09
  DEFM "47,71,50,82,100,"
  DEFM "50,0,174,82,4,10"
  DEFM "0",$0D,$E2,$0E,$09,"DEFB",$09,"47,70,"
  DEFM "174,82,100,37,0,"
  DEFM "52,82,8,150",$0D,$EC,$0E,$09,"D"
  DEFM "EFB",$09,"48,71,50,82,"
  DEFM "100,49,0,174,82,"
  DEFM "4,100",$0D,$F6,$0E,$09,"DEFB",$09,"48"
  DEFM ",73,100,82,50,47"
  DEFM ",0,100,82,128,17"
  DEFM "2",$0D,$00,$0F,$09,"DEFB",$09,"49,73,"
  DEFM "100,82,50,50,0,1"
  DEFM "00,82,128,172",$0D,$0A,$0F
  DEFM $09,"DEFB",$09,"49,70,174,"
  DEFM "82,100,48,0,52,8"
  DEFM "2,8,100",$0D,$14,$0F,$09,"DEFB",$09
  DEFM "50,72,100,82,172"
  DEFM ",49,0,100,82,64,"
  DEFM "52",$0D,$1E,$0F,$09,"DEFB",$09,"50,70"
  DEFM ",174,82,100,47,0"
  DEFM ",52,82,8,100",$0D,"(",$0F,$09
  DEFM "DEFB",$09,"50,71,50,82"
  DEFM ",50,2,0,174,102,"
  DEFM "4,150",$0D,"2",$0F,$09,"DEFB",$09,"50"
  DEFM ",72,150,82,48,63"
  DEFM ",0,90,82,128,174"
  DEFM $0D,"<",$0F,$09,"DEFB",$09,"51,80,1"
  DEFM "10,52,120,80,0,5"
  DEFM "6,180,32,156",$0D,"F",$0F,$09
  DEFM "DEFB",$09,"51,83,150,1"
  DEFM "00,48,52,0,50,10"
  DEFM "0,128,174",$0D,"P",$0F,$09,"DEF"
  DEFM "B",$09,"51,81,178,100,"
  DEFM "146,62,0,52,"

; Leftover source text
;
; Six bytes of a DEFB line of the object table's source, between OBJECTS's text
; and the title page's routine.
SOURCE_BEFORE_TITLE:
  DEFM "100,8,"

; Print the title page's words
;
; Used by the routine at TITLE_SCREEN.
;
; Called by TITLE_SCREEN once the title picture (room 79) is drawn and
; coloured: the game's name and subtitle, its author and publisher, and the
; keys and what each does, each at its own place. It is all one string for the
; printer (PRINT), after the CALL, laid out below by the printer's commands:
; $C8 and a position, the characters, and $A4 to end.
TITLE_PAGE_TEXT:
  CALL PRINT              ; The string follows the CALL.
  DEFB $C8,$58,$AA        ; Print at x 88, y 170
  DEFB $06,$01,$09,$12,$0C,$09,$07,$08 ; "FAIRLIGHT"
  DEFB $14                             ;
  DEFB $C8,$58,$A0        ; Print at x 88, y 160
  DEFB $01,$00,$10,$12,$05,$0C,$15,$04 ; "A PRELUDE"
  DEFB $05                             ;
  DEFB $C8,$3C,$82        ; Print at x 60, y 130
  DEFB $02,$19,$00,$02,$0F,$00,$0A,$01 ; "BY BO JANGEBORG "
  DEFB $0E,$07,$05,$02,$0F,$12,$07,$00 ;
  DEFB $C8,$4C,$78        ; Print at x 76, y 120
  DEFB $06,$0F,$12,$00,$14,$08,$05,$00 ; "FOR THE EDGE"
  DEFB $05,$04,$07,$05                 ;
  DEFB $C8,$14,$50        ; Print at x 20, y 80
  DEFB $11,$26,$14        ; "Q-T"
  DEFB $C8,$14,$46        ; Print at x 20, y 70
  DEFB $01,$26,$07        ; "A-G"
  DEFB $C8,$14,$64        ; Print at x 20, y 100
  DEFB $19,$26,$10        ; "Y-P"
  DEFB $C8,$14,$5A        ; Print at x 20, y 90
  DEFB $08,$26,$05,$0E,$14 ; "H-ENT"
  DEFB $C8,$14,$3C        ; Print at x 20, y 60
  DEFB $13,$19,$0D,$26,$13,$10,$01,$03 ; "SYM-SPACE"
  DEFB $05                             ;
  DEFB $C8,$14,$32        ; Print at x 20, y 50
  DEFB $02,$26,$0D        ; "B-M"
  DEFB $C8,$14,$28        ; Print at x 20, y 40
  DEFB $18,$26,$16        ; "X-V"
  DEFB $C8,$14,$1E        ; Print at x 20, y 30
  DEFB $03,$01,$10,$26,$1A ; "CAP-Z"
  DEFB $C8,$14,$14        ; Print at x 20, y 20
  DEFB $1C,$26,$20        ; "1-5"
  DEFB $C8,$14,$0A        ; Print at x 20, y 10
  DEFB $21,$26,$22        ; "6-7"
  DEFB $C8,$7C,$3C        ; Print at x 124, y 60
  DEFB $0A,$15,$0D,$10    ; "JUMP"
  DEFB $C8,$7C,$32        ; Print at x 124, y 50
  DEFB $06,$09,$07,$08,$14 ; "FIGHT"
  DEFB $C8,$7C,$28        ; Print at x 124, y 40
  DEFB $10,$09,$03,$0B    ; "PICK"
  DEFB $C8,$7C,$1E        ; Print at x 124, y 30
  DEFB $04,$12,$0F,$10    ; "DROP"
  DEFB $C8,$7C,$14        ; Print at x 124, y 20
  DEFB $0F,$02,$0A        ; "OBJ"
  DEFB $C8,$7C,$0A        ; Print at x 124, y 10
  DEFB $15,$13,$05        ; "USE"
  DEFB $A4                ; End of the string
  RET

; Where the object templates are kept while the game runs
;
; The start-up (START) copies 932 bytes here from TEMPLATES_TAPE: the templates
; for object types 0-$38, 11 bytes each; from offset 630 (LARGE_TEMPLATES),
; those for types $46-$54, 9 bytes each; and from offset 784 the patches for
; the codes $E6 up in a room's object list, six bytes each. The patches' base
; (PATCHES, offset 778) is where code $E5 would find its entry: PATCH_RECORDS
; in DO_ROOM_COMMAND counts from there. On the tape these bytes are leftover
; source text (lines 3970-4180, more of the object table's DEFB lines); the
; game never reads it.
TEMPLATES:
  DEFM "56",$0D,$82,$0F,$09,"DEFB",$09,"53,70"
  DEFM ",48,82,156,76,0,"
  DEFM "154,82,4,156",$0D,$8C,$0F,$09
  DEFM "DEFB",$09,"54,70,88,82"
  DEFM ",158,53,0,92,130"
  DEFM ",8,152",$0D,$96,$0F,$09,"DEFB",$09,"5"
  DEFM "4,71,50,82,152,2"
  DEFM "9,0,128,124,4,15"
  DEFM "2",$0D,$A0,$0F,$09,"DEFB",$09,"54,71,"
  DEFM "90,128,156,55,0,"
  DEFM "88,82,4,156",$0D,$AA,$0F,$09,"D"
  DEFM "EFB",$09,"55,70,88,82,"
  DEFM "158,54,0,92,130,"
  DEFM "8,152",$0D,$B4,$0F,$09,"DEFB",$09,"55"
  DEFM ",82,110,150,154,"
  DEFM "56,0,110,52,16,1"
  DEFM "54",$0D,$BE,$0F,$09,"DEFB",$09,"56,80"
  DEFM ",110,52,154,55,0"
  DEFM ",110,140,32,156",$0D
  DEFM $C8,$0F,$09,"DEFB",$09,"56,71,90"
  DEFM ",82,110,68,0,88,"
  DEFM "82,4,110",$0D,$D2,$0F,$09,"DEFB"
  DEFM $09,"57,71,90,128,15"
  DEFM "6,58,0,88,82,4,1"
  DEFM "56",$0D,$DC,$0F,$09,"DEFB",$09,"57,73"
  DEFM ",80,82,100,46,6,"
  DEFM "90,82,128,132",$0D,$E6,$0F
  DEFM $09,"DEFB",$09,"57,72,60,8"
  DEFM "2,172,62,6,70,82"
  DEFM ",64,148",$0D,$F0,$0F,$09,"DEFB",$09
  DEFM "58,71,90,128,158"
  DEFM ",59,0,88,82,4,15"
  DEFM "6",$0D,$FA,$0F,$09,"DEFB",$09,"58,70,"
  DEFM "88,82,158,57,0,9"
  DEFM "2,130,8,152",$0D,$04,$10,$09,"D"
  DEFM "EFB",$09,"59,71,90,128"
  DEFM ",158,60,0,88,82,"
  DEFM "4,156",$0D,$0E,$10,$09,"DEFB",$09,"59"
  DEFM ",70,88,82,158,58"
  DEFM ",0,92,"
LARGE_TEMPLATES:
  DEFM "130,8,152",$0D,$18,$10,$09,"DEF"
  DEFM "B",$09,"60,82,110,150,"
  DEFM "154,61,7,146,52,"
  DEFM "16,154",$0D,"\"",$10,$09,"DEFB",$09,"6"
  DEFM "0,70,88,82,158,5"
  DEFM "9,0,92,130,8,152"
  DEFM $0D,",",$10,$09,"DEFB",$09,"61,80,1"
  DEFM "46,52,154,60,0,1"
  DEFM "00,160,32,156",$0D,"6",$10
  DEFM $09,"DEF"
PATCHES:
  DEFM "B",$09,"62,81,50,100,1"
  DEFM "46,51,0,176,100,"
  DEFM "4,146",$0D,"@",$10,$09,"DEFB",$09,"62"
  DEFM ",73,70,82,146,57"
  DEFM ",6,60,82,128,172"
  DEFM $0D,"J",$10,$09,"DEFB",$09,"62,72,1"
  DEFM "96,82,172,38,0,7"
  DEFM "0,82,64,50",$0D,"T",$10,$09,"DE"
  DEFM "FB",$09,"62,73,196,82,"
  DEFM "146,77,4,9"

; The font
;
; The game's text is in these characters' numbers, not in ASCII: 0 a space,
; 1-26 the letters, 27-36 the digits, 37 a full stop and 38 a dash. PRINT
; prints them.
FONT:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Character 0: space
  DEFB $00,$3C,$66,$66,$7E,$66,$66,$00 ; Character 1: A
  DEFB $00,$7C,$66,$7C,$66,$66,$7C,$00 ; Character 2: B
  DEFB $00,$3C,$66,$60,$60,$66,$3C,$00 ; Character 3: C
  DEFB $00,$78,$6C,$66,$66,$6C,$78,$00 ; Character 4: D
  DEFB $00,$7E,$60,$7C,$60,$60,$7E,$00 ; Character 5: E
  DEFB $00,$7E,$60,$7C,$60,$60,$60,$00 ; Character 6: F
  DEFB $00,$3C,$66,$60,$6E,$66,$3C,$00 ; Character 7: G
  DEFB $00,$66,$66,$7E,$66,$66,$66,$00 ; Character 8: H
  DEFB $00,$3C,$18,$18,$18,$18,$3C,$00 ; Character 9: I
  DEFB $00,$06,$06,$06,$66,$66,$3C,$00 ; Character 10: J
  DEFB $00,$6C,$78,$70,$78,$6C,$66,$00 ; Character 11: K
  DEFB $00,$60,$60,$60,$60,$60,$7E,$00 ; Character 12: L
  DEFB $00,$42,$66,$7E,$66,$66,$66,$00 ; Character 13: M
  DEFB $00,$66,$66,$76,$6E,$66,$66,$00 ; Character 14: N
  DEFB $00,$3C,$66,$66,$66,$66,$3C,$00 ; Character 15: O
  DEFB $00,$7C,$66,$66,$7C,$60,$60,$00 ; Character 16: P
  DEFB $00,$3C,$66,$66,$76,$6E,$3C,$00 ; Character 17: Q
  DEFB $00,$7C,$66,$66,$7C,$6C,$66,$00 ; Character 18: R
  DEFB $00,$3C,$60,$3C,$06,$66,$3C,$00 ; Character 19: S
  DEFB $00,$7E,$18,$18,$18,$18,$18,$00 ; Character 20: T
  DEFB $00,$66,$66,$66,$66,$66,$3C,$00 ; Character 21: U
  DEFB $00,$66,$66,$66,$66,$3C,$18,$00 ; Character 22: V
  DEFB $00,$66,$66,$66,$66,$7E,$24,$00 ; Character 23: W
  DEFB $00,$66,$3C,$18,$18,$3C,$66,$00 ; Character 24: X
  DEFB $00,$66,$3C,$18,$18,$18,$18,$00 ; Character 25: Y
  DEFB $00,$7E,$06,$0C,$18,$30,$7E,$00 ; Character 26: Z
  DEFB $00,$3C,$66,$6E,$76,$66,$3C,$00 ; Character 27: 0
  DEFB $00,$18,$38,$18,$18,$18,$3C,$00 ; Character 28: 1
  DEFB $00,$3C,$46,$06,$3C,$60,$7E,$00 ; Character 29: 2
  DEFB $00,$3C,$66,$0C,$06,$66,$3C,$00 ; Character 30: 3
  DEFB $00,$0C,$1C,$3C,$6C,$7E,$0C,$00 ; Character 31: 4
  DEFB $00,$7E,$60,$7C,$06,$66,$3C,$00 ; Character 32: 5
  DEFB $00,$3C,$60,$7C,$66,$66,$3C,$00 ; Character 33: 6
  DEFB $00,$7E,$06,$0C,$18,$30,$30,$00 ; Character 34: 7
  DEFB $00,$3C,$66,$3C,$66,$66,$3C,$00 ; Character 35: 8
  DEFB $00,$3C,$66,$66,$3E,$06,$3C,$00 ; Character 36: 9
  DEFB $00,$00,$00,$00,$00,$18,$18,$00 ; Character 37: .
  DEFB $00,$00,$00,$00,$3E,$00,$00,$00 ; Character 38: -
  DEFB $18,$34,$50,$9C,$92,$AA,$44,$38 ; Character 39: not a letter

; The room's floor, ceiling and walls: six object records
;
; Records 1 to 6 of the object records (the knight's is the seventh, KNIGHT),
; twenty bytes each, laid out like his. They have no sprite (+4 and +5 are
; zero, so nothing draws them) and huge sizes, and they box the room in for the
; collision code, which tests every record in use from the first
; (FIND_OBSTACLE): record 1 is the floor, ten high with its top at +7; record 2
; the ceiling; records 3 and 4 the walls across +6, one at each end; records 5
; and 6 the walls across +8. Each reaches right across the room the other two
; ways ($FF). An object occupies +6 to +6 plus +9, +7 less +10 to +7, and +8 to
; +8 plus +11 (FAR_CORNER).
;
; A room sets them with the patch code in its object list (or a part's), $E6
; up: PATCH_RECORDS in DO_ROOM_COMMAND writes the patch's six bytes into the
; floor's and the ceiling's +7, records 3 and 4's +6 and records 5 and 6's +8.
; In most rooms the floor's top is 50, the height the knight's feet are at when
; he stands on it. Every room the knight plays in has a patch in its list or in
; one of its parts; only rooms 1, 79 and 81 (GAME OVER, the title and the end
; of the quest) have none (read from the rooms' commands, parts followed). On
; the tape they hold the values below; entering rooms 3, 45, 80 and 5 in the
; simulator showed the walls moving to that room's patch (measured).
FIXED_RECORDS:
  DEFB $00,$00,$00,$00,$00,$00         ; Record 1, the floor: no sprite; at 50,
  DEFB $32,$32,$32                     ; 50, 50; 255 by 10 by 255
  DEFB $FF,$0A,$FF                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ; Record 2, the ceiling: at 50, 120, 50
  DEFB $32,$78,$32                     ; on the tape; 255 by 10 by 255
  DEFB $FF,$0A,$FF                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ; Record 3, a wall across +6: at 178,
  DEFB $B2,$FF,$32                     ; 255, 50; 10 by 255 by 255
  DEFB $0A,$FF,$FF                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ; Record 4, the other wall across +6: at
  DEFB $28,$FF,$32                     ; 40, 255, 50; 10 by 255 by 255
  DEFB $0A,$FF,$FF                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ; Record 5, a wall across +8: at 50,
  DEFB $32,$FF,$AF                     ; 255, 175 on the tape; 255 by 255 by 10
  DEFB $FF,$FF,$0A                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00         ; Record 6, the other wall across +8:
  DEFB $32,$FF,$AF                     ; the same on the tape
  DEFB $FF,$FF,$0A                     ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; The knight's object record
;
; Record 7; the room's objects follow from RECORDS. Twenty bytes, the layout of
; every object record. The fields this part of the code reads: +0 and +1, where
; the sprite is on the screen (x, and y of its top row, counted up from the
; bottom of the screen); +2 and +3, its width in pixels and height in rows; +4
; and +5, the sprite (image, then mask); +6 to +8, where the object is in the
; room, +6 and +8 along the floor and +7 the height of its top (ISO_MOVE turns
; a change in them into a change of +0 and +1); +9 to +11, its size along each;
; +12, its kind in the low nibble and flags above it; +19, its number in the
; object table (0 for the knight, who is not in it).
;
; The listing names the fields wherever IX holds a record's address:
; OBJ_SCREEN_X (+0), OBJ_SCREEN_Y (+1), OBJ_WIDTH (+2), OBJ_ROWS (+3),
; OBJ_SPRITE (+4, a word), OBJ_X (+6), OBJ_TOP (+7), OBJ_Z (+8), OBJ_LEN_X
; (+9), OBJ_HEIGHT (+10), OBJ_LEN_Z (+11), OBJ_KIND (+12), OBJ_DIRECTION (+13),
; OBJ_STATE (+14), OBJ_COUNT (+15), OBJ_WEIGHT (+16), OBJ_FRAME (+17),
; OBJ_COURSE (+18) and OBJ_NUMBER (+19); OBJ_SIZE is the record's twenty bytes.
; They are EQUs at the top of the source file. A door's record uses the same
; bytes for its own things -- +13 the room behind it, +14 the key, +15, +16 and
; +18 where the knight arrives, +17 the way through -- and the routines that
; read a door say so.
;
; On the tape this is his record at the start of a game. START copies it to the
; master copy (MASTER_OBJECTS), and TITLE_SCREEN copies it back at every new
; game and whenever he is carried off to another room, all but +14: bit 5 of
; +14 says which way his sprite images face, and MIMAN turns the images
; themselves round in memory when he turns, so the record must go on saying
; which way they face now.
KNIGHT:
  DEFB $3C,$3E            ; Where his sprite is (x 60, y 62), and its size (24
  DEFB $18,$1F            ; pixels by 31 rows)
KNIGHT_SPRITE:
  DEFW SPRITE9110         ; His sprite: the first of his frames
  DEFB $36,$4E,$6E        ; +6 to +8, where he is in the room (54, 78, 110); +9
  DEFB $08,$1C,$08        ; to +11, his size (8, 28, 8); +12, his kind (0) and
  DEFB $C0                ; flags; +13
  DEFB $01                ;
KNIGHT_FLAGS:
  DEFB $08                 ; +14, which a reset of the record keeps (bit 5:
  DEFB $01,$12,$10,$01,$00 ; which way his sprite images face); +15 to +19
                           ; (+19, his number: 0)

; The object records for the room's things
;
; Records 8 up: filled when a room is entered, twenty bytes a record. ROOMST
; copies in the records of the things carried and PLACE_ROOM_OBJECTS makes the
; rest from the room's entries in the object table, placed by the room's object
; list (DO_ROOM_COMMAND); IY+$38 holds the address of the next free record and
; IY+$00 counts the records in use, the fixed seven included. On the tape:
; leftover source text, lines 4300-4510 (DEFB lines of the object table, and a
; comment line that heads the table's second part); the game never reads it.
RECORDS:
  DEFM ",0,92,130,8,152",$0D
  DEFM $CC,$10,$09,"DEFB",$09,"67,82,11"
  DEFM "0,150,154,68,0,1"
  DEFM "10,52,16,154",$0D,$D6,$10,$09
  DEFM "DEFB",$09,"68,80,110,5"
  DEFM "2,154,67,0,110,1"
  DEFM "40,32,156",$0D,$E0,$10,$09,"DEF"
  DEFM "B",$09,"68,71,90,82,11"
  DEFM "0,56,0,88,82,4,1"
  DEFM "10",$0D,$EA,$10,$09,"DEFB",$09,"69,73"
  DEFM ",120,82,84,2,0,1"
  DEFM "00,82,128,174",$0D,$F4,$10
  DEFM $09,"DEFB",$09,"70,71,50,8"
  DEFM "2,78,72,0,174,82"
  DEFM ",4,78",$0D,$FE,$10,$09,"DEFB",$09,"70"
  DEFM ",75,50,150,50,73"
  DEFM ",0,50,150,128,17"
  DEFM "2",$0D,$08,$11,$09,"DEFB",$09,"71,70,"
  DEFM "174,82,78,73,0,5"
  DEFM "2,82,8,78",$0D,$12,$11,$09,"DEF"
  DEFM "B",$09,"72,70,174,82,7"
  DEFM "8,70,0,52,82,8,7"
  DEFM "8",$0D,$1C,$11,$09,"DEFB",$09,"73,75,"
  DEFM "50,150,172,70,0,"
  DEFM "50,150,64,52",$0D,"&",$11,$09
  DEFM "DEFB",$09,"73,71,50,82"
  DEFM ",78,71,0,174,82,"
  DEFM "4,78",$0D,"0",$11,$09,"DEFB",$09,"73,"
  DEFM "73,80,82,50,64,0"
  DEFM ",90,130,128,172",$0D
  DEFM ":",$11,$09,"DEFB",$09,"75,70,80"
  DEFM ",82,154,63,0,50,"
  DEFM "82,8,154",$0D,"D",$11,$09,"DEFB"
  DEFM $09,"76,70,154,82,15"
  DEFM "4,53,0,50,82,8,1"
  DEFM "54",$0D,"N",$11,$09,"DEFB",$09,"77,73"
  DEFM ",70,82,100,78,0,"
  DEFM "70,82,128,172",$0D,"X",$11
  DEFM $09,"DEFB",$09,"77,72,100,"
  DEFM "128,172,62,4,196"
  DEFM ",82,64,148",$0D,"b",$11,$09,"DE"
  DEFM "FB",$09,"78,72,70,82,1"
  DEFM "72,77,0,70,82,64"
  DEFM ",102",$0D,"l",$11,$09,"DEFB",$09,"78,"
  DEFM "75,50,150,50,17,"
  DEFM "0,100,200,128,17"
  DEFM "2",$0D,"v",$11,$09,"DEFB",$09,"80,82,"
  DEFM "110,200,154,51,0"
  DEFM ",110,52,16,110",$0D,$80
  DEFM $11,";STATIC OBJ",$0D,$8A,$11,$09
  DEFM "DEFB",$09,"3,49,0,150,"
  DEFM "80,100",$0D,$94,$11,$09,"DEFB",$09,"5"
  DEFM ",49,0,150,80,100"
  DEFM $0D,$9E,$11,$09,"DEFB",$09,"5,4"

; Play the loading tune until a key is pressed
;
; Used by the routine at START.
;
; Called once, from START, while the loading screen is still up: two voices on
; the beeper, a note at a time (TUNE_PLAY_NOTE), with the ROM's KEY-SCAN
; between notes. The voices' pointers are set from TUNE_VOICES first, so the
; tune starts from its beginning. The tune lasts 52.6 seconds (418 note bytes a
; voice, of which the last three rest in both and are passed over, so 415 notes
; heard, each 0.127 s; measured for the sounds page); after it both voices
; rest, and the routine goes on scanning the keyboard in silence.
;
; Interrupts are off while it plays (KEY-SCAN does not need them); it turns
; them on as it returns, and START turns them off again three instructions
; later, for good.
;
; From the first room on, these bytes are part of the clean copy of the screen
; (RESTOR copies the screen here), so the tune cannot be played again.
LOADING_TUNE:
  LD HL,TUNE_VOICES       ; Both voices to the start of the tune: the four
  LD DE,VOICE_ONE_AT      ; pointers from TUNE_VOICES.
  LD BC,$0008             ;
  LDIR                    ;
  DI                      ; Interrupts off while it plays.
LOADING_TUNE_0:
  CALL TUNE_PLAY_NOTE     ; Play a note (once both voices are resting,
                          ; nothing).
  CALL $028E              ; KEY-SCAN leaves E at $FF while no key is pressed.
  LD A,$FF                ;
  CP E                    ;
  JP Z,LOADING_TUNE_0     ;
  EI                      ; A key.
  RET                     ;

; The loading tune's variables
;
; Set by LOADING_TUNE and the player. On the tape, the pointers hold where the
; tune had got to when the tape was made; LOADING_TUNE sets them from
; TUNE_VOICES before it plays.
VOICE_ONE_NOTE:
  DEFB $02                ; Voice one's note, from TUNE_NEXT_NOTE
VOICE_TWO_NOTE:
  DEFB $29                ; Voice two's
TUNE_PORT:
  DEFB $00                ; What both voices send to port $FE before they
                          ; toggle the speaker bit: 0, the border black
VOICE_ONE_AT:
  DEFW $C11A,$C290        ; Voice one: the byte before its next note, and where
                          ; it goes back to at its end
VOICE_TWO_AT:
  DEFW $C2BE,$C434        ; Voice two: the same
NOTE_LENGTH:
  DEFB $EE                ; A note lasts 256 less this ($EE: 18) passes of 256
                          ; turns of the player's loop

; Take a voice's next note
;
; Used by the routine at TUNE_PLAY_NOTE.
;
; A voice's first word is the address of the note last played, and the byte
; after it is the next. $40 marks a voice's end; the voice then carries on from
; the address in its second word (TUNE_RESTART_VOICE), which for both voices is
; their last note, a rest, so the tune plays once and then rests for ever.
;
;   HL A voice's two words (at offset 3 or 7 of VOICE_ONE_NOTE)
; O:A The note
TUNE_NEXT_NOTE:
  LD E,(HL)               ; DE: the address after the note last played.
  INC HL                  ;
  LD D,(HL)               ;
  INC DE                  ;
; This entry point is used by the routine at TUNE_RESTART_VOICE.
TUNE_NEXT_NOTE_0:
  LD A,(DE)               ; The voice's end?
  CP $40                  ;
  JR Z,TUNE_RESTART_VOICE ;
  LD (HL),D               ; No: DE is the voice's place now.
  DEC HL                  ;
  LD (HL),E               ;
  RET                     ;

; Look up a note's pitch
;
; Used by the routine at TUNE_PLAY_NOTE.
;
; A note is a number of semitones, -12 to 40, or 41 for a rest. Twelve is added
; to it to index the table of pitches at offset 8 of TUNE_VOICES (TUNE_NOTES),
; which gives the number of turns of the player's loop between two toggles of
; the speaker bit. The rest's entry is 1: a toggle every turn, about 18 kHz,
; too high to be heard as a note; when both voices rest, TUNE_PLAY_NOTE plays
; nothing at all.
;
;   HL A voice's note (VOICE_ONE_NOTE or the byte after it)
; O:H Its pitch: the turns of the loop between two toggles
; O:L 1, the countdown to the first toggle
TUNE_PITCH:
  LD A,(HL)               ; The table, indexed by the note plus 12.
  ADD A,$0C               ;
  LD E,A                  ;
  LD D,$00                ;
  LD HL,TUNE_NOTES        ;
  ADD HL,DE               ;
  LD H,(HL)               ; H: the pitch; L: 1, so that the voice toggles on
  LD L,$01                ; the first turn.
  RET                     ;

; Send a voice back to where it repeats from
;
; Used by the routine at TUNE_NEXT_NOTE.
;
; Reached from TUNE_NEXT_NOTE at a voice's $40. It never ran in the build's
; sessions, which press a key long before the end of the tune; the sounds
; page's recording runs it.
;
; HL The high byte of the voice's first word
TUNE_RESTART_VOICE:
  INC HL                  ; DE: the address in the voice's second word; HL
  LD E,(HL)               ; back.
  INC HL                  ;
  LD D,(HL)               ;
  DEC HL                  ;
  DEC HL                  ;
  JR TUNE_NEXT_NOTE_0     ; Take the note there, the voice's last.

; Play one note of the loading tune
;
; Used by the routine at LOADING_TUNE.
;
; Both voices' next notes are taken and their pitches looked up. Unless both
; are resting, the note is played for 18 passes of 256 turns of a loop that
; sends a byte to the speaker's port twice a turn, one for each voice. Each
; voice keeps its own copy of the port byte (voice one's in A', voice two's in
; A) and its own countdown (E, and L), and toggles the speaker bit in its copy
; when the countdown runs out; so each is a square wave at its own pitch, and
; the two sound together. The two ways round the loop take the same time, 96
; T-states (the JR Z that never jumps and the NOPs pad the shorter), so neither
; voice's pitch depends on the other's.
;
; Once both voices rest, it returns at once. That never ran in the sessions
; (the sounds page's runs reach it), and nor did the end of a note by way of
; the first DJNZ: which of the two ends a note depends only on voice two's
; countdown in the note's last turn.
TUNE_PLAY_NOTE:
  LD HL,VOICE_ONE_AT      ; Voice one's next note.
  CALL TUNE_NEXT_NOTE     ;
  LD (VOICE_ONE_NOTE),A   ;
  LD HL,VOICE_TWO_AT      ; Voice two's.
  CALL TUNE_NEXT_NOTE     ;
  LD (VOICE_TWO_NOTE),A   ;
  LD HL,VOICE_ONE_NOTE    ; Voice one's pitch, on the stack.
  CALL TUNE_PITCH         ;
  PUSH HL                 ;
  LD HL,VOICE_TWO_NOTE    ; Voice two's: H its pitch, L its countdown; D and E
  CALL TUNE_PITCH         ; voice one's.
  POP DE                  ;
  LD A,H                  ; Both resting: nothing to play.
  CP $01                  ;
  JR NZ,TUNE_PLAY_NOTE_0  ;
  LD A,D                  ;
  CP $01                  ;
  RET Z                   ;
TUNE_PLAY_NOTE_0:
  LD A,(NOTE_LENGTH)      ; BC counts the note's turns: B 256 at a time, C up
  LD C,A                  ; from $EE to 0.
  LD B,$00                ;
  LD A,(TUNE_PORT)        ; Both voices start from the same port byte: voice
  EX AF,AF'               ; one's copy in A', voice two's in A.
  LD A,(TUNE_PORT)        ;
  LD IXH,D                ; Voice one's pitch in IXh, to reload its countdown
                          ; from.
  LD D,$10                ; D: the speaker bit (bit 4 of port $FE).
TUNE_PLAY_NOTE_1:
  NOP                     ; Padding.
  NOP                     ;
TUNE_PLAY_NOTE_2:
  EX AF,AF'               ; Voice one: its port byte out, and its countdown
  DEC E                   ; down; not run out, the other way round.
  OUT ($FE),A             ;
  JR NZ,TUNE_PLAY_NOTE_4  ;
  LD E,IXH                ; Run out: reload it, and toggle voice one's speaker
  XOR D                   ; bit.
  EX AF,AF'               ; Voice two: its countdown down; not run out, out
  DEC L                   ; with its port byte as it is.
  JP NZ,TUNE_PLAY_NOTE_5  ;
TUNE_PLAY_NOTE_3:
  OUT ($FE),A             ; Run out: out with voice two's port byte; reload its
  LD L,H                  ; countdown and toggle its speaker bit.
  XOR D                   ;
  DJNZ TUNE_PLAY_NOTE_1   ; Next turn; next 256; the note is over.
  INC C                   ;
  JP NZ,TUNE_PLAY_NOTE_2  ;
  RET                     ;
TUNE_PLAY_NOTE_4:
  JR Z,TUNE_PLAY_NOTE_4   ; As long as the reload above, and never jumps: Z is
                          ; clear here.
  EX AF,AF'               ; Voice two: its countdown down; run out, go and
  DEC L                   ; toggle it.
  JP Z,TUNE_PLAY_NOTE_3   ;
TUNE_PLAY_NOTE_5:
  OUT ($FE),A             ; Out with voice two's port byte, and padding.
  NOP                     ;
  NOP                     ;
  DJNZ TUNE_PLAY_NOTE_1   ; Next turn; next 256; the note is over.
  INC C                   ;
  JP NZ,TUNE_PLAY_NOTE_2  ;
  RET                     ;

; The loading tune: where the voices start, the pitches, and the two voices
;
; Four words first, copied to VOICE_ONE_NOTE by LOADING_TUNE: for each voice,
; the byte before its first note (never played) and the address it goes back to
; after its end marker, which is its own last note, a rest.
;
; From offset 8 (TUNE_NOTES), the table of pitches: 54 bytes, one for each note
; from -12 to 40 and the rest's 1. Each is the number of turns of the player's
; loop between two toggles of the speaker, $FF down to $0C, each about 0.944 of
; the one before: a semitone.
;
; From offset 63, voice one's 418 notes, and $40 to end them at offset 481;
; from offset 483, voice two's 418 and its $40 at offset 901. A note is a
; signed number of semitones ($FB is -5); 41 ($29) is a rest.
;
; From offset 902 to the end: leftover source text, the last lines of the
; object table's source (lines 4920-4940, with the DEFB 255 that ends the
; table), continuing the text at RECORDS, and ten bytes that are not text.
TUNE_VOICES:
  DEFW $C0EE,$C290        ; Voice one: its first note's address less one, and
  DEFW $C292,$C434        ; where it goes back to; then voice two's
TUNE_NOTES:
  DEFB $FF,$F0,$E3,$D7,$CB,$C0,$B4,$AB ; Pitches for the notes -12 to 35
  DEFB $A1,$97,$90,$88,$80,$79,$72,$6C ;
  DEFB $66,$60,$5B,$56,$51,$4C,$48,$44 ;
  DEFB $40,$3D,$39,$36,$33,$30,$2D,$2B ;
  DEFB $28,$26,$24,$22,$20,$1E,$1C,$1B ;
  DEFB $19,$18,$17,$15,$14,$13,$12,$11 ;
  DEFB $10,$0F,$0E,$0D,$0C,$01,$29,$13 ; Pitches for 36 to 40; 1, for the rest
                                       ; (41); the byte before voice one's
                                       ; first note; its first note
  DEFB $15,$0A,$0A,$0A,$0A,$0A,$0A,$0A ; Voice one
  DEFB $0A,$02,$02,$02,$02,$02,$02,$02 ;
  DEFB $02,$FE,$FE,$FE,$FE,$FE,$FE,$FE ;
  DEFB $FE,$05,$05,$05,$05,$05,$05,$05 ;
  DEFB $05,$07,$07,$07,$07,$07,$07,$07 ;
  DEFB $07,$02,$02,$02,$02,$02,$02,$02 ;
  DEFB $02,$07,$07,$07,$07,$07,$07,$07 ;
  DEFB $07,$03,$03,$03,$03,$02,$02,$02 ;
  DEFB $02,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F6,$F6,$F6,$F6,$F6,$29,$29 ;
  DEFB $29,$FE,$29,$29,$FE,$FE,$29,$00 ;
  DEFB $29,$F9,$F9,$F9,$F9,$F9,$29,$29 ;
  DEFB $29,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F6,$29,$29,$F6,$F6,$29,$FD ;
  DEFB $29,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F7,$FB,$FE,$03,$F6,$FA,$FD ;
  DEFB $02,$FB,$13,$13,$FB,$FB,$12,$FD ;
  DEFB $0F,$F6,$09,$05,$09,$02,$29,$13 ;
  DEFB $15,$FE,$16,$16,$FE,$FE,$15,$00 ;
  DEFB $13,$F9,$0C,$09,$0C,$05,$1D,$1F ;
  DEFB $21,$FB,$29,$22,$FB,$FB,$21,$FD ;
  DEFB $1F,$F6,$29,$21,$F6,$F6,$22,$FD ;
  DEFB $1E,$FB,$13,$29,$FB,$FB,$13,$FD ;
  DEFB $29,$F7,$FB,$FE,$FB,$F6,$FA,$FD ;
  DEFB $FA,$F9,$F9,$05,$05,$29,$29,$05 ;
  DEFB $05,$FE,$FE,$0A,$0A,$29,$29,$0A ;
  DEFB $0A,$03,$03,$0F,$0F,$29,$29,$0F ;
  DEFB $0F,$FE,$FE,$0A,$0A,$29,$29,$0A ;
  DEFB $0A,$F9,$F9,$05,$05,$29,$29,$05 ;
  DEFB $05,$FE,$FE,$0A,$0A,$29,$29,$0A ;
  DEFB $0A,$02,$02,$29,$29,$00,$00,$29 ;
  DEFB $29,$02,$0E,$00,$0C,$FE,$0A,$FD ;
  DEFB $09,$FB,$FB,$07,$16,$FA,$FA,$06 ;
  DEFB $15,$FB,$FB,$07,$16,$FD,$FD,$09 ;
  DEFB $1A,$FB,$FB,$07,$16,$FA,$FA,$06 ;
  DEFB $15,$FB,$FB,$07,$16,$FD,$FD,$16 ;
  DEFB $18,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F6,$29,$29,$29,$29,$29,$29 ;
  DEFB $29,$FE,$16,$16,$FE,$FE,$15,$00 ;
  DEFB $13,$F9,$0C,$09,$0C,$05,$29,$1F ;
  DEFB $21,$FB,$29,$22,$FB,$FB,$21,$FD ;
  DEFB $29,$F6,$29,$21,$F6,$F6,$22,$FD ;
  DEFB $1E,$FB,$13,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F7,$FB,$FE,$FB,$F6,$FA,$FD ;
  DEFB $02,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F6,$29,$29,$F6,$F6,$29,$FD ;
  DEFB $29,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$F7,$FB,$FE,$FB,$F6,$FA,$FD ;
  DEFB $02,$FB,$29,$13,$FB,$FB,$12,$FD ;
  DEFB $29,$F6,$29,$12,$F6,$F6,$13,$FD ;
  DEFB $29,$FB,$29,$29,$FB,$FB,$29,$FD ;
  DEFB $29,$FB,$FB,$FB,$FB,$FB,$29,$29 ;
  DEFB $29,$40,$29,$13,$15,$16,$16,$16 ; Voice one's last note (a rest, which
                                       ; it repeats after its end); its end
                                       ; marker; the byte before voice two's
                                       ; first note; its first five
  DEFB $16,$15,$15,$13,$13,$1A,$15,$11 ; Voice two
  DEFB $15,$0E,$0E,$16,$18,$1A,$1A,$1A ;
  DEFB $1A,$18,$18,$16,$16,$1D,$18,$15 ;
  DEFB $18,$11,$11,$13,$15,$16,$29,$16 ;
  DEFB $29,$16,$15,$13,$13,$15,$29,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$0F,$13,$16 ;
  DEFB $16,$0E,$15,$13,$15,$16,$16,$16 ;
  DEFB $16,$15,$15,$13,$13,$1A,$15,$11 ;
  DEFB $15,$0E,$0E,$16,$18,$1A,$1A,$1A ;
  DEFB $1A,$18,$18,$16,$16,$1D,$18,$15 ;
  DEFB $18,$11,$11,$13,$15,$16,$FB,$16 ;
  DEFB $29,$16,$15,$13,$13,$15,$F6,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$0F,$13,$16 ;
  DEFB $16,$0E,$15,$13,$15,$16,$16,$16 ;
  DEFB $16,$15,$15,$13,$13,$1A,$15,$11 ;
  DEFB $15,$0E,$0E,$16,$18,$1A,$1A,$1A ;
  DEFB $1A,$18,$18,$16,$16,$1D,$18,$15 ;
  DEFB $18,$11,$11,$13,$15,$16,$FB,$16 ;
  DEFB $29,$16,$15,$13,$13,$15,$F6,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$0F,$13,$16 ;
  DEFB $1B,$0E,$15,$13,$15,$11,$15,$1D ;
  DEFB $29,$1D,$1D,$1B,$29,$11,$16,$1A ;
  DEFB $29,$1A,$1A,$1A,$1A,$11,$18,$1B ;
  DEFB $29,$1D,$1D,$1B,$1B,$11,$16,$1A ;
  DEFB $29,$1A,$1A,$1A,$1A,$11,$15,$1D ;
  DEFB $29,$1D,$1D,$1B,$1B,$11,$16,$1A ;
  DEFB $29,$1A,$1A,$1A,$29,$1A,$1A,$1A ;
  DEFB $1A,$18,$18,$1A,$1B,$1A,$1A,$18 ;
  DEFB $18,$16,$16,$15,$15,$13,$16,$1A ;
  DEFB $16,$12,$15,$1A,$15,$13,$16,$1A ;
  DEFB $16,$12,$15,$1A,$1A,$13,$16,$1A ;
  DEFB $16,$12,$15,$1A,$15,$13,$16,$1A ;
  DEFB $16,$12,$15,$13,$15,$16,$16,$16 ;
  DEFB $16,$15,$15,$13,$13,$1A,$15,$11 ;
  DEFB $15,$0E,$0E,$16,$18,$1A,$1A,$1A ;
  DEFB $1A,$18,$18,$16,$16,$1D,$18,$15 ;
  DEFB $18,$11,$11,$13,$15,$16,$FB,$16 ;
  DEFB $29,$16,$15,$13,$13,$15,$F6,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$0F,$13,$16 ;
  DEFB $13,$0E,$15,$13,$15,$16,$FB,$16 ;
  DEFB $29,$16,$15,$13,$13,$15,$F6,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$0F,$13,$16 ;
  DEFB $1B,$0E,$15,$13,$15,$16,$FB,$16 ;
  DEFB $29,$16,$15,$13,$FD,$15,$F6,$15 ;
  DEFB $29,$15,$16,$15,$12,$13,$13,$13 ;
  DEFB $13,$13,$13,$13,$13,$13,$13,$13 ;
  DEFB $13,$13,$29,$29,$29,$40,$30,$2C ; Voice two's last notes and its end
                                       ; marker; the start of the leftover text
  DEFM "106,80,140",$0D,"8",$13,$09,"DE"
  DEFM "FB",$09,"73,22,0,106,8"
  DEFM "0,100",$0D,"B",$13,"*L+",$0D,"L",$13,$09,"D"
  DEFM "EFB",$09,"255",$0D,"j",$09,$00,$00,$00,$00,$00,$7F
  DEFM $7F,$7F,$7F,$7F

; The game's first instruction
;
; The loader returns here once it has checked its checksum and cleared itself.
; The stack goes near the top of SOURCE_AND_STACK; the loading tune plays until
; a key is pressed; IY is set to the variables, and interrupts turned off for
; the rest of the game; the object table and the templates are copied from
; where the tape has them to where the game reads them; a master copy of the
; object table, the variables and the knight's record is made at
; MASTER_OBJECTS, for each new game to start from; and the title page begins.
;
; The game runs with interrupts off from here on (measured: the interrupt
; flip-flop stays clear in the simulator, and the ROM's frame counter in its
; system variables never moves). It has to: the sprites from SPRITE5B00 up lie
; over the ROM's system variables, which the ROM's interrupt routine writes to
; fifty times a second.
START:
  LD HL,STACK_TOP         ; The stack: two bytes below the end of
  LD SP,HL                ; SOURCE_AND_STACK, over leftover source text.
  CALL LOADING_TUNE       ; The loading tune, until a key is pressed.
  LD IY,OBJECT_COUNT      ; IY at the variables, from here on.
  DI                      ; Interrupts off for good (the tune turned them on as
                          ; it returned).
  LD HL,OBJECTS_TAPE      ; The object table, and 263 bytes of text after it:
  LD DE,OBJECTS           ; 3420 bytes from OBJECTS_TAPE to OBJECTS.
  LD BC,$0D5C             ;
  LDIR                    ;
  LD HL,TEMPLATES_TAPE    ; The templates and the patches: 932 bytes from
  LD DE,TEMPLATES         ; TEMPLATES_TAPE to TEMPLATES.
  LD BC,$03A4             ;
  LDIR                    ;
  LD DE,MASTER_OBJECTS    ; The master copy: the object table's first 1200
  LD HL,OBJECTS           ; bytes...
  LD BC,$04B0             ;
  LDIR                    ;
  LD HL,OBJECT_COUNT      ; ...the 61 bytes of variables a new game starts with
  LD C,$3D                ; (IY+$00 to IY+$3C; B is 0 after the LDIR)...
  LDIR                    ;
  LD HL,KNIGHT            ; ...and the knight's record.
  LD C,$14                ;
  LDIR                    ;
  JP TITLE_SCREEN         ; The title page.

; Leftover source text
;
; Three lines of source text (12860-12870 and part of the line before), from
; code that stores into IY+$71 after an AND 5, with labels the author called
; BT32 and BT33: much like the code at MEET_DECOY by the AND 5 there, though
; not line for line the same. The text runs on, with gaps where the game's
; bytes lie, at SOURCE_AFTER_OBJECTS and SOURCE_AFTER_TEMPLATES.
SOURCE_AFTER_START:
  DEFM $09,"AND",$09,"5",$0D,$18,$09,"48",$0D,"<2BT"
  DEFM "32",$09,"LD",$09,"(T+13),A",$0D,"F"
  DEFM "2BT33",$09

; The object table, as the tape has it
;
; 381 records: 207 of six bytes and 174 of eleven.
OBJECTS_TAPE:
  DEFB $14,$0E,$20,$32,$44,$32 ; 1: room 20, type 14; 32, 50, 68, 50
  DEFB $48,$0E,$20,$5A,$3C,$96 ; 2: room 72, type 14; 32, 90, 60, 150
  DEFB $29,$0E,$20,$AA,$52,$A0 ; 3: room 41, type 14; 32, 170, 82, 160
  DEFB $38,$0E,$20,$3C,$48,$5A ; 4: room 56, type 14; 32, 60, 72, 90
  DEFB $21,$0F,$20,$32,$7A,$86 ; 5: room 33, type 15; 32, 50, 122, 134
  DEFB $2E,$0E,$20,$3C,$3E,$32 ; 6: room 46, type 14; 32, 60, 62, 50
  DEFB $0E,$32,$2B,$5A,$36,$5A ; 7: room 14, type 50; 43, 90, 54, 90
  DEFB $3D,$0E,$20,$3C,$44,$32 ; 8: room 61, type 14; 32, 60, 68, 50
  DEFB $0D,$04,$20,$64,$34,$44 ; 9: room 13, type 4; 32, 100, 52, 68
  DEFB $13,$15,$25,$7A,$54,$80 ; 10: room 19, type 21; 37, 122, 84, 128
  DEFB $14,$11,$28,$78,$3A,$96 ; 11: room 20, type 17; 40, 120, 58, 150
  DEFB $18,$22,$25,$82,$76,$A0 ; 12: room 24, type 34; 37, 130, 118, 160
  DEFB $1C,$1D,$26,$64,$5A,$64 ; 13: room 28, type 29; 38, 100, 90, 100
  DEFB $1D,$20,$29,$8C,$36,$6E ; 14: room 29, type 32; 41, 140, 54, 110
  DEFB $2C,$1D,$26,$46,$3A,$A8 ; 15: room 44, type 29; 38, 70, 58, 168
  DEFB $2D,$22,$25,$84,$42,$32 ; 16: room 45, type 34; 37, 132, 66, 50
  DEFB $2D,$22,$25,$82,$62,$6E ; 17: room 45, type 34; 37, 130, 98, 110
  DEFB $30,$15,$2A,$94,$34,$68 ; 18: room 48, type 21; 42, 148, 52, 104
  DEFB $31,$17,$20,$82,$54,$A0 ; 19: room 49, type 23; 32, 130, 84, 160
  DEFB $31,$17,$20,$6E,$54,$A0 ; 20: room 49, type 23; 32, 110, 84, 160
  DEFB $31,$17,$20,$50,$54,$A0 ; 21: room 49, type 23; 32, 80, 84, 160
  DEFB $32,$1D,$26,$6E,$3C,$32 ; 22: room 50, type 29; 38, 110, 60, 50
  DEFB $38,$22,$25,$42,$52,$58 ; 23: room 56, type 34; 37, 66, 82, 88
  DEFB $39,$15,$2A,$74,$5E,$A6 ; 24: room 57, type 21; 42, 116, 94, 166
  DEFB $47,$04,$20,$64,$44,$36 ; 25: room 71, type 4; 32, 100, 68, 54
  DEFB $47,$04,$20,$68,$46,$36 ; 26: room 71, type 4; 32, 104, 70, 54
  DEFB $47,$04,$20,$66,$48,$3A ; 27: room 71, type 4; 32, 102, 72, 58
  DEFB $02,$08,$20,$32,$48,$A0 ; 28: room 2, type 8; 32, 50, 72, 160
  DEFB $02,$08,$20,$32,$48,$92 ; 29: room 2, type 8; 32, 50, 72, 146
  DEFB $02,$08,$20,$40,$48,$92 ; 30: room 2, type 8; 32, 64, 72, 146
  DEFB $02,$08,$20,$32,$5E,$A0 ; 31: room 2, type 8; 32, 50, 94, 160
  DEFB $02,$00,$00,$8C,$40,$64 ; 32: room 2, type 0; 0, 140, 64, 100
  DEFB $02,$00,$00,$64,$40,$64 ; 33: room 2, type 0; 0, 100, 64, 100
  DEFB $02,$03,$20,$82,$3A,$6E ; 34: room 2, type 3; 32, 130, 58, 110
  DEFB $02,$03,$20,$5A,$3A,$72 ; 35: room 2, type 3; 32, 90, 58, 114
  DEFB $02,$03,$20,$66,$3A,$5A ; 36: room 2, type 3; 32, 102, 58, 90
  DEFB $02,$03,$20,$8E,$3A,$5A ; 37: room 2, type 3; 32, 142, 58, 90
  DEFB $02,$09,$24,$64,$4E,$64 ; 38: room 2, type 9; 36, 100, 78, 100
  DEFB $07,$08,$20,$32,$48,$A0 ; 39: room 7, type 8; 32, 50, 72, 160
  DEFB $07,$08,$20,$32,$48,$92 ; 40: room 7, type 8; 32, 50, 72, 146
  DEFB $07,$08,$20,$40,$48,$A0 ; 41: room 7, type 8; 32, 64, 72, 160
  DEFB $07,$08,$20,$40,$48,$92 ; 42: room 7, type 8; 32, 64, 72, 146
  DEFB $07,$08,$20,$32,$5E,$A0 ; 43: room 7, type 8; 32, 50, 94, 160
  DEFB $07,$11,$28,$32,$64,$A2 ; 44: room 7, type 17; 40, 50, 100, 162
  DEFB $0D,$25,$00,$6E,$4C,$5A ; 45: room 13, type 37; 0, 110, 76, 90
  DEFB $0D,$18,$00,$6E,$44,$5A ; 46: room 13, type 24; 0, 110, 68, 90
  DEFB $0E,$25,$00,$5A,$4C,$70 ; 47: room 14, type 37; 0, 90, 76, 112
  DEFB $0E,$12,$00,$58,$44,$6C ; 48: room 14, type 18; 0, 88, 68, 108
  DEFB $14,$1C,$20,$46,$4E,$32 ; 49: room 20, type 28; 32, 70, 78, 50
  DEFB $14,$00,$00,$8C,$40,$64 ; 50: room 20, type 0; 0, 140, 64, 100
  DEFB $14,$00,$00,$64,$40,$64 ; 51: room 20, type 0; 0, 100, 64, 100
  DEFB $14,$03,$20,$82,$3A,$6E ; 52: room 20, type 3; 32, 130, 58, 110
  DEFB $14,$03,$20,$5A,$3A,$72 ; 53: room 20, type 3; 32, 90, 58, 114
  DEFB $14,$03,$20,$66,$3A,$5A ; 54: room 20, type 3; 32, 102, 58, 90
  DEFB $14,$03,$20,$8E,$3A,$5A ; 55: room 20, type 3; 32, 142, 58, 90
  DEFB $14,$09,$24,$64,$4E,$64 ; 56: room 20, type 9; 36, 100, 78, 100
  DEFB $14,$09,$24,$8C,$4E,$64 ; 57: room 20, type 9; 36, 140, 78, 100
  DEFB $14,$1F,$24,$8E,$48,$6E ; 58: room 20, type 31; 36, 142, 72, 110
  DEFB $1A,$1C,$20,$D2,$3E,$8C ; 59: room 26, type 28; 32, 210, 62, 140
  DEFB $1A,$1C,$20,$C8,$3E,$78 ; 60: room 26, type 28; 32, 200, 62, 120
  DEFB $17,$08,$20,$32,$48,$64 ; 61: room 23, type 8; 32, 50, 72, 100
  DEFB $22,$08,$20,$32,$48,$A0 ; 62: room 34, type 8; 32, 50, 72, 160
  DEFB $22,$08,$20,$32,$48,$92 ; 63: room 34, type 8; 32, 50, 72, 146
  DEFB $22,$08,$20,$40,$48,$A0 ; 64: room 34, type 8; 32, 64, 72, 160
  DEFB $22,$08,$20,$40,$48,$92 ; 65: room 34, type 8; 32, 64, 72, 146
  DEFB $22,$08,$20,$32,$5E,$A0 ; 66: room 34, type 8; 32, 50, 94, 160
  DEFB $29,$00,$00,$78,$40,$8C ; 67: room 41, type 0; 0, 120, 64, 140
  DEFB $29,$09,$24,$78,$4E,$96 ; 68: room 41, type 9; 36, 120, 78, 150
  DEFB $29,$1E,$24,$50,$44,$8C ; 69: room 41, type 30; 36, 80, 68, 140
  DEFB $29,$00,$00,$50,$40,$8C ; 70: room 41, type 0; 0, 80, 64, 140
  DEFB $2B,$00,$00,$78,$40,$78 ; 71: room 43, type 0; 0, 120, 64, 120
  DEFB $2B,$00,$00,$50,$40,$78 ; 72: room 43, type 0; 0, 80, 64, 120
  DEFB $2B,$03,$20,$6E,$3A,$82 ; 73: room 43, type 3; 32, 110, 58, 130
  DEFB $2B,$03,$20,$46,$3A,$86 ; 74: room 43, type 3; 32, 70, 58, 134
  DEFB $2B,$03,$20,$52,$3A,$6E ; 75: room 43, type 3; 32, 82, 58, 110
  DEFB $2B,$03,$20,$7A,$3A,$6E ; 76: room 43, type 3; 32, 122, 58, 110
  DEFB $2C,$08,$20,$32,$48,$96 ; 77: room 44, type 8; 32, 50, 72, 150
  DEFB $2C,$08,$20,$40,$48,$96 ; 78: room 44, type 8; 32, 64, 72, 150
  DEFB $30,$2E,$00,$96,$44,$64 ; 79: room 48, type 46; 0, 150, 68, 100
  DEFB $31,$09,$24,$46,$54,$64 ; 80: room 49, type 9; 36, 70, 84, 100
  DEFB $31,$09,$24,$8C,$54,$46 ; 81: room 49, type 9; 36, 140, 84, 70
  DEFB $31,$1F,$24,$8E,$52,$50 ; 82: room 49, type 31; 36, 142, 82, 80
  DEFB $37,$08,$20,$32,$48,$6E ; 83: room 55, type 8; 32, 50, 72, 110
  DEFB $39,$08,$20,$32,$48,$82 ; 84: room 57, type 8; 32, 50, 72, 130
  DEFB $39,$09,$24,$32,$56,$86 ; 85: room 57, type 9; 36, 50, 86, 134
  DEFB $3D,$00,$00,$78,$40,$78 ; 86: room 61, type 0; 0, 120, 64, 120
  DEFB $3D,$00,$00,$50,$40,$78 ; 87: room 61, type 0; 0, 80, 64, 120
  DEFB $3D,$03,$20,$6E,$3A,$82 ; 88: room 61, type 3; 32, 110, 58, 130
  DEFB $3D,$03,$20,$46,$3A,$86 ; 89: room 61, type 3; 32, 70, 58, 134
  DEFB $40,$08,$20,$64,$48,$46 ; 90: room 64, type 8; 32, 100, 72, 70
  DEFB $40,$08,$20,$64,$48,$32 ; 91: room 64, type 8; 32, 100, 72, 50
  DEFB $40,$08,$20,$72,$48,$46 ; 92: room 64, type 8; 32, 114, 72, 70
  DEFB $40,$08,$20,$72,$48,$32 ; 93: room 64, type 8; 32, 114, 72, 50
  DEFB $40,$08,$20,$64,$5E,$46 ; 94: room 64, type 8; 32, 100, 94, 70
  DEFB $45,$1E,$24,$32,$44,$96 ; 95: room 69, type 30; 36, 50, 68, 150
  DEFB $45,$1E,$24,$32,$44,$82 ; 96: room 69, type 30; 36, 50, 68, 130
  DEFB $47,$00,$00,$46,$40,$62 ; 97: room 71, type 0; 0, 70, 64, 98
  DEFB $47,$00,$00,$78,$40,$64 ; 98: room 71, type 0; 0, 120, 64, 100
  DEFB $47,$03,$20,$6E,$3A,$50 ; 99: room 71, type 3; 32, 110, 58, 80
  DEFB $47,$03,$20,$32,$3A,$54 ; 100: room 71, type 3; 32, 50, 58, 84
  DEFB $47,$03,$20,$56,$3A,$64 ; 101: room 71, type 3; 32, 86, 58, 100
  DEFB $47,$03,$20,$88,$3A,$64 ; 102: room 71, type 3; 32, 136, 58, 100
  DEFB $48,$00,$00,$46,$40,$62 ; 103: room 72, type 0; 0, 70, 64, 98
  DEFB $48,$00,$00,$78,$40,$64 ; 104: room 72, type 0; 0, 120, 64, 100
  DEFB $48,$03,$20,$6E,$3A,$64 ; 105: room 72, type 3; 32, 110, 58, 100
  DEFB $48,$03,$20,$52,$3A,$5A ; 106: room 72, type 3; 32, 82, 58, 90
  DEFB $4B,$11,$28,$32,$38,$64 ; 107: room 75, type 17; 40, 50, 56, 100
  DEFB $4B,$11,$28,$3C,$38,$68 ; 108: room 75, type 17; 40, 60, 56, 104
  DEFB $4B,$11,$28,$36,$3E,$64 ; 109: room 75, type 17; 40, 54, 62, 100
  DEFB $02,$0D,$D0,$32,$50,$82 ; 110: room 2, type 13; 208, 50, 80, 130
  DEFB $03,$34,$C0,$50,$4C,$96 ; 111: room 3, type 52; 192, 80, 76, 150
  DEFB $05,$0D,$D0,$96,$50,$78 ; 112: room 5, type 13; 208, 150, 80, 120
  DEFB $07,$0D,$D0,$96,$50,$78 ; 113: room 7, type 13; 208, 150, 80, 120
  DEFB $08,$34,$C0,$64,$4C,$96 ; 114: room 8, type 52; 192, 100, 76, 150
  DEFB $09,$2D,$80,$96,$64,$78 ; 115: room 9, type 45; 128, 150, 100, 120
  DEFB $0C,$2D,$80,$96,$64,$78 ; 116: room 12, type 45; 128, 150, 100, 120
  DEFB $0F,$1B,$C0,$AA,$4A,$78 ; 117: room 15, type 27; 192, 170, 74, 120
  DEFB $10,$21,$C0,$A0,$4A,$9B ; 118: room 16, type 33; 192, 160, 74, 155
  DEFB $11,$0D,$D0,$36,$50,$78 ; 119: room 17, type 13; 208, 54, 80, 120
  DEFB $14,$1B,$C0,$32,$5E,$32 ; 120: room 20, type 27; 192, 50, 94, 50
  DEFB $16,$0D,$D0,$32,$50,$78 ; 121: room 22, type 13; 208, 50, 80, 120
  DEFB $1B,$0D,$D0,$32,$50,$78 ; 122: room 27, type 13; 208, 50, 80, 120
  DEFB $1C,$2D,$80,$A2,$50,$A0 ; 123: room 28, type 45; 128, 162, 80, 160
  DEFB $1C,$34,$C0,$50,$4C,$32 ; 124: room 28, type 52; 192, 80, 76, 50
  DEFB $1C,$34,$C0,$32,$4C,$64 ; 125: room 28, type 52; 192, 50, 76, 100
  DEFB $1D,$1A,$C0,$50,$78,$9B ; 126: room 29, type 26; 192, 80, 120, 155
  DEFB $1D,$34,$C0,$50,$4C,$32 ; 127: room 29, type 52; 192, 80, 76, 50
  DEFB $1F,$21,$C0,$A0,$4A,$9B ; 128: room 31, type 33; 192, 160, 74, 155
  DEFB $20,$34,$C0,$50,$4C,$32 ; 129: room 32, type 52; 192, 80, 76, 50
  DEFB $20,$34,$C0,$32,$4C,$64 ; 130: room 32, type 52; 192, 50, 76, 100
  DEFB $21,$21,$C0,$3C,$4A,$9B ; 131: room 33, type 33; 192, 60, 74, 155
  DEFB $22,$1B,$C0,$46,$62,$96 ; 132: room 34, type 27; 192, 70, 98, 150
  DEFB $24,$1A,$C0,$3C,$4A,$8C ; 133: room 36, type 26; 192, 60, 74, 140
  DEFB $24,$1A,$C0,$46,$4A,$78 ; 134: room 36, type 26; 192, 70, 74, 120
  DEFB $26,$1A,$C0,$46,$4A,$50 ; 135: room 38, type 26; 192, 70, 74, 80
  DEFB $27,$21,$C0,$B4,$4A,$9B ; 136: room 39, type 33; 192, 180, 74, 155
  DEFB $27,$21,$C0,$8C,$4A,$7D ; 137: room 39, type 33; 192, 140, 74, 125
  DEFB $28,$21,$C0,$A0,$4A,$9B ; 138: room 40, type 33; 192, 160, 74, 155
  DEFB $29,$1B,$C0,$3C,$4A,$9B ; 139: room 41, type 27; 192, 60, 74, 155
  DEFB $29,$1B,$C0,$82,$4A,$7D ; 140: room 41, type 27; 192, 130, 74, 125
  DEFB $2B,$1B,$C0,$50,$4A,$9B ; 141: room 43, type 27; 192, 80, 74, 155
  DEFB $2B,$1B,$C0,$82,$4A,$9B ; 142: room 43, type 27; 192, 130, 74, 155
  DEFB $2E,$21,$C0,$3C,$4A,$50 ; 143: room 46, type 33; 192, 60, 74, 80
  DEFB $30,$2D,$80,$5C,$50,$A0 ; 144: room 48, type 45; 128, 92, 80, 160
  DEFB $32,$34,$C0,$64,$4C,$96 ; 145: room 50, type 52; 192, 100, 76, 150
  DEFB $33,$34,$C0,$96,$4C,$78 ; 146: room 51, type 52; 192, 150, 76, 120
  DEFB $32,$34,$C0,$32,$4C,$64 ; 147: room 50, type 52; 192, 50, 76, 100
  DEFB $38,$2D,$80,$3E,$50,$A0 ; 148: room 56, type 45; 128, 62, 80, 160
  DEFB $39,$2D,$80,$5C,$7C,$A4 ; 149: room 57, type 45; 128, 92, 124, 164
  DEFB $3A,$2D,$80,$5C,$7C,$A4 ; 150: room 58, type 45; 128, 92, 124, 164
  DEFB $3B,$2D,$80,$5C,$7C,$A4 ; 151: room 59, type 45; 128, 92, 124, 164
  DEFB $3C,$21,$C0,$32,$4A,$7D ; 152: room 60, type 33; 192, 50, 74, 125
  DEFB $3C,$21,$C0,$46,$4A,$64 ; 153: room 60, type 33; 192, 70, 74, 100
  DEFB $3D,$38,$80,$5C,$50,$A4 ; 154: room 61, type 56; 128, 92, 80, 164
  DEFB $42,$21,$C0,$46,$4A,$64 ; 155: room 66, type 33; 192, 70, 74, 100
  DEFB $44,$2D,$80,$3E,$50,$82 ; 156: room 68, type 45; 128, 62, 80, 130
  DEFB $47,$1B,$C0,$96,$4A,$7D ; 157: room 71, type 27; 192, 150, 74, 125
  DEFB $48,$1B,$C0,$6E,$4A,$7D ; 158: room 72, type 27; 192, 110, 74, 125
  DEFB $49,$1A,$C0,$46,$4A,$50 ; 159: room 73, type 26; 192, 70, 74, 80
  DEFB $4D,$1A,$C0,$46,$4A,$6E ; 160: room 77, type 26; 192, 70, 74, 110
  DEFB $4E,$1A,$C0,$3C,$4A,$8C ; 161: room 78, type 26; 192, 60, 74, 140
  DEFB $4E,$1A,$C0,$46,$4A,$78 ; 162: room 78, type 26; 192, 70, 74, 120
  DEFB $4E,$1A,$C0,$5A,$4A,$50 ; 163: room 78, type 26; 192, 90, 74, 80
  DEFB $02,$46,$B2,$62,$96,$32,$00,$34,$56,$08,$32 ; 164: room 2, type 70; 178,
                                                   ; 98, 150, 50, 0, 52, 86, 8,
                                                   ; 50
  DEFB $02,$48,$66,$52,$AC,$45,$00,$78,$52,$40,$58 ; 165: room 2, type 72; 102,
                                                   ; 82, 172, 69, 0, 120, 82,
                                                   ; 64, 88
  DEFB $4A,$4A,$E6,$96,$82,$03,$00,$32,$96,$08,$82 ; 166: room 74, type 74;
                                                   ; 230, 150, 130, 3, 0, 50,
                                                   ; 150, 8, 130
  DEFB $03,$4A,$BC,$64,$96,$06,$00,$32,$64,$08,$82 ; 167: room 3, type 74; 188,
                                                   ; 100, 150, 6, 0, 50, 100,
                                                   ; 8, 130
  DEFB $03,$4B,$96,$96,$48,$04,$00,$46,$96,$80,$B8 ; 168: room 3, type 75; 150,
                                                   ; 150, 72, 4, 0, 70, 150,
                                                   ; 128, 184
  DEFB $03,$4A,$30,$96,$88,$4A,$00,$E6,$96,$04,$82 ; 169: room 3, type 74; 48,
                                                   ; 150, 136, 74, 0, 230, 150,
                                                   ; 4, 130
  DEFB $04,$4B,$46,$96,$32,$05,$00,$64,$96,$80,$D8 ; 170: room 4, type 75; 70,
                                                   ; 150, 50, 5, 0, 100, 150,
                                                   ; 128, 216
  DEFB $04,$4B,$46,$96,$B8,$03,$00,$96,$96,$40,$4A ; 171: room 4, type 75; 70,
                                                   ; 150, 184, 3, 0, 150, 150,
                                                   ; 64, 74
  DEFB $04,$51,$76,$64,$7E,$0D,$05,$32,$64,$08,$60 ; 172: room 4, type 81; 118,
                                                   ; 100, 126, 13, 5, 50, 100,
                                                   ; 8, 96
  DEFB $05,$4B,$64,$96,$DE,$04,$00,$46,$96,$40,$32 ; 173: room 5, type 75; 100,
                                                   ; 150, 222, 4, 0, 70, 150,
                                                   ; 64, 50
  DEFB $06,$4A,$32,$64,$82,$03,$00,$B0,$64,$04,$96 ; 174: room 6, type 74; 50,
                                                   ; 100, 130, 3, 0, 176, 100,
                                                   ; 4, 150
  DEFB $06,$4B,$8C,$96,$AE,$07,$00,$84,$96,$40,$32 ; 175: room 6, type 75; 140,
                                                   ; 150, 174, 7, 0, 132, 150,
                                                   ; 64, 50
  DEFB $06,$51,$E6,$64,$92,$08,$00,$32,$64,$08,$50 ; 176: room 6, type 81; 230,
                                                   ; 100, 146, 8, 0, 50, 100,
                                                   ; 8, 80
  DEFB $07,$51,$B0,$64,$92,$08,$00,$32,$64,$08,$90 ; 177: room 7, type 81; 176,
                                                   ; 100, 146, 8, 0, 50, 100,
                                                   ; 8, 144
  DEFB $07,$4B,$84,$96,$30,$06,$00,$8C,$96,$80,$AE ; 178: room 7, type 75; 132,
                                                   ; 150, 48, 6, 0, 140, 150,
                                                   ; 128, 174
  DEFB $08,$51,$B0,$64,$92,$09,$00,$46,$78,$08,$60 ; 179: room 8, type 81; 176,
                                                   ; 100, 146, 9, 0, 70, 120,
                                                   ; 8, 96
  DEFB $08,$51,$30,$64,$92,$07,$00,$B0,$64,$04,$90 ; 180: room 8, type 81; 48,
                                                   ; 100, 146, 7, 0, 176, 100,
                                                   ; 4, 144
  DEFB $08,$51,$30,$64,$50,$06,$00,$E6,$64,$04,$90 ; 181: room 8, type 81; 48,
                                                   ; 100, 80, 6, 0, 230, 100,
                                                   ; 4, 144
  DEFB $08,$4B,$82,$64,$30,$0A,$00,$32,$64,$80,$AE ; 182: room 8, type 75; 130,
                                                   ; 100, 48, 10, 0, 50, 100,
                                                   ; 128, 174
  DEFB $09,$51,$B0,$78,$60,$12,$00,$3C,$64,$08,$80 ; 183: room 9, type 81; 176,
                                                   ; 120, 96, 18, 0, 60, 100,
                                                   ; 8, 128
  DEFB $09,$51,$46,$78,$60,$08,$00,$B0,$64,$04,$92 ; 184: room 9, type 81; 70,
                                                   ; 120, 96, 8, 0, 176, 100,
                                                   ; 4, 146
  DEFB $0A,$54,$32,$34,$2C,$00,$00,$14,$14,$20,$14 ; 185: room 10, type 84; 50,
                                                   ; 52, 44, 0, 0, 20, 20, 32,
                                                   ; 20
  DEFB $0A,$4B,$32,$96,$30,$0B,$00,$32,$96,$80,$AE ; 186: room 10, type 75; 50,
                                                   ; 150, 48, 11, 0, 50, 150,
                                                   ; 128, 174
  DEFB $0A,$4B,$32,$96,$AE,$08,$00,$84,$96,$40,$32 ; 187: room 10, type 75; 50,
                                                   ; 150, 174, 8, 0, 132, 150,
                                                   ; 64, 50
  DEFB $0B,$4B,$32,$96,$AE,$0A,$00,$32,$96,$40,$32 ; 188: room 11, type 75; 50,
                                                   ; 150, 174, 10, 0, 50, 150,
                                                   ; 64, 50
  DEFB $0B,$51,$70,$64,$32,$0C,$00,$46,$78,$08,$60 ; 189: room 11, type 81;
                                                   ; 112, 100, 50, 12, 0, 70,
                                                   ; 120, 8, 96
  DEFB $0C,$51,$B0,$78,$60,$0F,$00,$3C,$64,$08,$80 ; 190: room 12, type 81;
                                                   ; 176, 120, 96, 15, 0, 60,
                                                   ; 100, 8, 128
  DEFB $0C,$51,$46,$78,$60,$0B,$00,$6E,$64,$04,$32 ; 191: room 12, type 81; 70,
                                                   ; 120, 96, 11, 0, 110, 100,
                                                   ; 4, 50
  DEFB $0D,$50,$6E,$34,$5A,$0E,$00,$46,$8C,$20,$78 ; 192: room 13, type 80;
                                                   ; 110, 52, 90, 14, 0, 70,
                                                   ; 140, 32, 120
  DEFB $0D,$47,$32,$52,$64,$04,$00,$76,$52,$04,$7E ; 193: room 13, type 71; 50,
                                                   ; 82, 100, 4, 0, 118, 82, 4,
                                                   ; 126
  DEFB $0E,$49,$78,$52,$9A,$0A,$00,$46,$64,$80,$82 ; 194: room 14, type 73;
                                                   ; 120, 82, 154, 10, 0, 70,
                                                   ; 100, 128, 130
  DEFB $0F,$4A,$E6,$96,$5E,$13,$00,$34,$96,$08,$5E ; 195: room 15, type 74;
                                                   ; 230, 150, 94, 19, 0, 52,
                                                   ; 150, 8, 94
  DEFB $0F,$51,$32,$64,$80,$0C,$00,$AE,$78,$04,$60 ; 196: room 15, type 81; 50,
                                                   ; 100, 128, 12, 0, 174, 120,
                                                   ; 4, 96
  DEFB $10,$4A,$E6,$96,$5E,$11,$00,$34,$96,$08,$5E ; 197: room 16, type 74;
                                                   ; 230, 150, 94, 17, 0, 52,
                                                   ; 150, 8, 94
  DEFB $10,$4A,$32,$96,$5E,$13,$00,$E6,$96,$04,$5E ; 198: room 16, type 74; 50,
                                                   ; 150, 94, 19, 0, 230, 150,
                                                   ; 4, 94
  DEFB $11,$4B,$64,$C8,$AE,$4E,$00,$32,$96,$40,$32 ; 199: room 17, type 75;
                                                   ; 100, 200, 174, 78, 0, 50,
                                                   ; 150, 64, 50
  DEFB $11,$4A,$32,$96,$5E,$10,$00,$E6,$96,$04,$5E ; 200: room 17, type 74; 50,
                                                   ; 150, 94, 16, 0, 230, 150,
                                                   ; 4, 94
  DEFB $12,$51,$32,$64,$80,$09,$00,$AE,$78,$04,$60 ; 201: room 18, type 81; 50,
                                                   ; 100, 128, 9, 0, 174, 120,
                                                   ; 4, 96
  DEFB $12,$4A,$E6,$96,$5E,$15,$00,$34,$96,$08,$5E ; 202: room 18, type 74;
                                                   ; 230, 150, 94, 21, 0, 52,
                                                   ; 150, 8, 94
  DEFB $13,$4A,$E6,$96,$5E,$10,$00,$34,$96,$08,$5E ; 203: room 19, type 74;
                                                   ; 230, 150, 94, 16, 0, 52,
                                                   ; 150, 8, 94
  DEFB $13,$4A,$32,$96,$5E,$0F,$00,$E6,$96,$04,$5E ; 204: room 19, type 74; 50,
                                                   ; 150, 94, 15, 0, 230, 150,
                                                   ; 4, 94
  DEFB $14,$48,$78,$52,$AC,$15,$00,$78,$52,$40,$6A ; 205: room 20, type 72;
                                                   ; 120, 82, 172, 21, 0, 120,
                                                   ; 82, 64, 106
  DEFB $15,$4A,$32,$96,$5E,$12,$00,$E6,$96,$04,$5E ; 206: room 21, type 74; 50,
                                                   ; 150, 94, 18, 0, 230, 150,
                                                   ; 4, 94
  DEFB $15,$48,$BE,$52,$AC,$16,$01,$78,$52,$40,$56 ; 207: room 21, type 72;
                                                   ; 190, 82, 172, 22, 1, 120,
                                                   ; 82, 64, 86
  DEFB $15,$49,$78,$52,$66,$14,$00,$78,$52,$80,$AC ; 208: room 21, type 73;
                                                   ; 120, 82, 102, 20, 0, 120,
                                                   ; 82, 128, 172
  DEFB $15,$4A,$E6,$96,$5E,$19,$00,$34,$96,$08,$5E ; 209: room 21, type 74;
                                                   ; 230, 150, 94, 25, 0, 52,
                                                   ; 150, 8, 94
  DEFB $16,$49,$78,$52,$54,$15,$01,$BE,$52,$80,$AC ; 210: room 22, type 73;
                                                   ; 120, 82, 84, 21, 1, 190,
                                                   ; 82, 128, 172
  DEFB $17,$49,$78,$52,$54,$19,$01,$BE,$52,$80,$AC ; 211: room 23, type 73;
                                                   ; 120, 82, 84, 25, 1, 190,
                                                   ; 82, 128, 172
  DEFB $18,$49,$78,$52,$54,$1A,$01,$BE,$52,$80,$AC ; 212: room 24, type 73;
                                                   ; 120, 82, 84, 26, 1, 190,
                                                   ; 82, 128, 172
  DEFB $19,$48,$BE,$52,$AC,$17,$01,$78,$52,$40,$56 ; 213: room 25, type 72;
                                                   ; 190, 82, 172, 23, 1, 120,
                                                   ; 82, 64, 86
  DEFB $19,$4A,$32,$96,$5E,$15,$00,$E6,$96,$04,$5E ; 214: room 25, type 74; 50,
                                                   ; 150, 94, 21, 0, 230, 150,
                                                   ; 4, 94
  DEFB $19,$4A,$E6,$96,$5E,$1A,$00,$34,$96,$08,$5E ; 215: room 25, type 74;
                                                   ; 230, 150, 94, 26, 0, 52,
                                                   ; 150, 8, 94
  DEFB $1A,$48,$BE,$52,$AC,$18,$01,$78,$52,$40,$56 ; 216: room 26, type 72;
                                                   ; 190, 82, 172, 24, 1, 120,
                                                   ; 82, 64, 86
  DEFB $1A,$4A,$32,$96,$5E,$19,$00,$E6,$96,$04,$5E ; 217: room 26, type 74; 50,
                                                   ; 150, 94, 25, 0, 230, 150,
                                                   ; 4, 94
  DEFB $1A,$4C,$C4,$96,$66,$1B,$00,$32,$96,$80,$AC ; 218: room 26, type 76;
                                                   ; 196, 150, 102, 27, 0, 50,
                                                   ; 150, 128, 172
  DEFB $1B,$4C,$32,$96,$AE,$1A,$00,$C4,$96,$40,$6A ; 219: room 27, type 76; 50,
                                                   ; 150, 174, 26, 0, 196, 150,
                                                   ; 64, 106
  DEFB $1B,$4E,$B4,$74,$8C,$22,$00,$78,$32,$10,$3C ; 220: room 27, type 78;
                                                   ; 180, 116, 140, 34, 0, 120,
                                                   ; 50, 16, 60
  DEFB $1B,$49,$32,$52,$66,$1C,$00,$64,$52,$80,$AC ; 221: room 27, type 73; 50,
                                                   ; 82, 102, 28, 0, 100, 82,
                                                   ; 128, 172
  DEFB $1C,$48,$64,$52,$AC,$1B,$00,$32,$52,$40,$68 ; 222: room 28, type 72;
                                                   ; 100, 82, 172, 27, 0, 50,
                                                   ; 82, 64, 104
  DEFB $1D,$4B,$32,$96,$30,$1E,$00,$32,$96,$80,$AC ; 223: room 29, type 75; 50,
                                                   ; 150, 48, 30, 0, 50, 150,
                                                   ; 128, 172
  DEFB $1D,$47,$32,$7A,$98,$22,$00,$AC,$62,$04,$98 ; 224: room 29, type 71; 50,
                                                   ; 122, 152, 34, 0, 172, 98,
                                                   ; 4, 152
  DEFB $1D,$46,$80,$7A,$98,$36,$00,$34,$52,$08,$98 ; 225: room 29, type 70;
                                                   ; 128, 122, 152, 54, 0, 52,
                                                   ; 82, 8, 152
  DEFB $1D,$48,$8C,$52,$7C,$35,$00,$3C,$52,$40,$68 ; 226: room 29, type 72;
                                                   ; 140, 82, 124, 53, 0, 60,
                                                   ; 82, 64, 104
  DEFB $1E,$4B,$32,$96,$30,$1F,$00,$32,$96,$80,$AC ; 227: room 30, type 75; 50,
                                                   ; 150, 48, 31, 0, 50, 150,
                                                   ; 128, 172
  DEFB $1E,$4B,$32,$96,$AE,$1D,$00,$32,$96,$40,$34 ; 228: room 30, type 75; 50,
                                                   ; 150, 174, 29, 0, 50, 150,
                                                   ; 64, 52
  DEFB $1E,$4A,$30,$96,$32,$20,$00,$B0,$96,$04,$32 ; 229: room 30, type 74; 48,
                                                   ; 150, 50, 32, 0, 176, 150,
                                                   ; 4, 50
  DEFB $1F,$4B,$32,$96,$AE,$1E,$00,$32,$96,$40,$34 ; 230: room 31, type 75; 50,
                                                   ; 150, 174, 30, 0, 50, 150,
                                                   ; 64, 52
  DEFB $1F,$4A,$30,$96,$32,$21,$00,$B0,$96,$04,$32 ; 231: room 31, type 74; 48,
                                                   ; 150, 50, 33, 0, 176, 150,
                                                   ; 4, 50
  DEFB $1F,$51,$B0,$64,$46,$51,$08,$3C,$64,$08,$80 ; 232: room 31, type 81;
                                                   ; 176, 100, 70, 81, 8, 60,
                                                   ; 100, 8, 128
  DEFB $20,$4B,$32,$96,$30,$21,$00,$32,$96,$80,$AC ; 233: room 32, type 75; 50,
                                                   ; 150, 48, 33, 0, 50, 150,
                                                   ; 128, 172
  DEFB $20,$4A,$B2,$96,$32,$1E,$00,$34,$96,$08,$32 ; 234: room 32, type 74;
                                                   ; 178, 150, 50, 30, 0, 52,
                                                   ; 150, 8, 50
  DEFB $21,$51,$32,$64,$80,$25,$00,$70,$64,$04,$84 ; 235: room 33, type 81; 50,
                                                   ; 100, 128, 37, 0, 112, 100,
                                                   ; 4, 132
  DEFB $21,$4B,$32,$96,$AE,$20,$00,$32,$96,$40,$34 ; 236: room 33, type 75; 50,
                                                   ; 150, 174, 32, 0, 50, 150,
                                                   ; 64, 52
  DEFB $21,$4A,$B2,$96,$32,$1F,$00,$34,$96,$08,$32 ; 237: room 33, type 74;
                                                   ; 178, 150, 50, 31, 0, 52,
                                                   ; 150, 8, 50
  DEFB $22,$46,$B0,$62,$98,$1D,$00,$34,$7C,$08,$98 ; 238: room 34, type 70;
                                                   ; 176, 98, 152, 29, 0, 52,
                                                   ; 124, 8, 152
  DEFB $22,$47,$32,$52,$50,$23,$00,$6E,$52,$04,$56 ; 239: room 34, type 71; 50,
                                                   ; 82, 80, 35, 0, 110, 82, 4,
                                                   ; 86
  DEFB $22,$4E,$64,$34,$32,$1B,$00,$AA,$74,$20,$82 ; 240: room 34, type 78;
                                                   ; 100, 52, 50, 27, 0, 170,
                                                   ; 116, 32, 130
  DEFB $23,$46,$6E,$52,$56,$22,$00,$34,$52,$08,$50 ; 241: room 35, type 70;
                                                   ; 110, 82, 86, 34, 0, 52,
                                                   ; 82, 8, 80
  DEFB $23,$4B,$32,$96,$32,$24,$00,$32,$96,$80,$AC ; 242: room 35, type 75; 50,
                                                   ; 150, 50, 36, 0, 50, 150,
                                                   ; 128, 172
  DEFB $24,$4B,$32,$96,$AC,$23,$00,$32,$96,$40,$34 ; 243: room 36, type 75; 50,
                                                   ; 150, 172, 35, 0, 50, 150,
                                                   ; 64, 52
  DEFB $24,$4B,$32,$96,$32,$25,$00,$32,$96,$80,$AC ; 244: room 36, type 75; 50,
                                                   ; 150, 50, 37, 0, 50, 150,
                                                   ; 128, 172
  DEFB $25,$51,$70,$64,$82,$21,$00,$3C,$64,$08,$80 ; 245: room 37, type 81;
                                                   ; 112, 100, 130, 33, 0, 60,
                                                   ; 100, 8, 128
  DEFB $25,$4B,$32,$96,$AC,$24,$00,$32,$96,$40,$34 ; 246: room 37, type 75; 50,
                                                   ; 150, 172, 36, 0, 50, 150,
                                                   ; 64, 52
  DEFB $25,$4B,$32,$96,$32,$26,$00,$32,$96,$80,$AC ; 247: room 37, type 75; 50,
                                                   ; 150, 50, 38, 0, 50, 150,
                                                   ; 128, 172
  DEFB $25,$47,$32,$52,$96,$2F,$00,$AE,$52,$04,$64 ; 248: room 37, type 71; 50,
                                                   ; 82, 150, 47, 0, 174, 82,
                                                   ; 4, 100
  DEFB $26,$4B,$32,$96,$AE,$25,$00,$32,$96,$40,$34 ; 249: room 38, type 75; 50,
                                                   ; 150, 174, 37, 0, 50, 150,
                                                   ; 64, 52
  DEFB $26,$4A,$70,$96,$64,$27,$00,$34,$96,$08,$64 ; 250: room 38, type 74;
                                                   ; 112, 150, 100, 39, 0, 52,
                                                   ; 150, 8, 100
  DEFB $26,$49,$46,$52,$30,$3E,$00,$C8,$52,$80,$AC ; 251: room 38, type 73; 70,
                                                   ; 82, 48, 62, 0, 200, 82,
                                                   ; 128, 172
  DEFB $27,$4A,$32,$96,$64,$26,$00,$70,$96,$04,$64 ; 252: room 39, type 74; 50,
                                                   ; 150, 100, 38, 0, 112, 150,
                                                   ; 4, 100
  DEFB $27,$4A,$E6,$96,$64,$28,$00,$34,$96,$08,$64 ; 253: room 39, type 74;
                                                   ; 230, 150, 100, 40, 0, 52,
                                                   ; 150, 8, 100
  DEFB $27,$49,$3C,$52,$68,$2A,$03,$32,$52,$80,$AC ; 254: room 39, type 73; 60,
                                                   ; 82, 104, 42, 3, 50, 82,
                                                   ; 128, 172
  DEFB $28,$4A,$32,$96,$64,$27,$00,$E6,$96,$04,$64 ; 255: room 40, type 74; 50,
                                                   ; 150, 100, 39, 0, 230, 150,
                                                   ; 4, 100
  DEFB $28,$49,$78,$52,$68,$29,$00,$64,$52,$80,$AC ; 256: room 40, type 73;
                                                   ; 120, 82, 104, 41, 0, 100,
                                                   ; 82, 128, 172
  DEFB $29,$48,$64,$52,$AA,$28,$00,$78,$52,$40,$6C ; 257: room 41, type 72;
                                                   ; 100, 82, 170, 40, 0, 120,
                                                   ; 82, 64, 108
  DEFB $2A,$48,$34,$52,$AC,$27,$03,$3C,$52,$40,$6C ; 258: room 42, type 72; 52,
                                                   ; 82, 172, 39, 3, 60, 82,
                                                   ; 64, 108
  DEFB $2A,$46,$4E,$52,$6C,$2B,$00,$34,$52,$08,$6C ; 259: room 42, type 70; 78,
                                                   ; 82, 108, 43, 0, 52, 82, 8,
                                                   ; 108
  DEFB $2A,$49,$36,$52,$4C,$2D,$03,$3C,$52,$80,$AC ; 260: room 42, type 73; 54,
                                                   ; 82, 76, 45, 3, 60, 82,
                                                   ; 128, 172
  DEFB $2B,$47,$32,$52,$6C,$2A,$00,$4E,$52,$04,$6C ; 261: room 43, type 71; 50,
                                                   ; 82, 108, 42, 0, 78, 82, 4,
                                                   ; 108
  DEFB $2B,$48,$5A,$52,$4E,$2C,$00,$5A,$52,$80,$AC ; 262: room 43, type 72; 90,
                                                   ; 82, 78, 44, 0, 90, 82,
                                                   ; 128, 172
  DEFB $2C,$48,$5A,$52,$AC,$2B,$00,$5A,$52,$40,$50 ; 263: room 44, type 72; 90,
                                                   ; 82, 172, 43, 0, 90, 82,
                                                   ; 64, 80
  DEFB $2D,$4A,$36,$96,$32,$2E,$00,$AE,$96,$04,$32 ; 264: room 45, type 74; 54,
                                                   ; 150, 50, 46, 0, 174, 150,
                                                   ; 4, 50
  DEFB $2D,$48,$3C,$52,$AE,$2A,$03,$36,$52,$40,$52 ; 265: room 45, type 72; 60,
                                                   ; 82, 174, 42, 3, 54, 82,
                                                   ; 64, 82
  DEFB $2E,$4A,$AE,$96,$32,$2D,$00,$3A,$96,$08,$32 ; 266: room 46, type 74;
                                                   ; 174, 150, 50, 45, 0, 58,
                                                   ; 150, 8, 50
  DEFB $2E,$48,$5A,$52,$84,$39,$06,$50,$52,$40,$6C ; 267: room 46, type 72; 90,
                                                   ; 82, 132, 57, 6, 80, 82,
                                                   ; 64, 108
  DEFB $2E,$51,$3A,$64,$6A,$34,$00,$50,$64,$04,$72 ; 268: room 46, type 81; 58,
                                                   ; 100, 106, 52, 0, 80, 100,
                                                   ; 4, 114
  DEFB $2F,$48,$64,$52,$AC,$30,$00,$64,$52,$40,$34 ; 269: room 47, type 72;
                                                   ; 100, 82, 172, 48, 0, 100,
                                                   ; 82, 64, 52
  DEFB $2F,$47,$32,$52,$64,$32,$00,$AE,$52,$04,$64 ; 270: room 47, type 71; 50,
                                                   ; 82, 100, 50, 0, 174, 82,
                                                   ; 4, 100
  DEFB $2F,$46,$AE,$52,$64,$25,$00,$34,$52,$08,$96 ; 271: room 47, type 70;
                                                   ; 174, 82, 100, 37, 0, 52,
                                                   ; 82, 8, 150
  DEFB $30,$47,$32,$52,$64,$31,$00,$AE,$52,$04,$64 ; 272: room 48, type 71; 50,
                                                   ; 82, 100, 49, 0, 174, 82,
                                                   ; 4, 100
  DEFB $30,$49,$64,$52,$32,$2F,$00,$64,$52,$80,$AC ; 273: room 48, type 73;
                                                   ; 100, 82, 50, 47, 0, 100,
                                                   ; 82, 128, 172
  DEFB $31,$49,$64,$52,$32,$32,$00,$64,$52,$80,$AC ; 274: room 49, type 73;
                                                   ; 100, 82, 50, 50, 0, 100,
                                                   ; 82, 128, 172
  DEFB $31,$46,$AE,$52,$64,$30,$00,$34,$52,$08,$64 ; 275: room 49, type 70;
                                                   ; 174, 82, 100, 48, 0, 52,
                                                   ; 82, 8, 100
  DEFB $32,$48,$64,$52,$AC,$31,$00,$64,$52,$40,$34 ; 276: room 50, type 72;
                                                   ; 100, 82, 172, 49, 0, 100,
                                                   ; 82, 64, 52
  DEFB $32,$46,$AE,$52,$64,$2F,$00,$34,$52,$08,$64 ; 277: room 50, type 70;
                                                   ; 174, 82, 100, 47, 0, 52,
                                                   ; 82, 8, 100
  DEFB $32,$47,$32,$52,$32,$02,$00,$AE,$66,$04,$96 ; 278: room 50, type 71; 50,
                                                   ; 82, 50, 2, 0, 174, 102, 4,
                                                   ; 150
  DEFB $32,$48,$96,$52,$30,$3F,$00,$5A,$52,$80,$AE ; 279: room 50, type 72;
                                                   ; 150, 82, 48, 63, 0, 90,
                                                   ; 82, 128, 174
  DEFB $33,$50,$6E,$34,$78,$50,$00,$38,$B4,$20,$9C ; 280: room 51, type 80;
                                                   ; 110, 52, 120, 80, 0, 56,
                                                   ; 180, 32, 156
  DEFB $33,$53,$96,$64,$30,$34,$00,$32,$64,$80,$AE ; 281: room 51, type 83;
                                                   ; 150, 100, 48, 52, 0, 50,
                                                   ; 100, 128, 174
  DEFB $33,$51,$B2,$64,$92,$3E,$00,$34,$64,$08,$92 ; 282: room 51, type 81;
                                                   ; 178, 100, 146, 62, 0, 52,
                                                   ; 100, 8, 146
  DEFB $34,$51,$50,$64,$72,$2E,$00,$3C,$64,$08,$6A ; 283: room 52, type 81; 80,
                                                   ; 100, 114, 46, 0, 60, 100,
                                                   ; 8, 106
  DEFB $34,$53,$32,$64,$AE,$33,$00,$96,$64,$40,$34 ; 284: room 52, type 83; 50,
                                                   ; 100, 174, 51, 0, 150, 100,
                                                   ; 64, 52
  DEFB $35,$49,$3C,$52,$64,$1D,$00,$8C,$52,$80,$7C ; 285: room 53, type 73; 60,
                                                   ; 82, 100, 29, 0, 140, 82,
                                                   ; 128, 124
  DEFB $35,$47,$5A,$80,$9C,$36,$00,$58,$52,$04,$9C ; 286: room 53, type 71; 90,
                                                   ; 128, 156, 54, 0, 88, 82,
                                                   ; 4, 156
  DEFB $35,$46,$30,$52,$9C,$4C,$00,$9A,$52,$04,$9C ; 287: room 53, type 70; 48,
                                                   ; 82, 156, 76, 0, 154, 82,
                                                   ; 4, 156
  DEFB $36,$46,$58,$52,$9E,$35,$00,$5C,$82,$08,$98 ; 288: room 54, type 70; 88,
                                                   ; 82, 158, 53, 0, 92, 130,
                                                   ; 8, 152
  DEFB $36,$47,$32,$52,$98,$1D,$00,$80,$7C,$04,$98 ; 289: room 54, type 71; 50,
                                                   ; 82, 152, 29, 0, 128, 124,
                                                   ; 4, 152
  DEFB $36,$47,$5A,$80,$9C,$37,$00,$58,$52,$04,$9C ; 290: room 54, type 71; 90,
                                                   ; 128, 156, 55, 0, 88, 82,
                                                   ; 4, 156
  DEFB $37,$46,$58,$52,$9E,$36,$00,$5C,$82,$08,$98 ; 291: room 55, type 70; 88,
                                                   ; 82, 158, 54, 0, 92, 130,
                                                   ; 8, 152
  DEFB $37,$52,$6E,$96,$9A,$38,$00,$6E,$34,$10,$9A ; 292: room 55, type 82;
                                                   ; 110, 150, 154, 56, 0, 110,
                                                   ; 52, 16, 154
  DEFB $38,$50,$6E,$34,$9A,$37,$00,$6E,$8C,$20,$9C ; 293: room 56, type 80;
                                                   ; 110, 52, 154, 55, 0, 110,
                                                   ; 140, 32, 156
  DEFB $38,$47,$5A,$52,$6E,$44,$00,$58,$52,$04,$6E ; 294: room 56, type 71; 90,
                                                   ; 82, 110, 68, 0, 88, 82, 4,
                                                   ; 110
  DEFB $39,$47,$5A,$80,$9C,$3A,$00,$58,$52,$04,$9C ; 295: room 57, type 71; 90,
                                                   ; 128, 156, 58, 0, 88, 82,
                                                   ; 4, 156
  DEFB $39,$49,$50,$52,$64,$2E,$06,$5A,$52,$80,$84 ; 296: room 57, type 73; 80,
                                                   ; 82, 100, 46, 6, 90, 82,
                                                   ; 128, 132
  DEFB $39,$48,$3C,$52,$AC,$3E,$06,$46,$52,$40,$94 ; 297: room 57, type 72; 60,
                                                   ; 82, 172, 62, 6, 70, 82,
                                                   ; 64, 148
  DEFB $3A,$47,$5A,$80,$9E,$3B,$00,$58,$52,$04,$9C ; 298: room 58, type 71; 90,
                                                   ; 128, 158, 59, 0, 88, 82,
                                                   ; 4, 156
  DEFB $3A,$46,$58,$52,$9E,$39,$00,$5C,$82,$08,$98 ; 299: room 58, type 70; 88,
                                                   ; 82, 158, 57, 0, 92, 130,
                                                   ; 8, 152
  DEFB $3B,$47,$5A,$80,$9E,$3C,$00,$58,$52,$04,$9C ; 300: room 59, type 71; 90,
                                                   ; 128, 158, 60, 0, 88, 82,
                                                   ; 4, 156
  DEFB $3B,$46,$58,$52,$9E,$3A,$00,$5C,$82,$08,$98 ; 301: room 59, type 70; 88,
                                                   ; 82, 158, 58, 0, 92, 130,
                                                   ; 8, 152
  DEFB $3C,$52,$6E,$96,$9A,$3D,$07,$92,$34,$10,$9A ; 302: room 60, type 82;
                                                   ; 110, 150, 154, 61, 7, 146,
                                                   ; 52, 16, 154
  DEFB $3C,$46,$58,$52,$9E,$3B,$00,$5C,$82,$08,$98 ; 303: room 60, type 70; 88,
                                                   ; 82, 158, 59, 0, 92, 130,
                                                   ; 8, 152
  DEFB $3D,$50,$92,$34,$9A,$3C,$00,$64,$A0,$20,$9C ; 304: room 61, type 80;
                                                   ; 146, 52, 154, 60, 0, 100,
                                                   ; 160, 32, 156
  DEFB $3E,$51,$32,$64,$92,$33,$00,$B0,$64,$04,$92 ; 305: room 62, type 81; 50,
                                                   ; 100, 146, 51, 0, 176, 100,
                                                   ; 4, 146
  DEFB $3E,$49,$46,$52,$92,$39,$06,$3C,$52,$80,$AC ; 306: room 62, type 73; 70,
                                                   ; 82, 146, 57, 6, 60, 82,
                                                   ; 128, 172
  DEFB $3E,$48,$C4,$52,$AC,$26,$00,$46,$52,$40,$32 ; 307: room 62, type 72;
                                                   ; 196, 82, 172, 38, 0, 70,
                                                   ; 82, 64, 50
  DEFB $3E,$49,$C4,$52,$92,$4D,$04,$5A,$82,$80,$AC ; 308: room 62, type 73;
                                                   ; 196, 82, 146, 77, 4, 90,
                                                   ; 130, 128, 172
  DEFB $3F,$49,$46,$52,$9A,$41,$02,$3C,$52,$80,$AC ; 309: room 63, type 73; 70,
                                                   ; 82, 154, 65, 2, 60, 82,
                                                   ; 128, 172
  DEFB $3F,$48,$5A,$52,$AC,$32,$00,$96,$52,$40,$34 ; 310: room 63, type 72; 90,
                                                   ; 82, 172, 50, 0, 150, 82,
                                                   ; 64, 52
  DEFB $3F,$46,$9A,$52,$9E,$40,$00,$34,$52,$08,$96 ; 311: room 63, type 70;
                                                   ; 154, 82, 158, 64, 0, 52,
                                                   ; 82, 8, 150
  DEFB $3F,$46,$30,$52,$9E,$4B,$00,$4E,$52,$04,$9A ; 312: room 63, type 70; 48,
                                                   ; 82, 158, 75, 0, 78, 82, 4,
                                                   ; 154
  DEFB $40,$47,$32,$52,$98,$3F,$00,$98,$52,$04,$9A ; 313: room 64, type 71; 50,
                                                   ; 82, 152, 63, 0, 152, 82,
                                                   ; 4, 154
  DEFB $40,$48,$5A,$80,$AC,$49,$00,$50,$52,$40,$34 ; 314: room 64, type 72; 90,
                                                   ; 128, 172, 73, 0, 80, 82,
                                                   ; 64, 52
  DEFB $41,$48,$3C,$52,$AC,$3F,$02,$46,$52,$40,$9C ; 315: room 65, type 72; 60,
                                                   ; 82, 172, 63, 2, 70, 82,
                                                   ; 64, 156
  DEFB $41,$47,$5A,$80,$9C,$42,$00,$58,$52,$04,$9C ; 316: room 65, type 71; 90,
                                                   ; 128, 156, 66, 0, 88, 82,
                                                   ; 4, 156
  DEFB $42,$46,$58,$52,$9E,$41,$00,$5C,$82,$08,$98 ; 317: room 66, type 70; 88,
                                                   ; 82, 158, 65, 0, 92, 130,
                                                   ; 8, 152
  DEFB $42,$47,$5A,$80,$9C,$43,$00,$58,$52,$04,$9C ; 318: room 66, type 71; 90,
                                                   ; 128, 156, 67, 0, 88, 82,
                                                   ; 4, 156
  DEFB $43,$46,$58,$52,$9E,$42,$00,$5C,$82,$08,$98 ; 319: room 67, type 70; 88,
                                                   ; 82, 158, 66, 0, 92, 130,
                                                   ; 8, 152
  DEFB $43,$52,$6E,$96,$9A,$44,$00,$6E,$34,$10,$9A ; 320: room 67, type 82;
                                                   ; 110, 150, 154, 68, 0, 110,
                                                   ; 52, 16, 154
  DEFB $44,$50,$6E,$34,$9A,$43,$00,$6E,$8C,$20,$9C ; 321: room 68, type 80;
                                                   ; 110, 52, 154, 67, 0, 110,
                                                   ; 140, 32, 156
  DEFB $44,$47,$5A,$52,$6E,$38,$00,$58,$52,$04,$6E ; 322: room 68, type 71; 90,
                                                   ; 82, 110, 56, 0, 88, 82, 4,
                                                   ; 110
  DEFB $45,$49,$78,$52,$54,$02,$00,$64,$52,$80,$AE ; 323: room 69, type 73;
                                                   ; 120, 82, 84, 2, 0, 100,
                                                   ; 82, 128, 174
  DEFB $46,$47,$32,$52,$4E,$48,$00,$AE,$52,$04,$4E ; 324: room 70, type 71; 50,
                                                   ; 82, 78, 72, 0, 174, 82, 4,
                                                   ; 78
  DEFB $46,$4B,$32,$96,$32,$49,$00,$32,$96,$80,$AC ; 325: room 70, type 75; 50,
                                                   ; 150, 50, 73, 0, 50, 150,
                                                   ; 128, 172
  DEFB $47,$46,$AE,$52,$4E,$49,$00,$34,$52,$08,$4E ; 326: room 71, type 70;
                                                   ; 174, 82, 78, 73, 0, 52,
                                                   ; 82, 8, 78
  DEFB $48,$46,$AE,$52,$4E,$46,$00,$34,$52,$08,$4E ; 327: room 72, type 70;
                                                   ; 174, 82, 78, 70, 0, 52,
                                                   ; 82, 8, 78
  DEFB $49,$4B,$32,$96,$AC,$46,$00,$32,$96,$40,$34 ; 328: room 73, type 75; 50,
                                                   ; 150, 172, 70, 0, 50, 150,
                                                   ; 64, 52
  DEFB $49,$47,$32,$52,$4E,$47,$00,$AE,$52,$04,$4E ; 329: room 73, type 71; 50,
                                                   ; 82, 78, 71, 0, 174, 82, 4,
                                                   ; 78
  DEFB $49,$49,$50,$52,$32,$40,$00,$5A,$82,$80,$AC ; 330: room 73, type 73; 80,
                                                   ; 82, 50, 64, 0, 90, 130,
                                                   ; 128, 172
  DEFB $4B,$46,$50,$52,$9A,$3F,$00,$32,$52,$08,$9A ; 331: room 75, type 70; 80,
                                                   ; 82, 154, 63, 0, 50, 82, 8,
                                                   ; 154
  DEFB $4C,$46,$9A,$52,$9A,$35,$00,$32,$52,$08,$9A ; 332: room 76, type 70;
                                                   ; 154, 82, 154, 53, 0, 50,
                                                   ; 82, 8, 154
  DEFB $4D,$49,$46,$52,$64,$4E,$00,$46,$52,$80,$AC ; 333: room 77, type 73; 70,
                                                   ; 82, 100, 78, 0, 70, 82,
                                                   ; 128, 172
  DEFB $4D,$48,$64,$80,$AC,$3E,$04,$C4,$52,$40,$94 ; 334: room 77, type 72;
                                                   ; 100, 128, 172, 62, 4, 196,
                                                   ; 82, 64, 148
  DEFB $4E,$48,$46,$52,$AC,$4D,$00,$46,$52,$40,$66 ; 335: room 78, type 72; 70,
                                                   ; 82, 172, 77, 0, 70, 82,
                                                   ; 64, 102
  DEFB $4E,$4B,$32,$96,$32,$11,$00,$64,$C8,$80,$AC ; 336: room 78, type 75; 50,
                                                   ; 150, 50, 17, 0, 100, 200,
                                                   ; 128, 172
  DEFB $50,$52,$6E,$C8,$9A,$33,$00,$6E,$34,$10,$6E ; 337: room 80, type 82;
                                                   ; 110, 200, 154, 51, 0, 110,
                                                   ; 52, 16, 110
  DEFB $03,$31,$00,$96,$50,$64 ; 338: room 3, type 49; 0, 150, 80, 100
  DEFB $05,$31,$00,$96,$50,$64 ; 339: room 5, type 49; 0, 150, 80, 100
  DEFB $05,$31,$00,$3C,$50,$46 ; 340: room 5, type 49; 0, 60, 80, 70
  DEFB $08,$31,$00,$8C,$50,$96 ; 341: room 8, type 49; 0, 140, 80, 150
  DEFB $0A,$2B,$00,$5A,$82,$78 ; 342: room 10, type 43; 0, 90, 130, 120
  DEFB $0B,$2A,$00,$00,$82,$14 ; 343: room 11, type 42; 0, 0, 130, 20
  DEFB $0C,$07,$00,$B2,$96,$6E ; 344: room 12, type 7; 0, 178, 150, 110
  DEFB $14,$33,$80,$6E,$5A,$AC ; 345: room 20, type 51; 128, 110, 90, 172
  DEFB $14,$35,$00,$6E,$50,$AA ; 346: room 20, type 53; 0, 110, 80, 170
  DEFB $1B,$33,$80,$6E,$64,$AC ; 347: room 27, type 51; 128, 110, 100, 172
  DEFB $1B,$35,$00,$6E,$5A,$AA ; 348: room 27, type 53; 0, 110, 90, 170
  DEFB $22,$33,$80,$6E,$5A,$AC ; 349: room 34, type 51; 128, 110, 90, 172
  DEFB $22,$35,$00,$6E,$50,$AA ; 350: room 34, type 53; 0, 110, 80, 170
  DEFB $22,$19,$00,$5A,$40,$34 ; 351: room 34, type 25; 0, 90, 64, 52
  DEFB $22,$19,$00,$5A,$40,$46 ; 352: room 34, type 25; 0, 90, 64, 70
  DEFB $22,$19,$00,$5A,$40,$58 ; 353: room 34, type 25; 0, 90, 64, 88
  DEFB $22,$19,$00,$6C,$40,$58 ; 354: room 34, type 25; 0, 108, 64, 88
  DEFB $22,$19,$00,$7E,$40,$58 ; 355: room 34, type 25; 0, 126, 64, 88
  DEFB $22,$19,$00,$90,$40,$58 ; 356: room 34, type 25; 0, 144, 64, 88
  DEFB $2D,$30,$80,$8C,$4A,$5A ; 357: room 45, type 48; 128, 140, 74, 90
  DEFB $2D,$30,$80,$6E,$4A,$72 ; 358: room 45, type 48; 128, 110, 74, 114
  DEFB $2D,$30,$80,$72,$4A,$5A ; 359: room 45, type 48; 128, 114, 74, 90
  DEFB $2D,$30,$80,$72,$4A,$46 ; 360: room 45, type 48; 128, 114, 74, 70
  DEFB $2D,$30,$80,$72,$4A,$32 ; 361: room 45, type 48; 128, 114, 74, 50
  DEFB $2E,$30,$80,$82,$4A,$5A ; 362: room 46, type 48; 128, 130, 74, 90
  DEFB $2E,$30,$80,$96,$4A,$3C ; 363: room 46, type 48; 128, 150, 74, 60
  DEFB $2E,$31,$00,$82,$50,$6E ; 364: room 46, type 49; 0, 130, 80, 110
  DEFB $2E,$31,$00,$56,$50,$3C ; 365: room 46, type 49; 0, 86, 80, 60
  DEFB $2F,$28,$80,$4E,$50,$4E ; 366: room 47, type 40; 128, 78, 80, 78
  DEFB $2F,$28,$80,$4E,$50,$8A ; 367: room 47, type 40; 128, 78, 80, 138
  DEFB $2F,$28,$80,$8A,$50,$4E ; 368: room 47, type 40; 128, 138, 80, 78
  DEFB $2F,$28,$80,$8A,$50,$8A ; 369: room 47, type 40; 128, 138, 80, 138
  DEFB $30,$28,$80,$4E,$50,$4E ; 370: room 48, type 40; 128, 78, 80, 78
  DEFB $30,$28,$80,$4E,$50,$8A ; 371: room 48, type 40; 128, 78, 80, 138
  DEFB $31,$19,$00,$52,$40,$70 ; 372: room 49, type 25; 0, 82, 64, 112
  DEFB $31,$37,$00,$40,$44,$5E ; 373: room 49, type 55; 0, 64, 68, 94
  DEFB $31,$19,$00,$8A,$40,$52 ; 374: room 49, type 25; 0, 138, 64, 82
  DEFB $31,$37,$00,$78,$44,$40 ; 375: room 49, type 55; 0, 120, 68, 64
  DEFB $33,$31,$00,$6E,$50,$82 ; 376: room 51, type 49; 0, 110, 80, 130
  DEFB $33,$31,$00,$82,$50,$5A ; 377: room 51, type 49; 0, 130, 80, 90
  DEFB $33,$31,$00,$96,$50,$3C ; 378: room 51, type 49; 0, 150, 80, 60
  DEFB $33,$31,$00,$50,$50,$78 ; 379: room 51, type 49; 0, 80, 80, 120
  DEFB $46,$16,$00,$6A,$50,$8C ; 380: room 70, type 22; 0, 106, 80, 140
  DEFB $49,$16,$00,$6A,$50,$64 ; 381: room 73, type 22; 0, 106, 80, 100
  DEFB $FF                ; End of the table

; Leftover source text
;
; More of the source text, lines 15380-15690, just after the object table on
; the tape; the start-up's copy to OBJECTS takes the first 263 bytes of it
; along. It is the source of the end of ROOMST: the DEFB of the glyphs of one
; of the quest's closing messages, the call of MESS2 (MESS2) and the jump to
; WAIT (WAIT), and the start of the room's set-up, from the label ROS (the LD
; (IY),7 there) to the loop that copies the records of the things carried, OBJD
; and OB2, with DATLEN for the record's length and the variable bases V (IY,
; OBJECT_COUNT) and T (IY+$64).
SOURCE_AFTER_OBJECTS:
  DEFM "DEFB",$09,"0,20,8,5,0,"
  DEFM "23,9,26,1,18,4,0"
  DEFM ",9,19,0,6,18,5,5"
  DEFM $0D,$14,"<",$09,"DEFB",$09,"164",$0D,$1E,"<",$09
  DEFM "CALL",$09,"MESS2",$0D,"(<",$09,"JP"
  DEFM $09,"WAIT",$0D,"2<ROS",$09,"LD",$09,"("
  DEFM "IY),7",$0D,"<<",$09,"LD",$09,"B,5",$0D
  DEFM "F<",$09,"LD",$09,"HL,55552",$0D,"P"
  DEFM "<",$09,"LD",$09,"(T),HL",$0D,"Z<OB"
  DEFM "JD",$09,"LD",$09,"L,(IY+31)",$0D
  DEFM "d<",$09,"INC",$09,"IY",$0D,"n<",$09,"LD",$09
  DEFM "H,(IY+31)",$0D,"x<",$09,"INC"
  DEFM $09,"IY",$0D,$82,"<",$09,"LD",$09,"A,L",$0D,$8C,"<"
  DEFM $09,"OR",$09,"H",$0D,$96,"<",$09,"JR",$09,"Z,OB"
  DEFM "2",$0D,$A0,"<",$09,"LD",$09,"(IY+29),"
  DEFM "E",$0D,$AA,"<",$09,"LD",$09,"(IY+30),"
  DEFM "D",$0D,$B4,"<",$09,"PUSH",$09,"BC",$0D,$BE,"<",$09
  DEFM "LD",$09,"BC,DATLEN",$0D,$C8,"<",$09
  DEFM "EX",$09,"DE,HL",$0D,$D2,"<",$09,"ADD",$09
  DEFM "HL,BC",$0D,$DC,"<",$09,"EX",$09,"DE,H"
  DEFM "L",$0D,$E6,"<",$09,"PUSH",$09,"DE",$0D,$F0,"<",$09
  DEFM "LD",$09,"DE,(T)",$0D,$FA,"<",$09,"LDI"
  DEFM "R",$0D,$04,"=",$09,"LD",$09,"(T),DE",$0D,$0E
  DEFM "=",$09,"POP",$09,"DE",$0D,$18,"=",$09,"POP",$09
  DEFM "BC",$0D,"\"=",$09,"LD",$09,"A,(V)",$0D,","
  DEFM "=",$09,"INC",$09,"A",$0D,"6=",$09,"LD",$09,"(V"
  DEFM "),A",$0D,"@=OB2",$09,"DJNZ",$09,"O"
  DEFM "BJD",$0D,"J=",$09,"LD",$09,"("

; Templates for object types 0-56, as the tape has them
TEMPLATES_TAPE:
  DEFB $68,$21,$28,$22,$00,$7D,$0E,$0E,$16,$00,$16 ; Type 0: 40 by 34, sprite
                                                   ; SPRITE7D00
  DEFB $74,$13,$18,$14,$1A,$80,$0A,$0A,$0A,$00,$00 ; Type 1: 24 by 20, sprite
                                                   ; SPRITE801A
  DEFB $74,$18,$18,$15,$88,$7E,$0A,$0A,$0A,$03,$10 ; Type 2: 24 by 21, sprite
                                                   ; SPRITE7E88
  DEFB $78,$0F,$10,$0D,$54,$7E,$08,$08,$08,$00,$13 ; Type 3: 16 by 13, sprite
                                                   ; SPRITE7E54
  DEFB $74,$0D,$18,$0E,$06,$7F,$0C,$02,$0C,$00,$11 ; Type 4: 24 by 14, sprite
                                                   ; SPRITE7F06
  DEFB $6C,$17,$20,$18,$5A,$7F,$0A,$0A,$12,$00,$00 ; Type 5: 32 by 24, sprite
                                                   ; SPRITE7F5A
  DEFB $79,$12,$10,$11,$92,$80,$0A,$0B,$0A,$00,$00 ; Type 6: 16 by 17, sprite
                                                   ; SPRITE8092
  DEFB $6E,$19,$18,$1A,$C2,$82,$04,$10,$0E,$00,$14 ; Type 7: 24 by 26, sprite
                                                   ; SPRITE82C2
  DEFB $74,$20,$18,$1D,$98,$81,$0E,$16,$0E,$00,$16 ; Type 8: 24 by 29, sprite
                                                   ; SPRITE8198
  DEFB $78,$13,$10,$10,$46,$82,$0A,$0E,$0A,$00,$10 ; Type 9: 16 by 16, sprite
                                                   ; SPRITE8246
  DEFB $00,$00,$00,$00,$00,$00,$64,$0A,$3C,$00,$00 ; Type 10: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$80,$50,$50,$00,$00 ; Type 11: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$32,$50,$50,$00,$00 ; Type 12: no sprite
  DEFB $74,$28,$18,$26,$B8,$8B,$0E,$1E,$0E,$07,$16 ; Type 13: 24 by 38, sprite
                                                   ; SPRITE8BB8
  DEFB $76,$07,$10,$05,$86,$82,$06,$02,$08,$00,$10 ; Type 14: 16 by 5, sprite
                                                   ; SPRITE8286
  DEFB $78,$0E,$10,$0D,$08,$9F,$0A,$08,$0A,$00,$12 ; Type 15: 16 by 13, sprite
                                                   ; SPRITE9F08
  DEFB $74,$14,$18,$11,$5A,$87,$0A,$0C,$0A,$00,$00 ; Type 16: 24 by 17, sprite
                                                   ; SPRITE875A
  DEFB $78,$0B,$10,$0A,$9A,$82,$08,$06,$08,$00,$14 ; Type 17: 16 by 10, sprite
                                                   ; SPRITE829A
  DEFB $6C,$11,$28,$12,$D2,$84,$0E,$02,$0E,$00,$00 ; Type 18: 40 by 18, sprite
                                                   ; SPRITE84D2
  DEFB $6E,$17,$18,$18,$86,$85,$02,$10,$0E,$00,$00 ; Type 19: 24 by 24, sprite
                                                   ; SPRITE8586
  DEFB $7A,$17,$18,$18,$16,$86,$0E,$10,$02,$00,$00 ; Type 20: 24 by 24, sprite
                                                   ; SPRITE8616
  DEFB $72,$0B,$18,$08,$C0,$87,$0A,$02,$0E,$00,$10 ; Type 21: 24 by 8, sprite
                                                   ; SPRITE87C0
  DEFB $73,$2C,$18,$29,$5E,$83,$0C,$1E,$0C,$00,$00 ; Type 22: 24 by 41, sprite
                                                   ; SPRITE835E
  DEFB $74,$18,$18,$15,$54,$84,$08,$10,$08,$00,$11 ; Type 23: 24 by 21, sprite
                                                   ; SPRITE8454
  DEFB $6C,$11,$28,$12,$D2,$84,$0E,$02,$0E,$00,$14 ; Type 24: 40 by 18, sprite
                                                   ; SPRITE84D2
  DEFB $77,$17,$10,$18,$F0,$87,$08,$0E,$08,$00,$00 ; Type 25: 16 by 24, sprite
                                                   ; SPRITE87F0
  DEFB $74,$1D,$18,$1A,$3C,$9F,$0A,$18,$0A,$06,$14 ; Type 26: 24 by 26, sprite
                                                   ; SPRITE9F3C
  DEFB $74,$1D,$18,$1A,$B8,$A4,$0A,$18,$0A,$09,$14 ; Type 27: 24 by 26, sprite
                                                   ; SPRITEA4B8
  DEFB $74,$1D,$18,$1A,$B8,$A4,$0A,$0C,$0A,$00,$12 ; Type 28: 24 by 26, sprite
                                                   ; SPRITEA4B8
  DEFB $78,$0D,$10,$0A,$D6,$80,$06,$08,$06,$00,$10 ; Type 29: 16 by 10, sprite
                                                   ; SPRITE80D6
  DEFB $74,$0B,$10,$09,$FE,$80,$06,$04,$0C,$00,$10 ; Type 30: 16 by 9, sprite
                                                   ; SPRITE80FE
  DEFB $76,$0D,$10,$0A,$22,$81,$08,$08,$08,$00,$10 ; Type 31: 16 by 10, sprite
                                                   ; SPRITE8122
  DEFB $72,$0D,$18,$0D,$4A,$81,$08,$04,$0A,$00,$10 ; Type 32: 24 by 13, sprite
                                                   ; SPRITE814A
  DEFB $74,$1D,$18,$1A,$3C,$9F,$0A,$18,$0A,$0A,$14 ; Type 33: 24 by 26, sprite
                                                   ; SPRITE9F3C
  DEFB $78,$18,$10,$17,$3C,$9B,$0A,$10,$0A,$00,$10 ; Type 34: 16 by 23, sprite
                                                   ; SPRITE9B3C
  DEFB $7C,$18,$08,$18,$98,$9B,$04,$10,$04,$00,$00 ; Type 35: 8 by 24, sprite
                                                   ; SPRITE9B98
  DEFB $7C,$18,$08,$18,$C8,$9B,$04,$10,$04,$00,$00 ; Type 36: 8 by 24, sprite
                                                   ; SPRITE9BC8
  DEFB $60,$1A,$28,$18,$F8,$9B,$0A,$08,$22,$00,$15 ; Type 37: 40 by 24, sprite
                                                   ; SPRITE9BF8
  DEFB $7C,$1A,$18,$18,$E8,$9C,$16,$0E,$04,$00,$00 ; Type 38: 24 by 24, sprite
                                                   ; SPRITE9CE8
  DEFB $66,$18,$28,$18,$78,$9D,$0C,$06,$18,$00,$00 ; Type 39: 40 by 24, sprite
                                                   ; SPRITE9D78
  DEFB $78,$0A,$10,$0A,$04,$61,$0C,$0E,$0C,$0E,$1E ; Type 40: 16 by 10, sprite
                                                   ; SPRITE6104
  DEFB $7C,$20,$08,$20,$C8,$9E,$04,$1E,$04,$00,$00 ; Type 41: 8 by 32, sprite
                                                   ; SPRITE9EC8
  DEFB $00,$00,$00,$00,$00,$00,$50,$50,$46,$00,$00 ; Type 42: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$2C,$50,$46,$00,$00 ; Type 43: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$14,$50,$18,$00,$00 ; Type 44: no sprite
  DEFB $78,$22,$10,$20,$88,$5E,$0A,$1E,$0A,$0B,$18 ; Type 45: 16 by 32, sprite
                                                   ; SPRITE5E88
  DEFB $7A,$17,$18,$18,$16,$86,$0E,$12,$02,$00,$16 ; Type 46: 24 by 24, sprite
                                                   ; SPRITE8616
  DEFB $00,$00,$00,$00,$00,$00,$B4,$04,$B4,$00,$00 ; Type 47: no sprite
  DEFB $72,$18,$18,$18,$84,$5C,$0C,$18,$0C,$04,$1E ; Type 48: 24 by 24, sprite
                                                   ; SPRITE5C84
  DEFB $74,$18,$18,$18,$A6,$86,$0E,$18,$0E,$00,$00 ; Type 49: 24 by 24, sprite
                                                   ; SPRITE86A6
  DEFB $78,$10,$18,$0E,$34,$5E,$0E,$04,$0A,$00,$10 ; Type 50: 24 by 14, sprite
                                                   ; SPRITE5E34
  DEFB $7C,$10,$08,$08,$00,$5B,$0A,$0E,$0A,$0C,$1E ; Type 51: 8 by 8, sprite
                                                   ; SPRITE5B00
  DEFB $78,$18,$10,$17,$30,$5B,$0A,$1A,$0A,$0D,$1E ; Type 52: 16 by 23, sprite
                                                   ; SPRITE5B30
  DEFB $7A,$10,$08,$10,$44,$5C,$06,$0A,$06,$00,$1E ; Type 53: 8 by 16, sprite
                                                   ; SPRITE5C44
  DEFB $7A,$10,$08,$10,$64,$5C,$06,$0A,$06,$00,$1E ; Type 54: 8 by 16, sprite
                                                   ; SPRITE5C64
  DEFB $68,$1E,$30,$15,$88,$5F,$1E,$04,$1E,$00,$00 ; Type 55: 48 by 21, sprite
                                                   ; SPRITE5F88
  DEFB $78,$22,$10,$20,$84,$60,$0A,$1E,$0A,$0F,$18 ; Type 56: 16 by 32, sprite
                                                   ; SPRITE6084
  DEFB $09,$4E,$43        ; Between the tables

; Templates for object types $46-$54, as the tape has them
LARGE_TEMPLATES_TAPE:
  DEFB $00,$00,$00,$00,$00,$00,$02,$20,$16 ; Type $46: no sprite
  DEFB $68,$33,$18,$33,$54,$89,$02,$20,$16 ; Type $47: 24 by 51, sprite
                                           ; SPRITE8954
  DEFB $00,$00,$00,$00,$00,$00,$16,$20,$02 ; Type $48: no sprite
  DEFB $80,$33,$18,$33,$86,$8A,$16,$20,$02 ; Type $49: 24 by 51, sprite
                                           ; SPRITE8A86
  DEFB $00,$00,$00,$00,$00,$00,$02,$64,$8C ; Type $4A: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$8C,$64,$02 ; Type $4B: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$28,$64,$02 ; Type $4C: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$02,$64,$28 ; Type $4D: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$32,$02,$1E ; Type $4E: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$1E,$02,$32 ; Type $4F: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$0A,$02,$0A ; Type $50: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$02,$32,$1E ; Type $51: no sprite
  DEFB $6C,$1A,$28,$1A,$50,$88,$0A,$02,$0A ; Type $52: 40 by 26, sprite
                                           ; SPRITE8850
  DEFB $00,$00,$00,$00,$00,$00,$1E,$32,$02 ; Type $53: no sprite
  DEFB $00,$00,$00,$00,$00,$00,$50,$02,$28 ; Type $54: no sprite
  DEFB $0D,$70,$3F,$09,$52,$45,$53,$09 ; Between the tables
  DEFB $32,$2C,$28,$49,$59,$2B,$32,$33 ;
  DEFB $29,$0D,$7A                     ;

; Patches for the codes $E6 up in a room's object list, as the tape has them
PATCHES_TAPE:
  DEFB $32,$B4,$B2,$28,$28,$AE ; Code $E6: 50, 180, 178, 40, 40, 174
  DEFB $32,$B4,$E8,$28,$5E,$AE ; Code $E7: 50, 180, 232, 40, 94, 174
  DEFB $32,$B4,$90,$28,$4A,$AE ; Code $E8: 50, 180, 144, 40, 74, 174
  DEFB $32,$78,$70,$28,$28,$AE ; Code $E9: 50, 120, 112, 40, 40, 174
  DEFB $32,$B4,$90,$28,$5E,$AE ; Code $EA: 50, 180, 144, 40, 94, 174 (no room
                               ; uses it)
  DEFB $32,$B4,$82,$28,$5A,$AE ; Code $EB: 50, 180, 130, 40, 90, 174
  DEFB $32,$78,$50,$28,$42,$AE ; Code $EC: 50, 120, 80, 40, 66, 174
  DEFB $32,$B4,$9A,$28,$44,$AE ; Code $ED: 50, 180, 154, 40, 68, 174
  DEFB $32,$64,$9A,$28,$90,$AE ; Code $EE: 50, 100, 154, 40, 144, 174
  DEFB $32,$B4,$98,$28,$28,$B2 ; Code $EF: 50, 180, 152, 40, 40, 178
  DEFB $32,$B4,$B0,$28,$28,$86 ; Code $F0: 50, 180, 176, 40, 40, 134
  DEFB $32,$B4,$50,$28,$68,$AE ; Code $F1: 50, 180, 80, 40, 104, 174
  DEFB $32,$B4,$28,$DE,$88,$AE ; Code $F2: 50, 180, 40, 222, 136, 174
  DEFB $32,$B4,$28,$82,$28,$AE ; Code $F3: 50, 180, 40, 130, 40, 174
  DEFB $32,$B4,$BC,$28,$40,$C2 ; Code $F4: 50, 180, 188, 40, 64, 194
  DEFB $32,$B4,$E6,$28,$78,$AE ; Code $F5: 50, 180, 230, 40, 120, 174
  DEFB $32,$B4,$76,$3C,$28,$B8 ; Code $F6: 50, 180, 118, 60, 40, 184
  DEFB $32,$B4,$AA,$2C,$2E,$E0 ; Code $F7: 50, 180, 170, 44, 46, 224
  DEFB $0A,$B4,$B2,$28,$28,$AE ; Code $F8: 10, 180, 178, 40, 40, 174
  DEFB $32,$E6,$50,$28,$8C,$AE ; Code $F9: 50, 230, 80, 40, 140, 174
  DEFB $57,$41,$49,$54,$0D,$DE,$3F,$09 ; The rest of what the start-up copies
  DEFB $4C,$44,$09,$41,$2C,$32,$33,$39 ; (no room uses a code that reads it)
  DEFB $0D,$E8,$3F,$09,$43,$41,$4C,$4C ;
  DEFB $09,$49,$4E,$50                 ;

; Leftover source text
;
; More of the source text, lines 16370-17190: the source of the part of
; MAIN_LOOP that uses the thing in hand and chooses one of the five places to
; carry things, with its labels STAR2, ST3 to ST9, ST20 to ST22, STE3 and USE4
; to USE6, and calls of routines the author called INPUT, EEN, TELE, INFO0,
; INFOR and PRINT (INPUT, SAVE_OBJECT_POSITIONS, the entry into a room in
; TITLE_SCREEN, CLEAR_THING_BOX, SHOW_THING_IN_USE and PRINT).
;
; Once the game runs, its buffers lie over these bytes: the clean copy of the
; screen runs to offset 363, and the four pages COMPOSITE_TO_SCREEN composites
; from start at offsets 364 (page $D8, BUFFER_D800), 620 (page $D9,
; BUFFER_D900) and 876 (page $DA, BUFFER_DA00); page $DB lies over the loader's
; leftovers.
SOURCE_AFTER_TEMPLATES:
  DEFM "UT",$0D,$F2,"?",$09,"RRA",$0D,$FC,"?",$09,"JR",$09
  DEFM "NC,STAR2",$0D,$06,"@",$09,"BIT",$09
  DEFM "1,B",$0D,$10,"@",$09,"RET",$09,"NZ",$0D,$1A,"@"
  DEFM "STAR2",$09,"AND",$09,"12",$0D,"$@",$09
  DEFM "JR",$09,"Z,ST20",$0D,".@",$09,"LD",$09
  DEFM "H,255",$0D,"8@",$09,"LD",$09,"L,(I"
  DEFM "Y+30)",$0D,"B@",$09,"LD",$09,"E,(H"
  DEFM "L)",$0D,"L@",$09,"INC",$09,"HL",$0D,"V@",$09
  DEFM "LD",$09,"D,(HL)",$0D,$60,"@",$09,"PUS"
  DEFM "H",$09,"DE",$0D,"j@",$09,"POP",$09,"IX",$0D,"t"
  DEFM "@",$09,"LD",$09,"A,(IX+12)",$0D,"~"
  DEFM "@",$09,"AND",$09,"15",$0D,$88,"@",$09,"CP",$09,"9"
  DEFM $0D,$92,"@",$09,"JR",$09,"NZ,USE6",$0D,$9C
  DEFM "@",$09,"LD",$09,"(IY+52),30",$0D
  DEFM $A6,"@",$09,"LD",$09,"B,0",$0D,$B0,"@",$09,"LD",$09
  DEFM "(HL),B",$0D,$BA,"@",$09,"DEC",$09,"HL"
  DEFM $0D,$C4,"@",$09,"LD",$09,"(HL),B",$0D,$CE,"@"
  DEFM $09,"CALL",$09,"EEN",$0D,$D8,"@",$09,"POP"
  DEFM $09,"HL",$0D,$E2,"@",$09,"JP",$09,"TELE",$0D,$EC
  DEFM "@USE6",$09,"CP",$09,"6",$0D,$F6,"@",$09,"JR"
  DEFM $09,"NZ,USE5",$0D,$00,"A",$09,"LD",$09,"D"
  DEFM "E,2313",$0D,$0A,"A",$09,"LD",$09,"(V+"
  DEFM "21),DE",$0D,$14,"A",$09,"JR"
BUFFER_D800:
  DEFB $09
  DEFM "ST22",$0D,$1E,"AUSE5",$09,"CP",$09,"5"
  DEFM $0D,"(A",$09,"JR",$09,"NZ,USE4",$0D,"2"
  DEFM "A",$09,"SET",$09,"7,(IY+23)",$0D
  DEFM "<A",$09,"JR",$09,"ST22",$0D,"FAUSE"
  DEFM "4",$09,"CP",$09,"4",$0D,"PA",$09,"JR",$09,"NZ,"
  DEFM "ST20",$0D,"ZA",$09,"LD",$09,"A,(V+"
  DEFM "21)",$0D,"dA",$09,"INC",$09,"A",$0D,"nA",$09
  DEFM "CP",$09,"10",$0D,"xA",$09,"JR",$09,"NC,S"
  DEFM "T21",$0D,$82,"A",$09,"LD",$09,"(V+21)"
  DEFM ",A",$0D,$8C,"A",$09,"JR",$09,"ST22",$0D,$96,"A"
  DEFM "ST21",$09,"LD",$09,"(IY+22),"
  DEFM "9",$0D,$A0,"AST22",$09,"LD",$09,"A,(V"
  DEFM "+30)",$0D,$AA,"A",$09,"SET",$09,"0,(I"
  DEFM "Y+23)",$0D,$B4,"A",$09,"LD",$09,"(HL)"
  DEFM ",0",$0D,$BE,"A",$09,"DEC",$09,"HL",$0D,$C8,"A",$09
  DEFM "LD",$09,"(HL),0",$0D,$D2,"A",$09,"JR"
BUFFER_D900:
  DEFB $09
  DEFM "STE3",$0D,$DC,"AST20",$09,"LD",$09,"A"
  DEFM ",247",$0D,$E6,"A",$09,"CALL",$09,"INP"
  DEFM "UT",$0D,$F0,"A",$09,"JR",$09,"Z,ST3",$0D,$FA
  DEFM "A",$09,"LD",$09,"B,5",$0D,$04,"B",$09,"LD",$09,"C"
  DEFM ",255",$0D,$0E,"BST4",$09,"INC",$09,"C"
  DEFM $0D,$18,"B",$09,"INC",$09,"C",$0D,"\"B",$09,"RRA"
  DEFM $0D,",B",$09,"JR",$09,"C,ST5",$0D,"6B",$09
  DEFM "DJNZ",$09,"ST4",$0D,"@BST5",$09,"L"
  DEFM "D",$09,"A,158",$0D,"JB",$09,"ADD",$09,"A"
  DEFM ",C",$0D,"TB",$09,"CP",$09,"(IY+30)"
  DEFM $0D,$5E,"B",$09,"JR",$09,"Z,ST3",$0D,"hB",$09
  DEFM "LD",$09,"(IY+30),A",$0D,"rBS"
  DEFM "TE3",$09,"LD",$09,"H,255",$0D,"|B",$09
  DEFM "LD",$09,"L,A",$0D,$86,"B",$09,"LD",$09,"E,("
  DEFM "HL)",$0D,$90,"B",$09,"INC",$09,"HL",$0D,$9A,"B"
  DEFM $09,"LD",$09,"D,(HL)",$0D,$A4,"B",$09,"E"
BUFFER_DA00:
  DEFB $58
  DEFM $09,"DE,HL",$0D,$AE,"B",$09,"LD",$09,"A,H"
  DEFM $0D,$B8,"B",$09,"OR",$09,"L",$0D,$C2,"B",$09,"JR",$09,"N"
  DEFM "Z,ST6",$0D,$CC,"B",$09,"CALL",$09,"IN"
  DEFM "FO0",$0D,$D6,"B",$09,"JR",$09,"ST3",$0D,$E0,"B"
  DEFM "ST6",$09,"CALL",$09,"INFOR",$0D,$EA
  DEFM "BST3",$09,"BIT",$09,"0,(IY+2"
  DEFM "3)",$0D,$F4,"B",$09,"JR",$09,"Z,ST9",$0D,$FE
  DEFM "B",$09,"RES",$09,"0,(IY+23)",$0D
  DEFM $08,"C",$09,"CALL",$09,"PRINT",$0D,$12,"C"
  DEFM $09,"DEFB",$09,"200,55,12,"
  DEFM "164",$0D,$1C,"C",$09,"LD",$09,"A,(V+2"
  DEFM "1)",$0D,"&C",$09,"ADD",$09,"A,27",$0D

; What the loader left: its table of pieces, its stack and its checksum
;
; The tape's long block does not load these bytes: the loader's second stage
; put them here, and they are as its turbo stage left them. At the start of
; that stage (a snapshot taken there) the block begins with a jump to
; LOADER_CLEARED, and from offset 3 the table the loader pops, with SP, as it
; goes: a zero (no more screen lines), then a length and an address for each
; piece of the game, the first of which (14 bytes at offset 9) writes the rest
; of the table ahead of where it is being read, and a zero length to end. As
; the stack pointer worked up through the table, the loader's calls pushed
; their return addresses into the words it had read, which is why most of it
; now holds two return addresses over and over.
;
; After the table: at offset 23, the address the loader returned to when the
; table ran out, the checksum test at the end of LOADER_CLEARED; at offset 25,
; the last piece loaded, three bytes: the address the loader's final RET goes
; to, START, and a byte of the checksum; at offset 28, the byte the checksum
; test wants (it adds H to the byte at offset 27 and compares); at offset 29,
; the header the long block starts with, which the loader checks ($03F6).
LOADER_TABLE:
  DEFB $DB,$49,$DB                     ; Once a jump to the turbo stage; the
  DEFB $00,$00                         ; table's first zero; return addresses
  DEFB $D9,$DB,$49,$DB,$D9,$DB,$49,$DB ; over the table; its zero length; the
  DEFB $D9,$DB,$49,$DB,$D9,$DB,$49,$DB ; return to the checksum test; the
  DEFB $00,$00                         ; return to START and the checksum's
  DEFB $B2,$DC                         ; byte; what the test wants; the header
  DEFB $7C,$C4                         ;
  DEFB $58                             ;
  DEFB $36                             ;
  DEFB $F6,$03                         ;

; The loader, cleared
;
; The loader's turbo stage, which clears itself as its last act: an LD (HL),0
; and an LDIR run zeros from here to the end of the block. The LDIR's own first
; byte is the last it clears; the processor then fetches the instruction again
; (an LDIR repeats by going back to itself), finds a NOP, and goes on through
; the LDIR's second byte (OR B) to the RET after it, which takes the last
; piece's return address off the stack: START. So 488 bytes are cleared, and
; the last two are not zeros. (Read from the loader's code in a snapshot taken
; where the turbo stage starts.)
;
; The code names offset 289 (BUFFER_DC00) only as the end of the 512 bytes
; below it that SORT_AND_DRAW_BEHIND clears: pages $DA and $DB.
LOADER_CLEARED:
  DEFS $0121
BUFFER_DC00:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Zeros, but for the last two bytes: the
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; LDIR's second byte, and the RET
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$B0 ;
  DEFB $C9                             ;

; The loader's failure routine
;
; Where the loader goes if its checksum test fails. It never runs on a good
; load and is kept as data here; what it does, read from the bytes: it clears
; memory from its own first bytes down to SPRITE5B00 (an LDDR), prints a line
; in the ROM's characters on the bottom row of the screen, bright yellow and
; flashing on black, asking for the tape to be rewound and loaded again, makes
; the border black, warbles on the beeper with two calls of the ROM's BEEPER
; 233 times over, and resets the machine (RST 0).
;
; After its message, the byte the loader keeps its decryption key in (it XORs
; each byte loaded with it, and adds to it), as the load left it; and three
; counters of the countdown the loader draws over the loading screen.
LOADER_FAILURE:
  DEFB $21,$D3,$DC,$11,$D2,$DC,$01,$D3 ; The routine
  DEFB $81,$AF,$77,$ED,$B8,$FD,$21,$1D ;
  DEFB $DD,$1E,$E7,$06,$18,$C5,$FD,$6E ;
  DEFB $00,$26,$00,$01,$00,$3C,$29,$29 ;
  DEFB $29,$09,$16,$50,$06,$08,$7E,$12 ;
  DEFB $14,$23,$10,$FA,$16,$5A,$3E,$C6 ;
  DEFB $12,$1C,$FD,$23,$C1,$10,$DE,$3E ;
  DEFB $00,$32,$48,$5C,$06,$E9,$C5,$11 ;
  DEFB $05,$00,$21,$6A,$06,$CD,$B5,$03 ;
  DEFB $1E,$04,$21,$05,$04,$CD,$B5,$03 ;
  DEFB $C1,$10,$EB,$C7                 ; The routine's last four bytes (the end
  DEFB $20,$45,$52,$52,$4F,$52,$3A,$20 ; of the BEEPER loop, and the RST 0);
  DEFB $52,$45,$57,$49,$4E,$44,$20,$26 ; the message, 24 characters of ASCII;
  DEFB $20,$52,$45,$4C,$4F,$41,$44,$20 ; the key; the countdown's counters
  DEFB $ED                             ;
  DEFB $FF,$4F,$4F                     ;

; What is left of the development assembler's symbol table
;
; 64 whole symbols, 64 of them the address of an instruction in this listing's
; code.
SYMBOL_TABLE:
  DEFB $C7,$65,$F0        ; The end of a symbol whose start the loader's bytes
                          ; replaced: its last letter and its value
  DEFB $1F,$DF,$73,$DE     ; ATTRI = ATTRI
  DEFB $01                 ;
  DEFB $41,$54,$54,$52,$C9 ;
  DEFB $FB,$F0             ;
  DEFB $6C,$E3,$AE,$E0    ; PAUS = PAUS
  DEFB $01                ;
  DEFB $50,$41,$55,$D3    ;
  DEFB $D8,$F0            ;
  DEFB $00,$00,$9C,$E6    ; TELE = TELE
  DEFB $01                ;
  DEFB $54,$45,$4C,$C5    ;
  DEFB $9B,$F0            ;
  DEFB $00,$00,$5C,$E6         ; ROOMST = ROOMST
  DEFB $01                     ;
  DEFB $52,$4F,$4F,$4D,$53,$D4 ;
  DEFB $20,$FD                 ;
  DEFB $45,$DE,$2E,$DE    ; EEN = SAVE_OBJECT_POSITIONS
  DEFB $01                ;
  DEFB $45,$45,$CE        ;
  DEFB $06,$F9            ;
  DEFB $00,$00,$17,$E1    ; WAIT = WAIT
  DEFB $01                ;
  DEFB $57,$41,$49,$D4    ;
  DEFB $D2,$F0            ;
  DEFB $3D,$DF,$EC,$DE     ; INPUT = INPUT
  DEFB $01                 ;
  DEFB $49,$4E,$50,$55,$D4 ;
  DEFB $DF,$F0             ;
  DEFB $89,$DE,$00,$00    ; IN31 = IN31
  DEFB $01                ;
  DEFB $49,$4E,$33,$B1    ;
  DEFB $E6,$F0            ;
  DEFB $00,$00,$22,$E1         ; RESTOR = RESTOR
  DEFB $01                     ;
  DEFB $52,$45,$53,$54,$4F,$D2 ;
  DEFB $0B,$F1                 ;
  DEFB $00,$00,$B5,$DD     ; MIMAN = MIMAN
  DEFB $01                 ;
  DEFB $4D,$49,$4D,$41,$CE ;
  DEFB $17,$F1             ;
  DEFB $02,$DE,$C2,$DD         ; MIRROR = MIRROR
  DEFB $01                     ;
  DEFB $4D,$49,$52,$52,$4F,$D2 ;
  DEFB $2D,$F1                 ;
  DEFB $CF,$DD,$DB,$DD         ; MIWRAI = MIWRAI
  DEFB $01                     ;
  DEFB $4D,$49,$57,$52,$41,$C9 ;
  DEFB $1F,$F1                 ;
  DEFB $00,$00,$00,$00     ; MITRO = MITRO
  DEFB $01                 ;
  DEFB $4D,$49,$54,$52,$CF ;
  DEFB $27,$F1             ;
  DEFB $EF,$DD,$E5,$DD    ; MW1 = MW1
  DEFB $01                ;
  DEFB $4D,$57,$B1        ;
  DEFB $3A,$F1            ;
  DEFB $00,$00,$00,$00    ; MW2 = MW2
  DEFB $01                ;
  DEFB $4D,$57,$B2        ;
  DEFB $43,$F1            ;
  DEFB $8C,$E7,$F8,$DD    ; MW = MW
  DEFB $01                ;
  DEFB $4D,$D7            ;
  DEFB $57,$F1            ;
  DEFB $00,$00,$00,$00    ; MW0 = MW0
  DEFB $01                ;
  DEFB $4D,$57,$B0        ;
  DEFB $60,$F1            ;
  DEFB $00,$00,$0D,$DE    ; MIR0 = MIR0
  DEFB $01                ;
  DEFB $4D,$49,$52,$B0    ;
  DEFB $64,$F1            ;
  DEFB $00,$00,$18,$DE    ; MIR1 = MIR1
  DEFB $01                ;
  DEFB $4D,$49,$52,$B1    ;
  DEFB $67,$F1            ;
  DEFB $00,$00,$23,$DE    ; MIR2 = MIR2
  DEFB $01                ;
  DEFB $4D,$49,$52,$B2    ;
  DEFB $69,$F1            ;
  DEFB $00,$00,$00,$00    ; MIR3 = MIR3
  DEFB $01                ;
  DEFB $4D,$49,$52,$B3    ;
  DEFB $8D,$F1            ;
  DEFB $3B,$DE,$36,$E3         ; FACING = FACING
  DEFB $01                     ;
  DEFB $46,$41,$43,$49,$4E,$C7 ;
  DEFB $99,$F1                 ;
  DEFB $63,$E3,$00,$00    ; FA0 = FA0
  DEFB $01                ;
  DEFB $46,$41,$B0        ;
  DEFB $AC,$F1            ;
  DEFB $5F,$DE,$52,$DE         ; DECLI1 = DECLI1
  DEFB $01                     ;
  DEFB $44,$45,$43,$4C,$49,$B1 ;
  DEFB $B4,$F1                 ;
  DEFB $00,$00,$CD,$E0         ; DECLIF = DECLIF
  DEFB $01                     ;
  DEFB $44,$45,$43,$4C,$49,$C6 ;
  DEFB $B6,$F1                 ;
  DEFB $00,$00,$69,$DE    ; DE1 = DE1
  DEFB $01                ;
  DEFB $44,$45,$B1        ;
  DEFB $C8,$F1            ;
  DEFB $00,$00,$00,$00    ; DE2 = DE2
  DEFB $01                ;
  DEFB $44,$45,$B2        ;
  DEFB $D7,$F1            ;
  DEFB $00,$DF,$F5,$E0     ; CHE3D = CHE3D
  DEFB $01                 ;
  DEFB $43,$48,$45,$33,$C4 ;
  DEFB $E0,$F1             ;
  DEFB $A1,$E5,$92,$DE    ; NOG = SKIP_GRAVITY
  DEFB $01                ;
  DEFB $4E,$4F,$C7        ;
  DEFB $8C,$F6            ;
  DEFB $80,$E3,$9F,$DE    ; I0 = I0
  DEFB $01                ;
  DEFB $49,$B0            ;
  DEFB $1D,$F2            ;
  DEFB $43,$E0,$92,$E6         ; NOPROP = ADD_GRAVITY
  DEFB $01                     ;
  DEFB $4E,$4F,$50,$52,$4F,$D0 ;
  DEFB $7E,$F6                 ;
  DEFB $A8,$DE,$C6,$DE    ; I3 = I3
  DEFB $01                ;
  DEFB $49,$B3            ;
  DEFB $58,$F2            ;
  DEFB $00,$00,$B2,$DE    ; I00 = I00
  DEFB $01                ;
  DEFB $49,$30,$B0        ;
  DEFB $2C,$F2            ;
  DEFB $00,$00,$BC,$DE    ; I01 = I01
  DEFB $01                ;
  DEFB $49,$30,$B1        ;
  DEFB $45,$F2            ;
  DEFB $00,$00,$A7,$DF    ; I02 = I02
  DEFB $01                ;
  DEFB $49,$30,$B2        ;
  DEFB $4D,$F2            ;
  DEFB $00,$00,$D0,$DE    ; I30 = I30
  DEFB $01                ;
  DEFB $49,$33,$B0        ;
  DEFB $67,$F2            ;
  DEFB $D9,$DE,$2A,$DF    ; I8 = KNIGHT_UPDATE
  DEFB $01                ;
  DEFB $49,$B8            ;
  DEFB $CD,$F3            ;
  DEFB $E2,$DE,$F7,$DE    ; I4 = I4
  DEFB $01                ;
  DEFB $49,$B4            ;
  DEFB $75,$F2            ;
  DEFB $00,$00,$00,$00    ; I31 = I31
  DEFB $01                ;
  DEFB $49,$33,$B1        ;
  DEFB $72,$F2            ;
  DEFB $00,$00,$00,$00    ; KON6 = MOVE_IN_DIRECTION
  DEFB $01                ;
  DEFB $4B,$4F,$4E,$B6    ;
  DEFB $7D,$F6            ;
  DEFB $00,$00,$33,$DF    ; I5 = I5
  DEFB $01                ;
  DEFB $49,$B5            ;
  DEFB $9F,$F2            ;
  DEFB $15,$DF,$0A,$DF    ; BUT = WORKING_POSITION
  DEFB $01                ;
  DEFB $42,$55,$D4        ;
  DEFB $B0,$F7            ;
  DEFB $00,$00,$C3,$E0    ; BUT2 = WORKING_SIZES
  DEFB $01                ;
  DEFB $42,$55,$54,$B2    ;
  DEFB $BA,$F7            ;
  DEFB $3A,$E2,$41,$E1    ; BB2 = BOX_OVERLAP
  DEFB $01                ;
  DEFB $42,$42,$B2        ;
  DEFB $F2,$FC            ;
  DEFB $66,$E6,$00,$00    ; ANIM = ANIM
  DEFB $01                ;
  DEFB $41,$4E,$49,$CD    ;
  DEFB $45,$F6            ;
  DEFB $63,$E0,$51,$DF    ; I9 = I9
  DEFB $01                ;
  DEFB $49,$B9            ;
  DEFB $BE,$F2            ;
  DEFB $00,$00,$48,$DF    ; I50 = I50
  DEFB $01                ;
  DEFB $49,$35,$B0        ;
  DEFB $B5,$F2            ;
  DEFB $58,$E0,$6F,$DF    ; INP5 = KNIGHT_TURN
  DEFB $01                ;
  DEFB $49,$4E,$50,$B5    ;
  DEFB $D7,$F5            ;
  DEFB $00,$00,$84,$DF    ; I6 = CREATURE_UPDATE
  DEFB $01                ;
  DEFB $49,$B6            ;
  DEFB $09,$F3            ;
  DEFB $00,$00,$5B,$DF    ; I91 = I91
  DEFB $01                ;
  DEFB $49,$39,$B1        ;
  DEFB $F2,$F2            ;
  DEFB $00,$00,$65,$DF    ; I92 = I92
  DEFB $01                ;
  DEFB $49,$39,$B2        ;
  DEFB $EE,$F2            ;
  DEFB $00,$00,$00,$00    ; I95 = I95
  DEFB $01                ;
  DEFB $49,$39,$B5        ;
  DEFB $EB,$F2            ;
  DEFB $A8,$E1,$6D,$E0    ; INPE = SET_SPRITE_AND_MOVE
  DEFB $01                ;
  DEFB $49,$4E,$50,$C5    ;
  DEFB $77,$F6            ;
  DEFB $8F,$DF,$00,$00    ; ZZ1 = STEER
  DEFB $01                ;
  DEFB $5A,$5A,$B1        ;
  DEFB $F7,$F2            ;
  DEFB $BC,$DF,$9C,$DF    ; I600 = GUARD_FRAMES
  DEFB $01                ;
  DEFB $49,$36,$30,$B0    ;
  DEFB $3C,$F3            ;
  DEFB $CD,$E5,$00,$00         ; ZOOMIN = ZOOMIN
  DEFB $01                     ;
  DEFB $5A,$4F,$4F,$4D,$49,$CE ;
  DEFB $48,$FC                 ;
  DEFB $00,$00,$B1,$DF    ; I601 = GUARD_MOVES
  DEFB $01                ;
  DEFB $49,$36,$30,$B1    ;
  DEFB $11,$F3            ;
  DEFB $00,$00,$DA,$DF    ; I11 = CREATURE_UPDATE_4
  DEFB $01                ;
  DEFB $49,$31,$B1        ;
  DEFB $5A,$F3            ;
  DEFB $00,$00,$C6,$DF    ; I602 = CREATURE_UPDATE_0
  DEFB $01                ;
  DEFB $49,$36,$30,$B2    ;
  DEFB $35,$F3            ;
  DEFB $00,$00,$00,$00    ; I60 = CREATURE_UPDATE_1
  DEFB $01                ;
  DEFB $49,$36,$B0        ;
  DEFB $46,$F3            ;
  DEFB $00,$00,$D0,$DF    ; I61 = CREATURE_UPDATE_2
  DEFB $01                ;
  DEFB $49,$36,$B1        ;
  DEFB $4D,$F3            ;
  DEFB $00,$00,$3A,$E0    ; I62 = CREATURE_UPDATE_3
  DEFB $01                ;
  DEFB $49,$36,$B2        ;
  DEFB $54,$F3            ;
  DEFB $E4,$DF,$FB,$DF    ; I12 = CREATURE_UPDATE_6
  DEFB $01                ;
  DEFB $49,$31,$B2        ;
  DEFB $6F,$F3            ;
  DEFB $F0,$DF,$00,$00     ; I1110 = WRAITH_MOVES
  DEFB $01                 ;
  DEFB $49,$31,$31,$31,$B0 ;
  DEFB $5E,$F3             ;
  DEFB $00,$00,$00,$00,$01,$49,$31 ; The links of the next symbol, cut off by
                                   ; the game's code

; Print the closing lines of the quest
;
; Used by the routine at ROOMST.
;
; The author's MESS2: the source text at SOURCE_AFTER_OBJECTS calls MESS2 and
; jumps to WAIT at the end of ROOMST, just as the code there calls this and
; jumps to WAIT. Two lines under either ending's message in room 81, whether
; the quest succeeded or not: that the quest continues, and where -- the title
; of the sequel.
MESS2:
  CALL PRINT              ; The two lines follow the CALL.
  DEFB $C8,$28,$50        ; Print at x 40, y 80
  DEFB $14,$08,$05,$00,$11,$15,$05,$13 ; "THE QUEST CONTINUES IN"
  DEFB $14,$00,$03,$0F,$0E,$14,$09,$0E ;
  DEFB $15,$05,$13,$00,$09,$0E         ;
  DEFB $C8,$30,$28        ; Print at x 48, y 40
  DEFB $01,$00,$14,$12,$01,$09,$0C,$00 ; "A TRAIL OF DARKNESS"
  DEFB $0F,$06,$00,$04,$01,$12,$0B,$0E ;
  DEFB $05,$13,$13                     ;
  DEFB $A4                ; End of the string
  RET

; More of the symbol table
;
; Eighteen bytes of the assembler's symbol table left between MESS2 and
; SHOW_MESSAGE, the format of SYMBOL_TABLE: the last byte of a value, a whole
; symbol, and the start of another. The whole one is named I62, but its value
; is 43 more than the value the table at SYMBOL_TABLE gives I62 (both are
; instructions in CREATURE_UPDATE); two symbols of one name cannot be in one
; tree, so these scraps are from another state of the table than the one at
; SYMBOL_TABLE: an earlier assembly, or an earlier pass.
SYMBOLS_AFTER_MESS2:
  DEFB $F3                ; The end of a value; links, 1, the name I62 and its
  DEFB $00,$00,$96,$E0    ; value; the links and the 1 of a symbol whose name
  DEFB $01                ; the routine at SHOW_MESSAGE cuts off
  DEFB $49,$36,$B2        ;
  DEFB $7F,$F3            ;
  DEFB $40,$E0,$57,$E0    ;
  DEFB $01                ;
  DEFB $49,$31            ;

; Show a message under the room, and take it away again
;
; Used by the routine at MAIN_LOOP.
;
; Called once a pass by the main loop (MAIN_LOOP). A message is asked for by
; putting its number in IY+$07: 1 when the knight's way is blocked
; (CREATURE_UPDATE, BUMPED), 2 when a door is locked (BUMPED), 3 when what he
; would pick up is too heavy (PICK_UP_LOOK_ON). Message 1 prints a B and then
; shares message 2's word.
;
; The message is printed at x 28, y 12, over LIFE's digits, and stays for ten
; passes, counted in IY+$08, while bit 6 of IY+$17 is set; then nine spaces
; clear it, and bit 0 of IY+$17 asks the main loop to print LIFE again.
SHOW_MESSAGE:
  LD HL,$0C1C             ; Everything here prints at x 28, y 12.
  LD (PRINT_X),HL         ;
  LD A,(MESSAGE)          ; A new message?
  AND A                   ;
  JR NZ,SHOW_MESSAGE_0    ;
  BIT 6,(IY+GAME_FLAGS-V)  ; No: if one is showing, count down its passes.
  RET Z                    ;
  DEC (IY+MESSAGE_TIMER-V) ;
  RET NZ                   ;
  RES 6,(IY+GAME_FLAGS-V) ; Its time is up: clear it, and have LIFE printed
  SET 0,(IY+GAME_FLAGS-V) ; again.
  CALL PRINT              ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; "         "
  DEFB $00                             ;
  DEFB $A4                ; End of the string
  RET
SHOW_MESSAGE_0:
  LD (IY+MESSAGE_TIMER-V),$0A ; A new message: ten passes, and it has been
  SET 6,(IY+GAME_FLAGS-V)     ; taken.
  LD (IY+MESSAGE-V),$00       ;
  CP $01                  ; Message 1: B...
  JR NZ,SHOW_MESSAGE_1    ;
  CALL PRINT              ;
  DEFB $02                ; "B"
  DEFB $A4                ; End of the string
  JR SHOW_MESSAGE_2
SHOW_MESSAGE_1:
  CP $02                  ; Message 2.
  JR NZ,SHOW_MESSAGE_3    ;
SHOW_MESSAGE_2:
  CALL PRINT              ;
  DEFB $0C,$0F,$03,$0B,$05,$04 ; "LOCKED"
  DEFB $A4                ; End of the string
  RET
SHOW_MESSAGE_3:
  CP $03                  ; Message 3.
  RET NZ                  ;
  CALL PRINT              ;
  DEFB $14,$0F,$0F,$00,$08,$05,$01,$16 ; "TOO HEAVY"
  DEFB $19                             ;
  DEFB $A4                ; End of the string
  RET

; More of the symbol table
;
; Ten bytes of the symbol table left between SHOW_MESSAGE and the textures, as
; at SYMBOLS_AFTER_MESS2. They do not parse as cleanly: read as the end of a
; link, a flag byte of 0 (every whole symbol at SYMBOL_TABLE has 1 there), a
; one-letter name (J), its value (a jump target in this release, inside
; CREATURE_UPDATE), and the links and flag of the next symbol, cut off by the
; textures. Not settled.
SYMBOLS_BEFORE_TEXTURES:
  DEFB $00,$00            ; The end of a link; 0; J; its value; the next
  DEFB $CA                ; symbol's links and its 1
  DEFB $3C                ;
  DEFB $F4,$B9            ;
  DEFB $E0,$00,$00,$01    ;

; Texture 0 (fill code $E6)
TEXTURES:
  DEFB $55,$AA,$55,$AA,$55,$AA,$55,$AA ; Four columns of eight rows
  DEFB $55,$AA,$55,$AA,$55,$AA,$55,$AA ;
  DEFB $55,$AA,$55,$AA,$55,$AA,$55,$AA ;
  DEFB $55,$AA,$55,$AA,$55,$AA,$55,$AA ;

; Texture 1 (fill code $E7)
TEXTURE1:
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF ; Four columns of eight rows
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF ;
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF ;
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF ;

; Texture 2 (fill code $E8)
TEXTURE2:
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ; Four columns of eight rows
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ;
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ;
  DEFB $55,$55,$55,$55,$55,$55,$55,$55 ;

; Texture 3 (fill code $E9)
TEXTURE3:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ; Four columns of eight rows
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ;
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ;

; Texture 4 (fill code $EA)
TEXTURE4:
  DEFB $03,$0D,$3A,$D5,$3A,$0D,$03,$00 ; Four columns of eight rows
  DEFB $00,$C0,$B0,$5C,$AB,$5C,$B0,$CC ;
  DEFB $03,$CC,$37,$EA,$55,$EA,$35,$0E ;
  DEFB $03,$00,$00,$C0,$7B,$AC,$70,$C0 ;

; Texture 5 (fill code $EB)
TEXTURE5:
  DEFB $10,$10,$10,$FF,$01,$01,$01,$FF ; Four columns of eight rows
  DEFB $10,$10,$10,$FF,$01,$01,$01,$FF ;
  DEFB $10,$10,$10,$FF,$01,$01,$01,$FF ;
  DEFB $10,$10,$10,$FF,$01,$01,$01,$FF ;

; Texture 6 (fill code $EC)
TEXTURE6:
  DEFB $C4,$74,$4C,$43,$C0,$30,$0C,$07 ; Four columns of eight rows
  DEFB $C0,$30,$0C,$07,$C4,$74,$4C,$43 ;
  DEFB $C4,$74,$4C,$43,$C0,$30,$0C,$07 ;
  DEFB $C0,$30,$0C,$07,$C4,$74,$4C,$43 ;

; Texture 7 (fill code $ED)
TEXTURE7:
  DEFB $23,$2E,$32,$C2,$03,$0C,$30,$E0 ; Four columns of eight rows
  DEFB $03,$0C,$30,$E0,$23,$2E,$32,$C2 ;
  DEFB $23,$2E,$32,$C2,$03,$0C,$30,$E0 ;
  DEFB $03,$0C,$30,$E0,$23,$2E,$32,$C2 ;

; Texture 8 (fill code $EE)
TEXTURE8:
  DEFB $DF,$55,$DD,$55,$FD,$05,$FF,$50 ; Four columns of eight rows
  DEFB $FD,$05,$FF,$50,$DF,$55,$DD,$55 ;
  DEFB $DF,$55,$DD,$55,$FD,$05,$FF,$50 ;
  DEFB $FD,$05,$FF,$50,$DF,$55,$DD,$55 ;

; Texture 9 (fill code $EF)
TEXTURE9:
  DEFB $1E,$21,$81,$92,$B8,$44,$0F,$10 ; Four columns of eight rows
  DEFB $02,$07,$C8,$28,$11,$3A,$44,$84 ;
  DEFB $20,$71,$8B,$04,$0E,$31,$81,$41 ;
  DEFB $F3,$0C,$C4,$26,$19,$11,$73,$8C ;

; Texture 10 (fill code $F0)
TEXTURE10:
  DEFB $00,$00,$C3,$FF,$E7,$81,$00,$00 ; Four columns of eight rows
  DEFB $3C,$FF,$FF,$FF,$FF,$FF,$7E,$18 ;
  DEFB $00,$00,$C3,$FF,$E7,$81,$00,$00 ;
  DEFB $3C,$FF,$FF,$FF,$FF,$FF,$7E,$18 ;

; Texture 11 (fill code $F1)
TEXTURE11:
  DEFB $77,$AA,$77,$AA,$77,$AA,$57,$AA ; Four columns of eight rows
  DEFB $5D,$AA,$5D,$AA,$5D,$AA,$5D,$AA ;
  DEFB $57,$AA,$77,$AA,$77,$AA,$77,$AA ;
  DEFB $5D,$AA,$5D,$AA,$7D,$AA,$5D,$AA ;

; Texture 12 (fill code $F2)
TEXTURE12:
  DEFB $39,$32,$57,$53,$5A,$20,$0D,$50 ; Four columns of eight rows
  DEFB $30,$31,$51,$41,$E3,$C4,$E0,$E4 ;
  DEFB $B4,$BC,$BD,$BB,$AF,$B0,$B1,$C0 ;
  DEFB $A7,$A6,$BE,$AD,$B2,$BA,$E5,$A5 ;

; Texture 13 (fill code $F3)
TEXTURE13:
  DEFB $03,$0D,$38,$D0,$38,$0C,$03,$00 ; Four columns of eight rows
  DEFB $00,$C0,$30,$1C,$0B,$1C,$B0,$CC ;
  DEFB $03,$CC,$37,$E0,$40,$E0,$30,$0E ;
  DEFB $03,$00,$00,$C0,$7B,$2C,$70,$C0 ;

; Texture 14 (fill code $F4)
TEXTURE14:
  DEFB $41,$41,$41,$49,$41,$41,$41,$45 ; Four columns of eight rows
  DEFB $08,$88,$08,$08,$08,$08,$09,$08 ;
  DEFB $41,$05,$41,$41,$41,$41,$41,$41 ;
  DEFB $28,$08,$08,$08,$0A,$08,$48,$08 ;

; Texture 15 (fill code $F5)
TEXTURE15:
  DEFB $C0,$30,$1C,$07,$03,$04,$04,$04 ; Four columns of eight rows
  DEFB $10,$10,$10,$10,$F0,$78,$1E,$03 ;
  DEFB $C4,$FE,$4E,$83,$80,$80,$80,$80 ;
  DEFB $00,$00,$00,$00,$C0,$30,$1E,$1B ;

; Texture 16 (fill code $F6)
TEXTURE16:
  DEFB $08,$08,$08,$08,$0F,$1E,$78,$C0 ; Four columns of eight rows
  DEFB $03,$0C,$38,$E0,$C0,$20,$20,$20 ;
  DEFB $00,$00,$00,$00,$03,$0C,$78,$D8 ;
  DEFB $23,$7F,$72,$C1,$01,$01,$01,$01 ;

; Texture 17 (fill code $F7)
TEXTURE17:
  DEFB $00,$00,$00,$00,$03,$0C,$33,$C0 ; Four columns of eight rows
  DEFB $03,$0C,$30,$C0,$00,$00,$00,$C0 ;
  DEFB $00,$00,$00,$00,$03,$0C,$30,$C0 ;
  DEFB $33,$0C,$30,$C0,$00,$00,$00,$00 ;

; Texture 18 (fill code $F8)
TEXTURE18:
  DEFB $08,$A9,$42,$11,$0C,$96,$5C,$58 ; Four columns of eight rows
  DEFB $43,$08,$20,$04,$52,$23,$25,$B5 ;
  DEFB $14,$16,$24,$2A,$95,$0A,$3A,$D8 ;
  DEFB $42,$59,$16,$D5,$31,$A0,$15,$81 ;

; Texture 19 (fill code $F9)
TEXTURE19:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Four columns of eight rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Texture 20 (fill code $FA)
TEXTURE20:
  DEFB $88,$00,$22,$00,$88,$00,$22,$00 ; Four columns of eight rows
  DEFB $88,$00,$22,$00,$88,$00,$22,$00 ;
  DEFB $88,$00,$22,$00,$88,$00,$22,$00 ;
  DEFB $88,$00,$22,$00,$88,$00,$22,$00 ;

; Texture 21 (fill code $FB)
TEXTURE21:
  DEFB $1E,$61,$AD,$92,$B8,$44,$0F,$D0 ; Four columns of eight rows
  DEFB $42,$37,$C8,$2E,$D1,$3A,$45,$B4 ;
  DEFB $2E,$71,$8B,$34,$CE,$31,$8D,$51 ;
  DEFB $D3,$0C,$D4,$26,$D9,$15,$73,$8C ;

; Texture 22 (fill code $FC)
TEXTURE22:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Four columns of eight rows
  DEFB $18,$3C,$42,$42,$7E,$42,$42,$00 ;
  DEFB $24,$3C,$42,$42,$7E,$42,$42,$00 ;
  DEFB $24,$3C,$42,$42,$42,$42,$3C,$00 ;

; Texture 23 (fill code $FD)
TEXTURE23:
  DEFB $00,$10,$38,$04,$3C,$44,$3C,$00 ; Four columns of eight rows
  DEFB $00,$28,$38,$04,$3C,$44,$3C,$00 ;
  DEFB $00,$28,$38,$44,$44,$44,$38,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Texture 24 (fill code $FE)
TEXTURE24:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Four columns of eight rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Texture 25 (fill code $FF)
TEXTURE25:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; Four columns of eight rows
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;

; Redraw a rectangle of the screen from an image, its mask and the clean copy
;
; Used by the routines at CLEAR_THING_BOX and REDRAW_OBJECT.
;
; Krumlinde's RTN_Composite_To_Screen. The pixels the game draws on the screen
; once a room is drawn go through here (the colours are ATTRI's): a moving
; object's new picture (from REDRAW_OBJECT), the box on the panel for the thing
; in use (CLEAR_THING_BOX, SHOW_THING_IN_USE), and every character printed
; (PRINT, by way of the second entry, three instructions in).
;
; The rectangle's top left corner is x, y at IY+$64 and IY+$65 (y counted up
; from the bottom of the screen, as everywhere in the game), its width in bytes
; at IY+$73 and its height in rows at IY+$67. A row is written as its width
; plus one screen bytes, since the image is shifted to x's pixel within its
; byte, and each byte is made from four buffer pages ($D8 to $DB: the 1 KB
; after the clean copy, from offset 364 of SOURCE_AFTER_TEMPLATES), indexed by
; one count that goes on through the rows: where page $D8 has a bit set, the
; screen keeps what it has; elsewhere, where page $D9 has it clear, the pixel
; comes from the image (IX); where $D9 has it set, it comes from page $DB if
; page $DA has it set too (when bit 1 of IY+$71 says pages $DA and $DB are in
; use), and otherwise from the clean copy of the room, the byte 32 KB above the
; screen byte (the copy RESTOR and room code $E2 make).
;
; The callers fill the pages. For a moving object, REDRAW_OBJECT and the
; routines it calls (CULL_OBJECT, SORT_AND_DRAW_BEHIND, DRAW_SPRITE) fill them
; from the objects that overlap the rectangle: the object's own mask, what
; stands in front of it, and what moves behind it (see there). The printer
; clears pages $D8 and $D9, so a character is drawn as it is; CLEAR_THING_BOX
; sets every bit of page $D9, which puts the clean copy back over the box. The
; pixels to the left of x in each row's first byte are marked in page $D8 by
; this routine itself, so that they stay as they are.
;
; The shift is made by jumping into a run of seven RRCAs: the start rewrites
; the operand of the JR before them. It also rewrites the JRs round the steps
; for pages $DA and $DB (to skip them unless they are in use) and the one
; before a row's last byte (to skip it when x is on a byte boundary, as nothing
; spills into it). Rows above the top of the screen (y above 191) are skipped,
; and it stops at the bottom of the screen.
;
; At this entry the image's address is the word at IY+$68, and the routine
; starts three rows before it, as REDRAW_OBJECT's rectangle does; at the
; second, COMPOSITE_FROM_IX, three instructions in, HL is the address to start
; from.
COMPOSITE_TO_SCREEN:
  LD HL,(WORK_SPRITE)        ; HL: the image less three rows (IY+$73 bytes
  XOR A                      ; each): REDRAW_OBJECT's rectangle starts three
  LD D,A                     ; rows above the object's sprite.
  LD B,$03                   ;
COMPOSITE_TO_SCREEN_0:
  ADD A,(IY+DRAW_WIDTH-V)    ;
  DJNZ COMPOSITE_TO_SCREEN_0 ;
  LD E,A                     ;
  SBC HL,DE                  ;
; This entry point is used by the routines at PRINT_FIND_GLYPH and
; SHOW_THING_IN_USE.
COMPOSITE_FROM_IX:
  PUSH HL                 ; IX: where the image's bytes are read from.
  POP IX                  ;
  EXX                     ; C': the index into the pages, from 0.
  LD C,$00                ;
  EXX                     ;
  LD BC,(POINT)               ; B, C: the top left corner. Is the top on the
  LD A,$BF                    ; screen (y 191 or less)? A: 191 less y, its row
  SUB B                       ; from the top.
  JR NC,COMPOSITE_TO_SCREEN_2 ;
  EXX                     ; No: take the rows above the screen off the height;
  NEG                     ; if none are left, there is nothing to draw.
  LD B,A                  ;
  LD A,(SECOND_POINT_ROW) ;
  SUB B                   ;
  RET C                   ;
  RET Z                   ;
  LD (SECOND_POINT_ROW),A ;
  LD A,(SECOND_POINT)        ; And skip them: IX on by the width for each, the
  RRA                        ; page index by the width plus one.
  RRA                        ;
  RRA                        ;
  LD E,A                     ;
  INC A                      ;
  LD C,A                     ;
  XOR A                      ;
  LD D,A                     ;
COMPOSITE_TO_SCREEN_1:
  ADD IX,DE                  ;
  ADD A,C                    ;
  DJNZ COMPOSITE_TO_SCREEN_1 ;
  LD C,A                     ;
  EXX                     ; Start at the top row.
  XOR A                   ;
COMPOSITE_TO_SCREEN_2:
  CALL $22B0              ; HL: the screen address of the rectangle's first
                          ; byte (the ROM's PIXEL-ADD, from its LD B,A on); A:
                          ; x's pixel within its byte.
  PUSH HL                 ; Rewrite the JR into the RRCAs, to rotate the image
  CPL                     ; right by x's pixel.
  AND $07                 ;
  LD B,A                  ;
  LD ($E46C),A            ;
  XOR A                      ; D: the bits of a rotated byte that stay in their
  INC B                      ; own screen byte; E: those that spill into the
COMPOSITE_TO_SCREEN_3:
  SCF                        ; next.
  RLA                        ;
  DJNZ COMPOSITE_TO_SCREEN_3 ;
  LD D,A                     ;
  CPL                        ;
  LD E,A                     ;
  LD HL,$002C                ; Rewrite the JR before a row's last byte: skip it
  AND A                      ; when x is on a byte boundary.
  LD A,L                     ;
  JR Z,COMPOSITE_TO_SCREEN_4 ;
  XOR A                      ;
COMPOSITE_TO_SCREEN_4:
  LD ($E4AD),A               ;
  EXX                         ; Rewrite the two JRs round the steps for pages
  LD HL,$000D                 ; $DA and $DB: skip them unless bit 1 of IY+$71
  LD DE,$000D                 ; is set.
  LD A,E                      ;
  BIT 1,(IY+WORK_DIRECTION-V) ;
  JR Z,COMPOSITE_TO_SCREEN_5  ;
  XOR A                       ;
  LD L,A                      ;
COMPOSITE_TO_SCREEN_5:
  LD ($E487),A                ;
  LD A,L                      ;
  LD ($E4BD),A                ;
  POP HL                  ; HL': the screen address; B': page $D8.
  LD B,$D8                ;
COMPOSITE_TO_SCREEN_6:
  PUSH HL                 ; A row. The pixels left of x in its first byte are
  LD A,(BC)               ; marked in page $D8, to be left as they are.
  EXX                     ;
  OR E                    ;
  EXX                     ;
  LD (BC),A               ;
  EXX                     ; B: the image's bytes in a row; L: the bits spilt
  LD B,(IY+DRAW_WIDTH-V)  ; from the byte before, none yet.
  LD L,$00                ;
COMPOSITE_TO_SCREEN_7:
  LD A,(IX+$00)            ; Rotate the next image byte right by x's pixel (the
  JR COMPOSITE_TO_SCREEN_8 ; JR lands on the right RRCA).
COMPOSITE_TO_SCREEN_8:
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  RRCA                     ;
  LD H,A                  ; A: this byte's image bits, and those spilt from the
  AND D                   ; byte before.
  OR L                    ;
  EXX                      ; Page $D9: the image where it is clear, the clean
  LD E,A                   ; copy (the screen address with bit 7 set) where it
  INC B                    ; is set.
  LD A,(BC)                ;
  LD D,A                   ;
  CPL                      ;
  AND E                    ;
  LD E,A                   ;
  LD A,D                   ;
  SET 7,H                  ;
  AND (HL)                 ;
  RES 7,H                  ;
  OR E                     ;
  JR COMPOSITE_TO_SCREEN_9 ;
COMPOSITE_TO_SCREEN_9:
  LD E,A                  ; Where pages $D9 and $DA both have a bit set, page
  INC B                   ; $DB's bit (skipped unless bit 1 of IY+$71 is set).
  LD A,(BC)               ;
  AND D                   ;
  CPL                     ;
  LD D,A                  ;
  CPL                     ;
  OR E                    ;
  LD E,A                  ;
  INC B                   ;
  LD A,(BC)               ;
  OR D                    ;
  AND E                   ;
  LD E,A                  ; Page $D8: the screen's own bit where it is set, the
  LD B,$D8                ; new one elsewhere.
  LD A,(BC)               ;
  LD D,A                  ;
  CPL                     ;
  AND E                   ;
  LD E,A                  ;
  LD A,(HL)               ;
  AND D                   ;
  OR E                    ;
  LD (HL),A               ;
  INC L                   ; Next screen byte, next page index.
  INC C                   ;
  EXX                        ; Keep the bits that spill into the next byte;
  LD A,H                     ; next image byte.
  AND E                      ;
  LD L,A                     ;
  INC IX                     ;
  DJNZ COMPOSITE_TO_SCREEN_7 ;
  EXX                       ; The row's last screen byte, which only the spilt
  JR COMPOSITE_TO_SCREEN_10 ; bits reach (skipped when x is on a byte
                            ; boundary).
COMPOSITE_TO_SCREEN_10:
  LD E,A                    ; Page $D9, as above.
  INC B                     ;
  LD A,(BC)                 ;
  LD D,A                    ;
  CPL                       ;
  AND E                     ;
  LD E,A                    ;
  SET 7,H                   ;
  LD A,(HL)                 ;
  RES 7,H                   ;
  AND D                     ;
  OR E                      ;
  JR COMPOSITE_TO_SCREEN_11 ;
COMPOSITE_TO_SCREEN_11:
  LD E,A                  ; Pages $DA and $DB, as above.
  INC B                   ;
  LD A,(BC)               ;
  AND D                   ;
  CPL                     ;
  LD D,A                  ;
  CPL                     ;
  OR E                    ;
  LD E,A                  ;
  INC B                   ;
  LD A,(BC)               ;
  OR D                    ;
  AND E                   ;
  LD E,A                  ; Page $D8, and the bits right of the image's end (D)
  LD B,$D8                ; left as they are too.
  LD A,(BC)               ;
  EXX                     ;
  OR D                    ;
  EXX                     ;
  LD D,A                  ;
  CPL                     ;
  AND E                   ;
  LD E,A                  ;
  LD A,(HL)               ;
  AND D                   ;
  OR E                    ;
  LD (HL),A               ;
  POP HL                      ; Next row: the page index past the row's last
  INC C                       ; byte; one row fewer to do.
  INC H                       ;
  DEC (IY+SECOND_POINT_ROW-V) ;
  RET Z                       ;
  LD A,H                      ; The screen address of the row below; stop at
  AND $07                     ; the bottom of the screen.
  JP NZ,COMPOSITE_TO_SCREEN_6 ;
  LD A,L                      ;
  ADD A,$20                   ;
  LD L,A                      ;
  LD A,H                      ;
  JR C,COMPOSITE_TO_SCREEN_12 ;
  SUB $08                     ;
COMPOSITE_TO_SCREEN_12:
  LD H,A                      ;
  CP $58                      ;
  RET NC                      ;
  JP COMPOSITE_TO_SCREEN_6    ;

; Move an object to a new position, and its sprite on the screen with it
;
; Used by the routines at PLACE_FROM_TEMPLATE, CREATURE_UPDATE,
; ANIMATE_AND_MOVE and BUMPED.
;
; Krumlinde's RTN_Iso_Project. The new position is compared with the record's
; (+6 to +8), field by field, and the sprite's place on the screen (+0, +1)
; moved by the difference, projected: a step along +6 moves it one pixel right
; and half a row up, a step along +8 one pixel left and half a row up, and a
; step up in +7 (the height) one row up. So, give or take a constant, x is +6
; less +8 and y is (+6 plus +8) / 2 plus +7, and the far corner of a room is at
; the top of the screen.
;
; Half rows are rounded towards zero, and C remembers whether +6's half was
; rounded: when both +6 and +8 move an odd amount the same way, the two halves
; make a whole row between them. An odd move along one axis alone would lose
; its half row, but the knight moves two at a step (measured, walking each way
; in the simulator: x by 2 and y by 1 a step).
;
; Called when an object is made for a room (PLACE_FROM_TEMPLATE, after setting
; its record to 50, its height plus 50, 50, the position its template's screen
; place is drawn for) and when things move (CREATURE_UPDATE, ANIMATE_AND_MOVE,
; BUMPED).
;
; IX The object's record
; B The new +6
; D The new +7 (the height of its top)
; H The new +8
ISO_MOVE:
  PUSH HL                 ; Keep H, the new +8; HL: the sprite's place on the
  LD C,$00                ; screen, x and y.
  LD L,(IX+OBJ_SCREEN_X)  ;
  LD H,(IX+OBJ_SCREEN_Y)  ;
  LD A,B                  ; How far +6 moves (not at all: on to the height).
  SUB (IX+OBJ_X)          ;
  JR Z,ISO_MOVE_3         ;
  LD E,A                  ; Further: half of it, rounded down; bit 0 of C set
  JR C,ISO_MOVE_0         ; if it was odd.
  SRL A                   ;
  JR NC,ISO_MOVE_2        ;
  SET 0,C                 ;
  JR ISO_MOVE_2           ;
ISO_MOVE_0:
  NEG                     ; Back: half of it, rounded towards zero; bit 1 of C
  SRL A                   ; set if it was odd.
  JR NC,ISO_MOVE_1        ;
  SET 1,C                 ;
ISO_MOVE_1:
  NEG                     ;
ISO_MOVE_2:
  ADD A,H                 ; y up by the half, x right by the whole; the new +6.
  LD H,A                  ;
  LD A,E                  ;
  ADD A,L                 ;
  LD L,A                  ;
  LD (IX+OBJ_X),B         ;
ISO_MOVE_3:
  LD A,D                  ; y up by the change in the height; the new +7.
  SUB (IX+OBJ_TOP)        ;
  ADD A,H                 ;
  LD H,A                  ;
  LD (IX+OBJ_TOP),D       ;
  POP DE                  ; How far +8 moves.
  LD A,D                  ;
  SUB (IX+OBJ_Z)          ;
  LD E,A                  ;
  JR C,ISO_MOVE_4         ; Further: half of it, and a row more if +6 moved an
  SRL A                   ; odd amount the same way.
  JR NC,ISO_MOVE_6        ;
  BIT 0,C                 ;
  JR Z,ISO_MOVE_6         ;
  INC A                   ;
  JR ISO_MOVE_6           ;
ISO_MOVE_4:
  NEG                     ; Back: the same, the other way.
  SRL A                   ;
  JR NC,ISO_MOVE_5        ;
  BIT 1,C                 ;
  JR Z,ISO_MOVE_5         ;
  INC A                   ;
ISO_MOVE_5:
  NEG                     ;
ISO_MOVE_6:
  ADD A,H                 ; y up by the half, x left by the whole.
  LD H,A                  ;
  LD A,L                  ;
  SUB E                   ;
  LD L,A                  ;
  LD (IX+OBJ_Z),D         ; The new +8, and the sprite's new place.
  LD (IX+OBJ_SCREEN_X),L  ;
  LD (IX+OBJ_SCREEN_Y),H  ;
  RET                     ;

; Draw the room the knight is in
;
; Used by the routines at TITLE_SCREEN and ROOMST.
;
; Called by ROOMST for every room entered, and by TITLE_SCREEN for the title
; (room 79, put in IY+$34 for the purpose), for GAME OVER (room 1) and at the
; end of the quest (room 81). The flag that says the room's objects have been
; placed (bit 0 of IY+$3C) is cleared, so that its $E4 $04 or $E4 $05 places
; them once however many parts it draws; the room is found by walking the table
; at ROOM1 from room 1, each record's first word its length; the drawing
; variables are set from ROOM_DEFAULTS; and the room is drawn from its colour
; byte on (DRAW_ROOM_RECORD).
;
; Stage 1 called it DRAW_ROOM_NUMBER, which reads as if it drew a number.
DRAW_CURRENT_ROOM:
  RES 0,(IY+OBJECTS_PLACED-V) ; Let the room place its objects again
                              ; (MORE_ROOM_COMMANDS, room code $E4 $04 or $05).
  LD HL,ROOM1              ; Find the room's record: room n is the nth, each
  XOR A                    ; skipped by its length.
DRAW_CURRENT_ROOM_0:
  LD E,(HL)                ;
  INC HL                   ;
  LD D,(HL)                ;
  DEC HL                   ;
  INC A                    ;
  CP (IY+ROOM-V)           ;
  JR Z,DRAW_CURRENT_ROOM_1 ;
  ADD HL,DE                ;
  JR DRAW_CURRENT_ROOM_0   ;
DRAW_CURRENT_ROOM_1:
  INC HL                  ; IX: the room's colour byte, after the length.
  INC HL                  ;
  PUSH HL                 ;
  POP IX                  ;
  LD HL,ROOM_DEFAULTS     ; The drawing variables' starting values, into IY+$5F
  LD DE,ORIGIN            ; to IY+$72.
  LD BC,$0014             ;
  LDIR                    ;
  JR DRAW_ROOM_RECORD     ; Draw it.

; What the drawing variables start as in each room
;
; Twenty bytes, copied to IY+$5F to IY+$72 by DRAW_CURRENT_ROOM before a room
; is drawn. The byte after them is not copied, and nothing reads it.
ROOM_DEFAULTS:
  DEFB $00,$00,$00,$00,$00 ; Into IY+$5F to IY+$68: the origin for the objects
  DEFB $32,$32,$32,$32,$38 ; placed (0, 0, 0); a word other code uses (0); the
                           ; point and the second point (50, 50 and 50, 50);
                           ; $38 for the attributes, which DRAW_ROOM_RECORD
                           ; replaces with 0 before anything reads it
  DEFB $00,$00,$00,$00,$00 ; Into IY+$69 to IY+$72: 0; lines to the screen, not
  DEFB $00,$00,$00,$00,$80 ; the fill's map (IY+$6A: 0); the mode, the repeat
                           ; count and the repeat's address (0); two bytes the
                           ; object code uses (0); and $80 in IY+$72, which the
                           ; code that moves things reads
  DEFB $00                ; Not copied

; Draw a room from its record
;
; Used by the routine at DRAW_CURRENT_ROOM.
;
; The screen is cleared (CLEAR_ROOM_SCREEN) with black ink on black paper, so
; the drawing cannot be seen until ATTRI colours it; the record's first byte is
; kept as the room's colour (IY+$0E); and its commands are carried out one at a
; time by DO_ROOM_COMMAND, until the $E5 that ends them. The format is laid out
; command by command in each room's entry (room 1's is ROOM1).
;
; The loop (RUN_ROOM_COMMANDS, after the colour byte) is also how a part is
; drawn: room codes $E0 and $E1 (MORE_ROOM_COMMANDS) find the part in the table
; at PART1 and run its commands through it, recursively. A part has no colour
; byte.
;
; IX The room's record, at its colour byte
DRAW_ROOM_RECORD:
  XOR A                   ; The attributes' byte 0, and the screen cleared.
  LD (WORK_SPRITE),A      ;
  CALL CLEAR_ROOM_SCREEN  ;
  LD A,(IX+$00)           ; The room's colour.
  LD (ROOM_COLOUR),A      ;
  INC IX                  ;
; This entry point is used by the routine at MORE_ROOM_COMMANDS.
RUN_ROOM_COMMANDS:
  LD A,(IX+$00)           ; The next command; $E5 ends the room, or the part.
  CP $E5                  ;
  RET Z                   ;
  LD D,(IY+MODE-V)        ; Carry it out, with D the mode byte (IY+MODE-V).
  CALL DO_ROOM_COMMAND    ;
  LD IY,OBJECT_COUNT      ; IY back at the variables after every command,
                          ; though none of them moves it.
  INC IX                  ; On past the command's last byte.
  JR RUN_ROOM_COMMANDS    ;

; Clear the screen
;
; Used by the routine at DRAW_ROOM_RECORD.
;
; Krumlinde's RTN_Clear_Room_Screen. The attributes are filled with the byte at
; IY+$68 (always 0: DRAW_ROOM_RECORD sets it just before) and the pixels with
; zeros, by pushing: SP is pointed at the end of each area in turn, the value
; pushed eight bytes at a time, and SP put back. The second area is filled by
; falling into the loop the first was filled by with a CALL.
CLEAR_ROOM_SCREEN:
  LD HL,SPRITE5B00         ; The attributes: 96 turns, down from their end.
  LD A,(WORK_SPRITE)       ;
  LD E,A                   ;
  LD D,A                   ;
  LD BC,$0060              ;
  CALL CLEAR_ROOM_SCREEN_0 ;
  LD DE,$0000             ; Then the pixels, below them: 768 turns of zeros.
  LD BC,$0300             ;
CLEAR_ROOM_SCREEN_0:
  LD (FOUND_RECORD),SP    ; Keep SP; SP at the top of the area.
  LD SP,HL                ;
CLEAR_ROOM_SCREEN_1:
  PUSH DE                   ; Eight bytes a turn.
  PUSH DE                   ;
  PUSH DE                   ;
  PUSH DE                   ;
  DEC BC                    ;
  LD A,B                    ;
  OR C                      ;
  JR NZ,CLEAR_ROOM_SCREEN_1 ;
  LD (CLEAR_END),SP       ; HL: where the fill stopped, the top of the next
  LD HL,(CLEAR_END)       ; area; SP back.
  LD SP,(FOUND_RECORD)    ;
  RET                     ;

; Carry out one room command
;
; Used by the routine at DRAW_ROOM_RECORD.
;
; One command of a room's (or a part's) drawing, at IX; on return IX is at its
; last byte, and the loop (DRAW_ROOM_RECORD) steps past it. The commands are
; laid out in the rooms' entries; this is what they do. The point is x, y at
; IY+$64, IY+$65 and the second point at IY+$66, IY+$67; y counts up from the
; bottom of the screen, and rows go modulo 192.
;
; Points, $00-$BF: the byte is a row, the next a column, and the point moves
; there. With mode bit 4 the two are added to the point instead; bit 6 mirrors
; the column (255 less it, or negated when it is added); bit 3 moves the second
; point by as much as the point; bit 5 draws a line from the second point to
; the new point (MORE_ROOM_COMMANDS); and bit 2 then makes the new point the
; second point too, so that the next line starts where this one ended.
;
; $C0, a row and a column: the second point, set, or with bit 4 moved, as a
; point is. $CF: the second point to the point. $D0: the two swapped. $D6: the
; end of a repeat started by $D5 (MORE_ROOM_COMMANDS): IY+$6C counted down, and
; back to just after the $D5 while it has not run out. $E6-$FF: a flood fill
; with a texture from the point (FILL_NEXT_SEED; the textures are 32 bytes each
; from TEXTURES -- not all of them patterns). Everything else goes on to
; MORE_ROOM_COMMANDS: lines, the mode bits, the repeat's start, parts, the
; clean copy, and $E4 and its sub-commands.
;
; In object mode (mode bit 7, which $E4 $04 sets for the rest of the room), a
; code below $E4 is an object: its type and four bytes, made into an object
; record at the next free one (IY+$38) by PLACE_OBJECT; $E4 does nothing; and
; $E6 up are patches (PATCH_RECORDS), which set the room's floor, ceiling and
; walls (FIXED_RECORDS) from the table of patches (at offset 778 of TEMPLATES).
;
; A The command
; D The mode byte (IY+$6B)
; IX The command's address
DO_ROOM_COMMAND:
  BIT 7,D                 ; Object mode?
  JR Z,DO_ROOM_COMMAND_1  ;
  CP $E4                  ; Yes: $E4 does nothing; $E6 up are patches.
  RET Z                   ;
  JR NC,PATCH_RECORDS     ;
  PUSH IX                 ; An object: HL at its type, IX at the next free
  PUSH IX                 ; record, and the record made.
  POP HL                  ;
  LD IX,(FREE_RECORD)     ;
  CALL PLACE_OBJECT       ;
  POP IX                  ; IX at the object's last byte.
  LD DE,$0004             ;
  ADD IX,DE               ;
  RET                     ;
PATCH_RECORDS:
  PUSH IX                 ; PATCH_RECORDS: IX at record 1 (the floor); HL at
  LD IX,FIXED_RECORDS     ; patch n (the code less $E5), six bytes each from
  SUB $E5                 ; the table's base.
  LD B,A                  ;
  LD DE,$0006             ;
  LD HL,PATCHES           ;
DO_ROOM_COMMAND_0:
  ADD HL,DE               ;
  DJNZ DO_ROOM_COMMAND_0  ;
  LD A,(HL)                    ; Its six bytes into the floor's and the
  INC HL                       ; ceiling's +7, the walls' +6 (records 3 and 4)
  LD (IX+OBJ_TOP),A            ; and the other walls' +8 (records 5 and 6).
  LD A,(HL)                    ;
  INC HL                       ;
  LD (IX+OBJ_SIZE+OBJ_TOP),A   ;
  LD A,(HL)                    ;
  INC HL                       ;
  LD (IX+$02*OBJ_SIZE+OBJ_X),A ;
  LD A,(HL)                    ;
  INC HL                       ;
  LD (IX+$03*OBJ_SIZE+OBJ_X),A ;
  LD A,(HL)                    ;
  INC HL                       ;
  LD (IX+$04*OBJ_SIZE+OBJ_Z),A ;
  LD A,(HL)                    ;
  LD (IX+$05*OBJ_SIZE+OBJ_Z),A ;
  POP IX
  RET
DO_ROOM_COMMAND_1:
  CP $C0                   ; A point ($00-$BF)?
  JR NC,DO_ROOM_COMMAND_11 ;
  LD BC,(POINT)           ; BC: the point as it was; H: the row; A: the column.
  LD H,A                  ;
  INC IX                  ;
  LD A,(IX+$00)           ;
  BIT 6,D                 ; Mode bit 6 mirrors the column: 255 less it, or
  JR Z,DO_ROOM_COMMAND_3  ; negated when it is added (bit 4).
  BIT 4,D                 ;
  JR Z,DO_ROOM_COMMAND_2  ;
  NEG                     ;
  JR DO_ROOM_COMMAND_3    ;
DO_ROOM_COMMAND_2:
  CPL                     ;
DO_ROOM_COMMAND_3:
  LD L,A                  ; Added to the point (mode bit 4)?
  BIT 4,D                 ;
  JR Z,DO_ROOM_COMMAND_6  ;
  ADD A,C                 ; Yes: the column to x, and the row to y, modulo 192
  LD C,A                  ; (a sum that carries, or reaches 192, has 64 added).
  LD A,H                  ;
  ADD A,B                 ;
  JR C,DO_ROOM_COMMAND_4  ;
  CP $C0                  ;
  JR C,DO_ROOM_COMMAND_5  ;
DO_ROOM_COMMAND_4:
  ADD A,$40               ;
DO_ROOM_COMMAND_5:
  LD B,A                  ;
  JR DO_ROOM_COMMAND_7    ;
DO_ROOM_COMMAND_6:
  LD C,A                  ; No: the point is the row and column.
  LD B,H                  ;
DO_ROOM_COMMAND_7:
  BIT 3,D                 ; Mode bit 3: the second point moves as far as the
  JR Z,DO_ROOM_COMMAND_9  ; point does (its row modulo 192).
  LD A,(SECOND_POINT)     ;
  ADD A,C                 ;
  SUB (IY+POINT-V)        ;
  LD (SECOND_POINT),A     ;
  LD A,(SECOND_POINT_ROW) ;
  ADD A,B                 ;
  SUB (IY+POINT_ROW-V)    ;
  CP $C0                  ;
  JR C,DO_ROOM_COMMAND_8  ;
  ADD A,$40               ;
DO_ROOM_COMMAND_8:
  LD (SECOND_POINT_ROW),A ;
DO_ROOM_COMMAND_9:
  LD A,B                  ; The new point (its row modulo 192 again, which
  CP $C0                  ; cannot matter: never ran).
  JR C,DO_ROOM_COMMAND_10 ;
  ADD A,$40               ;
DO_ROOM_COMMAND_10:
  LD B,A                  ;
  LD (POINT),BC           ;
  BIT 5,D                 ; Mode bit 5: a line from the second point to it.
  CALL NZ,DRAW_LINE       ;
  BIT 2,(IY+MODE-V)       ; Mode bit 2: the second point follows.
  RET Z                   ;
  LD HL,(POINT)           ;
  LD (SECOND_POINT),HL    ;
  RET                     ;
DO_ROOM_COMMAND_11:
  CP $CF                   ; $CF: the second point to the point.
  JR NZ,DO_ROOM_COMMAND_12 ;
  LD HL,(POINT)            ;
  LD (SECOND_POINT),HL     ;
  RET                      ;
DO_ROOM_COMMAND_12:
  CP $C0                   ; $C0: a second point, a row and a column.
  JR NZ,DO_ROOM_COMMAND_18 ;
  INC IX                   ;
  BIT 4,D                  ;
  JR NZ,DO_ROOM_COMMAND_14 ;
  LD A,(IX+$00)           ; Set: the row, then the column, mirrored with mode
  LD (SECOND_POINT_ROW),A ; bit 6 (never in any room: the CPL never ran).
  INC IX                  ;
  LD A,(IX+$00)           ;
  BIT 6,D                 ;
  JR Z,DO_ROOM_COMMAND_13 ;
  CPL                     ;
DO_ROOM_COMMAND_13:
  LD (SECOND_POINT),A     ;
  RET                     ;
DO_ROOM_COMMAND_14:
  LD A,(IX+$00)                 ; Or added to it (mode bit 4): the row modulo
  ADD A,(IY+SECOND_POINT_ROW-V) ; 192, the column negated with bit 6.
  JR C,DO_ROOM_COMMAND_15       ;
  CP $C0                        ;
  JR C,DO_ROOM_COMMAND_16       ;
DO_ROOM_COMMAND_15:
  ADD A,$40                     ;
DO_ROOM_COMMAND_16:
  LD (SECOND_POINT_ROW),A       ;
  INC IX                        ;
  LD A,(IX+$00)                 ;
  BIT 6,D                       ;
  JR Z,DO_ROOM_COMMAND_17       ;
  NEG                           ;
DO_ROOM_COMMAND_17:
  ADD A,(IY+SECOND_POINT-V)     ;
  JR DO_ROOM_COMMAND_13         ;
DO_ROOM_COMMAND_18:
  CP $D6                   ; $D6: the end of a repeat. Count down; not run out,
  JR NZ,DO_ROOM_COMMAND_19 ; back to the $D5's count byte.
  DEC (IY+REPEATS-V)       ;
  RET Z                    ;
  LD IX,(REPEAT_FROM)      ;
  RET                      ;
DO_ROOM_COMMAND_19:
  CP $D0                   ; $D0: the points swapped.
  JR NZ,DO_ROOM_COMMAND_20 ;
  LD HL,(POINT)            ;
  LD DE,(SECOND_POINT)     ;
  LD (SECOND_POINT),HL     ;
  LD (POINT),DE            ;
  RET                      ;
DO_ROOM_COMMAND_20:
  CP $E6                  ; The rest below $E6 go on to MORE_ROOM_COMMANDS.
  JP C,MORE_ROOM_COMMANDS ;
  SUB $E6                 ; A fill: the texture's address, 32 bytes each from
  LD E,A                  ; TEXTURES, kept at IY+$78.
  LD D,$00                ;
  LD B,$05                ;
DO_ROOM_COMMAND_21:
  SLA E                   ;
  RL D                    ;
  DJNZ DO_ROOM_COMMAND_21 ;
  LD HL,TEXTURES          ;
  ADD HL,DE               ;
  LD (FOUND_RECORD),HL    ;
  LD BC,(POINT)           ; Nothing to fill if the point is set in the fill's
  CALL BUFFER_PIXEL       ; map already.
  AND (HL)                ;
  RET NZ                  ;
  LD H,$FE                ; Push the end marker (its high byte $FE), and fill
  PUSH HL                 ; from the point.
  JR FILL_SEED            ;

; Fill the next run of a flood fill
;
; Used by the routine at FILL_NEXT_PIXEL.
;
; The textured flood fill of room codes $E6-$FF (DO_ROOM_COMMAND), with the
; machine stack as its list of places still to fill. A place is x, y in C, B (y
; up from the bottom), and the list ends at a word whose high byte is $FE,
; pushed before the first. The fill's map is the 6 KB 32 KB above the screen,
; laid out like it: the pixels set there bound the fill (room code $E4 $00
; clears it and sends the lines there, and $E2 copies the screen there), and
; the fill sets there every pixel it fills. For each place taken off the list:
; if it is off the top or the bottom of the screen, or already set in the map,
; it is dropped; otherwise the fill goes right to the last clear pixel of its
; run, and from there fills leftwards a pixel at a time (FILL_NEXT_PIXEL),
; writing the texture's pixels to the screen, setting them in the map, and
; pushing a place in the row above or below each time a clear run begins there.
;
; This part sets up a run: the map addresses of its pixel and of the pixels
; above and below it (IY+$7B, IY+$7D, IY+$76), and the texture's two bytes for
; the row (B' the one for this byte, C' the other). A texture is 16 pixels by
; 16 rows, in four 8 by 8 cells: bytes 0-7 and 8-15 the left and right cells
; for the character rows in which y has bit 3 set, bytes 16-23 and 24-31 for
; the others; each cell's bytes run from the top of its character row. So the
; pattern lines up with the screen's character cells, and with the colours,
; whatever the area's shape.
FILL_NEXT_SEED:
  POP BC                  ; The next place; the end marker ends the fill; a
  LD A,B                  ; place off the screen (y 192 or more, or below 0) is
  CP $FE                  ; dropped.
  RET Z                   ;
  CP $C0                  ;
  JR NC,FILL_NEXT_SEED    ;
; This entry point is used by the routine at DO_ROOM_COMMAND.
FILL_SEED:
  CALL BUFFER_PIXEL       ; FILL_SEED, where DO_ROOM_COMMAND starts: dropped if
  AND (HL)                ; its pixel is set in the map (HL the byte, D the
  JR NZ,FILL_NEXT_SEED    ; bit).
FILL_NEXT_SEED_0:
  AND (HL)                ; Go right to a set pixel, or to the screen's right
  JR NZ,FILL_NEXT_SEED_1  ; edge (x back round to 0).
  INC C                   ;
  RRC D                   ;
  LD A,D                  ;
  JR NC,FILL_NEXT_SEED_0  ;
  INC HL                  ;
  DEC C                   ;
  INC C                   ;
  JR NZ,FILL_NEXT_SEED_0  ;
FILL_NEXT_SEED_1:
  LD E,$00                ; Back one pixel, the run's last clear one; E: no run
  DEC C                   ; open above or below yet.
  RLC D                   ;
  JR NC,FILL_NEXT_SEED_2  ;
  DEC HL                  ;
FILL_NEXT_SEED_2:
  LD (STEP_AXES),HL       ; Keep its map address; HL: its screen address.
  LD A,H                  ;
  SUB $80                 ;
  LD H,A                  ;
  PUSH HL                 ; The map address of the pixel above (y plus 1): the
  INC B                   ; screen address a line up, worked out afresh across
  DEC H                   ; the top of a character row.
  LD A,H                  ;
  AND $07                 ;
  XOR $07                 ;
  CALL Z,PIXEL_ADDRESS    ;
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  LD (WORK_RECORD),HL     ;
  POP HL                  ; And of the pixel below.
  DEC B                   ;
  DEC B                   ;
  INC H                   ;
  LD A,H                  ;
  AND $07                 ;
  CALL Z,PIXEL_ADDRESS    ;
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  INC B                   ;
  LD (WORK_HEADING),HL    ;
  PUSH BC                 ; x, y into BC'.
  EXX                     ;
  POP BC                  ;
  LD HL,(FOUND_RECORD)    ; HL': the texture's byte for this row of the left
  XOR A                   ; cell: the second half unless bit 3 of y is set, and
  BIT 3,B                 ; the row within the character row, from the top.
  JR NZ,FILL_NEXT_SEED_3  ;
  LD A,$10                ;
FILL_NEXT_SEED_3:
  ADD A,L                 ;
  LD L,A                  ;
  LD A,B                  ;
  CPL                     ;
  AND $07                 ;
  ADD A,L                 ;
  LD L,A                  ;
  LD A,C                  ; C' the left cell's byte, B' the right's; swapped
  LD C,(HL)               ; when bit 3 of x is clear, so that B' is this
  LD DE,$0008             ; byte's.
  ADD HL,DE               ;
  LD B,(HL)               ;
  BIT 3,A                 ;
  JR NZ,FILL_NEXT_SEED_4  ;
  LD E,B                  ;
  LD B,C                  ;
  LD C,E                  ;
FILL_NEXT_SEED_4:
  LD E,B                  ; E': this byte's; HL': the screen address; and on to
  LD HL,(STEP_AXES)       ; fill leftwards.
  LD A,H                  ;
  SUB $80                 ;
  LD H,A                  ;
  EXX                     ;
  JR FILL_THIS_PIXEL      ;

; Paint one row of the textured fill, a pixel at a time, leftwards
;
; Used by the routine at FILL_WHOLE_BYTE.
;
; The inner loop of the flood fill that the room codes $E6-$FF start
; (DO_ROOM_COMMAND) and FILL_NEXT_SEED feeds with runs to fill. It walks
; leftwards along one row from the right-hand end of an unfilled run until it
; meets a pixel that is already set in the clean copy of the screen
; (LOADING_TUNE, the fill's map of what bounds it and what it has done) or the
; left edge of the screen. Each pixel is set in the clean copy, so that the
; fill never comes back to it, and set or cleared on the screen from the
; texture: the texture replaces whatever was drawn there.
;
; As it goes it watches the rows above and below. Where a clear pixel follows a
; set one there, a run opens, and its row and column are pushed on the machine
; stack for FILL_NEXT_SEED to fill later; bits 0 (above) and 1 (below) of E
; remember that a run is open, so that a long run is pushed once rather than at
; every pixel. A run in a row off the screen (above the top or below the
; bottom, where the pointers land in other memory) may be pushed too, and
; FILL_NEXT_SEED throws it away. When the mask in D moves into the next byte to
; the left, FILL_BYTE_TO_LEFT moves every pointer a byte left and
; FILL_WHOLE_BYTE may paint the whole byte at once.
;
; Krumlinde's name (Fill_NextPixel). The entry at FILL_THIS_PIXEL is where
; FILL_NEXT_SEED starts a run.
;
; B Row of the pixel just painted, counted from the bottom (0-191)
; C Its column
; D Its mask (bit 7 the left-hand pixel of the byte)
; E Bit 0: a run is open in the row above; bit 1: in the row below
; HL' The screen byte
; E' The texture's byte for this screen byte; B' and C' the texture's two bytes
;    for the row
FILL_NEXT_PIXEL:
  LD A,C                  ; the left edge of the screen ends the run: on to the
  AND A                   ; next (FILL_NEXT_SEED)
  JP Z,FILL_NEXT_SEED     ;
  DEC C                    ; one pixel left; into the next byte when the mask
  RLC D                    ; wraps round
  CALL C,FILL_BYTE_TO_LEFT ;
; This entry point is used by the routine at FILL_NEXT_SEED.
FILL_THIS_PIXEL:
  LD HL,(STEP_AXES)       ; already set in the clean copy: the run ends here
  LD A,D                  ;
  AND (HL)                ;
  JP NZ,FILL_NEXT_SEED    ;
  LD A,D                  ; set it there, so that the fill never comes back
  OR (HL)                 ;
  LD (HL),A               ;
  LD A,D                  ; the screen's pixel: set where the texture has a 1,
  EXX                     ; cleared where it has a 0
  LD D,A                  ;
  AND E                   ;
  JR NZ,FILL_NEXT_PIXEL_0 ;
  LD A,D                  ;
  CPL                     ;
  AND (HL)                ;
  JR FILL_NEXT_PIXEL_1    ;
FILL_NEXT_PIXEL_0:
  OR (HL)                 ;
FILL_NEXT_PIXEL_1:
  LD (HL),A               ;
  EXX                     ; the row above: is a run open there?
  LD HL,(WORK_RECORD)     ;
  LD A,D                  ;
  BIT 0,E                 ;
  JR NZ,FILL_NEXT_PIXEL_2 ;
  AND (HL)                ; no: a clear pixel above opens one; push its row and
  JR NZ,FILL_NEXT_PIXEL_3 ; column
  INC B                   ;
  PUSH BC                 ;
  SET 0,E                 ;
  DEC B                   ;
  JR FILL_NEXT_PIXEL_3    ;
FILL_NEXT_PIXEL_2:
  AND (HL)                ; yes: a set pixel above closes it
  JR Z,FILL_NEXT_PIXEL_3  ;
  RES 0,E                 ;
FILL_NEXT_PIXEL_3:
  LD HL,(WORK_HEADING)    ; the row below, the same way
  LD A,D                  ;
  BIT 1,E                 ;
  JR NZ,FILL_NEXT_PIXEL_4 ;
  AND (HL)                ; none open: a clear pixel below opens one
  JR NZ,FILL_NEXT_PIXEL   ;
  DEC B                   ;
  PUSH BC                 ;
  SET 1,E                 ;
  INC B                   ;
  JR FILL_NEXT_PIXEL      ;
FILL_NEXT_PIXEL_4:
  AND (HL)                ; one open: a set pixel closes it
  JR Z,FILL_NEXT_PIXEL    ;
  RES 1,E                 ;
  JR FILL_NEXT_PIXEL      ;

; Fill a whole byte at once when nothing in it needs looking at pixel by pixel
;
; Used by the routine at FILL_BYTE_TO_LEFT.
;
; Jumped to from FILL_BYTE_TO_LEFT when the fill has just moved into a new
; byte. The whole byte is painted in one go only when nothing in it could
; change the fill's course: all eight pixels are clear in the clean copy, and
; each neighbouring row is the same all along the byte -- all clear if a run is
; open there (the run just goes on), all set if none is (none can open). Then
; all eight are marked in the clean copy, the texture's byte is written to the
; screen whole, and the loop goes on from the byte's left-hand pixel; the
; return address into FILL_NEXT_PIXEL is dropped so as to go straight to its
; top, ready for the next byte. Otherwise it returns and the byte is done pixel
; by pixel. On a room's big plain areas this paints eight pixels for about the
; work of one.
;
; HL The byte below, in the clean copy
FILL_WHOLE_BYTE:
  LD A,(HL)               ; the row below, with no run open: go on only if all
  BIT 1,E                 ; eight are set
  JR NZ,FILL_WHOLE_BYTE_0 ;
  INC A                   ;
  JR Z,FILL_WHOLE_BYTE_1  ;
  RET                     ;
FILL_WHOLE_BYTE_0:
  AND A                   ; with a run open: only if all eight are clear
  RET NZ                  ;
FILL_WHOLE_BYTE_1:
  LD HL,(WORK_RECORD)     ; the row above, the same way
  LD A,(HL)               ;
  BIT 0,E                 ;
  JR NZ,FILL_WHOLE_BYTE_2 ;
  INC A                   ;
  JR Z,FILL_WHOLE_BYTE_3  ;
  RET                     ;
FILL_WHOLE_BYTE_2:
  AND A                   ;
  RET NZ                  ;
FILL_WHOLE_BYTE_3:
  LD HL,(STEP_AXES)       ; this row: all eight must be clear
  LD A,(HL)               ;
  AND A                   ;
  RET NZ                  ;
  CPL                     ; mark all eight done
  LD (HL),A               ;
  EXX                     ; the texture's byte onto the screen whole
  LD (HL),E               ;
  EXX                     ;
  LD A,C                  ; the byte's left-hand pixel is the last one painted
  AND $F8                 ;
  LD C,A                  ;
  LD D,$80                ;
  POP HL                  ; drop the return into FILL_NEXT_PIXEL and go on from
  JP FILL_NEXT_PIXEL      ; its top

; Move the fill's pointers a byte to the left
;
; Used by the routine at FILL_NEXT_PIXEL.
;
; Called from FILL_NEXT_PIXEL when the pixel mask wraps round into the byte to
; the left. The clean copy's pointers for this row and the row above (the low
; bytes at IY+$7B and IY+$7D) and for the row below, and the screen pointer,
; all go back a byte; and the texture's two bytes change places, since a
; texture is 16 pixels wide. Then FILL_WHOLE_BYTE sees whether the new byte can
; be filled whole. A row's bytes never cross into another row here, because
; FILL_NEXT_PIXEL stops at column 0.
FILL_BYTE_TO_LEFT:
  DEC (IY+STEP_AXES-V)    ; this row and the row above, in the clean copy
  DEC (IY+WORK_RECORD-V)  ;
  EXX                     ; the screen; the texture's other byte for the new
  DEC L                   ; screen byte
  LD E,C                  ;
  LD C,B                  ;
  LD B,E                  ;
  EXX                     ;
  LD HL,(WORK_HEADING)    ; the row below; then try the byte whole
  DEC L                   ;
  LD (WORK_HEADING),HL    ;
  JR FILL_WHOLE_BYTE      ;

; Find the screen byte of a pixel
;
; Used by the routines at FILL_NEXT_SEED and SCREEN_PIXEL.
;
; The screen address of the pixel at column C, row B, with the rows counted up
; from the bottom: row 191 is the top line of the screen. It is the arithmetic
; of the ROM's PIXEL-ADD, over 192 lines rather than BASIC's 176 and without
; the ROM's check.
;
;   B Row (0 the bottom line, 191 the top)
;   C Column (0-255)
; O:HL The screen byte
PIXEL_ADDRESS:
  LD A,$BF                ; the line, counted down from the top of the screen
  SUB B                   ;
  LD L,A                  ;
  AND A                   ; H: the third of the screen and the line within the
  RRA                     ; character row
  SCF                     ;
  RRA                     ;
  AND A                   ;
  RRA                     ;
  XOR L                   ;
  AND $F8                 ;
  XOR L                   ;
  LD H,A                  ;
  LD A,C                  ; L: the character row within the third, and the
  RLCA                    ; column over 8
  RLCA                    ;
  RLCA                    ;
  XOR L                   ;
  AND $C7                 ;
  XOR L                   ;
  RLCA                    ;
  RLCA                    ;
  LD L,A                  ;
  RET                     ;

; Find a pixel in the clean copy of the screen
;
; Used by the routines at DO_ROOM_COMMAND and FILL_NEXT_SEED.
;
; As SCREEN_PIXEL, then moved to the same place in the clean copy of the screen
; (LOADING_TUNE), 32K above the screen. The fill uses the clean copy as its
; map.
;
;   B Row, from the bottom
;   C Column
; O:HL The byte in the clean copy
; O:A The pixel's mask, and D the same
BUFFER_PIXEL:
  CALL SCREEN_PIXEL       ; the screen byte and the mask
  LD D,A                  ; the same byte in the clean copy
  LD A,H                  ;
  ADD A,$80               ;
  LD H,A                  ;
  LD A,D                  ;
  RET                     ;

; Find a pixel's screen byte and its mask
;
; Used by the routines at BUFFER_PIXEL and PLOT_LINE_START.
;
;   B Row, from the bottom
;   C Column
; O:HL The screen byte
; O:A The pixel's mask (bit 7 the left-hand pixel); D is left 0
SCREEN_PIXEL:
  CALL PIXEL_ADDRESS      ; the screen byte
  LD A,C                  ; $80, moved right by the column's low three bits
  AND $07                 ;
  LD D,A                  ;
  INC D                   ;
  LD A,$01                ;
SCREEN_PIXEL_0:
  RRCA                    ;
  DEC D                   ;
  JR NZ,SCREEN_PIXEL_0    ;
  RET                     ;

; Plot the first pixel of a line
;
; Used by the routine at MORE_ROOM_COMMANDS.
;
; Plots the pixel at column C, row B with the room drawing's pen, and leaves HL
; and D at it for MORE_ROOM_COMMANDS to carry on the line from there. The pen
; draws on the screen, or in the clean copy (LOADING_TUNE) while a room has
; sent its lines there (code $E4 $00 puts $80 in IY+$6A, which is added to the
; screen address; $E4 $01 puts 0 back). By the mode bits (MODE) it sets the
; pixel (the usual), clears it (bit 0, codes $CB and $CC) or flips it (bit 1,
; codes $CD and $CE). A row above the top of the screen is not plotted -- a
; guard nothing reaches, since the points always wrap round into the screen
; (DO_ROOM_COMMAND).
;
;   B Row, from the bottom
;   C Column
; O:HL The byte plotted, on the screen or in the clean copy
; O:D The pixel's mask
PLOT_LINE_START:
  LD A,$BF                ; above the top of the screen: nothing
  SUB B                   ;
  RET C                   ;
  CALL SCREEN_PIXEL       ; the screen byte and mask; IY+$6A moves it to the
  LD D,A                  ; clean copy
  LD A,H                  ;
  ADD A,(IY+LINE_PAGE-V)  ;
  LD H,A                  ;
  LD A,(HL)               ; flip it (bit 1); or set it, and clear it again if
  BIT 1,(IY+MODE-V)       ; bit 0 is on
  JR NZ,PLOT_LINE_START_0 ;
  OR D                    ;
  BIT 0,(IY+MODE-V)       ;
  JR Z,PLOT_LINE_START_1  ;
PLOT_LINE_START_0:
  XOR D                   ; write it back
PLOT_LINE_START_1:
  LD (HL),A               ;
  RET                     ;

; The room commands $C1-$E4: lines, mode bits, repeats, parts, the clean copy
; and $E4
;
; Used by the routine at DO_ROOM_COMMAND.
;
; Where the command interpreter (DO_ROOM_COMMAND) sends every code below $E6
; that it has not dealt with itself -- it takes the points ($00-$BF), $C0, $CF,
; $D0 and $D6, and in object mode the objects. A cascade of comparisons; a code
; that none of them matches ($D1, $D3, $D4, $D7-$DF and $E3) does nothing and
; has no operand. The lengths of every code are laid out command by command in
; the rooms (ROOM1) and parts (PART1).
;
; $D2 draws a line from the second point to the first, both ends included
; (DRAW_LINE; DO_ROOM_COMMAND also calls it after each point while mode bit 5
; is on). It is Bresenham's: a step along the longer distance every pixel, and
; one along the shorter whenever the running error passes the longer. The first
; pixel goes through PLOT_LINE_START; the rest are plotted here with the same
; pen, stepping the screen address a line or a pixel at a time rather than
; working it out afresh.
;
; $C1-$CE set and clear the mode bits (MODE), which the interpreter reads
; before every command. Bit 0 ($CB on, $CC off): lines clear pixels. Bit 1 ($CD
; on, $CE off): lines flip pixels. Bit 2 ($C3, $C4): after each point the
; second point is moved to it, so that with bit 5 the points make a joined
; line. Bit 3 ($C5, $C6): the second point moves along with the first. Bit 4
; ($C1, $C2): points are relative -- their bytes are added to the point before,
; and those of $C0 and $E4 $05 to the second point and the origin. Bit 5 ($C7,
; $C8): a line from the second point to each new point. Bit 6 ($C9, $CA): the
; column bytes are negated or complemented, which mirrors the drawing left to
; right. Bit 7 is object mode, which $E4 $04 turns on. How the points use bits
; 2 to 6 is DO_ROOM_COMMAND's.
;
; $D5 n repeats what follows, up to the $D6 that DO_ROOM_COMMAND handles, n
; times: the count goes in REPEATS and the place to go back to in REPEAT_FROM,
; so there is one repeat at a time. $E0 n and $E1 n draw part n (PART1) in the
; middle of the room's commands and come back to them; $E1 keeps the drawing's
; state as it was -- both points, the origin, the mode and the repeat, which it
; saves and restores -- and $E0 lets the part change it. Either way object mode
; ends with the part. $E2 copies the screen into the clean copy: from then on,
; what has been drawn so far bounds the fills.
;
; $E4 has a second byte. $E4 $00 clears the clean copy and sends the lines into
; it, where they bound a fill without being seen; $E4 $01 sends them back to
; the screen. Room 2 uses the pair to lay a second texture over part of a wall
; that is already textured, inside an outline drawn only in the clean copy
; (measured: without them the fill finds its first point already set and does
; nothing); part 16 does the same. $E4 $04 turns object mode on, and $E4 $05 x
; y z sets the origin (ORIGIN, ORIGIN_Y, ORIGIN_Z) that is added to the place
; of each object a room's commands put down -- rooms 13 and 17 draw one part's
; objects several times over, moving the origin each time. Both first place the
; object table's things in the room (PLACE_ROOM_OBJECTS), once in each drawing
; of a room, whichever comes first -- so the table's things are always placed
; with the origin at 0, and their places are the room's own. Any other second
; byte does nothing.
;
; Of these codes only $CE occurs in no room or part. Room 26 is the only one to
; turn flipping on, for its last line, which crosses a wall that is already
; textured; its drawing ends soon after, so nothing needs to turn it off
; (measured: with the line drawn in set pixels instead, 36 pixels of the room
; come out different).
MORE_ROOM_COMMANDS:
  CP $D2                  ; not $D2: the other codes
  JP NZ,ROOM_MODE_CODES   ;
; This entry point is used by the routine at DO_ROOM_COMMAND.
DRAW_LINE:
  LD BC,(SECOND_POINT)    ; the line starts at the second point
  CALL PLOT_LINE_START    ;
  EXX                        ; rows: how far to the first point, and which way
  LD A,(SECOND_POINT_ROW)    ; (D +1 down the screen, -1 up)
  SUB (IY+POINT_ROW-V)       ;
  LD D,$01                   ;
  JR NC,MORE_ROOM_COMMANDS_0 ;
  CPL                        ;
  INC A                      ;
  LD D,$FF                   ;
MORE_ROOM_COMMANDS_0:
  LD B,A                  ; B = the rows
  LD A,(SECOND_POINT)        ; columns: E +1 to go left, -1 right
  SUB (IY+POINT-V)           ;
  LD E,$01                   ;
  JR NC,MORE_ROOM_COMMANDS_1 ;
  CPL                        ;
  INC A                      ;
  LD E,$FF                   ;
MORE_ROOM_COMMANDS_1:
  LD C,A                  ; C = the columns
  CP B                       ; more rows than columns: every step moves a row,
  JR NC,MORE_ROOM_COMMANDS_2 ; some a column too (the plain step has no column)
  LD L,C                     ;
  PUSH DE                    ;
  XOR A                      ;
  LD E,A                     ;
  JR MORE_ROOM_COMMANDS_3    ;
MORE_ROOM_COMMANDS_2:
  OR C                    ; more columns: every step moves a column (the plain
  RET Z                   ; step has no row); nothing more to do if the points
  LD L,B                  ; are the same
  LD B,C                  ;
  PUSH DE                 ;
  LD D,$00                ;
MORE_ROOM_COMMANDS_3:
  LD H,B                  ; H = steps, the longer distance; the error starts at
  LD A,B                  ; half of it
  RRA                     ;
MORE_ROOM_COMMANDS_4:
  ADD A,L                   ; add the shorter distance: past the longer?
  JR C,MORE_ROOM_COMMANDS_5 ;
  CP H                      ;
  JR C,MORE_ROOM_COMMANDS_6 ;
MORE_ROOM_COMMANDS_5:
  SUB H                   ; yes: take the longer off, and step both ways (the
  LD C,A                  ; step pushed first)
  EXX                     ;
  POP BC                  ;
  PUSH BC                 ;
  JR MORE_ROOM_COMMANDS_7 ;
MORE_ROOM_COMMANDS_6:
  LD C,A                  ; no: the plain step
  PUSH DE                 ;
  EXX                     ;
  POP BC                  ;
MORE_ROOM_COMMANDS_7:
  LD A,B                    ; a row to move?
  AND A                     ;
  JR Z,MORE_ROOM_COMMANDS_9 ;
  ADD A,H                    ; down a line: into the next character row, and
  LD H,A                     ; into the next third only if L carried
  AND $07                    ;
  JR NZ,MORE_ROOM_COMMANDS_8 ;
  BIT 7,B                    ;
  JR NZ,MORE_ROOM_COMMANDS_9 ;
  LD A,L                     ;
  ADD A,$20                  ;
  LD L,A                     ;
  JR C,MORE_ROOM_COMMANDS_9  ;
  LD A,H                     ;
  SUB $08                    ;
  LD H,A                     ;
  JR MORE_ROOM_COMMANDS_9    ;
MORE_ROOM_COMMANDS_8:
  XOR $07                    ; up a line: the same, the other way
  JR NZ,MORE_ROOM_COMMANDS_9 ;
  BIT 7,B                    ;
  JR Z,MORE_ROOM_COMMANDS_9  ;
  LD A,L                     ;
  SUB $20                    ;
  LD L,A                     ;
  JR C,MORE_ROOM_COMMANDS_9  ;
  LD A,H                     ;
  ADD A,$08                  ;
  LD H,A                     ;
MORE_ROOM_COMMANDS_9:
  LD A,C                     ; a column to move?
  AND A                      ;
  JR Z,MORE_ROOM_COMMANDS_11 ;
  RLA                         ; left: the mask moves left, into the byte before
  JR C,MORE_ROOM_COMMANDS_10  ; when it wraps
  LD A,D                      ;
  RLCA                        ;
  LD D,A                      ;
  JR NC,MORE_ROOM_COMMANDS_11 ;
  DEC L                       ;
  JR MORE_ROOM_COMMANDS_11    ;
MORE_ROOM_COMMANDS_10:
  LD A,D                      ; right
  RRCA                        ;
  LD D,A                      ;
  JR NC,MORE_ROOM_COMMANDS_11 ;
  INC L                       ;
MORE_ROOM_COMMANDS_11:
  BIT 1,(IY+MODE-V)           ; plot it with the pen, as PLOT_LINE_START does
  LD A,(HL)                   ;
  JR NZ,MORE_ROOM_COMMANDS_12 ;
  OR D                        ;
  BIT 0,(IY+MODE-V)           ;
  JR Z,MORE_ROOM_COMMANDS_13  ;
MORE_ROOM_COMMANDS_12:
  XOR D                       ;
MORE_ROOM_COMMANDS_13:
  LD (HL),A                   ;
  EXX                       ; the error back in A; the next step
  LD A,C                    ;
  DJNZ MORE_ROOM_COMMANDS_4 ;
  POP DE                  ; drop the step saved at the start
  RET                     ;
ROOM_MODE_CODES:
  CP $CB                      ; $CB: bit 0 on
  JR NZ,MORE_ROOM_COMMANDS_14 ;
  LD C,$01                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_14:
  CP $CD                      ; $CD: bit 1 on
  JR NZ,MORE_ROOM_COMMANDS_15 ;
  LD C,$02                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_15:
  CP $C3                      ; $C3: bit 2 on
  JR NZ,MORE_ROOM_COMMANDS_17 ;
  LD C,$04                    ;
MORE_ROOM_COMMANDS_16:
  LD A,(MODE)             ; set the bit in MODE
  OR C                    ;
  LD (MODE),A             ;
  RET                     ;
MORE_ROOM_COMMANDS_17:
  CP $C7                      ; $C7: bit 5 on
  JR NZ,MORE_ROOM_COMMANDS_18 ;
  LD C,$20                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_18:
  CP $C5                      ; $C5: bit 3 on
  JR NZ,MORE_ROOM_COMMANDS_19 ;
  LD C,$08                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_19:
  CP $C1                      ; $C1: bit 4 on
  JR NZ,MORE_ROOM_COMMANDS_20 ;
  LD C,$10                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_20:
  CP $C9                      ; $C9: bit 6 on
  JR NZ,MORE_ROOM_COMMANDS_21 ;
  LD C,$40                    ;
  JR MORE_ROOM_COMMANDS_16    ;
MORE_ROOM_COMMANDS_21:
  CP $CA                      ; $CA: bit 6 off
  JR NZ,MORE_ROOM_COMMANDS_22 ;
  LD C,$BF                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_22:
  CP $C2                      ; $C2: bit 4 off
  JR NZ,MORE_ROOM_COMMANDS_23 ;
  LD C,$EF                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_23:
  CP $CE                      ; $CE: bit 1 off (no room or part has it)
  JR NZ,MORE_ROOM_COMMANDS_24 ;
  LD C,$FD                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_24:
  CP $CC                      ; $CC: bit 0 off
  JR NZ,MORE_ROOM_COMMANDS_25 ;
  LD C,$FE                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_25:
  CP $C8                      ; $C8: bit 5 off
  JR NZ,MORE_ROOM_COMMANDS_26 ;
  LD C,$DF                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_26:
  CP $C6                      ; $C6: bit 3 off
  JR NZ,MORE_ROOM_COMMANDS_27 ;
  LD C,$F7                    ;
  JR MORE_ROOM_COMMANDS_28    ;
MORE_ROOM_COMMANDS_27:
  CP $C4                      ; $C4: bit 2 off
  JR NZ,MORE_ROOM_COMMANDS_29 ;
  LD C,$FB                    ;
MORE_ROOM_COMMANDS_28:
  LD A,D                  ; clear the bit (D is MODE, as the interpreter read
  AND C                   ; it)
  LD (MODE),A             ;
  RET                     ;
MORE_ROOM_COMMANDS_29:
  CP $D5                      ; $D5 n
  JR NZ,MORE_ROOM_COMMANDS_30 ;
  INC IX                  ; the count, and where to go back to: the count's own
  LD A,(IX+$00)           ; place, which the interpreter steps past
  LD (REPEATS),A          ;
  LD (REPEAT_FROM),IX     ;
  RET                     ;
MORE_ROOM_COMMANDS_30:
  CP $E1                      ; $E1 n
  JR NZ,MORE_ROOM_COMMANDS_31 ;
  LD HL,(POINT)           ; keep the points, the mode, the repeat, the origin
  PUSH HL                 ; and the bytes between
  LD HL,(SECOND_POINT)    ;
  PUSH HL                 ;
  LD E,(IY+WORK_SPRITE-V) ;
  PUSH DE                 ;
  LD HL,(REPEATS)         ;
  PUSH HL                 ;
  LD HL,(REPEAT_FROM)     ;
  PUSH HL                 ;
  LD HL,(WORK_KIND)       ;
  PUSH HL                 ;
  LD HL,(ORIGIN)          ;
  PUSH HL                 ;
  LD HL,(ORIGIN_Z)        ;
  PUSH HL                 ;
  CALL DRAW_PART          ; draw the part
  POP HL                  ; and put them all back
  LD (ORIGIN_Z),HL        ;
  POP HL                  ;
  LD (ORIGIN),HL          ;
  POP HL                  ;
  LD (WORK_KIND),HL       ;
  POP HL                  ;
  LD (REPEAT_FROM),HL     ;
  POP HL                  ;
  LD (REPEATS),HL         ;
  POP HL                  ;
  LD A,L                  ;
  LD (WORK_SPRITE),A      ;
  LD A,H                  ;
  LD (MODE),A             ;
  POP HL                  ;
  LD (SECOND_POINT),HL    ;
  POP HL                  ;
  LD (POINT),HL           ;
  RET                     ;
MORE_ROOM_COMMANDS_31:
  CP $E0                      ; $E0 n
  JR NZ,MORE_ROOM_COMMANDS_34 ;
DRAW_PART:
  INC IX                  ; the part's number; the parts from PART1, the first
  LD B,(IX+$00)           ; numbered 1
  LD HL,(PARTS_TABLE)     ;
  LD A,$01                ;
  LD C,A                  ;
MORE_ROOM_COMMANDS_32:
  LD A,C                      ; this one?
  CP B                        ;
  JR NZ,MORE_ROOM_COMMANDS_33 ;
  PUSH IX                 ; yes: run its commands to its $E5, after its length;
  INC HL                  ; object mode ends with it
  INC HL                  ;
  PUSH HL                 ;
  POP IX                  ;
  CALL RUN_ROOM_COMMANDS  ;
  RES 7,(IY+MODE-V)       ;
  POP IX                  ;
  RET                     ;
MORE_ROOM_COMMANDS_33:
  PUSH HL                  ; no: past it by its length
  LD E,(HL)                ;
  INC HL                   ;
  LD D,(HL)                ;
  POP HL                   ;
  ADD HL,DE                ;
  INC C                    ;
  JR MORE_ROOM_COMMANDS_32 ;
MORE_ROOM_COMMANDS_34:
  CP $E2                      ; $E2
  JR NZ,MORE_ROOM_COMMANDS_36 ;
  LD HL,$4000             ; the screen...
  LD E,$00                ;
MORE_ROOM_COMMANDS_35:
  LD A,$40                ; ...into the clean copy, its 6144 bytes of pixels
  ADD A,$80               ;
  LD D,A                  ;
  LD BC,$1800             ;
  LDIR                    ;
  RET                     ;
MORE_ROOM_COMMANDS_36:
  CP $E4                  ; $E4, or nothing
  RET NZ                  ;
  INC IX                      ; the second byte
  LD A,(IX+$00)               ;
  CP $00                      ;
  JR NZ,MORE_ROOM_COMMANDS_37 ;
  LD HL,$BFFF              ; 0: clear the clean copy (a zero at the end of the
  LD (HL),$00              ; records area, RECORDS, copied along it) and send
  LD (IY+LINE_PAGE-V),$80  ; lines into it
  LD E,$00                 ;
  JR MORE_ROOM_COMMANDS_35 ;
MORE_ROOM_COMMANDS_37:
  CP $01                      ; 1: lines onto the screen again
  JR NZ,MORE_ROOM_COMMANDS_38 ;
  LD (IY+LINE_PAGE-V),$00     ;
  RET                         ;
MORE_ROOM_COMMANDS_38:
  CP $04                      ; 4: object mode on
  JR NZ,MORE_ROOM_COMMANDS_39 ;
  SET 7,(IY+MODE-V)           ;
PLACE_OBJECTS_ONCE:
  BIT 0,(IY+OBJECTS_PLACED-V) ; place the object table's things in the room, if
  RET NZ                      ; this drawing has not yet
  SET 0,(IY+OBJECTS_PLACED-V) ;
  PUSH IX                     ;
  CALL PLACE_ROOM_OBJECTS     ;
  POP IX                      ;
  RET                         ;
MORE_ROOM_COMMANDS_39:
  CP $05                  ; 5: place them too
  RET NZ                  ;
  CALL PLACE_OBJECTS_ONCE ;
  INC IX                     ; then the origin's three bytes, each added to the
  LD D,(IY+MODE-V)           ; origin as it is while mode bit 4 is on
  LD A,(IX+$00)              ;
  BIT 4,D                    ;
  JR Z,MORE_ROOM_COMMANDS_40 ;
  ADD A,(IY+ORIGIN-V)        ;
MORE_ROOM_COMMANDS_40:
  LD (ORIGIN),A              ;
  INC IX                     ;
  LD A,(IX+$00)              ;
  BIT 4,D                    ;
  JR Z,MORE_ROOM_COMMANDS_41 ;
  ADD A,(IY+ORIGIN_Y-V)      ;
MORE_ROOM_COMMANDS_41:
  LD (ORIGIN_Y),A            ;
  INC IX                     ;
  LD A,(IX+$00)              ;
  BIT 4,D                    ;
  JR Z,MORE_ROOM_COMMANDS_42 ;
  ADD A,(IY+ORIGIN_Z-V)      ;
MORE_ROOM_COMMANDS_42:
  LD (ORIGIN_Z),A            ;
  RET                     ; done

; Put the object table's things for this room into its records
;
; Used by the routine at MORE_ROOM_COMMANDS.
;
; Walks the whole object table (OBJECTS) and makes a record (PLACE_OBJECT) for
; every entry whose room is ROOM, in the table's order, from FREE_RECORD on.
; First every record from there to the end of the area (RECORDS; the clean copy
; begins where it ends) is cleared.
;
; An entry is a room, a type and four more bytes for a type below $46 -- the
; things, which can be moved and carried from room to room -- or nine for the
; rest (doors, walls and the like); $FF ends the table. A thing's record also
; gets its number in the table, counting from 1, at +19: the code that moves a
; thing to another room or into the knight's hands writes its new room into its
; entry by that number (SET_THING_ROOM). The number is a byte, which is enough
; because the 163 things come first.
;
; Called once in each drawing of a room, by MORE_ROOM_COMMANDS's $E4 $04 or $E4
; $05. The most records a room's drawing makes is 30 (room 71), besides the
; knight's and the five carried; the area has room for 43 (measured, in rooms
; 1-80).
PLACE_ROOM_OBJECTS:
  LD IX,(FREE_RECORD)     ; clear the records from the next free one to the end
  LD HL,(FREE_RECORD)     ; of the area
  LD (HL),$00             ;
  LD DE,(FREE_RECORD)     ;
  INC DE                  ;
  PUSH HL                 ;
  LD HL,LOADING_TUNE      ;
  AND A                   ;
  SBC HL,DE               ;
  PUSH HL                 ;
  POP BC                  ;
  POP HL                  ;
  LDIR                    ;
  LD HL,(OBJECT_TABLE_AT)     ; from the start of the table, numbering the
  LD (IY+PLACED_NUMBER-V),$00 ; entries
PLACE_ROOM_OBJECTS_0:
  LD A,(HL)               ; the entry's room; $FF ends the table
  INC HL                  ;
  CP $FF                  ;
  RET Z                   ;
  INC (IY+PLACED_NUMBER-V)  ; count it; this room?
  CP (IY+ROOM-V)            ;
  JR Z,PLACE_ROOM_OBJECTS_2 ;
  LD DE,$0005               ; no: past it, six bytes or eleven by its type
  LD A,(HL)                 ;
  CP $46                    ;
  JR C,PLACE_ROOM_OBJECTS_1 ;
  LD DE,$000A               ;
PLACE_ROOM_OBJECTS_1:
  ADD HL,DE                 ;
  JR PLACE_ROOM_OBJECTS_0   ;
PLACE_ROOM_OBJECTS_2:
  CALL PLACE_OBJECT       ; yes: make its record
  LD A,(PLACED_TYPE)            ; a thing: its number in the table at +19
  CP $46                        ;
  JR NC,PLACE_ROOM_OBJECTS_0    ;
  LD A,(PLACED_NUMBER)          ;
  LD (IX+OBJ_NUMBER-OBJ_SIZE),A ;
  JR PLACE_ROOM_OBJECTS_0       ;

; Make an object record from a type, a place and its template
;
; Used by the routines at DO_ROOM_COMMAND and PLACE_ROOM_OBJECTS.
;
; Makes the record at IX for an object whose type is at HL, from the type's
; template and the bytes that follow the type, and counts it in OBJECT_COUNT.
; It serves both the object table (PLACE_ROOM_OBJECTS) and the objects a room's
; own commands put down in object mode (DO_ROOM_COMMAND), which are written the
; same way as the table's things without the room.
;
; A type below $46 has an 11-byte template (TEMPLATES) and four bytes after it:
; +12 (the thing's kind, and whether it can be picked up), then its place, +6
; to +8 (along the floor, the height of its top, across the floor). The
; template gives +0 to +5 (where its sprite goes on the screen, the sprite's
; size and the sprite), +9 to +11 (its length along, its height and its length
; across, each from the corner at +6 to +8) and two more bytes: +14, whose low
; nibble is the kind of movement the object dispatcher (CHE3D) acts on, and +16
; (bits 0-4: 0 for an object that stays put, which the object dispatcher passes
; over, else 16 plus its weight, PICK_UP_LOOK_ON; bit 5 set while it is carried
; or gone).
;
; A type from $46 has a 9-byte template (LARGE_TEMPLATES, less $46) and nine
; bytes after it: the place, then six bytes for +13 to +18, which the door code
; reads (BUMPED). Its +12 is 1, the kind that the object dispatcher passes
; over. A room's commands only ever put down types below $46 -- they take five
; bytes each (DO_ROOM_COMMAND), which would not do for these.
;
; The template's screen position is right for an object standing at 50, 50 with
; its floor at 50, so the record is first given that place (the top is 50 plus
; the height) and ISO_MOVE moves it from there to the place asked for plus the
; origin, moving the screen position with it. Then a thing's movement gets its
; starting state by kind: +15 is 1, and +13 and +17 are set for kinds 3 and
; 4-10 (and for kind 2, which no template has, so that code never runs).
;
;   HL The type, followed by its bytes
;   IX The record to fill (FREE_RECORD)
; O:HL The byte after them
; O:IX The next record, which FREE_RECORD is left at
PLACE_OBJECT:
  LD A,(HL)               ; the type, kept for PLACE_ROOM_OBJECTS
  LD (PLACED_TYPE),A      ;
  RES 6,(IY+WORK_RECORD-V) ; a type from $46: +12 is 1, and bit 6 of IY+$7D
  CP $46                   ; says so below
  JR C,PLACE_OBJECT_0      ;
  LD (IX+OBJ_KIND),$01     ;
  SET 6,(IY+WORK_RECORD-V) ;
PLACE_OBJECT_0:
  INC HL                  ; past the type; one more record in use
  INC (IY+OBJECT_COUNT-V) ;
  PUSH IX                 ; the templates for types below $46, 11 bytes each...
  EXX                     ;
  LD DE,$000B             ;
  LD HL,TEMPLATES         ;
  INC A                   ;
  BIT 6,(IY+WORK_RECORD-V)   ; ...or from $46, 9 bytes each
  JR Z,PLACE_FROM_TEMPLATE_0 ;
  LD HL,LARGE_TEMPLATES      ;
  LD DE,$0009                ;
  SUB $46                    ;
  JR PLACE_FROM_TEMPLATE_0   ;

; Fill an object record from its template (PLACE_OBJECT continued)
;
; The rest of PLACE_OBJECT, from the loop that finds the template on: the
; template's pointer is in the other register set (HL') and the bytes after the
; type in this one, and the record is filled from each in turn.
PLACE_FROM_TEMPLATE:
  ADD HL,DE               ; the template for the type
; This entry point is used by the routine at PLACE_OBJECT.
PLACE_FROM_TEMPLATE_0:
  DEC A
  JR NZ,PLACE_FROM_TEMPLATE ; }
  LD B,$06                ; template: +0 to +5, where the sprite goes, its size
  CALL COPY_TO_RECORD     ; and the sprite
  EXX                         ; a small type: its first byte to +12
  BIT 6,(IY+WORK_RECORD-V)    ;
  JR NZ,PLACE_FROM_TEMPLATE_1 ;
  LD A,(HL)                   ;
  INC HL                      ;
  LD (IX+OBJ_KIND-OBJ_X),A    ;
PLACE_FROM_TEMPLATE_1:
  LD B,$03                ; its place, +6 to +8
  CALL COPY_TO_RECORD     ;
  EXX                     ; template: +9 to +11, the lengths along, up and
  LD B,$03                ; across from the corner
  CALL COPY_TO_RECORD     ;
  BIT 6,(IY+WORK_RECORD-V)   ; a large type: six more bytes, to +13 to +18
  JR Z,PLACE_FROM_TEMPLATE_2 ;
  EXX                        ;
  LD B,$06                   ;
  INC IX                     ;
  CALL COPY_TO_RECORD        ;
  EXX                        ;
  JR PLACE_FROM_TEMPLATE_3   ;
PLACE_FROM_TEMPLATE_2:
  LD A,(HL)                     ; a small type: the template's last two bytes
  LD (IX+OBJ_STATE-OBJ_KIND),A  ; to +14 and +16
  INC HL                        ;
  LD A,(HL)                     ;
  LD (IX+OBJ_WEIGHT-OBJ_KIND),A ;
PLACE_FROM_TEMPLATE_3:
  POP IX                  ; the place asked for, plus the origin
  LD A,(IX+OBJ_X)         ;
  ADD A,(IY+ORIGIN-V)     ;
  LD B,A                  ;
  LD A,(IX+OBJ_TOP)       ;
  ADD A,(IY+ORIGIN_Y-V)   ;
  LD D,A                  ;
  LD A,(IX+OBJ_Z)         ;
  ADD A,(IY+ORIGIN_Z-V)   ;
  LD H,A                  ;
  LD (IX+OBJ_X),$32       ; from the place the template's screen position is
  LD A,(IX+OBJ_HEIGHT)    ; for, move it there (ISO_MOVE)
  ADD A,$32               ;
  LD (IX+OBJ_TOP),A       ;
  LD (IX+OBJ_Z),$32       ;
  CALL ISO_MOVE           ;
  EXX                         ; a large type: done
  BIT 6,(IY+WORK_RECORD-V)    ;
  JR NZ,PLACE_FROM_TEMPLATE_6 ;
  LD (IX+OBJ_COUNT),$01   ; +15: a countdown the object code uses
  LD A,(IX+OBJ_STATE)         ; the kind of movement: 2 (no template has it)
  AND $0F                     ;
  CP $02                      ;
  JR NZ,PLACE_FROM_TEMPLATE_4 ;
  LD (IX+OBJ_DIRECTION),$05 ; its +13
PLACE_FROM_TEMPLATE_4:
  CP $03                      ; kind 3: +13
  JR NZ,PLACE_FROM_TEMPLATE_5 ;
  LD (IX+OBJ_DIRECTION),$45   ;
PLACE_FROM_TEMPLATE_5:
  CP $04                      ; kinds 4-10: +13 and +17
  JR C,PLACE_FROM_TEMPLATE_6  ;
  CP $0B                      ;
  JR NC,PLACE_FROM_TEMPLATE_6 ;
  LD (IX+OBJ_DIRECTION),$05   ;
  LD (IX+OBJ_FRAME),$10       ;
PLACE_FROM_TEMPLATE_6:
  LD DE,$0014             ; the next free record
  ADD IX,DE               ;
  LD (FREE_RECORD),IX     ;
  RET                     ;

; Copy bytes into an object record
;
; Used by the routine at PLACE_FROM_TEMPLATE.
;
;   B How many
;   HL From
;   IX To
; O:HL,IX Past them
COPY_TO_RECORD:
  LD A,(HL)               ; a byte at a time
  LD (IX+$00),A           ;
  INC HL                  ;
  INC IX                  ;
  DJNZ COPY_TO_RECORD     ;
  RET

; A spare byte
;
; Zero; nothing reads it.
BYTE_BEFORE_PRINT_CHAR:
  DEFS $01

; Print one character
;
; Used by the routine at MAIN_LOOP.
;
; Prints the character in A at the printing position (PRINT_X, PRINT_Y), by
; putting it into the one-character string after its own call to the printer
; (PRINT). LIFE's digits are printed this way (MAIN_LOOP).
;
; A The character (0 a space, 1-26 the letters, 27-36 the digits)
PRINT_CHAR:
  LD ($EBFB),A            ; into the string
  CALL PRINT              ; print it
  DEFB $00                ; " "
  DEFB $A4                ; End of the string
  RET

; Print the string after the call
;
; Used by the routines at TITLE_PAGE_TEXT, MESS2, SHOW_MESSAGE, PRINT_CHAR,
; CLEAR_THING_BOX, TITLE_SCREEN, ROOMST and MAIN_LOOP.
;
; The game's text printer, the author's PRINT (the name the leftover source
; text calls it by). The string is the bytes after the CALL: characters of the
; font (FONT), $C8 and two bytes to move the printing position (PRINT_X, in
; pixels from the left, and PRINT_Y, in rows counted up from the bottom), and
; $A4 to end it; the printer returns to the byte after the $A4. A string can be
; only a $C8 and its position, to set it for PRINT_CHAR.
;
; Each character is an 8 by 8 picture put on the screen by the compositor
; (COMPOSITE_TO_SCREEN, at its second entry point, 15 bytes in), 8 pixels to
; the right of the one before. With its first two planes (BUFFER_D800 and
; BUFFER_D900) cleared and nothing else to merge, the compositor puts the
; character over the 8 by 8 pixels under it and leaves its neighbours alone, so
; text need not sit on the character grid. The printer uses the room drawing's
; point variables for the place and size, which the drawing is finished with.
PRINT:
  LD (IY+DRAW_WIDTH-V),$01 ; one byte wide; the first two planes cleared
  LD HL,BUFFER_DA00        ;
  LD B,$40                 ;
  CALL CLEAR_BELOW         ;
  LD (IY+WORK_DIRECTION-V),$00 ; nothing else to merge
; This entry point is used by the routine at PRINT_FIND_GLYPH.
PRINT_NEXT_CHAR:
  POP HL                  ; the next byte of the string; $A4 ends it, returning
PRINT_0:
  LD A,(HL)               ; past it
  INC HL                  ;
  CP $A4                  ;
  PUSH HL                 ;
  RET Z                   ;
  CP $C8                  ; $C8: a new printing position
  JR NZ,PRINT_1           ;
  POP HL                  ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (PRINT_X),A          ;
  LD A,(HL)               ;
  INC HL                  ;
  LD (PRINT_Y),A          ;
  JR PRINT_0              ;
PRINT_1:
  LD DE,$0008             ; an 8 by 8 picture at the printing position
  LD HL,$0808             ;
  LD (SECOND_POINT),HL    ;
  LD HL,(PRINT_X)         ;
  LD (POINT),HL           ;
  LD HL,FONT              ; the character's 8 bytes in the font
  INC A                   ;
  JR PRINT_FIND_GLYPH_0   ;

; Find a character in the font and print it (PRINT continued)
;
; The rest of the printer, from the loop that finds the character on.
PRINT_FIND_GLYPH:
  ADD HL,DE               ; 8 bytes a character
; This entry point is used by the routine at PRINT.
PRINT_FIND_GLYPH_0:
  DEC A
  JR NZ,PRINT_FIND_GLYPH  ; }
  CALL COMPOSITE_FROM_IX  ; draw it
  LD A,(PRINT_X)          ; 8 pixels on; the next character
  ADD A,$08               ;
  LD (PRINT_X),A          ;
  JR PRINT_NEXT_CHAR      ;

; Show a carried thing in the panel's box
;
; Used by the routines at PICK_UP_LOOK_ON and MAIN_LOOP.
;
; The author's INFOR (named by its calls in the leftover source text). Clears
; the panel's box and prints the number of the carried place in use
; (CLEAR_THING_BOX), then draws the sprite of the object whose record is at HL
; in the box, at x 20, row 40: only the sprite's image, with the compositor's
; first two planes cleared, over what the box holds. Called when a thing is
; picked up (PICK_UP_LOOK_ON) and when a carried place that holds one is chosen
; (MAIN_LOOP).
;
; HL The thing's record
SHOW_THING_IN_USE:
  PUSH HL                 ; clear the box and number it
  CALL CLEAR_THING_BOX    ;
  LD HL,BUFFER_DA00       ; the first two planes cleared
  LD B,$40                ;
  CALL CLEAR_BELOW        ;
  POP HL                  ; its sprite's width, height and address, +2 to +5
  INC HL                  ;
  INC HL                  ;
  LD DE,SECOND_POINT      ;
  LD BC,$0004             ;
  LDIR                    ;
  LD A,(SECOND_POINT)     ; the width in bytes
  SRL A                   ;
  SRL A                   ;
  SRL A                   ;
  LD (DRAW_WIDTH),A       ;
  LD HL,(WORK_SPRITE)     ; draw it in the box (placed by CLEAR_THING_BOX)
  JP COMPOSITE_FROM_IX    ;

; Clear the panel's box for the thing in use, and number it
;
; Used by the routines at SHOW_THING_IN_USE, CREATURE_UPDATE and MAIN_LOOP.
;
; The author's INFO0 (named by its calls in the leftover source text). The
; panel shows the thing in use in a box 24 pixels wide and 32 high at x 20, row
; 40 down, and the number of its carried place (1-5) above it at x 10, y 50.
; The box is put back as the clean copy of the screen (LOADING_TUNE) has it:
; the compositor (COMPOSITE_TO_SCREEN) is given its second plane all set, which
; takes every pixel from the clean copy, so whatever sprite it finds does not
; matter. Then the digit is printed, from SELECTED. Called on its own when a
; thing is dropped (CREATURE_UPDATE) or an empty place is chosen (MAIN_LOOP),
; and by SHOW_THING_IN_USE.
CLEAR_THING_BOX:
  LD B,$20                ; the second plane all set: every pixel from the
  LD HL,BUFFER_DA00       ; clean copy
  LD DE,$FFFF             ;
  CALL FILL_BELOW         ;
  LD HL,BUFFER_D900       ; the first plane clear
  LD B,$20                ;
  CALL CLEAR_BELOW        ;
  LD HL,$2814             ; the box: x 20, row 40, 24 by 32
  LD (POINT),HL           ;
  LD HL,$2018             ;
  LD (SECOND_POINT),HL    ;
  LD HL,BUFFER_D800       ; not used: COMPOSITE_TO_SCREEN loads HL itself
  LD (IY+WORK_DIRECTION-V),$00 ; nothing else to merge; 4 bytes wide
  LD A,$04                     ;
  LD (DRAW_WIDTH),A            ;
  CALL COMPOSITE_TO_SCREEN ; put the box back
  LD A,(SELECTED)         ; the place in use ($9F-$A7 in twos) as a digit 1-5,
  SUB $9E                 ; into the string
  RRA                     ;
  ADD A,$1C               ;
  LD ($ECB4),A            ;
  CALL PRINT              ; print it (the string follows the CALL, laid out by
                          ; the data generator)
  DEFB $C8,$0A,$32        ; Print at x 10, y 50
  DEFB $00                ; " "
  DEFB $A4                ; End of the string
  LD HL,$2814
  LD (POINT),HL
  RET

; Redraw an object, and every other object that overlaps it
;
; Used by the routines at PICK_UP_LOOK_ON, ANIMATE_AND_MOVE, OBJECTS_MEET and
; DRAW_STILL_THINGS.
;
; The author's SRP (named by its call in the leftover source text's pick-up
; code). Draws the object whose record is at HL where it now stands -- or rubs
; it out, if it has been carried off or is gone (bit 5 of +16) -- together with
; every other object whose sprite overlaps it on the screen, each in front of
; or behind it as their places say, and puts the result on the screen. The
; record's first twelve bytes are copied to the variables from IY+$64 on (the
; room drawing's points, which it is finished with), and the box to redraw is
; the sprite's, with three rows more at the top and three at the bottom.
;
; The work is done in the compositor's planes. The first (BUFFER_D800) is
; cleared; then either the object's sprite is drawn into them (DRAW_SPRITE,
; with $80) or the second (BUFFER_D900) is filled, which lets the clean copy of
; the room show through where it was. Then every record from the knight's (the
; seventh) to the last in use, but this one, goes to CULL_OBJECT, which lists
; at BUFFER_DA00 those that overlap the box (IY+$7F counts them, less one) and
; compares each one's depth with the corner of this object's box (FAR_CORNER).
; If any of them needs drawing, SORT_AND_DRAW_BEHIND sorts them and draws them
; into the planes, and at the end COMPOSITE_TO_SCREEN puts the box onto the
; screen.
;
; Used when a thing is picked up (PICK_UP_LOOK_ON, to rub it out), as objects
; move (ANIMATE_AND_MOVE, OBJECTS_MEET), and when a room is entered
; (DRAW_STILL_THINGS draws each object that stays put into the picture before
; it becomes the clean copy; bit 4 of IY+$17 is set then, and nothing is rubbed
; out).
;
; HL The object's record
REDRAW_OBJECT:
  LD DE,POINT             ; the record's first twelve bytes to IY+$64 on; IX
  PUSH HL                 ; the record
  POP IX                  ;
  LD BC,$000C             ;
  LDIR                    ;
  LD A,(WORK_SPRITE)      ; no sprite: nothing to draw
  OR (IX+OBJ_SPRITE+$01)  ;
  RET Z                   ;
  LD HL,BUFFER_D900       ; the first plane cleared
  CALL CLEAR_256_BELOW    ;
  LD (IY+RIDE_DIRECTION-V),$FF ; none listed yet
  LD (IY+WORK_BEHAVIOUR-V),$00 ;
  LD A,(SECOND_POINT)     ; the width in bytes
  SRL A                   ;
  SRL A                   ;
  SRL A                   ;
  LD (DRAW_WIDTH),A       ;
  BIT 4,(IY+GAME_FLAGS-V) ; carried or gone, and the room not being entered?
  JR NZ,REDRAW_OBJECT_0   ;
  BIT 5,(IX+OBJ_WEIGHT)   ;
  JR Z,REDRAW_OBJECT_0    ;
  LD HL,BUFFER_DA00       ; then the clean copy shows through: the second plane
  LD DE,$FFFF             ; all set
  LD B,$20                ;
  CALL FILL_BELOW         ;
  JR REDRAW_OBJECT_1      ;
REDRAW_OBJECT_0:
  LD A,$80                ; else its sprite into the planes
  CALL DRAW_SPRITE        ;
REDRAW_OBJECT_1:
  CALL FAR_CORNER         ; the corner of its box that depths are compared with
  LD A,(SECOND_POINT_ROW) ; three rows more above and below
  ADD A,$06               ;
  LD (SECOND_POINT_ROW),A ;
  LD A,(POINT_ROW)        ;
  ADD A,$03               ;
  LD (POINT_ROW),A        ;
  LD IX,KNIGHT            ; from the knight's record, the seventh; nothing to
  XOR A                   ; merge yet
  LD (WORK_DIRECTION),A   ;
  LD A,$06                ;
REDRAW_OBJECT_2:
  INC A                   ; each record but this one: does it overlap?
  LD (DRAW_INDEX),A       ;
  CP (IY+THIS_RECORD-V)   ;
  CALL NZ,CULL_OBJECT     ;
  EXX                     ; the next record, keeping DE
  LD DE,$0014             ;
  ADD IX,DE               ;
  EXX                     ;
  LD A,(DRAW_INDEX)       ; up to the last in use
  CP (IY+OBJECT_COUNT-V)  ;
  JR NZ,REDRAW_OBJECT_2   ;
  BIT 1,(IY+WORK_DIRECTION-V)  ; sort and draw those that must be
  CALL NZ,SORT_AND_DRAW_BEHIND ;
  JP COMPOSITE_TO_SCREEN  ; onto the screen

; Sort one object into the redraw of a region: in front, behind, or out of it
;
; Used by the routine at REDRAW_OBJECT.
;
; Called by REDRAW_OBJECT for each object record but the one being redrawn
; (THIS_RECORD), with IX at the record and D, E, C the redrawn object's far
; corner and floor (FAR_CORNER). The region is the rectangle of screen being
; rebuilt, the redrawn object's own box with three rows more above and below
; it: its x at IY+$64, its top row at IY+$65 (y counts up the screen), its
; width in pixels at IY+$66 and its height at IY+$67. An object that does not
; overlap the region, or has no sprite, is left out. One that overlaps it and
; stands in front of the redrawn object (IS_IN_FRONT) has its cover drawn at
; once into page $D8 (DRAW_SPRITE, mode 0), which tells the compositor
; (COMPOSITE_TO_SCREEN) to leave the screen as it is there. One behind goes
; onto the list at page $DA for SORT_AND_DRAW_BEHIND to sort and draw.
; Krumlinde's name for it is Cull_TestObject.
;
; What counts depends on the pass. Normally (bit 4 of IY+$17 clear) scenery --
; an object whose +$10 has bits 0-4 clear, drawn once as the room was entered
; and so already in the clean copy of the screen (LOADING_TUNE) -- goes on the
; list but does not by itself ask for the list to be drawn: only a live object
; behind sets bit 1 of IY+$71. In the scenery pass as a room is entered (bit 4
; set, ROOMST) live objects are left out altogether, since they are drawn
; later, and anything behind asks for the list. A door (type 1 in +$0C) skips
; both tests; anything taken out of the room (bit 5 of +$10: carried, or
; destroyed) is never drawn.
;
; IX An object record
; D The redrawn object's far edge along +6
; E Its floor
; C Its far edge along +8
CULL_OBJECT:
  LD A,(IX+OBJ_KIND)      ; A door skips the flag tests
  AND $0F                 ;
  CP $01                  ;
  JR Z,CULL_OBJECT_1      ;
  BIT 4,(IY+GAME_FLAGS-V) ; In the scenery pass, leave out live objects
  JR Z,CULL_OBJECT_0      ;
  LD A,(IX+OBJ_WEIGHT)    ;
  AND $1F                 ;
  RET NZ                  ;
CULL_OBJECT_0:
  BIT 5,(IX+OBJ_WEIGHT)   ; Leave out anything taken out of the room
  RET NZ                  ;
CULL_OBJECT_1:
  LD A,(IX+OBJ_SCREEN_X)  ; Across: out if the object lies wholly right or
  SUB (IY+POINT-V)        ; wholly left of the region
  JR C,CULL_OBJECT_2      ;
  SUB (IY+SECOND_POINT-V) ;
  RET NC                  ;
  JR CULL_OBJECT_3        ;
CULL_OBJECT_2:
  ADD A,(IX+OBJ_WIDTH)    ;
  RET NC                  ;
  RET Z                   ;
CULL_OBJECT_3:
  LD A,(IX+OBJ_SCREEN_Y)        ; Down: y is the top row and the sprite hangs
  SUB (IY+POINT_ROW-V)          ; +3 rows below it; out if wholly below or
  JR C,CULL_OBJECT_4            ; above
  SUB (IX+OBJ_ROWS)             ;
  RET NC                        ;
  JR CULL_OBJECT_5              ;
CULL_OBJECT_4:
  ADD A,(IY+SECOND_POINT_ROW-V) ;
  RET NC                        ;
  RET Z                         ;
CULL_OBJECT_5:
  LD A,(IX+OBJ_SPRITE)    ; No sprite, nothing to draw
  OR (IX+OBJ_SPRITE+$01)  ;
  RET Z                   ;
  CALL IS_IN_FRONT            ; In front of the redrawn object: its cover into
  XOR A                       ; page $D8, and done
  BIT 0,(IY+WORK_DIRECTION-V) ;
  JP NZ,DRAW_SPRITE           ;
  LD A,(RIDE_DIRECTION)   ; Behind it: its number onto the list at page $DA;
  INC A                   ; IY+$7F, which REDRAW_OBJECT sets to $FF, holds the
  LD (RIDE_DIRECTION),A   ; last entry's index
  LD H,$DA                ;
  LD L,A                  ;
  LD A,(DRAW_INDEX)       ;
  LD (HL),A               ;
  BIT 4,(IY+GAME_FLAGS-V) ; Scenery behind does not need the list drawn, except
  JR NZ,CULL_OBJECT_6     ; in the scenery pass
  LD A,(IX+OBJ_WEIGHT)    ;
  AND $1F                 ;
  RET Z                   ;
CULL_OBJECT_6:
  SET 1,(IY+WORK_DIRECTION-V) ; The list has something to draw
  RET                         ;

; Point IX at an object record by its number
;
; Used by the routine at SORT_AND_DRAW_BEHIND.
;
; Records are numbered from 1, the first of the six fixed ones (FIXED_RECORDS);
; the knight's is 7 (KNIGHT). Twenty bytes each. Used by the sorting in
; SORT_AND_DRAW_BEHIND (Krumlinde's RTN_ObjectPtr_From_Index).
;
;   B The record's number
; O:IX The record
RECORD_FROM_NUMBER:
  LD DE,$0014                  ; From the first record, twenty bytes a step;
  LD IX,FIXED_RECORDS          ; the jump into the loop makes one step fewer
  JR RECORD_FROM_NUMBER_STEP_0 ; than B

; The stepping loop of RECORD_FROM_NUMBER
;
; A routine of its own only because RECORD_FROM_NUMBER jumps into the middle of
; it: IX moves on a record for each number past the first.
RECORD_FROM_NUMBER_STEP:
  ADD IX,DE
; This entry point is used by the routine at RECORD_FROM_NUMBER.
RECORD_FROM_NUMBER_STEP_0:
  DJNZ RECORD_FROM_NUMBER_STEP
  RET

; Put the objects behind in drawing order, and draw them into pages $DA and $DB
;
; Used by the routine at REDRAW_OBJECT.
;
; Called by REDRAW_OBJECT when the list that CULL_OBJECT built at page $DA has
; something to draw (bit 1 of IY+$71). The list holds record numbers; IY+$7F
; the index of the last. Krumlinde's name for it is RTN_Sort_And_Draw_Sprites.
;
; First the list is sorted. For each place in turn, the entries after it are
; tested against the one there with IS_IN_FRONT; if one of them stands in front
; of it, the entry is taken out, the rest close up, it goes on the end, and
; whatever now fills its place is tested in turn. The list is drawn from the
; end back, so each object is drawn before anything in front of it. An
; isometric scene has no single depth to sort by, and three objects can each
; stand in front of the next; the fifty moves allowed at each place (IY+$7E)
; are what stop such a ring from sorting forever.
;
; Then the list is copied up to IY+$46, since the pages it lies in are about to
; be cleared -- thirty bytes whatever its length, over the printer's position
; and the room origin, which are wanted only while printing or drawing a room
; -- and drawn: each object's cover is ORed into page $DA and cleared out of
; page $DB (mode 4), and its image ORed into page $DB (mode 8). So page $DA
; ends up with where the objects behind cover the region, and page $DB with
; what they show, nearer over farther. In an ordinary pass the entries at the
; back of the list that are scenery or doors are skipped, because the clean
; copy the compositor starts from already shows them; from the first live
; object on everything is drawn, scenery included, since it has to cover that
; object. In the scenery pass everything is drawn.
SORT_AND_DRAW_BEHIND:
  LD HL,BUFFER_DA00           ; One entry: nothing to sort. IY+$74 counts the
  LD A,(RIDE_DIRECTION)       ; places still to settle
  AND A                       ;
  LD (WORK_WEIGHT),A          ;
  JR Z,SORT_AND_DRAW_BEHIND_5 ;
SORT_AND_DRAW_BEHIND_0:
  LD (IY+DRAW_COUNT-V),$32 ; At most fifty moves at this place
SORT_AND_DRAW_BEHIND_1:
  LD B,(HL)               ; The record at this place, and its far corner
  CALL RECORD_FROM_NUMBER ;
  CALL FAR_CORNER         ;
  LD B,(IY+WORK_WEIGHT-V)      ; Test each entry after it; none in front: the
  PUSH HL                      ; place is settled
SORT_AND_DRAW_BEHIND_2:
  INC HL                       ;
  LD A,(HL)                    ;
  EXX                          ;
  LD B,A                       ;
  CALL RECORD_FROM_NUMBER      ;
  EXX                          ;
  CALL IS_IN_FRONT             ;
  BIT 0,(IY+WORK_DIRECTION-V)  ;
  JR NZ,SORT_AND_DRAW_BEHIND_3 ;
  DJNZ SORT_AND_DRAW_BEHIND_2  ;
  JR SORT_AND_DRAW_BEHIND_4    ;
SORT_AND_DRAW_BEHIND_3:
  POP HL                  ; One is in front: take this entry out and close up
  PUSH HL                 ; the list...
  LD A,(HL)               ;
  PUSH HL                 ;
  POP DE                  ;
  INC HL                  ;
  LD BC,$001E             ;
  LDIR                    ;
  LD L,(IY+RIDE_DIRECTION-V) ; ...and put it on the end
  LD H,$DA                   ;
  LD (HL),A                  ;
  DEC (IY+DRAW_COUNT-V)       ; Test what now fills the place, unless the moves
  JR Z,SORT_AND_DRAW_BEHIND_4 ; are used up
  POP HL                      ;
  JR SORT_AND_DRAW_BEHIND_1   ;
SORT_AND_DRAW_BEHIND_4:
  POP HL                       ; The next place
  INC HL                       ;
  DEC (IY+WORK_WEIGHT-V)       ;
  JR NZ,SORT_AND_DRAW_BEHIND_0 ;
SORT_AND_DRAW_BEHIND_5:
  LD HL,BUFFER_DA00       ; Keep the list up at IY+$46, out of the pages about
  LD DE,DRAW_LIST         ; to be cleared
  LD BC,$001E             ;
  LDIR                    ;
  LD HL,BUFFER_DC00       ; Clear pages $DA and $DB (512 bytes), and start at
  LD A,(RIDE_DIRECTION)   ; the last entry (IY+DRAW_COUNT-V)
  LD (IY+DRAW_COUNT-V),A  ;
  CALL CLEAR_512_BELOW    ;
  BIT 4,(IY+GAME_FLAGS-V)      ; An ordinary pass: nothing is drawn until the
  JR NZ,SORT_AND_DRAW_BEHIND_6 ; first live object
  RES 1,(IY+WORK_DIRECTION-V)  ;
SORT_AND_DRAW_BEHIND_6:
  LD H,$FF                ; The record at this index
  LD A,(DRAW_COUNT)       ;
  ADD A,$C6               ;
  LD L,A                  ;
  LD B,(HL)               ;
  CALL RECORD_FROM_NUMBER ;
  BIT 1,(IY+WORK_DIRECTION-V)  ; Until then, skip scenery and doors; draw from
  JR NZ,SORT_AND_DRAW_BEHIND_7 ; the first live object on
  LD A,(IX+OBJ_KIND)           ;
  AND $0F                      ;
  CP $01                       ;
  JR Z,SORT_AND_DRAW_BEHIND_8  ;
  LD A,(IX+OBJ_WEIGHT)         ;
  AND $1F                      ;
  JR Z,SORT_AND_DRAW_BEHIND_8  ;
  SET 1,(IY+WORK_DIRECTION-V)  ;
SORT_AND_DRAW_BEHIND_7:
  LD A,$04                ; Its cover into page $DA, its image into page $DB
  CALL DRAW_SPRITE        ;
  LD A,$08                ;
  CALL DRAW_SPRITE        ;
SORT_AND_DRAW_BEHIND_8:
  LD A,(DRAW_COUNT)            ; On to the first entry
  DEC A                        ;
  LD (DRAW_COUNT),A            ;
  CP $FF                       ;
  JR NZ,SORT_AND_DRAW_BEHIND_6 ;
  RET                          ;

; Is this object in front of the other?
;
; Used by the routines at CULL_OBJECT and SORT_AND_DRAW_BEHIND.
;
; Sets bit 0 of IY+$71 if the object at IX stands in front of the other object
; whose far corner and floor are in D, E and C (FAR_CORNER): if it does not lie
; wholly beyond the other on any axis. That is: its +6 is less than the other's
; far edge along +6, its top (+7) is above the other's floor, and its +8 is
; less than the other's far edge along +8. Greater +6 and +8 are farther from
; the viewer, and something wholly below another's floor is under it, so drawn
; behind it. Asked only of objects that overlap on the screen, one answer is
; enough to order them. Krumlinde's name for it is RTN_ComparePosition.
;
;   IX The object
;   D The other's far edge along +6
;   E The other's floor
;   C The other's far edge along +8
; O:F Carry and zero are left from the last comparison made
IS_IN_FRONT:
  LD A,D                      ; Not in front if its +6 is at or beyond the
  RES 0,(IY+WORK_DIRECTION-V) ; other's far edge
  CP (IX+OBJ_X)               ;
  RET C                       ;
  RET Z                       ;
  LD A,E                  ; Or its top is at or below the other's floor
  CP (IX+OBJ_TOP)         ;
  RET NC                  ;
  LD A,C                  ; Or its +8 is at or beyond the other's far edge
  CP (IX+OBJ_Z)           ;
  RET C                   ;
  RET Z                   ;
  SET 0,(IY+WORK_DIRECTION-V) ; In front
  RET                         ;

; Draw an object's sprite into one of the region's buffers
;
; Used by the routines at REDRAW_OBJECT, CULL_OBJECT and SORT_AND_DRAW_BEHIND.
;
; The one routine that draws objects, and it never touches the screen: it draws
; the object at IX into a buffer the shape of the region being rebuilt -- a row
; one byte wider than the region's width in bytes (IY+$73), as many rows as the
; region is high, wrapping within its 256-byte page -- clipped to the region
; and shifted to the pixel. The compositor (COMPOSITE_TO_SCREEN) then makes the
; screen's bytes from the buffers. Krumlinde's name for it is RTN_Draw_Sprite.
;
; The mode in A says what is drawn where. Mode $80, for the object being
; redrawn (REDRAW_OBJECT): its mask, into page $D9, with three rows of $FF
; (nothing covered) above and below it. Mode 0, for an object in front of it
; (CULL_OBJECT): its cover -- the mask inverted, a bit set where the object
; shows -- ORed into page $D8. Modes 4 and 8, for the objects behind
; (SORT_AND_DRAW_BEHIND): the cover ORed into page $DA and cleared out of page
; $DB, and then the image ORed into page $DB. A sprite is its image and then
; its mask, each width/8 bytes by height rows (+2 and +3), so every mode but 8
; starts one plane in.
;
; The setting up works out, in turn: which rows to draw -- skipping the
; sprite's rows above the region, or the buffer's rows above the sprite -- into
; IY+$75; the shift, x mod 8, written into the JR in DRAW_SPRITE_ROWS that
; jumps into its run of RRCAs, and the masks for the two parts of a shifted
; byte written into the three ANDs there; and which columns: a sprite starting
; left of the region is handled by DRAW_SPRITE_CLIP_LEFT, one starting inside
; it by moving the buffer pointer along (DRAW_SPRITE_SKIP_COLUMNS). Then
; DRAW_SPRITE_ROWS draws.
;
; The bits of C, besides the mode's: bit 4, the sprite starts left of the
; region; bit 5, the first column only primes the spill and is not written; bit
; 6, no spill column after the last, because the sprite is on a byte boundary
; or is cut by the region's right edge.
;
; A The mode: $80, 0, 4 or 8
; IX The object's record
DRAW_SPRITE:
  PUSH BC                 ; The sprite's width in bytes, kept at IY+$78
  PUSH DE                 ;
  LD C,A                  ;
  LD A,(IX+OBJ_WIDTH)     ;
  SRL A                   ;
  SRL A                   ;
  SRL A                   ;
  LD B,A                  ;
  LD (FOUND_RECORD),A     ;
  XOR A                   ; One plane's size: width times height
DRAW_SPRITE_0:
  ADD A,(IX+OBJ_ROWS)     ;
  DJNZ DRAW_SPRITE_0      ;
  LD H,(IX+OBJ_SPRITE+$01) ; The sprite; every mode but 8 draws the second
  LD L,(IX+OBJ_SPRITE)     ; plane, the mask
  BIT 3,C                  ;
  JR NZ,DRAW_SPRITE_1      ;
  LD E,A                   ;
  LD D,$00                 ;
  ADD HL,DE                ;
DRAW_SPRITE_1:
  EX DE,HL                ; DE: where to read from
  LD A,(POINT_ROW)        ; Does the sprite start above the region's top row?
  SUB (IX+OBJ_SCREEN_Y)   ;
  JR C,DRAW_SPRITE_3      ;
  LD B,A                  ; No: skip the buffer's rows above it (a count of 0
  XOR A                   ; goes round 256 times and comes back to no rows)
DRAW_SPRITE_2:
  ADD A,(IY+DRAW_WIDTH-V) ;
  INC A                   ;
  DJNZ DRAW_SPRITE_2      ;
  LD L,A                  ;
  LD H,$D9                ;
  LD A,(POINT_ROW)            ; And draw down to the region's bottom, or the
  SUB (IY+SECOND_POINT_ROW-V) ; sprite's height if that is less
  LD B,A                      ;
  LD A,(IX+OBJ_SCREEN_Y)      ;
  SUB B                       ;
  CP (IX+OBJ_ROWS)            ;
  JR C,DRAW_SPRITE_5          ;
  LD A,(IX+OBJ_ROWS)          ;
  JR DRAW_SPRITE_5            ;
DRAW_SPRITE_3:
  CPL                      ; Yes: skip the sprite's rows above the region
  LD H,A                   ;
  LD B,(IY+FOUND_RECORD-V) ;
  INC H                    ;
  XOR A                    ;
DRAW_SPRITE_4:
  ADD A,H                  ;
  DJNZ DRAW_SPRITE_4       ;
  LD H,$00                 ;
  LD L,A                   ;
  ADD HL,DE                ;
  EX DE,HL                 ;
  LD HL,BUFFER_D900       ; And draw from the buffer's top down to the sprite's
  LD A,(IX+OBJ_SCREEN_Y)  ; bottom
  SUB (IX+OBJ_ROWS)       ;
  LD B,A                  ;
  LD A,(POINT_ROW)        ;
  SUB B                   ;
DRAW_SPRITE_5:
  LD (IY+WORK_ANIMATION-V),A ; The rows to draw
  LD A,(IX+OBJ_SCREEN_X)  ; 7 minus (x mod 8) into the JR's displacement: that
  CPL                     ; many of the seven RRCAs are jumped over
  AND $07                 ;
  LD ($EFD1),A            ;
  CP $07                  ; On a byte boundary: nothing spills into a next
  JR NZ,DRAW_SPRITE_6     ; column
  SET 6,C                 ;
DRAW_SPRITE_6:
  LD B,A                  ; A mask of the low 8 minus (x mod 8) bits: the part
  XOR A                   ; of a shifted byte that stays in its column
  INC B                   ;
DRAW_SPRITE_7:
  SCF                     ;
  RLA                     ;
  DJNZ DRAW_SPRITE_7      ;
  LD ($EFF4),A            ; Into the two ANDs that keep it, and its complement
  LD ($EFE3),A            ; into the one that keeps the spill
  CPL                     ;
  LD ($F008),A            ;
  LD A,(POINT)            ; Columns from the region's left byte to the
  AND $F8                 ; sprite's; bit 4 if the sprite starts left of it
  LD B,A                  ;
  LD A,(IX+OBJ_SCREEN_X)  ;
  AND $F8                 ;
  SUB B                   ;
  JR NC,DRAW_SPRITE_8     ;
  SET 4,C                 ;
  NEG                     ;
DRAW_SPRITE_8:
  SRL A                       ; In bytes; starting left: DRAW_SPRITE_CLIP_LEFT
  SRL A                       ;
  SRL A                       ;
  LD B,A                      ;
  BIT 4,C                     ;
  JR NZ,DRAW_SPRITE_CLIP_LEFT ;
  INC B                           ; Starting inside: draw what fits before the
  SET 6,C                         ; region's right edge and its spare column,
  SUB (IY+DRAW_WIDTH-V)           ; the spill cut off...
  NEG                             ;
  INC A                           ;
  CP (IY+FOUND_RECORD-V)          ;
  JR C,DRAW_SPRITE_SKIP_COLUMNS_0 ;
  JR Z,DRAW_SPRITE_SKIP_COLUMNS_0 ;
  LD A,(FOUND_RECORD)           ; ...or the whole width and the spill column
  RES 6,C                       ; after it
  JR DRAW_SPRITE_SKIP_COLUMNS_0 ;

; Part of DRAW_SPRITE: move the buffer pointer to the sprite's first column
;
; A routine of its own only because DRAW_SPRITE jumps into the middle of it. B
; is one more than the columns to pass over.
DRAW_SPRITE_SKIP_COLUMNS:
  INC HL
; This entry point is used by the routine at DRAW_SPRITE.
DRAW_SPRITE_SKIP_COLUMNS_0:
  DJNZ DRAW_SPRITE_SKIP_COLUMNS
  JR DRAW_SPRITE_ROWS_1

; Part of DRAW_SPRITE: a sprite that starts left of the region
;
; Used by the routine at DRAW_SPRITE.
;
; A holds how many of the sprite's bytes lie left of the region's first. The
; columns drawn are the rest of the sprite, or, if it also runs past the
; region's right edge, the region's width and its spare column (bit 6 then: no
; spill beyond). The last byte left of the region is still read, and one more
; column drawn for it, because its shifted spill is the first visible column's
; left part; bit 5, set as the drawing starts, keeps it from being written
; itself.
;
; A The bytes cut off at the left
DRAW_SPRITE_CLIP_LEFT:
  PUSH DE                       ; The sprite runs past the right edge too: the
  LD E,A                        ; region's width and its spare column
  ADD A,(IY+DRAW_WIDTH-V)       ;
  SUB (IY+FOUND_RECORD-V)       ;
  JR NC,DRAW_SPRITE_CLIP_LEFT_0 ;
  LD A,(DRAW_WIDTH)             ;
  SET 6,C                       ;
  INC A                         ;
  JR DRAW_SPRITE_CLIP_LEFT_1    ;
DRAW_SPRITE_CLIP_LEFT_0:
  LD A,(FOUND_RECORD)     ; Or the rest of the sprite
  SUB E                   ;
DRAW_SPRITE_CLIP_LEFT_1:
  POP DE                  ; On to skip the bytes cut off
  JR DRAW_SPRITE_ROWS_0   ;

; Part of DRAW_SPRITE: skip the bytes cut off at the left, then draw the rows
;
; The drawing. The sprite pointer stays in HL, and the buffer pointer and the
; mode move to the alternate set, so the loop holds both without touching
; memory. Each sprite byte is inverted if the mode is $80 (the mask, inverted,
; is cover, so the zero bits the shift brings in mean nothing covered; it is
; inverted back as it is stored), rotated right by x mod 8 through the patched
; JR, and split: the part that stays in this column, with the last column's
; spill ORed in, is written; the part that spills is kept in E for the next.
; Mode $80 stores the byte as it is; modes 0 and 8 OR it in; mode 4 ORs it into
; page $DA and first clears the same bits from page $DB.
;
; The three ANDs and the JR's displacement here are rewritten by DRAW_SPRITE
; before every sprite; the operands the listing shows are the tape's.
DRAW_SPRITE_ROWS:
  INC DE                  ; Skip the bytes cut off (one fewer: the last of them
; This entry point is used by the routine at DRAW_SPRITE_CLIP_LEFT.
DRAW_SPRITE_ROWS_0:
  DJNZ DRAW_SPRITE_ROWS   ; primes the spill), and count that column
  INC A                   ; }
; This entry point is used by the routine at DRAW_SPRITE_SKIP_COLUMNS.
DRAW_SPRITE_ROWS_1:
  LD (WORK_WEIGHT),A      ; The columns to draw
  PUSH HL                    ; The buffer pointer and the mode to the alternate
  EX DE,HL                   ; set; the rows; page $D9 to start with
  PUSH BC                    ;
  EXX                        ;
  POP BC                     ;
  POP HL                     ;
  LD B,(IY+WORK_ANIMATION-V) ;
  LD H,$D9                   ;
  BIT 7,C                 ; Mode $80?
  JR Z,DRAW_SPRITE_ROWS_6 ;
  LD B,$03                 ; Yes: three rows of $FF, nothing covered, at the
  XOR A                    ; top of page $D9...
DRAW_SPRITE_ROWS_2:
  ADD A,(IY+WORK_WEIGHT-V) ;
  INC A                    ;
  DJNZ DRAW_SPRITE_ROWS_2  ;
  LD B,A                   ;
  LD HL,BUFFER_D900        ;
DRAW_SPRITE_ROWS_3:
  LD (HL),$FF              ;
  INC HL                   ;
  DJNZ DRAW_SPRITE_ROWS_3  ;
  LD H,A                        ; ...and three below the sprite's rows...
  LD B,(IY+WORK_WEIGHT-V)       ;
  INC B                         ;
DRAW_SPRITE_ROWS_4:
  ADD A,(IY+SECOND_POINT_ROW-V) ;
  DJNZ DRAW_SPRITE_ROWS_4       ;
  LD L,A                        ;
  LD B,H                        ;
  LD A,H                        ;
  LD H,$D9                      ;
DRAW_SPRITE_ROWS_5:
  LD (HL),$FF                   ;
  INC HL                        ;
  DJNZ DRAW_SPRITE_ROWS_5       ;
  LD L,A                     ; ...and the sprite from the fourth row
  LD B,(IY+WORK_ANIMATION-V) ;
  JR DRAW_SPRITE_ROWS_8      ;
DRAW_SPRITE_ROWS_6:
  DEC H                   ; The other modes: page $D8, page $DA for mode 4,
  BIT 2,C                 ; page $DB for mode 8
  JR Z,DRAW_SPRITE_ROWS_7 ;
  LD H,$DA                ;
DRAW_SPRITE_ROWS_7:
  BIT 3,C                 ;
  JR Z,DRAW_SPRITE_ROWS_8 ;
  LD H,$DB                ;
DRAW_SPRITE_ROWS_8:
  PUSH HL                 ; Each row: E carries the spill from column to
  EXX                     ; column; the first column only primes it if the
  PUSH HL                 ; sprite starts left of the region
  LD B,(IY+WORK_WEIGHT-V) ;
  LD E,$00                ;
  BIT 4,C                 ;
  JR Z,DRAW_SPRITE_ROWS_9 ;
  SET 5,C                 ;
DRAW_SPRITE_ROWS_9:
  LD A,(HL)                ; Each column: a sprite byte; mode $80 inverts the
  INC HL                   ; mask into cover
  BIT 7,C                  ;
  JR Z,DRAW_SPRITE_ROWS_10 ;
  CPL                      ;
DRAW_SPRITE_ROWS_10:
  JR DRAW_SPRITE_ROWS_11  ; Patched: jumps over 7 minus (x mod 8) of the RRCAs
DRAW_SPRITE_ROWS_11:
  RRCA                    ; Rotate right by x mod 8
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  BIT 3,C                   ; Mode 8, the image
  JR NZ,DRAW_SPRITE_ROWS_13 ;
  BIT 7,C                  ; Mode $80?
  JR Z,DRAW_SPRITE_ROWS_12 ;
  LD D,A                  ; Yes: this column's part (the AND is patched) with
  AND $01                 ; the last one's spill, back into a mask
  OR E                    ;
  CPL                     ;
  EXX                     ;
  JR DRAW_SPRITE_ROWS_16  ;
DRAW_SPRITE_ROWS_12:
  CPL                     ; Modes 0 and 4: the mask becomes cover
DRAW_SPRITE_ROWS_13:
  LD D,A                   ; The whole byte kept for the spill; only that, the
  BIT 5,C                  ; first time round when the first column is not
  JR Z,DRAW_SPRITE_ROWS_14 ; written
  RES 5,C                  ;
  JR DRAW_SPRITE_ROWS_17   ;
DRAW_SPRITE_ROWS_14:
  AND $01                 ; This column's part (the AND is patched), with the
  OR E                    ; last one's spill
  EXX                     ;
  BIT 2,C                  ; Mode 4: clear this cover out of the image in page
  JR Z,DRAW_SPRITE_ROWS_15 ; $DB
  INC H                    ;
  PUSH AF                  ;
  CPL                      ;
  AND (HL)                 ;
  LD (HL),A                ;
  POP AF                   ;
  DEC H                    ;
DRAW_SPRITE_ROWS_15:
  OR (HL)                 ; OR it into the buffer (or, for mode $80, store it);
DRAW_SPRITE_ROWS_16:
  LD (HL),A               ; the next column
  INC L                   ;
  EXX                     ;
DRAW_SPRITE_ROWS_17:
  LD A,D                  ; The spill for the next column (the AND is patched)
  AND $FF                 ;
  LD E,A                  ;
  DJNZ DRAW_SPRITE_ROWS_9 ;
  POP HL                   ; The sprite's next row
  LD D,$00                 ;
  LD E,(IY+FOUND_RECORD-V) ;
  ADD HL,DE                ;
  EXX
  BIT 6,C                   ; A spill column after the last?
  JR NZ,DRAW_SPRITE_ROWS_20 ;
  CPL                       ; Write the spill into it the same way
  BIT 7,C                   ;
  JR NZ,DRAW_SPRITE_ROWS_19 ;
  BIT 2,C                   ;
  JR Z,DRAW_SPRITE_ROWS_18  ;
  INC H                     ;
  PUSH AF                   ;
  AND (HL)                  ;
  LD (HL),A                 ;
  POP AF                    ;
  DEC H                     ;
DRAW_SPRITE_ROWS_18:
  CPL                       ;
  OR (HL)                   ;
DRAW_SPRITE_ROWS_19:
  LD (HL),A                 ;
DRAW_SPRITE_ROWS_20:
  POP HL                  ; The buffer's next row: one byte wider than the
  LD A,L                  ; region
  ADD A,(IY+DRAW_WIDTH-V) ;
  LD L,A                  ;
  INC L                   ;
  DJNZ DRAW_SPRITE_ROWS_8 ;
  POP DE                  ; Done
  POP BC                  ;
  RET                     ;

; Find an object's far corner and floor
;
; Used by the routines at REDRAW_OBJECT and SORT_AND_DRAW_BEHIND.
;
; D is +6 plus +9 and C is +8 plus +11, the far edges along the two floor axes;
; E is +7, the top, less +10, the height: the floor it stands on. IS_IN_FRONT
; tests other objects against them. Krumlinde's name for it is
; RTN_ComputeSortKey.
;
;   IX The object's record
; O:D The far edge along +6
; O:E The floor
; O:C The far edge along +8
FAR_CORNER:
  LD A,(IX+OBJ_X)
  ADD A,(IX+OBJ_LEN_X)
  LD D,A
  LD A,(IX+OBJ_TOP)
  SUB (IX+OBJ_HEIGHT)
  LD E,A
  LD A,(IX+OBJ_Z)
  ADD A,(IX+OBJ_LEN_Z)
  LD C,A
  RET

; Clear the 256 bytes below HL
;
; Used by the routine at REDRAW_OBJECT.
;
; Used with HL at the top of page $D8 to clear it (REDRAW_OBJECT).
;
; HL The byte after the last to clear
CLEAR_256_BELOW:
  LD B,$20
  JR CLEAR_BELOW

; Clear the 512 bytes below HL
;
; Used by the routine at SORT_AND_DRAW_BEHIND.
;
; And the two entries every fill of the buffers uses: CLEAR_BELOW, at offset 2,
; clears B times 8 bytes below HL, and FILL_BELOW, at offset 5, fills them with
; DE. The stack pointer is put at HL and DE pushed four times a turn, the
; fastest way a Z80 has to fill memory; SP is kept at IY+$76 while it is
; borrowed. No interrupt can push into the area meanwhile: the game runs with
; interrupts off (the DI at offset 11 of START). Krumlinde's names for these
; are RTN_ClearBuffer_512, FastFill_Zero and RTN_FastFill.
;
; HL The byte after the last to fill
; B The number of 8-byte units, at CLEAR_BELOW and FILL_BELOW
; DE The word to fill with, at FILL_BELOW
CLEAR_512_BELOW:
  LD B,$40                ; 64 units: 512 bytes
; This entry point is used by the routines at PRINT, SHOW_THING_IN_USE,
; CLEAR_THING_BOX and CLEAR_256_BELOW.
CLEAR_BELOW:
  LD DE,$0000             ; CLEAR_BELOW: fill with zero
; This entry point is used by the routines at CLEAR_THING_BOX and
; REDRAW_OBJECT.
FILL_BELOW:
  LD (WORK_HEADING),SP    ; FILL_BELOW: the stack pointer borrowed
  LD SP,HL                ;
CLEAR_512_BELOW_0:
  PUSH DE                 ; Eight bytes a turn, going down
  PUSH DE                 ;
  PUSH DE                 ;
  PUSH DE                 ;
  DJNZ CLEAR_512_BELOW_0  ;
  LD SP,(WORK_HEADING)    ; And given back
  RET                     ;

; The title, a game, GAME OVER, and round again
;
; Used by the routine at START.
;
; Reached from the start-up (START) and never left. The title is room 79 drawn
; (DRAW_CURRENT_ROOM), coloured (ATTRI), with the title page printed over it
; (TITLE_PAGE_TEXT) and, in Release 2, 9-JOY beside the controls; then it waits
; for a key. ROOM is kept round the drawing, though the copy from the master a
; moment later sets it anyway.
;
; A key starts a game (NEW_GAME, at offset 36). The master copies made at
; start-up (MASTER_OBJECTS) go back: the object table's first 1200 bytes, and
; the 61 bytes of variables from IY on. TELE, the author's name for offset 54,
; puts the knight's record back as a game starts it and enters the room ROOM
; names (ROOMST). That call returns only when the game is over: LIFE gone, the
; quest's last room reached, or 0 pressed with SYMBOL SHIFT (MAIN_LOOP). Then
; SAVE_OBJECT_POSITIONS puts the room's things back into the object table, and
; room 1 is drawn as the backdrop for GAME OVER, which waits for the keys to be
; let go and one pressed (WAIT) before the title comes round again.
;
; TELE is also where the thing that carries the knight off (type 9, MAIN_LOOP)
; goes, with ROOM set to 30, so he arrives as a new game starts him. The
; knight's +$0E is kept through the copy: its bits 5 and 6 say which way his
; sprites face, and they are turned round in place (MIMAN), so the record must
; go on agreeing with them.
;
; In Release 1 the routine begins by setting IY, turning interrupts off and
; making the start-up's copies, which Release 2 moved into START, and there is
; no 9-JOY. The name the author gave this routine is lost but for its last
; letter, G (SYMBOL_TABLE). Krumlinde's name for it is RTN_Title_Screen_Loop.
TITLE_SCREEN:
  LD A,(ROOM)             ; The title: room 79, with ROOM kept round it
  PUSH AF                 ;
  LD (IY+ROOM-V),$4F      ;
  CALL DRAW_CURRENT_ROOM  ;
  POP AF                  ;
  LD (ROOM),A             ;
  CALL ATTRI              ; Coloured
  CALL TITLE_PAGE_TEXT    ; The title page's text
  CALL PRINT              ; And Release 2's note that 9 turns the joystick on
  DEFB $C8,$C8,$50        ; Print at x 200, y 80
  DEFB $24,$26,$0A,$0F,$19 ; "9-JOY"
  DEFB $A4                ; End of the string
  CALL PAUS
NEW_GAME:
  LD HL,MASTER_OBJECTS    ; NEW_GAME: the object table's master copy back
  LD DE,OBJECTS           ;
  LD BC,$04B0             ;
  LDIR                    ;
  LD DE,OBJECT_COUNT      ; And the variables' (HL runs on from the one to the
  LD C,$3D                ; other)
  LDIR                    ;
; This entry point is used by the routine at MAIN_LOOP.
TELE:
  LD A,(KNIGHT_FLAGS)     ; TELE: the knight's record from the master, but for
  LD HL,MASTER_KNIGHT     ; his +$0E
  LD DE,KNIGHT            ;
  LD BC,$0014             ;
  LDIR                    ;
  LD (KNIGHT_FLAGS),A     ;
  CALL ROOMST             ; Play: back here when the game is over
  CALL SAVE_OBJECT_POSITIONS ; The room's things back into the object table,
                             ; and the creatures' sprites turned back
  LD (IY+ROOM-V),$01      ; Room 1 as GAME OVER's backdrop
  CALL DRAW_CURRENT_ROOM  ;
  CALL PRINT              ; GAME OVER
  DEFB $C8,$5A,$64        ; Print at x 90, y 100
  DEFB $07,$01,$0D,$05,$00,$0F,$16,$05 ; "GAME OVER"
  DEFB $12                             ;
  DEFB $A4                ; End of the string
  CALL ATTRI
  CALL WAIT               ; Wait for the keys to be let go and one pressed; the
  JP TITLE_SCREEN         ; title again

; Wait for no key, then for a key
;
; Used by the routines at TITLE_SCREEN, ROOMST and MAIN_LOOP.
;
; The author's WAIT; PAUS, at offset 6, is the second half alone, a wait for a
; key. Both read all eight half-rows at once (A=0 selects them all), so any key
; will do. WAIT is used after GAME OVER (TITLE_SCREEN), at the end of the quest
; (ROOMST) and for the pause, SPACE with SYMBOL SHIFT (MAIN_LOOP); PAUS under
; the title.
WAIT:
  XOR A                   ; Until no key is held
  CALL INPUT              ;
  JR NZ,WAIT              ;
; This entry point is used by the routine at TITLE_SCREEN.
PAUS:
  XOR A                   ; PAUS: until one is
  CALL INPUT              ;
  JR Z,PAUS               ;
  RET                     ;

; Read a row of keys
;
; Used by the routines at WAIT, CREATURE_UPDATE, KNIGHT_CONTROLS and MAIN_LOOP.
;
; The author's INPUT. A selects the half-rows the way the high byte of IN
; A,($FE)'s address does, a 0 bit for each one read; what comes back has a bit
; set for each key held.
;
;   A The half-rows to read
; O:A Bits 0-4, one for each key held
; O:F Z if none is
INPUT:
  IN A,($FE)              ; Keys pull their bits low: turn them round
  AND $1F                 ;
  XOR $1F                 ;
  RET                     ;

; Read the Kempston joystick, if it is in use
;
; Used by the routines at CREATURE_UPDATE, KNIGHT_CONTROLS and MAIN_LOOP.
;
; The author's IN31: 31 ($1F) is the Kempston interface's port. Nothing is read
; unless bit 3 of OPTIONS is set, which 9 turns on and off (MAIN_LOOP): on a
; Spectrum without the interface the port gives whatever the bus holds, which
; would read as the stick being moved. The port is read three times and the
; reads ORed together; why three is not known. Each XOR A puts 0 in the high
; half of the port's address.
;
; Release 1's routine is XOR A and RET before the same reads: its joystick is
; switched off, and Release 2's switch and the 9-JOY on the title are the
; change (see the notes' versions.md).
;
; O:A Bits 0-4: right, left, down, up, fire (0 if not in use)
; O:F Z if nothing
IN31:
  XOR A                   ; Not in use: nothing
  BIT 3,(IY+OPTIONS-V)    ;
  RET Z                   ;
  IN A,($1F)              ; Three reads, ORed
  LD B,A                  ;
  XOR A                   ;
  IN A,($1F)              ;
  OR B                    ;
  LD B,A                  ;
  XOR A                   ;
  IN A,($1F)              ;
  OR B                    ;
  AND $1F                 ; The five bits
  RET                     ;

; Colour the whole screen in the room's colour
;
; Used by the routines at TITLE_SCREEN, ROOMST and MAIN_LOOP.
;
; The author's ATTRI: all 768 attribute bytes set to ROOM_COLOUR. A room is
; drawn unseen, its attributes cleared (DRAW_CURRENT_ROOM), and coloured only
; when it is complete: under the title and GAME OVER (TITLE_SCREEN), at the end
; of the quest (ROOMST), and after the first pass of a new room, when every
; object has been drawn (MAIN_LOOP).
ATTRI:
  LD A,(ROOM_COLOUR)
  LD HL,$5800
  LD (HL),A
  LD DE,$5801
  LD BC,$02FF
  LDIR
  RET

; Copy the screen to the clean copy at LOADING_TUNE
;
; Used by the routines at ROOMST and DRAW_STILL_THINGS.
;
; The author's RESTOR. The 6144 bytes of the screen's bitmap go to
; LOADING_TUNE, where the loading tune was. Entering a room (ROOMST) does it
; twice: once when the room is drawn, as the background the scenery is drawn
; over, and once when the scenery is done. The compositor (COMPOSITE_TO_SCREEN)
; takes the background from this copy wherever it rebuilds the screen round a
; moving object, which is what the name is about: it is what restores the
; picture an object uncovers.
RESTOR:
  LD HL,$4000
  LD DE,LOADING_TUNE
  LD BC,$1800
  LDIR
  RET

; Turn the knight's sprites to face his way
;
; Used by the routine at KNIGHT_CONTROLS.
;
; The author's MIMAN, mirror man: MIRROR (MITRO) for the knight, whose sprites
; begin at SPRITE9110: 28 planes, the image and mask of all fourteen of his
; frames. Called from his walking (KNIGHT_CONTROLS).
;
; C His direction bits
; E His +$0E
; IX His record
MIMAN:
  LD HL,SPRITE9110        ; The first sprite; 28 planes, counted in the
  EXX                     ; alternate C
  LD C,$1C                ;
  JR MIRROR               ;

; Turn the sprites of the state-11 creature to face its way
;
; Used by the routines at CREATURE_UPDATE and SAVE_OBJECT_POSITIONS.
;
; The author's MIWRAI, which reads as "mirror wraith": MIRROR (MITRO) for the
; two frames at SPRITE5E88, 4 planes, the sprites of objects in state 11
; (CREATURE_UPDATE), and in SAVE_OBJECT_POSITIONS to turn them back as a room
; is left.
;
; C Its direction bits
; E Its +$0E
; IX Its record
MIWRAI:
  LD HL,SPRITE5E88        ; The first sprite; 4 planes
  EXX                     ;
  LD C,$04                ;
  JR MIRROR               ;

; Turn the sprites of the state-7 creature to face its way
;
; Used by the routines at CREATURE_UPDATE and SAVE_OBJECT_POSITIONS.
;
; The author's MITRO, which reads as "mirror troll": the six frames at
; SPRITE8BB8, 12 planes, the sprites of objects in state 7 (CREATURE_UPDATE),
; and turned back as a room is left (SAVE_OBJECT_POSITIONS).
;
; Then MIRROR, at offset 6, the part the three share. The direction bits in C
; become two facing bits in E: bit 6 says which of the two views the sprites
; show, bit 5 whether the view is mirrored. $08 (Y to P, or the stick right) is
; view 0 as drawn; $40 (Q to T, up) view 0 mirrored; $80 (A to G, down) view 1
; as drawn; $04 (H to ENTER, left) view 1 mirrored. E goes to IY+$72, the copy
; of +$0E that CHE3D writes back, and if bit 5 of the record's +$0E says the
; sprites face the other way they are mirrored in place (MW). With no direction
; bit ($CC) nothing changes.
;
; The sprites are shared by every creature of a kind, so a record's bit 5 is
; only true if one creature of the kind is about: no room has two in state 7 or
; two in state 11 (measured over every room). Leaving a room turns them back
; (SAVE_OBJECT_POSITIONS), so the next room's creature, whose record comes
; fresh from its template with bit 5 clear, agrees with them; the knight's +$0E
; is kept through a new game for the same reason (TELE, TITLE_SCREEN).
; Krumlinde's names are Sub_F117, Sub_F11F and Sub_F127.
;
;   C The direction bits
;   E The record's +$0E
;   IX The record
; O:E The new facing in bits 5 and 6, also at IY+$72
MITRO:
  LD HL,SPRITE8BB8        ; The first sprite; 12 planes
  EXX                     ;
  LD C,$0C                ;
; This entry point is used by the routines at MIMAN and MIWRAI.
MIRROR:
  EXX                     ; MIRROR: no direction, nothing to do
  LD A,C                  ;
  AND $CC                 ;
  RET Z                   ;
  RES 5,E                 ; Bit 5, mirrored: set for $40 and $04
  AND $88                 ;
  JR NZ,MW1               ;
  SET 5,E                 ;
MW1:
  LD A,C                  ; MW1: bit 6, view 1: set for $80 and $04
  SET 6,E                 ;
  AND $84                 ;
  JR NZ,MW2               ;
  RES 6,E                 ;
MW2:
  LD (IY+WORK_BEHAVIOUR-V),E ; MW2: the new facing for the record
  LD A,(IX+OBJ_WIDTH)     ; The width in bytes (the carry is clear from the
  RRA                     ; AND)
  RRA                     ;
  RRA                     ;
  PUSH DE                 ;
  PUSH BC                 ;
  PUSH HL                 ;
  LD C,A                  ;
  CALL MW                 ; Mirror them if they face the other way
  POP HL
  POP BC
  POP DE
  RET

; Mirror a run of sprite planes in place, if they face the other way
;
; Used by the routine at MITRO.
;
; The author's MW. Nothing is done if bit 5 of the record's +$0E, the way the
; sprites face now, already matches bit 5 of E. Otherwise every row of every
; plane is turned end for end: each byte's bits reversed into E and pushed, and
; then popped back over the row, which reverses the bytes' order too.
;
; E The new facing
; C The width in bytes
; HL The first plane
; IX The record
; C' The number of planes
MW:
  LD A,(IX+OBJ_STATE)     ; Already that way round: nothing to do
  BIT 5,E                 ;
  JR NZ,MW0               ;
  XOR $20                 ;
MW0:
  BIT 5,A                 ;
  RET NZ                  ;
  EXX                     ; MIR0: each plane, its height in rows (in the
MIR0:
  LD B,(IX+OBJ_ROWS)      ; alternate B)
MIR1:
  EXX                     ; MIR1: each row, its width in bytes
  LD B,C                  ;
MIR2:
  LD A,(HL)               ; MIR2: each byte's bits reversed, and pushed
  INC HL                  ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  RRA                     ;
  RL E                    ;
  PUSH DE                 ;
  DJNZ MIR2               ;
  LD E,C                  ; Back to the row's start
  LD D,$00                ;
  LD B,E                  ;
  AND A                   ;
  SBC HL,DE               ;
MIR3:
  POP DE                  ; MIR3: the bytes written back, last first
  LD (HL),E               ;
  INC HL                  ;
  DJNZ MIR3               ;
  EXX                     ; The next row; the next plane
  DJNZ MIR1               ;
  DEC C                   ;
  JR NZ,MIR0              ;
  RET                     ;

; Turn facing bits back into a direction, and find the view's sprite
;
; Used by the routines at PICK_UP and KNIGHT_CONTROLS.
;
; The author's FACING, the other way from MIRROR (MITRO): bits 6 and 5 of E
; give C one of $08 or $40 (view 0) or $04 or $80 (view 1), and for view 0 HL
; moves on by the word at IY+$62, from the first view's sprite to the other's.
; Picking up (PICK_UP) and fighting (KNIGHT_CONTROLS) use it to take the pose
; for the way the knight faces.
;
;   E The facing, in bits 5 and 6
;   HL The pose's sprite in view 1
; O:C The direction bit
; O:HL The pose's sprite in the view he faces
FACING:
  BIT 6,E                 ; View 1?
  JR NZ,FA0               ;
  PUSH DE                 ; View 0: its sprite is further on
  LD DE,(AWAY_FRAMES)     ;
  ADD HL,DE               ;
  POP DE                  ;
  LD C,$08                ; $08, or $40 when mirrored
  BIT 5,E                 ;
  RET Z                   ;
  LD C,$40                ;
  RET                     ;
FA0:
  LD C,$04                ; FA0: $80, or $04 when mirrored
  BIT 5,E                 ;
  RET NZ                  ;
  LD C,$80                ;
  RET                     ;

; Take ten from LIFE
;
; Used by the routine at OBJECTS_MEET.
;
; The author's DECLI1; DECLIF, at offset 2, takes what A holds. LIFE is two
; decimal digits (LIFE_TENS and LIFE_UNITS), and it stops at 00, which ends the
; game (MAIN_LOOP). Bit 0 of IY+$17 asks for it to be printed again. Ten or one
; goes when something is met (OBJECTS_MEET), three when the creature in state 4
; strikes (CHE3D), and, when the knight lands from a long fall, what it lasted
; beyond 20 steps (CREATURE_UPDATE). The alternate registers do the work, so
; the caller's are kept.
;
; A How much LIFE to take, at DECLIF
DECLI1:
  LD A,$0A                ; Ten
; This entry point is used by the routines at CHE3D, CREATURE_UPDATE and
; OBJECTS_MEET.
DECLIF:
  SET 0,(IY+GAME_FLAGS-V) ; DECLIF: LIFE to be printed again; take A from its
  EXX                     ; digits
  LD B,$FF                ;
  LD HL,(LIFE_TENS)       ;
  CALL DE1                ;
  LD (LIFE_TENS),HL       ;
  EXX                     ;
  RET                     ;

; Take a number from LIFE's two digits
;
; Used by the routine at DECLI1.
;
; The author's DE1. A is split into tens (counted in B) and units; the units
; are taken from H, borrowing from the tens, and the tens from L. If that goes
; below nothing LIFE is 00.
;
;   A The number, below 100
;   B $FF
;   L The tens
;   H The units
; O:HL The new tens and units
DE1:
  INC B                   ; Tens into B, units into C
  SUB $0A                 ;
  JR NC,DE1               ;
  ADD A,$0A               ;
  LD C,A                  ;
  LD A,H                  ; The units, borrowing a ten if need be
  SUB C                   ;
  JR NC,DE2               ;
  ADD A,$0A               ;
  INC B                   ;
DE2:
  LD H,A                  ; DE2: the tens
  LD A,L                  ;
  SUB B                   ;
  LD L,A                  ;
  RET NC                  ;
  XOR A                   ; Below nothing: 00
  LD L,A                  ;
  LD H,A                  ;
  RET                     ;

; Update one object: the start of the dispatch on its state
;
; Used by the routines at ANIMATE_AND_MOVE and MAIN_LOOP.
;
; The author's CHE3D (Krumlinde's Sub_F1E0). The main loop (MAIN_LOOP) calls it
; once a pass for every record from the knight's on, and the movement code
; comes back to it at once for an object whose carried-along movement has just
; stopped (ANIMATE_AND_MOVE). Nothing is done for an object without a sprite, a
; door (type 1 in +$0C, dealt with where it is met, BUMPED), anything taken out
; of the room (bit 5 of +$10) or scenery (bits 0-4 of +$10 clear). The labels
; inside are the author's own.
;
; Otherwise the record's first 19 bytes are copied to IY+$64 on and its address
; kept at IY+$7D; its state byte, +$0E, is also kept at IY+$67, for the
; movement code to see bit 7 of it as it was when the pass began. In the first
; pass after a room is entered (bit 2 of IY+$17) the object is only drawn where
; it stands (NOG, ANIMATE_AND_MOVE). An object carried along by a movement
; already under way (bit 7 of +$0E) carries on in the direction kept in +$12
; (NOPROP). Otherwise the low four bits of +$0E, its state, say what it does.
; The states dealt with here:
;
; State 0, at rest: it falls if it can -- the movement code adds the fall --
; except that with bit 4 of +$0E, which is cleared as it is read, it makes its
; last movement (+$0D) once more instead: a thing just dropped
; (CREATURE_UPDATE) or knocked (OBJECTS_MEET). The pass also notes two kinds of
; thing as it meets them: the first thing of type 8 (+$0C) is kept at IY+$0F
; with bit 0 of IY+$11 set, and the creatures in state 9 go for it rather than
; for the knight (ZOOMIN, ZOOMIN), and destroy it when they reach it
; (MEET_DECOY); a thing of kind 11 sets bit 1 of IY+$11, which wakes the
; creature in state 15 (CREATURE_UPDATE). Both are forgotten when a room is
; entered, a thing is picked up, or the kind-8 thing is destroyed.
;
; State 3 bounces about: it keeps moving along its last movement, $45 (a
; diagonal) when it has none, and the movement code turns it round when it is
; blocked. State 4 strikes at the knight when he is in its reach -- its own box
; moved 12 towards lower +6, towards the viewer -- taking three from LIFE each
; pass and showing its striking frames (TYPE48_FRAMES); otherwise it is left
; alone. State 5 is the knight in a jump (KNIGHT_CONTROLS starts one): eight
; passes going up in the direction he was walking, without the fall, then back
; to state 8 to come down. State 9 is a creature that rises out of the floor:
; after a wait it grows through four frames (SPRITEA4B8 to SPRITEA2E4) as +$11
; counts up, and then walks after the knight like state 6. Every other state,
; the knight's 8 among them, goes on to CREATURE_UPDATE.
;
; Bit 7 of IY+$17 is set when the thing of type 5 is used (MAIN_LOOP), and
; lasts until a room is entered. While it is set every state but the knight's 8
; and his jump's 5 is dealt with as state 0: the creatures stand where they are
; and only fall. Release 1 excepts only state 8 -- at offset 131 it has JR I00
; where Release 2 has CP 5 and JR NZ -- and there a knight who jumps while the
; freeze lasts stays in state 5 for good, since nothing counts his jump down:
; he never walks again. Played in the simulator in both releases (the type-5
; thing in room 24 picked up and used, then SPACE, then Q): Release 1's knight
; stayed in state 5 and did not move; Release 2's landed after eight passes and
; walked.
;
; HL The object's record
CHE3D:
  PUSH HL                 ; No sprite: nothing to do
  POP IX                  ;
  LD A,(IX+OBJ_SPRITE)    ;
  OR (IX+OBJ_SPRITE+$01)  ;
  RET Z                   ;
  LD A,(IX+OBJ_KIND)      ; A door: dealt with where it is met
  AND $0F                 ;
  CP $01                  ;
  RET Z                   ;
  LD A,(IX+OBJ_WEIGHT)    ; Taken out of the room, or scenery
  BIT 5,A                 ;
  RET NZ                  ;
  AND $1F                 ;
  RET Z                   ;
  LD DE,POINT             ; The record's first 19 bytes to IY+$64 on, its
  LD (WORK_RECORD),HL     ; address to IY+$7D
  LD BC,$0013             ;
  LDIR                    ;
  LD A,(WORK_BEHAVIOUR)   ; The state byte as the pass found it, over the
  LD (SECOND_POINT_ROW),A ; height's copy
  BIT 2,(IY+GAME_FLAGS-V) ; The first pass in a new room: only draw it
  JP NZ,SKIP_GRAVITY      ;
  BIT 7,A                 ; Carried along: on in the direction in +$12
  JR Z,I0                 ;
  LD A,(IX+OBJ_COURSE)    ;
  JP ADD_GRAVITY          ;
I0:
  LD C,(IY+WORK_DIRECTION-V)  ; I0: C its last movement (+$0D), HL its sprite;
  LD HL,(WORK_SPRITE)         ; bit 4 cleared in the copy of +$0E; state 0?
  RES 4,(IY+WORK_BEHAVIOUR-V) ;
  LD E,A                      ;
  AND $0F                     ;
  JR NZ,I3                    ;
I00:
  BIT 0,(IY+THINGS_NOTED-V) ; I00: the first kind-8 thing, kept while none is
  JR NZ,I01                 ;
  LD A,(WORK_KIND)          ;
  AND $0F                   ;
  CP $08                    ;
  JR NZ,I01                 ;
  SET 0,(IY+THINGS_NOTED-V) ;
  LD (DECOY),IX             ;
  JR I02                    ;
I01:
  CP $0B                    ; I01: a kind-11 thing. Once a kind-8 thing is
  JR NZ,I02                 ; known this compares the state instead of the
  SET 1,(IY+THINGS_NOTED-V) ; kind, so a kind-11 thing met later goes
                            ; unnoticed, and a frozen creature in state 11
                            ; counts as one
I02:
  LD A,C                  ; I02: with bit 4, its last movement once more;
  BIT 4,E                 ; otherwise only bit 0 of it, and the movement code
  JP NZ,ADD_GRAVITY       ; adds the fall
  AND $01                 ;
  JP ADD_GRAVITY          ;
I3:
  BIT 7,(IY+GAME_FLAGS-V) ; I3: the freeze: the knight to his controls, his
  JR Z,I30                ; jump on, everything else as state 0
  CP $08                  ;
  JP Z,KNIGHT_UPDATE      ;
  CP $05                  ;
  JR NZ,I00               ;
I30:
  CP $03                  ; I30: state 3: its last movement, or $45 if it has
  JR NZ,I4                ; no direction
  LD A,C                  ;
  AND $CC                 ;
  JR NZ,I31               ;
  LD C,$45                ;
I31:
  JP MOVE_IN_DIRECTION    ; I31: move (KON6)
I4:
  CP $04                  ; I4: state 4: is the knight in its box moved 12
  JR NZ,I5                ; along +6?
  CALL WORKING_POSITION   ;
  CALL WORKING_SIZES      ;
  LD A,B                  ;
  SUB $0C                 ;
  LD B,A                  ;
  LD IX,KNIGHT            ;
  CALL BOX_OVERLAP        ;
  RET NC                  ;
  LD A,$03                ; Never run in the build's sessions: three from LIFE,
  CALL DECLIF             ; and its striking frames, 144 bytes each, without
  LD IX,(WORK_RECORD)     ; moving (ANIM)
  LD C,$00                ;
  LD HL,SPRITE5C84        ;
  LD DE,$0090             ;
  JP ANIM                 ;
I5:
  CP $05                  ; I5: state 5, the jump: when +$0F has counted down,
  JR NZ,I9                ; back to state 8, and only the fall
  DEC (IX+OBJ_COUNT)      ;
  JR NZ,I50               ;
  LD A,E                  ;
  AND $F0                 ;
  OR $08                  ;
  LD (WORK_BEHAVIOUR),A   ;
  LD C,$01                ;
  JP MOVE_IN_DIRECTION    ;
I50:
  LD A,(WORK_HEADING)     ; I50: up (bit 4) without the fall (bit 1) along
  OR $12                  ; +$12, in the knight's poses (INP5, KNIGHT_CONTROLS)
  LD C,A                  ;
  JP KNIGHT_TURN          ;
I9:
  CP $09                  ; I9: other states go on
  JR NZ,CREATURE_UPDATE   ;
  LD A,(WORK_ANIMATION)   ; State 9: risen already (bit 6 of +$11)?
  BIT 6,A                 ;
  JR NZ,I91               ;
  INC A                   ; Rising: +$11 counts up; it stands still
  LD (IX+OBJ_FRAME),A     ;
  CP $40                  ;
  JR NC,I92               ;
  LD C,$01                ;
  LD HL,SPRITEA4B8        ; Its frame by the count: below $37, $3A, $3D and $40
  CP $37                  ;
  JR C,I95                ;
  LD HL,SPRITEA41C        ;
  CP $3A                  ;
  JR C,I95                ;
  LD HL,SPRITEA380        ;
  CP $3D                  ;
  JR C,I95                ;
  LD HL,SPRITEA2E4        ;
I95:
  JP SET_SPRITE_AND_MOVE  ; I95: into +4 and +5 (INPE)
I92:
  LD (IX+OBJ_FRAME),$51   ; I92: risen: +$11 to $51
I91:
  CALL STEER              ; I91: turn after the knight now and then (ZZ1), and
  JR GUARD_FRAMES         ; walk with state 6's sprites (I600)
; Continued at CREATURE_UPDATE.

; Keep a creature's course, or aim it at the knight when its count runs out
;
; Used by the routines at CHE3D and CREATURE_UPDATE.
;
; The author's ZZ1. The creatures that chase -- the guards (CREATURE_UPDATE,
; and state 9 in CHE3D), the wraith and the troll -- each keep a countdown at
; +15 of their record and their course at +18. Every pass takes one off the
; count; when it reaches nought ZOOMIN aims the creature at the knight (or, for
; a state-9 guard, at a lure lying in the room), sets the count again (10
; passes, or 3 when he is within 14 along y) and says how far away he is. So a
; creature changes its mind only every few passes.
;
;   IX The creature's record (the pass's working copy of it is at IY+$64)
;   E Its state (+14)
; O:C The direction to go in, with the low two bits cleared (the direction bits
;     are described at KNIGHT_CONTROLS)
; O:D How far the knight is, along the floor axis on which he is further, if
;     the course was set again this pass; nought if it was not
STEER:
  LD A,(WORK_HEADING)     ; The course it is on (+18, from the working copy)
  DEC (IX+OBJ_COUNT)      ; Count this pass off the record's +15; at nought,
  LD D,$00                ; take a new course (and distance) from ZOOMIN
  CALL Z,ZOOMIN           ;
  AND $FC                 ; Only the way to go, not the low bits: in C, and
  LD C,A                  ; kept at +18
  LD (IX+OBJ_COURSE),A    ;
  RET                     ;

; Update an object by its state: guards, the troll, the wraith, the floating
; things and the knight
;
; Used by the routine at CHE3D.
;
; The author's I6: the rest of the dispatch that CHE3D (CHE3D) begins, which
; tests the low nibble of the object's state (+14) in turn and comes here for
; state 6 and up. Each case chooses a direction in C and a sprite in HL, and
; leaves by one of three doors into the movement code: ANIM (in
; KNIGHT_CONTROLS), which picks a frame from a run of them, SET_SPRITE_AND_MOVE
; (ANIMATE_AND_MOVE), which shows HL as it is, or MOVE_IN_DIRECTION
; (ANIMATE_AND_MOVE), which leaves the sprite alone. From there the object is
; moved in direction C, collides, lands, and is redrawn.
;
; The states handled here, with the object types whose templates (TEMPLATES)
; start them in each: 6 and 10 (types 26 and 33): a guard. Within 30 of the
; knight along the floor it chases him (STEER); further off, a state-6 guard
; walks to and fro along x and a state-10 one along y, turning back at whatever
; stops it. Its frames depend on the way it walks: SPRITE9F3C, SPRITEA110,
; SPRITEA554 or SPRITEA728, three each. The guards of state 9 (type 27), which
; materialise first (CHE3D), use the same frames and always chase. 7 (type 13):
; the troll, which chases, turning its frames (SPRITE8BB8 facing the viewer,
; SPRITE8E64 facing away). 11 (type 45): a wraith, which chases and has one
; frame each way, SPRITE5E88 and SPRITE5F08. 12 (type 51): hangs in the air
; where it is and flickers through three small frames from SPRITE5B00. 13 (type
; 52): wanders, diagonally if it has no way of its own yet, and turns back off
; whatever it meets; frames from SPRITE5B30. 14 (type 40): hangs where it is
; and flickers through three frames from SPRITE6104. 15 (type 56, one in room
; 61): stands still until the thing of kind 11 lies in the room, when it takes
; the wraith's frames and state and chases the knight from then on (measured:
; it becomes state 11 for good). The door out of room 61 waits for the same
; thing (BUMPED). 8: the knight -- KNIGHT_UPDATE, below. Any other (1 or 2,
; which no object that is updated has): moves the way +13 says, with no sprite
; change.
;
; The knight (the author's I8, KNIGHT_UPDATE) comes here on every pass on which
; he is not in the air: in the air, CHE3D carries him on in the direction +18
; holds. First, if he has just landed from a long fall, it costs him LIFE:
; IY+$14 counts the passes he fell for, and each pass over 20 -- each two units
; over 40 -- takes a point (measured: a fall of 50 cost 5, of 60 cost 10, of 40
; nothing). Then the keys. Any key but the number keys goes to the action keys:
; X to V pick up (PICK_UP), CAPS SHIFT and Z drop, and the rest walk, jump and
; fight (KNIGHT_CONTROLS). With no key, the Kempston joystick (when 9 has
; turned it on) goes to KNIGHT_CONTROLS too. With neither, he stands: facing
; the viewer or away, with now and then a fidget of 14 passes (bit 3 of IY+$17)
; after a random wait of 128 to 255.
;
; The drop (Krumlinde's MainLoop_DropItemCheck, at the CAPS SHIFT row test)
; takes the thing in the place in use and puts it down just beside him on the
; side he faces: past his own width or depth when he faces the way the axis
; grows, past the thing's own when he faces back. Its top is set level with
; his, so it starts in the air. If the thing's box there meets anything
; (FIND_OBSTACLE), BLOCKED (message 1, IY+$07) and nothing changes. Otherwise
; the place is emptied, the thing moved there, its weight -- its +16 less 16,
; and never below nought -- taken off CARRIED_WEIGHT (IY+$12), its carried flag
; cleared, and it is given one pass going up (state bit 4 with +13 = $12) after
; which it falls to the floor like anything else. The object table is told it
; is in this room now (SET_THING_ROOM) and the panel's box for the place is
; emptied (CLEAR_THING_BOX). With 46 or more object records in use the drop key
; is ignored (not worked out why).
;
; A The state's low nibble
; E The whole state, +14
; C Its direction, +13 (KNIGHT_CONTROLS has the bits)
; HL Its sprite, +4 and +5
; IX Its record; the working copy of its +0 to +18 is at IY+$64 to IY+$76
CREATURE_UPDATE:
  CP $06                  ; States 6 and 10: a guard
  JR Z,GUARD_MOVES        ;
  CP $0A                  ;
  JR NZ,CREATURE_UPDATE_4 ;
GUARD_MOVES:
  CALL STEER              ; The author's I601. Keep course, or aim at the
                          ; knight (D is how far he is, when it aimed)
  LD A,D                  ; Not aimed this pass, or the knight within 30: go
  AND A                   ; the way STEER said
  JR Z,GUARD_FRAMES       ;
  CP $1E                  ;
  JR C,GUARD_FRAMES       ;
  LD (IX+OBJ_COUNT),$01   ; Far off: look again next pass
  LD A,E                  ; A state-6 guard walks along x
  AND $0F                 ;
  CP $06                  ;
  LD A,(WORK_DIRECTION)   ;
  JR Z,CREATURE_UPDATE_0  ;
  AND $C3                 ; State 10: keep its y direction (and the low bits);
  LD C,A                  ; with none, go up y ($40) and turn back when stopped
  AND $C0                 ; (bit 0)
  JR NZ,GUARD_FRAMES      ;
  LD C,$41                ;
  JR GUARD_FRAMES         ;
CREATURE_UPDATE_0:
  AND $0F                 ; State 6 (the author's I602): keep its x direction;
  LD C,A                  ; with none, go down x ($04) and turn back when
  JR NZ,GUARD_FRAMES      ; stopped
  LD C,$05                ;
; This entry point is used by the routine at CHE3D.
GUARD_FRAMES:
  LD HL,SPRITE9F3C        ; The author's I600, which the materialised guards of
                          ; state 9 use too (CHE3D). Frames by the way it goes:
                          ; down y, or standing, SPRITE9F3C
  BIT 3,C                 ; Up x: SPRITEA110 (the author's I60 is the next
  JR Z,CREATURE_UPDATE_1  ; test)
  LD HL,SPRITEA110        ;
CREATURE_UPDATE_1:
  BIT 2,C                 ; Down x: SPRITEA554 (I61 is the next)
  JR Z,CREATURE_UPDATE_2  ;
  LD HL,SPRITEA554        ;
CREATURE_UPDATE_2:
  BIT 6,C                 ; Up y: SPRITEA728 (a later test wins over an earlier
  JR Z,CREATURE_UPDATE_3  ; one)
  LD HL,SPRITEA728        ;
CREATURE_UPDATE_3:
  LD DE,$009C             ; The author's I62: frames of 24 by 26, 156 bytes
  JP ANIM                 ; apart; step through them
CREATURE_UPDATE_4:
  CP $0B                  ; The author's I11. State 11: a wraith
  JR NZ,CREATURE_UPDATE_6 ;
WRAITH_MOVES:
  CALL STEER              ; The author's I1110 (state 15 comes here too). Keep
                          ; course, or aim at the knight
  CALL MIWRAI             ; Turn its two frames (SPRITE5E88) to face the way it
                          ; goes; HL is the first
  BIT 6,E                 ; Facing away (bit 6 of the state clear): the second
  JR NZ,CREATURE_UPDATE_5 ; frame, 128 bytes on (SPRITE5F08)
  LD DE,$0080             ;
  ADD HL,DE               ;
CREATURE_UPDATE_5:
  JP SET_SPRITE_AND_MOVE  ; Show that frame (no animation) and move
CREATURE_UPDATE_6:
  CP $0C                  ; The author's I12. State 12: the small floating
  JR NZ,CREATURE_UPDATE_9 ; thing
  LD DE,$0010             ; Frames of 8 by 8, 16 bytes apart, from SPRITE5B00
  LD HL,SPRITE5B00        ;
CREATURE_UPDATE_7:
  LD C,$02                ; No way to go, and bit 1: it does not fall
CREATURE_UPDATE_8:
  SET 4,(IX+OBJ_FRAME)    ; Make sure the run is at least three frames (the
                          ; last frame, bits 3-5 of +17, at least 2)
  JP ANIM                 ; Step through the frames
CREATURE_UPDATE_9:
  CP $0D                   ; State 13
  JR NZ,CREATURE_UPDATE_11 ;
  LD A,C                   ; With no x or y direction of its own, go down x and
  AND $CC                  ; up y ($45), turning back when stopped
  JR NZ,CREATURE_UPDATE_10 ;
  LD C,$45                 ;
CREATURE_UPDATE_10:
  LD DE,$005C             ; Frames of 16 by 23 from SPRITE5B30
  LD HL,SPRITE5B30        ;
  JR CREATURE_UPDATE_8    ;
CREATURE_UPDATE_11:
  CP $0E                   ; State 14
  JR NZ,CREATURE_UPDATE_12 ;
  LD HL,SPRITE6104        ; Frames of 16 by 10 from SPRITE6104, hanging still
  LD DE,$0028             ;
  JR CREATURE_UPDATE_7    ;
CREATURE_UPDATE_12:
  CP $0F                   ; State 15
  JR NZ,CREATURE_UPDATE_13 ;
  XOR A                     ; Unless the thing of kind 11 lies in the room (bit
  BIT 1,(IY+THINGS_NOTED-V) ; 1 of IY+$11, set by CHE3D): stand quite still,
  JP Z,ANIMATE_AND_MOVE_3   ; not even falling. (This skips the clearing of C:
                            ; C still holds +13, which is nought for this
                            ; figure)
  LD E,$0B                ; Then be a wraith. The wraith's case writes the
  JR WRAITH_MOVES         ; state it is given, so it stays one (measured, by
                          ; putting the thing of kind 11 in room 61: the figure
                          ; took the wraith's frame and state 11 and came for
                          ; the knight)
CREATURE_UPDATE_13:
  CP $07                  ; State 7: the troll
  JR NZ,KNIGHT_UPDATE     ;
  RES 4,(IX+OBJ_KIND)     ; Clear bit 4 of its +12, which makes a touch cost
                          ; the knight 10 LIFE (OBJECTS_MEET): the troll's
                          ; object-table records have it set, so it lasts only
                          ; until the troll's first pass (the working copy
                          ; keeps it for that pass)
  CALL STEER              ; Keep course, or aim at the knight
  CALL MITRO              ; Turn its frames (SPRITE8BB8) to face the way it
                          ; goes
  BIT 6,E                  ; Facing away: the frames that start 684 bytes on
  JR NZ,CREATURE_UPDATE_14 ; (SPRITE8E64)
  LD DE,$02AC              ;
  ADD HL,DE                ;
CREATURE_UPDATE_14:
  LD DE,$00E4             ; Frames of 24 by 38, 228 bytes apart
  JP ANIM                 ;
; This entry point is used by the routine at CHE3D.
KNIGHT_UPDATE:
  CP $08                  ; The author's I8. Any state not handled above just
  JP NZ,MOVE_IN_DIRECTION ; moves the way +13 says
  LD A,(IY+FALL_COUNT-V)  ; State 8, the knight, on the ground. A fall of more
  SUB $14                 ; than 20 passes (IY+$14, counted by
  CALL NC,DECLIF          ; ANIMATE_AND_MOVE) costs a LIFE point a pass over
  LD (IY+FALL_COUNT-V),$00 ; Start the count again
  LD C,$01                ; Standing: no way to go (bit 0 alone)
  LD A,$18                ; Any key but 1-5 and 6-0: the action and movement
  CALL INPUT              ; keys
  JR NZ,PICK_OR_DROP      ;
  CALL IN31               ; No key: the Kempston joystick, if it is on (IN31)
  JP NZ,STICK_DIRECTION   ;
  LD C,(IX+OBJ_DIRECTION) ; Nothing pressed. C = the way he was going, which
                          ; matters only if he stands on something that moves
  LD A,(WORK_ANIMATION)   ; Back to the first frame of a run (+17's bits 0-2)
  AND $F8                 ;
  LD (IX+OBJ_FRAME),A     ;
  DEC (IX+OBJ_COURSE)      ; Count down to a change of stance (+18)
  JR NZ,CREATURE_UPDATE_15 ;
  LD A,(GAME_FLAGS)       ; Start or end a fidget (bit 3 of IY+$17)
  XOR $08                 ;
  LD (GAME_FLAGS),A       ;
  BIT 3,A                  ; A fidget lasts 14 passes...
  LD (IX+OBJ_COURSE),$0E   ;
  JR NZ,CREATURE_UPDATE_15 ;
  LD A,R                  ; ...and the stillness between them 128 to 255, at
  OR $80                  ; random
  LD (IX+OBJ_COURSE),A    ;
CREATURE_UPDATE_15:
  RES 1,(IY+GAME_FLAGS-V) ; His sword is not out
  BIT 4,E                  ; Riding on something that moves (state bit 4): keep
  JR NZ,CREATURE_UPDATE_18 ; his sprite and go with it
  BIT 6,E                 ; Facing the viewer: SPRITE91CA, or SPRITE99C8 in a
  JR Z,CREATURE_UPDATE_16 ; fidget
  LD HL,SPRITE91CA        ;
  BIT 3,(IY+GAME_FLAGS-V) ;
  JR Z,CREATURE_UPDATE_17 ;
  LD HL,SPRITE99C8        ;
  JP CREATURE_UPDATE_17   ;
CREATURE_UPDATE_16:
  LD HL,SPRITE93F8        ; Facing away: SPRITE93F8, or SPRITE9A82 in a fidget
  BIT 3,(IY+GAME_FLAGS-V) ;
  JP Z,CREATURE_UPDATE_17 ;
  LD HL,SPRITE9A82        ;
CREATURE_UPDATE_17:
  LD C,$01                ; Stand still
CREATURE_UPDATE_18:
  JP SET_SPRITE_AND_MOVE  ; Show the frame, and move (or not)
PICK_OR_DROP:
  LD A,$FE                ; Krumlinde's MainLoop_DropItemCheck. A key is down,
  RES 3,(IY+GAME_FLAGS-V) ; so no fidget
  CALL INPUT              ; Nothing on the CAPS SHIFT to V row: walk, jump or
  JP Z,KNIGHT_CONTROLS    ; fight (KNIGHT_CONTROLS)
  AND $1C                 ; X, C or V: pick up (PICK_UP)
  JP NZ,PICK_UP           ;
DROP_THING:
  LD A,(IY+OBJECT_COUNT-V) ; CAPS SHIFT or Z: drop. Not with 46 records or more
  CP $2E                   ; in use: then read the walking keys instead
  JP NC,WALK_KEYS          ;
  LD H,$FF                ; The place in use (SELECTED, IY+$1E) is empty:
  LD L,(IY+SELECTED-V)    ; nothing to drop; just redraw him
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  LD A,E                  ;
  OR D                    ;
  JP Z,REDRAW_THIS_OBJECT ;
  DEC HL                  ; Keep the place's address; IX = the thing; B, D, H =
  PUSH HL                 ; where he is
  PUSH DE                 ;
  POP IX                  ;
  CALL WORKING_POSITION   ;
  LD E,(IY+WORK_BEHAVIOUR-V) ; Which way he faces: bits 5 and 6 of his state
  BIT 5,E                    ;
  JR NZ,CREATURE_UPDATE_20   ;
  BIT 6,E                    ;
  JR NZ,CREATURE_UPDATE_19   ;
  LD A,B                   ; Up x (neither bit): put it past his width
  ADD A,(IY+REPEATS+$01-V) ;
  LD B,A                   ;
  JR DROP_TEST             ;
CREATURE_UPDATE_19:
  LD A,H                  ; Down y (bit 6): its own depth short of him
  SUB (IX+OBJ_LEN_Z)      ;
  LD H,A                  ;
  JR DROP_TEST            ;
CREATURE_UPDATE_20:
  BIT 6,E                 ; Down x (both bits): its own width short of him
  JR Z,CREATURE_UPDATE_21 ;
  LD A,B                  ;
  SUB (IX+OBJ_LEN_X)      ;
  LD B,A                  ;
  JR DROP_TEST            ;
CREATURE_UPDATE_21:
  LD A,H                       ; Up y (bit 5): past his depth
  ADD A,(IY+REPEAT_FROM+$01-V) ;
  LD H,A                       ;
DROP_TEST:
  LD C,(IX+OBJ_LEN_X)     ; Krumlinde's DropItem_TestPlacement. Would the
  LD E,(IX+OBJ_HEIGHT)    ; thing's own box there meet anything? (It is still
  LD L,(IX+OBJ_LEN_Z)     ; marked as carried, so it does not meet itself)
  PUSH IX                 ;
  CALL FIND_OBSTACLE      ;
  EXX                     ; Keep the place's address in the other register set
  POP IX                  ;
  POP HL                  ;
  EXX                     ;
  JR NC,DROP_COMMIT       ; Something is there: BLOCKED
  LD (IY+MESSAGE-V),$01   ;
  JR KNIGHT_DONE          ;
DROP_COMMIT:
  EXX                     ; Krumlinde's DropItem_Commit. Empty the place
  XOR A                   ;
  LD (HL),A               ;
  INC HL                  ;
  LD (HL),A               ;
  EXX                     ;
  CALL ISO_MOVE           ; Move the thing to the spot (its top level with his,
                          ; so it starts in the air)
  LD A,(IX+OBJ_WEIGHT)     ; Its weight: +16 less 16, and nought if that is
  AND $1F                  ; below it
  SUB $10                  ;
  JR NC,CREATURE_UPDATE_22 ;
  XOR A                    ;
CREATURE_UPDATE_22:
  LD L,A                   ;
  LD A,(CARRIED_WEIGHT)   ; Off what he carries (CARRIED_WEIGHT, IY+$12)
  SUB L                   ;
  LD (CARRIED_WEIGHT),A   ;
  RES 5,(IX+OBJ_WEIGHT)   ; No longer carried
  SET 4,(IX+OBJ_STATE)      ; For one pass it goes where +13 says: up, and not
  LD (IX+OBJ_DIRECTION),$12 ; falling (bits 4 and 1); then it falls
  LD C,(IY+ROOM-V)        ; The object table: it is in this room now
  CALL SET_THING_ROOM     ;
  CALL CLEAR_THING_BOX    ; Empty the panel's box for the place
; This entry point is used by the routines at PICK_UP and PICK_UP_LOOK_ON.
KNIGHT_DONE:
  JP REDRAW_THIS_OBJECT   ; The author's DOE: the way out of the knight's
                          ; actions. Redraw him, and the pass is over for him

; Write a thing's room into the object table
;
; Used by the routines at CREATURE_UPDATE, PICK_UP_LOOK_ON, OBJECTS_MEET and
; MEET_DECOY.
;
; The author's ROMM. A thing's number (+19 of its record, counted from 1,
; PLACE_ROOM_OBJECTS) is its place in the object table (OBJECTS), and the first
; 163 records of that table are all six bytes long, so the number times six,
; from six bytes before the table, reaches the room byte of the thing's own
; record. Dropping writes the room it is dropped in; picking up and the things
; that vanish (OBJECTS_MEET) write $FE, which no room is, so the thing is
; placed nowhere until it is dropped again. (A thing's place in the room is
; saved separately, by SAVE_OBJECT_POSITIONS, when the knight leaves.)
;
; Only the first 163 records of the table can be reached this way, and they are
; the things that can move between rooms. A record with no number (+19 nought)
; runs the loop 256 times and reaches 1536 bytes past the start, among the
; eleven-byte records -- and that happens: room 19's drawing places two things
; of its own (not from the object table, so with no number) that can be picked
; up, and picking one up writes $FE into the x of the object table's record
; 214, the door from room 25 to room 21. Measured: after that the door is at x
; 254 and room 25 cannot be left that way. (Dropping the thing would write 19
; there instead.)
;
; IX The thing's record
; C The room, or $FE for none
SET_THING_ROOM:
  LD B,(IX+OBJ_NUMBER)    ; HL = six bytes before the object table, plus six
  LD HL,$A91E             ; for each step of the thing's number
  LD DE,$0006             ;
SET_THING_ROOM_0:
  ADD HL,DE               ;
  DJNZ SET_THING_ROOM_0   ;
  LD (HL),C               ; The room
  RET                     ;

; Pick up whatever the knight is standing at
;
; Used by the routine at CREATURE_UPDATE.
;
; X, C or V (CREATURE_UPDATE). Only into an empty place: if the place in use (1
; to 5, SELECTED) holds something, nothing happens. Otherwise he stoops
; (SPRITE956C facing the viewer, SPRITE9626 facing away) and the game looks for
; things in a box the size of his own, four units on the way he faces (measured
; facing up x, with a thing 8 wide: it was found with its corner anywhere from
; 2 behind his to 10 ahead). FIND_OBSTACLE finds the first record whose box
; meets it; PICK_UP_LOOK_ON goes on through the rest until one can be carried.
PICK_UP:
  LD H,$FF                ; The place in use already holds something: do
  LD L,(IY+SELECTED-V)    ; nothing but redraw him
  LD A,(HL)               ;
  INC HL                  ;
  OR (HL)                 ;
  JR NZ,KNIGHT_DONE       ;
  LD HL,$00BA             ; The stooping frames: SPRITE956C, and 186 bytes on
  LD (AWAY_FRAMES),HL     ; (SPRITE9626) facing away
  LD HL,SPRITE956C        ;
  CALL FACING                ; Choose by which way he faces; C = that way; it
  LD (IY+WORK_DIRECTION-V),C ; becomes his sprite
  LD (KNIGHT_SPRITE),HL      ;
  CALL WORKING_POSITION   ; B, D, H = where he is
  LD A,C                  ; Move along x (bit 0), or along y (bit 2) if he
  LD C,$01                ; faces along y
  AND $C0                 ;
  JR Z,PICK_UP_0          ;
  LD C,$04                ;
PICK_UP_0:
  CALL STEP_ALL_AXES      ; Two steps of two: four units on
  CALL STEP_ALL_AXES      ;
  CALL WORKING_SIZES      ; His sizes; what does a box there meet?
  CALL FIND_OBSTACLE      ;
  JR PICK_UP_LOOK_ON_0    ;

; Look on for a thing that can be carried, and take it
;
; The pick-up's search, from where FIND_OBSTACLE (or this, going round) left
; it. Each record whose box meets the search box is tested: it must be a thing
; that can be picked up (bit 5 of +12). A door ends the search (though no door
; has bit 5 set: a door's +12 is exactly 1). Then the weight: the thing's +16
; less 16 (never below nought) is added to what he carries (CARRIED_WEIGHT,
; IY+$12), and if that comes to 8 or more it is TOO HEAVY (message 3) and
; nothing changes. So the load is at most 7; the heaviest things weigh 6.
;
; Taking it: the place in use gets the record's address, the record is marked
; as carried (bit 5 of +16) and not in the air, and the object table says it is
; in no room ($FE, SET_THING_ROOM). The knight is redrawn stooping; then the
; thing's picture is wiped from the room, by redrawing its area (REDRAW_OBJECT)
; with THIS_RECORD pointing at it so that it is left out, and drawn in the
; panel's box for the place (SHOW_THING_IN_USE). Krumlinde names the part from
; the weight on RTN_Store_Carried_Weight.
;
; The flags in IY+$11 are cleared: they say whether the lure and the thing of
; kind 11 lie in the room, and whichever still does sets its flag again on the
; next pass (CHE3D).
PICK_UP_LOOK_ON:
  CALL NEXT_OBSTACLE      ; Look on from the last record met
; This entry point is used by the routine at PICK_UP.
PICK_UP_LOOK_ON_0:
  JR NC,KNIGHT_DONE       ; Nothing more: the pick-up ends with a redraw
  BIT 5,(IX+OBJ_KIND)     ; Not a thing that can be carried: look on
  JR Z,PICK_UP_LOOK_ON    ;
  LD A,(IX+OBJ_KIND)      ; A door: stop
  AND $0F                 ;
  CP $01                  ;
  JR Z,KNIGHT_DONE        ;
  LD A,(IX+OBJ_WEIGHT)    ; Its weight: +16 less 16, nought if below
  AND $1F                 ;
  SUB $10                 ;
  JR NC,PICK_UP_LOOK_ON_1 ;
  XOR A                   ;
PICK_UP_LOOK_ON_1:
  ADD A,(IY+CARRIED_WEIGHT-V) ; Added to his load, 8 or more is TOO HEAVY
  CP $08                      ;
  JR C,TAKE_THING             ;
  LD (IY+MESSAGE-V),$03       ;
  JR KNIGHT_DONE              ;
TAKE_THING:
  LD (CARRIED_WEIGHT),A   ; The author's WEI3. The new load
  PUSH IX                 ; The place in use holds the thing now
  POP DE                  ;
  LD H,$FF                ;
  LD L,(IY+SELECTED-V)    ;
  LD (HL),E               ;
  INC HL                  ;
  LD (HL),D               ;
  SET 5,(IX+OBJ_WEIGHT)   ; Carried, and not in the air
  RES 7,(IX+OBJ_STATE)    ;
  RES 1,(IY+THINGS_NOTED-V) ; The thing of kind 11 may not lie in the room any
                            ; more
  LD C,$FE                ; In no room
  CALL SET_THING_ROOM     ;
  PUSH IX                 ; Redraw the knight, stooping
  CALL KNIGHT_DONE        ;
  POP HL                  ; THIS_RECORD = IY+$78, meant as the thing's number
  LD A,(THIS_RECORD)      ; among the records so that its own redraw leaves it
  PUSH AF                 ; out; but the knight's redraw has already used that
  LD A,(FOUND_RECORD)     ; byte for a sprite's width (3 when measured, the
  LD (THIS_RECORD),A      ; thing being 9), so a fixed record is left out
                          ; instead
  PUSH HL                 ; Redraw where it was: without it
  CALL REDRAW_OBJECT      ;
  POP HL                  ; Draw it in the panel's box
  CALL SHOW_THING_IN_USE  ;
  POP AF                  ; THIS_RECORD back to the knight's
  LD (THIS_RECORD),A      ;
  LD (IY+THINGS_NOTED-V),$00 ; Both room flags cleared (see above)
  RET                     ; The knight's pass is over

; The knight's controls: walk, jump or fight, and the frames they show
;
; Used by the routine at CREATURE_UPDATE.
;
; Reached from KNIGHT_UPDATE (CREATURE_UPDATE) when a key other than the action
; keys is down, or the joystick has moved. The way to go comes from the
; joystick if it is on and moved, otherwise from the keyboard. A later test
; wins, so there is no diagonal walking: on the keyboard Q-T beats A-G beats
; H-ENTER beats Y-P, and on the joystick up beats down beats left beats right.
;
; A direction is a byte with one bit for each way, the same for every object
; (+13, +18, IY+$71, IY+$7C): bit 0 -- turn back when stopped (MEET_DECOY
; reverses the way rather than ending it); bit 1 -- rising: do not fall this
; pass; bit 2 -- down x; bit 3 -- up x (Y-P, joystick right); bit 4 -- up; bit
; 5 -- down (gravity); bit 6 -- up y (Q-T, joystick up); bit 7 -- down y. On
; the screen, going up x moves up and to the right, and going up y moves up and
; to the left. A step is two units along one axis, or one along each of x and y
; for a diagonal; up or down is always two.
;
; The author's I88, with the author's own labels from the source text left at
; SOURCE_AND_STACK for most of its tests. INP5 then turns the knight to face
; the way he goes (MIMAN mirrors all his frames, and sets bits 5 and 6 of his
; state: FACING has which is which). Mid-jump (state 5, from CHE3D) he just
; walks on. Otherwise SPACE or SYMBOL SHIFT jumps: up for 8 passes of two
; units, going the way he walked, then down (measured: from 78 to 94 and back).
; His state becomes 5 for the rise, keeping the facing bits; CHE3D counts the
; rise off and makes him 8 again, and he falls as anything does. B, N or M, or
; the joystick's fire, fights: the sword is out (bit 1 of IY+$17, which is what
; hurts a creature he meets, OBJECTS_MEET) for three passes, standing, and then
; away for three while he steps forward, the two frames facing the viewer or
; away (SPRITE96E0 and SPRITE979A, SPRITE9854 and SPRITE990E). Otherwise he
; walks, through three frames of his walk (SPRITE9110 facing the viewer,
; SPRITE933E away).
;
; The author's ANIM, at the end, picks a frame from a run of them. +17 holds
; the frame (bits 0-2), the last frame of the run (bits 3-5) and bit 7 while
; going back. HL is the first frame and DE the size of one; the frame shown is
; HL + DE times the frame. The run goes forward to the last and then back, but
; it goes back by jumping to frame 1: measured, a run of three goes 0, 1, 2, 1,
; 0, 1, 2 ..., but one of four goes 0, 1, 2, 3, 1, 0 and one of two 0, 1, 1, 0.
; Every run the game uses is three frames. The rest of it is at
; ANIMATE_AND_MOVE.
;
; E The knight's state, +14
; C The way to go by default (1: standing)
; IX His record
KNIGHT_CONTROLS:
  CALL IN31               ; The author's I88. The joystick, if it is on;
  JR Z,WALK_KEYS          ; otherwise the keyboard
; This entry point is used by the routine at CREATURE_UPDATE.
STICK_DIRECTION:
  RRA                     ; The author's I89 (the source's I82 to I85 are the
  JR NC,KNIGHT_CONTROLS_0 ; next four tests). Right: up x
  LD C,$08                ;
KNIGHT_CONTROLS_0:
  RRA                     ; Left: down x
  JR NC,KNIGHT_CONTROLS_1 ;
  LD C,$04                ;
KNIGHT_CONTROLS_1:
  RRA                     ; Down: down y
  JR NC,KNIGHT_CONTROLS_2 ;
  LD C,$80                ;
KNIGHT_CONTROLS_2:
  RRA                     ; Up: up y
  JR NC,KNIGHT_CONTROLS_3 ;
  LD C,$40                ;
KNIGHT_CONTROLS_3:
  RRA                     ; Fire: fight, at once
  JR C,KNIGHT_FIGHT       ;
  JR KNIGHT_TURN          ; Walk
; This entry point is used by the routine at CREATURE_UPDATE.
WALK_KEYS:
  LD A,$DF                ; The author's I80 (INP2 to INP4 are the next three
  CALL INPUT              ; tests). Y-P: up x
  JR Z,KNIGHT_CONTROLS_4  ;
  LD C,$08                ;
KNIGHT_CONTROLS_4:
  LD A,$BF                ; H-ENTER: down x
  CALL INPUT              ;
  JR Z,KNIGHT_CONTROLS_5  ;
  LD C,$04                ;
KNIGHT_CONTROLS_5:
  LD A,$FD                ; A-G: down y
  CALL INPUT              ;
  JR Z,KNIGHT_CONTROLS_6  ;
  LD C,$80                ;
KNIGHT_CONTROLS_6:
  LD A,$FB                ; Q-T: up y
  CALL INPUT              ;
  JR Z,KNIGHT_TURN        ;
  LD C,$40                ;
; This entry point is used by the routine at CHE3D.
KNIGHT_TURN:
  CALL MIMAN              ; The author's INP5 (CHE3D comes here mid-jump). Turn
                          ; his frames to face the way he goes; HL = his
                          ; walking frames facing the viewer (SPRITE9110)
  LD A,E                  ; Facing away: the walk at SPRITE933E
  BIT 6,E                 ;
  JR NZ,KNIGHT_CONTROLS_7 ;
  LD HL,SPRITE933E        ;
KNIGHT_CONTROLS_7:
  AND $0F                 ; Mid-jump (state 5): just walk on through the air
  CP $05                  ;
  JR Z,KNIGHT_CONTROLS_10 ;
  LD A,$7F                ; None of SPACE, SYMBOL SHIFT, M, N and B: walk
  CALL INPUT              ;
  JR Z,KNIGHT_CONTROLS_10 ;
  AND $03                 ; SPACE or SYMBOL SHIFT: jump
  JR NZ,KNIGHT_JUMP       ;
KNIGHT_FIGHT:
  LD HL,$0174             ; The author's INP59. B, N or M, or fire: fight. The
  LD (AWAY_FRAMES),HL     ; frames SPRITE96E0 facing the viewer, and 372 bytes
  LD HL,SPRITE96E0        ; on (SPRITE9854) facing away; C = the way he faces
  CALL FACING             ;
  BIT 1,(IY+GAME_FLAGS-V) ; Is his sword out?
  JR NZ,KNIGHT_CONTROLS_8 ;
  DEC (IX+OBJ_COUNT)      ; Not yet: the step forward, until +15 runs out
  JR NZ,KNIGHT_CONTROLS_9 ;
  SET 1,(IY+GAME_FLAGS-V) ; Out with the sword, for three passes (this pass
  LD (IX+OBJ_COUNT),$03   ; still steps)
  JR SET_SPRITE_AND_MOVE  ;
KNIGHT_CONTROLS_8:
  LD C,$00                ; Sword out: stand
  DEC (IX+OBJ_COUNT)        ; For three passes
  JR NZ,SET_SPRITE_AND_MOVE ;
  LD (IX+OBJ_COUNT),$03   ; Then away with it, three passes more
  RES 1,(IY+GAME_FLAGS-V) ;
KNIGHT_CONTROLS_9:
  LD DE,$00BA             ; The stepping frame, one on from the other
  ADD HL,DE               ;
  JR SET_SPRITE_AND_MOVE  ;
KNIGHT_JUMP:
  SET 4,C                 ; Jump: up, and not falling, as well as the way he
  SET 1,C                 ; walks
  LD (IX+OBJ_COUNT),$08   ; For 8 passes (+15), going this way (+18)
  LD (IX+OBJ_COURSE),C    ;
  LD A,E                     ; State 5, rising, with his facing kept; show the
  AND $70                    ; first frame of the walk
  OR $05                     ;
  LD (IY+WORK_BEHAVIOUR-V),A ;
  JR SET_SPRITE_AND_MOVE     ;
KNIGHT_CONTROLS_10:
  LD DE,$00BA             ; Walk: frames 186 bytes apart; the sword is not out
  RES 1,(IY+GAME_FLAGS-V) ;
; This entry point is used by the routines at CHE3D and CREATURE_UPDATE.
ANIM:
  PUSH BC                 ; The author's ANIM. Keep the way to go
  LD A,(IX+OBJ_FRAME)     ; C = +17; B = the frame, plus one
  LD C,A                  ;
  AND $07                 ;
  INC A                   ;
  LD B,A                  ;
  BIT 7,C                 ; Going forward: the next frame is this one plus one
  JR Z,ANIMATE_AND_MOVE_0 ;
  SUB $02                  ; Going back: this one less one...
  JR NC,ANIMATE_AND_MOVE_0 ;
  LD A,$01                ; ...and at nought, the frame before is 1, going
  RES 7,C                 ; forward again
  JR ANIMATE_AND_MOVE_0   ;

; Show the frame, then move the object and redraw it
;
; The rest of the author's ANIM (KNIGHT_CONTROLS), and then the common end of
; every object's update: INPE sets the sprite, KON6 takes the direction, NOPROP
; adds gravity, NOG makes the direction into the three axes of the step, and
; the step is tried against every other record (FIND_OBSTACLE). If something is
; in the way, BUMPED deals with it: a door may take the knight to another room,
; anything else is met (OBJECTS_MEET) and the step tried again axis by axis
; (MEET_DECOY), which comes back to TRY_STEP here. When the step is clear the
; record gets the new state and place (ISO_MOVE), and the object is redrawn
; (REDRAW_OBJECT).
;
; Gravity: unless the direction has bit 1 (rising), the up bit is cleared (by
; the constant $EF in IY+$0B) and down added (from the constant in IY+$05), so
; everything falls two units a pass until it is stopped. A fall sets bit 7 of
; the state, in the air, and while that is set CHE3D does not run the object's
; own case but keeps it going the way +18 says. A fall keeps only the down bit
; (and the low two), so everything falls straight down, the knight at the end
; of a jump too (measured). The air ends when the fall is stopped, or when the
; count in +15 runs out (it is 1 while falling, 3 for a bounce), and if it was
; in the air at the start of the pass and did not move at all, the object is
; updated again at once (CHE3D) as a thing on the ground. Bit 6 of IY+$7B,
; which MEET_DECOY sets when the step was stopped by an object of kind 2 or 3,
; makes it bounce: three passes going up.
;
; The knight's screen position is worked out afresh on each pass: his record is
; first put back to one fixed point on the floor (50, 78, 50) and its place on
; the screen, and ISO_MOVE moves him from there. Everything else is moved from
; where it was.
;
; On the first pass in a room (bit 2 of IY+$17, which the room's entry sets and
; MAIN_LOOP clears) nothing moves: the direction is cleared, but all three axis
; bits are set, so the test runs on a box one unit up x, two down and one down
; y from where the object is, and whatever that meets is dealt with as usual
; (BUMPED); then the record is only drawn. What the offset box is for is not
; worked out.
;
; HL The first frame of the run
; DE The size of one frame
; B The frame, plus one
; A The next frame
; C The object's +17
ANIMATE_AND_MOVE:
  ADD HL,DE               ; HL = the frame to show
; This entry point is used by the routine at KNIGHT_CONTROLS.
ANIMATE_AND_MOVE_0:
  DJNZ ANIMATE_AND_MOVE   ; }
  LD B,A                  ; The last frame of the run
  LD A,C                  ;
  RRA                     ;
  RRA                     ;
  RRA                     ;
  AND $07                 ;
  CP B                     ; Past it: go back, and next time show frame 1
  LD A,C                   ;
  JR NC,ANIMATE_AND_MOVE_1 ;
  AND $F8                  ;
  OR $81                   ;
  JR ANIMATE_AND_MOVE_2    ;
ANIMATE_AND_MOVE_1:
  AND $F8                 ; Otherwise the next frame
  OR B                    ;
ANIMATE_AND_MOVE_2:
  LD (IX+OBJ_FRAME),A     ;
  POP BC                  ; The way to go
; This entry point is used by the routines at CHE3D, CREATURE_UPDATE and
; KNIGHT_CONTROLS.
SET_SPRITE_AND_MOVE:
  LD (IX+OBJ_SPRITE),L     ; The author's INPE: the sprite is HL
  LD (IX+OBJ_SPRITE+$01),H ;
; This entry point is used by the routines at CHE3D and CREATURE_UPDATE.
MOVE_IN_DIRECTION:
  LD A,C                  ; The author's KON6: the way to go is C
; This entry point is used by the routine at CHE3D.
ADD_GRAVITY:
  BIT 1,A                 ; The author's NOPROP. Rising (bit 1): no gravity
  JR NZ,SKIP_GRAVITY      ; this pass
  AND (IY+NO_RISE_MASK-V) ; Otherwise no up (IY+$0B holds $EF), and down
  LD C,A                  ; (IY+$05 holds $23; its low two bits are not used)
  LD A,(GRAVITY)          ;
  AND $FC                 ;
  OR C                    ;
; This entry point is used by the routine at CHE3D.
SKIP_GRAVITY:
  LD C,$00                ; The author's NOG. C will be the axes of the step
  BIT 2,(IY+GAME_FLAGS-V) ;
  JR Z,ANIMATE_AND_MOVE_3 ;
  XOR A                   ; The first pass in a room: no way to go, but a test
  LD C,$07                ; on all three axes
; This entry point is used by the routine at CREATURE_UPDATE.
ANIMATE_AND_MOVE_3:
  LD (WORK_DIRECTION),A   ; The way to go this pass: IY+$71 (which MEET_DECOY
  LD (ASKED_DIRECTION),A  ; may change) and IY+$7C (which it does not)
  LD B,A                  ; Down or up x: an x step (bit 0 of IY+$7B)
  AND $0C                 ;
  JR Z,ANIMATE_AND_MOVE_4 ;
  SET 0,C                 ;
ANIMATE_AND_MOVE_4:
  LD A,B                  ; Up or down: a step in height (bit 1)
  AND $30                 ;
  JR Z,ANIMATE_AND_MOVE_5 ;
  SET 1,C                 ;
ANIMATE_AND_MOVE_5:
  LD A,B                  ; Up or down y: a y step (bit 2)
  AND $C0                 ;
  JR Z,ANIMATE_AND_MOVE_6 ;
  SET 2,C                 ;
ANIMATE_AND_MOVE_6:
  LD (IY+STEP_AXES-V),C   ; IY+$7B = the axes of the step
; This entry point is used by the routine at MEET_DECOY.
TRY_STEP:
  RES 7,(IY+STEP_AXES-V)  ; MEET_DECOY comes back here: no door met yet (bit 7
                          ; of IY+$7B)
  LD C,(IY+STEP_AXES-V)   ; B, D, H = where it would be after the step
  CALL WORKING_POSITION   ;
  CALL STEP_ALL_AXES      ;
  LD A,(STEP_AXES)        ; Not moving: nothing to test
  AND $07                 ;
  JR Z,COMMIT_STEP        ;
  CALL WORKING_SIZES      ; With its sizes, does it meet anything? If so, see
  CALL FIND_OBSTACLE      ; what (IX is what it met)
  JP C,BUMPED             ;
; This entry point is used by the routines at OBJECTS_MEET and MOVER_VANISHES.
COMMIT_STEP:
  LD IX,(WORK_RECORD)     ; The step is clear. The record gets the state from
  LD A,(WORK_BEHAVIOUR)   ; the working copy
  LD (IX+OBJ_STATE),A     ;
  BIT 2,(IY+GAME_FLAGS-V)  ; The first pass in a room: just draw it
  JP NZ,REDRAW_THIS_OBJECT ;
  AND $0F                  ; The knight?
  CP $08                   ;
  JR NZ,ANIMATE_AND_MOVE_7 ;
  LD (IX+OBJ_SCREEN_X),$74 ; Put his record back to the fixed point, so that
  LD (IX+OBJ_SCREEN_Y),$22 ; his screen place comes out afresh
  LD (IX+OBJ_X),$32        ;
  LD (IX+OBJ_TOP),$4E      ;
  LD (IX+OBJ_Z),$32        ;
ANIMATE_AND_MOVE_7:
  CALL ISO_MOVE           ; Move it: the new place, and the screen position
                          ; from it
  LD E,(IX+OBJ_STATE)        ; E = the state; D = the way it went (after any
  LD D,(IY+WORK_DIRECTION-V) ; change by MEET_DECOY)
  BIT 7,E                  ; On the ground, that becomes its way (+13)
  JR NZ,ANIMATE_AND_MOVE_8 ;
  LD (IX+OBJ_DIRECTION),D  ;
ANIMATE_AND_MOVE_8:
  BIT 4,E                 ; Riding on something that moves (state bit 4): take
  JR Z,ANIMATE_AND_MOVE_9 ; its way (IY+RIDE_DIRECTION-V), keeping the low bits
  LD A,D                  ;
  AND $03                 ;
  LD C,A                  ;
  LD A,(RIDE_DIRECTION)   ;
  AND $FC                 ;
  OR C                    ;
  LD (IX+OBJ_DIRECTION),A ;
ANIMATE_AND_MOVE_9:
  BIT 1,(IY+STEP_AXES-V)   ; Moved in height, going down: falling
  JR Z,ANIMATE_AND_MOVE_10 ;
  BIT 5,D                  ;
  JR Z,ANIMATE_AND_MOVE_10 ;
  LD (IX+OBJ_COUNT),$01   ; In the air; keep going down (with the low bits)
  LD A,D                  ;
  AND $23                 ;
  SET 7,E                 ;
  LD B,A                    ; The knight counts the passes he falls for
  LD A,(THIS_RECORD)        ; (IY+FALL_COUNT-V)
  CP $07                    ;
  LD A,B                    ;
  JR NZ,ANIMATE_AND_MOVE_12 ;
  INC (IY+FALL_COUNT-V)     ;
  JR ANIMATE_AND_MOVE_12    ;
ANIMATE_AND_MOVE_10:
  BIT 6,(IY+STEP_AXES-V)   ; Stopped by an object of kind 2 or 3 (bit 6 of
  JR Z,ANIMATE_AND_MOVE_11 ; IY+$7B, from MEET_DECOY)
  SET 7,E                 ; Bounce: in the air, going up for three passes
  LD (IX+OBJ_COUNT),$03   ;
  LD B,$12                ;
  JR ANIMATE_AND_MOVE_15  ;
ANIMATE_AND_MOVE_11:
  BIT 7,E                  ; On the ground: done
  JR Z,ANIMATE_AND_MOVE_16 ;
  DEC (IX+OBJ_COUNT)       ; In the air: count down, and at nought it is out of
  JR Z,ANIMATE_AND_MOVE_14 ; the air
  LD A,D                  ; Keep going the way it went
ANIMATE_AND_MOVE_12:
  LD B,A                      ; Mid-jump (state 5): the way asked for, before
  LD A,E                      ; MEET_DECOY changed it
  AND $0F                     ;
  CP $05                      ;
  JR NZ,ANIMATE_AND_MOVE_13   ;
  LD B,(IY+ASKED_DIRECTION-V) ;
ANIMATE_AND_MOVE_13:
  CP $08                    ; The knight in the air with no step in height has
  JR NZ,ANIMATE_AND_MOVE_15 ; landed
  BIT 1,(IY+STEP_AXES-V)    ;
  JR NZ,ANIMATE_AND_MOVE_15 ;
ANIMATE_AND_MOVE_14:
  RES 7,E                 ; Out of the air; carry on the way +13 says
  LD (IX+OBJ_COUNT),$01   ;
  LD B,(IX+OBJ_DIRECTION) ;
ANIMATE_AND_MOVE_15:
  LD (IX+OBJ_COURSE),B    ; Its way while in the air
  LD A,(STEP_AXES)          ; It moved: keep the new state
  AND $07                   ;
  JR NZ,ANIMATE_AND_MOVE_16 ;
  BIT 7,(IY+SECOND_POINT_ROW-V) ; It did not move, and was not in the air at
  JR Z,ANIMATE_AND_MOVE_16      ; the start of the pass: keep the state
  RES 7,E                 ; It was in the air and could not move at all: out of
  LD (IX+OBJ_STATE),E     ; the air, and update it again at once
  LD (IX+OBJ_COUNT),$01   ;
  LD HL,(WORK_RECORD)     ;
  JP CHE3D                ;
ANIMATE_AND_MOVE_16:
  LD A,E                  ; The new state
  LD (IX+OBJ_STATE),A     ;
  AND $0F                  ; Anything but a thing lying (state 0) is redrawn
  JR NZ,REDRAW_THIS_OBJECT ;
  BIT 5,(IX+OBJ_WEIGHT)    ; A thing that is carried too
  JR NZ,REDRAW_THIS_OBJECT ;
  LD A,(STEP_AXES)        ; A thing lying still needs no redraw
  AND $07                 ;
  RET Z                   ;
; This entry point is used by the routine at CREATURE_UPDATE.
REDRAW_THIS_OBJECT:
  LD HL,(WORK_RECORD)     ; Redraw the object, in its new place
  JP REDRAW_OBJECT        ;

; Where the object being updated is
;
; Used by the routines at CHE3D, CREATURE_UPDATE, PICK_UP, ANIMATE_AND_MOVE,
; BUMPED, OBJECTS_MEET, MOVER_VANISHES and MEET_DECOY.
;
; The author's BUT. Reads the working copy that CHE3D makes of the record (+6
; to +8, at IY+$6A to IY+$6C).
;
; O:B Its place along x (+6)
; O:D Its top (+7), counting upwards
; O:H Its place along y (+8)
WORKING_POSITION:
  LD B,(IY+LINE_PAGE-V)
  LD D,(IY+MODE-V)
  LD H,(IY+REPEATS-V)
  RET

; How big the object being updated is
;
; Used by the routines at CHE3D, PICK_UP, ANIMATE_AND_MOVE, BUMPED and
; MEET_DECOY.
;
; The author's BUT2. Its box runs from +6 to +6 plus the width along x, from +8
; to +8 plus the depth along y, and from +7 less the height up to +7 -- a
; corner and three sizes, not a centre and half-sizes (the box test in
; TEST_ONE_RECORD).
;
; O:C Its width, along x (+9)
; O:E Its height (+10)
; O:L Its depth, along y (+11)
WORKING_SIZES:
  LD C,(IY+REPEATS+$01-V)
  LD E,(IY+REPEAT_FROM-V)
  LD L,(IY+REPEAT_FROM+$01-V)
  RET

; Something is in the way: a door takes the knight through, anything else is
; met
;
; Used by the routine at ANIMATE_AND_MOVE.
;
; Reached when a step would make the object's box meet another record's
; (FIND_OBSTACLE), IX being the one it meets. Anything but a door (kind 1 in
; the low nibble of +12, the eleven-byte records of the object table) goes to
; OBJECTS_MEET. A door stops anyone but the knight, like a wall. For him: The
; key. If the door's +14 holds a thing's number, the thing in the place in use
; must be that one, or it is LOCKED (message 2). With the place empty, IX
; becomes nought and the test reads byte 19 of the ROM, $FF, which is no
; thing's number, so it is LOCKED. Eight things open doors (numbers 1 to 8; 21
; doors need one). The way. The door's +17 has the direction bits
; (KNIGHT_CONTROLS) of the way through it, and he must be going that way this
; pass: x or y for a doorway, up or down for a hole (twelve doors). Walking
; into a door any other way is stopped as by a wall. Going down happens by
; gravity alone, as he stands over the hole; going up needs a jump. Room 61.
; The only way out of room 61 also needs the thing of kind 11 to be lying in
; the room (bit 1 of IY+$11) -- measured: without it he stands on the hole;
; with it he drops to room 60. Where he arrives. For a doorway along y he must
; be wholly within the door's width; he arrives as far along x from the door's
; +15 as he was from the door's corner, at y = +18 (less his depth if he walked
; down y). For one along x, within its depth; as far along y from +18, at x =
; +15 (less his width if he walked down x). For a hole his x and y are carried
; across relative to the door (+15 and +18) and his top is set to +16 (plus his
; height going up; that case never ran in the build's sessions). Through a
; doorway his height must lie wholly within the door's, and carries across
; relative to +16. The room behind. Every thing among the first 163 records of
; the object table whose record puts it in the room he is going to is tested
; against where he would arrive, its box made from the table's position and its
; template's sizes; if one is there, it is BLOCKED (message 1) and he stays. A
; thing with bit 4 of its +12 -- in the table, only the trolls -- does not
; count (measured, by moving thing 1 into room 30 where the door from room 29
; lands him: BLOCKED; with bit 4 set he went through).
;
; Then the room changes (Krumlinde's RTN_Trigger_Room_Change): the room number
; is the door's +13, the knight's record is moved to where he arrives, the
; things' places are saved (SAVE_OBJECT_POSITIONS), and the new room is entered
; (ROOMST), which goes back to the main loop.
;
; IX The record in the way
; B The object's x after the step (D its top, H its y; C, E, L its sizes)
BUMPED:
  LD A,(IX+OBJ_KIND)      ; Not a door: meet it
  AND $0F                 ;
  CP $01                  ;
  JP NZ,OBJECTS_MEET      ;
  SET 7,(IY+STEP_AXES-V)  ; A door was met this pass
  LD A,(THIS_RECORD)      ; Only the knight goes through; for anything else it
  CP $07                  ; is a wall (MEET_DECOY)
  JP NZ,BLOCKED_MOVE      ;
  LD A,(IX+OBJ_STATE)     ; No key needed
  AND A                   ;
  JR Z,DOOR_WAY           ;
  PUSH HL                 ; The thing in the place in use (nought, the ROM, if
  PUSH DE                 ; none)
  PUSH IX                 ;
  LD L,(IY+SELECTED-V)    ;
  LD H,$FF                ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  PUSH DE                 ;
  POP IX                  ;
  CP (IX+OBJ_NUMBER)      ; Is it the key?
  POP IX                  ;
  POP DE                  ;
  POP HL                  ;
  JR Z,DOOR_WAY           ;
  LD (IY+MESSAGE-V),$02   ; No: LOCKED, and it is a wall
  JP BLOCKED_MOVE         ;
DOOR_WAY:
  LD A,(IX+OBJ_FRAME)     ; Krumlinde's RTN_Check_Door_Keys, though the key is
  LD C,A                  ; already settled here. C = the way through the door
  AND (IY+ASKED_DIRECTION-V) ; Is he going that way? This is AND
  JP Z,BLOCKED_MOVE          ; (IY+ASKED_DIRECTION-V): Krumlinde has a DB and a
                             ; label at its second byte, and reads the rest as
                             ; AND (HL) and LD A,H
  LD A,(ROOM)             ; In room 61...
  CP $3D                  ;
  JR NZ,DOOR_ARRIVAL      ;
  BIT 1,(IY+THINGS_NOTED-V) ; ...only if the thing of kind 11 lies there
  JP Z,BLOCKED_MOVE         ;
DOOR_ARRIVAL:
  CALL WORKING_POSITION   ; B, D, H = where he is (before the step)
  LD L,(IX+OBJ_COUNT)     ; L = the x he arrives at, E = the y (the door's +15
  LD E,(IX+OBJ_COURSE)    ; and +18)
  LD A,C                  ; Is the way along y (neither x nor height)?
  AND $3C                 ;
  JR NZ,BUMPED_0          ;
  LD A,B                   ; Along y: he must be wholly within the door's width
  SUB (IX+OBJ_X)           ;
  JP C,BLOCKED_MOVE        ;
  LD B,A                   ;
  ADD A,(IY+REPEATS+$01-V) ;
  SUB (IX+OBJ_LEN_X)       ;
  JP NC,BLOCKED_MOVE       ;
  LD A,L                  ; x: as far along from +15 as he was from the door's
  ADD A,B                 ; corner
  LD B,A                  ;
  LD H,E                  ; y: +18 when going up y...
  BIT 6,C                 ;
  JR NZ,BUMPED_2          ;
  LD A,E                     ; ...or his depth less, going down y
  SUB (IY+REPEAT_FROM+$01-V) ;
  LD H,A                     ;
  JR BUMPED_2                ;
BUMPED_0:
  LD A,C                  ; A hole (up or down)?
  AND $30                 ;
  JR Z,BUMPED_1           ;
  LD A,B                  ; x: carried across relative to the door
  SUB (IX+OBJ_X)          ;
  ADD A,L                 ;
  LD B,A                  ;
  LD A,H                  ; And y
  SUB (IX+OBJ_Z)          ;
  ADD A,E                 ;
  LD H,A                  ;
  LD A,(IX+OBJ_WEIGHT)    ; His top: the door's +16...
  BIT 4,C                 ; ...when going down
  JR Z,BUMPED_3           ;
  ADD A,(IY+REPEAT_FROM-V) ; Going up, plus his height (never ran in the
  JR BUMPED_3              ; build's sessions)
BUMPED_1:
  LD A,H                       ; Along x: he must be wholly within the door's
  SUB (IX+OBJ_Z)               ; depth
  JP C,BLOCKED_MOVE            ;
  LD H,A                       ;
  ADD A,(IY+REPEAT_FROM+$01-V) ;
  SUB (IX+OBJ_LEN_Z)           ;
  JP NC,BLOCKED_MOVE           ;
  LD A,H                  ; (A wasted load: A is loaded again at once)
  LD A,E                  ; y: as far along from +18 as he was from the door's
  ADD A,H                 ; corner
  LD H,A                  ;
  LD A,L                  ; x: +15 when going up x...
  LD B,A                  ;
  BIT 3,C                 ; ...or his width less, going down x
  JR NZ,BUMPED_2          ;
  SUB (IY+REPEATS+$01-V)  ;
  LD B,A                  ;
BUMPED_2:
  LD A,D                  ; Through a doorway: his top must be below the door's
  SUB (IX+OBJ_TOP)        ; top...
  JP NC,BLOCKED_MOVE      ;
  LD D,A                  ; ...and his feet not below the door's foot
  SUB (IY+REPEAT_FROM-V)  ;
  ADD A,(IX+OBJ_HEIGHT)   ;
  JP NC,BLOCKED_MOVE      ;
  LD A,(IX+OBJ_WEIGHT)    ; His top: as far below +16 as it was below the
  ADD A,D                 ; door's top
BUMPED_3:
  LD D,A                  ; D = his top on arrival
  CALL WORKING_SIZES      ; C, E, L = his sizes; keep all six in the other set
  EXX                     ;
  LD C,(IX+OBJ_DIRECTION) ; C = the room behind the door (+13)
ARRIVAL_CHECK:
  LD HL,$A91F             ; HL five bytes before the object table, so that each
  PUSH IX                 ; step of five and the byte read after it moves on
                          ; one six-byte record; keep the door's record
BUMPED_4:
  LD DE,$0005             ; Next record: E = its room, A = its type
  ADD HL,DE               ;
  LD E,(HL)               ;
  INC HL                  ;
  LD A,(HL)               ;
  CP $46                  ; The first eleven-byte record ends the things: none
  JR NC,GO_THROUGH_DOOR   ; is in the way
  LD A,E                  ; A thing in another room: next
  CP C                    ;
  JR NZ,BUMPED_4          ;
  PUSH HL                 ; Make a record of it at IY+$4B: its +12 byte and its
  PUSH BC                 ; place (x, top, y) go to +5 to +8 (+5 and +6 are
  LD A,(HL)               ; PRINT_X and PRINT_Y; whatever prints next sets them
  INC HL                  ; again)
  LD DE,$FFD0             ;
  LD BC,$0004             ;
  LDIR                    ;
  PUSH DE                 ; Its template (TEMPLATES): the sizes, at byte 6
  LD HL,$B72F             ;
  LD DE,$000B             ;
  INC A                   ;
BUMPED_5:
  ADD HL,DE               ;
  DEC A                   ;
  JR NZ,BUMPED_5          ;
  POP DE                  ; To +9 to +11
  LD BC,$0003             ;
  LDIR                    ;
  LD IX,ARRIVAL_BOX       ; Would he arrive in its box? (the box test in
  EXX                     ; TEST_ONE_RECORD, with his arrival in the other set)
  CALL BOX_OVERLAP        ;
  EXX                     ;
  POP BC                  ; No: next thing
  POP HL                  ;
  JR NC,BUMPED_4          ;
  BIT 4,(IX+OBJ_SPRITE+$01) ; A thing with bit 4 of +12 does not count
  JR NZ,BUMPED_4            ;
  LD (IY+MESSAGE-V),$01   ; Anything else: BLOCKED, and it is a wall
  POP IX                  ;
  JP BLOCKED_MOVE         ;
GO_THROUGH_DOOR:
  LD (IY+ROOM-V),C        ; Krumlinde's RTN_Trigger_Room_Change. The room is
                          ; the one behind the door
  POP AF                  ; Drop the scan's IX, and the two words the main loop
  EXX                     ; left (MAIN_LOOP): ROOMST goes back into the loop
  POP AF                  ; itself
  POP AF                  ;
  LD IX,(WORK_RECORD)     ; Move the knight to where he arrives
  CALL ISO_MOVE           ;
  LD A,(WORK_BEHAVIOUR)   ; With the state he had
  LD (IX+OBJ_STATE),A     ;
  CALL SAVE_OBJECT_POSITIONS ; Save where the things of the room are
                             ; (SAVE_OBJECT_POSITIONS)
  JP ROOMST               ; And enter the new one

; Write the room's things' positions back into the object table (the author's
; EEN)
;
; Used by the routines at TITLE_SCREEN, BUMPED and MAIN_LOOP.
;
; Run whenever the knight leaves a room: through a door (BUMPED), carried off
; by the thing of kind 9 (MAIN_LOOP), and at the end of a game, before GAME
; OVER (TITLE_SCREEN). The records after the knight's (from RECORDS) are the
; things he carries and then the object table's things for this room, in the
; table's order. For each, the three bytes of where it is -- +6 x, +7 y (its
; top: y is the height) and +8 z -- are copied into bytes 3 to 5 of its entry
; in the object table (OBJECTS), found from the number at +$13. That is how a
; thing left somewhere, or pushed, is still there when the knight comes back.
;
; The walk stops at the first door. The table lists a room's things that can
; move before its doors, and nothing after them is kept: not the doors, not the
; table's last six-byte entries (the author's source text heads them STATIC
; OBJ), and not what the room's drawing placed. The walk would also stop after
; the last record in use, but that never happened in the build's sessions:
; every room has a door.
;
; Two creatures are drawn facing the other way by turning their shared frames
; round in place: the wraith (SPRITE5E88, behaviour 11) and the troll
; (SPRITE8BB8, behaviour 7) -- the author's MIWRAI and MITRO name the routines.
; One whose frames are turned (bit 5 of +14) has them turned back here, by
; asking for the direction +x (C=8), so that the next room's wraiths and
; trolls, which start with bit 5 clear, find them the way round they expect.
; The record keeps its bit 5, but it is about to be overwritten.
SAVE_OBJECT_POSITIONS:
  LD A,(OBJECT_COUNT)     ; Nothing to do if the knight's is the last record in
  SUB $07                 ; use (the seventh)
  RET Z                   ;
  LD IX,RECORDS           ; IX = the first record after his; B = how many there
  LD B,A                  ; are
SAVE_OBJECT_POSITIONS_0:
  LD A,(IX+OBJ_KIND)      ; Stop at the first door (kind 1 in +12)
  AND $0F                 ;
  CP $01                  ;
  RET Z                   ;
  PUSH BC                      ; HL = the thing's entry plus 3: six bytes a
  LD B,(IX+OBJ_NUMBER)         ; number, counted on from just below the table;
  LD DE,$0006                  ; kept on the stack
  LD HL,$A921                  ;
SAVE_OBJECT_POSITIONS_1:
  ADD HL,DE                    ;
  DJNZ SAVE_OBJECT_POSITIONS_1 ;
  PUSH HL                      ;
  LD A,(IX+OBJ_STATE)     ; B = its behaviour byte (+14); C = 8, facing +x, for
  LD B,A                  ; the mirror routines
  LD C,$08                ;
  AND $0F                 ;
  CP $0B                        ; Behaviour 11, the wraith: frames turned round
  JR NZ,SAVE_OBJECT_POSITIONS_2 ; (bit 5)? Turn them back (MIWRAI)
  BIT 5,B                       ;
  CALL NZ,MIWRAI                ;
  JR SAVE_OBJECT_POSITIONS_3    ;
SAVE_OBJECT_POSITIONS_2:
  CP $07                        ; Behaviour 7, the troll: the same (MITRO)
  JR NZ,SAVE_OBJECT_POSITIONS_3 ;
  BIT 5,B                       ;
  CALL NZ,MITRO                 ;
SAVE_OBJECT_POSITIONS_3:
  PUSH IX                 ; Copy x, y and z (+6 to +8) into the entry
  POP HL                  ;
  LD DE,$0006             ;
  ADD HL,DE               ;
  POP DE                  ;
  LD BC,$0003             ;
  LDIR                    ;
  POP BC                       ; On to the next record
  LD DE,$0014                  ;
  ADD IX,DE                    ;
  DJNZ SAVE_OBJECT_POSITIONS_0 ;
  RET                     ; After the last record (never reached in the build's
                          ; sessions)
; Measured in the simulator: a thing's +6 and +8 changed in room 20, then LIFE
; set to 0; after this routine the thing's entry held the new values.

; Settle what happens when a moving object runs into one that is not a door
;
; Used by the routine at BUMPED.
;
; Jumped to from BUMPED when the move tried for the object being updated -- the
; mover: its record at WORK_RECORD, its number in THIS_RECORD and a working
; copy of it from IY+$64 -- would overlap a record that is not a door: the
; other, at IX, its number in FOUND_RECORD. The kind bytes (+12) of the two
; decide, in this order.
;
; A mover with bit 4 of its kind byte hurts what it touches: the troll and the
; bouncing balls (SPRITE7E88). If the other is the knight he loses 10 LIFE,
; except on a room's first pass (bit 2 of GAME_FLAGS). If the other is not a
; still thing (+16), it is knocked -- bit 4 of its +14 and the direction $12
; make its next update a hop upward -- and the mover vanishes where it is (bit
; 5 of its +16). Against a still thing the tests go on.
;
; When the knight walks into something whose kind byte has bit 4, he loses 10
; LIFE, the other vanishes, and his move carries on as if it had not been
; there.
;
; Bit 7 of the kind byte marks a fighter: the knight and nearly every creature.
; A fighter other than the knight that walks into him takes 1 LIFE; the knight
; walking into a fighter loses 1 LIFE himself, unless his sword is out (bit 1
; of GAME_FLAGS, the striking half of the fight animation, KNIGHT_CONTROLS).
; Then a fighter that can be killed (bit 6: the guards, the ghosts and the
; troll) has one of its strikes taken: the counter FIND_OBSTACLE gave it, one
; of the six STRIKES_LEFT, each 4 when the room was entered. At none left, a
; guard (behaviour 6, 9 or 10) is left lying as its helmet (SPRITEA4B8), a
; thing that can be picked up; anything else vanishes. That never happened in
; the build's sessions. Staged in the simulator -- the counters set to 1, the
; guard of room 29 put in front of the knight, and B and Y held -- the guard
; became the helmet.
;
; After the fighters: a creature of behaviour 13 (the ghost, SPRITE5B30) takes
; any thing that can be picked up that it runs into: the thing vanishes, and
; its entry in the object table is moved to room $FE, out of the game
; (SET_THING_ROOM). A wraith (behaviour 11) that a thing of kind 6 or 10 runs
; into vanishes with it, both taken out of the game; that too never ran in the
; sessions, and was staged in room 28 by dropping the kind-6 thing onto the
; wraith. Anything that runs into a kind-7 object -- the floor of the pits in
; rooms 9 and 12 -- vanishes, and if it is the knight, LIFE goes to 0.
; Everything else goes on to MEET_DECOY.
OBJECTS_MEET:
  BIT 4,(IY+WORK_KIND-V)  ; Does the mover hurt what it touches (bit 4 of its
  JR Z,OBJECTS_MEET_1     ; kind)?
  BIT 2,(IY+GAME_FLAGS-V) ; Not on the room's first pass
  JR NZ,OBJECTS_MEET_0    ;
  LD A,(FOUND_RECORD)     ; The knight touched: 10 LIFE (the author's DECLI1)
  CP $07                  ;
  JR NZ,OBJECTS_MEET_1    ;
  CALL DECLI1             ;
OBJECTS_MEET_0:
  LD A,(IX+OBJ_WEIGHT)    ; A still thing: on to the next test
  AND $1F                 ;
  JR Z,OBJECTS_MEET_1     ;
  SET 4,(IX+OBJ_STATE)      ; Knock it: next time it moves by the direction
  LD (IX+OBJ_DIRECTION),$12 ; $12, up
  LD IX,(WORK_RECORD)     ; The mover vanishes
  SET 5,(IX+OBJ_WEIGHT)   ;
  CALL WORKING_POSITION   ; where it was, and is erased (ANIMATE_AND_MOVE)
  JP COMMIT_STEP          ;
OBJECTS_MEET_1:
  BIT 4,(IX+OBJ_KIND)     ; Does the other hurt, and is the mover the knight?
  JR Z,OBJECTS_MEET_2     ;
  LD A,(THIS_RECORD)      ;
  CP $07                  ;
  JR NZ,OBJECTS_MEET_2    ;
  CALL DECLI1             ; 10 LIFE, and the other vanishes
  JR OTHER_VANISHES       ;
OBJECTS_MEET_2:
  BIT 7,(IY+WORK_KIND-V)  ; Is the mover a fighter (bit 7)?
  JR Z,OBJECTS_MEET_8     ;
  LD A,(THIS_RECORD)      ; The knight: below
  CP $07                  ;
  JR Z,OBJECTS_MEET_4     ;
  LD A,(FOUND_RECORD)     ; Another fighter: has it walked into the knight?
  CP $07                  ;
  JR NZ,OBJECTS_MEET_8    ;
OBJECTS_MEET_3:
  LD A,$01                ; Take 1 LIFE (at DECLIF, DECLI1)
  CALL DECLIF             ;
  JR OBJECTS_MEET_8       ;
OBJECTS_MEET_4:
  BIT 1,(IY+GAME_FLAGS-V) ; The knight: is his sword out?
  JR NZ,OBJECTS_MEET_5    ;
  BIT 7,(IX+OBJ_KIND)     ; No: a fighter touched costs him 1 LIFE
  JR NZ,OBJECTS_MEET_3    ;
  JR OBJECTS_MEET_8       ;
OBJECTS_MEET_5:
  BIT 6,(IX+OBJ_KIND)     ; Yes: can the other be killed (bit 6)?
  JR Z,OBJECTS_MEET_8     ;
  LD L,(IY+STRIKES_AT-V)  ; Take a strike off its counter (the address's low
  LD H,$FF                ; byte in IY+2)
  DEC (HL)                ;
  JR NZ,OBJECTS_MEET_8    ;
  LD A,(IX+OBJ_STATE)     ; None left: is it a guard (behaviour 6, 9 or 10)?
  AND $0F                 ;
  CP $06                  ;
  JR Z,OBJECTS_MEET_6     ;
  CP $09                  ;
  JR Z,OBJECTS_MEET_6     ;
  CP $0A                  ;
  JR Z,OBJECTS_MEET_6     ;
; This entry point is used by the routine at MEET_DECOY.
OTHER_VANISHES:
  SET 5,(IX+OBJ_WEIGHT)   ; OTHER_VANISHES: bit 5 of its +16
  JR OBJECTS_MEET_7       ;
OBJECTS_MEET_6:
  LD (IX+OBJ_SPRITE),$B8     ; The guard's helmet: its sprite, behaviour 0 with
  LD (IX+OBJ_SPRITE+$01),$A4 ; a hop, a fighter that can be picked up,
  LD (IX+OBJ_STATE),$10      ; direction $12
  LD (IX+OBJ_KIND),$A0       ;
  LD (IX+OBJ_DIRECTION),$12  ;
OBJECTS_MEET_7:
  LD A,(THIS_RECORD)      ; Finish the mover's move (BLOCKED_MOVE, MEET_DECOY)
  PUSH AF                 ;
  PUSH IX                 ;
  CALL BLOCKED_MOVE       ;
  POP HL                  ; Redraw the other as the record being drawn (the
  PUSH HL                 ; number is stale: see below)
  POP IX                  ;
  LD A,(FOUND_RECORD)     ;
  LD (THIS_RECORD),A      ;
  CALL REDRAW_OBJECT      ;
  POP AF                  ; THIS_RECORD back; the mover's update is done
  LD (THIS_RECORD),A      ;
  RET                     ;
OBJECTS_MEET_8:
  LD A,(WORK_BEHAVIOUR)   ; A behaviour-13 creature, the ghost, and a thing
  AND $0F                 ; that can be picked up?
  CP $0D                  ;
  JR NZ,OBJECTS_MEET_9    ;
  BIT 5,(IX+OBJ_KIND)     ;
  JR NZ,OBJECTS_MEET_11   ;
OBJECTS_MEET_9:
  LD A,(IX+OBJ_STATE)     ; A wraith (behaviour 11) met by a thing of kind 6 or
  AND $0F                 ; 10?
  CP $0B                  ;
  JR NZ,OBJECTS_MEET_12   ;
  LD A,(WORK_KIND)        ;
  AND $0F                 ;
  CP $06                  ;
  JR Z,OBJECTS_MEET_10    ;
  CP $0A                  ;
  JR NZ,OBJECTS_MEET_12   ;
OBJECTS_MEET_10:
  PUSH IX                 ; The thing leaves the game (room $FE) and
  LD IX,(WORK_RECORD)     ; vanishes...
  LD C,$FE                ;
  CALL SET_THING_ROOM     ;
  SET 5,(IX+OBJ_WEIGHT)   ;
  POP IX                  ;
OBJECTS_MEET_11:
  LD C,$FE                ; ...and so does the other
  CALL SET_THING_ROOM     ;
  JR OTHER_VANISHES       ;
OBJECTS_MEET_12:
  LD A,(IX+OBJ_KIND)      ; Kind 7, the pit floor?
  AND $0F                 ;
  CP $07                  ;
  JR NZ,MEET_DECOY        ;
  LD IX,(WORK_RECORD)     ; IX = the mover
  LD A,(THIS_RECORD)      ; The knight: LIFE 0
  CP $07                  ;
  JR NZ,MOVER_VANISHES    ;
  LD HL,$0000             ;
  LD (LIFE_TENS),HL       ;
  JR MOVER_VANISHES       ; Over the five bytes at SKIPPED_REMOVAL
; When something has vanished, or a guard become a helmet, the mover's move is
; finished at MEET_DECOY's BLOCKED_MOVE and the other is redrawn -- erased, in
; fact, as it is now hidden -- with THIS_RECORD set to the other's number for
; REDRAW_OBJECT. The number is read from FOUND_RECORD after the mover's own
; redraw has used that byte for its sprite's width in bytes (DRAW_SPRITE), so
; it is wrong: 3, not 19, when the knight met the troll in room 2 in the
; simulator. It only changes which record REDRAW_OBJECT leaves out of the
; redraw. A vanished thing is hidden anyway; a helmet is not, and is drawn once
; as if in front of itself -- measured with a guard killed by fighting in room
; 77: one pixel differs from a corrected run, for one pass.

; Five bytes of code no jump reaches
;
; LD C,$FE and CALL SET_THING_ROOM, the pair OBJECTS_MEET uses to take a thing
; out of the game by moving its object-table entry to room $FE. They lie after
; the JR that ends the kind-7 case, which always skips them (Krumlinde noted
; them too). So a thing that falls to a pit's floor keeps its entry and, as
; SAVE_OBJECT_POSITIONS saves where it vanished, is placed again the next time
; the room is entered, and falls in again (measured: its table room stays 9;
; not checked by leaving through room 9's doors). Had they run for the knight
; they would have done harm: the number at +$13 of his record is 0, and
; SET_THING_ROOM would count 256 entries on and overwrite a byte of the table
; far beyond.
SKIPPED_REMOVAL:
  DEFB $0E,$FE,$CD,$E6,$F4

; Make the mover vanish where it stands
;
; Used by the routine at OBJECTS_MEET.
;
; The end of OBJECTS_MEET's kind-7 case, and of a hurting mover's touch: bit 5
; of the mover's +16 hides it -- it is no longer updated, drawn or run into --
; and the move is finished where the mover already was, which erases it
; (ANIMATE_AND_MOVE).
;
; IX The mover's record
MOVER_VANISHES:
  SET 5,(IX+OBJ_WEIGHT)   ; Hidden
  CALL WORKING_POSITION   ; Finish the move at the old position
  JP COMMIT_STEP          ;

; Let a guard take a decoy, or else stop the part of a move that is blocked
;
; Used by the routine at OBJECTS_MEET.
;
; The last case of OBJECTS_MEET: a behaviour-9 guard that runs into a decoy
; (kind 8) takes it. The decoy vanishes, its entry goes to room $FE, and
; THINGS_NOTED is cleared, so that CHE3D finds any other decoy afresh and until
; then the guard chases the knight (ZOOMIN). Anything else, and a move into a
; door (BUMPED), comes to BLOCKED_MOVE.
;
; BLOCKED_MOVE works out how much of the move the other object stops, trying
; the move against that one object only (TEST_OTHER) from where the mover was.
; Each axis that is moving is tried alone: x (+6), y (+7, the height) and z
; (+8). One that collides is taken out of the move, and the mover's direction
; on it is turned round if the mover bounces (bit 0 of its direction, +13) or
; cleared if it does not. Two collisions do something else. Running along x
; into a kind-3 object, or along z into a kind-2 one, marks a climb (bit 6 of
; STEP_AXES): those are the invisible steps of a staircase, and
; ANIMATE_AND_MOVE lifts the mover for three passes. Coming down onto the other
; marks a landing (bit 5); and if what the mover lands on is moving -- by its
; own behaviour, or coasting (bit 7 of +14) -- the mover rides it: bit 4 of the
; mover's +14 is set and the other's direction (+13, or +18 if coasting) goes
; to RIDE_DIRECTION, which ANIMATE_AND_MOVE gives the mover. Nothing rides a
; door.
;
; Then the pairs, from where the mover was: x with y colliding takes y out; x
; with z takes both out; y with z takes y out. If all three axes are still in
; the move after that, only the whole move collides, and none of it is made.
;
; Last, a push. Unless the mover landed on the other or it is a door, and
; unless the other is still (nothing in the low five bits of +16, which for a
; thing that moves are 16 more than its weight), the other is pushed if it is
; no more than 5 heavier than the mover: it coasts (bit 7 of +14) for the
; mover's +16 less its own, plus 6, passes (+15), heading (+18) the way the
; mover asked to go (ASKED_DIRECTION), keeping its own bounce and rise bits.
; The knight's +16 is 18, so he pushes anything of 23 or less. What is left of
; the move is then tried again (ANIMATE_AND_MOVE), and may run into something
; else.
;
; A The other's kind (+12, low nibble)
; IX The other's record
MEET_DECOY:
  CP $08                  ; A decoy, and the mover a behaviour-9 guard?
  JR NZ,BLOCKED_MOVE      ;
  LD A,(WORK_BEHAVIOUR)   ;
  AND $0F                 ;
  CP $09                  ;
  JR NZ,BLOCKED_MOVE      ;
  LD C,$FE                   ; The decoy leaves the game (room $FE); look for
  CALL SET_THING_ROOM        ; decoys again
  LD (IY+THINGS_NOTED-V),$00 ;
  JP OTHER_VANISHES       ; It vanishes (OBJECTS_MEET)
; This entry point is used by the routines at BUMPED and OBJECTS_MEET.
BLOCKED_MOVE:
  CALL WORKING_POSITION   ; BLOCKED_MOVE: B, D, H = the mover's x, y and z
  CALL WORKING_SIZES      ; before the move; C, E, L its lengths
  LD C,(IY+STEP_AXES-V)   ; C = the axes moving (STEP_AXES)
  CALL STEP_ALONG_X       ; x alone
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_3      ;
  RES 0,C                 ; Blocked: x out of the move
  LD A,(IX+OBJ_KIND)      ; Along x into a kind-3 step: a climb
  AND $0F                 ;
  CP $03                  ;
  JR NZ,MEET_DECOY_0      ;
  SET 6,C                 ;
  JR MEET_DECOY_3         ;
MEET_DECOY_0:
  LD A,(WORK_DIRECTION)   ; Otherwise turn round on x if the mover bounces, or
  BIT 0,A                 ; stop on x
  JR NZ,MEET_DECOY_1      ;
  AND $F3                 ;
  JR MEET_DECOY_2         ;
MEET_DECOY_1:
  XOR $0C                 ;
MEET_DECOY_2:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_3:
  LD B,(IY+LINE_PAGE-V)   ; y alone, x back where it was
  CALL STEP_ALONG_Y       ;
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_8      ;
  RES 1,C                 ; Blocked: y out
  BIT 7,C                 ; Nothing rides a door
  JR NZ,MEET_DECOY_5      ;
  LD D,(IX+OBJ_STATE)         ; Coming down onto it (bit 5 of the direction)?
  BIT 5,(IY+WORK_DIRECTION-V) ;
  JR Z,MEET_DECOY_5           ;
  SET 5,C                 ; A landing
  LD A,D                  ; What it lands on has a behaviour: ride with its
  AND $1F                 ; direction (+13)
  LD A,(IX+OBJ_DIRECTION) ;
  JR NZ,MEET_DECOY_4      ;
  BIT 7,D                 ; Or is coasting: ride with its heading (+18)
  JR Z,MEET_DECOY_5       ;
  LD A,(IX+OBJ_COURSE)    ;
MEET_DECOY_4:
  SET 4,(IY+WORK_BEHAVIOUR-V) ; Riding: bit 4 of the mover's +14, and the way
  LD (RIDE_DIRECTION),A       ; to go
MEET_DECOY_5:
  LD A,(WORK_DIRECTION)   ; Turn round on y if the mover bounces, or stop on y
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_6      ;
  AND $CF                 ;
  JR MEET_DECOY_7         ;
MEET_DECOY_6:
  XOR $30                 ;
MEET_DECOY_7:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_8:
  LD D,(IY+MODE-V)        ; z alone, y back where it was
  CALL STEP_ALONG_Z       ;
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_12     ;
  RES 2,C                 ; Blocked: z out
  LD A,(IX+OBJ_KIND)      ; Along z into a kind-2 step: a climb
  AND $0F                 ;
  CP $02                  ;
  JR NZ,MEET_DECOY_9      ;
  SET 6,C                 ;
  JR MEET_DECOY_12        ;
MEET_DECOY_9:
  LD A,(WORK_DIRECTION)   ; Otherwise turn round on z, or stop on z
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_10     ;
  AND $3F                 ;
  JR MEET_DECOY_11        ;
MEET_DECOY_10:
  XOR $C0                 ;
MEET_DECOY_11:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_12:
  LD H,(IY+REPEATS-V)     ; Back to where the mover was
  CALL WORKING_POSITION   ;
  LD A,C                  ; x and y together
  AND $03                 ;
  CP $03                  ;
  JR NZ,MEET_DECOY_16     ;
  CALL STEP_ALONG_X       ;
  CALL STEP_ALONG_Y       ;
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_15     ;
  RES 1,C                 ; Blocked: y out, turned round or stopped
  LD A,(WORK_DIRECTION)   ;
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_13     ;
  AND $CF                 ;
  JR MEET_DECOY_14        ;
MEET_DECOY_13:
  XOR $30                 ;
MEET_DECOY_14:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_15:
  CALL WORKING_POSITION   ; Back again
MEET_DECOY_16:
  LD A,C                  ; x and z together
  AND $05                 ;
  CP $05                  ;
  JR NZ,MEET_DECOY_20     ;
  CALL STEP_ALONG_X       ;
  CALL STEP_ALONG_Z       ;
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_19     ;
  RES 0,C                 ; Blocked: both out, both turned round or stopped
  RES 2,C                 ;
  LD A,(WORK_DIRECTION)   ;
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_17     ;
  AND $33                 ;
  JR MEET_DECOY_18        ;
MEET_DECOY_17:
  XOR $CC                 ;
MEET_DECOY_18:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_19:
  CALL WORKING_POSITION   ; Back again
MEET_DECOY_20:
  LD A,C                  ; y and z together
  AND $06                 ;
  CP $06                  ;
  JR NZ,MEET_DECOY_24     ;
  CALL STEP_ALONG_Y       ;
  CALL STEP_ALONG_Z       ;
  CALL TEST_OTHER         ;
  JR NC,MEET_DECOY_23     ;
  RES 1,C                 ; Blocked: y out
  LD A,(WORK_DIRECTION)   ;
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_21     ;
  AND $CF                 ;
  JR MEET_DECOY_22        ;
MEET_DECOY_21:
  XOR $30                 ;
MEET_DECOY_22:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_23:
  CALL WORKING_POSITION   ; Back again
MEET_DECOY_24:
  LD A,C                  ; All three still moving? Then only the whole move
  AND $07                 ; collides...
  CP $07                  ;
  JR NZ,MEET_DECOY_27     ;
  LD A,C                  ; ...so none of it is made
  AND $F8                 ;
  LD C,A                  ;
  LD A,(WORK_DIRECTION)   ;
  BIT 0,A                 ;
  JR NZ,MEET_DECOY_25     ;
  AND $03                 ;
  JR MEET_DECOY_26        ;
MEET_DECOY_25:
  XOR $FC                 ;
MEET_DECOY_26:
  LD (WORK_DIRECTION),A   ;
MEET_DECOY_27:
  LD A,C                  ; What is left of the move, the landing and door bits
  AND $5F                 ; dropped
  LD (STEP_AXES),A        ;
  LD A,C                  ; No push after a landing or into a door
  AND $A0                 ;
  JR NZ,MEET_DECOY_28     ;
  LD A,(IX+OBJ_WEIGHT)    ; Nor of a still thing
  AND $1F                 ;
  JR Z,MEET_DECOY_28      ;
  LD B,A                  ; Pushed if no more than 5 heavier than the mover
  LD A,(WORK_WEIGHT)      ;
  AND $1F                 ;
  ADD A,$05               ;
  SUB B                   ;
  JR C,MEET_DECOY_28      ;
  INC A                   ; Coasting for the difference plus 6 passes
  LD (IX+OBJ_COUNT),A     ;
  SET 7,(IX+OBJ_STATE)    ;
  LD A,(ASKED_DIRECTION)  ; heading the way the mover asked to go, with its own
  AND $FC                 ; bounce and rise bits
  LD B,A                  ;
  LD A,(IX+OBJ_DIRECTION) ;
  AND $03                 ;
  OR B                    ;
  LD (IX+OBJ_COURSE),A    ;
MEET_DECOY_28:
  JP TRY_STEP             ; Try what is left of the move again

; Step a position along x, if x is moving
;
; Used by the routines at MEET_DECOY and STEP_ALL_AXES.
;
; Two units, or one when z is moving too. The way is bit 2 of the direction in
; WORK_DIRECTION: set for -x, clear for +x (bit 3).
;
;   C The axes moving: bit 0 x, bit 1 y, bit 2 z
;   B x
; O:B x after the step
STEP_ALONG_X:
  BIT 0,C                 ; x not moving
  RET Z                   ;
  BIT 2,(IY+WORK_DIRECTION-V) ; Which way?
  JR Z,STEP_ALONG_X_0         ;
  DEC B                   ; -x: one, or two if z is not moving
  BIT 2,C                 ;
  RET NZ                  ;
  DEC B                   ;
  RET                     ;
STEP_ALONG_X_0:
  INC B                   ; +x the same
  BIT 2,C                 ;
  RET NZ                  ;
  INC B                   ;
  RET                     ;

; Step a position along y, the height, if y is moving
;
; Used by the routines at MEET_DECOY and STEP_ALL_AXES.
;
; Always two units: up if bit 4 of the direction in WORK_DIRECTION is set, down
; (bit 5) if not.
;
;   C The axes moving: bit 1 y
;   D y
; O:D y after the step
STEP_ALONG_Y:
  BIT 1,C                 ; y not moving
  RET Z                   ;
  BIT 4,(IY+WORK_DIRECTION-V) ; Up two
  JR Z,STEP_ALONG_Y_0         ;
  INC D                       ;
  INC D                       ;
  RET                         ;
STEP_ALONG_Y_0:
  DEC D                   ; Down two
  DEC D                   ;
  RET                     ;

; Step a position along z, if z is moving
;
; Used by the routines at MEET_DECOY and STEP_ALL_AXES.
;
; Two units, or one when x is moving too: +z if bit 6 of the direction in
; WORK_DIRECTION is set, -z (bit 7) if not.
;
;   C The axes moving: bit 2 z
;   H z
; O:H z after the step
STEP_ALONG_Z:
  BIT 2,C                 ; z not moving
  RET Z                   ;
  BIT 6,(IY+WORK_DIRECTION-V) ; Which way?
  JR Z,STEP_ALONG_Z_0         ;
  INC H                   ; +z: one, or two if x is not moving
  BIT 0,C                 ;
  RET NZ                  ;
  INC H                   ;
  RET                     ;
STEP_ALONG_Z_0:
  DEC H                   ; -z the same
  BIT 0,C                 ;
  RET NZ                  ;
  DEC H                   ;
  RET                     ;

; Step a position along every axis that is moving
;
; Used by the routines at PICK_UP and ANIMATE_AND_MOVE.
;
; The whole of a move: STEP_ALONG_X, STEP_ALONG_Y and STEP_ALONG_Z in turn. A
; move along both x and z is one unit each way.
;
;   C The axes moving: bit 0 x, bit 1 y, bit 2 z
;   B, D, H x, y and z
; O:B, D, H The position after the move
STEP_ALL_AXES:
  CALL STEP_ALONG_X
  CALL STEP_ALONG_Y
  JR STEP_ALONG_Z

; Aim a chasing creature at the knight, or at a decoy (the author's ZOOMIN)
;
; Used by the routine at STEER.
;
; Called by STEER when a chaser's timer (+15) runs out: the guards (behaviours
; 6, 9 and 10), the troll (7) and the wraith (11, and 15 once woken). The
; target is the knight's record (KNIGHT), except for a behaviour-9 guard while
; a decoy is in the room (bit 0 of THINGS_NOTED): then it is the decoy's
; record, which CHE3D keeps in DECOY. IY is pointed at the target for AIM_AT,
; so (IY+6) and (IY+8) there are the target's x and z rather than variables --
; which is why THINGS_NOTED is read by its address here -- and then set back to
; OBJECT_COUNT.
;
;   E The chaser's behaviour byte (+14)
;   IX The chaser's record
; O:A The new heading
; O:D How far off the target is along that axis
ZOOMIN:
  LD A,E                  ; The target is the knight...
  LD IY,KNIGHT            ;
  AND $0F                 ;
  CP $09                  ;
  JR NZ,ZOOMIN_0          ;
  LD A,(THINGS_NOTED)     ; ...unless this is a behaviour-9 guard and a decoy
  BIT 0,A                 ; has been seen
  JR Z,ZOOMIN_0           ;
  LD IY,(DECOY)           ; The decoy's record
ZOOMIN_0:
  CALL AIM_AT             ; Work out the heading
  LD IY,OBJECT_COUNT      ; IY back on the variables
  RET                     ;

; Work out which way a chaser should go to reach its target
;
; Used by the routine at ZOOMIN.
;
; The heading is along one floor axis only, whichever the target is further off
; along: x (+6) or z (+8), measured to a point two units past the target's
; corner, and z when they are equal. The chaser's timer (+15) is set to 10
; passes before it looks again, or to 3 when the z distance is under 14 -- the
; z distance whichever axis won, as the code has it.
;
;   IX The chaser's record
;   IY The target's record
; O:A The heading: 8 for +x, 4 for -x, $40 for +z, $80 for -z
; O:D How far off the target is along that axis
AIM_AT:
  LD A,(IY+OBJ_X)         ; Look again in 10 passes
  ADD A,$02               ;
  LD (IX+OBJ_COUNT),$0A   ;
  PUSH HL                 ; Keep HL
  SUB (IX+OBJ_X)          ; Along x: H = +x (8) or -x (4), D = how far
  LD H,$08                ;
  JR NC,AIM_AT_0          ;
  NEG                     ;
  LD H,$04                ;
AIM_AT_0:
  LD D,A                  ;
  LD A,(IY+OBJ_Z)         ; Along z: L = +z ($40) or -z ($80)
  ADD A,$02               ;
  SUB (IX+OBJ_Z)          ;
  LD L,$40                ;
  JR NC,AIM_AT_1          ;
  NEG                     ;
  LD L,$80                ;
AIM_AT_1:
  CP D                    ; As far or further along z: head that way
  JR C,AIM_AT_2           ;
  LD D,A                  ;
  LD H,L                  ;
AIM_AT_2:
  CP $0E                  ; Near along z: look again in 3 passes
  JR NC,AIM_AT_3          ;
  LD (IX+OBJ_COUNT),$03   ;
AIM_AT_3:
  LD A,H                  ; A = the heading
  POP HL                  ;
  RET                     ;

; Test the mover's box, moved, against the record at IX only
;
; Used by the routine at MEET_DECOY.
;
; MEET_DECOY tries each axis of a blocked move against the one object the move
; ran into. C is holding the axes, so the mover's x length is taken from its
; working copy (IY+$6D) for the test and C given back after.
;
;   IX The record
;   B, D, H The mover's x, y and z, moved
;   E, L Its height and z length
; O:F Carry set if the boxes overlap
TEST_OTHER:
  PUSH BC
  LD C,(IY+REPEATS+$01-V)
  CALL TEST_ONE_RECORD
  POP BC
  RET

; Find a record whose box overlaps a given box
;
; Used by the routines at CREATURE_UPDATE, PICK_UP and ANIMATE_AND_MOVE.
;
; Walks the records in use from the last down to the first -- the six fixed
; ones at FIXED_RECORDS, the room's floor, ceiling and four walls, included --
; and stops at the first that overlaps the box, the mover's own record and
; hidden things aside (TEST_ONE_RECORD). Used for a move (ANIMATE_AND_MOVE),
; for the place a thing would be dropped (CREATURE_UPDATE), and by the pick-up
; (PICK_UP), which carries on down the list from NEXT_OBSTACLE
; (PICK_UP_LOOK_ON) until it finds a thing it can take.
;
; On the way it deals out the strike counters. IY+2 starts at $9E and goes down
; by one at each fighter (bit 7 of +12), but no lower than $98: the first six
; fighters from the top of the list have the counters at $9D down to $98 in
; STRIKES_LEFT, and any more share the last. The count depends only on the
; order of the records, so a fighter has the same counter for as long as the
; room lasts, and when a fighter is found IY+2 holds the low byte of its
; counter, for OBJECTS_MEET.
;
;   B, D, H x, y and z of the box (y its top)
;   C, E, L its x length, height and z length
; O:F Carry set if a record was found
; O:IX The record found; FOUND_RECORD its number
FIND_OBSTACLE:
  LD IX,(FREE_RECORD)     ; IX = the next free record
  LD A,(OBJECT_COUNT)      ; FOUND_RECORD counts down from the number of
  LD (IY+FOUND_RECORD-V),A ; records in use
  LD (IY+STRIKES_AT-V),$9E ; The strike counters from the top
  EXX                     ; DE' = minus 20; IX = the last record in use
  LD DE,$FFEC             ;
  ADD IX,DE               ;
FIND_OBSTACLE_0:
  EXX                     ; A fighter?
  BIT 7,(IX+OBJ_KIND)     ;
  JR Z,FIND_OBSTACLE_1    ;
  DEC (IY+STRIKES_AT-V)   ; The next counter down, the sixth at most
  LD A,(STRIKES_AT)       ;
  CP $98                  ;
  JR NC,FIND_OBSTACLE_1   ;
  INC (IY+STRIKES_AT-V)   ;
FIND_OBSTACLE_1:
  CALL TEST_ONE_RECORD    ; Overlapping: found
  RET C                   ;
; This entry point is used by the routine at PICK_UP_LOOK_ON.
NEXT_OBSTACLE:
  EXX                     ; NEXT_OBSTACLE: on down the list
  ADD IX,DE               ;
  DEC (IY+FOUND_RECORD-V) ;
  JR NZ,FIND_OBSTACLE_0   ;
  AND A                   ; None: carry clear
  EXX                     ;
  RET                     ;

; Test a box against one record, unless it is the mover's own or hidden
;
; Used by the routines at TEST_OTHER and FIND_OBSTACLE.
;
; A record counts unless it is the one being updated (FOUND_RECORD equal to
; THIS_RECORD), or has bit 5 of +16 set -- carried, or vanished -- when it is
; not a door. Doors always count.
;
; BOX_OVERLAP, the author's BB2, is the box test itself, used on its own by
; CHE3D and BUMPED. A box runs from a corner: from +6 for the length +9 along
; x, from +8 for +11 along z, and down from the top, +7, for the height +10.
; Two boxes overlap when they overlap along all three axes, each test strict,
; so boxes that only touch do not; each axis that does not overlap returns at
; once with the carry clear.
;
;   IX The record
;   B, D, H x, y and z of the box
;   C, E, L its x length, height and z length
; O:F Carry set if they overlap
TEST_ONE_RECORD:
  LD A,(FOUND_RECORD)     ; The mover's own record: no
  SUB (IY+THIS_RECORD-V)  ;
  RET Z                   ;
  LD A,(IX+OBJ_KIND)      ; A door: always
  AND $0F                 ;
  CP $01                  ;
  JR Z,BOX_OVERLAP        ;
  AND A                   ; Anything else, unless hidden
  BIT 5,(IX+OBJ_WEIGHT)   ;
  RET NZ                  ;
; This entry point is used by the routines at CHE3D and BUMPED.
BOX_OVERLAP:
  LD A,(IX+OBJ_Z)         ; BOX_OVERLAP: z -- the record's corner less the
  SUB H                   ; box's must lie between minus the record's length
  JR C,TEST_ONE_RECORD_0  ; and the box's
  SUB L                   ;
  RET NC                  ;
  JR TEST_ONE_RECORD_1    ;
TEST_ONE_RECORD_0:
  NEG                     ;
  SUB (IX+OBJ_LEN_Z)      ;
  RET NC                  ;
TEST_ONE_RECORD_1:
  LD A,(IX+OBJ_X)         ; x the same way
  SUB B                   ;
  JR C,TEST_ONE_RECORD_2  ;
  SUB C                   ;
  RET NC                  ;
  JR TEST_ONE_RECORD_3    ;
TEST_ONE_RECORD_2:
  NEG                     ;
  SUB (IX+OBJ_LEN_X)      ;
  RET NC                  ;
TEST_ONE_RECORD_3:
  LD A,(IX+OBJ_TOP)       ; y, from the tops down: the carry from the last
  SUB D                   ; subtraction is the answer
  JR C,TEST_ONE_RECORD_4  ;
  SUB (IX+OBJ_HEIGHT)     ;
  RET                     ;
TEST_ONE_RECORD_4:
  NEG                     ;
  SUB E                   ;
  RET                     ;

; Enter the room in ROOM, or end the quest (the author's ROOMST)
;
; Used by the routines at TITLE_SCREEN and BUMPED.
;
; Called by a new game (TITLE_SCREEN, at TELE) and jumped to from the door code
; (BUMPED) once the knight's record has its new place. It does not return until
; the game is over: the main loop (MAIN_LOOP) runs inside it and returns from
; it when LIFE is gone, or on SYMBOL SHIFT and 0, back to TITLE_SCREEN for GAME
; OVER. A door, and the thing that carries the knight off, come back in here
; with the stack as it was.
;
; Room 81 is the end of the quest. Its picture is drawn and the verdict
; printed: success if any of the five things carried is number 5 in the object
; table (+$13; the thing that lies in room 33), failure if not. An empty place
; reads as a record at address 0, whose +$13 is a ROM byte ($FF) and never
; matches. Then the two lines of MESS2, a key (WAIT), and back to GAME OVER.
;
; Any other room is entered at LOAD_ROOM (the author's ROS). First the carried
; things: their records, wherever the last room left them, are copied to the
; first places after the knight's, in the order of the five places, and each
; place is pointed at its record's new home. They go by way of BUFFER_D900, as
; one record may be moved onto another that has still to be copied. IY steps
; two bytes a place through the loop (the author's OBJD to OB2) so that IY+$1F
; and IY+$20 are each place in turn. OBJECT_COUNT becomes 7 and one for each
; thing carried; FREE_RECORD the next place. Then the room is drawn
; (DRAW_CURRENT_ROOM), which also makes the records of its objects, the six
; strike counters are set to 4, LIFE's label is printed, and the bare room is
; copied to the clean copy of the screen (RESTOR) before DRAW_STILL_THINGS
; draws the still things and starts the main loop.
ROOMST:
  LD DE,RECORDS           ; DE = the first record after the knight's: where the
                          ; carried things go
  LD A,(IY+ROOM-V)        ; Room 0 (room 10's hole): the game ends
  AND A                   ;
  RET Z                   ;
  CP $51                  ; Any room but 81: LOAD_ROOM
  JR NZ,LOAD_ROOM         ;
  CALL DRAW_CURRENT_ROOM  ; Draw room 81's picture and colour the screen; then
  CALL ATTRI              ; print the start of the verdict
  CALL PRINT
  DEFB $C8,$48,$78        ; Print at x 72, y 120
  DEFB $19,$0F,$15,$00,$08,$01,$16,$05 ; "YOU HAVE "
  DEFB $00                             ;
  DEFB $A4                ; End of the string
  LD HL,CARRIED
  LD B,$05
ROOMST_0:
  LD E,(HL)               ; IX = the record in this place
  INC HL                  ;
  LD D,(HL)               ;
  INC HL                  ;
  PUSH DE                 ;
  POP IX                  ;
  LD A,(IX+OBJ_NUMBER)    ; Number 5 in the object table: print success
  CP $05                  ;
  JR Z,ROOMST_1           ;
  DJNZ ROOMST_0           ; Try the next place; after the last, print failure
  CALL PRINT
  DEFB $06,$01,$09,$0C,$05,$04 ; "FAILED"
  DEFB $A4                ; End of the string
  JR ROOMST_2
ROOMST_1:
  CALL PRINT
  DEFB $13,$15,$03,$03,$05,$04,$05,$04 ; "SUCCEDED"
  DEFB $A4                ; End of the string
ROOMST_2:
  CALL PRINT
  DEFB $00,$09,$0E        ; " IN"
  DEFB $C8,$14,$64        ; Print at x 20, y 100
  DEFB $19,$0F,$15,$12,$00,$11,$15,$05 ; "YOUR QUEST THE WIZARD IS FREE"
  DEFB $13,$14,$00,$14,$08,$05,$00,$17 ;
  DEFB $09,$1A,$01,$12,$04,$00,$09,$13 ;
  DEFB $00,$06,$12,$05,$05             ;
  DEFB $A4                ; End of the string
  CALL MESS2
  JP WAIT                 ; Wait for a key, and return to the new game's code:
                          ; GAME OVER
LOAD_ROOM:
  LD (IY+OBJECT_COUNT-V),$07 ; LOAD_ROOM: seven records, the six fixed ones and
                             ; the knight's
  LD B,$05                ; Five places; the records gather in BUFFER_D900
  LD HL,BUFFER_D900       ; first, the pointer in POINT (the author's T)
  LD (POINT),HL           ;
ROOMST_3:
  LD L,(IY+$1F)           ; HL = the record in the next place, IY moved on two
  INC IY                  ;
  LD H,(IY+$1F)           ;
  INC IY                  ;
  LD A,L                  ;
  OR H                    ;
  JR Z,ROOMST_4           ;
  LD (IY+$1D),E           ; Point the place at DE, the record's new home
  LD (IY+$1E),D           ;
  PUSH BC                 ; DE on to the next home
  LD BC,$0014             ;
  EX DE,HL                ;
  ADD HL,BC               ;
  EX DE,HL                ;
  PUSH DE                 ; Copy the record's 20 bytes to the buffer
  LD DE,(POINT)           ;
  LDIR                    ;
  LD (POINT),DE           ;
  POP DE                  ;
  POP BC
  LD A,(OBJECT_COUNT)     ; One more record in use
  INC A                   ;
  LD (OBJECT_COUNT),A     ;
ROOMST_4:
  DJNZ ROOMST_3           ; Next place (the author's OB2)
  LD (FREE_RECORD),DE     ; The room's own records start after the carried
                          ; things
  LD DE,RECORDS           ; Copy the carried things into place (five records'
  LD HL,BUFFER_D900       ; worth, whatever was carried)
  LD BC,$0064             ;
  LDIR                    ;
  LD IY,OBJECT_COUNT      ; IY back on the variables
  CALL DRAW_CURRENT_ROOM  ; Draw the room and make its objects' records
  LD A,$04                ; Four strikes in each of the six counters; then
  LD HL,STRIKES_LEFT      ; print LIFE's label
  LD B,$06                ;
ROOMST_5:
  LD (HL),A               ;
  INC HL                  ;
  DJNZ ROOMST_5           ;
  CALL PRINT
  DEFB $C8,$30,$14        ; Print at x 48, y 20
  DEFB $0C,$09,$06,$05    ; "LIFE"
  DEFB $A4                ; End of the string
  CALL RESTOR
  LD HL,RECORDS             ; From the first record after the knight's, with
  LD (IY+THIS_RECORD-V),$07 ; bit 4 of GAME_FLAGS set: still things are drawn
  SET 4,(IY+GAME_FLAGS-V)   ; into the room
  JR DRAW_STILL_THINGS_1  ; Draw them (DRAW_STILL_THINGS)
; Room 0 returns at once, which ends the game: a new game's room comes from the
; master copy (MASTER_OBJECTS), where it is 29, but door record 185, a hole in
; room 10's floor, leads to room 0, so falling through it ends the game with
; LIFE still full (measured for the Facts page).

; Draw a room's doors and still things into its picture, and start the main
; loop
;
; Entered at its end from ROOMST, with HL at the first record after the
; knight's and THIS_RECORD at 7. Each record is drawn now, once, if it is a
; door or still: nothing in the low five bits of +16, a thing that never moves
; and that CHE3D never updates. With bit 4 of GAME_FLAGS set, REDRAW_OBJECT
; draws it among the other still things only. When all are done the screen is
; copied to the clean copy again (RESTOR), so from now on they are part of the
; room's picture, drawn again only where something passes in front of them.
;
; Then THINGS_NOTED is cleared and GAME_FLAGS set to 5 -- LIFE to be printed
; (bit 0) and the room's first pass (bit 2), everything else off, a freeze
; included -- and the main loop starts with its keys (MAIN_LOOP).
;
; HL The record
DRAW_STILL_THINGS:
  PUSH HL                 ; IX = the record; THIS_RECORD = its number
  POP IX                  ;
  INC (IY+THIS_RECORD-V)  ;
  LD A,(IX+OBJ_KIND)       ; A door: draw it
  AND $0F                  ;
  CP $01                   ;
  JR Z,DRAW_STILL_THINGS_0 ;
  LD A,(IX+OBJ_WEIGHT)    ; Anything else only if still
  AND $1F                 ;
DRAW_STILL_THINGS_0:
  PUSH HL                 ; Draw it (REDRAW_OBJECT)
  CALL Z,REDRAW_OBJECT    ;
  POP HL                  ;
  LD DE,$0014             ; Next record
  ADD HL,DE               ;
; This entry point is used by the routine at ROOMST.
DRAW_STILL_THINGS_1:
  LD A,(OBJECT_COUNT)     ; Until the last in use
  CP (IY+THIS_RECORD-V)   ;
  JR NZ,DRAW_STILL_THINGS ;
  CALL RESTOR             ; Copy the screen, still things and all, to the clean
                          ; copy
  LD (IY+THINGS_NOTED-V),$00 ; A new room's flags, and into the main loop
  LD (IY+GAME_FLAGS-V),$05   ;
  JR PASS_KEYS               ;

; The main loop: the keys between passes, LIFE, the message line and every
; object
;
; One pass is: the keys that are not the knight's own (walking, jumping,
; fighting, picking up and dropping are read in his update, CREATURE_UPDATE);
; LIFE printed if it has changed; the message line (SHOW_MESSAGE); and each
; record from the knight's, the seventh, to the last in use updated by the
; author's CHE3D (CHE3D). Nothing waits for the frame, so a pass takes as long
; as it takes. The author's source text, left on the tape, names the places
; from the use of a thing on: STAR2, USE6 to USE4, ST20 to ST22, STE3, ST3 to
; ST6 and ST9.
;
; The keys, in order. 9 turns the Kempston joystick on or off (bit 3 of
; OPTIONS), and waits until no key is held. After a room's first pass its
; colours are put on (ATTRI) -- it was drawn black on black -- so it appears
; all at once, and the thing in use is shown again. Then, unless the joystick
; is being pushed: SPACE and SYMBOL SHIFT together pause the game until a key
; is pressed; SYMBOL SHIFT and 0 together return from ROOMST, which ends the
; game; 6 or 7 use the thing in the chosen place; 1 to 5 choose a place and
; show what is in it.
;
; What using a thing does depends on its kind (+12). Kind 9 carries the knight
; off to room 30, to where a new game starts him (TELE, TITLE_SCREEN), after
; SAVE_OBJECT_POSITIONS has saved the room. Kind 6 makes LIFE 99. Kind 5
; freezes the room's creatures until he leaves it (bit 7 of GAME_FLAGS: CHE3D
; then lets everything but the knight only fall). Kind 4 adds 10 to LIFE, to no
; more than 99. Each of these is used up: its place is emptied, though its
; record stays among the room's, hidden, and its entry in the object table says
; room $FE; LIFE is printed again. A thing of any other kind does nothing.
;
; A pass ends with a RET when LIFE is 0: that returns from ROOMST to
; TITLE_SCREEN, which says GAME OVER.
MAIN_LOOP:
  LD A,$EF                ; Row 6 to 0: 9 held?
  CALL INPUT              ;
  RRA                     ;
  RRA                     ;
  JR NC,MAIN_LOOP_1       ;
  LD A,(OPTIONS)          ; Turn the joystick on or off
  XOR $08                 ;
  LD (OPTIONS),A          ;
MAIN_LOOP_0:
  XOR A                   ; Wait until no key is held
  CALL INPUT              ;
  JR NZ,MAIN_LOOP_0       ;
MAIN_LOOP_1:
  BIT 2,(IY+GAME_FLAGS-V) ; After the room's first pass (bit 2 of
  JR Z,PASS_KEYS          ; GAME_FLAGS)...
  CALL ATTRI              ; ...put the room's colours on, so it appears at
                          ; once...
  RES 2,(IY+GAME_FLAGS-V) ; ...and show the thing in use again
  LD A,(SELECTED)         ;
  JP SHOW_IN_USE          ;
; This entry point is used by the routine at DRAW_STILL_THINGS.
PASS_KEYS:
  CALL IN31               ; PASS_KEYS: the joystick pushed? Then no more keys
  JP NZ,START_PASS        ; this pass
  LD A,$7F                ; B = SPACE (bit 0) and SYMBOL SHIFT (bit 1)
  CALL INPUT              ;
  AND $03                 ;
  LD B,A                  ;
  CP $03                  ; Both: pause until a key (WAIT)
  CALL Z,WAIT             ;
  LD A,$EF                ; Row 6 to 0 again, 0 into the carry
  CALL INPUT              ;
  RRA                     ;
  JR NC,MAIN_LOOP_2       ;
  BIT 1,B                 ; 0 with SYMBOL SHIFT: return, ending the game
  RET NZ                  ;
MAIN_LOOP_2:
  AND $0C                 ; STAR2: 6 or 7 (now bits 3 and 2)? Use the thing in
  JR Z,MAIN_LOOP_8        ; the chosen place
  LD H,$FF                ; IX = its record (0 for an empty place: its +12 is a
  LD L,(IY+SELECTED-V)    ; ROM byte of kind 15, and nothing happens)
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  PUSH DE                 ;
  POP IX                  ;
  LD A,(IX+OBJ_KIND)      ; Kind 9?
  AND $0F                 ;
  CP $09                  ;
  JR NZ,MAIN_LOOP_3       ;
  LD (IY+ROOM-V),$1E      ; To room 30
  LD B,$00                ; Empty the place
  LD (HL),B               ;
  DEC HL                  ;
  LD (HL),B               ;
  CALL SAVE_OBJECT_POSITIONS ; Save the room's things (SAVE_OBJECT_POSITIONS)
  POP HL                  ; Drop the return to the new game's code, and go in
  JP TELE                 ; as a new game does (TELE)
MAIN_LOOP_3:
  CP $06                  ; USE6: kind 6, LIFE 99
  JR NZ,MAIN_LOOP_4       ;
  LD DE,$0909             ;
  LD (LIFE_TENS),DE       ;
  JR MAIN_LOOP_7          ;
MAIN_LOOP_4:
  CP $05                  ; USE5: kind 5, freeze the creatures
  JR NZ,MAIN_LOOP_5       ;
  SET 7,(IY+GAME_FLAGS-V) ;
  JR MAIN_LOOP_7          ;
MAIN_LOOP_5:
  CP $04                  ; USE4: kind 4, LIFE's tens up one...
  JR NZ,MAIN_LOOP_8       ;
  LD A,(LIFE_TENS)        ;
  INC A                   ;
  CP $0A                  ;
  JR NC,MAIN_LOOP_6       ;
  LD (LIFE_TENS),A        ;
  JR MAIN_LOOP_7          ;
MAIN_LOOP_6:
  LD (IY+LIFE_UNITS-V),$09 ; ...or at 9 tens already, 99 (ST21)
MAIN_LOOP_7:
  LD A,(SELECTED)         ; ST22: used up -- LIFE to be printed, the place
  SET 0,(IY+GAME_FLAGS-V) ; emptied, and shown empty
  LD (HL),$00             ;
  DEC HL                  ;
  LD (HL),$00             ;
  JR SHOW_IN_USE          ;
MAIN_LOOP_8:
  LD A,$F7                ; ST20: row 1 to 5; nothing held, on to the pass
  CALL INPUT              ;
  JR Z,START_PASS         ;
  LD B,$05                ; C = 1, 3, 5, 7 or 9 for keys 1 to 5
  LD C,$FF                ;
MAIN_LOOP_9:
  INC C                   ;
  INC C                   ;
  RRA                     ;
  JR C,MAIN_LOOP_10       ;
  DJNZ MAIN_LOOP_9        ;
MAIN_LOOP_10:
  LD A,$9E                ; The place ($9F to $A7); the one in use already:
  ADD A,C                 ; nothing to do
  CP (IY+SELECTED-V)      ;
  JR Z,START_PASS         ;
  LD (IY+SELECTED-V),A    ; Choose it
SHOW_IN_USE:
  LD H,$FF                ; SHOW_IN_USE (STE3): HL = the record in the place
  LD L,A                  ;
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  EX DE,HL                ;
  LD A,H                  ;
  OR L                    ;
  JR NZ,MAIN_LOOP_11      ;
  CALL CLEAR_THING_BOX    ; Empty: clear the box and show the place's number
  JR START_PASS           ; (CLEAR_THING_BOX)
MAIN_LOOP_11:
  CALL SHOW_THING_IN_USE  ; Show the thing (SHOW_THING_IN_USE)
START_PASS:
  BIT 0,(IY+GAME_FLAGS-V) ; START_PASS (ST3): LIFE changed (bit 0 of
  JR Z,MAIN_LOOP_12       ; GAME_FLAGS)? Then move the printer to x 55, y 12
  RES 0,(IY+GAME_FLAGS-V) ;
  CALL PRINT
  DEFB $C8,$37,$0C        ; Print at x 55, y 12
  DEFB $A4                ; End of the string
  LD A,(LIFE_TENS)
  ADD A,$1B
  CALL PRINT_CHAR
  LD A,(LIFE_UNITS)
  ADD A,$1B
  CALL PRINT_CHAR
MAIN_LOOP_12:
  CALL SHOW_MESSAGE       ; The message line (SHOW_MESSAGE, at ST9)
  LD HL,KNIGHT              ; From the knight's record, the seventh
  LD (IY+THIS_RECORD-V),$07 ;
  LD A,(LIFE_TENS)        ; LIFE 0: return from ROOMST, the game over
  OR (IY+LIFE_UNITS-V)    ;
  RET Z                   ;
MAIN_LOOP_13:
  PUSH HL                 ; Update this object (CHE3D)
  CALL CHE3D              ;
  POP HL                  ;
  LD A,(THIS_RECORD)      ; The last in use done: next pass
  INC (IY+THIS_RECORD-V)  ;
  CP (IY+OBJECT_COUNT-V)  ;
  JP Z,MAIN_LOOP          ;
  LD DE,$0014             ; Next record
  ADD HL,DE               ;
  JR MAIN_LOOP_13         ;

; Leftover characters
;
; Bits of the ROM's user-defined graphics as the tape's maker left them: the
; ends of the letters C, D and E, which the ROM puts at the top of memory when
; it starts. The game never reads them. More of the same lie among the
; variables above, where the game does not use the bytes.
UDG_LEFTOVERS:
  DEFB $42,$40,$40,$42,$3C,$00,$00,$78
  DEFB $44,$42,$42,$44,$78,$00,$00,$7E
  DEFB $40,$7C,$40,$40,$7E,$00

; The game's variables
;
; IY holds OBJECT_COUNT throughout the game, so most of these are reached as
; IY+n: the author's source text calls this base V, as in (V+3), and the
; listing writes each such access the same way, as the variable less V:
; (IY+ROOM-V) is ROOM, and V is an EQU at the top of the source file. Only two
; places move IY: ZOOMIN (ZOOMIN) points it at a chaser's target for a moment,
; and ROOMST steps it through the carried things. On the tape the first 61
; bytes, up to OBJECTS_PLACED, hold the values a game starts with; the start-up
; copies them to the master copy (MASTER_OBJECTS) and a new game copies them
; back. The rest are set before they are read; on the tape many hold the ends
; of the ROM's user-defined graphics, like UDG_LEFTOVERS.
;
; From POINT up the bytes have several lives, one at a time. While a room is
; drawn they are the drawing's state, twenty of them (from ORIGIN) reset from
; ROOM_DEFAULTS for each room. While an object is updated (CHE3D), POINT to
; WORK_HEADING are a copy of its record's first 19 bytes -- the author's T, as
; in (T+13) -- so that IY+$64 is the record's +0, IY+$6A its x (+6), IY+$6B its
; y (+7), IY+$6C its z (+8), IY+$70 its kind (+12) and so on; FOUND_RECORD
; (T+20), STEP_AXES, ASKED_DIRECTION, WORK_RECORD and RIDE_DIRECTION go with
; them. While a sprite is drawn (REDRAW_OBJECT) the same bytes hold the
; rectangle being redrawn, from a copy of +0 to +11, and the drawing's
; counters; and DRAW_LIST, lower down, takes a list of 30 bytes that runs over
; the printer's and the room drawing's bytes. Each use sets what it reads
; first.
;
; The labels are for the use the object code makes of a byte where it reads it
; by address, and for the drawing's otherwise.
OBJECT_COUNT:
  DEFB $00                ; Records in use, counted from FIXED_RECORDS: the six
                          ; fixed ones, the knight's (7), then the carried
                          ; things' and the room's
  DEFB $02                ; Not used
STRIKES_AT:
  DEFB $0B                ; The low byte of the strike counter of the fighter
                          ; FIND_OBSTACLE last passed ($98 to $9D)
THIS_RECORD:
  DEFB $00                ; The number of the record being updated or drawn,
                          ; counted from FIXED_RECORDS (the knight is 7)
  DEFB $80                ; Not used
GRAVITY:
  DEFB $23                ; $23, never written: its top six bits are ORed into
                          ; the direction of a thing not rising -- bit 5, down
                          ; (ANIMATE_AND_MOVE)
OPTIONS:
  DEFB $10                ; Bit 3: the Kempston joystick is in use (9 turns it
                          ; on and off)
MESSAGE:
  DEFB $00                ; The message SHOW_MESSAGE is to show: 1 BLOCKED, 2
                          ; LOCKED, 3 TOO HEAVY; 0 none
MESSAGE_TIMER:
  DEFB $00                ; MESSAGE_TIMER: passes the message stays up (10).
  DEFB $00                ; Then two bytes not used; NO_RISE_MASK
  DEFB $00                ; (IY+NO_RISE_MASK-V), $EF and never written: ANDed
NO_RISE_MASK:
  DEFB $EF                ; with the direction of a thing not rising, it takes
  DEFB $00                ; out bit 4, up (ANIMATE_AND_MOVE); and two more not
  DEFB $00                ; used
ROOM_COLOUR:
  DEFB $00                ; The room's colour, from its first byte
DECOY:
  DEFB $00,$00            ; The record of a decoy (kind 8) in the room, noted
                          ; by CHE3D for the guards of behaviour 9
THINGS_NOTED:
  DEFB $00                ; Bit 0: a decoy is in the room (DECOY); bit 1: a
                          ; thing of kind 11 is, which wakes the creature of
                          ; behaviour 15 and lets the doors of room 61 be used
                          ; (CHE3D, BUMPED)
CARRIED_WEIGHT:
  DEFB $00                ; The weight of what is carried; 8 or more is too
                          ; heavy
  DEFB $00                ; Not used; then FALL_COUNT (IY+FALL_COUNT-V), the
FALL_COUNT:
  DEFB $00                ; passes the knight has been falling: each over 20
                          ; costs 1 LIFE when he lands (CREATURE_UPDATE;
                          ; measured in the simulator)
LIFE_TENS:
  DEFB $09                ; LIFE: the tens
LIFE_UNITS:
  DEFB $09                ; LIFE: the units
GAME_FLAGS:
  DEFB $00                ; Bit 0: LIFE to be printed; 1: the knight's sword
                          ; out; 2: the room's first pass; 3: the knight's idle
                          ; pose; 4: still things being drawn into the room; 6:
                          ; a message showing; 7: the creatures frozen
STRIKES_LEFT:
  DEFB $00,$3E,$08,$08,$08,$08 ; Six fighters' strikes left, 4 each when a room
                               ; is entered (FIND_OBSTACLE deals them out)
SELECTED:
  DEFB $9F                ; The low byte of the word in CARRIED for the thing
                          ; in use ($9F to $A7)
CARRIED:
  DEFB $00,$00            ; The records of the five things carried
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $00,$00            ;
  DEFB $44,$48,$70,$48,$44,$42,$00,$00 ; Not used
  DEFB $40,$00,$00        ; Not used
ROOM:
  DEFB $1D                ; The room the knight is in
PARTS_TABLE:
  DEFB $8C,$75            ; Where the parts are (PART1)
  DEFB $00                ; Not used
FREE_RECORD:
  DEFB $00,$00            ; The next free object record
OBJECT_TABLE_AT:
  DEFB $24,$A9            ; Where the object table is (OBJECTS)
OBJECTS_PLACED:
  DEFB $42                ; Bit 0: the object table's things have been placed
  DEFB $42                ; in this room (room code $E4, MORE_ROOM_COMMANDS);
  DEFB $42                ; the rest not used
  DEFB $00                ;
  DEFB $00                ;
  DEFB $42                ;
  DEFB $62                ;
  DEFB $52                ;
  DEFB $4A,$46            ; Not used
DRAW_LIST:
  DEFB $42                ; 30 bytes to the end of AWAY_FRAMES: the numbers of
                          ; the records to draw, in order, copied from
                          ; BUFFER_DA00 by SORT_AND_DRAW_BEHIND
  DEFB $00,$00,$3C,$42    ; More of DRAW_LIST
ARRIVAL_BOX:
  DEFB $42,$42,$42,$3C,$00 ; The door code (BUMPED) points IX here, so that a
                           ; record's +5 to +11 are PRINT_X and the six bytes
                           ; after it: the box of a door's far side
PRINT_X:
  DEFB $00                ; Where the next character is printed: x
PRINT_Y:
  DEFB $7C                ; And y
  DEFB $42,$42,$7C,$40,$40,$00,$00,$3C ; The rest of ARRIVAL_BOX, and more of
                                       ; DRAW_LIST
PLACED_TYPE:
  DEFB $42                ; The type of the object being placed (PLACE_OBJECT)
PLACED_NUMBER:
  DEFB $42                ; Counts the object table's entries as
                          ; PLACE_ROOM_OBJECTS walks it: the number it gives a
                          ; record at +$13 (it wraps round after 255)
  DEFB $52,$4A,$3C        ; More of DRAW_LIST
ORIGIN:
  DEFB $00                ; Added to x (+6) of each object the room places
                          ; (IY+$5F-$61; room code $E4 $05)
ORIGIN_Y:
  DEFB $00                ; Added to its y, the height (+7)
ORIGIN_Z:
  DEFB $7C                ; Added to its z (+8)
AWAY_FRAMES:
  DEFB $42,$42            ; How far the knight's frames for walking away (+x or
                          ; +z) lie beyond those for walking towards the
                          ; viewer, set just before FACING adds it
POINT:
  DEFB $7C                ; The room drawing's first point: column. While an
                          ; object is updated, its +0; in ROOMST, where the
                          ; next carried record goes
POINT_ROW:
  DEFB $44                ; And row. While an object is updated, its +1
SECOND_POINT:
  DEFB $42                ; The second point: column. While an object is
                          ; updated, its +2
SECOND_POINT_ROW:
  DEFB $00                ; And row. While an object is updated, its +14 as it
                          ; was when the update began (CHE3D)
WORK_SPRITE:
  DEFB $00                ; While an object is updated or drawn, its sprite
                          ; (+4, +5, a word); zero, and the byte the screen is
                          ; cleared with, when a room is drawn
                          ; (CLEAR_ROOM_SCREEN)
  DEFB $3C                ; The sprite's high byte; then LINE_PAGE
LINE_PAGE:
  DEFB $40                ; (IY+LINE_PAGE-V): 0 to draw a room's lines on the
                          ; screen, $80 in the clean copy (room code $E4), and
                          ; while an object is updated, its x (+6)
MODE:
  DEFB $3C                ; The room drawing's mode bits (room codes $C1-$CE,
                          ; $E4 $04); while an object is updated, its y (+7)
REPEATS:
  DEFB $02                ; How many times the room drawing repeats (room code
                          ; $D5); while an object is updated, its z (+8)
  DEFB $42                ; Kept with REPEATS by room code $E1; while an object
                          ; is updated, its x length (+9)
REPEAT_FROM:
  DEFB $3C,$00            ; Where the repeat goes back to; while an object is
                          ; updated, its height and z length (+10, +11)
WORK_KIND:
  DEFB $00                ; While an object is updated, its kind byte (+12)
WORK_DIRECTION:
  DEFB $FE                ; Its direction (+13): 0 bounces, 1 rises, 2 -x, 3
                          ; +x, 4 up, 5 down, 6 +z, 7 -z; the sprite drawing's
                          ; flags
WORK_BEHAVIOUR:
  DEFB $10                ; Its behaviour byte (+14)
DRAW_WIDTH:
  DEFB $10                ; A sprite's width in bytes, while it is drawn; while
                          ; an object is updated, its timer (+15)
WORK_WEIGHT:
  DEFB $10                ; Its +16: 16 more than its weight, 0 if still; the
                          ; length of the draw list while sprites are drawn
WORK_ANIMATION:
  DEFB $10                ; Its animation byte (+17); rows, while a sprite is
                          ; drawn
WORK_HEADING:
  DEFB $10,$00            ; Its heading (+18); SP while CLEAR_512_BELOW borrows
                          ; it; the fill's pointer to the row below
FOUND_RECORD:
  DEFB $00                ; The number of the record FIND_OBSTACLE found (the
                          ; author's T+20); SP while CLEAR_ROOM_SCREEN borrows
                          ; it; the fill's texture; a sprite row's bytes
                          ; (DRAW_SPRITE)
DRAW_INDEX:
  DEFB $42                ; The record REDRAW_OBJECT is looking at
CLEAR_END:
  DEFB $42                ; Where CLEAR_ROOM_SCREEN's clearing stopped
STEP_AXES:
  DEFB $42                ; A move's axes: bit 0 x, 1 y, 2 z; 5 landed, 6 a
                          ; climb, 7 into a door; the fill's pointer to this
                          ; row
ASKED_DIRECTION:
  DEFB $42                ; The direction a move asked for, before collisions
                          ; changed it
WORK_RECORD:
  DEFB $42                ; The record being updated; the fill's pointer to the
                          ; row above
DRAW_COUNT:
  DEFB $3C                ; Counts down the draw list; the high byte of
                          ; WORK_RECORD
RIDE_DIRECTION:
  DEFB $00                ; The direction of what the mover has landed on; the
                          ; last entry in the draw list at BUFFER_DA00 ($FF:
                          ; none)

