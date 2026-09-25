    DEVICE ZXSPECTRUM48
PLAYER EQU $EA90
PLAYER_ROOM EQU $EA91
PLAYER_FLAG EQU $EA92
PLAYER_X EQU $EA93
PLAYER_Y EQU $EA94
PLAYER_MODE EQU $EA95
PLAYER_DX EQU $EA96
PLAYER_DY EQU $EA97
WEAPON EQU $EA98
WEAPON_ROOM EQU $EA99
WEAPON_HIT EQU $EA9A
WEAPON_X EQU $EA9B
WEAPON_Y EQU $EA9C
WEAPON_DX EQU $EA9E
WEAPON_DY EQU $EA9F
SOUND_SLOT EQU $EAA0
LIVE_OBJECTS EQU $EAA8
LIVE_RED_KEY EQU $EAC8
LIVE_COLLECTABLE_80 EQU $EAE0
LIVE_DROP_SLOTS EQU $EAE8
LIVE_COLLECTABLES EQU $EB18
LIVE_FOOD EQU $EB58
LIVE_MUSHROOMS EQU $EDD8
MOVE_ROOM EQU $EE59
LIVE_MONSTERS EQU $EE60
LIVE_DOORS EQU $EEE0
FRAMES EQU $5C78
FRAMES_HIGH EQU $5C79
JP_HL_POKE EQU $5CB0
SELECTION EQU $5E00
TILE_SOURCE EQU $5E01
LAST_FRAME EQU $5E03
IN_FRAME EQU $5E04
RUNNING_SUM EQU $5E05
DRAW_WIDTH EQU $5E10
DRAW_SHIFT EQU $5E11
TICKS EQU $5E12
TICKS_HIGH EQU $5E13
ROOM_DRAWN EQU $5E14
WORK_SPRITE EQU $5E15
WORK_X EQU $5E16
WORK_Y EQU $5E17
CLIP_COUNT EQU $5E18
CLIP_LIMIT EQU $5E19
ROOM_COLOUR EQU $5E1A
LIST_POINTER EQU $5E1B
ROOM_HALF_WIDTH EQU $5E1D
ROOM_HALF_HEIGHT EQU $5E1E
CARRYING EQU $5E1F
PICKUP_KEY EQU $5E20
LIVES EQU $5E21
MENU_COLOUR EQU $5E22
LINE_WORK EQU $5E23
LINE_WORK_NEXT EQU $5E24
ACTORS_HERE EQU $5E25
SPAWN_ROOM EQU $5E26
SPAWN_COUNTDOWN EQU $5E27
FOOD_LEVEL EQU $5E28
FOOD_DRAWN EQU $5E29
SCORE EQU $5E2A
SCORE_LOW EQU $5E2C
FIRE_BLOCKED EQU $5E2D
DOOR_WAIT EQU $5E2E
STEP_COUNTER EQU $5E2F
CARRIED EQU $5E30
CARRIED_SPRITE EQU $5E32
THIRD_SLOT EQU $5E38
FLASH_COUNT EQU $5E3C
CLOCK EQU $5E3D
CLOCK_SECONDS EQU $5E3F
ROOMS_SEEN EQU $5E40
ROOMS_EXPLORED EQU $5E54
CURSOR EQU $5E55

  ORG $6000

; Entry point, and the second half of the tape protection
;
; The 18-byte decryptor at $5B80 (in the printer buffer, entered by the
; loader's PRINT USR 23424) RRDs a nibble through the whole game block and then
; jumps here.
;
; This is where the tape's third trick pays off. One of the tiny CODE blocks
; pokes $255E into FRAMES at $5C78 for no reason a normal loader would have;
; the check below is the reason. A cracked loader that drops the little blocks,
; or anything that lets an interrupt tick FRAMES on before arriving here, fails
; the compare and falls straight back to BASIC with no error -- the game simply
; does not start.
;
; A FRAMES+1, which must still hold $25
ENTRY:
  DI
  LD SP,$5E00             ; Well below the game block at $5FFF, so the stack
                          ; cannot walk into the code.
  LD A,(FRAMES_HIGH)      ; FRAMES+1. Interrupts are off from the DI above, so
                          ; this still holds what the tape poked.
  CP $25
  RET NZ                  ; Not a failure path with a message -- just RET,
                          ; straight back to the BASIC that called USR.
  JP TITLE_SCREEN         ; The real entry point.

; Every record in the game, before anything has happened
;
; The 5488 bytes LOAD_INITIAL_STATE copies to $EA90 -- which is to say the
; whole of the runtime area, $EA90 to the top of memory, written out in full
; and moved into place with one LDIR. Nothing is built at run time; the castle
; is simply copied.
;
; It is laid out exactly as the running game reads it, in the four regions
; MAIN_LOOP and FRAME_TICK walk. The bytes below are grouped one record to a
; line.
;
; What is in it, read out of the data: three empty records for the player, the
; weapon and the sound slot, which are filled in when a game starts rather than
; here; 115 objects of the 119 slots, among them sixteen mushrooms and ten each
; of the six kinds of food; five monsters, one each of the mummy, Dracula, the
; devil, Frankenstein's monster and the humpback; and 274 sixteen-byte records
; for the doors and the furniture.
;
; The doors are the surprise. Every one is sixteen bytes, not eight -- one
; record holding both of its sides -- which is why DOOR_OTHER_SIDE flips bit 3
; of an address: it is moving between the two halves of a single record. The
; last region is 274 of these sixteen-byte records: 205 doors, and 69 pairs of
; pieces of furniture, one in each of two rooms, stored the same way though
; nothing ever crosses between them -- 36 of the pairs are not even the same
; piece. A record's type byte says which (see DOOR_KINDS in build_aticatac.py):
; its handler, found by DISPATCH_FROM_LIST, is a door routine for a door and
; DRAW_DOOR, the draw-only tail of DOOR, for furniture. Each room's list names
; the records that are in it; the objects and monsters it names nowhere,
; finding them by their own room byte.
INITIAL_STATE:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The player: filled in when a game
                                       ; starts
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The player's weapon: filled in when
                                       ; one is thrown
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; The sound slot: filled in when a sound
                                       ; plays
ACG_KEY_PARTS:
  DEFB $8C,$00,$00,$58,$58,$46,$00,$00 ; A.C.G. key, piece 1: in room $00 at
                                       ; 88,88
  DEFB $8D,$00,$00,$58,$58,$46,$00,$00 ; A.C.G. key, piece 2: in room $00 at
                                       ; 88,88
  DEFB $8E,$00,$00,$58,$58,$46,$00,$00 ; A.C.G. key, piece 3: in room $00 at
                                       ; 88,88
GREEN_KEY:
  DEFB $81,$05,$00,$70,$60,$44,$00,$00 ; Key: in room $05 at 112,96
RED_KEY:
  DEFB $81,$17,$00,$80,$40,$42,$00,$00 ; Key: in room $17 at 128,64
CYAN_KEY:
  DEFB $81,$53,$00,$58,$58,$45,$00,$00 ; Key: in room $53 at 88,88
YELLOW_KEY:
  DEFB $81,$66,$00,$30,$87,$46,$00,$00 ; Key: in room $66 at 48,135
COLLECTABLE_80:
  DEFB $80,$09,$00,$40,$40,$42,$00,$00 ; Collectable $80: in room $09 at 64,64
DROP_SLOTS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty object slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty object slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty object slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty object slot
  DEFB $8A,$05,$00,$40,$70,$46,$00,$00 ; Collectable $8A: in room $05 at 64,112
  DEFB $8B,$30,$00,$40,$70,$45,$00,$00 ; Collectable $8B: in room $30 at 64,112
COLLECTABLES:
  DEFB $82,$3B,$00,$60,$60,$44,$00,$00 ; Collectable $82: in room $3B at 96,96
  DEFB $83,$48,$00,$70,$70,$45,$00,$00 ; Collectable $83: in room $48 at
                                       ; 112,112
  DEFB $84,$64,$00,$80,$80,$46,$00,$00 ; Collectable $84: in room $64 at
                                       ; 128,128
  DEFB $85,$6B,$00,$40,$40,$45,$00,$00 ; Collectable $85: in room $6B at 64,64
  DEFB $86,$13,$00,$50,$50,$44,$00,$00 ; Collectable $86: in room $13 at 80,80
  DEFB $87,$84,$00,$60,$40,$43,$00,$00 ; Collectable $87: in room $84 at 96,64
  DEFB $88,$1F,$00,$70,$70,$42,$00,$00 ; Collectable $88: in room $1F at
                                       ; 112,112
  DEFB $89,$49,$00,$50,$40,$47,$00,$00 ; Collectable $89: in room $49 at 80,64
FOOD:
  DEFB $50,$27,$00,$57,$67,$43,$00,$00 ; Food: in room $27 at 87,103
  DEFB $50,$7F,$00,$40,$40,$46,$00,$00 ; Food: in room $7F at 64,64
  DEFB $50,$1E,$00,$50,$57,$46,$00,$00 ; Food: in room $1E at 80,87
  DEFB $50,$0C,$00,$60,$60,$43,$00,$00 ; Food: in room $0C at 96,96
  DEFB $50,$67,$00,$57,$40,$42,$00,$00 ; Food: in room $67 at 87,64
  DEFB $50,$41,$00,$57,$67,$42,$00,$00 ; Food: in room $41 at 87,103
  DEFB $51,$75,$00,$30,$40,$44,$00,$00 ; Food: in room $75 at 48,64
  DEFB $51,$83,$00,$30,$40,$46,$00,$00 ; Food: in room $83 at 48,64
  DEFB $51,$0C,$00,$60,$70,$42,$00,$00 ; Food: in room $0C at 96,112
  DEFB $51,$68,$00,$57,$40,$43,$00,$00 ; Food: in room $68 at 87,64
  DEFB $51,$45,$00,$57,$46,$45,$00,$00 ; Food: in room $45 at 87,70
  DEFB $51,$46,$00,$43,$7B,$45,$00,$00 ; Food: in room $46 at 67,123
  DEFB $52,$86,$00,$47,$60,$43,$00,$00 ; Food: in room $86 at 71,96
  DEFB $52,$6E,$00,$60,$77,$42,$00,$00 ; Food: in room $6E at 96,119
  DEFB $52,$7D,$00,$57,$67,$43,$00,$00 ; Food: in room $7D at 87,103
  DEFB $52,$6A,$00,$30,$67,$42,$00,$00 ; Food: in room $6A at 48,103
  DEFB $52,$3E,$00,$43,$7B,$42,$00,$00 ; Food: in room $3E at 67,123
  DEFB $52,$35,$00,$57,$67,$43,$00,$00 ; Food: in room $35 at 87,103
  DEFB $53,$2B,$00,$40,$80,$46,$00,$00 ; Food: in room $2B at 64,128
  DEFB $53,$8A,$00,$57,$67,$45,$00,$00 ; Food: in room $8A at 87,103
  DEFB $53,$09,$00,$80,$90,$44,$00,$00 ; Food: in room $09 at 128,144
  DEFB $53,$70,$00,$80,$90,$43,$00,$00 ; Food: in room $70 at 128,144
  DEFB $53,$74,$00,$57,$87,$42,$00,$00 ; Food: in room $74 at 87,135
  DEFB $53,$33,$00,$57,$67,$45,$00,$00 ; Food: in room $33 at 87,103
  DEFB $54,$78,$00,$37,$37,$47,$00,$00 ; Food: in room $78 at 55,55
  DEFB $54,$8A,$00,$7F,$7F,$47,$00,$00 ; Food: in room $8A at 127,127
  DEFB $54,$0B,$00,$57,$67,$46,$00,$00 ; Food: in room $0B at 87,103
  DEFB $54,$65,$00,$57,$87,$46,$00,$00 ; Food: in room $65 at 87,135
  DEFB $54,$53,$00,$43,$7B,$47,$00,$00 ; Food: in room $53 at 67,123
  DEFB $54,$4C,$00,$6B,$7B,$46,$00,$00 ; Food: in room $4C at 107,123
  DEFB $55,$7B,$00,$50,$60,$45,$00,$00 ; Food: in room $7B at 80,96
  DEFB $55,$87,$00,$57,$67,$45,$00,$00 ; Food: in room $87 at 87,103
  DEFB $55,$0D,$00,$30,$67,$43,$00,$00 ; Food: in room $0D at 48,103
  DEFB $55,$66,$00,$43,$87,$43,$00,$00 ; Food: in room $66 at 67,135
  DEFB $55,$53,$00,$6B,$7B,$42,$00,$00 ; Food: in room $53 at 107,123
  DEFB $55,$4F,$00,$57,$67,$47,$00,$00 ; Food: in room $4F at 87,103
  DEFB $56,$7E,$00,$37,$80,$44,$00,$00 ; Food: in room $7E at 55,128
  DEFB $56,$8C,$00,$57,$67,$44,$00,$00 ; Food: in room $8C at 87,103
  DEFB $56,$70,$00,$30,$90,$44,$00,$00 ; Food: in room $70 at 48,144
  DEFB $56,$66,$00,$6B,$87,$44,$00,$00 ; Food: in room $66 at 107,135
  DEFB $56,$3C,$00,$43,$7B,$42,$00,$00 ; Food: in room $3C at 67,123
  DEFB $56,$39,$00,$43,$7B,$42,$00,$00 ; Food: in room $39 at 67,123
  DEFB $57,$7E,$00,$87,$80,$47,$00,$00 ; Food: in room $7E at 135,128
  DEFB $57,$24,$00,$60,$70,$47,$00,$00 ; Food: in room $24 at 96,112
  DEFB $57,$70,$00,$57,$90,$47,$00,$00 ; Food: in room $70 at 87,144
  DEFB $57,$12,$00,$57,$40,$47,$00,$00 ; Food: in room $12 at 87,64
  DEFB $57,$5E,$00,$57,$67,$47,$00,$00 ; Food: in room $5E at 87,103
  DEFB $57,$1D,$00,$30,$67,$47,$00,$00 ; Food: in room $1D at 48,103
  DEFB $50,$17,$00,$40,$40,$42,$00,$00 ; Food: in room $17 at 64,64
  DEFB $50,$73,$00,$30,$67,$42,$00,$00 ; Food: in room $73 at 48,103
  DEFB $50,$07,$00,$57,$67,$43,$00,$00 ; Food: in room $07 at 87,103
  DEFB $50,$02,$00,$57,$67,$43,$00,$00 ; Food: in room $02 at 87,103
  DEFB $51,$0F,$00,$57,$67,$43,$00,$00 ; Food: in room $0F at 87,103
  DEFB $51,$3A,$00,$30,$48,$43,$00,$00 ; Food: in room $3A at 48,72
  DEFB $51,$41,$00,$80,$67,$42,$00,$00 ; Food: in room $41 at 128,103
  DEFB $51,$85,$00,$43,$7B,$42,$00,$00 ; Food: in room $85 at 67,123
  DEFB $52,$6C,$00,$57,$47,$43,$00,$00 ; Food: in room $6C at 87,71
  DEFB $52,$3A,$00,$57,$48,$43,$00,$00 ; Food: in room $3A at 87,72
  DEFB $52,$69,$00,$30,$40,$03,$00,$00 ; Food: in room $69 at 48,64
  DEFB $52,$80,$00,$30,$40,$03,$00,$00 ; Food: in room $80 at 48,64
  DEFB $53,$04,$00,$57,$67,$42,$00,$00 ; Food: in room $04 at 87,103
  DEFB $53,$4B,$00,$30,$88,$42,$00,$00 ; Food: in room $4B at 48,136
  DEFB $53,$11,$00,$57,$67,$46,$00,$00 ; Food: in room $11 at 87,103
  DEFB $53,$80,$00,$57,$40,$44,$00,$00 ; Food: in room $80 at 87,64
  DEFB $54,$69,$00,$30,$67,$46,$00,$00 ; Food: in room $69 at 48,103
  DEFB $54,$35,$00,$57,$90,$46,$00,$00 ; Food: in room $35 at 87,144
  DEFB $54,$69,$00,$30,$90,$46,$00,$00 ; Food: in room $69 at 48,144
  DEFB $54,$80,$00,$80,$80,$44,$00,$00 ; Food: in room $80 at 128,128
  DEFB $55,$57,$00,$57,$40,$46,$00,$00 ; Food: in room $57 at 87,64
  DEFB $55,$35,$00,$57,$40,$46,$00,$00 ; Food: in room $35 at 87,64
  DEFB $55,$25,$00,$6B,$7B,$43,$00,$00 ; Food: in room $25 at 107,123
  DEFB $55,$1B,$00,$57,$67,$44,$00,$00 ; Food: in room $1B at 87,103
  DEFB $56,$58,$00,$57,$40,$44,$00,$00 ; Food: in room $58 at 87,64
  DEFB $56,$4E,$00,$67,$40,$42,$00,$00 ; Food: in room $4E at 103,64
  DEFB $56,$37,$00,$57,$67,$46,$00,$00 ; Food: in room $37 at 87,103
  DEFB $56,$85,$00,$6B,$7B,$44,$00,$00 ; Food: in room $85 at 107,123
  DEFB $57,$5B,$00,$57,$67,$47,$00,$00 ; Food: in room $5B at 87,103
  DEFB $57,$4E,$00,$40,$67,$47,$00,$00 ; Food: in room $4E at 64,103
  DEFB $57,$49,$00,$57,$67,$47,$00,$00 ; Food: in room $49 at 87,103
  DEFB $57,$28,$00,$57,$67,$47,$00,$00 ; Food: in room $28 at 87,103
MUSHROOMS:
  DEFB $A1,$50,$00,$57,$40,$42,$00,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $50 at 87,64
  DEFB $A1,$43,$00,$6B,$54,$42,$01,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $43 at 107,84
  DEFB $A1,$40,$00,$43,$7B,$42,$02,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $40 at 67,123
  DEFB $A1,$8F,$00,$57,$8F,$42,$03,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $8F at 87,143
  DEFB $A1,$8F,$00,$43,$7B,$42,$04,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $8F at 67,123
  DEFB $A1,$8F,$00,$6B,$7B,$42,$05,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $8F at 107,123
  DEFB $A1,$45,$00,$80,$67,$42,$06,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $45 at 128,103
  DEFB $A1,$38,$00,$6B,$54,$42,$07,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $38 at 107,84
  DEFB $A1,$74,$00,$30,$40,$42,$06,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $74 at 48,64
  DEFB $A1,$74,$00,$30,$88,$42,$05,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $74 at 48,136
  DEFB $A1,$74,$00,$78,$88,$42,$04,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $74 at 120,136
  DEFB $A1,$74,$00,$80,$40,$42,$03,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $74 at 128,64
  DEFB $A1,$54,$00,$57,$40,$42,$02,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $54 at 87,64
  DEFB $A1,$3B,$00,$43,$7B,$42,$01,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $3B at 67,123
  DEFB $A1,$3B,$00,$6B,$7B,$42,$00,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $3B at 107,123
  DEFB $A1,$53,$00,$80,$40,$42,$01,$00 ; Mushroom, which drains the player's
                                       ; life force: in room $53 at 128,64
  DEFB $31,$00,$00,$00,$00,$00,$00,$00 ; sprite $31: in room $00 at 0,0
MONSTERS:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty monster slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty monster slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; An empty monster slot
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ;
MUMMY:
  DEFB $70,$17,$00,$50,$50,$47,$00,$00 ; Mummy: in room $17
  DEFB $00,$00,$00,$68,$68,$00,$00,$00 ;
DRACULA:
  DEFB $7C,$6D,$00,$50,$50,$44,$00,$00 ; Dracula: in room $6D
  DEFB $00,$00,$00,$72,$72,$00,$00,$00 ;
DEVIL:
  DEFB $78,$43,$00,$50,$50,$43,$00,$00 ; Devil: in room $43
  DEFB $00,$00,$00,$72,$72,$00,$00,$00 ;
FRANKENSTEIN_S_MONSTER:
  DEFB $74,$55,$00,$50,$50,$42,$00,$00 ; Frankenstein's monster: in room $55
  DEFB $00,$00,$00,$50,$60,$00,$00,$00 ;
HUMPBACK:
  DEFB $9C,$56,$00,$58,$38,$42,$00,$00 ; Humpback: in room $56
  DEFB $00,$00,$00,$50,$60,$00,$00,$00 ;
DOOR_R07_R00:
  DEFB $02,$07,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $07, then the
  DEFB $02,$00,$34,$50,$B7,$80,$04,$06 ; side in room $00
DOOR_R19_R00:
  DEFB $02,$19,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $19, then the
  DEFB $02,$00,$34,$08,$6F,$E0,$06,$03 ; side in room $00
CYAN_DOOR_R01_R00:
  DEFB $0A,$01,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $01,
  DEFB $0A,$00,$34,$50,$1F,$00,$04,$56 ; then the side in room $00
DOOR_R02_R01:
  DEFB $02,$02,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $02, then the
  DEFB $02,$01,$34,$08,$6F,$E0,$06,$03 ; side in room $01
DOOR_R03_R02:
  DEFB $02,$03,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $03, then the
  DEFB $02,$02,$34,$08,$6F,$E0,$06,$03 ; side in room $02
DOOR_R04_R03:
  DEFB $02,$04,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $04, then the
  DEFB $02,$03,$34,$50,$B7,$80,$04,$06 ; side in room $03
DOOR_R19_R04:
  DEFB $02,$19,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $19, then the
  DEFB $02,$04,$34,$80,$6F,$60,$B7,$03 ; side in room $04
DOOR_R05_R04:
  DEFB $02,$05,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $05, then the
  DEFB $02,$04,$34,$50,$B7,$80,$04,$06 ; side in room $04
DOOR_R06_R05:
  DEFB $02,$06,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $06, then the
  DEFB $02,$05,$34,$A0,$6F,$60,$B7,$03 ; side in room $05
BIG_DOOR_R1A_R06:
  DEFB $03,$1A,$38,$48,$B6,$80,$16,$08 ; A big door: the side in room $1A, then
  DEFB $02,$06,$34,$50,$3F,$00,$04,$56 ; the side in room $06
GREEN_DOOR_R08_R06:
  DEFB $09,$08,$34,$50,$1F,$00,$04,$56 ; A green door: the side in room $08,
  DEFB $09,$06,$34,$50,$97,$80,$04,$06 ; then the side in room $06
DOOR_R07_R06:
  DEFB $02,$07,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $07, then the
  DEFB $02,$06,$34,$A0,$6F,$60,$B7,$03 ; side in room $06
DOOR_R09_R08:
  DEFB $02,$09,$34,$50,$1F,$00,$04,$57 ; A door: the side in room $09, then the
  DEFB $02,$08,$34,$50,$B7,$80,$04,$06 ; side in room $08
DOOR_R0A_R09:
  DEFB $02,$0A,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $0A, then the
  DEFB $02,$09,$34,$08,$6F,$E0,$06,$03 ; side in room $09
DOOR_R0B_R0A:
  DEFB $02,$0B,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $0B, then the
  DEFB $02,$0A,$34,$08,$6F,$E0,$06,$03 ; side in room $0A
DOOR_R0C_R0B:
  DEFB $02,$0C,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $0C, then the
  DEFB $02,$0B,$34,$08,$6F,$E0,$06,$03 ; side in room $0B
DOOR_R0D_R0C:
  DEFB $02,$0D,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $0D, then the
  DEFB $02,$0C,$34,$08,$6F,$E0,$06,$03 ; side in room $0C
DOOR_R0E_R0D:
  DEFB $02,$0E,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $0E, then the
  DEFB $02,$0D,$34,$50,$1F,$00,$04,$56 ; side in room $0D
DOOR_R0F_R0E:
  DEFB $02,$0F,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $0F, then the
  DEFB $02,$0E,$34,$50,$1F,$00,$04,$56 ; side in room $0E
DOOR_R10_R0F:
  DEFB $02,$10,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $10, then the
  DEFB $02,$0F,$34,$50,$1F,$00,$04,$56 ; side in room $0F
RED_DOOR_R11_R10:
  DEFB $08,$11,$34,$50,$B7,$80,$04,$06 ; A red door: the side in room $11, then
  DEFB $08,$10,$34,$50,$1F,$00,$04,$56 ; the side in room $10
DOOR_R12_R11:
  DEFB $02,$12,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $12, then the
  DEFB $02,$11,$34,$50,$1F,$00,$04,$56 ; side in room $11
DOOR_R13_R12:
  DEFB $02,$13,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $13, then the
  DEFB $02,$12,$34,$50,$1F,$00,$04,$56 ; side in room $12
DOOR_R14_R13:
  DEFB $02,$14,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $14, then the
  DEFB $02,$13,$34,$A0,$6F,$60,$B7,$03 ; side in room $13
DOOR_R15_R14:
  DEFB $02,$15,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $15, then the
  DEFB $02,$14,$34,$A0,$6F,$60,$B7,$03 ; side in room $14
DOOR_R16_R15:
  DEFB $02,$16,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $16, then the
  DEFB $02,$15,$34,$A0,$6F,$60,$B7,$03 ; side in room $15
RED_DOOR_R17_R16:
  DEFB $08,$17,$34,$08,$6F,$E0,$06,$03 ; A red door: the side in room $17, then
  DEFB $08,$16,$34,$A0,$6F,$60,$B7,$03 ; the side in room $16
GREEN_DOOR_R18_R17:
  DEFB $09,$18,$34,$50,$1F,$00,$04,$56 ; A green door: the side in room $18,
  DEFB $09,$17,$34,$50,$B7,$80,$04,$06 ; then the side in room $17
DOOR_R18_R02:
  DEFB $02,$18,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $18, then the
  DEFB $02,$02,$34,$50,$3F,$00,$04,$56 ; side in room $02
DOOR_R1A_R1B:
  DEFB $02,$1A,$34,$50,$28,$00,$04,$56 ; A door: the side in room $1A, then the
  DEFB $02,$1B,$34,$50,$B7,$80,$04,$06 ; side in room $1B
DOOR_R1B_R1C:
  DEFB $02,$1B,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $1B, then the
  DEFB $03,$1C,$74,$08,$77,$E0,$08,$F5 ; side in room $1C
DOOR_R1C_R1D:
  DEFB $02,$1C,$34,$98,$6F,$60,$AF,$03 ; A door: the side in room $1C, then the
  DEFB $01,$1D,$34,$18,$6F,$E0,$06,$03 ; side in room $1D
DOOR_R1E_R1F:
  DEFB $02,$1E,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $1E, then the
  DEFB $02,$1F,$34,$50,$B7,$80,$04,$06 ; side in room $1F
DOOR_R1F_R20:
  DEFB $02,$1F,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $1F, then the
  DEFB $02,$20,$34,$A0,$6F,$60,$B7,$03 ; side in room $20
DOOR_R20_R21:
  DEFB $02,$20,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $20, then the
  DEFB $02,$21,$34,$A0,$6F,$60,$B7,$03 ; side in room $21
DOOR_R21_R22:
  DEFB $02,$21,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $21, then the
  DEFB $02,$22,$34,$50,$1F,$00,$04,$56 ; side in room $22
DOOR_R22_R23:
  DEFB $02,$22,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $22, then the
  DEFB $02,$23,$34,$50,$1F,$00,$04,$56 ; side in room $23
DOOR_R23_R24:
  DEFB $02,$23,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $23, then the
  DEFB $02,$24,$34,$08,$6F,$E0,$06,$03 ; side in room $24
DOOR_R24_R25:
  DEFB $02,$24,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $24, then the
  DEFB $02,$25,$34,$08,$6F,$E0,$06,$03 ; side in room $25
CYAN_DOOR_R25_R1E:
  DEFB $0A,$25,$34,$50,$1F,$00,$04,$56 ; A cyan door: the side in room $25,
  DEFB $0A,$1E,$34,$50,$B7,$80,$04,$06 ; then the side in room $1E
DOOR_R24_R26:
  DEFB $02,$24,$34,$50,$3F,$00,$04,$56 ; A door: the side in room $24, then the
  DEFB $03,$26,$38,$48,$B6,$80,$16,$08 ; side in room $26
DOOR_R02_R26:
  DEFB $02,$02,$34,$50,$97,$80,$04,$06 ; A door: the side in room $02, then the
  DEFB $02,$26,$34,$50,$28,$00,$04,$56 ; side in room $26
DOOR_R27_R28:
  DEFB $02,$27,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $27, then the
  DEFB $02,$28,$34,$50,$1F,$00,$04,$56 ; side in room $28
CYAN_DOOR_R28_R29:
  DEFB $0A,$28,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $28,
  DEFB $0A,$29,$34,$50,$1F,$00,$04,$56 ; then the side in room $29
DOOR_R29_R2A:
  DEFB $02,$29,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $29, then the
  DEFB $02,$2A,$34,$A0,$6F,$60,$B7,$03 ; side in room $2A
DOOR_R2A_R2B:
  DEFB $02,$2A,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $2A, then the
  DEFB $02,$2B,$34,$A0,$6F,$60,$B7,$03 ; side in room $2B
DOOR_R2B_R2C:
  DEFB $02,$2B,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $2B, then the
  DEFB $02,$2C,$34,$50,$B7,$80,$04,$06 ; side in room $2C
DOOR_R2C_R2D:
  DEFB $02,$2C,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $2C, then the
  DEFB $02,$2D,$34,$50,$B7,$80,$04,$06 ; side in room $2D
GREEN_DOOR_R2D_R2E:
  DEFB $09,$2D,$34,$A0,$6F,$60,$B7,$03 ; A green door: the side in room $2D,
  DEFB $09,$2E,$34,$08,$6F,$E0,$06,$03 ; then the side in room $2E
DOOR_R2E_R27:
  DEFB $02,$2E,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $2E, then the
  DEFB $02,$27,$34,$08,$6F,$E0,$06,$03 ; side in room $27
DOOR_R27_R2F:
  DEFB $02,$27,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $27, then the
  DEFB $03,$2F,$38,$48,$B6,$80,$16,$08 ; side in room $2F
YELLOW_DOOR_R20_R2F:
  DEFB $0B,$20,$34,$50,$97,$80,$04,$06 ; A yellow door: the side in room $20,
  DEFB $0B,$2F,$34,$50,$28,$00,$04,$56 ; then the side in room $2F
CAVE_DOOR_R30_R31:
  DEFB $01,$30,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $30,
  DEFB $01,$31,$34,$50,$27,$00,$04,$56 ; then the side in room $31
CAVE_DOOR_R31_R32:
  DEFB $01,$31,$34,$50,$AF,$80,$04,$06 ; A cave door: the side in room $31,
  DEFB $01,$32,$34,$50,$27,$00,$04,$56 ; then the side in room $32
CAVE_DOOR_R32_R33:
  DEFB $01,$32,$34,$50,$AF,$80,$04,$06 ; A cave door: the side in room $32,
  DEFB $01,$33,$34,$50,$2F,$00,$04,$56 ; then the side in room $33
CAVE_DOOR_R33_R34:
  DEFB $01,$33,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $33,
  DEFB $01,$34,$34,$50,$27,$00,$04,$56 ; then the side in room $34
CAVE_DOOR_R34_R35:
  DEFB $01,$34,$34,$50,$AF,$80,$04,$06 ; A cave door: the side in room $34,
  DEFB $01,$35,$34,$50,$2F,$00,$04,$56 ; then the side in room $35
CAVE_DOOR_R33_R36:
  DEFB $01,$33,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $33,
  DEFB $01,$36,$34,$10,$6F,$E0,$06,$03 ; then the side in room $36
CAVE_DOOR_R36_R37:
  DEFB $01,$36,$34,$98,$6F,$60,$B7,$03 ; A cave door: the side in room $36,
  DEFB $01,$37,$34,$10,$6F,$E0,$06,$03 ; then the side in room $37
CAVE_DOOR_R37_R38:
  DEFB $01,$37,$34,$98,$6F,$60,$B7,$03 ; A cave door: the side in room $37,
  DEFB $01,$38,$34,$18,$6F,$E0,$06,$03 ; then the side in room $38
CAVE_DOOR_R38_R39:
  DEFB $01,$38,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $38,
  DEFB $01,$39,$34,$50,$2F,$00,$04,$56 ; then the side in room $39
GREEN_CAVE_DOOR_R38_R3A:
  DEFB $0D,$38,$34,$90,$6F,$60,$B7,$03 ; A green cave door: the side in room
  DEFB $0D,$3A,$34,$18,$6F,$E0,$06,$03 ; $38, then the side in room $3A
CAVE_DOOR_R39_R3B:
  DEFB $01,$39,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $39,
  DEFB $01,$3B,$34,$18,$6F,$E0,$06,$03 ; then the side in room $3B
CAVE_DOOR_R3A_R3B:
  DEFB $01,$3A,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $3A,
  DEFB $01,$3B,$34,$50,$2F,$00,$04,$56 ; then the side in room $3B
GREEN_CAVE_DOOR_R3B_R3C:
  DEFB $0D,$3B,$34,$50,$A7,$80,$04,$06 ; A green cave door: the side in room
  DEFB $0D,$3C,$34,$50,$2F,$00,$04,$56 ; $3B, then the side in room $3C
CAVE_DOOR_R3B_R3D:
  DEFB $01,$3B,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $3B,
  DEFB $01,$3D,$34,$18,$6F,$E0,$06,$03 ; then the side in room $3D
CAVE_DOOR_R3C_R3E:
  DEFB $01,$3C,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $3C,
  DEFB $01,$3E,$34,$18,$6F,$E0,$06,$03 ; then the side in room $3E
CAVE_DOOR_R3D_R3E:
  DEFB $01,$3D,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $3D,
  DEFB $01,$3E,$34,$50,$2F,$00,$04,$56 ; then the side in room $3E
CYAN_CAVE_DOOR_R3D_R3F:
  DEFB $0E,$3D,$34,$90,$6F,$60,$B7,$03 ; A cyan cave door: the side in room
  DEFB $0E,$3F,$34,$10,$6F,$E0,$06,$03 ; $3D, then the side in room $3F
CAVE_DOOR_R3F_R40:
  DEFB $01,$3F,$34,$98,$6F,$60,$B7,$03 ; A cave door: the side in room $3F,
  DEFB $01,$40,$34,$18,$6F,$E0,$06,$03 ; then the side in room $40
CAVE_DOOR_R40_R41:
  DEFB $01,$40,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $40,
  DEFB $01,$41,$34,$18,$6F,$E0,$06,$03 ; then the side in room $41
CAVE_DOOR_R40_R42:
  DEFB $01,$40,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $40,
  DEFB $01,$42,$34,$50,$AF,$80,$04,$06 ; then the side in room $42
CAVE_DOOR_R42_R43:
  DEFB $01,$42,$34,$50,$27,$00,$04,$56 ; A cave door: the side in room $42,
  DEFB $01,$43,$34,$50,$A7,$80,$04,$06 ; then the side in room $43
CAVE_DOOR_R43_R44:
  DEFB $01,$43,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $43,
  DEFB $01,$44,$34,$10,$6F,$E0,$06,$03 ; then the side in room $44
RED_CAVE_DOOR_R44_R45:
  DEFB $0C,$44,$34,$98,$6F,$60,$B7,$03 ; A red cave door: the side in room $44,
  DEFB $0C,$45,$34,$18,$6F,$E0,$06,$03 ; then the side in room $45
CAVE_DOOR_R43_R46:
  DEFB $01,$43,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $43,
  DEFB $01,$46,$34,$50,$A7,$80,$04,$06 ; then the side in room $46
CAVE_DOOR_R46_R47:
  DEFB $01,$46,$34,$18,$6F,$E0,$06,$03 ; A cave door: the side in room $46,
  DEFB $01,$47,$34,$98,$6F,$60,$B7,$03 ; then the side in room $47
RED_CAVE_DOOR_R47_R48:
  DEFB $0C,$47,$34,$10,$6F,$E0,$06,$03 ; A red cave door: the side in room $47,
  DEFB $0C,$48,$34,$90,$6F,$60,$B7,$03 ; then the side in room $48
CAVE_DOOR_R48_R49:
  DEFB $01,$48,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $48,
  DEFB $01,$49,$34,$50,$27,$00,$04,$56 ; then the side in room $49
CYAN_CAVE_DOOR_R48_R4A:
  DEFB $0E,$48,$34,$18,$6F,$E0,$06,$03 ; A cyan cave door: the side in room
  DEFB $0E,$4A,$34,$98,$6F,$60,$B7,$03 ; $48, then the side in room $4A
CAVE_DOOR_R4A_R4B:
  DEFB $01,$4A,$34,$10,$6F,$E0,$06,$03 ; A cave door: the side in room $4A,
  DEFB $01,$4B,$34,$90,$6F,$60,$B7,$03 ; then the side in room $4B
CAVE_DOOR_R4B_R4C:
  DEFB $01,$4B,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $4B,
  DEFB $01,$4C,$34,$50,$A7,$80,$04,$06 ; then the side in room $4C
CAVE_DOOR_R48_R4D:
  DEFB $01,$48,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $48,
  DEFB $01,$4D,$34,$50,$AF,$80,$04,$06 ; then the side in room $4D
RED_CAVE_DOOR_R4D_R4E:
  DEFB $0C,$4D,$34,$50,$27,$00,$04,$56 ; A red cave door: the side in room $4D,
  DEFB $0C,$4E,$34,$50,$A7,$80,$04,$06 ; then the side in room $4E
CAVE_DOOR_R4E_R4F:
  DEFB $01,$4E,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $4E,
  DEFB $01,$4F,$34,$10,$6F,$E0,$06,$03 ; then the side in room $4F
CAVE_DOOR_R4F_R50:
  DEFB $01,$4F,$34,$98,$6F,$60,$B7,$03 ; A cave door: the side in room $4F,
  DEFB $01,$50,$34,$18,$6F,$E0,$06,$03 ; then the side in room $50
CAVE_DOOR_R50_R51:
  DEFB $01,$50,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $50,
  DEFB $01,$51,$34,$50,$27,$00,$04,$56 ; then the side in room $51
GREEN_CAVE_DOOR_R50_R52:
  DEFB $0D,$50,$34,$90,$6F,$60,$B7,$03 ; A green cave door: the side in room
  DEFB $0D,$52,$34,$10,$6F,$E0,$06,$03 ; $50, then the side in room $52
CAVE_DOOR_R52_R53:
  DEFB $01,$52,$34,$98,$6F,$60,$B7,$03 ; A cave door: the side in room $52,
  DEFB $01,$53,$34,$18,$6F,$E0,$06,$03 ; then the side in room $53
CAVE_DOOR_R1D_R43:
  DEFB $01,$1D,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $1D,
  DEFB $01,$43,$34,$18,$6F,$E0,$06,$03 ; then the side in room $43
CAVE_DOOR_R46_R51:
  DEFB $01,$46,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $46,
  DEFB $01,$51,$34,$50,$AF,$80,$04,$06 ; then the side in room $51
CAVE_DOOR_R4C_R55:
  DEFB $01,$4C,$34,$18,$6F,$E0,$06,$03 ; A cave door: the side in room $4C,
  DEFB $01,$55,$34,$90,$6F,$60,$B7,$03 ; then the side in room $55
CAVE_DOOR_R54_R55:
  DEFB $01,$54,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $54,
  DEFB $01,$55,$34,$18,$6F,$E0,$06,$03 ; then the side in room $55
CAVE_DOOR_R54_R30:
  DEFB $01,$54,$34,$18,$6F,$E0,$06,$03 ; A cave door: the side in room $54,
  DEFB $01,$30,$34,$90,$6F,$60,$B7,$03 ; then the side in room $30
DOOR_R2D_R75:
  DEFB $02,$2D,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $2D, then the
  DEFB $02,$75,$34,$A0,$6F,$60,$B7,$03 ; side in room $75
DOOR_R75_R76:
  DEFB $02,$75,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $75, then the
  DEFB $02,$76,$34,$50,$1F,$00,$04,$56 ; side in room $76
DOOR_R76_R77:
  DEFB $02,$76,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $76, then the
  DEFB $02,$77,$34,$08,$6F,$E0,$06,$03 ; side in room $77
DOOR_R77_R78:
  DEFB $02,$77,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $77, then the
  DEFB $02,$78,$34,$08,$6F,$E0,$06,$03 ; side in room $78
DOOR_R78_R79:
  DEFB $02,$78,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $78, then the
  DEFB $02,$79,$34,$50,$1F,$00,$04,$56 ; side in room $79
DOOR_R79_R7A:
  DEFB $02,$79,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $79, then the
  DEFB $02,$7A,$34,$50,$1F,$00,$04,$56 ; side in room $7A
DOOR_R7A_R7B:
  DEFB $02,$7A,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $7A, then the
  DEFB $02,$7B,$34,$A0,$6F,$60,$B7,$03 ; side in room $7B
YELLOW_DOOR_R7B_R7C:
  DEFB $0B,$7B,$34,$08,$6F,$E0,$06,$03 ; A yellow door: the side in room $7B,
  DEFB $0B,$7C,$34,$A0,$6F,$60,$B7,$03 ; then the side in room $7C
YELLOW_DOOR_R7C_R7D:
  DEFB $0B,$7C,$34,$50,$1F,$00,$04,$56 ; A yellow door: the side in room $7C,
  DEFB $0B,$7D,$34,$50,$B7,$80,$04,$06 ; then the side in room $7D
DOOR_R7D_R76:
  DEFB $02,$7D,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $7D, then the
  DEFB $02,$76,$34,$50,$B7,$80,$04,$06 ; side in room $76
RED_DOOR_R7A_R7E:
  DEFB $08,$7A,$34,$A0,$6F,$60,$B7,$03 ; A red door: the side in room $7A, then
  DEFB $08,$7E,$34,$08,$6F,$E0,$06,$03 ; the side in room $7E
DOOR_R7E_R29:
  DEFB $02,$7E,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $7E, then the
  DEFB $02,$29,$34,$50,$B7,$80,$04,$06 ; side in room $29
DOOR_R21_R88:
  DEFB $02,$21,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $21, then the
  DEFB $02,$88,$34,$50,$B7,$80,$04,$06 ; side in room $88
GREEN_DOOR_R7F_R80:
  DEFB $09,$7F,$34,$A0,$6F,$60,$B7,$03 ; A green door: the side in room $7F,
  DEFB $09,$80,$34,$08,$6F,$E0,$06,$03 ; then the side in room $80
DOOR_R80_R82:
  DEFB $02,$80,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $80, then the
  DEFB $02,$82,$34,$50,$1F,$00,$04,$56 ; side in room $82
DOOR_R82_R81:
  DEFB $02,$82,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $82, then the
  DEFB $02,$81,$34,$A0,$6F,$60,$B7,$03 ; side in room $81
DOOR_R81_R7F:
  DEFB $02,$81,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $81, then the
  DEFB $02,$7F,$34,$50,$B7,$80,$04,$06 ; side in room $7F
CYAN_DOOR_R82_R87:
  DEFB $0A,$82,$34,$A0,$6F,$60,$B7,$03 ; A cyan door: the side in room $82,
  DEFB $0A,$87,$34,$08,$6F,$E0,$06,$03 ; then the side in room $87
DOOR_R87_R88:
  DEFB $02,$87,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $87, then the
  DEFB $02,$88,$34,$08,$6F,$E0,$06,$03 ; side in room $88
DOOR_R87_R8B:
  DEFB $02,$87,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $87, then the
  DEFB $02,$8B,$34,$50,$1F,$00,$04,$56 ; side in room $8B
DOOR_R8B_R8C:
  DEFB $02,$8B,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $8B, then the
  DEFB $02,$8C,$34,$50,$1F,$00,$04,$56 ; side in room $8C
GREEN_DOOR_R8C_R8D:
  DEFB $09,$8C,$34,$50,$B7,$80,$04,$06 ; A green door: the side in room $8C,
  DEFB $09,$8D,$34,$50,$1F,$00,$04,$56 ; then the side in room $8D
RED_DOOR_R83_R84:
  DEFB $08,$83,$34,$A0,$6F,$60,$B7,$03 ; A red door: the side in room $83, then
  DEFB $08,$84,$34,$08,$6F,$E0,$06,$03 ; the side in room $84
DOOR_R84_R86:
  DEFB $02,$84,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $84, then the
  DEFB $02,$86,$34,$50,$1F,$00,$04,$56 ; side in room $86
DOOR_R86_R85:
  DEFB $02,$86,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $86, then the
  DEFB $02,$85,$34,$A0,$6F,$60,$B7,$03 ; side in room $85
DOOR_R85_R83:
  DEFB $02,$85,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $85, then the
  DEFB $02,$83,$34,$50,$B7,$80,$04,$06 ; side in room $83
YELLOW_DOOR_R84_R89:
  DEFB $0B,$84,$34,$A0,$6F,$60,$B7,$03 ; A yellow door: the side in room $84,
  DEFB $0B,$89,$34,$08,$6F,$E0,$06,$03 ; then the side in room $89
DOOR_R89_R8D:
  DEFB $02,$89,$34,$50,$1F,$00,$04,$56 ; A door: the side in room $89, then the
  DEFB $02,$8D,$34,$50,$B7,$80,$04,$06 ; side in room $8D
DOOR_R89_R8A:
  DEFB $02,$89,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $89, then the
  DEFB $02,$8A,$34,$08,$6F,$E0,$06,$03 ; side in room $8A
GREEN_DOOR_R8A_R23:
  DEFB $09,$8A,$34,$50,$1F,$00,$04,$56 ; A green door: the side in room $8A,
  DEFB $09,$23,$34,$50,$B7,$80,$04,$06 ; then the side in room $23
DOOR_R13_R73:
  DEFB $02,$13,$34,$08,$6F,$E0,$06,$03 ; A door: the side in room $13, then the
  DEFB $02,$73,$34,$A0,$6F,$60,$B7,$03 ; side in room $73
DOOR_R11_R6B:
  DEFB $02,$11,$34,$80,$6F,$60,$B7,$03 ; A door: the side in room $11, then the
  DEFB $02,$6B,$34,$08,$6F,$E0,$06,$03 ; side in room $6B
DOOR_R6B_R6C:
  DEFB $02,$6B,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $6B, then the
  DEFB $02,$6C,$34,$08,$6F,$E0,$06,$03 ; side in room $6C
CYAN_DOOR_R6C_R03:
  DEFB $0A,$6C,$34,$A0,$6F,$60,$B7,$03 ; A cyan door: the side in room $6C,
  DEFB $0A,$03,$34,$08,$6F,$E0,$06,$03 ; then the side in room $03
GREEN_DOOR_R0F_R6D:
  DEFB $09,$0F,$34,$80,$6F,$60,$B7,$03 ; A green door: the side in room $0F,
  DEFB $09,$6D,$34,$08,$6F,$E0,$06,$03 ; then the side in room $6D
DOOR_R6D_R6E:
  DEFB $02,$6D,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $6D, then the
  DEFB $02,$6E,$34,$08,$6F,$E0,$06,$03 ; side in room $6E
DOOR_R6E_R05:
  DEFB $02,$6E,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $6E, then the
  DEFB $02,$05,$34,$08,$6F,$E0,$06,$03 ; side in room $05
CYAN_DOOR_R0D_R6F:
  DEFB $0A,$0D,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $0D,
  DEFB $0A,$6F,$34,$50,$1F,$00,$04,$56 ; then the side in room $6F
DOOR_R6F_R70:
  DEFB $02,$6F,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $6F, then the
  DEFB $02,$70,$34,$70,$1F,$00,$04,$56 ; side in room $70
DOOR_R70_R71:
  DEFB $02,$70,$34,$30,$1F,$00,$04,$56 ; A door: the side in room $70, then the
  DEFB $03,$71,$38,$48,$B6,$80,$16,$08 ; side in room $71
DOOR_R71_R72:
  DEFB $02,$71,$34,$50,$28,$00,$04,$56 ; A door: the side in room $71, then the
  DEFB $03,$72,$38,$48,$B6,$80,$16,$08 ; side in room $72
DOOR_R72_R35:
  DEFB $02,$72,$34,$50,$28,$00,$04,$56 ; A door: the side in room $72, then the
  DEFB $01,$35,$34,$50,$A7,$80,$04,$06 ; side in room $35
CAVE_DOOR_R30_R74:
  DEFB $01,$30,$34,$18,$6F,$E0,$06,$03 ; A cave door: the side in room $30,
  DEFB $01,$74,$34,$90,$6F,$60,$B7,$03 ; then the side in room $74
DOOR_R56_R57:
  DEFB $02,$56,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $56, then the
  DEFB $02,$57,$34,$08,$6F,$E0,$06,$03 ; side in room $57
GREEN_DOOR_R57_R58:
  DEFB $09,$57,$34,$A0,$6F,$60,$B7,$03 ; A green door: the side in room $57,
  DEFB $09,$58,$34,$08,$6F,$E0,$06,$03 ; then the side in room $58
DOOR_R58_R59:
  DEFB $02,$58,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $58, then the
  DEFB $02,$59,$34,$08,$6F,$E0,$06,$03 ; side in room $59
DOOR_R5A_R5B:
  DEFB $02,$5A,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $5A, then the
  DEFB $02,$5B,$34,$08,$6F,$E0,$06,$03 ; side in room $5B
RED_DOOR_R5B_R5C:
  DEFB $08,$5B,$34,$A0,$6F,$60,$B7,$03 ; A red door: the side in room $5B, then
  DEFB $08,$5C,$34,$08,$6F,$E0,$06,$03 ; the side in room $5C
GREEN_DOOR_R5C_R5D:
  DEFB $09,$5C,$34,$A0,$6F,$60,$B7,$03 ; A green door: the side in room $5C,
  DEFB $09,$5D,$34,$08,$6F,$E0,$06,$03 ; then the side in room $5D
RED_DOOR_R5E_R5F:
  DEFB $08,$5E,$34,$A0,$6F,$60,$B7,$03 ; A red door: the side in room $5E, then
  DEFB $08,$5F,$34,$08,$6F,$E0,$06,$03 ; the side in room $5F
RED_DOOR_R5F_R60:
  DEFB $08,$5F,$34,$A0,$6F,$60,$B7,$03 ; A red door: the side in room $5F, then
  DEFB $08,$60,$34,$08,$6F,$E0,$06,$03 ; the side in room $60
DOOR_R60_R61:
  DEFB $02,$60,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $60, then the
  DEFB $02,$61,$34,$08,$6F,$E0,$06,$03 ; side in room $61
DOOR_R62_R63:
  DEFB $02,$62,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $62, then the
  DEFB $02,$63,$34,$08,$6F,$E0,$06,$03 ; side in room $63
DOOR_R63_R64:
  DEFB $02,$63,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $63, then the
  DEFB $02,$64,$34,$08,$6F,$E0,$06,$03 ; side in room $64
YELLOW_DOOR_R64_R65:
  DEFB $0B,$64,$34,$A0,$6F,$60,$B7,$03 ; A yellow door: the side in room $64,
  DEFB $0B,$65,$34,$08,$6F,$E0,$06,$03 ; then the side in room $65
DOOR_R56_R5A:
  DEFB $02,$56,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $56, then the
  DEFB $02,$5A,$34,$50,$1F,$00,$04,$56 ; side in room $5A
CYAN_DOOR_R5A_R5E:
  DEFB $0A,$5A,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $5A,
  DEFB $0A,$5E,$34,$50,$1F,$00,$04,$56 ; then the side in room $5E
DOOR_R5E_R62:
  DEFB $02,$5E,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $5E, then the
  DEFB $02,$62,$34,$50,$1F,$00,$04,$56 ; side in room $62
DOOR_R57_R5B:
  DEFB $02,$57,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $57, then the
  DEFB $02,$5B,$34,$50,$1F,$00,$04,$56 ; side in room $5B
GREEN_DOOR_R5B_R5F:
  DEFB $09,$5B,$34,$30,$B7,$80,$04,$06 ; A green door: the side in room $5B,
  DEFB $09,$5F,$34,$30,$1F,$00,$04,$56 ; then the side in room $5F
CYAN_DOOR_R5F_R63:
  DEFB $0A,$5F,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $5F,
  DEFB $0A,$63,$34,$50,$1F,$00,$04,$56 ; then the side in room $63
DOOR_R58_R5C:
  DEFB $02,$58,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $58, then the
  DEFB $02,$5C,$34,$50,$1F,$00,$04,$56 ; side in room $5C
RED_DOOR_R5C_R60:
  DEFB $08,$5C,$34,$70,$B7,$80,$04,$06 ; A red door: the side in room $5C, then
  DEFB $08,$60,$34,$70,$1F,$00,$04,$56 ; the side in room $60
CYAN_DOOR_R60_R64:
  DEFB $0A,$60,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $60,
  DEFB $0A,$64,$34,$50,$1F,$00,$04,$56 ; then the side in room $64
YELLOW_DOOR_R59_R5D:
  DEFB $0B,$59,$34,$50,$B7,$80,$04,$06 ; A yellow door: the side in room $59,
  DEFB $0B,$5D,$34,$50,$1F,$00,$04,$56 ; then the side in room $5D
DOOR_R5D_R61:
  DEFB $02,$5D,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $5D, then the
  DEFB $02,$61,$34,$50,$1F,$00,$04,$56 ; side in room $61
DOOR_R61_R65:
  DEFB $02,$61,$34,$50,$B7,$80,$04,$06 ; A door: the side in room $61, then the
  DEFB $02,$65,$34,$50,$1F,$00,$04,$56 ; side in room $65
CYAN_DOOR_R67_R56:
  DEFB $0A,$67,$34,$50,$B7,$80,$04,$06 ; A cyan door: the side in room $67,
  DEFB $0A,$56,$34,$50,$1F,$00,$04,$56 ; then the side in room $56
RED_DOOR_R68_R59:
  DEFB $08,$68,$34,$50,$B7,$80,$04,$06 ; A red door: the side in room $68, then
  DEFB $08,$59,$34,$50,$1F,$00,$04,$56 ; the side in room $59
YELLOW_DOOR_R69_R56:
  DEFB $0B,$69,$34,$A0,$6F,$60,$B7,$03 ; A yellow door: the side in room $69,
  DEFB $0B,$56,$34,$08,$6F,$E0,$06,$03 ; then the side in room $56
GREEN_DOOR_R6A_R62:
  DEFB $09,$6A,$34,$A0,$6F,$60,$B7,$03 ; A green door: the side in room $6A,
  DEFB $09,$62,$34,$08,$6F,$E0,$06,$03 ; then the side in room $62
YELLOW_DOOR_R66_R5B:
  DEFB $0B,$66,$34,$30,$1F,$00,$04,$56 ; A yellow door: the side in room $66,
  DEFB $0B,$5B,$34,$70,$B7,$80,$04,$06 ; then the side in room $5B
YELLOW_DOOR_R66_R5C:
  DEFB $0B,$66,$34,$70,$1F,$00,$04,$56 ; A yellow door: the side in room $66,
  DEFB $0B,$5C,$34,$30,$B7,$80,$04,$06 ; then the side in room $5C
YELLOW_DOOR_R66_R5F:
  DEFB $0B,$66,$34,$30,$B7,$80,$04,$06 ; A yellow door: the side in room $66,
  DEFB $0B,$5F,$34,$70,$1F,$00,$04,$56 ; then the side in room $5F
YELLOW_DOOR_R66_R60:
  DEFB $0B,$66,$34,$70,$B7,$80,$04,$06 ; A yellow door: the side in room $66,
  DEFB $0B,$60,$34,$30,$1F,$00,$04,$56 ; then the side in room $60
DOOR_R65_R1B:
  DEFB $02,$65,$34,$A0,$6F,$60,$B7,$03 ; A door: the side in room $65, then the
  DEFB $02,$1B,$34,$08,$6F,$E0,$06,$03 ; side in room $1B
CAVE_DOOR_R40_R8F:
  DEFB $01,$40,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $40,
  DEFB $01,$8F,$34,$50,$2F,$00,$04,$56 ; then the side in room $8F
CAVE_DOOR_R54_R90:
  DEFB $01,$54,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $54,
  DEFB $01,$90,$34,$50,$2F,$00,$04,$56 ; then the side in room $90
CAVE_DOOR_R90_R91:
  DEFB $01,$90,$34,$50,$A7,$80,$04,$06 ; A cave door: the side in room $90,
  DEFB $01,$91,$34,$50,$2F,$00,$04,$56 ; then the side in room $91
CAVE_DOOR_R91_R92:
  DEFB $01,$91,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $91,
  DEFB $01,$92,$34,$18,$6F,$E0,$06,$03 ; then the side in room $92
CAVE_DOOR_R92_R93:
  DEFB $01,$92,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $92,
  DEFB $01,$93,$34,$18,$6F,$E0,$06,$03 ; then the side in room $93
CAVE_DOOR_R93_R94:
  DEFB $01,$93,$34,$90,$6F,$60,$B7,$03 ; A cave door: the side in room $93,
  DEFB $01,$94,$34,$18,$6F,$E0,$06,$03 ; then the side in room $94
CAVE_DOOR_R3A_R94:
  DEFB $01,$3A,$34,$50,$2F,$00,$04,$56 ; A cave door: the side in room $3A,
  DEFB $01,$94,$34,$50,$A7,$80,$04,$06 ; then the side in room $94
TRAPDOOR_R73_R74:
  DEFB $19,$73,$34,$50,$70,$03,$24,$E4 ; A trapdoor in room $73, and where the
  DEFB $1B,$74,$34,$48,$74,$03,$00,$00 ; fall lands, in room $74
TRAPDOOR_R03_R65:
  DEFB $19,$03,$34,$30,$70,$03,$24,$E4 ; A trapdoor in room $03, and where the
  DEFB $1B,$65,$34,$38,$74,$03,$00,$00 ; fall lands, in room $65
TRAPDOOR_R61_R4B:
  DEFB $19,$61,$34,$50,$70,$03,$24,$E4 ; A trapdoor in room $61, and where the
  DEFB $1B,$4B,$34,$48,$74,$03,$00,$00 ; fall lands, in room $4B
TRAPDOOR_R2D_R8D:
  DEFB $19,$2D,$34,$50,$90,$03,$24,$E4 ; A trapdoor in room $2D, and where the
  DEFB $1B,$8D,$34,$48,$94,$03,$00,$00 ; fall lands, in room $8D
TRAPDOOR_R76_R84:
  DEFB $19,$76,$34,$50,$70,$03,$24,$E4 ; A trapdoor in room $76, and where the
  DEFB $1B,$84,$34,$48,$74,$03,$00,$00 ; fall lands, in room $84
TRAPDOOR_R8B_R6C:
  DEFB $19,$8B,$34,$50,$70,$03,$24,$E4 ; A trapdoor in room $8B, and where the
  DEFB $1B,$6C,$34,$48,$74,$03,$00,$00 ; fall lands, in room $6C
TRAPDOOR_R8D_R6E:
  DEFB $19,$8D,$34,$50,$50,$03,$24,$E4 ; A trapdoor in room $8D, and where the
  DEFB $1B,$6E,$34,$48,$54,$03,$00,$00 ; fall lands, in room $6E
TRAPDOOR_R21_R03:
  DEFB $19,$21,$34,$70,$70,$03,$24,$E4 ; A trapdoor in room $21, and where the
  DEFB $1B,$03,$34,$68,$74,$03,$00,$00 ; fall lands, in room $03
TRAPDOOR_R15_R66:
  DEFB $19,$15,$34,$50,$80,$03,$24,$E4 ; A trapdoor in room $15, and where the
  DEFB $1B,$66,$34,$48,$74,$03,$00,$00 ; fall lands, in room $66
TRAPDOOR_R78_R8A:
  DEFB $19,$78,$34,$70,$70,$03,$24,$E4 ; A trapdoor in room $78, and where the
  DEFB $1B,$8A,$34,$68,$74,$03,$00,$00 ; fall lands, in room $8A
TRAPDOOR_R29_R09:
  DEFB $19,$29,$34,$50,$80,$03,$24,$E4 ; A trapdoor in room $29, and where the
  DEFB $1B,$09,$34,$48,$74,$03,$00,$00 ; fall lands, in room $09
GHOST_PICTURE_R0B_R0C:
  DEFB $11,$0B,$00,$50,$97,$81,$00,$00 ; A ghost picture in room $0B, and a
  DEFB $11,$0C,$00,$50,$97,$81,$00,$00 ; ghost picture in room $0C
BARREL_STACK_R91_R3D:
  DEFB $27,$91,$00,$50,$8F,$00,$00,$00 ; A barrel stack in room $91, and a
  DEFB $27,$3D,$00,$5F,$5F,$00,$00,$00 ; barrel stack in room $3D
SUIT_OF_ARMOUR_R1F_R21:
  DEFB $1E,$1F,$00,$98,$67,$60,$00,$00 ; A suit of armour in room $1F, and a
  DEFB $1E,$21,$00,$08,$67,$E0,$00,$00 ; suit of armour in room $21
SUIT_OF_ARMOUR_R25_R23:
  DEFB $1E,$25,$00,$98,$67,$60,$00,$00 ; A suit of armour in room $25, and a
  DEFB $1E,$23,$00,$08,$67,$E0,$00,$00 ; suit of armour in room $23
SUIT_OF_ARMOUR_R00_R06:
  DEFB $1E,$00,$00,$98,$3F,$60,$00,$00 ; A suit of armour in room $00, and a
  DEFB $1E,$06,$00,$38,$47,$00,$00,$00 ; suit of armour in room $06
SUIT_OF_ARMOUR_R00_R06_B:
  DEFB $1E,$00,$00,$98,$8F,$60,$00,$00 ; A suit of armour in room $00, and a
  DEFB $1E,$06,$00,$78,$47,$00,$00,$00 ; suit of armour in room $06
SUIT_OF_ARMOUR_R01_R03:
  DEFB $1E,$01,$00,$58,$27,$00,$00,$00 ; A suit of armour in room $01, and a
  DEFB $1E,$03,$00,$58,$27,$00,$00,$00 ; suit of armour in room $03
SUIT_OF_ARMOUR_R05_R07:
  DEFB $1E,$05,$00,$58,$B7,$80,$00,$00 ; A suit of armour in room $05, and a
  DEFB $1E,$07,$00,$58,$B7,$80,$00,$00 ; suit of armour in room $07
SUIT_OF_ARMOUR_R17_R15:
  DEFB $1E,$17,$00,$58,$27,$00,$00,$00 ; A suit of armour in room $17, and a
  DEFB $1E,$15,$00,$78,$97,$80,$00,$00 ; suit of armour in room $15
SUIT_OF_ARMOUR_R15_R13:
  DEFB $1E,$15,$00,$38,$97,$80,$00,$00 ; A suit of armour in room $15, and a
  DEFB $1E,$13,$00,$58,$27,$00,$00,$00 ; suit of armour in room $13
SUIT_OF_ARMOUR_R88_R8A:
  DEFB $1E,$88,$00,$08,$3F,$E0,$00,$00 ; A suit of armour in room $88, and a
  DEFB $1E,$8A,$00,$08,$47,$E0,$00,$00 ; suit of armour in room $8A
SUIT_OF_ARMOUR_R88_R8A_B:
  DEFB $1E,$88,$00,$08,$8F,$E0,$00,$00 ; A suit of armour in room $88, and a
  DEFB $1E,$8A,$00,$08,$87,$E0,$00,$00 ; suit of armour in room $8A
SUIT_OF_ARMOUR_R27_R2B:
  DEFB $1E,$27,$00,$38,$27,$00,$00,$00 ; A suit of armour in room $27, and a
  DEFB $1E,$2B,$00,$38,$27,$00,$00,$00 ; suit of armour in room $2B
SUIT_OF_ARMOUR_R27_R2B_B:
  DEFB $1E,$27,$00,$78,$27,$00,$00,$00 ; A suit of armour in room $27, and a
  DEFB $1E,$2B,$00,$78,$27,$00,$00,$00 ; suit of armour in room $2B
SUIT_OF_ARMOUR_R56_R24:
  DEFB $1E,$56,$00,$38,$27,$00,$00,$00 ; A suit of armour in room $56, and a
  DEFB $1E,$24,$00,$38,$47,$00,$00,$00 ; suit of armour in room $24
SUIT_OF_ARMOUR_R56_R24_B:
  DEFB $1E,$56,$00,$78,$27,$00,$00,$00 ; A suit of armour in room $56, and a
  DEFB $1E,$24,$00,$78,$47,$00,$00,$00 ; suit of armour in room $24
SUIT_OF_ARMOUR_R7C_R7A:
  DEFB $1E,$7C,$00,$38,$27,$00,$00,$00 ; A suit of armour in room $7C, and a
  DEFB $1E,$7A,$00,$38,$27,$00,$00,$00 ; suit of armour in room $7A
SUIT_OF_ARMOUR_R7C_R7A_B:
  DEFB $1E,$7C,$00,$78,$27,$00,$00,$00 ; A suit of armour in room $7C, and a
  DEFB $1E,$7A,$00,$78,$27,$00,$00,$00 ; suit of armour in room $7A
SUIT_OF_ARMOUR_R09_R7F:
  DEFB $1E,$09,$00,$08,$3F,$E0,$00,$00 ; A suit of armour in room $09, and a
  DEFB $1E,$7F,$00,$38,$B7,$80,$00,$00 ; suit of armour in room $7F
SUIT_OF_ARMOUR_R09_R7F_B:
  DEFB $1E,$09,$00,$08,$8F,$E0,$00,$00 ; A suit of armour in room $09, and a
  DEFB $1E,$7F,$00,$78,$B7,$80,$00,$00 ; suit of armour in room $7F
TABLE_R0D_R13:
  DEFB $12,$0D,$00,$38,$50,$04,$CC,$49 ; A table in room $0D, and a table in
  DEFB $12,$13,$00,$70,$90,$04,$CC,$49 ; room $13
TABLE_R63_R5D:
  DEFB $12,$63,$00,$38,$50,$04,$CC,$49 ; A table in room $63, and a table in
  DEFB $12,$5D,$00,$70,$50,$04,$CC,$49 ; room $5D
TABLE_R18_R88:
  DEFB $12,$18,$00,$48,$50,$04,$CC,$49 ; A table in room $18, and a table in
  DEFB $12,$88,$00,$70,$50,$04,$CC,$49 ; room $88
TABLE_R7A_R81:
  DEFB $12,$7A,$00,$38,$50,$04,$CC,$49 ; A table in room $7A, and a table in
  DEFB $12,$81,$00,$70,$50,$04,$CC,$49 ; room $81
TABLE_R18_R6D:
  DEFB $12,$18,$00,$58,$80,$04,$CC,$49 ; A table in room $18, and a table in
  DEFB $12,$6D,$00,$30,$90,$04,$CC,$49 ; room $6D
TABLE_R5B_R5C:
  DEFB $12,$5B,$00,$38,$50,$04,$CC,$49 ; A table in room $5B, and a table in
  DEFB $12,$5C,$00,$70,$50,$04,$CC,$49 ; room $5C
TABLE_R6A_R1B:
  DEFB $12,$6A,$00,$78,$98,$04,$CC,$49 ; A table in room $6A, and a table in
  DEFB $12,$1B,$00,$70,$50,$04,$CC,$49 ; room $1B
TABLE_R2E_R7D:
  DEFB $12,$2E,$00,$38,$57,$04,$CC,$49 ; A table in room $2E, and a table in
  DEFB $12,$7D,$00,$48,$50,$04,$CC,$49 ; room $7D
TABLE_R2E_R7D_B:
  DEFB $12,$2E,$00,$60,$7F,$04,$CC,$49 ; A table in room $2E, and a table in
  DEFB $12,$7D,$00,$58,$80,$04,$CC,$49 ; room $7D
TABLE_R2A_R2D:
  DEFB $12,$2A,$00,$38,$57,$04,$CC,$49 ; A table in room $2A, and a table in
  DEFB $12,$2D,$00,$30,$80,$04,$CC,$49 ; room $2D
TABLE_R2A_R2D_B:
  DEFB $12,$2A,$00,$60,$7F,$04,$CC,$49 ; A table in room $2A, and a table in
  DEFB $12,$2D,$00,$70,$80,$04,$CC,$49 ; room $2D
A_C_G_SHIELD_R8D_R8C:
  DEFB $1C,$8D,$00,$28,$67,$E0,$00,$00 ; An A.C.G. shield in room $8D, and a
  DEFB $1D,$8C,$00,$28,$67,$E0,$00,$00 ; wall shield in room $8C
WALL_ANTLERS_R8B_R8C:
  DEFB $15,$8B,$00,$88,$6F,$40,$00,$00 ; Wall antlers in room $8B, and a wall
  DEFB $16,$8C,$00,$88,$67,$40,$00,$00 ; trophy in room $8C
A_C_G_SHIELD_R16_R14:
  DEFB $1C,$16,$00,$58,$37,$00,$00,$00 ; An A.C.G. shield in room $16, and a
  DEFB $1D,$14,$00,$58,$97,$80,$00,$00 ; wall shield in room $14
WALL_ANTLERS_R0E_R12:
  DEFB $15,$0E,$00,$28,$57,$E0,$00,$00 ; Wall antlers in room $0E, and a wall
  DEFB $16,$12,$00,$88,$6F,$40,$00,$00 ; trophy in room $12
A_C_G_SHIELD_R0F_R11:
  DEFB $1C,$0F,$00,$28,$67,$E0,$00,$00 ; An A.C.G. shield in room $0F, and a
  DEFB $1D,$11,$00,$28,$67,$E0,$00,$00 ; wall shield in room $11
WALL_ANTLERS_R10_R73:
  DEFB $15,$10,$00,$88,$6F,$40,$00,$00 ; Wall antlers in room $10, and a wall
  DEFB $16,$73,$00,$58,$97,$80,$00,$00 ; trophy in room $73
A_C_G_SHIELD_R08_R18:
  DEFB $1C,$08,$00,$88,$67,$40,$00,$00 ; An A.C.G. shield in room $08, and a
  DEFB $1D,$18,$00,$88,$67,$40,$00,$00 ; wall shield in room $18
WALL_ANTLERS_R6F_R0E:
  DEFB $15,$6F,$00,$28,$67,$E0,$00,$00 ; Wall antlers in room $6F, and a wall
  DEFB $16,$0E,$00,$28,$77,$E0,$00,$00 ; trophy in room $0E
PUMPKIN_PICTURE_R00_R19:
  DEFB $25,$00,$00,$28,$17,$00,$00,$00 ; A pumpkin picture in room $00, and a
  DEFB $1D,$19,$00,$58,$37,$00,$00,$00 ; wall shield in room $19
GHOST_PICTURE_R00_R0B:
  DEFB $11,$00,$00,$78,$1C,$00,$00,$00 ; A ghost picture in room $00, and a
  DEFB $16,$0B,$00,$58,$37,$00,$00,$00 ; wall trophy in room $0B
A_C_G_SHIELD_R00_R19:
  DEFB $1C,$00,$00,$38,$B7,$80,$00,$00 ; An A.C.G. shield in room $00, and a
  DEFB $1D,$19,$00,$58,$97,$80,$00,$00 ; wall shield in room $19
WALL_ANTLERS_R00_R0B:
  DEFB $15,$00,$00,$78,$B7,$80,$00,$00 ; Wall antlers in room $00, and a wall
  DEFB $16,$0B,$00,$58,$97,$81,$00,$00 ; trophy in room $0B
GHOST_PICTURE_R04_R15:
  DEFB $11,$04,$00,$28,$47,$E1,$00,$00 ; A ghost picture in room $04, and wall
  DEFB $15,$15,$00,$58,$37,$00,$00,$00 ; antlers in room $15
WALL_TROPHY_R04_R14:
  DEFB $16,$04,$00,$28,$87,$E0,$00,$00 ; A wall trophy in room $04, and a
  DEFB $25,$14,$00,$58,$37,$00,$00,$00 ; pumpkin picture in room $14
GHOST_PICTURE_R73_R6E:
  DEFB $11,$73,$00,$58,$3C,$00,$00,$00 ; A ghost picture in room $73, and a
  DEFB $16,$6E,$00,$58,$B7,$80,$00,$00 ; wall trophy in room $6E
A_C_G_SHIELD_R6D_R0E:
  DEFB $1C,$6D,$00,$58,$B7,$80,$00,$00 ; An A.C.G. shield in room $6D, and a
  DEFB $25,$0E,$00,$88,$6F,$40,$00,$00 ; pumpkin picture in room $0E
PUMPKIN_PICTURE_R07_R06:
  DEFB $25,$07,$00,$A8,$6F,$40,$00,$00 ; A pumpkin picture in room $07, and an
  DEFB $1C,$06,$00,$38,$97,$80,$00,$00 ; A.C.G. shield in room $06
A_C_G_SHIELD_R06_R01:
  DEFB $1C,$06,$00,$78,$97,$80,$00,$00 ; An A.C.G. shield in room $06, and a
  DEFB $1D,$01,$00,$A8,$67,$40,$00,$00 ; wall shield in room $01
GHOST_PICTURE_R18_R17:
  DEFB $11,$18,$00,$28,$6F,$E1,$00,$00 ; A ghost picture in room $18, and a
  DEFB $1D,$17,$00,$A8,$67,$40,$00,$00 ; wall shield in room $17
WALL_ANTLERS_R87_R89:
  DEFB $15,$87,$00,$38,$17,$00,$00,$00 ; Wall antlers in room $87, and a wall
  DEFB $16,$89,$00,$38,$B7,$80,$00,$00 ; trophy in room $89
WALL_TROPHY_R87_R89:
  DEFB $16,$87,$00,$78,$17,$00,$00,$00 ; A wall trophy in room $87, and wall
  DEFB $15,$89,$00,$78,$B7,$80,$00,$00 ; antlers in room $89
WALL_SHIELD_R00_R82:
  DEFB $1D,$00,$00,$08,$47,$E0,$00,$00 ; A wall shield in room $00, and a wall
  DEFB $16,$82,$00,$38,$B7,$80,$00,$00 ; trophy in room $82
WALL_TROPHY_R00_R82:
  DEFB $16,$00,$00,$08,$87,$E0,$00,$00 ; A wall trophy in room $00, and wall
  DEFB $15,$82,$00,$78,$B7,$80,$00,$00 ; antlers in room $82
GHOST_PICTURE_R66_R61:
  DEFB $11,$66,$00,$A0,$47,$61,$00,$00 ; A ghost picture in room $66, and a
  DEFB $1D,$61,$00,$A8,$6F,$60,$00,$00 ; wall shield in room $61
WALL_ANTLERS_R66_R5D:
  DEFB $15,$66,$00,$A8,$87,$60,$00,$00 ; Wall antlers in room $66, and a
  DEFB $25,$5D,$00,$A8,$6F,$60,$00,$00 ; pumpkin picture in room $5D
WALL_TROPHY_R66_R65:
  DEFB $16,$66,$00,$08,$47,$E0,$00,$00 ; A wall trophy in room $66, and a wall
  DEFB $1D,$65,$00,$58,$B7,$80,$00,$00 ; shield in room $65
A_C_G_SHIELD_R66_R64:
  DEFB $1C,$66,$00,$08,$87,$E0,$00,$00 ; An A.C.G. shield in room $66, and a
  DEFB $16,$64,$00,$58,$B7,$80,$00,$00 ; wall trophy in room $64
GHOST_PICTURE_R63_R62:
  DEFB $11,$63,$00,$58,$B7,$81,$00,$00 ; A ghost picture in room $63, and wall
  DEFB $15,$62,$00,$50,$B7,$80,$00,$00 ; antlers in room $62
WALL_TROPHY_R70_R0D:
  DEFB $16,$70,$00,$38,$B7,$80,$00,$00 ; A wall trophy in room $70, and wall
  DEFB $15,$0D,$00,$08,$6F,$E0,$00,$00 ; antlers in room $0D
WALL_SHIELD_R70_R0C:
  DEFB $1D,$70,$00,$78,$B7,$80,$00,$00 ; A wall shield in room $70, and a wall
  DEFB $16,$0C,$00,$58,$37,$00,$00,$00 ; trophy in room $0C
WALL_TROPHY_R09_R7F:
  DEFB $16,$09,$00,$A8,$47,$40,$00,$00 ; A wall trophy in room $09, and wall
  DEFB $15,$7F,$00,$08,$60,$E0,$00,$00 ; antlers in room $7F
GHOST_PICTURE_R09_R7F:
  DEFB $11,$09,$00,$A0,$87,$41,$00,$00 ; A ghost picture in room $09, and a
  DEFB $1D,$7F,$00,$58,$17,$00,$00,$00 ; wall shield in room $7F
WALL_ANTLERS_R5A_R27:
  DEFB $15,$5A,$00,$08,$47,$E0,$00,$00 ; Wall antlers in room $5A, and a
  DEFB $25,$27,$00,$A8,$47,$60,$00,$00 ; pumpkin picture in room $27
WALL_TROPHY_R5A_R27:
  DEFB $16,$5A,$00,$08,$87,$E0,$00,$00 ; A wall trophy in room $5A, and a wall
  DEFB $1D,$27,$00,$A8,$87,$60,$00,$00 ; shield in room $27
A_C_G_SHIELD_R29_R7E:
  DEFB $1C,$29,$00,$A8,$47,$60,$00,$00 ; An A.C.G. shield in room $29, and a
  DEFB $16,$7E,$00,$A8,$60,$60,$00,$00 ; wall trophy in room $7E
GHOST_PICTURE_R29_R7E:
  DEFB $11,$29,$00,$A0,$87,$61,$00,$00 ; A ghost picture in room $29, and wall
  DEFB $15,$7E,$00,$58,$B7,$80,$00,$00 ; antlers in room $7E
CLOCK_R0D_R13:
  DEFB $10,$0D,$34,$30,$27,$01,$04,$56 ; A clock (the knight only): the side in
  DEFB $10,$13,$34,$30,$B7,$81,$04,$06 ; room $0D, then the side in room $13
CLOCK_R09_R17:
  DEFB $10,$09,$34,$30,$27,$01,$04,$56 ; A clock (the knight only): the side in
  DEFB $10,$17,$34,$30,$B7,$81,$04,$06 ; room $09, then the side in room $17
CLOCK_R35_R8F:
  DEFB $10,$35,$34,$88,$6F,$61,$B7,$03 ; A clock (the knight only): the side in
  DEFB $10,$8F,$34,$18,$6F,$E1,$06,$03 ; room $35, then the side in room $8F
CLOCK_R67_R68:
  DEFB $10,$67,$34,$98,$6F,$61,$B7,$03 ; A clock (the knight only): the side in
  DEFB $10,$68,$34,$08,$6F,$E1,$06,$03 ; room $67, then the side in room $68
CLOCK_R8D_R22:
  DEFB $10,$8D,$34,$78,$4F,$61,$B7,$03 ; A clock (the knight only): the side in
  DEFB $10,$22,$34,$28,$6F,$E1,$06,$03 ; room $8D, then the side in room $22
CLOCK_R76_R75:
  DEFB $10,$76,$34,$30,$27,$01,$04,$56 ; A clock (the knight only): the side in
  DEFB $10,$75,$34,$30,$B7,$81,$04,$06 ; room $76, then the side in room $75
BOOKCASE_R0A_R16:
  DEFB $17,$0A,$34,$40,$47,$00,$04,$56 ; A bookcase (the wizard only): the side
  DEFB $17,$16,$34,$40,$97,$80,$04,$06 ; in room $0A, then the side in room $16
BOOKCASE_R3D_R49:
  DEFB $17,$3D,$34,$48,$37,$00,$04,$56 ; A bookcase (the wizard only): the side
  DEFB $17,$49,$34,$50,$AF,$80,$04,$06 ; in room $3D, then the side in room $49
BOOKCASE_R69_R6A:
  DEFB $17,$69,$34,$40,$B7,$80,$04,$06 ; A bookcase (the wizard only): the side
  DEFB $17,$6A,$34,$40,$27,$00,$04,$56 ; in room $69, then the side in room $6A
BOOKCASE_R6C_R6E:
  DEFB $17,$6C,$34,$40,$B7,$80,$04,$06 ; A bookcase (the wizard only): the side
  DEFB $17,$6E,$34,$40,$27,$00,$04,$56 ; in room $6C, then the side in room $6E
BOOKCASE_R3E_R41:
  DEFB $17,$3E,$34,$88,$77,$60,$B7,$03 ; A bookcase (the wizard only): the side
  DEFB $17,$41,$34,$48,$A7,$80,$04,$06 ; in room $3E, then the side in room $41
BARREL_R45_R53:
  DEFB $1A,$45,$34,$50,$37,$00,$04,$56 ; A barrel (the serf only): the side in
  DEFB $1A,$53,$34,$50,$A4,$A0,$04,$06 ; room $45, then the side in room $53
BARREL_R4C_R4E:
  DEFB $1A,$4C,$34,$88,$6F,$40,$B7,$03 ; A barrel (the serf only): the side in
  DEFB $1A,$4E,$34,$18,$6F,$E0,$06,$03 ; room $4C, then the side in room $4E
BARREL_R38_R4B:
  DEFB $1A,$38,$34,$50,$37,$00,$04,$56 ; A barrel (the serf only): the side in
  DEFB $1A,$4B,$34,$50,$A7,$A0,$04,$06 ; room $38, then the side in room $4B
BARREL_R6B_R6D:
  DEFB $1A,$6B,$34,$50,$B7,$A0,$04,$06 ; A barrel (the serf only): the side in
  DEFB $1A,$6D,$34,$50,$27,$00,$04,$56 ; room $6B, then the side in room $6D
BARREL_R8A_R08:
  DEFB $1A,$8A,$34,$98,$6F,$60,$B7,$03 ; A barrel (the serf only): the side in
  DEFB $1A,$08,$34,$28,$6F,$E1,$06,$03 ; room $8A, then the side in room $08
A_C_G_DOOR_R00_R8E:
  DEFB $24,$00,$C4,$98,$7F,$40,$BA,$D6 ; An a.c.g. door: the side in room $00,
  DEFB $24,$8E,$C4,$00,$7F,$E0,$08,$D6 ; then the side in room $8E
SKELETON_R53_R8F:
  DEFB $26,$53,$00,$80,$77,$61,$00,$00 ; A skeleton in room $53, and a skeleton
  DEFB $26,$8F,$00,$80,$77,$61,$00,$00 ; in room $8F
SKELETON_R33_R55:
  DEFB $26,$33,$00,$18,$6F,$E1,$00,$00 ; A skeleton in room $33, and a skeleton
  DEFB $26,$55,$00,$50,$A7,$81,$00,$00 ; in room $55

; What is in each room
;
; One pointer per room, 150 of them, each to a $0000-terminated list of the
; records that belong to that room. Read out of the game, room $00's list names
; $EEE0, $EEF0 and $EF00 -- which are exactly the door records found in the
; running game when the player starts there.
;
; The lists themselves follow immediately, from ROOM_LIST_00 on. Their entries
; are addresses into the initial-state template at INITIAL_STATE rather than
; into the runtime tables, and subtracting ROOM_CONTENTS is exactly the
; relocation from one to the other. See POPULATE_ROOM.
ROOM_CONTENTS:
  DEFB $A9,$76,$C3,$76,$CD,$76,$D7,$76
  DEFB $E5,$76,$F1,$76,$FB,$76,$0D,$77
  DEFB $17,$77,$21,$77,$33,$77,$3D,$77
  DEFB $47,$77,$51,$77,$5F,$77,$6B,$77
  DEFB $75,$77,$7D,$77,$87,$77,$8F,$77
  DEFB $9D,$77,$A7,$77,$B5,$77,$BF,$77
  DEFB $CB,$77,$D9,$77,$E3,$77,$E9,$77
  DEFB $F3,$77,$F9,$77,$FF,$77,$05,$78
  DEFB $0D,$78,$15,$78,$21,$78,$29,$78
  DEFB $33,$78,$3F,$78,$47,$78,$4D,$78
  DEFB $5D,$78,$63,$78,$71,$78,$7B,$78
  DEFB $85,$78,$8B,$78,$99,$78,$A3,$78
  DEFB $A9,$78,$B1,$78,$B7,$78,$BD,$78
  DEFB $C7,$78,$CD,$78,$D5,$78,$DB,$78
  DEFB $E1,$78,$EB,$78,$F1,$78,$F9,$78
  DEFB $03,$79,$09,$79,$15,$79,$1D,$79
  DEFB $23,$79,$2D,$79,$33,$79,$39,$79
  DEFB $43,$79,$49,$79,$4F,$79,$57,$79
  DEFB $5D,$79,$67,$79,$6D,$79,$73,$79
  DEFB $7D,$79,$85,$79,$8B,$79,$93,$79
  DEFB $99,$79,$A1,$79,$A7,$79,$AD,$79
  DEFB $B5,$79,$BD,$79,$C5,$79,$D3,$79
  DEFB $DB,$79,$E3,$79,$EB,$79,$F7,$79
  DEFB $05,$7A,$13,$7A,$1F,$7A,$27,$7A
  DEFB $33,$7A,$3F,$7A,$4B,$7A,$55,$7A
  DEFB $61,$7A,$6B,$7A,$77,$7A,$8B,$7A
  DEFB $91,$7A,$97,$7A,$9D,$7A,$A5,$7A
  DEFB $AD,$7A,$B7,$7A,$C3,$7A,$CF,$7A
  DEFB $D7,$7A,$E1,$7A,$E7,$7A,$ED,$7A
  DEFB $F7,$7A,$FD,$7A,$05,$7B,$11,$7B
  DEFB $17,$7B,$1F,$7B,$25,$7B,$33,$7B
  DEFB $39,$7B,$43,$7B,$4D,$7B,$57,$7B
  DEFB $61,$7B,$67,$7B,$6F,$7B,$7B,$7B
  DEFB $81,$7B,$8B,$7B,$91,$7B,$97,$7B
  DEFB $A3,$7B,$AF,$7B,$BB,$7B,$C9,$7B
  DEFB $D3,$7B,$DD,$7B,$EB,$7B,$EF,$7B
  DEFB $F7,$7B,$FD,$7B,$05,$7C,$0B,$7C
  DEFB $11,$7C,$17,$7C

; What is in room $00
;
; 12 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: A.C.G. key, piece 1, A.C.G. key, piece 2, A.C.G. key, piece 3
; and sprite $31.
ROOM_LIST_00:
  DEFW DOOR_R07_R00       ; A door to room $07
  DEFW DOOR_R19_R00       ; A door to room $19
  DEFW CYAN_DOOR_R01_R00  ; A cyan door to room $01
  DEFW A_C_G_DOOR_R00_R8E ; An A.C.G. door to room $8E
  DEFW SUIT_OF_ARMOUR_R00_R06 ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R00_R06_B ; A suit of armour
  DEFW PUMPKIN_PICTURE_R00_R19 ; A pumpkin picture
  DEFW GHOST_PICTURE_R00_R0B ; A ghost picture
  DEFW A_C_G_SHIELD_R00_R19 ; An A.C.G. shield
  DEFW WALL_ANTLERS_R00_R0B ; Wall antlers
  DEFW WALL_SHIELD_R00_R82 ; A wall shield
  DEFW WALL_TROPHY_R00_R82 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $01
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_01:
  DEFW CYAN_DOOR_R01_R00  ; A cyan door to room $00
  DEFW DOOR_R02_R01       ; A door to room $02
  DEFW SUIT_OF_ARMOUR_R01_R03 ; A suit of armour
  DEFW A_C_G_SHIELD_R06_R01 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $02
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_02:
  DEFW DOOR_R02_R01       ; A door to room $01
  DEFW DOOR_R03_R02       ; A door to room $03
  DEFW DOOR_R18_R02       ; A door to room $18
  DEFW DOOR_R02_R26       ; A door to room $26
  DEFW $0000              ; End of the list

; What is in room $03
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_03:
  DEFW DOOR_R03_R02       ; A door to room $02
  DEFW DOOR_R04_R03       ; A door to room $04
  DEFW CYAN_DOOR_R6C_R03  ; A cyan door to room $6C
  DEFW TRAPDOOR_R03_R65   ; A trapdoor, falling to room $65
  DEFW TRAPDOOR_R21_R03   ; Where the trapdoor in room $21 lands: a rug
  DEFW SUIT_OF_ARMOUR_R01_R03 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $04
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_04:
  DEFW DOOR_R04_R03       ; A door to room $03
  DEFW DOOR_R19_R04       ; A door to room $19
  DEFW DOOR_R05_R04       ; A door to room $05
  DEFW GHOST_PICTURE_R04_R15 ; A ghost picture
  DEFW WALL_TROPHY_R04_R14 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $05
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: key and collectable $8A.
ROOM_LIST_05:
  DEFW DOOR_R05_R04       ; A door to room $04
  DEFW DOOR_R06_R05       ; A door to room $06
  DEFW DOOR_R6E_R05       ; A door to room $6E
  DEFW SUIT_OF_ARMOUR_R05_R07 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $06
;
; 8 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_06:
  DEFW DOOR_R06_R05       ; A door to room $05
  DEFW BIG_DOOR_R1A_R06   ; A door to room $1A
  DEFW GREEN_DOOR_R08_R06 ; A green door to room $08
  DEFW DOOR_R07_R06       ; A door to room $07
  DEFW SUIT_OF_ARMOUR_R00_R06 ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R00_R06_B ; A suit of armour
  DEFW PUMPKIN_PICTURE_R07_R06 ; An A.C.G. shield
  DEFW A_C_G_SHIELD_R06_R01 ; An A.C.G. shield
  DEFW $0000              ; End of the list

; What is in room $07
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_07:
  DEFW DOOR_R07_R00       ; A door to room $00
  DEFW DOOR_R07_R06       ; A door to room $06
  DEFW SUIT_OF_ARMOUR_R05_R07 ; A suit of armour
  DEFW PUMPKIN_PICTURE_R07_R06 ; A pumpkin picture
  DEFW $0000              ; End of the list

; What is in room $08
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_08:
  DEFW GREEN_DOOR_R08_R06 ; A green door to room $06
  DEFW DOOR_R09_R08       ; A door to room $09
  DEFW A_C_G_SHIELD_R08_R18 ; An A.C.G. shield
  DEFW BARREL_R8A_R08     ; A barrel (the serf only) to room $8A
  DEFW $0000              ; End of the list

; What is in room $09
;
; 8 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $80 and food.
ROOM_LIST_09:
  DEFW DOOR_R09_R08       ; A door to room $08
  DEFW DOOR_R0A_R09       ; A door to room $0A
  DEFW TRAPDOOR_R29_R09   ; Where the trapdoor in room $29 lands: a rug
  DEFW CLOCK_R09_R17      ; A clock (the knight only) to room $17
  DEFW SUIT_OF_ARMOUR_R09_R7F ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R09_R7F_B ; A suit of armour
  DEFW WALL_TROPHY_R09_R7F ; A wall trophy
  DEFW GHOST_PICTURE_R09_R7F ; A ghost picture
  DEFW $0000              ; End of the list

; What is in room $0A
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_0A:
  DEFW DOOR_R0A_R09       ; A door to room $09
  DEFW DOOR_R0B_R0A       ; A door to room $0B
  DEFW BOOKCASE_R0A_R16   ; A bookcase (the wizard only) to room $16
  DEFW WALL_ANTLERS_R00_R0B ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $0B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_0B:
  DEFW DOOR_R0B_R0A       ; A door to room $0A
  DEFW DOOR_R0C_R0B       ; A door to room $0C
  DEFW GHOST_PICTURE_R0B_R0C ; A ghost picture
  DEFW GHOST_PICTURE_R00_R0B ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $0C
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_0C:
  DEFW DOOR_R0C_R0B       ; A door to room $0B
  DEFW DOOR_R0D_R0C       ; A door to room $0D
  DEFW GHOST_PICTURE_R0B_R0C ; A ghost picture
  DEFW WALL_SHIELD_R70_R0C ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $0D
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_0D:
  DEFW DOOR_R0D_R0C       ; A door to room $0C
  DEFW DOOR_R0E_R0D       ; A door to room $0E
  DEFW CYAN_DOOR_R0D_R6F  ; A cyan door to room $6F
  DEFW CLOCK_R0D_R13      ; A clock (the knight only) to room $13
  DEFW TABLE_R0D_R13      ; A table
  DEFW WALL_TROPHY_R70_R0D ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $0E
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_0E:
  DEFW DOOR_R0E_R0D       ; A door to room $0D
  DEFW DOOR_R0F_R0E       ; A door to room $0F
  DEFW WALL_ANTLERS_R0E_R12 ; Wall antlers
  DEFW WALL_ANTLERS_R6F_R0E ; A wall trophy
  DEFW A_C_G_SHIELD_R6D_R0E ; A pumpkin picture
  DEFW $0000              ; End of the list

; What is in room $0F
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_0F:
  DEFW DOOR_R0F_R0E       ; A door to room $0E
  DEFW DOOR_R10_R0F       ; A door to room $10
  DEFW GREEN_DOOR_R0F_R6D ; A green door to room $6D
  DEFW A_C_G_SHIELD_R0F_R11 ; An A.C.G. shield
  DEFW $0000              ; End of the list

; What is in room $10
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_10:
  DEFW DOOR_R10_R0F       ; A door to room $0F
  DEFW RED_DOOR_R11_R10   ; A red door to room $11
  DEFW WALL_ANTLERS_R10_R73 ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $11
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_11:
  DEFW RED_DOOR_R11_R10   ; A red door to room $10
  DEFW DOOR_R12_R11       ; A door to room $12
  DEFW DOOR_R11_R6B       ; A door to room $6B
  DEFW A_C_G_SHIELD_R0F_R11 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $12
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_12:
  DEFW DOOR_R12_R11       ; A door to room $11
  DEFW DOOR_R13_R12       ; A door to room $13
  DEFW WALL_ANTLERS_R0E_R12 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $13
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $86.
ROOM_LIST_13:
  DEFW DOOR_R13_R12       ; A door to room $12
  DEFW DOOR_R14_R13       ; A door to room $14
  DEFW DOOR_R13_R73       ; A door to room $73
  DEFW TABLE_R0D_R13      ; A table
  DEFW CLOCK_R0D_R13      ; A clock (the knight only) to room $0D
  DEFW SUIT_OF_ARMOUR_R15_R13 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $14
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_14:
  DEFW DOOR_R14_R13       ; A door to room $13
  DEFW DOOR_R15_R14       ; A door to room $15
  DEFW A_C_G_SHIELD_R16_R14 ; A wall shield
  DEFW WALL_TROPHY_R04_R14 ; A pumpkin picture
  DEFW $0000              ; End of the list

; What is in room $15
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_15:
  DEFW DOOR_R15_R14       ; A door to room $14
  DEFW DOOR_R16_R15       ; A door to room $16
  DEFW TRAPDOOR_R15_R66   ; A trapdoor, falling to room $66
  DEFW GHOST_PICTURE_R04_R15 ; Wall antlers
  DEFW SUIT_OF_ARMOUR_R17_R15 ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R15_R13 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $16
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_16:
  DEFW DOOR_R16_R15       ; A door to room $15
  DEFW RED_DOOR_R17_R16   ; A red door to room $17
  DEFW A_C_G_SHIELD_R16_R14 ; An A.C.G. shield
  DEFW BOOKCASE_R0A_R16   ; A bookcase (the wizard only) to room $0A
  DEFW $0000              ; End of the list

; What is in room $17
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: key, food and mummy.
ROOM_LIST_17:
  DEFW RED_DOOR_R17_R16   ; A red door to room $16
  DEFW GREEN_DOOR_R18_R17 ; A green door to room $18
  DEFW CLOCK_R09_R17      ; A clock (the knight only) to room $09
  DEFW GHOST_PICTURE_R18_R17 ; A wall shield
  DEFW SUIT_OF_ARMOUR_R17_R15 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $18
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_18:
  DEFW GREEN_DOOR_R18_R17 ; A green door to room $17
  DEFW DOOR_R18_R02       ; A door to room $02
  DEFW A_C_G_SHIELD_R08_R18 ; A wall shield
  DEFW TABLE_R18_R88      ; A table
  DEFW TABLE_R18_R6D      ; A table
  DEFW GHOST_PICTURE_R18_R17 ; A ghost picture
  DEFW $0000              ; End of the list

; What is in room $19
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_19:
  DEFW DOOR_R19_R00       ; A door to room $00
  DEFW DOOR_R19_R04       ; A door to room $04
  DEFW PUMPKIN_PICTURE_R00_R19 ; A wall shield
  DEFW A_C_G_SHIELD_R00_R19 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $1A
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_1A:
  DEFW BIG_DOOR_R1A_R06   ; A big door to room $06
  DEFW DOOR_R1A_R1B       ; A door to room $1B
  DEFW $0000              ; End of the list

; What is in room $1B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_1B:
  DEFW DOOR_R1A_R1B       ; A door to room $1A
  DEFW DOOR_R1B_R1C       ; A door to room $1C
  DEFW DOOR_R65_R1B       ; A door to room $65
  DEFW TABLE_R6A_R1B      ; A table
  DEFW $0000              ; End of the list

; What is in room $1C
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_1C:
  DEFW DOOR_R1B_R1C       ; A big door to room $1B
  DEFW DOOR_R1C_R1D       ; A door to room $1D
  DEFW $0000              ; End of the list

; What is in room $1D
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_1D:
  DEFW DOOR_R1C_R1D       ; A cave door to room $1C
  DEFW CAVE_DOOR_R1D_R43  ; A cave door to room $43
  DEFW $0000              ; End of the list

; What is in room $1E
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_1E:
  DEFW DOOR_R1E_R1F       ; A door to room $1F
  DEFW CYAN_DOOR_R25_R1E  ; A cyan door to room $25
  DEFW $0000              ; End of the list

; What is in room $1F
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $88.
ROOM_LIST_1F:
  DEFW DOOR_R1E_R1F       ; A door to room $1E
  DEFW DOOR_R1F_R20       ; A door to room $20
  DEFW SUIT_OF_ARMOUR_R1F_R21 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $20
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_20:
  DEFW DOOR_R1F_R20       ; A door to room $1F
  DEFW DOOR_R20_R21       ; A door to room $21
  DEFW YELLOW_DOOR_R20_R2F ; A yellow door to room $2F
  DEFW $0000              ; End of the list

; What is in room $21
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_21:
  DEFW DOOR_R20_R21       ; A door to room $20
  DEFW DOOR_R21_R22       ; A door to room $22
  DEFW DOOR_R21_R88       ; A door to room $88
  DEFW TRAPDOOR_R21_R03   ; A trapdoor, falling to room $03
  DEFW SUIT_OF_ARMOUR_R1F_R21 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $22
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_22:
  DEFW DOOR_R21_R22       ; A door to room $21
  DEFW DOOR_R22_R23       ; A door to room $23
  DEFW CLOCK_R8D_R22      ; A clock (the knight only) to room $8D
  DEFW $0000              ; End of the list

; What is in room $23
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_23:
  DEFW DOOR_R22_R23       ; A door to room $22
  DEFW DOOR_R23_R24       ; A door to room $24
  DEFW GREEN_DOOR_R8A_R23 ; A green door to room $8A
  DEFW SUIT_OF_ARMOUR_R25_R23 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $24
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_24:
  DEFW DOOR_R23_R24       ; A door to room $23
  DEFW DOOR_R24_R25       ; A door to room $25
  DEFW DOOR_R24_R26       ; A door to room $26
  DEFW SUIT_OF_ARMOUR_R56_R24 ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R56_R24_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $25
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_25:
  DEFW DOOR_R24_R25       ; A door to room $24
  DEFW CYAN_DOOR_R25_R1E  ; A cyan door to room $1E
  DEFW SUIT_OF_ARMOUR_R25_R23 ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $26
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_26:
  DEFW DOOR_R24_R26       ; A big door to room $24
  DEFW DOOR_R02_R26       ; A door to room $02
  DEFW $0000              ; End of the list

; What is in room $27
;
; 7 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_27:
  DEFW DOOR_R27_R28       ; A door to room $28
  DEFW DOOR_R2E_R27       ; A door to room $2E
  DEFW DOOR_R27_R2F       ; A door to room $2F
  DEFW SUIT_OF_ARMOUR_R27_R2B ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R27_R2B_B ; A suit of armour
  DEFW WALL_ANTLERS_R5A_R27 ; A pumpkin picture
  DEFW WALL_TROPHY_R5A_R27 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $28
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_28:
  DEFW DOOR_R27_R28       ; A door to room $27
  DEFW CYAN_DOOR_R28_R29  ; A cyan door to room $29
  DEFW $0000              ; End of the list

; What is in room $29
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_29:
  DEFW CYAN_DOOR_R28_R29  ; A cyan door to room $28
  DEFW DOOR_R29_R2A       ; A door to room $2A
  DEFW DOOR_R7E_R29       ; A door to room $7E
  DEFW TRAPDOOR_R29_R09   ; A trapdoor, falling to room $09
  DEFW A_C_G_SHIELD_R29_R7E ; An A.C.G. shield
  DEFW GHOST_PICTURE_R29_R7E ; A ghost picture
  DEFW $0000              ; End of the list

; What is in room $2A
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_2A:
  DEFW DOOR_R29_R2A       ; A door to room $29
  DEFW DOOR_R2A_R2B       ; A door to room $2B
  DEFW TABLE_R2A_R2D      ; A table
  DEFW TABLE_R2A_R2D_B    ; A table
  DEFW $0000              ; End of the list

; What is in room $2B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_2B:
  DEFW DOOR_R2A_R2B       ; A door to room $2A
  DEFW DOOR_R2B_R2C       ; A door to room $2C
  DEFW SUIT_OF_ARMOUR_R27_R2B ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R27_R2B_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $2C
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_2C:
  DEFW DOOR_R2B_R2C       ; A door to room $2B
  DEFW DOOR_R2C_R2D       ; A door to room $2D
  DEFW $0000              ; End of the list

; What is in room $2D
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_2D:
  DEFW DOOR_R2C_R2D       ; A door to room $2C
  DEFW GREEN_DOOR_R2D_R2E ; A green door to room $2E
  DEFW DOOR_R2D_R75       ; A door to room $75
  DEFW TRAPDOOR_R2D_R8D   ; A trapdoor, falling to room $8D
  DEFW TABLE_R2A_R2D      ; A table
  DEFW TABLE_R2A_R2D_B    ; A table
  DEFW $0000              ; End of the list

; What is in room $2E
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_2E:
  DEFW GREEN_DOOR_R2D_R2E ; A green door to room $2D
  DEFW DOOR_R2E_R27       ; A door to room $27
  DEFW TABLE_R2E_R7D      ; A table
  DEFW TABLE_R2E_R7D_B    ; A table
  DEFW $0000              ; End of the list

; What is in room $2F
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_2F:
  DEFW DOOR_R27_R2F       ; A big door to room $27
  DEFW YELLOW_DOOR_R20_R2F ; A yellow door to room $20
  DEFW $0000              ; End of the list

; What is in room $30
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $8B.
ROOM_LIST_30:
  DEFW CAVE_DOOR_R30_R31  ; A cave door to room $31
  DEFW CAVE_DOOR_R54_R30  ; A cave door to room $54
  DEFW CAVE_DOOR_R30_R74  ; A cave door to room $74
  DEFW $0000              ; End of the list

; What is in room $31
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_31:
  DEFW CAVE_DOOR_R30_R31  ; A cave door to room $30
  DEFW CAVE_DOOR_R31_R32  ; A cave door to room $32
  DEFW $0000              ; End of the list

; What is in room $32
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_32:
  DEFW CAVE_DOOR_R31_R32  ; A cave door to room $31
  DEFW CAVE_DOOR_R32_R33  ; A cave door to room $33
  DEFW $0000              ; End of the list

; What is in room $33
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_33:
  DEFW CAVE_DOOR_R32_R33  ; A cave door to room $32
  DEFW CAVE_DOOR_R33_R34  ; A cave door to room $34
  DEFW CAVE_DOOR_R33_R36  ; A cave door to room $36
  DEFW SKELETON_R33_R55   ; A skeleton
  DEFW $0000              ; End of the list

; What is in room $34
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_34:
  DEFW CAVE_DOOR_R33_R34  ; A cave door to room $33
  DEFW CAVE_DOOR_R34_R35  ; A cave door to room $35
  DEFW $0000              ; End of the list

; What is in room $35
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food, food and food.
ROOM_LIST_35:
  DEFW CAVE_DOOR_R34_R35  ; A cave door to room $34
  DEFW DOOR_R72_R35       ; A cave door to room $72
  DEFW CLOCK_R35_R8F      ; A clock (the knight only) to room $8F
  DEFW $0000              ; End of the list

; What is in room $36
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_36:
  DEFW CAVE_DOOR_R33_R36  ; A cave door to room $33
  DEFW CAVE_DOOR_R36_R37  ; A cave door to room $37
  DEFW $0000              ; End of the list

; What is in room $37
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_37:
  DEFW CAVE_DOOR_R36_R37  ; A cave door to room $36
  DEFW CAVE_DOOR_R37_R38  ; A cave door to room $38
  DEFW $0000              ; End of the list

; What is in room $38
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force.
ROOM_LIST_38:
  DEFW CAVE_DOOR_R37_R38  ; A cave door to room $37
  DEFW CAVE_DOOR_R38_R39  ; A cave door to room $39
  DEFW GREEN_CAVE_DOOR_R38_R3A ; A green cave door to room $3A
  DEFW BARREL_R38_R4B     ; A barrel (the serf only) to room $4B
  DEFW $0000              ; End of the list

; What is in room $39
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_39:
  DEFW CAVE_DOOR_R38_R39  ; A cave door to room $38
  DEFW CAVE_DOOR_R39_R3B  ; A cave door to room $3B
  DEFW $0000              ; End of the list

; What is in room $3A
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_3A:
  DEFW GREEN_CAVE_DOOR_R38_R3A ; A green cave door to room $38
  DEFW CAVE_DOOR_R3A_R3B  ; A cave door to room $3B
  DEFW CAVE_DOOR_R3A_R94  ; A cave door to room $94
  DEFW $0000              ; End of the list

; What is in room $3B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $82, mushroom, which drains the player's life force
; and mushroom, which drains the player's life force.
ROOM_LIST_3B:
  DEFW CAVE_DOOR_R39_R3B  ; A cave door to room $39
  DEFW CAVE_DOOR_R3A_R3B  ; A cave door to room $3A
  DEFW GREEN_CAVE_DOOR_R3B_R3C ; A green cave door to room $3C
  DEFW CAVE_DOOR_R3B_R3D  ; A cave door to room $3D
  DEFW $0000              ; End of the list

; What is in room $3C
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_3C:
  DEFW GREEN_CAVE_DOOR_R3B_R3C ; A green cave door to room $3B
  DEFW CAVE_DOOR_R3C_R3E  ; A cave door to room $3E
  DEFW $0000              ; End of the list

; What is in room $3D
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_3D:
  DEFW CAVE_DOOR_R3B_R3D  ; A cave door to room $3B
  DEFW CAVE_DOOR_R3D_R3E  ; A cave door to room $3E
  DEFW CYAN_CAVE_DOOR_R3D_R3F ; A cyan cave door to room $3F
  DEFW BOOKCASE_R3D_R49   ; A bookcase (the wizard only) to room $49
  DEFW BARREL_STACK_R91_R3D ; A barrel stack
  DEFW $0000              ; End of the list

; What is in room $3E
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_3E:
  DEFW CAVE_DOOR_R3C_R3E  ; A cave door to room $3C
  DEFW CAVE_DOOR_R3D_R3E  ; A cave door to room $3D
  DEFW BOOKCASE_R3E_R41   ; A bookcase (the wizard only) to room $41
  DEFW $0000              ; End of the list

; What is in room $3F
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_3F:
  DEFW CYAN_CAVE_DOOR_R3D_R3F ; A cyan cave door to room $3D
  DEFW CAVE_DOOR_R3F_R40  ; A cave door to room $40
  DEFW $0000              ; End of the list

; What is in room $40
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force.
ROOM_LIST_40:
  DEFW CAVE_DOOR_R3F_R40  ; A cave door to room $3F
  DEFW CAVE_DOOR_R40_R41  ; A cave door to room $41
  DEFW CAVE_DOOR_R40_R42  ; A cave door to room $42
  DEFW CAVE_DOOR_R40_R8F  ; A cave door to room $8F
  DEFW $0000              ; End of the list

; What is in room $41
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_41:
  DEFW CAVE_DOOR_R40_R41  ; A cave door to room $40
  DEFW BOOKCASE_R3E_R41   ; A bookcase (the wizard only) to room $3E
  DEFW $0000              ; End of the list

; What is in room $42
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_42:
  DEFW CAVE_DOOR_R40_R42  ; A cave door to room $40
  DEFW CAVE_DOOR_R42_R43  ; A cave door to room $43
  DEFW $0000              ; End of the list

; What is in room $43
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force and devil.
ROOM_LIST_43:
  DEFW CAVE_DOOR_R42_R43  ; A cave door to room $42
  DEFW CAVE_DOOR_R43_R44  ; A cave door to room $44
  DEFW CAVE_DOOR_R43_R46  ; A cave door to room $46
  DEFW CAVE_DOOR_R1D_R43  ; A cave door to room $1D
  DEFW $0000              ; End of the list

; What is in room $44
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_44:
  DEFW CAVE_DOOR_R43_R44  ; A cave door to room $43
  DEFW RED_CAVE_DOOR_R44_R45 ; A red cave door to room $45
  DEFW $0000              ; End of the list

; What is in room $45
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and mushroom, which drains the player's life force.
ROOM_LIST_45:
  DEFW RED_CAVE_DOOR_R44_R45 ; A red cave door to room $44
  DEFW BARREL_R45_R53     ; A barrel (the serf only) to room $53
  DEFW $0000              ; End of the list

; What is in room $46
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_46:
  DEFW CAVE_DOOR_R43_R46  ; A cave door to room $43
  DEFW CAVE_DOOR_R46_R47  ; A cave door to room $47
  DEFW CAVE_DOOR_R46_R51  ; A cave door to room $51
  DEFW $0000              ; End of the list

; What is in room $47
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_47:
  DEFW CAVE_DOOR_R46_R47  ; A cave door to room $46
  DEFW RED_CAVE_DOOR_R47_R48 ; A red cave door to room $48
  DEFW $0000              ; End of the list

; What is in room $48
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $83.
ROOM_LIST_48:
  DEFW RED_CAVE_DOOR_R47_R48 ; A red cave door to room $47
  DEFW CAVE_DOOR_R48_R49  ; A cave door to room $49
  DEFW CYAN_CAVE_DOOR_R48_R4A ; A cyan cave door to room $4A
  DEFW CAVE_DOOR_R48_R4D  ; A cave door to room $4D
  DEFW $0000              ; End of the list

; What is in room $49
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $89 and food.
ROOM_LIST_49:
  DEFW CAVE_DOOR_R48_R49  ; A cave door to room $48
  DEFW BOOKCASE_R3D_R49   ; A bookcase (the wizard only) to room $3D
  DEFW $0000              ; End of the list

; What is in room $4A
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_4A:
  DEFW CYAN_CAVE_DOOR_R48_R4A ; A cyan cave door to room $48
  DEFW CAVE_DOOR_R4A_R4B  ; A cave door to room $4B
  DEFW $0000              ; End of the list

; What is in room $4B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_4B:
  DEFW CAVE_DOOR_R4A_R4B  ; A cave door to room $4A
  DEFW CAVE_DOOR_R4B_R4C  ; A cave door to room $4C
  DEFW TRAPDOOR_R61_R4B   ; Where the trapdoor in room $61 lands: a rug
  DEFW BARREL_R38_R4B     ; A barrel (the serf only) to room $38
  DEFW $0000              ; End of the list

; What is in room $4C
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_4C:
  DEFW CAVE_DOOR_R4B_R4C  ; A cave door to room $4B
  DEFW CAVE_DOOR_R4C_R55  ; A cave door to room $55
  DEFW BARREL_R4C_R4E     ; A barrel (the serf only) to room $4E
  DEFW $0000              ; End of the list

; What is in room $4D
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_4D:
  DEFW CAVE_DOOR_R48_R4D  ; A cave door to room $48
  DEFW RED_CAVE_DOOR_R4D_R4E ; A red cave door to room $4E
  DEFW $0000              ; End of the list

; What is in room $4E
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_4E:
  DEFW RED_CAVE_DOOR_R4D_R4E ; A red cave door to room $4D
  DEFW CAVE_DOOR_R4E_R4F  ; A cave door to room $4F
  DEFW BARREL_R4C_R4E     ; A barrel (the serf only) to room $4C
  DEFW $0000              ; End of the list

; What is in room $4F
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_4F:
  DEFW CAVE_DOOR_R4E_R4F  ; A cave door to room $4E
  DEFW CAVE_DOOR_R4F_R50  ; A cave door to room $50
  DEFW $0000              ; End of the list

; What is in room $50
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force.
ROOM_LIST_50:
  DEFW CAVE_DOOR_R4F_R50  ; A cave door to room $4F
  DEFW CAVE_DOOR_R50_R51  ; A cave door to room $51
  DEFW GREEN_CAVE_DOOR_R50_R52 ; A green cave door to room $52
  DEFW $0000              ; End of the list

; What is in room $51
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_51:
  DEFW CAVE_DOOR_R50_R51  ; A cave door to room $50
  DEFW CAVE_DOOR_R46_R51  ; A cave door to room $46
  DEFW $0000              ; End of the list

; What is in room $52
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_52:
  DEFW GREEN_CAVE_DOOR_R50_R52 ; A green cave door to room $50
  DEFW CAVE_DOOR_R52_R53  ; A cave door to room $53
  DEFW $0000              ; End of the list

; What is in room $53
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: key, food, food and mushroom, which drains the player's life
; force.
ROOM_LIST_53:
  DEFW CAVE_DOOR_R52_R53  ; A cave door to room $52
  DEFW BARREL_R45_R53     ; A barrel (the serf only) to room $45
  DEFW SKELETON_R53_R8F   ; A skeleton
  DEFW $0000              ; End of the list

; What is in room $54
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force.
ROOM_LIST_54:
  DEFW CAVE_DOOR_R54_R55  ; A cave door to room $55
  DEFW CAVE_DOOR_R54_R30  ; A cave door to room $30
  DEFW CAVE_DOOR_R54_R90  ; A cave door to room $90
  DEFW $0000              ; End of the list

; What is in room $55
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: frankenstein's monster.
ROOM_LIST_55:
  DEFW CAVE_DOOR_R4C_R55  ; A cave door to room $4C
  DEFW CAVE_DOOR_R54_R55  ; A cave door to room $54
  DEFW SKELETON_R33_R55   ; A skeleton
  DEFW $0000              ; End of the list

; What is in room $56
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: humpback.
ROOM_LIST_56:
  DEFW DOOR_R56_R57       ; A door to room $57
  DEFW DOOR_R56_R5A       ; A door to room $5A
  DEFW CYAN_DOOR_R67_R56  ; A cyan door to room $67
  DEFW YELLOW_DOOR_R69_R56 ; A yellow door to room $69
  DEFW SUIT_OF_ARMOUR_R56_R24 ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R56_R24_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $57
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_57:
  DEFW DOOR_R56_R57       ; A door to room $56
  DEFW GREEN_DOOR_R57_R58 ; A green door to room $58
  DEFW DOOR_R57_R5B       ; A door to room $5B
  DEFW $0000              ; End of the list

; What is in room $58
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_58:
  DEFW GREEN_DOOR_R57_R58 ; A green door to room $57
  DEFW DOOR_R58_R59       ; A door to room $59
  DEFW DOOR_R58_R5C       ; A door to room $5C
  DEFW $0000              ; End of the list

; What is in room $59
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_59:
  DEFW DOOR_R58_R59       ; A door to room $58
  DEFW YELLOW_DOOR_R59_R5D ; A yellow door to room $5D
  DEFW RED_DOOR_R68_R59   ; A red door to room $68
  DEFW $0000              ; End of the list

; What is in room $5A
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_5A:
  DEFW DOOR_R5A_R5B       ; A door to room $5B
  DEFW DOOR_R56_R5A       ; A door to room $56
  DEFW CYAN_DOOR_R5A_R5E  ; A cyan door to room $5E
  DEFW WALL_ANTLERS_R5A_R27 ; Wall antlers
  DEFW WALL_TROPHY_R5A_R27 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $5B
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_5B:
  DEFW DOOR_R5A_R5B       ; A door to room $5A
  DEFW RED_DOOR_R5B_R5C   ; A red door to room $5C
  DEFW DOOR_R57_R5B       ; A door to room $57
  DEFW GREEN_DOOR_R5B_R5F ; A green door to room $5F
  DEFW YELLOW_DOOR_R66_R5B ; A yellow door to room $66
  DEFW TABLE_R5B_R5C      ; A table
  DEFW $0000              ; End of the list

; What is in room $5C
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_5C:
  DEFW RED_DOOR_R5B_R5C   ; A red door to room $5B
  DEFW GREEN_DOOR_R5C_R5D ; A green door to room $5D
  DEFW DOOR_R58_R5C       ; A door to room $58
  DEFW RED_DOOR_R5C_R60   ; A red door to room $60
  DEFW YELLOW_DOOR_R66_R5C ; A yellow door to room $66
  DEFW TABLE_R5B_R5C      ; A table
  DEFW $0000              ; End of the list

; What is in room $5D
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_5D:
  DEFW GREEN_DOOR_R5C_R5D ; A green door to room $5C
  DEFW YELLOW_DOOR_R59_R5D ; A yellow door to room $59
  DEFW DOOR_R5D_R61       ; A door to room $61
  DEFW TABLE_R63_R5D      ; A table
  DEFW WALL_ANTLERS_R66_R5D ; A pumpkin picture
  DEFW $0000              ; End of the list

; What is in room $5E
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_5E:
  DEFW RED_DOOR_R5E_R5F   ; A red door to room $5F
  DEFW CYAN_DOOR_R5A_R5E  ; A cyan door to room $5A
  DEFW DOOR_R5E_R62       ; A door to room $62
  DEFW $0000              ; End of the list

; What is in room $5F
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_5F:
  DEFW RED_DOOR_R5E_R5F   ; A red door to room $5E
  DEFW RED_DOOR_R5F_R60   ; A red door to room $60
  DEFW GREEN_DOOR_R5B_R5F ; A green door to room $5B
  DEFW CYAN_DOOR_R5F_R63  ; A cyan door to room $63
  DEFW YELLOW_DOOR_R66_R5F ; A yellow door to room $66
  DEFW $0000              ; End of the list

; What is in room $60
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_60:
  DEFW RED_DOOR_R5F_R60   ; A red door to room $5F
  DEFW DOOR_R60_R61       ; A door to room $61
  DEFW RED_DOOR_R5C_R60   ; A red door to room $5C
  DEFW CYAN_DOOR_R60_R64  ; A cyan door to room $64
  DEFW YELLOW_DOOR_R66_R60 ; A yellow door to room $66
  DEFW $0000              ; End of the list

; What is in room $61
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_61:
  DEFW DOOR_R60_R61       ; A door to room $60
  DEFW DOOR_R5D_R61       ; A door to room $5D
  DEFW DOOR_R61_R65       ; A door to room $65
  DEFW TRAPDOOR_R61_R4B   ; A trapdoor, falling to room $4B
  DEFW GHOST_PICTURE_R66_R61 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $62
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_62:
  DEFW DOOR_R62_R63       ; A door to room $63
  DEFW DOOR_R5E_R62       ; A door to room $5E
  DEFW GREEN_DOOR_R6A_R62 ; A green door to room $6A
  DEFW GHOST_PICTURE_R63_R62 ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $63
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_63:
  DEFW DOOR_R62_R63       ; A door to room $62
  DEFW DOOR_R63_R64       ; A door to room $64
  DEFW CYAN_DOOR_R5F_R63  ; A cyan door to room $5F
  DEFW TABLE_R63_R5D      ; A table
  DEFW GHOST_PICTURE_R63_R62 ; A ghost picture
  DEFW $0000              ; End of the list

; What is in room $64
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $84.
ROOM_LIST_64:
  DEFW DOOR_R63_R64       ; A door to room $63
  DEFW YELLOW_DOOR_R64_R65 ; A yellow door to room $65
  DEFW CYAN_DOOR_R60_R64  ; A cyan door to room $60
  DEFW A_C_G_SHIELD_R66_R64 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $65
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_65:
  DEFW YELLOW_DOOR_R64_R65 ; A yellow door to room $64
  DEFW DOOR_R61_R65       ; A door to room $61
  DEFW DOOR_R65_R1B       ; A door to room $1B
  DEFW TRAPDOOR_R03_R65   ; Where the trapdoor in room $03 lands: a rug
  DEFW WALL_TROPHY_R66_R65 ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $66
;
; 9 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: key, food and food.
ROOM_LIST_66:
  DEFW YELLOW_DOOR_R66_R5B ; A yellow door to room $5B
  DEFW YELLOW_DOOR_R66_R5C ; A yellow door to room $5C
  DEFW YELLOW_DOOR_R66_R5F ; A yellow door to room $5F
  DEFW YELLOW_DOOR_R66_R60 ; A yellow door to room $60
  DEFW TRAPDOOR_R15_R66   ; Where the trapdoor in room $15 lands: a rug
  DEFW GHOST_PICTURE_R66_R61 ; A ghost picture
  DEFW WALL_ANTLERS_R66_R5D ; Wall antlers
  DEFW WALL_TROPHY_R66_R65 ; A wall trophy
  DEFW A_C_G_SHIELD_R66_R64 ; An A.C.G. shield
  DEFW $0000              ; End of the list

; What is in room $67
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_67:
  DEFW CYAN_DOOR_R67_R56  ; A cyan door to room $56
  DEFW CLOCK_R67_R68      ; A clock (the knight only) to room $68
  DEFW $0000              ; End of the list

; What is in room $68
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_68:
  DEFW RED_DOOR_R68_R59   ; A red door to room $59
  DEFW CLOCK_R67_R68      ; A clock (the knight only) to room $67
  DEFW $0000              ; End of the list

; What is in room $69
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food, food and food.
ROOM_LIST_69:
  DEFW YELLOW_DOOR_R69_R56 ; A yellow door to room $56
  DEFW BOOKCASE_R69_R6A   ; A bookcase (the wizard only) to room $6A
  DEFW $0000              ; End of the list

; What is in room $6A
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_6A:
  DEFW GREEN_DOOR_R6A_R62 ; A green door to room $62
  DEFW BOOKCASE_R69_R6A   ; A bookcase (the wizard only) to room $69
  DEFW TABLE_R6A_R1B      ; A table
  DEFW $0000              ; End of the list

; What is in room $6B
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $85.
ROOM_LIST_6B:
  DEFW DOOR_R11_R6B       ; A door to room $11
  DEFW DOOR_R6B_R6C       ; A door to room $6C
  DEFW BARREL_R6B_R6D     ; A barrel (the serf only) to room $6D
  DEFW $0000              ; End of the list

; What is in room $6C
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_6C:
  DEFW DOOR_R6B_R6C       ; A door to room $6B
  DEFW CYAN_DOOR_R6C_R03  ; A cyan door to room $03
  DEFW TRAPDOOR_R8B_R6C   ; Where the trapdoor in room $8B lands: a rug
  DEFW BOOKCASE_R6C_R6E   ; A bookcase (the wizard only) to room $6E
  DEFW $0000              ; End of the list

; What is in room $6D
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: dracula.
ROOM_LIST_6D:
  DEFW GREEN_DOOR_R0F_R6D ; A green door to room $0F
  DEFW DOOR_R6D_R6E       ; A door to room $6E
  DEFW BARREL_R6B_R6D     ; A barrel (the serf only) to room $6B
  DEFW A_C_G_SHIELD_R6D_R0E ; An A.C.G. shield
  DEFW TABLE_R18_R6D      ; A table
  DEFW $0000              ; End of the list

; What is in room $6E
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_6E:
  DEFW DOOR_R6D_R6E       ; A door to room $6D
  DEFW DOOR_R6E_R05       ; A door to room $05
  DEFW TRAPDOOR_R8D_R6E   ; Where the trapdoor in room $8D lands: a rug
  DEFW BOOKCASE_R6C_R6E   ; A bookcase (the wizard only) to room $6C
  DEFW GHOST_PICTURE_R73_R6E ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $6F
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_6F:
  DEFW CYAN_DOOR_R0D_R6F  ; A cyan door to room $0D
  DEFW DOOR_R6F_R70       ; A door to room $70
  DEFW WALL_ANTLERS_R6F_R0E ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $70
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food, food and food.
ROOM_LIST_70:
  DEFW DOOR_R6F_R70       ; A door to room $6F
  DEFW DOOR_R70_R71       ; A door to room $71
  DEFW WALL_TROPHY_R70_R0D ; A wall trophy
  DEFW WALL_SHIELD_R70_R0C ; A wall shield
  DEFW $0000              ; End of the list

; What is in room $71
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_71:
  DEFW DOOR_R70_R71       ; A big door to room $70
  DEFW DOOR_R71_R72       ; A door to room $72
  DEFW $0000              ; End of the list

; What is in room $72
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_72:
  DEFW DOOR_R71_R72       ; A big door to room $71
  DEFW DOOR_R72_R35       ; A door to room $35
  DEFW $0000              ; End of the list

; What is in room $73
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_73:
  DEFW DOOR_R13_R73       ; A door to room $13
  DEFW TRAPDOOR_R73_R74   ; A trapdoor, falling to room $74
  DEFW WALL_ANTLERS_R10_R73 ; A wall trophy
  DEFW GHOST_PICTURE_R73_R6E ; A ghost picture
  DEFW $0000              ; End of the list

; What is in room $74
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food, mushroom, which drains the player's life force, mushroom,
; which drains the player's life force, mushroom, which drains the player's
; life force and mushroom, which drains the player's life force.
ROOM_LIST_74:
  DEFW CAVE_DOOR_R30_R74  ; A cave door to room $30
  DEFW TRAPDOOR_R73_R74   ; Where the trapdoor in room $73 lands: a rug
  DEFW $0000              ; End of the list

; What is in room $75
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_75:
  DEFW DOOR_R2D_R75       ; A door to room $2D
  DEFW DOOR_R75_R76       ; A door to room $76
  DEFW CLOCK_R76_R75      ; A clock (the knight only) to room $76
  DEFW $0000              ; End of the list

; What is in room $76
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_76:
  DEFW DOOR_R75_R76       ; A door to room $75
  DEFW DOOR_R76_R77       ; A door to room $77
  DEFW DOOR_R7D_R76       ; A door to room $7D
  DEFW TRAPDOOR_R76_R84   ; A trapdoor, falling to room $84
  DEFW CLOCK_R76_R75      ; A clock (the knight only) to room $75
  DEFW $0000              ; End of the list

; What is in room $77
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_77:
  DEFW DOOR_R76_R77       ; A door to room $76
  DEFW DOOR_R77_R78       ; A door to room $78
  DEFW $0000              ; End of the list

; What is in room $78
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_78:
  DEFW DOOR_R77_R78       ; A door to room $77
  DEFW DOOR_R78_R79       ; A door to room $79
  DEFW TRAPDOOR_R78_R8A   ; A trapdoor, falling to room $8A
  DEFW $0000              ; End of the list

; What is in room $79
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_79:
  DEFW DOOR_R78_R79       ; A door to room $78
  DEFW DOOR_R79_R7A       ; A door to room $7A
  DEFW $0000              ; End of the list

; What is in room $7A
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_7A:
  DEFW DOOR_R79_R7A       ; A door to room $79
  DEFW DOOR_R7A_R7B       ; A door to room $7B
  DEFW RED_DOOR_R7A_R7E   ; A red door to room $7E
  DEFW TABLE_R7A_R81      ; A table
  DEFW SUIT_OF_ARMOUR_R7C_R7A ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R7C_R7A_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $7B
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_7B:
  DEFW DOOR_R7A_R7B       ; A door to room $7A
  DEFW YELLOW_DOOR_R7B_R7C ; A yellow door to room $7C
  DEFW $0000              ; End of the list

; What is in room $7C
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_7C:
  DEFW YELLOW_DOOR_R7B_R7C ; A yellow door to room $7B
  DEFW YELLOW_DOOR_R7C_R7D ; A yellow door to room $7D
  DEFW SUIT_OF_ARMOUR_R7C_R7A ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R7C_R7A_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $7D
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_7D:
  DEFW YELLOW_DOOR_R7C_R7D ; A yellow door to room $7C
  DEFW DOOR_R7D_R76       ; A door to room $76
  DEFW TABLE_R2E_R7D      ; A table
  DEFW TABLE_R2E_R7D_B    ; A table
  DEFW $0000              ; End of the list

; What is in room $7E
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_7E:
  DEFW RED_DOOR_R7A_R7E   ; A red door to room $7A
  DEFW DOOR_R7E_R29       ; A door to room $29
  DEFW A_C_G_SHIELD_R29_R7E ; A wall trophy
  DEFW GHOST_PICTURE_R29_R7E ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $7F
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_7F:
  DEFW GREEN_DOOR_R7F_R80 ; A green door to room $80
  DEFW DOOR_R81_R7F       ; A door to room $81
  DEFW SUIT_OF_ARMOUR_R09_R7F ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R09_R7F_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $80
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food, food and food.
ROOM_LIST_80:
  DEFW GREEN_DOOR_R7F_R80 ; A green door to room $7F
  DEFW DOOR_R80_R82       ; A door to room $82
  DEFW $0000              ; End of the list

; What is in room $81
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_81:
  DEFW DOOR_R82_R81       ; A door to room $82
  DEFW DOOR_R81_R7F       ; A door to room $7F
  DEFW TABLE_R7A_R81      ; A table
  DEFW $0000              ; End of the list

; What is in room $82
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_82:
  DEFW DOOR_R80_R82       ; A door to room $80
  DEFW DOOR_R82_R81       ; A door to room $81
  DEFW CYAN_DOOR_R82_R87  ; A cyan door to room $87
  DEFW WALL_SHIELD_R00_R82 ; A wall trophy
  DEFW WALL_TROPHY_R00_R82 ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $83
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_83:
  DEFW RED_DOOR_R83_R84   ; A red door to room $84
  DEFW DOOR_R85_R83       ; A door to room $85
  DEFW $0000              ; End of the list

; What is in room $84
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: collectable $87.
ROOM_LIST_84:
  DEFW RED_DOOR_R83_R84   ; A red door to room $83
  DEFW DOOR_R84_R86       ; A door to room $86
  DEFW YELLOW_DOOR_R84_R89 ; A yellow door to room $89
  DEFW TRAPDOOR_R76_R84   ; Where the trapdoor in room $76 lands: a rug
  DEFW $0000              ; End of the list

; What is in room $85
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_85:
  DEFW DOOR_R86_R85       ; A door to room $86
  DEFW DOOR_R85_R83       ; A door to room $83
  DEFW $0000              ; End of the list

; What is in room $86
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_86:
  DEFW DOOR_R84_R86       ; A door to room $84
  DEFW DOOR_R86_R85       ; A door to room $85
  DEFW $0000              ; End of the list

; What is in room $87
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_87:
  DEFW CYAN_DOOR_R82_R87  ; A cyan door to room $82
  DEFW DOOR_R87_R88       ; A door to room $88
  DEFW DOOR_R87_R8B       ; A door to room $8B
  DEFW WALL_ANTLERS_R87_R89 ; Wall antlers
  DEFW WALL_TROPHY_R87_R89 ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $88
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_88:
  DEFW DOOR_R21_R88       ; A door to room $21
  DEFW DOOR_R87_R88       ; A door to room $87
  DEFW TABLE_R18_R88      ; A table
  DEFW SUIT_OF_ARMOUR_R88_R8A ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R88_R8A_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $89
;
; 5 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_89:
  DEFW YELLOW_DOOR_R84_R89 ; A yellow door to room $84
  DEFW DOOR_R89_R8D       ; A door to room $8D
  DEFW DOOR_R89_R8A       ; A door to room $8A
  DEFW WALL_ANTLERS_R87_R89 ; A wall trophy
  DEFW WALL_TROPHY_R87_R89 ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $8A
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food and food.
ROOM_LIST_8A:
  DEFW DOOR_R89_R8A       ; A door to room $89
  DEFW GREEN_DOOR_R8A_R23 ; A green door to room $23
  DEFW TRAPDOOR_R78_R8A   ; Where the trapdoor in room $78 lands: a rug
  DEFW BARREL_R8A_R08     ; A barrel (the serf only) to room $08
  DEFW SUIT_OF_ARMOUR_R88_R8A ; A suit of armour
  DEFW SUIT_OF_ARMOUR_R88_R8A_B ; A suit of armour
  DEFW $0000              ; End of the list

; What is in room $8B
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_8B:
  DEFW DOOR_R87_R8B       ; A door to room $87
  DEFW DOOR_R8B_R8C       ; A door to room $8C
  DEFW TRAPDOOR_R8B_R6C   ; A trapdoor, falling to room $6C
  DEFW WALL_ANTLERS_R8B_R8C ; Wall antlers
  DEFW $0000              ; End of the list

; What is in room $8C
;
; 4 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: food.
ROOM_LIST_8C:
  DEFW DOOR_R8B_R8C       ; A door to room $8B
  DEFW GREEN_DOOR_R8C_R8D ; A green door to room $8D
  DEFW A_C_G_SHIELD_R8D_R8C ; A wall shield
  DEFW WALL_ANTLERS_R8B_R8C ; A wall trophy
  DEFW $0000              ; End of the list

; What is in room $8D
;
; 6 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_8D:
  DEFW GREEN_DOOR_R8C_R8D ; A green door to room $8C
  DEFW DOOR_R89_R8D       ; A door to room $89
  DEFW TRAPDOOR_R2D_R8D   ; Where the trapdoor in room $2D lands: a rug
  DEFW TRAPDOOR_R8D_R6E   ; A trapdoor, falling to room $6E
  DEFW A_C_G_SHIELD_R8D_R8C ; An A.C.G. shield
  DEFW CLOCK_R8D_R22      ; A clock (the knight only) to room $22
  DEFW $0000              ; End of the list

; What is in room $8E
;
; 1 record, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_8E:
  DEFW A_C_G_DOOR_R00_R8E ; An A.C.G. door to room $00
  DEFW $0000              ; End of the list

; What is in room $8F
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
;
; Also here when a game starts, found by their own room byte rather than named
; in the list: mushroom, which drains the player's life force, mushroom, which
; drains the player's life force and mushroom, which drains the player's life
; force.
ROOM_LIST_8F:
  DEFW CAVE_DOOR_R40_R8F  ; A cave door to room $40
  DEFW CLOCK_R35_R8F      ; A clock (the knight only) to room $35
  DEFW SKELETON_R53_R8F   ; A skeleton
  DEFW $0000              ; End of the list

; What is in room $90
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_90:
  DEFW CAVE_DOOR_R54_R90  ; A cave door to room $54
  DEFW CAVE_DOOR_R90_R91  ; A cave door to room $91
  DEFW $0000              ; End of the list

; What is in room $91
;
; 3 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_91:
  DEFW CAVE_DOOR_R90_R91  ; A cave door to room $90
  DEFW CAVE_DOOR_R91_R92  ; A cave door to room $92
  DEFW BARREL_STACK_R91_R3D ; A barrel stack
  DEFW $0000              ; End of the list

; What is in room $92
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_92:
  DEFW CAVE_DOOR_R91_R92  ; A cave door to room $91
  DEFW CAVE_DOOR_R92_R93  ; A cave door to room $93
  DEFW $0000              ; End of the list

; What is in room $93
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_93:
  DEFW CAVE_DOOR_R92_R93  ; A cave door to room $92
  DEFW CAVE_DOOR_R93_R94  ; A cave door to room $94
  DEFW $0000              ; End of the list

; What is in room $94
;
; 2 records, then a zero to end the list. Each entry is its record in
; INITIAL_STATE, which POPULATE_ROOM relocates to where the running game keeps
; it.
ROOM_LIST_94:
  DEFW CAVE_DOOR_R93_R94  ; A cave door to room $93
  DEFW CAVE_DOOR_R3A_R94  ; A cave door to room $3A
  DEFW $0000              ; End of the list

; What is in room $95
;
; Nothing at all: just the terminator. An empty room.
ROOM_LIST_95:
  DEFW $0000              ; End of the list

; Title screen: draw the menu and poll for a selection
;
; Used by the routine at ENTRY.
;
; Runs the "ATICATAC GAME SELECTION" menu -- control method (1-3), character
; (4-6) and 0 to start. Both answers are packed into the one byte at $5E00:
; bits 1 and 2 are the control method, which READ_CONTROLS picks out with AND
; $06, and bits 3 and 4 the character, which DRAW_LIVES turns back into a
; sprite number. Reading it after choosing each character in turn gives $00,
; $08 and $10.
TITLE_SCREEN:
  LD HL,SELECTION         ; $5E00 is the base of the game-state block; the
                          ; first 16 bytes are zeroed here.
  LD B,$10
TITLE_SCREEN_0:
  LD (HL),$00
  INC HL
  DJNZ TITLE_SCREEN_0
  LD HL,TEXT_FONT-$0100   ; Point the tile source at the text font, so the menu
  LD (TILE_SOURCE),HL     ; can be drawn with PRINT_STRING.
; This entry point is used by the routine at GAME_OVER.
TITLE_AGAIN:
  CALL CLEAR_SCREEN       ; }
  CALL DRAW_TITLE_ICONS
TITLE_SCREEN_1:
  CALL DRAW_MENU
  LD A,$F7                ; Select the half-row holding keys 1-5. The OUT to
  OUT ($FD),A             ; $FD is inert on a 48K; what matters is that A is
  IN A,($FE)              ; left as the high address byte for the IN that
                          ; follows.
  CPL                     ; Keyboard bits are active-low, so CPL makes a set
                          ; bit mean "pressed".
  LD E,A
  LD A,(SELECTION)
  BIT 0,E
  JR Z,TITLE_SCREEN_2
  AND $F9
TITLE_SCREEN_2:
  BIT 1,E
  JR Z,TITLE_SCREEN_3
  AND $F9
  OR $02
TITLE_SCREEN_3:
  BIT 2,E
  JR Z,TITLE_SCREEN_4
  AND $F9
  OR $04
TITLE_SCREEN_4:
  BIT 3,E
  JR Z,TITLE_SCREEN_5
  AND $E7
TITLE_SCREEN_5:
  BIT 4,E
  JR Z,TITLE_SCREEN_6
  AND $E7
  OR $08
TITLE_SCREEN_6:
  LD D,A
  LD A,$EF
  OUT ($FD),A
  IN A,($FE)
  CPL
  LD E,A
  LD A,D
  BIT 4,E
  JR Z,TITLE_SCREEN_7
  AND $E7
  OR $10
TITLE_SCREEN_7:
  LD (SELECTION),A
  LD C,A
  BIT 0,E
  JP NZ,START_GAME
  LD HL,MENU_DATA
  LD B,$03
  LD A,C
  CALL HIGHLIGHT_LINE
  LD B,$03
  LD A,C
  RRCA
  RRCA
  CALL HIGHLIGHT_LINE
  JP TITLE_SCREEN_1

; Flash or unflash a whole menu line
;
; Used by the routine at TITLE_SCREEN.
;
; Walks a line of attributes calling one or other of the two routines above, so
; a whole option lights up rather than a single character.
HIGHLIGHT_LINE:
  RRCA
HIGHLIGHT_LINE_0:
  AND $03
  JR Z,HIGHLIGHT_LINE_2
  CALL UNHIGHLIGHT
HIGHLIGHT_LINE_1:
  DEC A
  DJNZ HIGHLIGHT_LINE_0
  RET
HIGHLIGHT_LINE_2:
  CALL HIGHLIGHT
  JR HIGHLIGHT_LINE_1

; Mark the menu line under the cursor
;
; SET 7,(HL) then INC HL. Setting bit 7 of a character is the end marker
; everywhere else, but here it is being used on the menu's attribute bytes to
; pick a line out.
SET_HIGHLIGHT:
  SET 7,(HL)
  INC HL

; Take the highlight off a menu cell
;
; Used by the routine at HIGHLIGHT_LINE.
;
; Clears bit 7 of an attribute -- the FLASH bit -- and steps on. The title
; screen shows the current choice by flashing it, so selecting is a matter of
; turning this bit off one line and on another.
UNHIGHLIGHT:
  RES 7,(HL)
  INC HL
  RET

; Unmark it again
;
; The other half of SET_HIGHLIGHT: RES 7,(HL) then INC HL.
CLEAR_HIGHLIGHT:
  RES 7,(HL)
  INC HL

; Put the highlight on a menu cell
;
; Used by the routine at HIGHLIGHT_LINE.
;
; Sets the bit UNHIGHLIGHT clears.
HIGHLIGHT:
  SET 7,(HL)
  INC HL
  RET

; Draw the title screen's list of options
;
; Used by the routine at TITLE_SCREEN.
;
; Points the tile source at the text font and then walks seven entries, each
; with its own string and position, writing the current one into $5E22 as it
; goes. Those seven are the six choices -- three control methods and three
; characters -- and the line that starts the game.
DRAW_MENU:
  LD HL,TEXT_FONT-$0100   ; The text font, less $100: TEXT_FONT-$100
  LD (TILE_SOURCE),HL
  LD DE,MENU_DATA
  EXX
  LD HL,MENU_ROWS
  LD DE,MENU_TEXT
  LD B,$07
DRAW_MENU_0:
  EXX
  LD A,(DE)
  LD (MENU_COLOUR),A
  INC DE
  EXX
  PUSH BC
  LD A,(HL)
  INC HL
  PUSH HL
  LD H,A
  LD L,$58
  CALL PRINT_MENU_LINE
  EXX
  POP HL
  POP BC
  INC DE
  DJNZ DRAW_MENU_0
  LD HL,$B800
  LD DE,COPYRIGHT_LINE
  CALL PRINT_STRING
  LD HL,$0020
  LD DE,MENU_TITLE
  JP PRINT_STRING

; The title screen's menu
;
; Three tables and then the words. The seven lines are drawn by DRAW_MENU,
; which walks the colours and the row positions in step and takes each string
; in turn; a character with bit 7 set ends a string, which is why there are no
; lengths anywhere.
;
; The last two strings are not part of the seven and carry their own colour
; byte in front, so they can be printed on their own.
MENU_DATA:
  DEFB $45,$45,$45,$45,$45,$45,$47 ; The colour of each line -- six in $45 and
                                   ; the last in $47, which is what makes START
                                   ; GAME brighter than the choices above it.
MENU_ROWS:
  DEFB $10,$28,$40,$58,$70,$88,$A0 ; The row each is drawn at, 24 pixels apart.
MENU_TEXT:
  DEFM "1  KEYBOAR",$C4
  DEFM "2  KEMPSTON JOYSTIC",$CB
  DEFM "3  CURSOR   JOYSTIC",$CB
  DEFM "4  KNIGH",$D4
  DEFM "5  WIZAR",$C4
  DEFM "6  SER",$C6
  DEFM "0  START GAM",$C5
COPYRIGHT_LINE:
  DEFM "G%1983 A.C.G. ALL RIGHTS RESERVE",$C4 ; The copyright line. "%" is the
                                              ; copyright sign in this font,
                                              ; not a per cent.
MENU_TITLE:
  DEFM "GATICATAC GAME SELECTIO",$CE

; Print one line of the menu
;
; Used by the routine at DRAW_MENU.
;
; Works out the display address and the attribute address for the same point --
; one in each register bank, the trick PRINT_STRING uses -- and draws the line
; with the colour held at $5E22.
PRINT_MENU_LINE:
  PUSH HL
  CALL PIXEL_TO_SCREEN
  LD A,(MENU_COLOUR)
  EX AF,AF'
  EXX
  POP HL
  CALL PIXEL_TO_ATTR
  JP PRINT_STRING_REST

; Set a new game up
;
; Used by the routine at TITLE_SCREEN.
;
; Clears the variables, sets the lives to three, points the cursor at $EB58,
; blanks the screen and goes on to build the castle. Everything a game needs to
; be true at its first frame is made true here.
START_GAME:
  CALL CLEAR_VARIABLES
  LD A,$03
  LD (LIVES),A
  LD HL,LIVE_FOOD
  LD (CURSOR),HL
  CALL CLEAR_SCREEN
  CALL DRAW_SCROLL
  CALL DRAW_LIVES
  CALL ROTATING_INDEX
  CALL PLACE_KEYS
  CALL LOAD_INITIAL_STATE
  CALL SCAN_DOORS
  CALL PLACE_PLAYER
  JP ARRIVE_IN_ROOM

; The loop the whole game runs in
;
; Used by the routines at MAIN_LOOP_MONSTERS and ENTER_ROOM.
;
; Everything the game does happens here. It walks three tables of records and
; hands each one to DISPATCH_ACTOR, which finds its handler from its sprite
; byte; there is no other structure above this. Monsters, doors, objects, the
; player and even the sound effects are all just records this loop reaches.
;
; The three tables have different shapes and are treated differently. From
; $EAA8 to $EE60 are eight-byte records -- objects, collectables, sounds -- and
; those are only dispatched if their room matches the player's. From $EE60 to
; $EEE0 are the sixteen-byte monster records, dispatched every pass whatever
; room they are in, which is how creatures keep moving around a castle you
; cannot see. From $EEE0 up are the doors, eight bytes again.
;
; Two details in the first three instructions are worth more than they look.
; The stack pointer is reset at the top of every pass, so no handler has to
; leave the stack as it found it -- which is what lets LOSE_FOOD_16 abandon its
; caller and jump straight to the death routine. And the EI here is where the
; DI at the entry point is finally lifted: everything before this runs with
; interrupts off.
MAIN_LOOP:
  LD SP,$5E00             ; Reset the stack every pass; handlers need not
                          ; balance it.
  EI                      ; Interrupts on. This is where the DI at ENTRY is
                          ; undone.
  XOR A                   ; Count of actors in the player's room, recounted
  LD (ACTORS_HERE),A      ; each pass.
  LD IX,LIVE_OBJECTS      ; The first table: objects and sounds, eight bytes
                          ; each.
  LD A,(ROOM_DRAWN)
  BIT 0,A
  JR NZ,MAIN_LOOP_0
  LD IX,LIVE_DOORS
  JR ROOM_LIST_PASS
MAIN_LOOP_0:
  LD A,(FRAMES)
  LD C,A
  LD A,(LAST_FRAME)
  CP C
  CALL NZ,FRAME_TICK
  LD A,(PLAYER_ROOM)      ; Only things in the player's room are dispatched
  CP (IX+$01)             ; from this one.
  LD HL,NEXT_OBJECT       ; The return address goes in HL, and the dispatch is
  JP Z,DISPATCH_ACTOR     ; a jump rather than a call.
NEXT_OBJECT:
  LD DE,$0008             ; Eight bytes to the next record.
  ADD IX,DE               ;
  PUSH IX                 ; Until the monster table is reached.
  POP HL                  ;
  LD DE,LIVE_MONSTERS     ;
  AND A                   ;
  SBC HL,DE               ;
  JR C,MAIN_LOOP_0
; This entry point is used by the routine at MAIN_LOOP_MONSTERS.
NEXT_MONSTER:
  LD A,(FRAMES)
  LD C,A
  LD A,(LAST_FRAME)
  CP C
  CALL NZ,FRAME_TICK
  LD HL,MAIN_LOOP_MONSTERS
  JR DISPATCH_ACTOR

; The second pass: the monsters
;
; Sixteen bytes a record rather than eight, and no room test -- every monster
; is dispatched every pass wherever it is. That is what keeps the castle alive
; behind the player rather than freezing rooms they have left.
MAIN_LOOP_MONSTERS:
  LD DE,$0010             ; Sixteen bytes to the next monster.
  ADD IX,DE               ;
  PUSH IX                 ; Until the door table is reached.
  POP HL                  ;
  LD DE,LIVE_DOORS        ;
  AND A                   ;
  SBC HL,DE               ;
  JR C,NEXT_MONSTER
; This entry point is used by the routine at MAIN_LOOP.
ROOM_LIST_PASS:
  LD A,(PLAYER_ROOM)
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,ROOM_CONTENTS
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (LIST_POINTER),HL
NEXT_IN_LIST:
  LD HL,(LIST_POINTER)
  LD A,(HL)
  INC HL
  INC HL
  LD (LIST_POINTER),HL
  DEC HL
  LD H,(HL)
  LD L,A
  OR H
  JR NZ,DISPATCH_FROM_LIST
  LD HL,(TICKS)
  INC HL
  LD (TICKS),HL
  LD HL,ROOM_DRAWN
  BIT 0,(HL)
  JR NZ,MAIN_LOOP_MONSTERS_0
  CALL DRAW_ROOM_CONTENTS
MAIN_LOOP_MONSTERS_0:
  LD HL,ROOM_DRAWN
  SET 0,(HL)
  LD HL,(RUNNING_SUM)
  LD DE,(FRAMES)
  ADD HL,DE
  LD A,(TICKS)
  ADD A,L
  LD L,A
  LD (RUNNING_SUM),HL
  CALL READ_FIRE_ROW
  CALL CHECK_KEY_HELD
  CALL ADVANCE_CURSOR
  LD A,(PLAYER_ROOM)
  CP $8E
  JP Z,SHOW_END_SCREEN
  JP MAIN_LOOP

; Jump to the handler for whatever this actor is
;
; Used by the routine at MAIN_LOOP.
;
; Looks the actor's +$00 byte up in ACTOR_HANDLERS and jumps to the address it
; finds. This is why so many of the per-creature routines have nothing
; referencing them anywhere in the disassembly -- they are only ever reached
; from that table, which to a disassembler is just data.
;
; The jump itself is worth a look. Rather than an equivalent sequence ending in
; JP (HL), the routine jumps to $5CB0 -- an address in the system variables,
; well outside the game. What lives there is a single $E9 byte, which is the
; opcode for JP (HL), and it got there because one of the five blocks on the
; tape is one byte long and loads to exactly that address. So the dispatch runs
; through an instruction the loader poked into spare ROM-variable space, and a
; loader that skips that block leaves the game jumping into whatever happened
; to be at $5CB0.
;
; IX The actor
DISPATCH_ACTOR:
  PUSH HL                 ; The caller left the address to come back to in HL,
                          ; and this puts it on the stack -- so the handler's
                          ; own RET returns into MAIN_LOOP, and the dispatch
                          ; itself costs a jump rather than a call.
; This entry point is used by the routine at FRAME_TICK.
DISPATCH_PUSHED:
  LD HL,ACTOR_HANDLERS    ; The table.
; This entry point is used by the routine at DISPATCH_FROM_LIST.
DISPATCH_IN_TABLE:
  LD C,(IX+$00)           ; The actor's sprite byte doubles as its type.
; This entry point is used by the routine at DRAW_SPRITE_PIXELS.
DISPATCH_TYPE_C:
  LD B,$00                ; Two bytes per entry, so double the index -- through
  SLA C                   ; B as well, since types run past $7F.
  RL B                    ;
  ADD HL,BC
  LD A,(HL)               ; Fetch the handler address into HL.
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  JP JP_HL_POKE           ; The poked JP (HL).

; Dispatch a record named in a room's list
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Takes an entry as ROOM_CONTENTS stores it, subtracts the ROOM_CONTENTS bias
; to get the real address, puts it in IX and dispatches it -- pushing a return
; address first, the same convention MAIN_LOOP uses.
DISPATCH_FROM_LIST:
  LD BC,NEXT_IN_LIST
  PUSH BC
  LD BC,ROOM_CONTENTS
  AND A
  SBC HL,BC
  PUSH HL
  POP IX
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR Z,DISPATCH_FROM_LIST_0
  LD BC,$0008
  ADD IX,BC
DISPATCH_FROM_LIST_0:
  LD HL,ACTOR_HANDLERS+$0144 ; ACTOR_HANDLERS + 2 * $A2, where the room
                             ; records' handlers start
  JR DISPATCH_IN_TABLE

; The work that happens once per frame
;
; Used by the routine at MAIN_LOOP.
;
; MAIN_LOOP runs as fast as it can and calls this only when the ROM's frame
; counter has moved on, so what happens here is tied to the 50Hz interrupt
; rather than to how much there is to do.
;
; It dispatches three records the main loop deliberately skips -- $EA90, $EA98
; and $EAA0, the player, the weapon it has in flight, and the sound effect slot
; -- and then ticks the clock. That is why the player moves at a steady speed
; however crowded a room is, while the monsters are dispatched on every pass of
; the outer loop.
;
; It runs with interrupts off, so a frame's work is never interrupted half way.
FRAME_TICK:
  DI                      ; Nothing may interrupt a frame's work.
  PUSH IX
  LD A,$01                ; A flag saying a frame is in progress.
  LD (IN_FRAME),A         ;
  LD IX,PLAYER            ; The player, first of the three.
; This entry point is used by the routine at FRAME_TICK_NEXT.
TICK_DISPATCH:
  LD HL,FRAME_TICK_NEXT   ; Push the return address, then enter DISPATCH_ACTOR
  PUSH HL                 ; below its own PUSH HL -- it has already been done
                          ; here.
  JP DISPATCH_PUSHED      ; Dispatch.

; On to the next of the three, then the clock
;
; Eight bytes at a time from the player up to $EAA8, which is where MAIN_LOOP's
; own first table begins -- so between them the two loops cover every record
; exactly once, at two different rates.
FRAME_TICK_NEXT:
  LD DE,$0008             ; Eight bytes on.
  ADD IX,DE               ;
  PUSH IX                 ; Until the main loop's first table is reached.
  POP HL                  ;
  LD DE,LIVE_OBJECTS      ;
  AND A                   ;
  SBC HL,DE               ;
  JR C,TICK_DISPATCH
  CALL TICK_CLOCK         ; Then advance the clock.
  LD A,(FRAMES)
  LD (LAST_FRAME),A
  XOR A
  LD (IN_FRAME),A
  POP IX
  EI
  RET

; Handler address for each actor type
;
; 202 addresses, indexed by an actor's +$00 byte, used by DISPATCH_ACTOR.
; Entries come in runs of two or four because the low bits of +$00 are the
; animation frame rather than part of the identity -- $5C and $5D are the two
; frames of one creature and share a handler, as do $58 to $5B.
;
; The first three runs are the playable characters -- $01-$10 knight, $11-$20
; wizard, $21-$30 serf -- sixteen sprite codes each, which is what makes "below
; $31" mean "is a player" in CHECK_HIT. Confirmed by starting a game as each of
; the three in turn and reading the player's sprite byte back: $08, $18 and
; $28, the same offset into each band.
;
; Checked against the running game: the monster at $EE80 had sprite byte $5C,
; the table entry two bytes into ACTOR_HANDLERS + $5C * 2 reads MOVE_ACTOR, and
; a breakpoint at MOVE_ACTOR does fire with IX pointing at that monster.
ACTOR_HANDLERS:
  DEFW INERT_SPRITE
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_KNIGHT
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_WIZARD
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW UPDATE_SERF
  DEFW PUT_DOWN
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW SPIN_SPELL
  DEFW SPIN_SPELL
  DEFW SPIN_SPELL
  DEFW SPIN_SPELL
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_SWORD
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW SPIN_AXE
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW MOVE_ACTOR
  DEFW MOVE_ACTOR
  DEFW MOVE_BAT
  DEFW MOVE_BAT
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW EAT_FOOD
  DEFW SPAWN_MONSTER
  DEFW SPAWN_MONSTER
  DEFW SPAWN_MONSTER
  DEFW SPAWN_MONSTER
  DEFW MOVE_ACTOR
  DEFW MOVE_ACTOR
  DEFW MOVE_GHOST_ALT
  DEFW MOVE_GHOST_ALT
  DEFW MOVE_871A
  DEFW MOVE_871A
  DEFW MOVE_GHOST
  DEFW MOVE_GHOST
  DEFW SOUND_64
  DEFW SOUND_65
  DEFW MATERIALISING
  DEFW DYING
  DEFW MOVE_GHOST_ALT
  DEFW MOVE_GHOST_ALT
  DEFW MOVE_BAT_ALT
  DEFW MOVE_BAT_ALT
  DEFW COUNTDOWN_ACTOR
  DEFW COUNTDOWN_ACTOR
  DEFW COUNTDOWN_ACTOR
  DEFW COUNTDOWN_ACTOR
  DEFW MOVE_MUMMY
  DEFW MOVE_MUMMY
  DEFW MOVE_MUMMY
  DEFW MOVE_MUMMY
  DEFW MOVE_FRANKENSTEIN
  DEFW MOVE_FRANKENSTEIN
  DEFW MOVE_FRANKENSTEIN
  DEFW MOVE_FRANKENSTEIN
  DEFW MOVE_DEVIL
  DEFW MOVE_DEVIL
  DEFW MOVE_DEVIL
  DEFW MOVE_DEVIL
  DEFW MOVE_DRACULA
  DEFW MOVE_DRACULA
  DEFW MOVE_DRACULA
  DEFW MOVE_DRACULA
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW PICK_UP
  DEFW GRAVESTONE
  DEFW MOVE_WITCH
  DEFW MOVE_WITCH
  DEFW MOVE_WITCH
  DEFW MOVE_WITCH
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_8A80
  DEFW MOVE_HUMPBACK
  DEFW MOVE_HUMPBACK
  DEFW MOVE_HUMPBACK
  DEFW MOVE_HUMPBACK
  DEFW SOUND_A0
  DEFW MUSHROOM
  DEFW INERT_SPRITE
  DEFW DOOR
  DEFW DOOR
  DEFW BIG_DOOR
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW DOOR_LOCKED_A
  DEFW DOOR_LOCKED_A
  DEFW DOOR_LOCKED_A
  DEFW DOOR_LOCKED_A
  DEFW DOOR_LOCKED_B
  DEFW DOOR_LOCKED_B
  DEFW DOOR_LOCKED_B
  DEFW DOOR_LOCKED_B
  DEFW DOOR_KNIGHT
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW INERT_SPRITE
  DEFW INERT_SPRITE
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW DOOR_WIZARD
  DEFW FLASH_AND_RASP
  DEFW TRAPDOOR
  DEFW DOOR_SERF
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW INERT_SPRITE
  DEFW WAIT_THEN_ACT
  DEFW WAIT_THEN_DOOR
  DEFW WAIT_THEN_ACT
  DEFW WAIT_THEN_DOOR
  DEFW ACG_DOOR
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR
  DEFW DRAW_DOOR

; A sprite that does nothing at all
;
; The handler for everything that is drawn but never acts -- the three
; control-method pictures on the title screen among them. It checks whether IX
; is one of the first three monster records and, if it is, burns a couple of
; hundred cycles doing nothing; otherwise it returns at once.
;
; The delay looks pointless but is not: those three slots are drawn every frame
; whatever occupies them, and an inert occupant that returned instantly would
; make the frame shorter than one holding a creature. Spending the time keeps
; the pace even.
INERT_SPRITE:
  PUSH IX                 ; IX, as a number, against the base of the monster
  POP HL                  ; table.
  LD DE,LIVE_MONSTERS     ;
  AND A                   ; Not in the table at all -- nothing to do.
  SBC HL,DE               ;
  LD A,H                  ;
  AND A                   ;
  RET NZ                  ;
  LD A,L                  ; Only the first three slots get the delay.
  CP $30                  ;
  RET NC                  ;
  LD HL,$00C0             ; 192, counted down and thrown away.
INERT_SPRITE_0:
  DEC HL                  ; The delay itself.
  LD A,H                  ;
  OR L                    ;
  JR NZ,INERT_SPRITE_0    ;
  RET

; Clear the play area, leaving the status panel alone
;
; Used by the routines at GAME_OVER, ENTER_ROOM and TRAPDOOR_FALL.
;
; Blanks the 24 character columns the castle is drawn in and stops there, so
; the parchment scroll down the right-hand side -- score, time, lives and the
; inventory -- survives untouched and does not have to be redrawn on every room
; change.
;
; Verified by running it against a live room and reading the display file back:
; columns 0-23 came back all zero, columns 24-31 unchanged.
CLEAR_PLAY_AREA:
  LD HL,$4000             ; 24 bytes across, 192 display-file rows -- the whole
  LD BC,$18C0             ; height of the screen, but only three quarters of
                          ; its width.
  XOR A                   ; The fill byte. Blank here, but the shared entry
                          ; below takes whatever is in A.

; Fill a rectangular block of the display file
;
; Used by the routines at DRAW_ROOM and PAINT_PANEL.
;
; The general form of CLEAR_PLAY_AREA above, which falls into it. Because it
; steps by a fixed 32 bytes per row rather than doing any display-file address
; arithmetic, "rows" here means consecutive 32-byte rows of the display file,
; not screen lines -- walking $4000 upwards covers the interleaved thirds in
; the order they are stored.
;
; HL Top-left corner, as a display file address
; B Width in bytes (character columns)
; C Number of rows
; A The byte to fill with
FILL_BLOCK:
  PUSH BC                 ; Both are needed again on the next row, so they are
  PUSH HL                 ; saved rather than recomputed.
  LD DE,$0020             ; One display-file row is 32 bytes.
FILL_BLOCK_0:
  LD (HL),A               ; Fill B bytes across.
  INC HL                  ;
  DJNZ FILL_BLOCK_0       ;
  POP HL
  ADD HL,DE               ; Step down to the next row.
  POP BC
  DEC C
  JR NZ,FILL_BLOCK
  RET

; Blank everything and black the border
;
; Used by the routines at TITLE_SCREEN and START_GAME.
;
; Bitmap, attributes, and then an OUT to port $FE with zero, which sets the
; border black. The whole screen gone in three calls.
CLEAR_SCREEN:
  CALL CLEAR_ATTRIBUTES
  CALL CLEAR_DISPLAY
  XOR A
  OUT ($FE),A
  RET

; Blank the display file
;
; Used by the routine at CLEAR_SCREEN.
;
; Writes $00 over $4000 for $58 pages -- the whole bitmap, all three thirds.
; The two routines below it share the same inner loop with a different address
; and length, which is why they are three entry points rather than three
; routines.
CLEAR_DISPLAY:
  LD HL,$4000
  LD B,$58
; This entry point is used by the routine at CLEAR_VARIABLES.
CLEAR_FROM_HL:
  LD C,$00
; This entry point is used by the routine at CLEAR_ATTRIBUTES.
FILL_FROM_HL:
  LD (HL),C
  INC HL
  LD A,H
  CP B
  JR NZ,FILL_FROM_HL
  RET

; Blank the attribute file
;
; Used by the routine at CLEAR_SCREEN.
;
; $5800 for $5B pages, through the same loop as CLEAR_DISPLAY.
CLEAR_ATTRIBUTES:
  LD HL,$5800
  LD B,$5B
  LD C,$00
  JR FILL_FROM_HL

; Blank the game's variables
;
; Used by the routine at START_GAME.
;
; $5E10 for $60 bytes -- the block holding the score, the clock, the inventory
; and everything else the game keeps about a session. Called when a new game
; starts.
CLEAR_VARIABLES:
  LD HL,DRAW_WIDTH
  LD B,$60
  JR CLEAR_FROM_HL

; Per-frame update for the wizard
;
; The wizard's equivalent of UPDATE_KNIGHT, reached from ACTOR_HANDLERS for
; sprite codes $11-$20.
UPDATE_WIZARD:
  LD BC,$2020
  LD DE,$2020
  LD HL,$2020
  CALL MOVE_PLAYER
  LD E,(IX+$06)
  LD D,(IX+$07)
  LD A,D
  OR E
  JR Z,UPDATE_WIZARD_4
  LD A,(FRAMES)
  AND $03
  JR NZ,UPDATE_WIZARD_4
  LD A,(IX+$00)
  AND $03
  ADD A,$11
  LD (IX+$00),A
  LD A,D
  AND A
  JP P,UPDATE_WIZARD_0
  NEG
UPDATE_WIZARD_0:
  LD C,A
  LD A,E
  AND A
  JP P,UPDATE_WIZARD_1
  NEG
UPDATE_WIZARD_1:
  CP C
  JR NC,UPDATE_WIZARD_5
  LD A,D
  AND A
  LD A,(IX+$00)
  JP M,UPDATE_WIZARD_2
  ADD A,$04
UPDATE_WIZARD_2:
  ADD A,$08
UPDATE_WIZARD_3:
  LD (IX+$00),A
  CALL SOUND_FOOTSTEP
UPDATE_WIZARD_4:
  CALL READ_CONTROLS
  AND $10
  CALL Z,TRY_FIRE_ALT
  JP PLAYER_TICK
UPDATE_WIZARD_5:
  LD A,E
  AND A
  LD A,(IX+$00)
  JP M,UPDATE_WIZARD_3
  ADD A,$04
  JR UPDATE_WIZARD_3

; Fire, for the third character
;
; Used by the routine at UPDATE_KNIGHT.
;
; The third of the three per-character fire routines, alongside TRY_FIRE and
; TRY_FIRE_ALT. Same three tests, same call to FIRE_WEAPON, and its own sound.
TRY_FIRE_THIRD:
  LD A,(WEAPON)
  AND A
  RET NZ
  LD A,(FIRE_BLOCKED)
  AND A
  RET NZ
  CALL SOUND_SWEEP_A41B
  CALL FIRE_WEAPON
  LD HL,WEAPON
  LD (HL),$40
  JR LAUNCH_SHOT

; Fire, for one of the other characters
;
; Used by the routine at UPDATE_WIZARD.
;
; Instruction for instruction the same as TRY_FIRE -- refuse if a shot is
; already in the air, refuse if $5E2D says not now, make a noise, launch -- but
; it calls SOUND_SWEEP_DOWN where the other calls SOUND_SWEEP_UP. Each
; character has its own copy of this so that each can have its own firing
; sound, rather than one routine taking a parameter.
TRY_FIRE_ALT:
  LD A,(WEAPON)
  AND A
  RET NZ
  LD A,(FIRE_BLOCKED)
  AND A
  RET NZ
  CALL SOUND_SWEEP_DOWN
  CALL FIRE_WEAPON
  LD HL,WEAPON
  LD (HL),$34
; This entry point is used by the routines at TRY_FIRE_THIRD and TRY_FIRE.
LAUNCH_SHOT:
  INC HL
  LD A,(IX+$01)
  LD (HL),A
  INC HL
  INC HL
  LD A,(IX+$03)
  LD (HL),A
  INC HL
  LD A,(IX+$04)
  LD (HL),A
  PUSH IX
  LD IX,WEAPON
  CALL DRAW_THING
  POP IX
  RET

; Launch the player's weapon
;
; Used by the routines at TRY_FIRE_THIRD, TRY_FIRE_ALT and TRY_FIRE.
;
; Sets the weapon's velocity from the direction the player is facing: +4, -4 or
; nothing on each axis, taken from the sign of +$06 and +$07. A shot therefore
; travels four pixels a frame along whichever axes the player was moving on,
; and a diagonal shot moves on both.
;
; Confirmed live -- firing and reading the weapon's velocity field back gives
; exactly $04 and $FC, and the shot's x walks across the room four pixels at a
; time.
;
; IX The player
FIRE_WEAPON:
  LD HL,WEAPON_DX         ; The weapon's velocity field, +$0E of the player's
                          ; record.
  LD A,$30                ; Mark the weapon as in flight.
  LD (SOUND_SLOT+$0007),A ;
  LD A,$00                ; And clear its contact flag.
  LD (WEAPON_HIT),A       ;
  LD A,(IX+$06)           ; Standing still: nothing to fire along.
  OR (IX+$07)             ;
  JR Z,FIRE_WEAPON_4      ;
  LD A,(IX+$06)           ; Which way on this axis?
  AND A                   ;
  JR Z,FIRE_WEAPON_1      ;
  JP M,FIRE_WEAPON_0
  LD A,$04                ; Right or down.
  JR FIRE_WEAPON_1        ;
FIRE_WEAPON_0:
  LD A,$FC                ; Left or up: $FC is minus four.
FIRE_WEAPON_1:
  LD (HL),A               ; Store it and do the other axis the same way.
  INC HL                  ;
  LD A,(IX+$07)
  AND A
  JR Z,FIRE_WEAPON_3
  JP M,FIRE_WEAPON_2
  LD A,$04
  JR FIRE_WEAPON_3
FIRE_WEAPON_2:
  LD A,$FC
FIRE_WEAPON_3:
  LD (HL),A
  RET
FIRE_WEAPON_4:
  LD A,(IX+$00)
  DEC A
  AND $0C
  JR Z,FIRE_WEAPON_5
  CP $04
  JR Z,FIRE_WEAPON_6
  CP $08
  JR NZ,FIRE_WEAPON_7
  LD (HL),$00
  INC HL
  LD (HL),$FC
  RET
FIRE_WEAPON_5:
  LD (HL),$FC
  INC HL
  LD (HL),$00
  RET
FIRE_WEAPON_6:
  LD (HL),$04
  INC HL
  LD (HL),$00
  RET
FIRE_WEAPON_7:
  LD (HL),$00
  INC HL
  LD (HL),$04
  RET

; Drive the spinning axe
;
; The axe's equivalent of SPIN_SWORD, over sprites $40 to $47 -- again eight
; frames, one per compass point. It is the knight's weapon.
SPIN_AXE:
  CALL ACTOR_TO_WORKSPACE
  LD A,(FRAMES)
  CPL
  RRA
  AND $07
  ADD A,$40
  LD (IX+$00),A
  LD (IX+$05),$42
  JR SPIN_WEAPON

; Drive the wizard's spell
;
; Sprites $34 to $37, and the odd one of the three weapons: where the sword and
; the axe are solid shapes redrawn at eight angles, this is a scatter of loose
; pixels that changes shape rather than turning, which is what makes it read as
; magic rather than as a thrown object. Two of its four frames are identical.
;
; Confirmed by firing as each character and reading the weapon type out of the
; player record: the wizard's shots come back as $36, inside this range, while
; the knight's are $41-$47 and the serf's $3E.
SPIN_SPELL:
  CALL ACTOR_TO_WORKSPACE
  LD A,(IX+$00)
  INC A
  AND $03
  ADD A,$34
  LD (IX+$00),A
  LD A,(FRAMES)
  RLA
  AND $02
  ADD A,$45
  LD (IX+$05),A
; This entry point is used by the routines at SPIN_AXE and SPIN_SWORD.
SPIN_WEAPON:
  LD DE,(ROOM_HALF_WIDTH)
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR NZ,CLEAR_ACTOR
  DEC (IX+$0F)
  JR Z,WEAPON_GONE
  BIT 0,(IX+$02)
  JR NZ,WEAPON_GONE
  LD A,(IX+$03)
  ADD A,(IX+$06)
  LD C,A
  SUB $58
  JP P,SPIN_SPELL_0
  NEG
SPIN_SPELL_0:
  CP E
  JR NC,SPIN_SPELL_5
SPIN_SPELL_1:
  LD A,(IX+$04)
  ADD A,(IX+$07)
  LD B,A
  SUB $68
  JP P,SPIN_SPELL_2
  NEG
SPIN_SPELL_2:
  CP D
  JR NC,SPIN_SPELL_4
SPIN_SPELL_3:
  LD (IX+$03),C
  LD (IX+$04),B
  JP REDRAW_ACTOR
SPIN_SPELL_4:
  LD B,(IX+$04)
  LD A,(IX+$07)
  NEG
  LD (IX+$07),A
  PUSH BC
  CALL SOUND_SPELL_2
  POP BC
  JR SPIN_SPELL_3
SPIN_SPELL_5:
  LD C,(IX+$03)
  LD A,(IX+$06)
  NEG
  LD (IX+$06),A
  PUSH BC
  CALL SOUND_SPELL_2
  POP BC
  JR SPIN_SPELL_1
; This entry point is used by the routine at COUNTDOWN_ACTOR.
WEAPON_GONE:
  CALL ERASE_THING
  CALL SOUND_SPELL
  LD A,(ROOM_COLOUR)
  LD (IX+$05),A
  CALL DRAW_FROM_RECORD
; This entry point is used by the routine at ACTOR_TICK_TIMER.
CLEAR_ACTOR:
  LD (IX+$00),$00
  RET

; Fire, if there is nothing already in the air
;
; Used by the routine at UPDATE_SERF.
;
; Refuses outright if the weapon slot at $EA98 is occupied, so only one shot
; exists at a time -- that single test is the whole of the game's rate of fire.
; With the way clear it makes the sweep noise and calls FIRE_WEAPON to launch
; one.
TRY_FIRE:
  LD A,(WEAPON)
  AND A
  RET NZ
  LD A,(FIRE_BLOCKED)
  AND A
  RET NZ
  CALL SOUND_SWEEP_UP
  CALL FIRE_WEAPON
  LD C,$00
  LD A,(HL)
  AND A
  JR Z,TRY_FIRE_3
  JP P,TRY_FIRE_0
  LD C,$04
TRY_FIRE_0:
  DEC HL
  LD A,(HL)
  AND A
  JR Z,TRY_FIRE_1
  JP P,TRY_FIRE_2
  DEC C
TRY_FIRE_1:
  LD A,C
  AND $07
  ADD A,$38
  LD HL,WEAPON
  LD (HL),A
  JP LAUNCH_SHOT
TRY_FIRE_2:
  INC C
  JR TRY_FIRE_1
TRY_FIRE_3:
  DEC HL
  BIT 7,(HL)
  JR Z,TRY_FIRE_4
  LD C,$06
  JR TRY_FIRE_1
TRY_FIRE_4:
  LD C,$02
  JR TRY_FIRE_1

; Turn a signed value into a direction code
;
; Used by the routine at SPIN_SWORD.
;
; Zero, positive or negative becomes 0 or 4 in C, which is then used to pick a
; sprite or a table entry. The game's usual way of turning "which way is it
; going" into "which picture".
SIGN_TO_DIRECTION:
  LD C,$00
  LD A,(HL)
  AND A
  JR Z,SIGN_TO_DIRECTION_3
  JP P,SIGN_TO_DIRECTION_0
  LD C,$04
SIGN_TO_DIRECTION_0:
  DEC HL
  LD A,(HL)
  AND A
  JR Z,SIGN_TO_DIRECTION_1
  JP P,SIGN_TO_DIRECTION_2
  DEC C
SIGN_TO_DIRECTION_1:
  LD A,C
  AND $07
  ADD A,$38
  LD HL,WEAPON
  LD (HL),A
  RET
SIGN_TO_DIRECTION_2:
  INC C
  JR SIGN_TO_DIRECTION_1
SIGN_TO_DIRECTION_3:
  DEC HL
  BIT 7,(HL)
  JR Z,SIGN_TO_DIRECTION_4
  LD C,$06
  JR SIGN_TO_DIRECTION_1
SIGN_TO_DIRECTION_4:
  LD C,$02
  JR SIGN_TO_DIRECTION_1

; Drive the spinning sword
;
; Sprites $38 to $3F are one sword drawn at eight angles, a compass point
; apart, and cycling through them is what makes it appear to spin.
;
; This is the serf's weapon. Each character throws its own: firing as each in
; turn and reading the type out of the player record's upper half gives $3E for
; the serf, $41 to $47 for the knight's axe and $36 for the wizard's spell.
SPIN_SWORD:
  CALL ACTOR_TO_WORKSPACE
  LD (IX+$05),$46
  LD HL,WEAPON_DY
  CALL SIGN_TO_DIRECTION
  JP SPIN_WEAPON

; Drive the other kind of bat
;
; Sprites $6A and $6B. What it does differently from MOVE_BAT has not been
; established -- only that the game keeps them apart.
MOVE_BAT_ALT:
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  CALL ACTOR_TO_WORKSPACE
  LD HL,ACTORS_HERE
  INC (HL)
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  LD (IX+$0F),$00
  LD DE,(ROOM_HALF_WIDTH)
  LD A,(IX+$09)
  INC A
  AND $0F
  LD (IX+$09),A
  JP NZ,MOVE_BAT_ALT_0
  LD A,R
  AND $07
  LD (IX+$08),A
MOVE_BAT_ALT_0:
  CALL VELOCITY_LOOKUP
  LD (IX+$05),$43
  JR NZ,MOVE_BAT_ALT_1
  INC HL
MOVE_BAT_ALT_1:
  LD A,(HL)
  BIT 1,(IX+$08)
  JR NZ,MOVE_BAT_ALT_2
  NEG
MOVE_BAT_ALT_2:
  ADD A,(IX+$04)
  LD C,A
  SUB $68
  JR C,MOVE_BAT_ALT_3
  CP D
  JR NC,MOVE_BAT_ALT_10
  JR MOVE_BAT_ALT_4
MOVE_BAT_ALT_3:
  NEG
  CP D
  JR NC,MOVE_BAT_ALT_11
MOVE_BAT_ALT_4:
  LD (IX+$04),C
MOVE_BAT_ALT_5:
  CALL VELOCITY_LOOKUP
  JR Z,MOVE_BAT_ALT_6
  INC HL
MOVE_BAT_ALT_6:
  LD A,(HL)
  BIT 0,(IX+$08)
  JR NZ,MOVE_BAT_ALT_7
  NEG
MOVE_BAT_ALT_7:
  ADD A,(IX+$03)
  LD C,A
  SUB $58
  JR C,MOVE_BAT_ALT_8
  CP E
  JR NC,MOVE_BAT_ALT_13
  JR MOVE_BAT_ALT_9
MOVE_BAT_ALT_8:
  NEG
  CP E
  JR NC,MOVE_BAT_ALT_12
MOVE_BAT_ALT_9:
  LD (IX+$03),C
  LD A,(IX+$09)
  RRA
  RRA
  AND $01
  LD C,A
  LD A,(IX+$00)
  AND $FE
  ADD A,C
  LD (IX+$00),A
  LD A,(PLAYER)
  CP $31
  JP NC,DRAW_MONSTER
  JP REDRAW_ACTOR
MOVE_BAT_ALT_10:
  RES 1,(IX+$08)
  JR MOVE_BAT_ALT_5
MOVE_BAT_ALT_11:
  SET 1,(IX+$08)
  JR MOVE_BAT_ALT_5
MOVE_BAT_ALT_12:
  SET 0,(IX+$08)
  JR MOVE_BAT_ALT_9
MOVE_BAT_ALT_13:
  RES 0,(IX+$08)
  JR MOVE_BAT_ALT_9

; Index a table by a creature's vertical speed
;
; Used by the routine at MOVE_BAT_ALT.
;
; Doubles +$09 and adds it to a table at STEP_VECTORS, then tests bit 2 of
; +$08. The pair of them are the velocity fields, so this is picking something
; -- a sprite or an offset -- out of a table according to how fast and which
; way a creature is moving.
VELOCITY_LOOKUP:
  LD C,(IX+$09)
  SLA C
  LD B,$00
  LD HL,STEP_VECTORS
  ADD HL,BC
  BIT 2,(IX+$08)
  RET

; How far to move, for each of sixteen headings
;
; Sixteen pairs, x then y, indexed by an actor's +$09 doubled. They run (3,0),
; (3,0), (3,1), (3,1), (3,1), then six of (2,2), then (1,3) three times and
; (0,3) twice -- a quarter turn walked round in sixteen steps, with the total
; distance kept roughly the same so a diagonal is not faster than a straight
; line.
STEP_VECTORS:
  DEFB $03,$00
  DEFB $03,$00
  DEFB $03,$01
  DEFB $03,$01
  DEFB $03,$01
  DEFB $02,$02
  DEFB $02,$02
  DEFB $02,$02
  DEFB $02,$02
  DEFB $02,$02
  DEFB $02,$02
  DEFB $01,$03
  DEFB $01,$03
  DEFB $01,$03
  DEFB $00,$03
  DEFB $00,$03

; Put a new monster into the room
;
; Used by the routine at UPDATE_KNIGHT.
;
; Monsters are not placed once and left. When the player is in the room named
; by $5E26, a countdown at $5E27 runs down and a new creature is dropped into
; the room when it expires -- which is why standing still in one place does not
; make you safe.
;
; It looks for a free slot among only the first three of the eight monster
; records, and gives up if all three are taken. Those three are also the ones
; INERT_SPRITE bothers to burn time for, so the spawning slots and the timed
; slots are the same three.
;
; A new monster is a straight sixteen-byte copy of a template at
; MONSTER_TEMPLATE -- one LDIR, and the record is complete.
SPAWN_MONSTER_INTO_ROOM:
  LD A,(SPAWN_ROOM)       ; Only in the room the spawner is watching.
  LD C,A                  ;
  LD A,(PLAYER_ROOM)      ;
  CP C                    ;
  JR NZ,SPAWN_MONSTER_INTO_ROOM_3 ; Wrong room: nothing to do.
  LD HL,SPAWN_COUNTDOWN   ; The countdown to the next one.
  LD A,(HL)               ;
  AND A                   ;
  JR Z,SPAWN_MONSTER_INTO_ROOM_4
  DEC (HL)                ; Not yet.
  RET NZ                  ;
SPAWN_MONSTER_INTO_ROOM_0:
  LD HL,LIVE_MONSTERS     ; Three slots, sixteen bytes apart.
  LD DE,$0010             ;
  LD B,$03                ;
SPAWN_MONSTER_INTO_ROOM_1:
  LD A,(HL)                      ; A zero sprite means the slot is free.
  AND A                          ;
  JR Z,SPAWN_MONSTER_INTO_ROOM_2 ;
  ADD HL,DE
  DJNZ SPAWN_MONSTER_INTO_ROOM_1
  RET
SPAWN_MONSTER_INTO_ROOM_2:
  EX DE,HL
  LD HL,MONSTER_TEMPLATE  ; The template.
  LD BC,$0010             ;
  PUSH DE
  LDIR                    ; Sixteen bytes, and the monster exists.
  POP HL
  PUSH HL
  INC HL
  LD A,(PLAYER_ROOM)
  LD (HL),A
  INC HL
  PUSH HL
  LD HL,SPAWN_TYPES
  LD A,(FRAMES)
  AND $0F
  LD E,A
  LD D,$00
  ADD HL,DE
  LD A,(HL)
  POP HL
  LD (HL),A
  LD DE,(ROOM_HALF_WIDTH)
  LD B,E
  CALL RANDOM_CHANCE
  LD (HL),A
  LD B,D
  CALL RANDOM_CHANCE
  LD (HL),A
  POP DE
  PUSH IX
  LD IX,$0000
  ADD IX,DE
  CALL RANDOM_VERTICAL
  CALL DRAW_THING
  POP IX
  RET
SPAWN_MONSTER_INTO_ROOM_3:
  LD (SPAWN_ROOM),A
  LD A,$20
  LD (SPAWN_COUNTDOWN),A
  RET
SPAWN_MONSTER_INTO_ROOM_4:
  LD A,R
  AND $0F
  RET NZ
  JR SPAWN_MONSTER_INTO_ROOM_0

; Move one actor, bounce it off the walls, animate it
;
; The per-actor update. Actors drift in a direction until they hit the edge of
; the room, then reverse; the direction is re-rolled at intervals from the
; refresh register, which is the game's random number source.
;
; Velocity lives in +$08 (x) and +$09 (y) and is nudged one step per call
; toward +2 or -2 rather than being set outright, so things accelerate and turn
; smoothly instead of snapping.
;
; IX The actor to move
MOVE_ACTOR:
  CALL ACTOR_TO_WORKSPACE ; An actor in another room is not drawn or moved...
  LD A,(PLAYER_ROOM)      ;
  CP (IX+$01)             ;
  JP NZ,ACTOR_TICK_TIMER  ; ...it only gets its timer ticked.
  LD HL,ACTORS_HERE       ; Count of actors present in this room.
  INC (HL)                ;
  CALL CHECK_SHOT_HIT     ; Two proximity tests: has the player shot this
                          ; monster, and has this monster caught the player.
  DEC E
  JP Z,DRAW_MONSTER
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  LD DE,(ROOM_HALF_WIDTH) ; The room's half-width and half-height -- how far
                          ; from the centre an actor may stray.
  LD (IX+$0F),$00
  LD (IX+$05),$46
  LD A,(IX+$07)
  AND $0F
  JR NZ,MOVE_ACTOR_0
  LD A,R                  ; The refresh register as a source of randomness:
  AND $03                 ; whatever R happens to hold, masked to two direction
                          ; bits.
  LD (IX+$06),A
MOVE_ACTOR_0:
  BIT 0,(IX+$07)
  JR NZ,MOVE_ACTOR_2
  BIT 0,(IX+$06)
  JP Z,MOVE_ACTOR_8
  LD A,(IX+$08)
  CP $02
  JR Z,MOVE_ACTOR_1
  INC (IX+$08)
MOVE_ACTOR_1:
  BIT 1,(IX+$06)
  JP Z,MOVE_ACTOR_9
  LD A,(IX+$09)
  CP $02
  JR Z,MOVE_ACTOR_2
  INC (IX+$09)
MOVE_ACTOR_2:
  INC (IX+$07)
  LD A,(IX+$07)           ; Flip the bottom bit of the sprite index every other
  AND $01                 ; tick, which is the walk animation.
  XOR (IX+$00)            ;
  LD (IX+$00),A
; This entry point is used by the routines at MOVE_BAT, MOVE_GHOST_ALT,
; MOVE_871A, MOVE_GHOST, MOVE_FRANKENSTEIN, MOVE_WITCH, MOVE_8A80 and
; MOVE_HUMPBACK.
STEP_ACTOR:
  LD A,(IX+$03)           ; Provisional new x = x + x-velocity.
  ADD A,(IX+$08)          ;
  LD C,A
  SUB $58                 ; Distance from the room's centre column ($58)...
  JR C,MOVE_ACTOR_3       ;
  CP E                    ;
  JR C,MOVE_ACTOR_4
  RES 0,(IX+$06)          ; ...and if that is outside the half-width, stay put
  LD (IX+$08),$FE         ; and reverse.
  LD C,(IX+$03)
  JR MOVE_ACTOR_4
MOVE_ACTOR_3:
  NEG
  CP E
  JR C,MOVE_ACTOR_4
  SET 0,(IX+$06)
  LD C,(IX+$03)
  LD (IX+$08),$02
MOVE_ACTOR_4:
  LD A,(IX+$04)           ; The same again for y, about centre row $68.
  ADD A,(IX+$09)          ;
  LD B,A
  SUB $68
  JR C,MOVE_ACTOR_5
  CP D
  JR C,MOVE_ACTOR_6
  RES 1,(IX+$06)
  LD (IX+$09),$FE
  LD B,(IX+$04)
  JR MOVE_ACTOR_6
MOVE_ACTOR_5:
  NEG
  CP D
  JR C,MOVE_ACTOR_6
  SET 1,(IX+$06)
  LD B,(IX+$04)
  LD (IX+$09),$02
MOVE_ACTOR_6:
  LD (IX+$03),C           ; Commit the new position.
  LD (IX+$04),B           ;
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  RET NZ
  LD A,(IX+$00)           ; Two kinds are exempt from the check below: the
  AND $FC                 ; humpback, whose codes are $9C-$9F, and the four big
  CP $9C                  ; monsters at $70-$7F -- the mummy, Frankenstein's
                          ; monster, the devil and Dracula. Masking with $FC
                          ; and $F0 tests a whole run of codes in one compare,
                          ; without caring which frame is showing.
  JR Z,MOVE_ACTOR_7
  AND $F0
  CP $70
  JR Z,MOVE_ACTOR_7
  LD A,(PLAYER)
  CP $31
  JP NC,DRAW_MONSTER
MOVE_ACTOR_7:
  JP REDRAW_ACTOR
MOVE_ACTOR_8:
  LD A,(IX+$08)
  CP $FE
  JP Z,MOVE_ACTOR_1
  DEC (IX+$08)
  JP MOVE_ACTOR_1
MOVE_ACTOR_9:
  LD A,(IX+$09)
  CP $FE
  JP Z,MOVE_ACTOR_2
  DEC (IX+$09)
  JP MOVE_ACTOR_2
; Nothing in the disassembly jumps here, which is not because the routine is
; dead: it is entry $5C/$5D of the table at ACTOR_HANDLERS, and DISPATCH_ACTOR
; reaches it through a JP (HL). Breaking here does catch it, 16 times in 20,
; always with IX = $EE80 -- the monster whose sprite byte is currently $5C. Two
; earlier rounds of sampling reported zero hits and concluded it was unused;
; both were taken before the player had finished spawning, when no monster was
; in the room yet.
;
; STEP_ACTOR is also entered directly by eight other routines, which is why the
; position update is written as a separate stretch: they supply their own
; velocity in +$08/+$09 and reuse the bounce logic. Verified against the
; running game -- ($5E1D) reads 56 by 56, and sampled actor positions stay
; inside $58 +/- 56 by $68 +/- 56.

; Has the player's shot hit this monster?
;
; Used by the routines at MOVE_BAT_ALT, MOVE_ACTOR, MOVE_BAT, MOVE_GHOST_ALT,
; MOVE_871A, MOVE_GHOST, MOVE_WITCH and MOVE_8A80.
;
; The mirror image of CHECK_HIT. Same test, same 12-pixel box, but reading
; $EA98 onwards -- the upper half of the player's record, where a weapon in
; flight lives -- so this asks whether the player has hit the monster rather
; than the other way round. The two are called back to back from the same
; place.
;
; This pair was previously written up as two entries of an 8-byte "object
; table". That was wrong. $EA90 is one 16-byte record laid out exactly like a
; monster's, and $EA98 is its second half, not a neighbouring record; the
; giveaway is that ACTOR_TO_WORKSPACE is called with $EA90 and with the monster
; records but never with $EA98.
;
; IX The monster to test
; E 1 if the shot has hit it, 0 if not
CHECK_SHOT_HIT:
  LD A,(WEAPON_ROOM)      ; +$09 is the weapon's room, +$08 its type, +$0B and
  LD E,$00                ; +$0C its position.
  CP (IX+$01)             ;
  RET NZ
  LD A,(WEAPON)
  AND A
  RET Z
  LD A,(WEAPON_X)
  SUB (IX+$03)
  JP P,CHECK_SHOT_HIT_0
  NEG
CHECK_SHOT_HIT_0:
  CP $0C
  RET NC
  LD A,(WEAPON_Y)
  SUB (IX+$04)
  JP P,CHECK_SHOT_HIT_1
  NEG
CHECK_SHOT_HIT_1:
  CP $0C
  RET NC
  LD A,$01
  LD (WEAPON_HIT),A
  LD E,$01
  RET

; Take a chance on the refresh register
;
; Used by the routine at SPAWN_MONSTER_INTO_ROOM.
;
; Compares R against a threshold in B, so a caller gets a yes or no with
; roughly known odds and no state to keep. R is not random, but it advances on
; every instruction fetch, and against a threshold it is unpredictable enough
; for a monster's whim.
RANDOM_CHANCE:
  LD A,B
  SUB $08
  LD B,A
  LD A,R
  INC HL
RANDOM_CHANCE_0:
  CP B
  JR C,RANDOM_CHANCE_1
  SUB B
  JR RANDOM_CHANCE_0
RANDOM_CHANCE_1:
  LD C,A
  LD A,R
  BIT 1,A
  LD A,$60
  JR Z,RANDOM_CHANCE_2
  ADD A,C
  RET
RANDOM_CHANCE_2:
  SUB C
  RET

; Has this monster caught the player?
;
; Used by the routines at MOVE_BAT_ALT, MOVE_ACTOR, MOVE_BAT, MOVE_GHOST_ALT,
; MOVE_871A, MOVE_GHOST, MOVE_MUMMY, MOVE_DRACULA, MOVE_FRANKENSTEIN,
; MOVE_DEVIL, MOVE_WITCH, MOVE_8A80 and MOVE_HUMPBACK.
;
; Compares the monster IX points at against the player's record at $EA90: same
; room, and within 12 pixels on both axes. Confirmed by breaking here and
; collecting IX -- it is only ever one of the eight monster records at
; $EE60-$EED0, tested against the fixed player address.
;
; IX The monster to test
; E 1 if it has the player, 0 if not
CHECK_HIT:
  LD A,(PLAYER_ROOM)      ; Cheapest rejection first: a monster in another room
  LD E,$00                ; cannot touch anything.
  CP (IX+$01)             ;
  RET NZ
  LD A,(PLAYER)           ; $31 is not an arbitrary threshold: sprite codes
  AND A                   ; $01-$30 are the three playable characters, sixteen
  RET Z                   ; codes each (see ACTOR_HANDLERS), so "non-zero and
  CP $31                  ; below $31" means "$EA90 currently holds a player".
  RET NC                  ; It reads $66 while the game is still bringing the
                          ; player into the room, which is what stops them
                          ; being killed before they exist.
  LD A,(PLAYER_X)         ; |dx|, via negate-if-negative rather than a signed
  SUB (IX+$03)            ; compare.
  JP P,CHECK_HIT_0        ;
  NEG                     ;
CHECK_HIT_0:
  CP $0C                  ; Within 12 pixels horizontally, or no hit.
  RET NC                  ;
  LD A,(PLAYER_Y)         ; The same for |dy|.
  SUB (IX+$04)            ;
  JP P,CHECK_HIT_1        ;
  NEG                     ;
CHECK_HIT_1:
  CP $0C                  ;
  RET NC
  LD A,$01                ; Record the hit where the caller can find it...
  LD (PLAYER_FLAG),A      ;
  CALL PLAY_SOUND         ; ...and make a noise about it.
  LD E,$01
  RET

; Cost the player thirty-two and carry on
;
; Used by the routines at MOVE_BAT_ALT, MOVE_ACTOR, MOVE_BAT, MOVE_GHOST_ALT,
; MOVE_871A, MOVE_GHOST, MOVE_WITCH and MOVE_8A80.
;
; The two-instruction path taken when a monster's proximity test succeeds:
; LOSE_FOOD_32, then back into the creature's movement. Being caught is
; expensive but not, on its own, fatal.
MONSTER_CAUGHT_PLAYER:
  CALL LOSE_FOOD_32
  JP DRAW_MONSTER

; Count down the actor's timer, and act when it expires
;
; Used by the routines at MOVE_BAT_ALT, MOVE_ACTOR, SPAWN_MONSTER, MOVE_BAT,
; MOVE_GHOST_ALT, MOVE_871A, COUNTDOWN_ACTOR, MOVE_GHOST, MOVE_WITCH and
; MOVE_8A80.
;
; Field +$0F of the actor record is a countdown. Almost every call is a no-op
; that just decrements it; only on the tick where it reaches zero does control
; go to SPIN_SPELL.
;
; IX The actor record
ACTOR_TICK_TIMER:
  DEC (IX+$0F)
  RET NZ
  JP CLEAR_ACTOR

; The sprite a monster arrives as
;
; Sprites $58 to $5B, four frames of a monster appearing. Nothing wanders in
; from another room: a creature is spawned into the one the player is in, and
; this is what is drawn while it does.
SPAWN_MONSTER:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  DEC (IX+$0E)
  JR Z,SPAWN_MONSTER_0
  LD A,(IX+$0E)
  AND $03
  ADD A,$58
  LD (IX+$00),A
  LD (IX+$0F),$80
  LD A,(PLAYER)
  CP $31
  JP NC,DRAW_MONSTER
  JP REDRAW_ACTOR
SPAWN_MONSTER_0:
  LD A,(IX+$02)
  LD (IX+$00),A
  JP REDRAW_ACTOR

; Drive a bat
;
; Sprites $4E and $4F. A second kind of bat, sprites $6A and $6B, is driven by
; MOVE_BAT_ALT instead; the two look alike but are not the same creature and do
; not share a routine.
MOVE_BAT:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  LD (IX+$05),$45
  INC (IX+$07)
  CALL Z,RANDOM_VERTICAL
  LD A,(IX+$07)
  RRA
  RRA
  AND $01
  LD C,A
  LD A,(IX+$00)
  AND $FE
  ADD A,C
  LD (IX+$00),A
  LD DE,(ROOM_HALF_WIDTH)
  LD (IX+$0F),$00
  JP STEP_ACTOR

; Drive the other kind of ghost
;
; Drives two separate runs of codes, $5E-$5F as well as $68-$69, so one routine
; is behind two different-looking things. Only the second is known to be a
; ghost.
MOVE_GHOST_ALT:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  LD (IX+$0F),$00
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  LD A,(IX+$0A)
  RRA
  AND $01
  LD C,A
  LD A,(IX+$00)
  AND $FE
  ADD A,C
  LD (IX+$00),A
  LD DE,(ROOM_HALF_WIDTH)
  INC (IX+$0A)
  LD A,(IX+$0A)
  CP $07
  JR NZ,MOVE_GHOST_ALT_0
  CALL RANDOM_VERTICAL
  LD (IX+$0A),$F9
MOVE_GHOST_ALT_0:
  SRA A
  ADD A,(IX+$04)
  LD C,A
  SUB $68
  JP P,MOVE_GHOST_ALT_2
  NEG
  CP D
  JR C,MOVE_GHOST_ALT_1
  LD (IX+$09),$02
  SET 1,(IX+$06)
  BIT 7,(IX+$0A)
  JR Z,MOVE_GHOST_ALT_1
  LD (IX+$0A),$00
MOVE_GHOST_ALT_1:
  LD (IX+$04),C
  JP STEP_ACTOR
MOVE_GHOST_ALT_2:
  CP D
  JR C,MOVE_GHOST_ALT_1
  RES 1,(IX+$06)
  LD (IX+$09),$FE
  LD (IX+$0A),$F9
  JR MOVE_GHOST_ALT_1

; Give a creature a random up or down
;
; Used by the routines at SPAWN_MONSTER_INTO_ROOM, MOVE_BAT, MOVE_GHOST_ALT,
; MOVE_871A, MOVE_WITCH and MOVE_8A80.
;
; Reads the refresh register, takes one bit to decide whether to act and two
; more to make plus or minus two, and drops the result into the vertical
; velocity. The same trick MOVE_ACTOR uses for direction, applied to one axis.
RANDOM_VERTICAL:
  LD A,R
  BIT 0,A
  JR Z,RANDOM_VERTICAL_2
  AND $04
  SUB $02
RANDOM_VERTICAL_0:
  LD (IX+$09),A
  LD A,R
  RRA
  BIT 0,A
  JR Z,RANDOM_VERTICAL_3
  AND $04
  SUB $02
RANDOM_VERTICAL_1:
  LD (IX+$08),A
  RET
RANDOM_VERTICAL_2:
  AND $02
  SUB $01
  JR RANDOM_VERTICAL_0
RANDOM_VERTICAL_3:
  AND $02
  SUB $01
  JR RANDOM_VERTICAL_1

; Drive the creature at $60-$61
;
; Two frames of a small squat monster, nine pixels tall, whose limbs pull in
; and stretch out again -- eleven pixels wide in the first frame and fifteen in
; the second. Which creature it is has not been established.
MOVE_871A:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  LD (IX+$0F),$00
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  LD DE,(ROOM_HALF_WIDTH)
  DEC (IX+$0D)
  JR NZ,MOVE_871A_0
  LD (IX+$0D),$11
  CALL RANDOM_VERTICAL
MOVE_871A_0:
  LD A,(IX+$0D)
  RRA
  AND $01
  LD C,A
  LD A,(IX+$00)
  AND $FE
  ADD A,C
  LD (IX+$00),A
  JP STEP_ACTOR
; This entry point is used by the routines at MOVE_BAT_ALT, MOVE_ACTOR,
; MONSTER_CAUGHT_PLAYER, SPAWN_MONSTER, MOVE_BAT, MOVE_GHOST_ALT, MOVE_GHOST,
; MOVE_FRANKENSTEIN, MOVE_WITCH and MOVE_8A80.
DRAW_MONSTER:
  LD A,(IX+$05)
  PUSH AF
  LD A,(ROOM_COLOUR)
  LD (IX+$05),A
  CALL ERASE_THING
  CALL DRAW_FROM_RECORD
  POP AF
  LD (IX+$05),A
  LD (IX+$00),$6C
  LD (IX+$0E),$10
  LD BC,$0155
  CALL ADD_SCORE
  CALL DRAW_THING
  JP DRAW_FROM_RECORD

; A creature on a timer
;
; Skips everything if it is in another room, then counts +$0E down and hands
; over when it reaches zero. Sprites $6C to $6F, the expanding burst, which is
; exactly what a thing on a fuse looks like.
COUNTDOWN_ACTOR:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  DEC (IX+$0E)
  JP Z,WEAPON_GONE
  LD A,(IX+$0E)
  AND $03
  ADD A,$6C
  LD (IX+$00),A
  JP REDRAW_ACTOR

; Drive a ghost
;
; Sprites $62 and $63. As with the bats there is a second ghost, sprites $68
; and $69, with its own routine in MOVE_GHOST_ALT.
MOVE_GHOST:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  LD DE,(ROOM_HALF_WIDTH)
  LD (IX+$0F),$00
  LD (IX+$05),$46
  LD A,(IX+$07)
  AND $07
  JR NZ,MOVE_GHOST_0
  LD A,R
  AND $03
  LD (IX+$06),A
MOVE_GHOST_0:
  BIT 0,(IX+$07)
  JR NZ,MOVE_GHOST_2
  BIT 0,(IX+$06)
  JR Z,MOVE_GHOST_3
  LD A,(IX+$08)
  CP $02
  JR Z,MOVE_GHOST_1
  INC (IX+$08)
MOVE_GHOST_1:
  BIT 1,(IX+$06)
  JR Z,MOVE_GHOST_4
  LD A,(IX+$09)
  CP $02
  JR Z,MOVE_GHOST_2
  INC (IX+$09)
MOVE_GHOST_2:
  INC (IX+$07)
  LD A,(IX+$07)
  AND $01
  XOR (IX+$00)
  LD (IX+$00),A
  JP STEP_ACTOR
MOVE_GHOST_3:
  LD A,(IX+$08)
  CP $FE
  JR Z,MOVE_GHOST_1
  DEC (IX+$08)
  JR MOVE_GHOST_1
MOVE_GHOST_4:
  LD A,(IX+$09)
  CP $FE
  JR Z,MOVE_GHOST_2
  DEC (IX+$09)
  JR MOVE_GHOST_2

; Set a heading towards the player
;
; Used by the routines at MOVE_MUMMY, MOVE_DRACULA, MOVE_FRANKENSTEIN,
; MOVE_DEVIL and MOVE_HUMPBACK.
;
; Compares the target's position with its own on each axis and sets the
; velocity fields to $FF or $01 accordingly -- the crudest possible pursuit,
; one pixel a frame towards wherever the player is, with no smoothing and no
; memory. It is what makes some creatures follow you rather than drift.
HOME_IN:
  LD C,$00
  LD A,D
  CP (IX+$04)
  JR Z,HOME_IN_1
  JR NC,HOME_IN_2
  LD (IX+$09),$FF
HOME_IN_0:
  LD A,E
  CP (IX+$03)
  JR Z,HOME_IN_3
  JR NC,HOME_IN_4
  LD (IX+$08),$FF
  RET
HOME_IN_1:
  LD (IX+$09),$00
  SET 0,C
  JR HOME_IN_0
HOME_IN_2:
  LD (IX+$09),$01
  JR HOME_IN_0
HOME_IN_3:
  LD (IX+$08),$00
  SET 1,C
  RET
HOME_IN_4:
  LD (IX+$08),$01
  RET

; Drive the mummy
;
; Sprites $70 to $73 -- four frames rather than the two most creatures get.
MOVE_MUMMY:
  CALL ACTOR_TO_WORKSPACE
  CALL CHECK_HIT
  DEC E
  CALL Z,LOSE_FOOD_8
  LD HL,LIVE_COLLECTABLE_80
  LD A,(HL)
  AND A
  JR Z,MOVE_MUMMY_0
  INC HL
  LD A,(HL)
  CP (IX+$01)
  JR NZ,MOVE_MUMMY_0
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  JR MOVE_MUMMY_4
MOVE_MUMMY_0:
  BIT 7,(IX+$06)
  JR NZ,MOVE_MUMMY_7
  LD HL,LIVE_RED_KEY
  LD A,(HL)
  AND A
  JR Z,MOVE_MUMMY_6
  INC HL
  LD A,(HL)
  CP (IX+$01)
  JR NZ,MOVE_MUMMY_6
  LD D,(IX+$0C)
  LD E,(IX+$0B)
  CALL HOME_IN
  LD A,C
  CP $03
  JR Z,MOVE_MUMMY_2
MOVE_MUMMY_1:
  LD A,(TICKS)
  RRA
  RRA
  AND $03
  ADD A,$70
  LD (IX+$00),A
  LD DE,$3838
  JP BIG_MONSTER_STEP
MOVE_MUMMY_2:
  BIT 6,(IX+$06)
  JR Z,MOVE_MUMMY_3
  LD (IX+$0B),$8C
  LD (IX+$0C),$68
  RES 6,(IX+$06)
  JR MOVE_MUMMY_1
MOVE_MUMMY_3:
  LD (IX+$0B),$68
  LD (IX+$0C),$38
  SET 6,(IX+$06)
  JR MOVE_MUMMY_1
MOVE_MUMMY_4:
  CALL HOME_IN
  LD A,C
  CP $03
  JR NZ,MOVE_MUMMY_1
  PUSH IX
  LD IX,LIVE_COLLECTABLE_80
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR NZ,MOVE_MUMMY_5
  CALL DRAW_THING
MOVE_MUMMY_5:
  POP IX
  LD A,$6B
  LD (LIVE_COLLECTABLE_80+$0001),A ; LIVE_COLLECTABLE_80+1: its room
  JR MOVE_MUMMY_2
MOVE_MUMMY_6:
  SET 7,(IX+$06)
MOVE_MUMMY_7:
  LD DE,(PLAYER_X)
  CALL HOME_IN
  JR MOVE_MUMMY_1

; Drive Dracula
;
; Sprites $7C to $7F, four frames.
MOVE_DRACULA:
  CALL ACTOR_TO_WORKSPACE
  CALL CHECK_HIT
  DEC E
  CALL Z,LOSE_FOOD_8
  LD DE,$468A
  CALL FIND_CARRIED
  JR NZ,MOVE_DRACULA_0
  LD DE,(PLAYER_X)
  CALL HOME_IN
  LD A,(IX+$08)
  NEG
  LD (IX+$08),A
  LD A,(IX+$09)
  NEG
  LD (IX+$09),A
  JR MOVE_DRACULA_1
MOVE_DRACULA_0:
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR NZ,MOVE_DRACULA_2
  LD DE,(PLAYER_X)
  CALL HOME_IN
MOVE_DRACULA_1:
  LD A,(TICKS)
  RRA
  RRA
  AND $03
  ADD A,$7C
  LD (IX+$00),A
  LD DE,$3434
  JP BIG_MONSTER_STEP
MOVE_DRACULA_2:
  LD (IX+$0B),$68
  LD (IX+$0C),$68
  CALL HOME_IN
  LD A,(FRAMES)
  AND A
  JP NZ,MOVE_DRACULA_1
  LD A,R
  AND $7F
  LD C,A
  CALL ROOM_SHAPE_OF
  CP $03
  JP NC,MOVE_DRACULA_1
  LD A,(PLAYER_ROOM)
  CP C
  JP Z,MOVE_DRACULA_1
  LD (IX+$01),C
  JR MOVE_DRACULA_1

; Find a room's shape number
;
; Used by the routine at MOVE_DRACULA.
;
; Doubles the room number into ROOM_TABLE and steps one byte on, which lands on
; the shape rather than the colour.
ROOM_SHAPE_OF:
  LD L,A
  LD H,$00
  LD DE,ROOM_TABLE
  ADD HL,HL
  ADD HL,DE
  INC HL
  LD A,(HL)
  RET

; Drive Frankenstein's monster
;
; Sprites $74 to $77, four frames. One of the four creatures whose touch costs
; eight units of life force through LOSE_FOOD_8.
MOVE_FRANKENSTEIN:
  CALL ACTOR_TO_WORKSPACE
  CALL CHECK_HIT
  DEC E
  JR NZ,MOVE_FRANKENSTEIN_1
  LD DE,$458B
  CALL FIND_CARRIED
  JR NZ,MOVE_FRANKENSTEIN_0
  LD BC,$1000
  CALL ADD_SCORE
  JP DRAW_MONSTER
MOVE_FRANKENSTEIN_0:
  CALL LOSE_FOOD_8
MOVE_FRANKENSTEIN_1:
  LD DE,(PLAYER_X)
  CALL HOME_IN
  LD A,(TICKS)
  RRA
  RRA
  AND $03
  ADD A,$74
  LD (IX+$00),A
  LD DE,$3434
; This entry point is used by the routines at MOVE_MUMMY, MOVE_DRACULA and
; MOVE_DEVIL.
BIG_MONSTER_STEP:
  LD A,(PLAYER)
  CP $31
  JP C,STEP_ACTOR
  LD DE,(PLAYER_X)
  CALL HOME_IN
  LD A,(IX+$08)
  NEG
  LD (IX+$08),A
  LD C,A
  LD A,(IX+$09)
  NEG
  LD (IX+$09),A
  LD DE,$3434
  AND C
  JP NZ,STEP_ACTOR
  LD (IX+$08),$01
  LD (IX+$09),$01
  JP STEP_ACTOR

; Drive the devil
;
; Sprites $78 to $7B. One of the four whose touch costs eight units through
; LOSE_FOOD_8.
MOVE_DEVIL:
  CALL ACTOR_TO_WORKSPACE
  CALL CHECK_HIT
  DEC E
  CALL Z,LOSE_FOOD_8
  LD DE,(PLAYER_X)
  CALL HOME_IN
  LD A,(IX+$00)
  AND $FC
  LD C,A
  LD A,(TICKS)
  RRA
  RRA
  AND $03
  ADD A,C
  LD (IX+$00),A
  LD DE,$3434
  JP BIG_MONSTER_STEP

; Take sixteen off the life force
;
; Used by the routine at MOVE_HUMPBACK.
;
; The heavier of the two penalties. If it would go below zero the stack is
; dropped and control goes straight to the death routine, so the caller never
; returns.
LOSE_FOOD_16:
  LD A,(FOOD_LEVEL)       ; Sixteen, against the eight LOSE_FOOD_8 takes.
  SUB $10                 ;
  JR C,FOOD_GONE
  JR SET_FOOD_LEVEL

; Take eight off the life force
;
; Used by the routines at MOVE_MUMMY, MOVE_DRACULA, MOVE_FRANKENSTEIN and
; MOVE_DEVIL.
;
; What touching most monsters costs -- four of the creature handlers call this
; one. Both penalties share the tail: store the new level, redraw the
; indicator, and on underflow die instead.
;
; A The new level
LOSE_FOOD_8:
  LD A,(FOOD_LEVEL)       ; Eight.
  SUB $08                 ;
  JR C,FOOD_GONE
; This entry point is used by the routine at LOSE_FOOD_16.
SET_FOOD_LEVEL:
  LD (FOOD_LEVEL),A       ; Store it, then redraw the roast on the scroll.
  JP DRAW_FOOD            ;
; This entry point is used by the routine at LOSE_FOOD_16.
FOOD_GONE:
  POP HL
  JP LOSE_LIFE

; Drive the witch
;
; Sprites $90 to $93. The countdown at +$0D and the arithmetic shift of +$09
; give her flight its rise and fall: SRA halves the vertical speed while
; keeping its sign, so she coasts upward, slows and drops rather than moving at
; a constant rate.
MOVE_WITCH:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  DEC (IX+$0D)
  JR NZ,MOVE_WITCH_0
  CALL RANDOM_VERTICAL
  SRA (IX+$09)
  LD (IX+$0D),$10
MOVE_WITCH_0:
  LD A,(IX+$00)
  AND $FC
  BIT 7,(IX+$08)
  JR NZ,MOVE_WITCH_1
  ADD A,$02
MOVE_WITCH_1:
  LD C,A
  LD A,(IX+$0D)
  RRA
  AND $01
  ADD A,C
  LD (IX+$00),A
  LD DE,(ROOM_HALF_WIDTH)
  LD (IX+$05),$43
  JP STEP_ACTOR

; Drive two unrelated creatures
;
; Covers sprites $94 to $9B, which are not one creature in eight frames but two
; in four each: $94-$97 is a running figure, $98-$9B a bat -- the third
; distinct bat in the game, after those driven by MOVE_BAT and MOVE_BAT_ALT.
; What the two have in common that lets them share a routine has not been
; established, so the routine is left with a name that claims nothing.
MOVE_8A80:
  CALL ACTOR_TO_WORKSPACE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JP NZ,ACTOR_TICK_TIMER
  LD HL,ACTORS_HERE
  INC (HL)
  CALL CHECK_HIT
  DEC E
  JP Z,MONSTER_CAUGHT_PLAYER
  CALL CHECK_SHOT_HIT
  DEC E
  JP Z,DRAW_MONSTER
  DEC (IX+$0D)
  JR NZ,MOVE_8A80_0
  CALL RANDOM_VERTICAL
  LD A,(FRAMES)
  AND $04
  SUB $02
  LD (IX+$08),A
  SRA (IX+$09)
  LD (IX+$0D),$20
MOVE_8A80_0:
  LD A,(IX+$00)
  AND $FC
  BIT 7,(IX+$08)
  JR NZ,MOVE_8A80_1
  ADD A,$02
MOVE_8A80_1:
  LD C,A
  LD A,(IX+$0D)
  RRA
  AND $01
  ADD A,C
  LD (IX+$00),A
  LD DE,(ROOM_HALF_WIDTH)
  LD (IX+$05),$42
  JP STEP_ACTOR

; Walk the eight records at $EB18
;
; Used by the routine at MOVE_HUMPBACK.
;
; Eight records, eight bytes apart, skipping any whose first byte is zero --
; the same shape as every other table walk in the game.
SCAN_COLLECTABLES:
  LD HL,LIVE_COLLECTABLES
  LD DE,$0008
  LD B,$08
SCAN_COLLECTABLES_0:
  PUSH HL
  LD A,(HL)
  AND A
  JR Z,SCAN_COLLECTABLES_1
  INC HL
  LD A,(HL)
  CP (IX+$01)
  JR NZ,SCAN_COLLECTABLES_1
  POP DE
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD C,$01
  RET
SCAN_COLLECTABLES_1:
  POP HL
  ADD HL,DE
  DJNZ SCAN_COLLECTABLES_0
  LD C,$00
  RET

; Drive the humpback
;
; Sprites $9C to $9F. MOVE_ACTOR singles this creature out by name: masking a
; sprite code with $FC and comparing against $9C matches all four of its frames
; at once, and those are let past a test the ordinary wanderers have to make.
MOVE_HUMPBACK:
  CALL ACTOR_TO_WORKSPACE
  CALL CHECK_HIT
  DEC E
  CALL Z,LOSE_FOOD_16
  XOR A
  LD (IX+$09),A
  LD (IX+$08),A
  CALL SCAN_COLLECTABLES
  DEC C
  JP NZ,MOVE_HUMPBACK_2
  CALL HOME_IN
  LD A,C
  CP $03
  JR NZ,MOVE_HUMPBACK_1
  CALL SCAN_COLLECTABLES
  LD DE,$0004
  AND A
  SBC HL,DE
  PUSH IX
  LD IX,$0000
  EX DE,HL
  ADD IX,DE
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR NZ,MOVE_HUMPBACK_0
  CALL DRAW_THING
MOVE_HUMPBACK_0:
  LD (IX+$00),$00
  POP IX
  JP MOVE_HUMPBACK_2
MOVE_HUMPBACK_1:
  LD A,(IX+$00)
  AND $FC
  LD C,A
  LD A,(TICKS)
  RRA
  RRA
  AND $03
  ADD A,C
  LD (IX+$00),A
  LD DE,$3C3C
MOVE_HUMPBACK_2:
  LD A,(PLAYER)
  CP $31
  JP C,STEP_ACTOR
  LD DE,$3A58
  CALL HOME_IN
  JP STEP_ACTOR

; A new monster, ready to copy
;
; The sixteen bytes SPAWN_MONSTER_INTO_ROOM copies into a free slot. Read out
; of the game they are 58 00 5C 68 68 44 00 00 02 02 00 00 00 10 20 00, and
; every one of them means something already documented elsewhere.
;
; The sprite is $58 -- not a creature but the arrival animation, so a new
; monster appears by materialising rather than blinking into existence. +$03
; and +$04 are $68 and $68, the centre of the room. +$08 and +$09 are its
; starting velocities. And +$02 holds $5C, the spider: the same trick the
; player uses when dying, where the sprite to turn into when the animation
; finishes is parked in a spare field until it is needed.
MONSTER_TEMPLATE:
  DEFB $58,$00,$5C,$68,$68,$44,$00,$00
  DEFB $02,$02,$00,$00,$00,$10,$20,$00

; What a new monster turns into
;
; Sixteen sprite codes, picked by the frame counter's low four bits:
; SPAWN_MONSTER_INTO_ROOM puts the one it picks into the new record's +$02,
; where MONSTER_TEMPLATE's arrival animation finds it when it finishes. The
; table runs on into the five bytes of SPAWNABLE_SPRITES below, which are its
; last five entries as well as a list of their own.
SPAWN_TYPES:
  DEFB $5C,$5E,$98,$98,$90,$90,$94,$94
  DEFB $5C,$5E,$60

; Five creatures
;
; $62, $4C, $4E, $68, $6A -- a ghost, the pumpkin, a bat, another ghost and
; another bat. Five sprite codes in a row immediately before the routine at
; DRAW_FOOD -- and, as it turns out, the last five entries of SPAWN_TYPES.
SPAWNABLE_SPRITES:
  DEFB $62,$4C,$4E,$68,$6A

; Redraw the roast on the scroll
;
; Used by the routines at LOSE_FOOD_8, EAT_FOOD, UPDATE_KNIGHT, LOSE_FOOD_32,
; PLACE_PLAYER and MUSHROOM_DRAIN.
;
; The life force in $5E28 is drawn as the roast down the right-hand side, eaten
; away as it falls. $5E29 remembers the level the picture was last drawn at,
; and both are shifted right three times before being compared, so nothing
; happens until a whole eighth of the roast has gone -- most calls return at
; the third instruction.
;
; It does not have its own copy of the picture. It reaches into the sprite
; tables, moves the roast's entry at ROAST_SPRITE forward by however many rows
; have been eaten and shortens the height bytes of GFX_B5 and GFX_B4, the
; second byte of each, to match, draws, and then puts all three back from the
; stack. The tables are only wrong for the few hundred T-states it takes to
; draw.
;
; Watched live: at rest ROAST_SPRITE holds GFX_B5 and GFX_B5's height byte
; holds $1E, and breaking just before the restore catches ROAST_SPRITE reading
; $C522 and then $C51C as the roast goes down -- the same entry, advanced past
; the rows that have been eaten.
;
; None; it reads the level out of $5E28
DRAW_FOOD:
  LD A,(FOOD_LEVEL)       ; The level, in eighths.
  SRL A                   ;
  SRL A                   ;
  SRL A                   ;
  LD C,A
  LD A,(FOOD_DRAWN)       ; What was drawn last time, also in eighths.
  SRL A                   ;
  SRL A                   ;
  SRL A                   ;
  LD B,A                  ;
  CP C                    ; The same, so the picture is still right.
  RET Z                   ;
  LD A,(GFX_B4+$0001)     ; Keep the roast's real height to put back
  LD E,A                  ; afterwards.
  LD A,(GFX_B5+$0001)     ;
  LD D,A                  ;
  PUSH IX
  LD IX,FOOD_RECORD       ; Not an actor, so borrow FOOD_RECORD.
  PUSH DE
  JR C,DRAW_FOOD_3
  LD A,(GFX_B5)
  LD E,A
  LD D,$00
  LD A,C
  PUSH BC
  CALL MULTIPLY
  POP BC
  LD DE,(ROAST_SPRITE)    ; The roast's entry in the sprite pointer table.
  PUSH DE                 ;
  ADD HL,DE               ;
  LD (ROAST_SPRITE),HL    ; Moved past the eaten rows, and put back before
                          ; returning.
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(GFX_B5+$0001)     ; GFX_B5+1: the bones' height byte
  SUB C
  JR Z,DRAW_FOOD_1
  PUSH DE
  LD (HL),A
  LD A,(GFX_B5)
  DEC HL
  LD (HL),A
  PUSH HL
  LD A,$14
  LD (IX+$00),A
  LD HL,$77C8
  LD A,H
  SUB C
  LD H,A
  LD (FOOD_RECORD+$0003),HL ; FOOD_RECORD+3: where the roast is drawn
  CALL DRAW_RECORD
  LD HL,(FOOD_RECORD+$0003) ; FOOD_RECORD+3: where the roast is drawn
  CALL PIXEL_TO_SCREEN
  LD A,(GFX_B5)
  LD B,A
DRAW_FOOD_0:
  LD (HL),$00
  INC L
  DJNZ DRAW_FOOD_0
  POP HL
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
DRAW_FOOD_1:
  POP HL
  LD (ROAST_SPRITE),HL
DRAW_FOOD_2:
  POP DE
  LD A,E
  LD (GFX_B4+$0001),A     ; GFX_B4+1: the whole roast's height byte
  LD A,D
  LD (GFX_B5+$0001),A     ; GFX_B5+1: the bones' height byte
  POP IX
  LD A,(FOOD_LEVEL)
  LD (FOOD_DRAWN),A
  RET
DRAW_FOOD_3:
  LD A,C
  LD (GFX_B4+$0001),A     ; GFX_B4+1: the whole roast's height byte
  LD A,$13
  LD (IX+$00),A
  LD HL,$77C8
  LD (FOOD_RECORD+$0003),HL ; FOOD_RECORD+3: where the roast is drawn
  CALL DRAW_RECORD
  LD B,$06
DRAW_FOOD_4:
  LD (HL),$00
  INC L
  DJNZ DRAW_FOOD_4
  JR DRAW_FOOD_2

; A second scratch record, for redrawing the food
;
; The disassembler calls this unused because nothing reaches it as code and
; nothing loads it as data through an obvious address. It is neither: DRAW_FOOD
; puts it in IX and draws from it, and writes a screen address into its +$03
; and +$04.
FOOD_RECORD:
  DEFS $08

; Clear the castle away and show how it went
;
; Used by the routine at LOSE_LIFE.
;
; Reached from UPDATE_KNIGHT when the player's last life goes. It blanks the
; play area, prints GAME OVER across it, and hands over to DRAW_SUMMARY for the
; three figures underneath, then sits in a counting loop long enough to read
; them.
;
; Note the second and third instructions: the tile source has to be pointed
; back at the text font first. During play it holds FONT_DIGITS, the copy
; biased so that digits index themselves, and anything printed through
; PLOT_TILE while it is still there comes out as the wrong glyphs entirely.
GAME_OVER:
  CALL CLEAR_PLAY_AREA    ; The castle goes; the status panel down the side
                          ; stays.
  LD HL,TEXT_FONT-$0100   ; Back to the text font, or the words below would be
  LD (TILE_SOURCE),HL     ; gibberish.
  LD HL,$3040             ; "GAME OVER", centred above the figures.
  LD DE,GAME_OVER_TEXT    ;
  CALL PRINT_STRING
  CALL DRAW_SUMMARY       ; TIME, SCORE and the proportion of the castle seen.
; This entry point is used by the routine at SHOW_END_SCREEN.
END_DELAY:
  LD B,$14                ; A delay, and a long one: twenty times round a full
  LD HL,$0000             ; 16-bit count.
GAME_OVER_0:
  DEC HL                  ; About four seconds in all, with nothing else
  LD A,H                  ; running.
  OR L                    ;
  JR NZ,GAME_OVER_0       ;
  DJNZ GAME_OVER_0        ;
  JP TITLE_AGAIN

; "GAME OVER"
;
; A colour byte and nine characters, the last with bit 7 set. GAME_OVER+12
; hands it to PRINT_STRING, then the three figures are printed under it, then a
; two-level counted delay runs and the game jumps back to the title screen.
GAME_OVER_TEXT:
  DEFM "GGAME OVE",$D2

; The handler for a piece of food
;
; Sprites $50 to $57 are food, and ACTOR_HANDLERS sends all eight of them here.
; Every frame it asks whether the player is standing on it; if not, it just
; draws itself and that is the whole of its behaviour.
;
; Eating is worth $40 -- a quarter of the bar -- and the total is held at $F0
; rather than being allowed to wrap, so arriving at a roast with almost full
; health wastes most of it. The two branches before the cap catch the carry as
; well as the compare, because $5E28 plus $40 can pass $FF.
;
; IX The food
EAT_FOOD:
  CALL ACTOR_TO_WORKSPACE ; Is the player on it?
  CALL NEAR_PLAYER        ;
  JR C,EAT_FOOD_0         ; No -- draw it and do nothing else.
  JP DRAW_AT_POSITION     ;
EAT_FOOD_0:
  CALL ERASE_THING        ; Rub it out and free its slot: eaten food does not
  LD (IX+$00),$00         ; come back.
  CALL PLAY_SOUND_A0      ; A noise.
  LD C,$40                ; Sixty-four units of life force.
  LD A,(FOOD_LEVEL)       ;
  ADD A,C                 ;
  JR C,EAT_FOOD_1         ; Cap it, catching both the carry and the limit...
  CP $F0                  ;
  JR C,EAT_FOOD_2         ;
EAT_FOOD_1:
  LD A,$F0                ; ...at $F0, just short of a full bar.
EAT_FOOD_2:
  LD (FOOD_LEVEL),A       ; Store it and redraw the roast on the scroll.
  JP DRAW_FOOD

; Flash the score line while a countdown runs
;
; Used by the routine at MATERIALISING.
;
; Counts $5E3C down and, while it lasts, sets bit 7 of the six attribute cells
; the score sits in -- the flash bit, so the ULA does the work and nothing has
; to be redrawn. A beep every sixteenth step goes with it.
FLASH_SCORE:
  DEC A                   ; The countdown.
  LD (FLASH_COUNT),A      ;
  JR Z,FLASH_SCORE_1
  AND $0F                 ; A beep once every sixteen.
  CALL Z,SOUND_BONUS      ;
  LD HL,$50C8             ; The attributes under the score, not the pixels.
  CALL PIXEL_TO_ATTR      ;
  LD B,$06
FLASH_SCORE_0:
  LD A,(HL)               ; Bit 7 is FLASH; the hardware alternates ink and
  OR $80                  ; paper from there on.
  LD (HL),A               ;
  INC HL
  DJNZ FLASH_SCORE_0
  RET
FLASH_SCORE_1:
  LD HL,$50C8
  CALL PIXEL_TO_ATTR
  LD B,$06
FLASH_SCORE_2:
  LD A,(HL)
  AND $7F
  LD (HL),A
  INC HL
  DJNZ FLASH_SCORE_2
  RET

; Raise the player back out of the floor
;
; The handler for sprite $66, and the mirror of DYING: +$06 counts up instead
; of down and the sprite rises. It is what runs at the start of a game as well
; as after a death, which is why the player's sprite byte reads $66 for several
; seconds before a new game is really under way -- and why CHECK_HIT, which
; only counts sprites below $31 as a player, cannot register a hit during it.
MATERIALISING:
  LD A,(FLASH_COUNT)      ; A bonus flashing on the scroll takes priority over
  AND A                   ; rising.
  JR NZ,FLASH_SCORE
  LD A,(FRAMES)           ; One step in four frames.
  AND $03                 ;
  JP NZ,ANIMATE_COLOUR
  INC (IX+$06)            ; Up a little further.
  LD A,(IX+$07)
  CALL SPRITE_ADDRESS
  LD A,(DE)
  CP (IX+$06)               ; At the top, so become a player again.
  JR Z,FINISH_MATERIALISING ;
; This entry point is used by the routine at DYING.
ANIMATE_SHAPE:
  PUSH DE
  PUSH HL
  LD B,H
  LD C,L
  LD A,(IX+$04)
  LD (IX+$02),A
  SUB (IX+$06)
  LD (IX+$04),A
  LD L,(IX+$06)
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  LD A,H
  LD (BC),A
  DEC BC
  LD A,L
  LD (BC),A
  PUSH HL
  LD C,(HL)
  LD B,(IX+$00)
  PUSH BC
  LD (HL),$01
  LD A,(IX+$07)
  LD (IX+$00),A
  CALL DRAW_THING
  POP BC
  POP HL
  LD (HL),C
  LD (IX+$00),B
  LD A,(IX+$02)
  LD (IX+$04),A
  POP HL
  POP DE
  LD (HL),D
  DEC HL
  LD (HL),E
; This entry point is used by the routine at DYING.
ANIMATE_COLOUR:
  LD A,(IX+$05)
  PUSH AF
  LD A,(FRAMES)
  RRCA
  RRCA
  AND $07
  JR NZ,MATERIALISING_0
  INC A
MATERIALISING_0:
  OR $40
  LD (IX+$05),A
  LD A,(IX+$06)
  CALL DRAW_AT_A
  POP AF
  LD (IX+$05),A
  JP SOUND_FROM_HEADING

; Turn back into the character and clear the animation
;
; Used by the routine at MATERIALISING.
;
; +$07 has been carrying the character's sprite since LOSE_LIFE put it there.
; Restoring it is all it takes to be alive again: the dispatcher will send the
; next frame to UPDATE_KNIGHT, and CHECK_HIT will start counting the player as
; hittable.
FINISH_MATERIALISING:
  LD A,(IX+$07)           ; Back to the knight, the wizard or the serf.
  LD (IX+$00),A           ;
  LD (IX+$06),$00         ; Clear the counter, the saved sprite and the offset.
  LD (IX+$07),$00         ;
  LD (IX+$02),$00         ;
  RET

; Sink the player into the floor
;
; The handler for sprite $67. Every fourth frame it counts +$06 down and shifts
; the sprite further down the screen by that much, so the character appears to
; sink. When the count passes zero it drops an object where the body was and
; hands over to PLACE_PLAYER.
DYING:
  LD A,(FRAMES)           ; One step in four frames.
  AND $03                 ;
  JR Z,ANIMATE_COLOUR
  DEC (IX+$06)            ; Down a little further, until it goes negative.
  JP M,DYING_0            ;
  LD A,(IX+$07)
  CALL SPRITE_ADDRESS
  JP ANIMATE_SHAPE
DYING_0:
  CALL DROP_OBJECT        ; Leave something behind, then carry on.
  JP PLACE_PLAYER         ;

; Put the castle back the way it started
;
; Used by the routine at START_GAME.
;
; One LDIR of $1570 bytes from INITIAL_STATE to $EA90. Everything the game
; keeps at run time -- the player's record, the objects, the monsters, the
; doors, all of it -- exists as a template inside the loaded block and is
; copied wholesale into the working area.
;
; So the runtime tables that do not appear in this disassembly, because they
; live above $D600, do appear in it after all: as five and a half kilobytes of
; data starting at INITIAL_STATE, waiting to be copied. Starting a new game is
; a single block move.
LOAD_INITIAL_STATE:
  LD HL,INITIAL_STATE
  LD DE,PLAYER
  LD BC,$1570
  LDIR
  RET

; Count down the low nibble of +$02
;
; Used by the routine at MOVE_PLAYER.
;
; Does nothing once it reaches zero, so a creature that uses it gets a delay
; that expires and then stays expired until something sets it again.
TICK_LOW_NIBBLE:
  LD A,(IX+$02)
  AND $0F
  RET Z
  DEC (IX+$02)
  RET

; Turn the controls into movement
;
; Used by the routines at UPDATE_WIZARD, UPDATE_SERF and UPDATE_KNIGHT.
;
; The other end of READ_CONTROLS. It takes the byte that routine returns and
; turns it into a signed step on each axis: bit 0 right, bit 1 left, bit 2
; down, bit 3 up, each tested for being clear because a zero bit is a pressed
; one. B holds the distance, so left is B negated and right is B as it stands.
;
; The result goes through STEER rather than straight into the position, so the
; player accelerates into a direction and coasts out of it instead of starting
; and stopping dead.
;
; IX The player
MOVE_PLAYER:
  LD A,(PLAYER_ROOM)      ; Remember which room this is happening in.
  LD (MOVE_ROOM),A        ;
  PUSH BC
  PUSH DE
  PUSH HL
  CALL TICK_LOW_NIBBLE
  LD A,(IX+$02)           ; Mark the record as being worked on.
  OR $30                  ;
  LD (IX+$02),A           ;
  CALL ACTOR_TO_WORKSPACE ; Position into the workspace, then read the
  CALL READ_CONTROLS      ; controls.
  LD C,A
  POP HL
  LD DE,$0000
  BIT 1,C                 ; Left: the step, negated.
  JR NZ,MOVE_PLAYER_0     ;
  LD A,B                  ;
  NEG                     ;
  LD E,A                  ;
MOVE_PLAYER_0:
  BIT 0,C                 ; Right: the step as it is.
  JR NZ,MOVE_PLAYER_1     ;
  LD E,B                  ;
MOVE_PLAYER_1:
  BIT 2,C                 ; Down.
  JR NZ,MOVE_PLAYER_2     ;
  LD D,B                  ;
MOVE_PLAYER_2:
  BIT 3,C                 ; Up: negated again.
  JR NZ,MOVE_PLAYER_3     ;
  LD A,B                  ;
  NEG                     ;
  LD D,A                  ;
MOVE_PLAYER_3:
  POP HL
  CALL DECAY_HEADING      ; Apply it...
  POP HL
  CALL STEER              ; ...through STEER, so the change is gradual.
  CALL STEP_AND_TEST      ;
  CALL WITHIN_ROOM_BOUNDS
  CALL STEP_AND_TEST_2
  JP APPLY_HEADING

; Per-frame update for the serf
;
; The serf's equivalent of UPDATE_KNIGHT, reached from ACTOR_HANDLERS for
; sprite codes $21-$30.
UPDATE_SERF:
  LD BC,$2020
  LD DE,$0101
  LD HL,$0707
  CALL MOVE_PLAYER
  LD E,(IX+$06)
  LD D,(IX+$07)
  LD A,D
  OR E
  JR Z,UPDATE_SERF_4
  LD A,(FRAMES)
  AND $03
  JR NZ,UPDATE_SERF_4
  LD A,(IX+$00)
  AND $03
  ADD A,$21
  LD (IX+$00),A
  LD A,D
  AND A
  JP P,UPDATE_SERF_0
  NEG
UPDATE_SERF_0:
  LD C,A
  LD A,E
  AND A
  JP P,UPDATE_SERF_1
  NEG
UPDATE_SERF_1:
  CP C
  JR NC,UPDATE_SERF_5
  LD A,D
  AND A
  LD A,(IX+$00)
  JP M,UPDATE_SERF_2
  ADD A,$04
UPDATE_SERF_2:
  ADD A,$08
UPDATE_SERF_3:
  LD (IX+$00),A
  CALL SOUND_FOOTSTEP
UPDATE_SERF_4:
  CALL READ_CONTROLS
  AND $10
  CALL Z,TRY_FIRE
  JP PLAYER_TICK
UPDATE_SERF_5:
  LD A,E
  AND A
  LD A,(IX+$00)
  JP M,UPDATE_SERF_3
  ADD A,$04
  JR UPDATE_SERF_3

; Per-frame update for the knight
;
; One of three near-identical routines, one per playable character: this is the
; knight, UPDATE_WIZARD and UPDATE_SERF are the other two. Which one runs is
; decided by the sprite byte alone -- see ACTOR_HANDLERS.
;
; Treats +$06 and +$07 as a signed dx/dy, compares their magnitudes to decide
; whether the movement is mostly horizontal or mostly vertical, and picks a
; sprite accordingly -- base + 4 or base + 8, with the low two bits cycling to
; give the walk cycle.
;
; This looked at first like it contradicted MOVE_ACTOR, which treats +$06 as a
; pair of direction bits rather than a signed value. It does not: the two
; routines work on different records. Breaking on each and reading IX shows
; UPDATE_KNIGHT is only ever called with IX = $EA90, the player, while
; MOVE_ACTOR is called with the 16-byte monster records at $EE90. Both readings
; stand; the field simply means different things in the two layouts.
;
; IX The actor to animate
UPDATE_KNIGHT:
  LD BC,$2020
  LD DE,$0303
  LD HL,$0707
  CALL MOVE_PLAYER
  LD E,(IX+$06)           ; dx and dy. If both are zero the thing is standing
  LD D,(IX+$07)           ; still and keeps its sprite.
  LD A,D
  OR E
  JR Z,UPDATE_KNIGHT_4
  LD A,(FRAMES)           ; FRAMES, so the walk cycle advances every fourth
  AND $03                 ; frame rather than every call. Interrupts are
                          ; enabled during play (checked live: IFF1 set, IM 1),
                          ; so the ROM's interrupt handler is what keeps this
                          ; ticking.
  JR NZ,UPDATE_KNIGHT_4
  LD A,(IX+$00)           ; Cycle the low two bits: the four frames of the
  AND $03                 ; walk.
  INC A                   ;
  LD (IX+$00),A
  LD A,D
  AND A
  JP P,UPDATE_KNIGHT_0
  NEG
UPDATE_KNIGHT_0:
  LD C,A
  LD A,E
  AND A
  JP P,UPDATE_KNIGHT_1
  NEG
UPDATE_KNIGHT_1:
  CP C
  JR NC,UPDATE_KNIGHT_5
  LD A,D                  ; Mostly-vertical movement takes one sprite group,
  AND A                   ; mostly-horizontal another.
  LD A,(IX+$00)           ;
  JP M,UPDATE_KNIGHT_2    ;
  ADD A,$04               ;
UPDATE_KNIGHT_2:
  ADD A,$08
UPDATE_KNIGHT_3:
  LD (IX+$00),A
  CALL SOUND_FOOTSTEP     ; A footstep.
UPDATE_KNIGHT_4:
  CALL READ_CONTROLS
  AND $10
  CALL Z,TRY_FIRE_THIRD
; This entry point is used by the routines at UPDATE_WIZARD and UPDATE_SERF.
PLAYER_TICK:
  CALL SPAWN_MONSTER_INTO_ROOM
  LD A,(TICKS)            ; Only every sixteenth tick.
  AND $0F                 ;
  JR NZ,REDRAW_ACTOR      ;
  LD A,(FOOD_LEVEL)       ; The life force runs down on its own, a unit at a
  DEC A                   ; time. Reaching zero is death -- there is no way to
  JR Z,LOSE_LIFE          ; stand still and survive.
  LD (FOOD_LEVEL),A       ; Store it and redraw the roast, which only actually
  CALL DRAW_FOOD          ; redraws once an eighth has gone.
; This entry point is used by the routines at SPIN_SPELL, MOVE_BAT_ALT,
; MOVE_ACTOR, SPAWN_MONSTER and COUNTDOWN_ACTOR.
REDRAW_ACTOR:
  CALL DRAW_CLIPPED
  JP DRAW_FROM_RECORD
UPDATE_KNIGHT_5:
  LD A,E
  AND A
  LD A,(IX+$00)
  JP M,UPDATE_KNIGHT_3
  ADD A,$04
  JR UPDATE_KNIGHT_3

; Take a life and start the player sinking
;
; Used by the routines at LOSE_FOOD_8, UPDATE_KNIGHT, LOSE_FOOD_32 and
; MUSHROOM_KILLED_PLAYER.
;
; The single way out of the game. Both food penalties and the steady drain
; arrive here when the life force reaches zero, and with no lives left it goes
; straight to GAME_OVER.
;
; Otherwise the player is not moved or hidden -- their sprite is changed to
; $67, which ACTOR_HANDLERS sends to DYING, and the character they were is put
; in +$07 for MATERIALISING to restore. Nothing else has to know a death has
; happened; the sprite byte carries the whole state.
;
; Watched live by starving the player: lives went 3 to 2, the sprite went $08
; to $67 to $66, the life force came back as $F0, and an object appeared in the
; first of the four drop slots reading 8F 00 68 60 68 45 FF 08 -- sprite $8F at
; the exact spot the player fell.
LOSE_LIFE:
  LD A,(LIVES)            ; No lives left...
  AND A                   ;
  JP Z,GAME_OVER          ; ...so that is the end of the game.
  DEC A                   ; Otherwise pay one.
  LD (LIVES),A            ;
  LD A,(IX+$00)           ; Was the thing that died a player at all? Sprites
  DEC A                   ; $01 to $30 are.
  CP $30                  ;
  JR C,LOSE_LIFE_1        ;
  LD A,(PLAYER)
LOSE_LIFE_0:
  LD (PLAYER_DY),A        ; Remember what to come back as.
  CALL SPRITE_ADDRESS
  LD A,(DE)
  LD (PLAYER_DX),A
  LD A,$67                ; $67 -- the sinking animation, which the dispatcher
  LD (PLAYER),A           ; will find on the next pass.
  RET
LOSE_LIFE_1:
  LD A,(WORK_X)           ; A non-player dies where the workspace says it was,
  LD (PLAYER_X),A         ; not where the player is.
  LD A,(WORK_Y)           ;
  LD (PLAYER_Y),A         ;
  LD A,(WORK_SPRITE)
  JR LOSE_LIFE_0

; Take thirty-two off the life force
;
; Used by the routine at MONSTER_CAUGHT_PLAYER.
;
; The heaviest of the three penalties, and the one MOVE_ACTOR's hit path uses.
; Unlike the other two this one clamps to zero rather than underflowing, then
; dies anyway -- the roast is redrawn empty before the life is taken, so the
; bar is seen to run out.
LOSE_FOOD_32:
  LD A,(FOOD_LEVEL)       ; Thirty-two, against sixteen and eight elsewhere.
  SUB $20                 ;
  JR Z,LOSE_FOOD_32_0     ; Exactly zero, or past it: either way the player is
  JR NC,LOSE_FOOD_32_1    ; dead.
  XOR A                   ;
LOSE_FOOD_32_0:
  LD (FOOD_LEVEL),A       ; Show the empty bar first, then lose the life.
  CALL DRAW_FOOD          ;
  JR LOSE_LIFE
LOSE_FOOD_32_1:
  LD (FOOD_LEVEL),A
  JP DRAW_FOOD

; Move a heading towards a target, within limits
;
; Used by the routine at MOVE_PLAYER.
;
; Adds E and D to the pair at +$06 and +$07 and clamps the result to L and H,
; handling the negative side by negating, comparing and negating back. The two
; fields are a signed heading, so this is how a creature turns towards
; something gradually rather than snapping round to face it.
STEER:
  LD A,(IX+$02)           ; Not every call: the low nibble of +$02 gates it.
  AND $0F                 ;
  JR NZ,STEER_6
  LD A,E                  ; Add the change to the horizontal part...
  ADD A,(IX+$06)          ;
  JP M,STEER_2            ; ...taking the negative side separately.
  CP L                    ; Clamp to the limit in L.
  JR C,STEER_0            ;
  LD A,L                  ;
STEER_0:
  LD (IX+$06),A           ; Store it.
  LD A,D                  ; And the vertical part the same way.
  ADD A,(IX+$07)          ;
  JP M,STEER_4
  CP H
  JR C,STEER_1
  LD A,H
STEER_1:
  LD (IX+$07),A
  LD A,(IX+$06)           ; Both parts through the same conversion on the way
  CALL SCALE_SIGNED       ; out.
  LD E,A
  LD A,(IX+$07)
  CALL SCALE_SIGNED
  LD D,A
  RET
STEER_2:
  NEG
  CP L
  JR C,STEER_3
  LD A,L
STEER_3:
  NEG
  JR STEER_0
STEER_4:
  NEG
  CP H
  JR C,STEER_5
  LD A,H
STEER_5:
  NEG
  JR STEER_1
STEER_6:
  LD A,(IX+$06)
  AND A
  JP M,STEER_9
  AND $F0
  JR Z,STEER_7
  LD A,$02
STEER_7:
  LD E,A
  LD A,(IX+$07)
  AND A
  JP M,STEER_10
  AND $F0
  JR Z,STEER_8
  LD A,$02
STEER_8:
  LD D,A
  RET
STEER_9:
  NEG
  AND $F0
  JR Z,STEER_7
  LD A,$FE
  JR STEER_7
STEER_10:
  NEG
  AND $F0
  JR Z,STEER_8
  LD A,$FE
  JR STEER_8

; Move a creature, on the axes it is allowed to move on
;
; Used by the routine at MOVE_PLAYER.
;
; Bits 4 and 5 of +$02 say whether the horizontal and vertical parts of a
; heading are to be applied. A creature pinned to one axis is not a special
; case in the movement code: it is the ordinary code with one of those bits
; clear.
APPLY_HEADING:
  BIT 4,(IX+$02)
  JR NZ,APPLY_HEADING_0
  LD A,E
  ADD A,(IX+$03)
  LD (IX+$03),A
APPLY_HEADING_0:
  BIT 5,(IX+$02)
  RET NZ
  LD A,D
  ADD A,(IX+$04)
  LD (IX+$04),A
  RET

; Divide a signed value by eight
;
; Used by the routine at STEER.
;
; Negates a negative, shifts three times, and puts the sign back. It is how a
; heading in +$06 and +$07 becomes a movement of a pixel or two rather than
; tens of them.
SCALE_SIGNED:
  AND A
  JP P,SCALE_SIGNED_0
  NEG
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  NEG
  RET
SCALE_SIGNED_0:
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  RET

; Let a heading fall back towards nothing
;
; Used by the routine at MOVE_PLAYER.
;
; The counterpart to STEER. Where that adds to the pair at +$06 and +$07, this
; subtracts from them towards zero, so a creature that stops being pushed
; coasts to a halt instead of stopping dead. Gated on the low nibble of +$02,
; so it only bites every so often.
DECAY_HEADING:
  LD A,(IX+$02)
  AND $0F
  RET NZ
  LD A,(IX+$06)
  AND A
  JR Z,DECAY_HEADING_2
  JP M,DECAY_HEADING_5
  SUB L
  JP P,DECAY_HEADING_1
DECAY_HEADING_0:
  XOR A
DECAY_HEADING_1:
  LD (IX+$06),A
DECAY_HEADING_2:
  LD A,(IX+$07)
  AND A
  RET Z
  JP M,DECAY_HEADING_6
  SUB H
  JP P,DECAY_HEADING_4
DECAY_HEADING_3:
  XOR A
DECAY_HEADING_4:
  LD (IX+$07),A
  RET
DECAY_HEADING_5:
  ADD A,L
  JP M,DECAY_HEADING_1
  JR DECAY_HEADING_0
DECAY_HEADING_6:
  ADD A,H
  JP M,DECAY_HEADING_4
  JR DECAY_HEADING_3

; Step a position and check what is there
;
; Used by the routine at MOVE_PLAYER.
;
; Adds the step to +$03 and +$04 and then runs a sixteen-iteration loop over
; the result -- the check that stops a creature walking through a wall.
STEP_AND_TEST:
  PUSH DE
  LD A,E
  ADD A,(IX+$03)
  LD E,A
  LD D,(IX+$04)
  LD B,$10
  CALL DISTANCE_FROM_CENTRE
  POP DE
  PUSH DE
  LD E,(IX+$03)
  LD A,D
  ADD A,(IX+$04)
  LD D,A
  LD B,$20
  CALL DISTANCE_FROM_CENTRE
  POP DE
  RET

; How far from the middle of the room is this?
;
; Used by the routine at STEP_AND_TEST.
;
; Takes the distance from the room's centre column at $58, makes it positive,
; and compares it with the half-width in $5E1D. The same test MOVE_ACTOR makes
; inline, kept as a routine for the callers that need it separately.
DISTANCE_FROM_CENTRE:
  LD HL,ROOM_HALF_WIDTH
  LD A,E
  SUB $58
  JP P,DISTANCE_FROM_CENTRE_0
  NEG
DISTANCE_FROM_CENTRE_0:
  CP (HL)
  RET NC
  INC HL
  LD A,D
  SUB $68
  JP P,DISTANCE_FROM_CENTRE_1
  NEG
DISTANCE_FROM_CENTRE_1:
  CP (HL)
  RET NC
  LD A,B
  CPL
  AND (IX+$02)
  LD (IX+$02),A
  RET

; Step a position and check it, the other way round
;
; Used by the routine at MOVE_PLAYER.
;
; The companion to STEP_AND_TEST, differing in which axis leads.
STEP_AND_TEST_2:
  PUSH DE
  LD A,E
  ADD A,(IX+$03)
  LD E,A
  LD D,(IX+$04)
  LD A,$10
  EX AF,AF'
  CALL POPULATE_ROOM
  POP DE
  PUSH DE
  LD E,(IX+$03)
  LD A,D
  ADD A,(IX+$04)
  LD D,A
  LD A,$20
  EX AF,AF'
  CALL POPULATE_ROOM
  POP DE
  RET

; Set up the records that belong to a room
;
; Used by the routine at STEP_AND_TEST_2.
;
; Every room has a list of the things in it -- its doors, and whatever else is
; fixed there. ROOM_CONTENTS holds one pointer per room, and this walks the
; list it finds, stopping at the $0000 that ends it.
;
; The addresses in the lists are not runtime addresses -- they point into the
; template at INITIAL_STATE that LOAD_INITIAL_STATE copies to $EA90, and taking
; ROOM_CONTENTS off one relocates it. That is not an arbitrary bias: $EA90
; minus INITIAL_STATE is $8A83, and subtracting ROOM_CONTENTS is the same as
; adding $8A83 in sixteen bits. Room $00's list holds DOOR_R07_R00, which is
; $0450 into the template and therefore $EEE0 once copied -- the door record a
; running game really has there.
;
; So the lists can be written once, against the template, and go on being
; correct after it has been moved.
;
; The check part-way down is the door pairing again. A door is two records
; eight bytes apart, one per room; if the one named in the list belongs to the
; other room, eight is added to reach the half that belongs to this one.
;
; IX A record whose +$01 is the room to set up
POPULATE_ROOM:
  LD C,(IX+$01)           ; The room number.
  LD B,$00                ;
  LD HL,ROOM_CONTENTS     ; Two bytes per room, into the table.
  SLA C                   ;
  RL B                    ;
  ADD HL,BC               ;
  LD C,(HL)               ; The start of this room's list.
  INC HL                  ;
  LD B,(HL)               ;
POPULATE_ROOM_0:
  LD A,(BC)               ; The next entry, and $0000 ends the list.
  INC BC                  ;
  LD L,A                  ;
  LD A,(BC)               ;
  INC BC                  ;
  LD H,A                  ;
  OR L                    ;
  RET Z                   ;
  PUSH BC
  LD BC,ROOM_CONTENTS     ; Take the bias off to get the record's real address.
  AND A                   ;
  SBC HL,BC               ;
  INC HL                  ;
  LD A,(HL)               ; Is this the half that belongs to the room being set
  CP (IX+$01)             ; up?
  JR Z,POPULATE_ROOM_1    ; No -- the other half is eight bytes along.
  LD BC,$0008             ;
  ADD HL,BC
POPULATE_ROOM_1:
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  BIT 2,A
  JR NZ,POPULATE_ROOM_4
  BIT 3,A
  JR NZ,POPULATE_ROOM_3
  LD A,(HL)
  SRA A
  SRA A
  AND $FC
  ADD A,C
  SUB E
  NEG
  LD C,A
  LD A,(HL)
  RLCA
  RLCA
  AND $3C
  INC HL
  CP C
  JR C,POPULATE_ROOM_3
  LD A,(HL)
  SRA A
  SRA A
  AND $FC
  ADD A,B
  SUB D
  LD B,A
  LD A,(HL)
  INC HL
  RLCA
  RLCA
  AND $3C
  CP B
  JR C,POPULATE_ROOM_3
  EX AF,AF'
  LD C,A
  EX AF,AF'
  LD A,C
  CPL
  AND (IX+$02)
POPULATE_ROOM_2:
  LD (IX+$02),A
POPULATE_ROOM_3:
  POP BC
  JR POPULATE_ROOM_0
POPULATE_ROOM_4:
  LD A,(HL)
  SRA A
  SRA A
  AND $FC
  ADD A,C
  SUB E
  NEG
  LD C,A
  LD A,(HL)
  RLCA
  RLCA
  AND $3C
  INC HL
  CP C
  JR C,POPULATE_ROOM_3
  LD A,(HL)
  SRA A
  SRA A
  AND $FC
  ADD A,B
  SUB D
  LD B,A
  LD A,(HL)
  INC HL
  RLCA
  RLCA
  AND $3C
  CP B
  JR C,POPULATE_ROOM_3
  EX AF,AF'
  LD C,A
  EX AF,AF'
  LD A,C
  OR (IX+$02)
  JR POPULATE_ROOM_2

; Is the player standing in this doorway?
;
; Used by the routines at DOOR, DOOR_NEEDS_KEY and TRAPDOOR_FALL.
;
; Unlike CHECK_HIT this box is deliberately lopsided. Both comparisons are
; unsigned against a subtraction that is not made absolute, so the player only
; registers from one side of the doorway -- walking into a door from behind
; does nothing.
;
; Bit 6 of +$05 says which way the doorway faces, and it halves the tolerance
; across the door rather than along it: a door in a side wall is generous
; vertically and tight horizontally, and the other way round for one in the top
; or bottom wall. The caller passes $1111 as the starting tolerance in BC.
;
; IX The door
; BC Tolerance across and along the doorway
; F Carry set if the player is in it
PLAYER_AT_DOOR:
  LD A,(PLAYER_FLAG)      ; Suppressed while the low nibble of $EA92 is set --
  AND $0F                 ; the flag ENTER_ROOM leaves behind, so one doorway
  RET NZ                  ; cannot fire twice.
  LD A,(PLAYER)           ; And only while the player is actually in play, the
  DEC A                   ; same $01-$30 test CHECK_HIT makes.
  CP $30                  ;
  RET NC                  ;
  BIT 6,(IX+$05)          ; Halve the tolerance across the door, unless it
  JR Z,PLAYER_AT_DOOR_0   ; faces the other way.
  SRL C                   ;
PLAYER_AT_DOOR_0:
  LD A,(PLAYER_X)         ; One-sided: unsigned, so a negative difference fails
  SUB (IX+$03)            ; the compare outright.
  CP C                    ;
  RET NC                  ;
  BIT 6,(IX+$05)
  JR NZ,PLAYER_AT_DOOR_1
  SRL B
PLAYER_AT_DOOR_1:
  LD A,(PLAYER_Y)         ; The same again for the other axis, negated because
  SUB (IX+$04)            ; this one is measured the opposite way.
  NEG                     ;
  CP B                    ;
  RET

; Is the player within 12 pixels of this thing?
;
; Used by the routines at EAT_FOOD, PICK_UP and MUSHROOM.
;
; The symmetric version of the test PLAYER_AT_DOOR makes -- absolute difference
; on both axes against the same 12-pixel box CHECK_HIT uses, with no room check
; and no one-sidedness.
;
; IX The thing to measure from
NEAR_PLAYER:
  LD A,(PLAYER_X)         ; |dx|, by negating if it came out negative.
  SUB (IX+$03)            ;
  JP P,NEAR_PLAYER_0      ;
  NEG
NEAR_PLAYER_0:
  CP $0C
  RET NC
  LD A,(PLAYER_Y)
  SUB (IX+$04)
  JP P,NEAR_PLAYER_1
  NEG
NEAR_PLAYER_1:
  CP $0C
  RET

; Move the player through a door and redraw everything
;
; Used by the routines at DOOR, DOOR_LOCKED_A and TRAPDOOR_FALL.
;
; Takes the door record in IX, copies its destination into the player's room
; and position, and then rebuilds the screen: mark the room seen, blank the
; play area, draw the new room, recolour the panel.
;
; The arrival position is not stored outright. +$02 packs both offsets into one
; byte, unpacked by rotating it in opposite directions and masking to $1E -- an
; even number 0 to 30 each way, the vertical one negated. Every door checked
; holds $34, which comes out as 8 to the right and 6 up, so the player lands
; just inside the room rather than on top of the doorway they arrived through.
;
; Confirmed by setting IX to four different door records and running from
; ENTER_ROOM+3, past its first call: doors to rooms $07, $19, $01 and $00
; produced exactly the destination and the offset position predicted from their
; bytes.
;
; IX The door being entered
ENTER_ROOM:
  CALL DOOR_OTHER_SIDE    ; Swap to the door's other side. The record the
                          ; player touched describes this room; the one eight
                          ; bytes away describes where they come out. That
                          ; reassignment of IX is also why anything testing
                          ; this routine has to enter below it.
  LD A,(IX+$01)           ; +$01 is the destination room.
  LD (PLAYER_ROOM),A      ;
  LD A,(IX+$02)           ; Rotate left and mask: the horizontal offset, added
  RLCA                    ; to the door's own x.
  AND $1E                 ;
  ADD A,(IX+$03)          ;
  LD (PLAYER_X),A         ;
  LD A,(IX+$02)           ; Rotate right three times for the vertical one,
  RRCA                    ; which is subtracted rather than added.
  RRCA                    ;
  RRCA                    ;
  AND $1E                 ;
  NEG                     ;
  ADD A,(IX+$04)          ;
  LD (PLAYER_Y),A         ;
  CALL MODE_TO_INDEX
  LD A,(PLAYER_FLAG)      ; Set the flag that stops PLAYER_AT_DOOR firing again
  OR $0F                  ; on the way out.
  LD (PLAYER_FLAG),A      ;
; This entry point is used by the routine at START_GAME.
ARRIVE_IN_ROOM:
  LD A,(PLAYER_ROOM)      ; Record the new room as seen.
  CALL MARK_ROOM_VISITED  ;
  CALL CLEAR_PLAY_AREA    ; Blank the play area, draw the new room, colour the
  CALL DRAW_ROOM          ; panel to match.
  CALL PAINT_PANEL        ;
  CALL DRAW_INVENTORY
  CALL PLAY_SOUND_65
  JP MAIN_LOOP
; The doors themselves are 8-byte records in a table above the monsters, around
; $EEE0: +$00 a sprite, +$01 the destination room, +$02 the packed arrival
; offset, +$03 and +$04 the doorway's own position, +$05 flags with bit 6
; giving its facing. Only the ones whose +$01 matches the room the player is in
; get tested.

; Count down, then behave as a door
;
; The same delay WAIT_THEN_ACT runs, but ending in DOOR rather than a draw -- a
; doorway that will not work until its counter has run out.
WAIT_THEN_DOOR:
  LD A,(TICKS)
  AND $01
  JP NZ,DOOR
  LD A,(DOOR_WAIT)
  AND A
  JR Z,WAIT_THEN_DOOR_0
  DEC A
  LD (DOOR_WAIT),A
  JP DOOR
WAIT_THEN_DOOR_0:
  LD A,(FIRE_BLOCKED)
  AND A
  JP NZ,DOOR
  JR RESTART_WAIT

; Count a delay down before doing anything
;
; Runs on alternate frames only, and while the counter at $5E2E is above zero
; it does nothing but decrement it and draw. When it finally reaches zero the
; routine below it runs. Reached from the handlers for sprites $C2 and $C4.
WAIT_THEN_ACT:
  LD A,(TICKS)
  AND $01
  JP NZ,DRAW_DOOR
  LD A,(DOOR_WAIT)
  AND A
  JP Z,RESTART_WAIT
  DEC A
  LD (DOOR_WAIT),A
  JP DRAW_DOOR
; This entry point is used by the routine at WAIT_THEN_DOOR.
RESTART_WAIT:
  LD A,$5E
  LD (DOOR_WAIT),A
  LD A,(IX+$05)
  PUSH AF
  OR $03
  LD (IX+$05),A
  CALL DRAW_RECORD
  LD A,(IX+$00)
  XOR $01
  CALL SET_BOTH_HALVES
  CALL DRAW_RECORD
  POP AF
  LD (IX+$05),A
  CALL DOOR_OPEN_OR_SHUT
  CALL DRAW_DOOR
  JP SOUND_NOISE_BURST

; Draw something twice over and make a noise
;
; Draws the thing with the low bits of its drawing mode forced on, then again
; with the bottom bit of its sprite flipped -- the other animation frame --
; then puts the mode back and draws it properly, and finishes by jumping into
; SOUND_NOISE_BURST. Three overlapping draws and a rasp, which is what a thing
; being destroyed looks and sounds like.
FLASH_AND_RASP:
  LD A,(TICKS)            ; One gate before any of it.
  AND A                   ;
  JP NZ,DRAW_DOOR         ;
  JR FLASH_AND_RASP_0
TRAPDOOR:
  LD A,(RUNNING_SUM)
  AND A
  JP NZ,TRAPDOOR_FALL
FLASH_AND_RASP_0:
  LD A,(IX+$05)           ; Force the low bits of the drawing mode on, and
  PUSH AF                 ; draw.
  OR $03                  ;
  LD (IX+$05),A           ;
  CALL DRAW_RECORD
  LD A,(IX+$00)           ; The other frame, over the top.
  XOR $01                 ;
  LD (IX+$00),A           ;
  CALL DRAW_RECORD        ;
  POP AF                  ; Put the mode back and draw it properly.
  LD (IX+$05),A           ;
  CALL DRAW_DOOR          ;
  JP SOUND_NOISE_BURST    ; And the rasp.
BIG_DOOR:
  LD BC,$2020
  JR DOORWAY

; An ordinary door
;
; Used by the routines at WAIT_THEN_DOOR and DOOR_SERF.
;
; The plain doorway, and the routine every other kind falls back on once it has
; decided to let the player through. It offers $1111 as the tolerance, asks
; PLAYER_AT_DOOR whether anyone is standing in it, and calls ENTER_ROOM if so
; -- then draws itself either way.
DOOR:
  LD BC,$1111
; This entry point is used by the routines at FLASH_AND_RASP and ACG_DOOR.
DOORWAY:
  CALL PLAYER_AT_DOOR
  CALL C,ENTER_ROOM
  JP DRAW_DOOR
; This entry point is used by the routines at WAIT_THEN_ACT, FLASH_AND_RASP,
; DOOR_LOCKED_A, DOOR_LOCKED_B, DOOR_SERF, ACG_DOOR and TRAPDOOR_FALL.
DRAW_DOOR:
  LD E,(IX+$03)
  LD D,(IX+$04)
  DEC D
  LD C,(IX+$00)
  LD B,(IX+$05)
  CALL DRAW_SPRITE_COLOURS
  LD A,(ROOM_DRAWN)
  AND A
  RET NZ
; This entry point is used by the routines at DRAW_FOOD, WAIT_THEN_ACT and
; FLASH_AND_RASP.
DRAW_RECORD:
  LD E,(IX+$03)
  LD D,(IX+$04)
  LD C,(IX+$00)
  LD B,(IX+$05)
  JP DRAW_SPRITE_PIXELS

; Will this locked door open?
;
; Used by the routines at DOOR_LOCKED_A and DOOR_LOCKED_B.
;
; The coloured doors. Each carries its colour in the low two bits of its own
; sprite, which index four attribute bytes at DOOR_COLOURS, and the door opens
; only if the player is carrying a key -- sprite $81 -- of that same colour.
;
; So the lock is not a flag anywhere. The door's colour is part of its sprite
; number, the key's colour is the drawing mode stored with it when it was
; picked up, and opening the door is a comparison of the two.
;
; IX The door
; F Carry set if it opens
DOOR_NEEDS_KEY:
  LD A,(IX+$00)           ; The low two bits of the sprite are the colour.
  AND $03                 ;
  LD HL,DOOR_COLOURS      ; Look it up.
  CALL ADD_A_TO_HL        ;
  LD D,(HL)               ; $81 is a key; D is the colour it has to be.
  LD E,$81                ;
  CALL FIND_CARRIED       ; Not carrying it: the door stays shut.
  JP NZ,DOOR_NEEDS_KEY_0  ;
  CALL OPEN_DOOR          ; Carrying it: behave as an ordinary doorway from
  LD BC,$1111             ; here on.
  JP PLAYER_AT_DOOR
DOOR_NEEDS_KEY_0:
  CALL SHUT_DOOR          ; Draw it shut and report no.
  AND A                   ;
  RET                     ;

; A locked door of the first sort
;
; Asks DOOR_NEEDS_KEY whether the player has the matching key. With one it sets
; the sprite on both halves to $02 through SET_BOTH_HALVES and goes through to
; ENTER_ROOM; without one it just draws itself shut.
DOOR_LOCKED_A:
  CALL DOOR_NEEDS_KEY
  JP NC,DRAW_DOOR
  LD A,$02
; This entry point is used by the routine at DOOR_LOCKED_B.
OPEN_AND_ENTER:
  CALL SET_BOTH_HALVES
  JP ENTER_ROOM

; A locked door of the second sort
;
; The same as DOOR_LOCKED_A but setting $01 rather than $02, so the two look
; different once open. They share everything from the third instruction on.
DOOR_LOCKED_B:
  CALL DOOR_NEEDS_KEY
  JP NC,DRAW_DOOR
  LD A,$01
  JR OPEN_AND_ENTER

; The four door colours
;
; Indexed by the low two bits of a door's sprite. The same four values are what
; a key carries as its drawing mode, so the comparison in FIND_CARRIED is
; between a door's colour and a key's colour with no translation in between.
DOOR_COLOURS:
  DEFB $42,$44,$45,$46

; Give both halves of a door the same sprite
;
; Used by the routines at WAIT_THEN_ACT and DOOR_LOCKED_A.
;
; Writes the sprite into the record IX points at, then flips bit 3 of the
; address -- the DOOR_OTHER_SIDE trick -- and writes it into the far half too.
; An open door has to look open from both rooms.
SET_BOTH_HALVES:
  PUSH IX
  POP HL
  LD (HL),A
  EX AF,AF'
  LD A,L
  XOR $08
  LD L,A
  EX AF,AF'
  LD (HL),A
  RET

; Add an unsigned byte to HL
;
; Used by the routines at DOOR_NEEDS_KEY and WORKSPACE_AND_DRAW.
;
; Four instructions to do what the Z80 has no single instruction for. Used
; wherever a table is indexed by a byte, which is most places.
ADD_A_TO_HL:
  ADD A,L
  LD L,A
  LD A,H
  ADC A,$00
  LD H,A
  RET

; Is the player carrying this?
;
; Used by the routines at MOVE_DRACULA, MOVE_FRANKENSTEIN and DOOR_NEEDS_KEY.
;
; Walks the three slots of the inventory looking for one that matches on both
; bytes: the sprite in E and the drawing mode -- which for a key is its colour
; -- in D. It starts at $5E32 rather than $5E30 because the first two bytes of
; a slot are the object's address; the sprite and the mode are the third and
; fourth, which is exactly what REMEMBER_CARRIED put there.
;
; E The sprite to look for
; D The colour it has to be
; F Zero flag set if it is being carried
FIND_CARRIED:
  LD B,$03                ; Three slots, four bytes each, starting at the
  LD HL,CARRIED_SPRITE    ; sprite byte of the first.
FIND_CARRIED_0:
  LD A,(HL)               ; Wrong sprite: on to the next slot.
  CP E                    ;
  INC HL                  ;
  JR NZ,FIND_CARRIED_1    ;
  LD A,(HL)               ; Right sprite, right colour: found.
  CP D                    ;
  RET Z                   ;
FIND_CARRIED_1:
  INC HL                  ; Step over the rest of the slot.
  INC HL                  ;
  INC HL                  ;
  DJNZ FIND_CARRIED_0     ;
  RET

; Swap IX to the far side of a door
;
; Used by the routines at ENTER_ROOM, OPEN_DOOR and SHUT_DOOR.
;
; A door is two records, one for each room it joins, and they are deliberately
; put eight bytes apart so that the other side is found by flipping one bit of
; the address. No pointer, no table, no search: XOR the low byte with $08 and
; IX is looking at the other half.
;
; That pairing is why the door records read out of a running game sit at $EEE0
; and $EEE8, $EEF0 and $EEF8. Each side carries the destination and arrival
; position for going that way, so walking through is a matter of reading the
; record you did not touch.
;
; IX A door; on exit, its other side
DOOR_OTHER_SIDE:
  PUSH IX                 ; IX into HL, where its low byte can be got at.
  POP HL                  ;
  LD A,L                  ; One bit is the whole of it.
  XOR $08                 ;
  LD L,A                  ;
  PUSH HL                 ; And back into IX.
  POP IX                  ;
  RET

; Draw everything in the player's room
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Walks the eight-byte records from the player up to the monster table, drawing
; each one whose room matches the player's and skipping any whose sprite is
; zero. It is the sweep that puts the room's objects, doors and the player back
; on the screen after the play area has been cleared.
DRAW_ROOM_CONTENTS:
  LD IX,PLAYER            ; From the player upwards.
DRAW_ROOM_CONTENTS_0:
  LD A,(IX+$00)             ; A zero sprite is an empty slot.
  AND A                     ;
  JR Z,DRAW_ROOM_CONTENTS_1 ;
  LD A,(PLAYER_ROOM)         ; And only things in this room.
  CP (IX+$01)                ;
  JR NZ,DRAW_ROOM_CONTENTS_1 ;
  CALL DRAW_THING         ; Draw it.
DRAW_ROOM_CONTENTS_1:
  LD DE,$0008             ; Eight bytes to the next.
  ADD IX,DE               ;
  PUSH IX
  POP HL
  LD DE,LIVE_MONSTERS
  AND A
  SBC HL,DE
  JR C,DRAW_ROOM_CONTENTS_0
DRAW_ROOM_CONTENTS_2:
  LD A,(IX+$00)
  AND A
  JR Z,DRAW_ROOM_CONTENTS_3
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  JR NZ,DRAW_ROOM_CONTENTS_3
  CALL DRAW_THING
DRAW_ROOM_CONTENTS_3:
  LD DE,$0010
  ADD IX,DE
  PUSH IX
  POP HL
  LD DE,LIVE_DOORS
  AND A
  SBC HL,DE
  JR C,DRAW_ROOM_CONTENTS_2
  RET

; Clear bit 1 of the drawing flags
;
; Used by the routine at PICK_UP.
;
; Reads $5E1F, ANDs out bit 1 and writes it back. Three instructions on their
; own, with no return -- it is fallen into rather than called.
CLEAR_DRAW_FLAG:
  LD A,(CARRYING)
  AND $FD
  LD (CARRYING),A

; Draw a thing where its record says it is
;
; Used by the routines at EAT_FOOD, PICK_UP, GRAVESTONE and MUSHROOM.
;
; Sets the width, works out where the sprite lands from +$03, and draws. The
; plain "put it on the screen" ending that most creature handlers jump to when
; they have nothing else to do.
DRAW_AT_POSITION:
  LD A,$10
; This entry point is used by the routine at MATERIALISING.
DRAW_AT_A:
  LD (DRAW_SHIFT),A
  LD A,(IX+$03)
  AND $07
  LD A,$02
  JR Z,DRAW_AT_POSITION_0
  INC A
DRAW_AT_POSITION_0:
  LD (DRAW_WIDTH),A
  JP DRAW_FROM_RECORD

; Pick a collectable up
;
; The playthroughs that build the code map never reach this, so the automatic
; pass leaves it as data. It is not: the bytes decode cleanly as code from the
; first byte, and forcing it here costs nothing -- the round-trip check still
; reassembles the whole game byte for byte, which it could not do if the split
; were wrong.
;
; The handler for sprites $80 to $8E -- the keys and the objects that kill the
; four big monsters. Like the food it does nothing but wait: every frame it
; asks whether the player is standing on it, and only then acts.
;
; Picking something up is not free. The player can hold three things, and
; taking a fourth pushes the oldest out, so the three calls at the end run in
; the order they have to: DROP_CARRIED first, while the item about to be lost
; can still be read, then SHIFT_CARRIED to make room, then REMEMBER_CARRIED to
; put the new one at the front.
;
; IX The collectable
PICK_UP:
  CALL ACTOR_TO_WORKSPACE ; Position and sprite into the workspace.
  LD A,(PICKUP_KEY)       ; Two gates before anything else is considered.
  AND A                   ;
  JR Z,CLEAR_DRAW_FLAG    ;
  LD A,(CARRYING)         ;
  AND $03                 ;
  JR NZ,DRAW_AT_POSITION  ;
  LD A,(PLAYER)           ; And the player has to actually be in play, the same
  DEC A                   ; $01-$30 test CHECK_HIT makes.
  CP $30                  ;
  JR NC,DRAW_AT_POSITION
  CALL NEAR_PLAYER        ; Standing on it?
  JR NC,DRAW_AT_POSITION  ;
  LD A,(CARRYING)         ; Mark that something is being carried.
  OR $03                  ;
  LD (CARRYING),A         ;
  CALL DROP_CARRIED       ; Put the oldest of the three back into the world...
  CALL SHIFT_CARRIED      ; ...shift the other two along...
  CALL REMEMBER_CARRIED   ; ...and record the new one at the front.
  JP DRAW_INVENTORY

; Record what has just been picked up
;
; Used by the routine at PICK_UP.
;
; Writes four bytes into the first slot at $5E30: the address of the object's
; own record, then its sprite and its drawing mode. Keeping the address rather
; than a copy is what lets DROP_CARRIED put the thing back exactly as it was.
REMEMBER_CARRIED:
  LD HL,CARRIED
  PUSH IX
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD A,(IX+$00)
  LD (HL),A
  INC HL
  LD A,(IX+$05)
  LD (HL),A
  CALL ERASE_THING
  LD A,(ROOM_COLOUR)
  LD (IX+$05),A
  CALL DRAW_FROM_RECORD
  LD (IX+$00),$00
  JP BEEP_ENTRIES

; Move the carried items along one slot
;
; Used by the routines at PICK_UP and PUT_DOWN.
;
; Three slots of four bytes at $5E30, $5E34 and $5E38. LDDR copies the eight
; bytes at $5E30 up to $5E34, so the newest slot is freed and whatever was in
; the third is overwritten -- which is why DROP_CARRIED has to run first.
SHIFT_CARRIED:
  LD HL,CARRIED+$0007     ; CARRIED+7: the last byte of the second slot...
  LD DE,CARRIED+$000B     ; CARRIED+11: ...and of the third
  LD BC,$0008
  LDDR
  RET

; Put the oldest carried thing back in the room
;
; Used by the routines at PICK_UP and PUT_DOWN.
;
; Reads the third slot at $5E38 and returns at once if it is empty, so nothing
; happens until the player is already carrying three. Otherwise it builds a
; record where the player is standing -- the sprite it had, the player's room
; from $EA91, then $80, then the player's x and y from $EA93 and $EA94 -- so a
; dropped object lands at your feet and can be picked straight back up.
DROP_CARRIED:
  LD HL,THIRD_SLOT        ; The slot about to be lost.
  LD E,(HL)               ;
  INC HL                  ;
  LD D,(HL)               ;
  INC HL                  ;
  LD A,D
  OR E
  RET Z                   ; Nothing there: the player is not carrying three
  PUSH DE                 ; yet.
  LD A,(HL)
  INC HL
  LD (DE),A
  INC DE
  LD A,(PLAYER_ROOM)
  LD (DE),A
  INC DE
  LD A,$80
  LD (DE),A
  INC DE
  LD A,(PLAYER_X)
  LD (DE),A
  INC DE
  LD A,(PLAYER_Y)
  LD (DE),A
  INC DE
  LD A,(HL)
  LD (DE),A
  POP DE
  CALL SHORT_HIGH_BEEP
  PUSH IX
  PUSH DE
  POP IX
  CALL DRAW_THING
  POP IX
  RET

; Read one key and remember whether it is down
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Selects the half-row holding B, N, M, symbol shift and space, keeps one bit
; of it and leaves the answer at $5E20 for other routines to look at rather
; than reading the keyboard again.
READ_FIRE_ROW:
  LD A,$7E
  OUT ($FD),A
  IN A,($FE)
  CPL
  AND $02
  LD (PICKUP_KEY),A
  RET

; Read the cursor keys
;
; Used by the routine at READ_CONTROLS.
;
; The branch READ_CONTROLS takes when the cursor option was chosen. The cursor
; keys are not adjacent in the matrix the way Q, W, E, R and T are, so this
; reads a different half-row and assembles the same five bits by hand rather
; than swapping two of them.
READ_CURSOR_KEYS:
  LD A,$EF
  OUT ($FD),A
  IN A,($FE)
  LD C,A
  AND $08
  LD E,A
  LD A,C
  RRCA
  RRCA
  AND $45
  OR E
  LD E,A
  RRCA
  RRCA
  AND $10
  OR E
  AND $1F
  LD E,A
  LD A,$F7
  OUT ($FD),A
  IN A,($FE)
  RRA
  RRA
  RRA
  AND $02
  OR E
  RET

; Read the player's controls, whichever kind they chose
;
; Used by the routines at UPDATE_WIZARD, MOVE_PLAYER, UPDATE_SERF and
; UPDATE_KNIGHT.
;
; Returns one byte for all three control methods, in Kempston's bit order: bit
; 0 right, bit 1 left, bit 2 down, bit 3 up, bit 4 fire. A bit is 0 when that
; direction is being asked for.
;
; Kempston reads the other way round, so its byte is inverted; the keyboard
; needs no inversion but does need its bits shuffled, because Q and W sit in
; the opposite order to left and right. That swap is the whole reason this
; routine looks fiddly -- it is what lets the movement code downstream be
; written once instead of three times.
;
; This is what pins down the key map: the half-row selected is $FBFE, which is
; Q W E R T, and after the swap Q lands on the "left" bit and W on the "right"
; bit. So the keyboard controls are Q left, W right, E down, R up, T fire.
; Confirmed live -- holding W drives the player's x up to the room's right-hand
; limit and E drives y down to the bottom one.
;
; A The direction/fire mask, 0 bits meaning pressed
READ_CONTROLS:
  LD A,(SELECTION)        ; The control method chosen on the title screen, kept
  AND $06                 ; in $5E00.
  JR Z,READ_CONTROLS_0    ; 0 is keyboard, 4 is the cursor keys, anything else
  CP $04                  ; Kempston.
  JR Z,READ_CURSOR_KEYS   ;
  IN A,($1F)              ; Kempston is active high, so invert it to match the
  CPL                     ; other two.
  RET
READ_CONTROLS_0:
  LD A,$FB                ; Select the half-row holding Q, W, E, R and T.
  OUT ($FD),A             ;
  IN A,($FE)              ; Bits 0-4 are Q, W, E, R, T in that order.
  LD C,A                  ;
  RRA                     ; Exchange bits 0 and 1, so that W becomes "right"
  AND $01                 ; and Q "left".
  LD E,A                  ;
  LD A,C                  ;
  RLA                     ;
  AND $02                 ;
  OR E                    ;
  LD E,A
  LD A,C                  ; E, R and T are already in the right places for
  AND $1C                 ; down, up and fire.
  OR E                    ;
  RET

; Put a carried object down
;
; The counterpart to PICK_UP, and gated the same way: the player has to be in
; play, and the flags at $5E20 and $5E1F have to agree that something is being
; carried. Where PICK_UP takes an object out of the room and into the three
; slots, this takes one back out of the slots and leaves it where the player is
; standing.
PUT_DOWN:
  LD A,(PLAYER)
  DEC A
  CP $30
  RET NC
  LD A,(PICKUP_KEY)
  AND A
  JR Z,PUT_DOWN_1
  LD A,(CARRYING)
  AND $03
  JR NZ,PUT_DOWN_0
  OR $02
  LD (CARRYING),A
  CALL DROP_CARRIED
  CALL SHIFT_CARRIED
  LD HL,$0000
  LD (CARRIED),HL
  LD (CARRIED_SPRITE),HL
  CALL DRAW_INVENTORY
PUT_DOWN_0:
  LD A,(CARRYING)
  AND $FE
  LD (CARRYING),A
  RET
PUT_DOWN_1:
  LD A,(CARRYING)
  AND $FD
  LD (CARRYING),A
  JR PUT_DOWN_0

; A door the serf can use
;
; Three doors, three entry points, one test. Each subtracts a character's first
; sprite from the player's current one and asks whether what is left is under
; $10 -- which is exactly "is the player this character", since each character
; owns sixteen consecutive sprite codes. DOOR_SERF takes $21 for the serf,
; DOOR_WIZARD takes $11 for the wizard and DOOR_KNIGHT takes 1 for the knight,
; and the three sprites that reach them are $BC, $B9 and $B2.
;
; Pass the test and the thing behaves as an ordinary door, through the same
; DOOR that every other door goes through. Fail it and control goes to
; DRAW_DOOR instead, which draws it and nothing more: the door is there,
; visible, and will not open.
;
; IX The door
DOOR_SERF:
  LD A,(PLAYER)           ; The serf's sprites start at $21.
  SUB $21                 ;
  JR DOOR_SERF_0
DOOR_WIZARD:
  LD A,(PLAYER)           ; The wizard's at $11.
  SUB $11                 ;
  JR DOOR_SERF_0
DOOR_KNIGHT:
  LD A,(PLAYER)           ; The knight's at 1.
  DEC A                   ;
DOOR_SERF_0:
  CP $10                  ; Sixteen codes per character, so anything under $10
  JR NC,DOOR_SERF_1       ; is a match.
  CALL OPEN_DOOR          ; The right character: let them through.
  JP DOOR                 ;
DOOR_SERF_1:
  CALL SHUT_DOOR          ; The wrong one: draw it and leave it shut.
  JP DRAW_DOOR            ;

; Build the player's record from scratch
;
; Used by the routines at START_GAME and DYING.
;
; Copies the eight-byte template at PLAYER_TEMPLATE over $EA90, having patched
; two things into it first: the room, from $EA91, and -- into the template's
; last byte, not its first -- the character's sprite, worked out from the menu
; selection the way DRAW_LIVES does it: shift $5E00 up, mask to $30, add 8.
;
; The first byte of the template is $66, and that is the point. A game does not
; begin with the player standing there; it begins with them rising out of the
; floor, because $66 is what MATERIALISING answers to. The character's own
; sprite goes into +$07, which is where FINISH_MATERIALISING looks when the
; animation ends.
;
; This is the answer to something that looked like a bug early on: reading the
; player's sprite byte a second after starting a game gives $66, not $08, and
; nothing responds to the controls. Nothing is wrong -- the player has not
; finished arriving.
PLACE_PLAYER:
  LD A,(SELECTION)
  RLCA
  AND $30
  ADD A,$08
  LD (PLAYER_TEMPLATE+$0007),A ; PLAYER_TEMPLATE+7: the character's sprite
  LD A,(PLAYER_ROOM)
  LD (PLAYER_TEMPLATE+$0001),A ; PLAYER_TEMPLATE+1: the room
  LD HL,PLAYER_TEMPLATE
  LD DE,PLAYER
  LD BC,$0008
  LDIR
  LD A,$68
  LD (FLASH_COUNT),A
  LD A,(LIVES)
  CP $03
  JR Z,PLACE_PLAYER_0
  PUSH IX
  LD IX,PLAYER
  CALL DRAW_THING
  POP IX
PLACE_PLAYER_0:
  LD A,$F0
  LD (FOOD_LEVEL),A
  CALL DRAW_FOOD
  JP DRAW_LIVES

; A player, ready to copy
;
; 66 00 00 60 68 47 FF 00. Sprite $66 is the materialising animation, $60 and
; $68 the position, and the last byte is patched by PLACE_PLAYER with the
; sprite to turn into once the player has finished rising.
PLAYER_TEMPLATE:
  DEFB $66,$00,$00,$60,$68,$47,$FF,$00

; Look at a key with interrupts off
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Turns interrupts off before reading the keyboard directly, so the answer
; cannot be disturbed half way. Returns at once unless the key is down.
CHECK_KEY_HELD:
  DI
  LD A,$7E
  OUT ($FD),A
  IN A,($FE)
  BIT 0,A
  RET NZ
  CPL
  AND $1E
  RET NZ
CHECK_KEY_HELD_0:
  LD A,$7E
  OUT ($FD),A
  IN A,($FE)
  BIT 0,A
  JR Z,CHECK_KEY_HELD_0
CHECK_KEY_HELD_1:
  LD A,$7E
  OUT ($FD),A
  IN A,($FE)
  BIT 0,A
  JR NZ,CHECK_KEY_HELD_1
CHECK_KEY_HELD_2:
  LD A,$7E
  OUT ($FD),A
  IN A,($FE)
  BIT 0,A
  JR Z,CHECK_KEY_HELD_2
  RET

; A number that changes every frame
;
; Used by the routine at START_GAME.
;
; Adds the frame counter to $5E12 and keeps three bits, so callers get a value
; that walks 0 to 7 over time without anyone having to keep a counter for it.
ROTATING_INDEX:
  LD A,(FRAMES)
  LD C,A
  LD A,(TICKS)
  ADD A,C
  AND $07
  LD C,A
  ADD A,A
  ADD A,C
  LD L,A
  LD H,$00
  LD BC,KEY_ROOM_SETS
  ADD HL,BC
  EX DE,HL
  LD HL,ACG_KEY_PARTS+$0001 ; ACG_KEY_PARTS+1: the first piece's room
  LD BC,$0008
  LD A,$03
ROTATING_INDEX_0:
  EX AF,AF'
  LD A,(DE)
  LD (HL),A
  ADD HL,BC
  INC DE
  EX AF,AF'
  DEC A
  JR NZ,ROTATING_INDEX_0
  RET

; Eight sets of three rooms, for hiding the key
;
; The routine above picks a set with (A + C) AND $07, multiplies by three, and
; copies the three bytes into the room bytes of ACG_KEY_PARTS, stepping by
; eight -- which is +$01 of three consecutive object records in INITIAL_STATE,
; the field that says which room the object is in. So this chooses where the
; three pieces are hidden, and it does it by editing the template before
; LOAD_INITIAL_STATE copies it.
;
; Every one of the 24 values is a valid room number, 149 or less, which is what
; a table of rooms should look like and what a table of anything else almost
; certainly would not.
KEY_ROOM_SETS:
  DEFB $81,$45,$7C
  DEFB $85,$49,$2B
  DEFB $6A,$3B,$7C
  DEFB $69,$71,$2B
  DEFB $67,$85,$7C
  DEFB $68,$7F,$2B
  DEFB $4D,$73,$7C
  DEFB $17,$10,$2B

; Walk the doors, sixteen bytes at a time
;
; Used by the routine at START_GAME.
;
; Steps through the door table in pairs -- $EEE0 and $EEE8 together, then the
; next pair -- with the frame counter's low bits in H, and tests each sprite
; against $70. Doors in Atic Atac open and close of their own accord, and this
; is the sweep that decides which are which.
SCAN_DOORS:
  LD A,(TICKS)            ; The frame counter drives it.
  LD L,A                  ;
  LD A,(FRAMES)           ; Low bits of the frame, with bit 4 forced on.
  AND $0F                 ;
  OR $10                  ;
  LD H,A
  EXX
  LD HL,LIVE_DOORS        ; The two halves of the first door, sixteen bytes to
  LD DE,LIVE_DOORS+$0008  ; the next pair.
  LD BC,$0010             ;
SCAN_DOORS_0:
  EXX
  LD A,(HL)
  INC HL
  EXX
  CP $70
  JR NC,SCAN_DOORS_1
  LD A,(DE)
  CP (HL)
  JR NZ,SCAN_DOORS_1
  CP $01
  JR Z,SCAN_DOORS_2
  CP $02
  JR Z,SCAN_DOORS_4
SCAN_DOORS_1:
  ADD HL,BC
  EX DE,HL
  ADD HL,BC
  RET C
  EX DE,HL
  JR SCAN_DOORS_0
SCAN_DOORS_2:
  LD A,$22
SCAN_DOORS_3:
  LD (DE),A
  LD (HL),A
  PUSH DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  LD A,(DE)
  OR $08
  LD (DE),A
  POP DE
  PUSH HL
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  OR $08
  LD (HL),A
  POP HL
  JR SCAN_DOORS_1
SCAN_DOORS_4:
  LD A,$20
  JR SCAN_DOORS_3

; Open or shut a door, according to its sprite
;
; Used by the routine at WAIT_THEN_ACT.
;
; Bit 0 of the sprite says which, so a door's own number carries whether it is
; currently open, and the two routines below do the work on both halves.
DOOR_OPEN_OR_SHUT:
  LD A,(IX+$00)
  AND $01
  JR Z,SHUT_DOOR

; Open a door, both halves at once
;
; Used by the routines at DOOR_NEEDS_KEY, DOOR_SERF and ACG_DOOR.
;
; Clear bit 3 of the drawing mode -- the bit that says a door is shut -- and
; clear it on the far side too, so the two halves never disagree about whether
; the door is open. DOOR_NEEDS_KEY calls it when the player is carrying the
; right key, and the character doors when the right character walks up.
OPEN_DOOR:
  LD A,(IX+$05)           ; Bit 3 off: open.
  AND $F7                 ;
  LD (IX+$05),A           ;
  PUSH IX                 ; Now the other side.
  CALL DOOR_OTHER_SIDE    ;
  LD A,(IX+$05)           ; The same there.
  AND $F7                 ;
  LD (IX+$05),A           ;
  POP IX
  RET

; Shut a door, both halves at once
;
; Used by the routines at DOOR_NEEDS_KEY, DOOR_SERF, DOOR_OPEN_OR_SHUT and
; ACG_DOOR.
;
; The opposite of the routine above: set bit 3 on both halves, so the door is
; drawn shut and stays that way. This is what runs when the key is missing or
; the wrong character is standing there -- the door is still drawn, it simply
; does not open.
SHUT_DOOR:
  LD A,(IX+$05)           ; Bit 3 on: shut.
  OR $08                  ;
  LD (IX+$05),A           ;
  PUSH IX                 ; And the far side.
  CALL DOOR_OTHER_SIDE    ;
  LD A,(IX+$05)           ; The same there.
  OR $08                  ;
  LD (IX+$05),A           ;
  POP IX
  RET

; Is this position inside the room?
;
; Used by the routine at MOVE_PLAYER.
;
; Compares a record's position against the room's half-extents at $5E1D, one
; more than the limit on each axis so that the boundary itself counts as
; inside.
WITHIN_ROOM_BOUNDS:
  PUSH DE
  LD B,$00
  LD HL,(ROOM_HALF_WIDTH)
  INC L
  INC H
  LD E,(IX+$03)
  LD D,(IX+$04)
  LD A,E
  SUB $58
  JP P,WITHIN_ROOM_BOUNDS_0
  NEG
WITHIN_ROOM_BOUNDS_0:
  CP L
  JR C,WITHIN_ROOM_BOUNDS_1
  INC B
WITHIN_ROOM_BOUNDS_1:
  LD A,D
  SUB $68
  JP P,WITHIN_ROOM_BOUNDS_2
  NEG
WITHIN_ROOM_BOUNDS_2:
  CP H
  JR C,WITHIN_ROOM_BOUNDS_3
  INC B
WITHIN_ROOM_BOUNDS_3:
  LD A,B
  LD (FIRE_BLOCKED),A
  POP DE
  RET

; Leave an object where the player is standing
;
; Used by the routine at DYING.
;
; Four slots of eight bytes at $EAE8. The first with a zero sprite is taken,
; given sprite $8F, and the seven bytes after it are copied straight out of the
; player's own record -- room, flag, position and all -- so the thing appears
; exactly where the player is. With all four in use the routine simply returns
; and nothing is dropped.
;
; The copy is what makes it cheap: because an object and an actor share the
; same eight-byte header, placing one is one LDIR rather than half a dozen
; assignments.
DROP_OBJECT:
  LD HL,LIVE_DROP_SLOTS   ; Four slots, eight bytes apart.
  LD DE,$0008             ;
  LD B,$04                ;
DROP_OBJECT_0:
  LD A,(HL)               ; A zero sprite means the slot is free.
  AND A                   ;
  JR Z,DROP_OBJECT_1      ;
  ADD HL,DE               ; All four taken, so give up.
  DJNZ DROP_OBJECT_0      ;
  RET                     ;
DROP_OBJECT_1:
  LD A,$45
  LD (PLAYER_MODE),A
  PUSH HL
  LD (HL),$8F             ; The sprite the dropped thing is drawn as.
  EX DE,HL
  INC DE
  LD HL,PLAYER_ROOM       ; Room, flag and position, straight from the player's
  LD BC,$0007             ; record.
  LDIR                    ;
  POP HL
; This entry point is used by the routine at SHOW_END_SCREEN.
PLACE_RECORD:
  PUSH IX
  PUSH HL
  POP IX
  CALL DRAW_THING
  POP IX
  RET

; The gravestone left where the player died
;
; Sprite $8F, and nothing more than a jump into the routine that draws a thing
; and leaves it alone. DROP_OBJECT is what puts one down: on dying, seven bytes
; of the player's record are copied into a free slot and given this sprite, so
; the stone stands exactly where the body fell.
;
; Confirmed live by starving the player -- the first of the four slots came
; back reading 8F 00 68 60 68 45 FF 08, sprite $8F at the player's own
; position.
GRAVESTONE:
  JP DRAW_AT_POSITION

; Advance the elapsed-time clock
;
; Used by the routine at FRAME_TICK_NEXT.
;
; The clock counts up rather than down -- Atic Atac's TIME is how long you have
; been in the castle, not how long is left. Three bytes of BCD at $5E3D, $5E3E
; and $5E3F hold it, and the panel prints them as one digit, then two, a colon,
; then two: 000:09.
;
; Its time base is the ROM's own FRAMES counter, which ticks 50 times a second
; on the interrupt the game leaves enabled. Rather than remember when the last
; second was, it subtracts 50 from FRAMES whenever there are at least 50 there,
; so the remainder carries the fraction of a second forward and nothing drifts.
;
; Confirmed against a running game: with the three bytes reading $00 $00 $09
; the panel showed TIME 000:09.
TICK_CLOCK:
  LD A,(FRAMES)           ; Fewer than fifty frames since the last tick, so
  CP $32                  ; there is nothing to do yet.
  RET C                   ;
  SUB $32                 ; Take a whole second out and leave the remainder for
  LD (FRAMES),A           ; next time.
  LD HL,CLOCK_SECONDS     ; The seconds, the last of the three bytes.
  LD A,(HL)               ; INC then DAA -- adding 1 in BCD, so the digits stay
  INC A                   ; printable.
  DAA                     ;
  LD (HL),A               ;
  CP $60                  ; Sixty, in BCD, is $60.
  JR NZ,TICK_CLOCK_0      ;
  LD (HL),$00             ; Round the seconds and carry into the minutes.
  DEC HL                  ;
  LD A,(HL)
  INC A
  DAA
  LD (HL),A
  CP $60
  JR NZ,TICK_CLOCK_0
  LD (HL),$00
  DEC HL                  ; And the minutes into the hours.
  LD A,(HL)               ;
  INC A                   ;
  DAA                     ;
  AND $0F                 ; Hours are kept to a single digit, which is what
                          ; makes the display 000:09 rather than 00:00:09.
  LD (HL),A
TICK_CLOCK_0:
  LD HL,$40C8
; This entry point is used by the routine at DRAW_SUMMARY.
PRINT_CLOCK:
  CALL PIXEL_TO_SCREEN
  LD DE,CLOCK
  LD B,$02
  CALL DRAW_LOW_DIGIT
  LD DE,CLOCK_SECONDS
  INC HL
  LD B,$01
  JP DRAW_DIGITS

; The A.C.G. door: it opens only for the whole of the A.C.G. key
;
; The handler for the A.C.G. door. It walks the three inventory slots four
; bytes at a time and wants $8C, $8D and $8E in them, in that order -- the
; three pieces of the A.C.G. key, ACG_KEY_PARTS -- and only then opens the door
; (OPEN_DOOR) and behaves as one, with a wider doorway than most. Anything less
; and it is drawn shut (SHUT_DOOR). Through it is room $8E, and reaching that
; ends the game.
ACG_DOOR:
  LD HL,CARRIED_SPRITE
  LD DE,$0004
  LD A,(HL)
  CP $8C
  JR NZ,ACG_DOOR_0
  ADD HL,DE
  LD A,(HL)
  CP $8D
  JR NZ,ACG_DOOR_0
  ADD HL,DE
  LD A,(HL)
  CP $8E
  JR NZ,ACG_DOOR_0
  CALL OPEN_DOOR
  LD BC,$3020
  JP DOORWAY
ACG_DOOR_0:
  CALL SHUT_DOOR
  JP DRAW_DOOR

; Print the three end-of-game figures
;
; Used by the routines at GAME_OVER and SHOW_END_SCREEN.
;
; Three labels and three numbers, stacked at the left of the cleared play area.
; The labels carry their own colour in their first byte and their own
; punctuation: the one for the clock ends with the font's colon glyph, so
; TIME's digits print either side of a colon that was drawn with the word.
;
; It assumes the text font is already selected, which is why GAME_OVER repoints
; $5E01 before calling. Halfway through it switches to the digit-biased copy
; for the numbers.
DRAW_SUMMARY:
  CALL COUNT_ROOMS_EXPLORED ; Work out the proportion of the castle seen before
                            ; printing it.
  LD HL,$4040             ; "TIME", with the colon.
  LD DE,END_LABELS        ;
  CALL PRINT_STRING       ;
  LD HL,$5040
  LD DE,SCORE_LABEL
  CALL PRINT_STRING
  LD HL,$6040
  LD DE,TIME_LABEL
  CALL PRINT_STRING
  LD HL,FONT_DIGITS       ; From here on the numbers, so bias the tile source
  LD (TILE_SOURCE),HL     ; to the digits.
  LD HL,$4080             ; The clock, then the score.
  CALL PRINT_CLOCK        ;
  LD HL,$5080
  CALL DRAW_SCORE_AT
  LD HL,$6080             ; And the rooms-explored figure.
  CALL PIXEL_TO_SCREEN    ; One byte, two digits.
  LD DE,ROOMS_EXPLORED    ;
  LD B,$01                ;
  JP DRAW_DIGITS

; The three words on the end-of-game screen
;
; Sixteen bytes each: a colour, then the word padded out with spaces to the
; width of the field, with bit 7 set on the last one. PRINT_END_FIGURES draws
; the numbers into the gap the padding leaves.
END_LABELS:
  DEFM "ETIME       #  ",$A0
SCORE_LABEL:
  DEFM "ESCORE         ",$A0
TIME_LABEL:
  DEFM "E$             ",$A0

; Mark a room as seen, by writing the instruction that does it
;
; Used by the routine at ENTER_ROOM.
;
; Sets one bit in the 19-byte map at $5E40, one bit per room, 152 rooms in all.
; The bit number is not known until run time, and rather than shift a mask into
; place the routine assembles the instruction it needs and stores it over the
; one below.
;
; SET b,(HL) is $CB followed by $C6 + b * 8, so ORing the room's low three bits
; (already shifted up by the three RLCAs) with $C6 gives exactly the operand
; byte required, and it is written into SET_BIT_OP+1 -- the second byte of the
; SET at SET_BIT_OP.
;
; Checked by calling it directly with a series of room numbers and reading both
; the map and the patched bytes back: $2A set bit 42 and left SET 2,(HL) in
; place, $07 set bit 7 as SET 7, $08 set bit 8 as SET 0, $4B set bit 75 as SET
; 3, and $97 set bit 151 as SET 7 -- the last bit the map has room for.
;
; A The room number
MARK_ROOM_VISITED:
  LD C,A                  ; Room / 8 -- which byte of the map.
  SRL C                   ;
  SRL C                   ;
  SRL C                   ;
  LD B,$00
  LD HL,ROOMS_SEEN        ; The map itself. It sits below ENTRY, so it is not
  ADD HL,BC               ; part of this disassembly.
  RLCA                    ; Room AND 7, shifted into the bit-number field of a
  RLCA                    ; SET opcode.
  RLCA                    ;
  AND $38                 ;
  OR $C6                  ;
  LD (SET_BIT_OP+$0001),A ; Overwrite the operand of the instruction on the
                          ; next line.
SET_BIT_OP:
  SET 0,(HL)              ; Reads as SET 0 here, but by the time it runs it is
                          ; SET (room AND 7).
  RET

; Work out how much of the castle has been seen
;
; Used by the routine at DRAW_SUMMARY.
;
; Counts the bits set in the room map and turns the total into a two-digit BCD
; figure at $5E54. It is not shown while playing -- DRAW_SUMMARY prints it on
; the GAME OVER screen, as the last of the three figures under the heading.
; Every third room seen is worth 2, and 1 is added at the end, so the value is
; (rooms / 3) * 2 + 1.
;
; Measured by setting the map by hand and running it: 6, 7 and 8 rooms all give
; $05, 11 gives $07, 144 gives $97, and none at all gives $01.
;
; The map holds 152 bits but the castle does not have 152 rooms. ROOM_TABLE has
; 151 entries, and of those the last two are black -- colour $00, so nothing
; they draw can be seen. That leaves 149 real rooms, 0 to 148, and (149 / 3) *
; 2 + 1 is exactly 99. The figure is scaled so that seeing everything reads 99
; and it never has to carry into a third digit, which a single byte of BCD
; could not hold: setting all 152 bits by hand does overflow it, and $5E54
; comes back $01, but no game can get there.
COUNT_ROOMS_EXPLORED:
  LD HL,ROOMS_SEEN        ; 19 bytes, 8 bits each.
  LD BC,$0813             ;
  LD D,$03
  XOR A
COUNT_ROOMS_EXPLORED_0:
  PUSH BC
  LD E,(HL)
  INC HL
COUNT_ROOMS_EXPLORED_1:
  RR E                         ; Walk the bits of one byte.
  JR NC,COUNT_ROOMS_EXPLORED_2 ;
  DEC D                        ; Two per three rooms, in BCD -- hence the DAA.
  JR NZ,COUNT_ROOMS_EXPLORED_2 ;
  LD D,$03                     ;
  ADD A,$02                    ;
  DAA                     ; Keeps the running total in BCD so it can be printed
                          ; a digit at a time.
COUNT_ROOMS_EXPLORED_2:
  DJNZ COUNT_ROOMS_EXPLORED_1
  POP BC
  DEC C
  JR NZ,COUNT_ROOMS_EXPLORED_0
  INC A                   ; The finished figure, read back by the status panel.
  LD (ROOMS_EXPLORED),A   ;
  RET

; Draw the screen shown when a game ends
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Draws the player, points the tile source back at the text font and prints a
; line at $2040 from a string at END_MESSAGES -- the same shape as GAME_OVER,
; for a different ending.
SHOW_END_SCREEN:
  LD HL,PLAYER
  CALL PLACE_RECORD
  LD HL,TEXT_FONT-$0100   ; The text font, less $100: TEXT_FONT-$100
  LD (TILE_SOURCE),HL
  LD HL,$2040
  LD DE,END_MESSAGES
  CALL PRINT_STRING
  LD HL,$3040
  LD DE,ESCAPED_TEXT
  CALL PRINT_STRING
  CALL DRAW_SUMMARY
  JP END_DELAY

; What it says when you escape
;
; Two strings, each a colour byte then the text, with bit 7 on the last
; character. The first is misspelt: the bytes read CONGRATULATION and then $D4,
; which is "T" with the end marker set, so the screen says CONGRATULATIONT.
; Drawing the screen confirms it -- this is what the game shipped with, not a
; mistake in reading it.
END_MESSAGES:
  DEFM "GCONGRATULATION",$D4
ESCAPED_TEXT:
  DEFM "GYOU HAVE ESCAPE",$C4

; Fall through a trapdoor
;
; Used by the routine at FLASH_AND_RASP.
;
; Reached only from the trapdoor's handler, TRAPDOOR, and only while the player
; is standing on it -- PLAYER_AT_DOOR with a tolerance of $1818. It draws room
; $96, which is not a room but the trapdoor fall's twelve nested rectangles
; (see the room types), then runs 128 times: each pass beeps a note whose pitch
; comes from the frame counter at $5C78 and walks down as the loop counts up,
; picks black or white from bit 3 of it, writes that into two cells of the
; attribute file and floods the rest outwards with SPIRAL_FILL. It ends in
; ENTER_ROOM, which takes the player to the trapdoor's other half -- the
; landing in the room below.
;
; Never reached in any of the recorded playthroughs, which is why the code map
; left it as data until it was disassembled by hand.
TRAPDOOR_FALL:
  LD BC,$1818
  CALL PLAYER_AT_DOOR
  JP NC,DRAW_DOOR
  CALL CLEAR_PLAY_AREA
  LD A,$96
  PUSH IX
  CALL DRAW_ROOM_A
  POP IX
  LD B,$80
TRAPDOOR_FALL_0:
  LD A,(FRAMES)           ; The frame counter, so the pitch follows real time
                          ; rather than a count of its own.
  LD C,A
TRAPDOOR_FALL_1:
  PUSH BC
  LD A,B
  CPL
  LD B,A
  CALL BEEP               ; One cycle of BEEP with B complemented, which is
                          ; what walks the pitch down as the loop counts up.
  POP BC
  LD A,(FRAMES)
  CP C
  JR Z,TRAPDOOR_FALL_1
  AND $07                 ; Bit 3 of the counter picks $00 or $47 -- black or
  LD A,$00                ; white.
  JR NZ,TRAPDOOR_FALL_2   ;
  LD A,$47                ;
TRAPDOOR_FALL_2:
  LD L,A
  LD H,A
  LD ($596B),HL
  LD ($598B),HL
  PUSH BC
  CALL SPIRAL_FILL        ; Flood the change outwards from the middle.
  POP BC
  DJNZ TRAPDOOR_FALL_0
  JP ENTER_ROOM           ; Straight back into the main loop; there is no
                          ; return.
SPIRAL_FILL:
  LD BC,$170B
  LD HL,$5AE0             ; $5AE0 is the last row of the attribute file; the
  LD DE,$0020             ; spiral is walked backwards from there.
TRAPDOOR_FALL_3:
  PUSH HL
  AND A
  SBC HL,DE
  INC L
  LD A,(HL)
  POP HL
  PUSH BC
TRAPDOOR_FALL_4:
  LD (HL),A
  INC L
  DJNZ TRAPDOOR_FALL_4
  POP BC
  PUSH BC
TRAPDOOR_FALL_5:
  LD (HL),A
  AND A
  SBC HL,DE
  DJNZ TRAPDOOR_FALL_5
  POP BC
  PUSH BC
TRAPDOOR_FALL_6:
  LD (HL),A
  DEC L
  DJNZ TRAPDOOR_FALL_6
  POP BC
  PUSH BC
TRAPDOOR_FALL_7:
  LD (HL),A
  ADD HL,DE
  DJNZ TRAPDOOR_FALL_7
  LD (HL),A
  AND A
  SBC HL,DE
  INC L
  POP BC
  DEC B                   ; Two rows and one column shorter each time round.
  DEC B                   ;
  DEC C                   ;
  JR NZ,TRAPDOOR_FALL_3
  RET

; The corners of shape $0C
;
; 48 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_0C:
  DEFB $5C,$63
  DEFB $63,$63
  DEFB $63,$5C
  DEFB $5C,$5C
  DEFB $54,$6B
  DEFB $6B,$6B
  DEFB $6B,$54
  DEFB $54,$54
  DEFB $4C,$73
  DEFB $73,$73
  DEFB $73,$4C
  DEFB $4C,$4C
  DEFB $44,$7B
  DEFB $7B,$7B
  DEFB $7B,$44
  DEFB $44,$44
  DEFB $3C,$83
  DEFB $83,$83
  DEFB $83,$3C
  DEFB $3C,$3C
  DEFB $34,$8B
  DEFB $8B,$8B
  DEFB $8B,$34
  DEFB $34,$34
  DEFB $2C,$93
  DEFB $93,$93
  DEFB $93,$2C
  DEFB $2C,$2C
  DEFB $24,$9B
  DEFB $9B,$9B
  DEFB $9B,$24
  DEFB $24,$24
  DEFB $1C,$A3
  DEFB $A3,$A3
  DEFB $A3,$1C
  DEFB $1C,$1C
  DEFB $14,$AB
  DEFB $AB,$AB
  DEFB $AB,$14
  DEFB $14,$14
  DEFB $0C,$B3
  DEFB $B3,$B3
  DEFB $B3,$0C
  DEFB $0C,$0C
  DEFB $04,$BB
  DEFB $BB,$BB
  DEFB $BB,$04
  DEFB $04,$04

; Which corners to join up, for shape $0C
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
SHAPE_EDGES_0C:
  DEFB $00,$01,$03,$FF,$02,$01,$03,$FF
  DEFB $04,$05,$07,$FF,$06,$05,$07,$FF
  DEFB $08,$09,$0B,$FF,$0A,$09,$0B,$FF
  DEFB $0C,$0D,$0F,$FF,$0E,$0D,$0F,$FF
  DEFB $10,$11,$13,$FF,$12,$11,$13,$FF
  DEFB $14,$15,$17,$FF,$16,$15,$17,$FF
  DEFB $18,$19,$1B,$FF,$1A,$19,$1B,$FF
  DEFB $1C,$1D,$1F,$FF,$1E,$1D,$1F,$FF
  DEFB $20,$21,$23,$FF,$22,$21,$23,$FF
  DEFB $24,$25,$27,$FF,$26,$25,$27,$FF
  DEFB $28,$29,$2B,$FF,$2A,$29,$2B,$FF
  DEFB $2C,$2D,$2F,$FF,$2E,$2D,$2F,$FF
  DEFB $FF

; Turn a drawing mode into a table index
;
; Used by the routine at ENTER_ROOM.
;
; Rotates +$05 down and masks to $06, which turns the top bits of the drawing
; mode into an even number -- an index into a table of word-sized entries.
MODE_TO_INDEX:
  LD A,(IX+$05)
  RLCA
  RLCA
  RLCA
  AND $06
  LD C,A
  LD B,$00
  LD HL,DRIFT_OFFSETS
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD (PLAYER_DX),A
  LD A,(HL)
  LD (PLAYER_DY),A
  RET

; Eight small steps
;
; $00 $20 $E0 $00 $00 $E0 $20 $00 -- read by the LD HL at MODE_TO_INDEX+11. As
; signed bytes they are 0, +32, -32, 0, 0, -32, +32, 0: a pair of nudges one
; way and then the other, which is what the mushroom's wander looks like on
; screen.
DRIFT_OFFSETS:
  DEFB $00,$20,$E0,$00,$00,$E0,$20,$00

; The mushroom that drains you
;
; Sprite $A1. Standing on it is not fatal at once -- it takes a unit of life
; force per pass and loops, so the drain continues for as long as the player
; stays on it and stops the moment they step off. Reaching zero there kills as
; surely as anything else.
;
; When nobody is on it, it cycles its colour rather than its shape: the low two
; bits of a counter index four attribute bytes at MUSHROOM_COLOURS, and only
; the drawing mode in +$05 changes. The sprite itself never moves.
;
; IX The mushroom
MUSHROOM:
  CALL ACTOR_TO_WORKSPACE ; Is the player standing on it?
  CALL NEAR_PLAYER        ;
  JR C,MUSHROOM_DRAIN     ; Yes -- start draining.
; This entry point is used by the routine at MUSHROOM_DRAIN.
MUSHROOM_COLOUR_STEP:
  LD A,(TICKS)            ; Otherwise advance the colour, every fourth frame.
  CPL                     ;
  AND $03                 ;
  JR NZ,MUSHROOM_0        ;
  INC (IX+$06)            ;
MUSHROOM_0:
  LD A,(IX+$06)           ; Four colours, cycled by the low two bits.
  AND $03                 ;
  LD C,A                  ;
  LD B,$00                ;
  LD HL,MUSHROOM_COLOURS  ;
  ADD HL,BC
  LD A,(HL)
  LD (IX+$05),A           ; Only the drawing mode changes; the shape is the
  JP DRAW_AT_POSITION     ; same every time.

; Drain a unit of life force and go round again
;
; Used by the routine at MUSHROOM.
MUSHROOM_DRAIN:
  LD A,(FOOD_LEVEL)       ; A unit of life force, every pass round the loop.
  DEC A                   ;
  LD (FOOD_LEVEL),A       ;
  JP Z,MUSHROOM_KILLED_PLAYER ; It has run out: die.
  CALL DRAW_FOOD          ; Otherwise redraw the roast and make a noise about
  CALL PLAY_SOUND         ; it...
  JP MUSHROOM_COLOUR_STEP ; ...and go round again while the player is still on
                          ; it.

; The mushroom's four colours
;
; Indexed by the low two bits of its counter, and written straight into +$05 as
; the drawing mode.
MUSHROOM_COLOURS:
  DEFB $42,$43,$46,$43

; Rub the mushroom out and take the life
;
; Used by the routine at MUSHROOM_DRAIN.
;
; Erases it, frees its slot, and jumps into LOSE_LIFE. The mushroom is consumed
; by killing you.
MUSHROOM_KILLED_PLAYER:
  CALL ERASE_THING
  LD (IX+$00),$00
  JP LOSE_LIFE

; Put three of the keys, and the mummy, in rooms chosen for this game
;
; Used by the routine at START_GAME.
;
; Writes into INITIAL_STATE before START_GAME copies it: the rooms of
; GREEN_KEY, RED_KEY and CYAN_KEY, each one of eight from RANDOM_ROOMS_ONE,
; RANDOM_ROOMS_TWO and RANDOM_ROOMS_THREE, chosen by the frame counter mixed
; with the running values at $5E12 and $5E13. The mummy goes into the same room
; as the red key. The yellow key's room is not touched, and neither is anything
; else here -- so these are the things that are somewhere different in every
; game.
PLACE_KEYS:
  LD A,(FRAMES)
  LD HL,RANDOM_ROOMS_ONE
  CALL TABLE_LOOKUP_3BIT
  LD (GREEN_KEY+$0001),A  ; GREEN_KEY+1: the green key's room
  LD A,(FRAMES)
  LD C,A
  LD A,(TICKS)
  ADD A,C
  LD HL,RANDOM_ROOMS_TWO
  CALL TABLE_LOOKUP_3BIT
  LD (RED_KEY+$0001),A    ; RED_KEY+1: the red key's room...
  LD (MUMMY+$0001),A      ; ...and MUMMY+1, the mummy's
  LD A,(FRAMES_HIGH)
  LD C,A
  LD A,(TICKS_HIGH)
  ADD A,C
  LD HL,RANDOM_ROOMS_THREE
  CALL TABLE_LOOKUP_3BIT
  LD (CYAN_KEY+$0001),A   ; CYAN_KEY+1: the cyan key's room
  RET

; Pick one of eight from a table
;
; Used by the routine at PLACE_KEYS.
;
; Masks to three bits, adds to HL, reads the byte. Small enough to inline, kept
; as a routine because several callers want exactly this.
TABLE_LOOKUP_3BIT:
  AND $07
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  RET

; Eight rooms to choose between
;
; Read by the helper at TABLE_LOOKUP_3BIT, which takes A AND $07 as the index.
; The result is written to GREEN_KEY's room byte -- inside INITIAL_STATE again,
; so this is another thing placed differently each game.
RANDOM_ROOMS_ONE:
  DEFB $05,$06,$07,$6D,$25,$24,$23,$22

; Eight more
;
; Chosen with the frame counter added to $5E12, and written to two places at
; once, RED_KEY's room byte and MUMMY's.
RANDOM_ROOMS_TWO:
  DEFB $17,$13,$09,$0D,$89,$87,$80,$85

; Eight more again
;
; Chosen with the other half of the frame counter added to $5E13, and written
; to CYAN_KEY's room byte.
RANDOM_ROOMS_THREE:
  DEFB $53,$8F,$41,$94,$33,$91,$39,$4C

; Step a cursor on by one record
;
; Used by the routine at MAIN_LOOP_MONSTERS.
;
; Adds eight to the pointer kept at $5E55, but only on frames where the low
; bits of $5E12 and $5E13 are both clear -- so it creeps through a table a
; record at a time over many frames rather than sweeping it in one go.
ADVANCE_CURSOR:
  LD A,(TICKS)
  LD C,A
  LD A,(TICKS_HIGH)
  AND $01
  OR C
  RET NZ
  LD HL,(CURSOR)
  LD DE,$0008
  ADD HL,DE
  LD (CURSOR),HL
  PUSH HL
  POP IX
  LD DE,LIVE_MUSHROOMS
  AND A
  SBC HL,DE
  JR NC,ADVANCE_CURSOR_0
  LD A,(PLAYER_ROOM)
  CP (IX+$01)
  RET Z
  LD A,(IX+$00)
  AND A
  RET NZ
  LD A,(FRAMES)
  AND $07
  ADD A,$50
  LD (IX+$00),A
  RET
ADVANCE_CURSOR_0:
  LD HL,LIVE_FOOD
  LD (CURSOR),HL
  RET

; Draw a sprite, choosing the routine from the drawing mode
;
; Used by the routine at DOOR.
;
; Neither this nor DRAW_SPRITE_COLOURS does any drawing. Each loads the address
; of its own table of eight routines and falls into the tail of DISPATCH_ACTOR,
; which indexes the table and jumps through the JP (HL) the tape left at $5CB0
; -- the same machinery that picks an actor's handler, reused for picking how a
; sprite gets put on the screen.
;
; The mode is the top three bits of the actor's +$05, so the low five bits are
; free for other flags -- PLAYER_AT_DOOR reads bit 6 of the same byte as a
; door's facing.
;
; C Sprite number
; B Drawing mode in its top three bits
; DE Where to draw, as pixel coordinates
DRAW_SPRITE_PIXELS:
  LD HL,PIXEL_DRAWERS     ; One table of eight...
; This entry point is used by the routine at DRAW_SPRITE_COLOURS.
DRAW_WITH_MODE:
  PUSH BC
  LD A,B                  ; ...indexed by the top three bits of B.
  RLCA                    ;
  RLCA                    ;
  RLCA                    ;
  AND $07                 ;
  LD C,A                  ;
  JP DISPATCH_TYPE_C      ; Into the dispatcher's tail, which does the lookup
                          ; and the jump.

; Eight ways of putting a sprite's pixels on the screen
;
; Chosen by DRAW_SPRITE_PIXELS from the drawing mode.
PIXEL_DRAWERS:
  DEFW BLIT_SPRITE
  DEFW BLIT_SPRITE_MIRRORED
  DEFW DRAW_PIXELS_2
  DEFW DRAW_PIXELS_3
  DEFW DRAW_PIXELS_4
  DEFW BLIT_SPRITE_FLIPPED
  DEFW DRAW_PIXELS_6
  DEFW DRAW_PIXELS_7

; Draw a sprite from the other set of eight routines
;
; Used by the routine at DOOR.
;
; As DRAW_SPRITE_PIXELS, but pointing at COLOUR_DRAWERS. Actor handlers call
; this one to put a sprite down and the masked one to take it away again, a row
; above -- which is why DOOR does the two with the same coordinates but a DEC D
; between them.
DRAW_SPRITE_COLOURS:
  LD HL,COLOUR_DRAWERS    ; The other table.
  JR DRAW_WITH_MODE

; Eight ways of putting a sprite's colours on the screen
;
; Chosen by DRAW_SPRITE_COLOURS from the drawing mode.
COLOUR_DRAWERS:
  DEFW DRAW_COLOURS_0
  DEFW DRAW_COLOURS_1
  DEFW DRAW_COLOURS_2
  DEFW DRAW_COLOURS_3
  DEFW DRAW_COLOURS_4
  DEFW DRAW_COLOURS_5
  DEFW DRAW_COLOURS_6
  DEFW DRAW_COLOURS_7

; Look up a sprite's bitmap and work out where it goes
;
; Used by the routines at BLIT_SPRITE, BLIT_SPRITE_MIRRORED, DRAW_PIXELS_2,
; DRAW_PIXELS_3, DRAW_PIXELS_4, BLIT_SPRITE_FLIPPED, DRAW_PIXELS_6 and
; DRAW_PIXELS_7.
;
; Sprite numbers are 1-based, so the number is decremented before being doubled
; into the table of addresses at FURNITURE_SPRITES. The first two bytes of the
; data are its size, and the pointer is left just past them.
;
; C Sprite number
; DE On exit, the first row of bitmap data
; B On exit, width in bytes
; C On exit, height in rows
; HL On exit, where the top-left corner lands in the display file
FETCH_SPRITE:
  LD HL,FURNITURE_SPRITES ; The table of sprite addresses.
  DEC C                   ; Numbered from 1, two bytes each.
  LD B,$00                ;
  SLA C                   ;
  RL B                    ;
  ADD HL,BC
  LD A,(HL)               ; The address of the bitmap itself.
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  EX DE,HL                ;
  CALL PIXEL_TO_SCREEN    ; Turn the pixel coordinates into a display file
                          ; address.
  LD A,(DE)               ; Width then height, and step past them to the first
  LD B,A                  ; row.
  INC DE                  ;
  LD A,(DE)               ;
  LD C,A                  ;
  INC DE                  ;
  RET
; Watched live, the sizes coming back are 4 by 24 for the characters and 6 by 5
; or 6 by 6 for smaller pieces -- so width really is in bytes, eight pixels at
; a time.
;
; FURNITURE_SPRITES is not a table of its own. It is the 161st entry of
; SPRITE_TABLE, and this routine does the same arithmetic SPRITE_ADDRESS does,
; so asking it for sprite 1 fetches entry 161. The base is what says which
; family of sprites is wanted. An earlier reading of this routine took the 39
; entries between FURNITURE_SPRITES and FURNITURE_COLOURS for the whole table
; and concluded it held the knight, the wizard and seven frames of the serf;
; that was an accident of where the next base happens to fall.

; Look up a sprite's colours
;
; Used by the routines at DRAW_COLOURS_0, DRAW_COLOURS_1, DRAW_COLOURS_2,
; DRAW_COLOURS_3, DRAW_COLOURS_4, DRAW_COLOURS_5, DRAW_COLOURS_6 and
; DRAW_COLOURS_7.
;
; The same routine as FETCH_SPRITE but based at FURNITURE_COLOURS -- the 200th
; entry of SPRITE_TABLE rather than the 161st -- and ending in PIXEL_TO_ATTR
; rather than PIXEL_TO_SCREEN, so what it fetches is a sprite's colours rather
; than its shape.
;
; C Sprite number
FETCH_SPRITE_ATTRS:
  LD HL,FURNITURE_COLOURS ; The colour tables, one per sprite.
  DEC C
  LD B,$00
  SLA C
  RL B
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  EX DE,HL
  CALL PIXEL_TO_ATTR      ; The attribute address rather than the display one.
  LD A,(DE)
  LD B,A
  INC DE
  LD A,(DE)
  LD C,A
  INC DE
  RET

; Copy a sprite to the screen, combining it however the caller asked
;
; The inner loop of everything that moves. A sprite is width bytes by height
; rows, and the row-to-row step is left to SCREEN_ROW_UP rather than being
; computed here, because the display file's thirds make it anything but a
; simple addition.
;
; It works upwards. The first row of a sprite's data is its bottom row, so an
; actor's +$03 and +$04 are the point its feet stand on rather than a top-left
; corner. Rendering the data top-down produces nothing recognisable; reversed,
; it comes out as a picture.
;
; How each byte meets what is already on the screen is not decided by a branch.
; SPRITE_COMBINE_OPCODE hands back an opcode and it is written over the NOP in
; the middle of the loop, so the same six instructions become a plain copy, an
; OR, an XOR or an AND with nothing tested per byte. Read live during play the
; byte is $00 -- a NOP, so a plain copy.
BLIT_SPRITE:
  POP BC
  CALL SPRITE_COMBINE_OPCODE ; Fetch the combining opcode and write it into the
  LD (BLIT_SPRITE_OP),A      ; loop below.
  CALL FETCH_SPRITE       ; Bitmap, size and destination.
BLIT_SPRITE_0:
  PUSH BC
  PUSH HL
BLIT_SPRITE_1:
  LD A,(DE)               ; One byte of the sprite.
  INC DE                  ;
BLIT_SPRITE_OP:
  NOP                     ; Assembled at run time: NOP, OR (HL), XOR (HL) or
                          ; AND (HL).
  LD (HL),A               ; Store it and move one cell right, width times.
  INC L                   ;
  DJNZ BLIT_SPRITE_1      ;
  POP HL
  CALL SCREEN_ROW_UP      ; Up one pixel row -- see SCREEN_ROW_UP. Sprites are
                          ; stored and drawn from the bottom.
  POP BC                  ; Repeat for every row.
  DEC C                   ;
  JR NZ,BLIT_SPRITE_0     ;
  RET

; Copy a sprite to the screen, back to front
;
; BLIT_SPRITE with two changes: the row is walked with DEC DE rather than INC
; DE, and every byte goes through REVERSE_BITS on the way out. Between them
; those mirror the sprite horizontally without a second copy of the data.
;
; It patches its own combining instruction the same way BLIT_SPRITE does --
; SPRITE_COMBINE_OPCODE hands back an opcode and it is written over the NOP in
; the loop.
BLIT_SPRITE_MIRRORED:
  POP BC                     ; The combining opcode, into the loop below.
  CALL SPRITE_COMBINE_OPCODE ;
  LD (BLIT_MIRRORED_OP),A    ;
  CALL FETCH_SPRITE
BLIT_SPRITE_MIRRORED_0:
  PUSH BC                 ; Start of a row.
  PUSH HL                 ;
  CALL NEXT_SPRITE_ROW    ;
BLIT_SPRITE_MIRRORED_1:
  DEC DE                  ; Backwards through the row, reversing each byte.
  LD A,(DE)               ;
  CALL REVERSE_BITS       ;
BLIT_MIRRORED_OP:
  NOP                     ; Assembled at run time: NOP, OR, XOR or AND.
  LD (HL),A
  INC L
  DJNZ BLIT_SPRITE_MIRRORED_1
  POP HL
  CALL SCREEN_ROW_UP
  POP BC
  CALL NEXT_SPRITE_ROW
  DEC C
  JR NZ,BLIT_SPRITE_MIRRORED_0
  RET

; Drawing mode 2: a sprite's pixels, the right way up
;
; Entry 2 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by
; row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the
; same as every other routine in the two tables.
DRAW_PIXELS_2:
  POP BC
  CALL SPRITE_COMBINE_OPCODE
  LD (DRAW_PIXELS_2_OP),A
  CALL FETCH_SPRITE
  LD A,B
  EXX
  LD L,$01
  LD B,A
  EXX
  CALL NEXT_SPRITE_ROW
  DEC DE
DRAW_PIXELS_2_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_PIXELS_2_1:
  LD A,(DE)
  EXX
  AND L
  JR Z,DRAW_PIXELS_2_2
  SCF
DRAW_PIXELS_2_2:
  RL H
  EXX
  CALL NEXT_SPRITE_ROW
  DEC C
  LD A,C
  AND $07
  JR NZ,DRAW_PIXELS_2_1
  EXX
  LD A,H
  EXX
DRAW_PIXELS_2_OP:
  NOP
  LD (HL),A
  INC L
  LD A,C
  AND A
  JR NZ,DRAW_PIXELS_2_1
  POP HL
  CALL SCREEN_ROW_UP
  POP DE
  POP BC
  EXX
  RLC L
  EXX
  JR NC,DRAW_PIXELS_2_0
  EXX
  DEC B
  EXX
  RET Z
  DEC DE
  JR DRAW_PIXELS_2_0

; Drawing mode 3: a sprite's pixels, the right way up
;
; Entry 3 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by
; row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the
; same as every other routine in the two tables.
DRAW_PIXELS_3:
  POP BC
  CALL SPRITE_COMBINE_OPCODE
  LD (DRAW_PIXELS_3_OP),A
  CALL FETCH_SPRITE
  LD A,B
  EXX
  LD B,A
  LD L,$80
  EXX
DRAW_PIXELS_3_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_PIXELS_3_1:
  LD A,(DE)
  EXX
  AND L
  JR Z,DRAW_PIXELS_3_2
  SCF
DRAW_PIXELS_3_2:
  RL H
  EXX
  CALL NEXT_SPRITE_ROW
  DEC C
  LD A,C
  AND $07
  JR NZ,DRAW_PIXELS_3_1
  EXX
  LD A,H
  EXX
DRAW_PIXELS_3_OP:
  NOP
  LD (HL),A
  INC L
  LD A,C
  AND A
  JR NZ,DRAW_PIXELS_3_1
  POP HL
  CALL SCREEN_ROW_UP
  POP DE
  POP BC
  EXX
  RRC L
  EXX
  JR NC,DRAW_PIXELS_3_0
  EXX
  DEC B
  EXX
  RET Z
  INC DE
  JR DRAW_PIXELS_3_0

; Turn a byte back to front
;
; Used by the routines at BLIT_SPRITE_MIRRORED and BLIT_SPRITE_FLIPPED.
;
; Eight rotations: each one shifts a bit off the top of A into the carry and
; back into the bottom of C, so C ends up holding A's bits in the opposite
; order. That is a sprite byte mirrored, and mirroring every byte of a row
; while reading the row's bytes backwards mirrors the whole sprite.
;
; It is what saves the game from storing anything twice. A creature facing left
; and the same creature facing right are one set of bytes and a different
; drawing routine.
;
; A The byte
; A On exit, the same bits in reverse
REVERSE_BITS:
  PUSH BC                 ; Eight bits to move.
  LD B,$08                ;
REVERSE_BITS_0:
  RLA                     ; Off the top of A, into the bottom of C.
  RR C                    ;
  DJNZ REVERSE_BITS_0     ;
  LD A,C                  ; C now holds it reversed.
  POP BC                  ;
  RET                     ;

; Step the sprite pointer on by one row
;
; Used by the routines at BLIT_SPRITE_MIRRORED, DRAW_PIXELS_2, DRAW_PIXELS_3,
; BLIT_SPRITE_FLIPPED, DRAW_PIXELS_6, DRAW_COLOURS_1, DRAW_COLOURS_2,
; DRAW_COLOURS_3, DRAW_COLOURS_5 and DRAW_COLOURS_6.
;
; DE += B, where B is the width in bytes. The counterpart at
; PREVIOUS_SPRITE_ROW subtracts instead, for the routines that read a sprite
; from the bottom up.
NEXT_SPRITE_ROW:
  LD A,B
  ADD A,E
  LD E,A
  LD A,D
  ADC A,$00
  LD D,A
  RET

; Step the sprite pointer back one row
;
; Used by the routines at DRAW_PIXELS_4, DRAW_PIXELS_6, DRAW_PIXELS_7,
; DRAW_COLOURS_4, DRAW_COLOURS_6 and DRAW_COLOURS_7.
;
; DE -= B. The mirror of NEXT_SPRITE_ROW, for the drawing modes that read a
; sprite from the bottom up.
PREVIOUS_SPRITE_ROW:
  LD A,E
  SUB B
  LD E,A
  LD A,D
  SBC A,$00
  LD D,A
  RET

; Multiply DE by A
;
; Used by the routines at DRAW_FOOD and START_AT_LAST_ROW.
;
; Shift and add, eight times: the only multiply the game has, and the Z80's
; excuse for not having one. START_AT_LAST_ROW uses it to find the bottom of a
; sprite, and DRAW_ROOM to index the six-byte shape entries.
MULTIPLY:
  LD HL,$0000
  LD B,$08
MULTIPLY_0:
  ADD HL,HL
  RLCA
  JR NC,MULTIPLY_1
  ADD HL,DE
MULTIPLY_1:
  DJNZ MULTIPLY_0
  RET

; Point at the bottom row of a sprite
;
; Used by the routines at DRAW_PIXELS_4, BLIT_SPRITE_FLIPPED, DRAW_PIXELS_6,
; DRAW_PIXELS_7, DRAW_COLOURS_4, DRAW_COLOURS_5, DRAW_COLOURS_6 and
; DRAW_COLOURS_7.
;
; Multiplies the width by the height less one and adds it to the data pointer,
; so drawing can start from the far end. Called by every drawing routine whose
; mode number has bit 2 set -- which is how the eight modes divide: the low two
; bits choose the horizontal treatment and bit 2 turns the sprite over.
;
; Checking all sixteen routines in the two tables bears that out exactly. Modes
; 0 to 3 leave the pointer where it is; modes 4 to 7 all begin by calling this.
START_AT_LAST_ROW:
  PUSH HL
  PUSH DE
  LD A,B
  LD E,C
  DEC E
  LD D,$00
  PUSH BC
  CALL MULTIPLY
  POP BC
  POP DE
  ADD HL,DE
  EX DE,HL
  POP HL
  RET

; Drawing mode 4: a sprite's pixels, upside down
;
; Entry 4 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by
; row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the
; same as every other routine in the two tables.
DRAW_PIXELS_4:
  POP BC
  CALL SPRITE_COMBINE_OPCODE
  LD (DRAW_PIXELS_4_OP),A
  CALL FETCH_SPRITE
  CALL START_AT_LAST_ROW
DRAW_PIXELS_4_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_PIXELS_4_1:
  LD A,(DE)
  INC DE
DRAW_PIXELS_4_OP:
  NOP
  LD (HL),A
  INC L
  DJNZ DRAW_PIXELS_4_1
  POP HL
  CALL SCREEN_ROW_UP
  POP DE
  POP BC
  CALL PREVIOUS_SPRITE_ROW
  DEC C
  JR NZ,DRAW_PIXELS_4_0
  RET

; Copy a sprite mirrored and upside down
;
; Mirrored like BLIT_SPRITE_MIRRORED, and turned over as well: the call to
; START_AT_LAST_ROW moves the data pointer to the last row before anything is
; drawn, so the rows come out in the opposite order.
;
; This is why there are eight drawing routines in each family rather than one.
; Four are the four orientations a sprite can be put on the screen in -- as
; stored, mirrored, upside down, or both -- and the drawing mode in the top
; three bits of an actor's +$05 picks between them. A creature that walks in
; four directions is one set of bytes.
BLIT_SPRITE_FLIPPED:
  POP BC                     ; The combining opcode.
  CALL SPRITE_COMBINE_OPCODE ;
  LD (BLIT_FLIPPED_OP),A     ;
  CALL FETCH_SPRITE
  CALL START_AT_LAST_ROW  ; Move to the last row: this one draws bottom to top.
  CALL NEXT_SPRITE_ROW
BLIT_SPRITE_FLIPPED_0:
  PUSH BC
  PUSH HL
BLIT_SPRITE_FLIPPED_1:
  DEC DE
  LD A,(DE)
  CALL REVERSE_BITS
BLIT_FLIPPED_OP:
  NOP
  LD (HL),A
  INC L
  DJNZ BLIT_SPRITE_FLIPPED_1
  POP HL
  CALL SCREEN_ROW_UP
  POP BC
  DEC C
  JR NZ,BLIT_SPRITE_FLIPPED_0
  RET

; Drawing mode 6: a sprite's pixels, upside down
;
; Entry 6 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by
; row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the
; same as every other routine in the two tables.
DRAW_PIXELS_6:
  POP BC
  CALL SPRITE_COMBINE_OPCODE
  LD (DRAW_PIXELS_6_OP),A
  CALL FETCH_SPRITE
  LD A,B
  EXX
  LD B,A
  LD L,$01
  EXX
  CALL NEXT_SPRITE_ROW
  DEC DE
  CALL START_AT_LAST_ROW
DRAW_PIXELS_6_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_PIXELS_6_1:
  LD A,(DE)
  EXX
  AND L
  JR Z,DRAW_PIXELS_6_2
  SCF
DRAW_PIXELS_6_2:
  RL H
  EXX
  CALL PREVIOUS_SPRITE_ROW
  DEC C
  LD A,C
  AND $07
  JR NZ,DRAW_PIXELS_6_1
  EXX
  LD A,H
  EXX
DRAW_PIXELS_6_OP:
  NOP
  LD (HL),A
  INC L
  LD A,C
  AND A
  JR NZ,DRAW_PIXELS_6_1
  POP HL
  CALL SCREEN_ROW_UP
  POP DE
  POP BC
  EXX
  RLC L
  EXX
  JR NC,DRAW_PIXELS_6_0
  EXX
  DEC B
  EXX
  RET Z
  DEC DE
  JR DRAW_PIXELS_6_0

; Drawing mode 7: a sprite's pixels, upside down
;
; Entry 7 of PIXEL_DRAWERS. It fetches through FETCH_SPRITE, then copies row by
; row with the combining instruction patched in by SPRITE_COMBINE_OPCODE, the
; same as every other routine in the two tables.
DRAW_PIXELS_7:
  POP BC
  CALL SPRITE_COMBINE_OPCODE
  LD (DRAW_PIXELS_7_OP),A
  CALL FETCH_SPRITE
  LD A,B
  EXX
  LD B,A
  LD L,$80
  EXX
  CALL START_AT_LAST_ROW
DRAW_PIXELS_7_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_PIXELS_7_1:
  LD A,(DE)
  EXX
  AND L
  JR Z,DRAW_PIXELS_7_2
  SCF
DRAW_PIXELS_7_2:
  RL H
  EXX
  CALL PREVIOUS_SPRITE_ROW
  DEC C
  LD A,C
  AND $07
  JR NZ,DRAW_PIXELS_7_1
  EXX
  LD A,H
  EXX
DRAW_PIXELS_7_OP:
  NOP
  LD (HL),A
  INC L
  LD A,C
  AND A
  JR NZ,DRAW_PIXELS_7_1
  POP HL
  CALL SCREEN_ROW_UP
  POP DE
  POP BC
  EXX
  RRC L
  EXX
  JR NC,DRAW_PIXELS_7_0
  EXX
  DEC B
  EXX
  RET Z
  INC DE
  JR DRAW_PIXELS_7_0

; Convert pixel coordinates to a display file address
;
; Used by the routines at PRINT_MENU_LINE, DRAW_FOOD, TICK_CLOCK, DRAW_SUMMARY,
; FETCH_SPRITE, PIXEL_MASK, SETUP_ERASE, SETUP_SPRITE_DRAW, ERASE_STRIP,
; ADD_SCORE, PRINT_STRING and DRAW_SCROLL.
;
; The standard 48K display address computation, done in place on HL. Builds
; $4000 + ((y AND $C0) << 5) + ((y AND $07) << 8) + ((y AND $38) << 2) + (x >>
; 3).
;
; HL On entry H = y (0-191), L = x. On exit, the display file address of that
;    pixel's character cell.
PIXEL_TO_SCREEN:
  LD A,L                  ; x >> 3 gives the character column; (y AND $38) << 2
  RRCA                    ; the row within the third.
  RRCA                    ;
  RRCA                    ;
  AND $1F                 ;
  LD L,A                  ;
  LD A,H
  RLCA
  RLCA
  AND $E0
  OR L
  LD L,A
  LD A,H
  AND $07
  EX AF,AF'
  LD A,H                  ; Stash the low three bits of y -- the scan line
                          ; within the cell.
  RRCA
  RRCA
  RRCA
  AND $18
  OR $40
  LD H,A                  ; Bits 6-7 of y select which third of the screen; OR
  EX AF,AF'               ; $40 puts it in the display file.
  OR H
  LD H,A
  RET

; Step a screen address down one pixel row
;
; The standard Spectrum move: bump the row within the character cell, and only
; when that carries out of three bits step L on by 32 and take 8 off H to get
; back into the right third of the screen.
;
; Nothing calls it. There is no CALL or JP to NEXT_PIXEL_ROW anywhere in the
; game, and it is not in any of the jump tables; the drawing routines all
; compute a fresh address through PIXEL_TO_SCREEN instead. It disassembles
; cleanly and ends in a RET, so it is a routine, just not one that runs.
NEXT_PIXEL_ROW:
  INC H
  LD A,H                  ; Still inside the cell -- nothing else to do.
  AND $07                 ;
  RET NZ
  LD A,L                  ; Down to the next character row...
  ADD A,$20               ;
  LD L,A                  ;
  AND $E0                 ; ...and if that did not wrap, the third is
                          ; unchanged.
  RET Z
  LD A,H
  SUB $08
  LD H,A
  RET

; Convert pixel coordinates to an attribute file address
;
; Used by the routines at PRINT_MENU_LINE, FLASH_SCORE, FETCH_SPRITE_ATTRS,
; WORKSPACE_AND_DRAW, PRINT_STRING and PAINT_PANEL.
;
; The same conversion as PIXEL_TO_SCREEN, but landing in the attribute file:
; $5800 + (y >> 3) * 32 + (x >> 3). Preserves BC.
;
; HL On entry H = y (0-191), L = x. On exit, the attribute address of that
;    character cell.
PIXEL_TO_ATTR:
  PUSH BC
  LD A,L
  RRCA
  RRCA
  RRCA
  AND $1F
  LD L,A
  LD A,H
  RLCA
  RLCA
  LD C,A
  AND $E0
  OR L
  LD L,A
  LD A,C                  ; OR $58 rather than $40 -- the only real difference
  AND $03                 ; from PIXEL_TO_SCREEN.
  OR $58
  LD H,A
  POP BC
  RET

; Draw the room the player is in
;
; Used by the routine at ENTER_ROOM.
;
; Looks the room up twice. Its own entry in ROOM_TABLE gives a colour and a
; shape number; the shape number then selects an entry in ROOM_SHAPES, which
; carries how far the player may walk and where the outline's geometry lives.
; Rooms therefore share outlines freely -- only the colour and the shape number
; are per-room.
;
; Verified against a running game: in room $00 the table gives colour $42 and
; shape $00, shape $00 gives 56 by 56 and the two pointers SHAPE_VERTI_00 and
; SHAPE_EDGES_00, and the machine's own $5E1A, $5E1D and $5E1E read back $42,
; 56 and 56 with the attribute file filled with $42.
DRAW_ROOM:
  XOR A
  LD (ROOM_DRAWN),A
  LD A,(PLAYER_ROOM)      ; The room the player is in.
; This entry point is used by the routine at TRAPDOOR_FALL.
DRAW_ROOM_A:
  LD BC,ROOM_TABLE        ; Two bytes per room...
  LD L,A                  ; ...so double the room number to index it.
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD A,(HL)               ; First byte: the colour the whole room is drawn in.
  INC HL                  ;
  LD (ROOM_COLOUR),A      ;
  EXX
  LD HL,$5800             ; 24 by 24 character cells -- the play area, the same
  LD BC,$1818             ; extent CLEAR_PLAY_AREA blanks.
  LD A,(ROOM_COLOUR)      ;
  CALL FILL_BLOCK         ; Flood the attribute file with the room's colour in
                          ; one go.
  EXX
  LD L,(HL)               ; Second byte is the shape number; six bytes per
  LD H,$00                ; shape, so multiply by 6 the cheap way, as x2 + x4.
  ADD HL,HL               ;
  LD C,L                  ;
  LD B,H                  ;
  ADD HL,HL               ;
  ADD HL,BC               ;
  LD BC,ROOM_SHAPES       ;
  ADD HL,BC
  LD A,(HL)               ; How far from the centre the player may walk --
  INC HL                  ; MOVE_ACTOR reads these back out of $5E1D.
  LD (ROOM_HALF_WIDTH),A  ;
  LD A,(HL)               ; The vertical limit.
  INC HL                  ;
  LD (ROOM_HALF_HEIGHT),A ;
  LD E,(HL)               ; Where the shape's vertices are.
  INC HL                  ;
  LD D,(HL)               ;
  INC HL                  ;
  LD A,(HL)               ; Where its edge list is.
  INC HL                  ;
  LD H,(HL)               ;
  LD L,A                  ;
  PUSH DE                 ; The vertices are indexed through IX.
  POP IX                  ;
  PUSH BC
; This entry point is used by the routine at DRAW_OUTLINE.
OUTLINE_DONE:
  POP BC

; Walk the edge list and draw the room's outline
;
; The edge list is a run of vertex numbers. The first begins a group, each one
; after it draws a line from that vertex to this one, and $FF ends the group; a
; second $FF ends the list. Writing it as groups rather than as pairs means a
; corner shared by three lines is only named once.
;
; The vertex number cannot be known in advance, so as with MARK_ROOM_VISITED
; the routine writes the instruction that will use it: the displacement in each
; LD r,(IX+$00) below is overwritten just before it runs.
;
; For room shape $00 the vertices are two nested squares -- (4,187) (4,4)
; (187,4) (187,187) and (31,160) (31,31) (160,31) (160,160) -- and the groups
; are 0 to 1,3,4; 2 to 1,3,6; 5 to 1,4,6; 7 to 3,4,6. That is the four outer
; walls, the four inner ones and the four corner diagonals, each drawn exactly
; once, which is the "looking into a box" outline every room is built from.
DRAW_OUTLINE:
  LD A,(HL)               ; $FF ends the whole list.
  INC HL                  ;
  CP $FF                  ;
  RET Z
  SLA A                      ; Double the vertex number and patch it into both
  LD (FROM_VERTEX_X+$0002),A ; halves of the 16-bit fetch below.
  INC A                      ;
  LD (FROM_VERTEX_Y+$0002),A ;
FROM_VERTEX_X:
  LD C,(IX+$00)           ; Reads as (IX+$00) but the displacements were just
FROM_VERTEX_Y:
  LD B,(IX+$00)           ; rewritten.
DRAW_OUTLINE_0:
  PUSH BC
  LD A,(HL)
  INC HL
  CP $FF
  JR Z,OUTLINE_DONE
  SLA A
  LD (TO_VERTEX_X+$0002),A ; TO_VERTEX_X+2: the displacement in the fetch below
  INC A
  LD (TO_VERTEX_Y+$0002),A ; TO_VERTEX_Y+2: likewise
TO_VERTEX_X:
  LD E,(IX+$00)
TO_VERTEX_Y:
  LD D,(IX+$00)
  PUSH HL
  CALL DRAW_LINE          ; Draw one line, corner to corner.
  POP HL
  POP BC
  JR DRAW_OUTLINE_0

; Build a mask for one pixel in a byte
;
; Used by the routine at DRAW_LINE.
;
; Takes the low three bits of an x coordinate and rotates a single set bit into
; that position. DRAW_LINE needs it for every point it plots, since a pixel is
; one bit of a byte the rest of which must survive.
PIXEL_MASK:
  LD A,L
  AND $07
  INC A
  LD B,A
  XOR A
  SCF
PIXEL_MASK_0:
  RRA
  DJNZ PIXEL_MASK_0
  PUSH HL
  PUSH AF
  EX AF,AF'
  PUSH AF
  CALL PIXEL_TO_SCREEN
  POP AF
  EX AF,AF'
  POP AF
  OR (HL)
  LD (HL),A
  POP HL
  RET

; Draw a line between two points
;
; Used by the routine at DRAW_OUTLINE.
;
; Takes the difference along each axis, remembers which way each one runs in a
; pair of bits, and picks whichever axis is longer to step along -- the
; ordinary way of drawing a line one pixel at a time on a machine with no
; multiply. $5E23 and $5E24 hold the working values.
;
; BC One end
; DE The other
DRAW_LINE:
  LD H,B                  ; Keep one end in HL to walk along.
  LD L,C                  ;
  LD C,$00
  LD A,H                  ; |dx|, with bit 0 of C remembering the direction.
  SUB D                   ;
  JR NC,DRAW_LINE_0       ;
  NEG                     ;
  SET 0,C                 ;
DRAW_LINE_0:
  LD B,A
  LD A,L                  ; |dy|, in bit 1.
  SUB E                   ;
  JR NC,DRAW_LINE_1       ;
  NEG                     ;
  SET 1,C                 ;
DRAW_LINE_1:
  CP B                    ; Whichever is longer becomes the axis stepped
                          ; along...
  EX AF,AF'
  LD A,C
  LD (LINE_WORK_NEXT),A
  EX AF,AF'
  JP C,DRAW_LINE_5        ; ...and the steep case is handled separately.
  LD (LINE_WORK),A
  PUSH DE
  PUSH HL
  LD E,A
  LD D,$00
  LD L,D
  LD H,B
  CALL MULTIPLY_2
  LD A,(LINE_WORK_NEXT)
  BIT 0,A
  JR NZ,DRAW_LINE_2
  CALL NEGATE_HL
DRAW_LINE_2:
  LD A,(LINE_WORK_NEXT)
  BIT 1,A
  LD C,$01
  JR NZ,DRAW_LINE_3
  LD C,$FF
DRAW_LINE_3:
  EX DE,HL
  POP HL
  LD A,(LINE_WORK)
  INC A
  LD B,A
  LD A,E
  EX AF,AF'
DRAW_LINE_4:
  PUSH BC
  CALL PIXEL_MASK
  LD A,L
  EX AF,AF'
  LD L,A
  ADD HL,DE
  LD A,L
  EX AF,AF'
  POP BC
  ADD A,C
  LD L,A
  DJNZ DRAW_LINE_4
  POP HL
  JP PIXEL_MASK
DRAW_LINE_5:
  EX AF,AF'
  LD A,B
  LD (LINE_WORK),A
  EX AF,AF'
  PUSH DE
  PUSH HL
  LD E,B
  LD D,$00
  LD L,D
  LD H,A
  CALL MULTIPLY_2
  LD A,(LINE_WORK_NEXT)
  BIT 1,A
  JR NZ,DRAW_LINE_6
  CALL NEGATE_HL
DRAW_LINE_6:
  LD A,(LINE_WORK_NEXT)
  BIT 0,A
  LD C,$01
  JR NZ,DRAW_LINE_7
  LD C,$FF
DRAW_LINE_7:
  EX DE,HL
  POP HL
  LD A,(LINE_WORK)
  INC A
  LD B,A
  LD A,E
  EX AF,AF'
DRAW_LINE_8:
  PUSH BC
  CALL PIXEL_MASK
  LD A,H
  EX AF,AF'
  LD H,L
  LD L,A
  ADD HL,DE
  LD A,L
  LD L,H
  EX AF,AF'
  POP BC
  ADD A,C
  LD H,A
  DJNZ DRAW_LINE_8
  POP HL
  JP PIXEL_MASK

; Choose the instruction that puts a sprite byte on the screen
;
; Used by the routines at BLIT_SPRITE, BLIT_SPRITE_MIRRORED, DRAW_PIXELS_2,
; DRAW_PIXELS_3, DRAW_PIXELS_4, BLIT_SPRITE_FLIPPED, DRAW_PIXELS_6 and
; DRAW_PIXELS_7.
;
; Returns an opcode rather than a flag, for BLIT_SPRITE to write into the
; middle of its own loop. The drawing mode is packed into B: the low two bits
; pick the combining operation here, the top three pick which of the eight
; drawing routines runs.
;
; B Drawing mode
; A $00 for NOP, $B6 for OR (HL), $AE for XOR (HL)
SPRITE_COMBINE_OPCODE:
  LD A,B                  ; Mode 0 leaves A zero -- a NOP, so the sprite byte
  AND $03                 ; is stored as it is.
  RET Z                   ;
  CP $01                  ; $AE is XOR (HL), which is how a sprite is drawn and
  LD A,$AE                ; then rubbed out again by drawing it a second time.
  RET NZ                  ; Modes 2 and 3 both take it.
  ADD A,$08               ; $AE + 8 is $B6, OR (HL) -- the sprite laid over
                          ; what is already there.
  RET

; Drawing mode 0: a sprite's colours, the right way up
;
; Entry 0 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_0:
  POP BC
  CALL FETCH_SPRITE_ATTRS
DRAW_COLOURS_0_0:
  PUSH BC
  PUSH HL
DRAW_COLOURS_0_1:
  LD A,(DE)
  INC DE
  AND A
  JR Z,DRAW_COLOURS_0_3
  CP $FF
  JR NZ,DRAW_COLOURS_0_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_0_2:
  LD (HL),A
DRAW_COLOURS_0_3:
  INC L
  DJNZ DRAW_COLOURS_0_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,DRAW_COLOURS_0_0
  RET

; Drawing mode 1: a sprite's colours, the right way up
;
; Entry 1 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_1:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  DEC DE
DRAW_COLOURS_1_0:
  CALL NEXT_SPRITE_ROW
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_1_1:
  LD A,(DE)
  DEC DE
  AND A
  JR Z,DRAW_COLOURS_1_3
  CP $FF
  JR NZ,DRAW_COLOURS_1_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_1_2:
  LD (HL),A
DRAW_COLOURS_1_3:
  INC L
  DJNZ DRAW_COLOURS_1_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  DEC C
  JR NZ,DRAW_COLOURS_1_0
  RET

; Drawing mode 2: a sprite's colours, the right way up
;
; Entry 2 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_2:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  LD A,B
  EXX
  LD B,A
  EXX
  CALL NEXT_SPRITE_ROW
DRAW_COLOURS_2_0:
  DEC DE
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_2_1:
  LD A,(DE)
  AND A
  JR Z,DRAW_COLOURS_2_3
  CP $FF
  JR NZ,DRAW_COLOURS_2_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_2_2:
  LD (HL),A
DRAW_COLOURS_2_3:
  CALL NEXT_SPRITE_ROW
  INC L
  DEC C
  JR NZ,DRAW_COLOURS_2_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  EXX
  DEC B
  EXX
  JR NZ,DRAW_COLOURS_2_0
  RET

; Drawing mode 3: a sprite's colours, the right way up
;
; Entry 3 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_3:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  LD A,B
  EXX
  LD B,A
  EXX
DRAW_COLOURS_3_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_3_1:
  LD A,(DE)
  AND A
  JR Z,DRAW_COLOURS_3_3
  CP $FF
  JR NZ,DRAW_COLOURS_3_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_3_2:
  LD (HL),A
DRAW_COLOURS_3_3:
  CALL NEXT_SPRITE_ROW
  INC L
  DEC C
  JR NZ,DRAW_COLOURS_3_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  INC DE
  EXX
  DEC B
  EXX
  JR NZ,DRAW_COLOURS_3_0
  RET

; Drawing mode 4: a sprite's colours, upside down
;
; Entry 4 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_4:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  CALL START_AT_LAST_ROW
DRAW_COLOURS_4_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_4_1:
  LD A,(DE)
  INC DE
  AND A
  JR Z,DRAW_COLOURS_4_3
  CP $FF
  JR NZ,DRAW_COLOURS_4_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_4_2:
  LD (HL),A
DRAW_COLOURS_4_3:
  INC L
  DJNZ DRAW_COLOURS_4_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  CALL PREVIOUS_SPRITE_ROW
  DEC C
  JR NZ,DRAW_COLOURS_4_0
  RET

; Drawing mode 5: a sprite's colours, upside down
;
; Entry 5 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_5:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  CALL START_AT_LAST_ROW
  CALL NEXT_SPRITE_ROW
  DEC DE
DRAW_COLOURS_5_0:
  PUSH BC
  PUSH HL
DRAW_COLOURS_5_1:
  LD A,(DE)
  DEC DE
  AND A
  JR Z,DRAW_COLOURS_5_3
  CP $FF
  JR NZ,DRAW_COLOURS_5_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_5_2:
  LD (HL),A
DRAW_COLOURS_5_3:
  INC L
  DJNZ DRAW_COLOURS_5_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,DRAW_COLOURS_5_0
  RET

; Drawing mode 6: a sprite's colours, upside down
;
; Entry 6 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_6:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  LD A,B
  EXX
  LD B,A
  EXX
  CALL START_AT_LAST_ROW
  CALL NEXT_SPRITE_ROW
DRAW_COLOURS_6_0:
  DEC DE
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_6_1:
  LD A,(DE)
  AND A
  JR Z,DRAW_COLOURS_6_3
  CP $FF
  JR NZ,DRAW_COLOURS_6_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_6_2:
  LD (HL),A
DRAW_COLOURS_6_3:
  CALL PREVIOUS_SPRITE_ROW
  INC L
  DEC C
  JR NZ,DRAW_COLOURS_6_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  EXX
  DEC B
  EXX
  JR NZ,DRAW_COLOURS_6_0
  RET

; Drawing mode 7: a sprite's colours, upside down
;
; Entry 7 of COLOUR_DRAWERS. It fetches through FETCH_SPRITE_ATTRS, then copies
; row by row with the combining instruction patched in by
; SPRITE_COMBINE_OPCODE, the same as every other routine in the two tables.
DRAW_COLOURS_7:
  POP BC
  CALL FETCH_SPRITE_ATTRS
  LD A,B
  EXX
  LD B,A
  EXX
  CALL START_AT_LAST_ROW
DRAW_COLOURS_7_0:
  PUSH BC
  PUSH DE
  PUSH HL
DRAW_COLOURS_7_1:
  LD A,(DE)
  AND A
  JR Z,DRAW_COLOURS_7_3
  CP $FF
  JR NZ,DRAW_COLOURS_7_2
  LD A,(ROOM_COLOUR)
DRAW_COLOURS_7_2:
  LD (HL),A
DRAW_COLOURS_7_3:
  CALL PREVIOUS_SPRITE_ROW
  INC L
  DEC C
  JR NZ,DRAW_COLOURS_7_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP DE
  POP BC
  INC DE
  EXX
  DEC B
  EXX
  JR NZ,DRAW_COLOURS_7_0
  RET

; Find the graphics for what is in the workspace
;
; Used by the routine at SETUP_ERASE.
;
; The same as SPRITE_OF_ACTOR but reading the sprite from $5E15 rather than
; from a record -- for the paths that have already lifted it out.
SPRITE_OF_WORKSPACE:
  LD A,(WORK_SPRITE)

; Find a sprite's graphics
;
; Used by the routines at MATERIALISING, DYING, LOSE_LIFE and SPRITE_OF_ACTOR.
;
; Sprite numbers are 1-based, so one is taken off before doubling into
; SPRITE_TABLE. This is the lookup the general drawing path uses, and it is the
; one that covers every sprite in the game -- the catalogue of pictures is
; built by driving this path, which is why it can draw codes right across the
; range.
;
; A The sprite number
; DE On exit, that sprite's graphics
SPRITE_ADDRESS:
  DEC A                   ; Numbered from 1, two bytes an entry.
  LD L,A                  ;
  LD H,$00                ;
  ADD HL,HL               ;
  LD BC,SPRITE_TABLE      ; The table.
  ADD HL,BC               ;
  LD E,(HL)               ; The address it holds.
  INC HL                  ;
  LD D,(HL)               ;
  RET

; Find this actor's graphics
;
; Used by the routine at SETUP_SPRITE_DRAW.
;
; Takes the sprite number out of the record and falls into SPRITE_ADDRESS. The
; two-instruction convenience that most of the drawing path actually calls.
SPRITE_OF_ACTOR:
  LD A,(IX+$00)
  JR SPRITE_ADDRESS

; Draw only the rows that fit
;
; Used by the routines at DRAW_THING, ERASE_THING and DRAW_CLIPPED.
;
; Part of the drawing path that deals with a sprite hanging off an edge: it
; counts rows down in C and drops out early rather than letting the blitter run
; past the end of the play area. The alternate register set holds the second of
; the two counts, which is why it is full of EXX.
CLIP_ROWS:
  LD A,C
  AND A
  JR Z,CLIP_ROWS_2
  DEC C
  CALL FETCH_ROW
  EXX
  LD A,C
  AND A
  JR Z,CLIP_ROWS_1
CLIP_ROWS_0:
  DEC C
  CALL SHIFT_AND_PLOT
CLIP_ROWS_1:
  EXX
  JR CLIP_ROWS
CLIP_ROWS_2:
  EXX
  LD A,C
  AND A
  JR NZ,CLIP_ROWS_0
; This entry point is used by the routine at DRAW_CLIPPED.
CLIP_SWAP:
  EXX
; This entry point is used by the routine at DRAW_CLIPPED.
CLIP_TOP:
  LD A,(CLIP_COUNT)
  LD C,A
  LD A,(CLIP_LIMIT)
  OR C
  RET Z
  XOR A
  LD (CLIP_COUNT),A
  EXX
  LD A,(CLIP_LIMIT)
  LD C,A
  XOR A
; This entry point is used by the routine at DRAW_CLIPPED.
CLIP_STORE:
  LD (CLIP_LIMIT),A
  EXX
  JR CLIP_ROWS

; Put two bytes on the screen with XOR
;
; The ending both shift chains fall into: XOR the shifted bytes onto what is
; already there, which both draws a sprite and rubs it out again on a second
; pass.
PLOT_XOR:
  EX DE,HL
  EX (SP),HL
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  POP DE
  DEC L
  JP SCREEN_ROW_UP

; Read two bytes of a sprite row
;
; Used by the routine at CLIP_ROWS.
;
; Loads a row into DE ready for shifting, and steps the pointer on.
FETCH_ROW:
  EX DE,HL
  PUSH DE
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  EX DE,HL
  XOR A
ERASE_JR:
  JR ERASE_JR

; The second unrolled shift chain
;
; Seven more ADD HL,HL and ADC A,A pairs, entered part-way down by a patched
; jump exactly as SHIFT_CHAIN is. There are two because the two plot endings --
; one XORing, one storing -- each need their own chain to fall into.
SHIFT_CHAIN_2:
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  ADD HL,HL
  ADC A,A
  EX DE,HL
  EX (SP),HL
  XOR (HL)
  LD (HL),A
  INC L
; This entry point is used by the routine at SHIFT_CHAIN.
XOR_BYTE:
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  POP DE
  DEC L
  DEC L

; Move a display file address up one pixel row
;
; Used by the routines at BLIT_SPRITE, BLIT_SPRITE_MIRRORED, DRAW_PIXELS_2,
; DRAW_PIXELS_3, DRAW_PIXELS_4, BLIT_SPRITE_FLIPPED, DRAW_PIXELS_6,
; DRAW_PIXELS_7, PLOT_XOR, PLOT_XOR_2 and ERASE_STRIP.
;
; The counterpart to PIXEL_TO_SCREEN's arithmetic, done as cheaply as possible
; because BLIT_SPRITE calls it once per row of every sprite on the screen.
; Within a character cell the row is the low three bits of H, so most calls are
; a DEC H and a test; only one in eight has to step back a whole character row,
; and only one in sixty-four crosses between the display's thirds.
;
; HL A display file address; on exit, the same column one pixel higher
SCREEN_ROW_UP:
  DEC H                   ; The common case, and usually the only instruction
                          ; that runs.
  LD A,H                  ; Did that take us out of the top of the character
  CPL                     ; cell? If not, done.
  AND $07                 ;
  RET NZ                  ;
  LD A,L                  ; It did: back one character row. A borrow here means
  SUB $20                 ; we also crossed into the third above, where H is
  LD L,A                  ; already right.
  RET C                   ;
  LD A,H                  ; No borrow, so undo the DEC H's effect on the cell
  ADD A,$08               ; row.
  LD H,A                  ;
  RET

; The other XOR ending
;
; As PLOT_XOR, reached from the other chain.
PLOT_XOR_2:
  EX DE,HL
  EX (SP),HL
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  POP DE
  DEC L
  JP SCREEN_ROW_UP

; Shift one row of a sprite into place and draw it
;
; Used by the routine at CLIP_ROWS.
;
; Reads two bytes of the row into HL and then jumps into the chain below at
; whatever depth SETUP_SPRITE_DRAW patched in. Each step there is ADD HL,HL
; with ADC A,A behind it, so the pair behaves as a 17-bit shift left: the bit
; falling off HL is caught in A, which becomes the third byte on screen.
SHIFT_AND_PLOT:
  EX DE,HL                ; The row.
  PUSH DE                 ;
  LD D,(HL)               ; Two bytes of it, and step past them.
  INC HL                  ;
  LD E,(HL)               ;
  INC HL                  ;
  EX DE,HL                ; A starts empty and collects the bits pushed out of
  XOR A                   ; HL.
DRAW_JR:
  JR DRAW_JR              ; Reads as a jump to itself; by the time it runs the
                          ; displacement has been overwritten, and it lands
                          ; part-way down the chain.

; Seven shifts, entered part-way down
;
; Not a loop: seven copies of the same two instructions, one after another, so
; that jumping in n pairs from the top performs 7 - n shifts with no counter
; and no branch. The whole cost of positioning a sprite to the pixel is one
; patched jump.
SHIFT_CHAIN:
  ADD HL,HL               ; Seven ADD HL,HL / ADC A,A pairs. Entering at the
  ADC A,A                 ; top shifts seven times, two bytes in six, and so
  ADD HL,HL               ; on.
  ADC A,A                 ;
  ADD HL,HL               ;
  ADC A,A                 ;
  ADD HL,HL               ;
  ADC A,A                 ;
  ADD HL,HL               ;
  ADC A,A                 ;
  ADD HL,HL               ;
  ADC A,A                 ;
  ADD HL,HL               ;
  ADC A,A                 ;
  EX DE,HL                ; Whatever the shift, the row ends up here to be
  EX (SP),HL              ; XORed onto the screen.
  XOR (HL)                ;
  LD (HL),A               ;
  INC L                   ;
  JR XOR_BYTE

; Two short entries into the drawing setup
;
; Each calls one half of the setup and jumps into the middle of the routine
; below, so a caller that already has half of what it needs can skip the rest.
SETUP_ALT_ENTRIES:
  CALL SETUP_AT_POSITION
  JR DRAW_THING_ALT
  CALL SETUP_ERASE_ALT
  JR ERASE_THING_ALT

; Draw a record's sprite
;
; Used by the routines at TRY_FIRE_ALT, SPAWN_MONSTER_INTO_ROOM, MOVE_871A,
; MOVE_MUMMY, MOVE_HUMPBACK, MATERIALISING, DRAW_ROOM_CONTENTS, DROP_CARRIED,
; PLACE_PLAYER, DROP_OBJECT, DRAW_LIST, DRAW_LIVES and DRAW_TITLE_ICONS.
;
; Sets the drawing up through SETUP_SPRITE_DRAW, clears the working count at
; $5E18, and draws. The entry most handlers use when they simply want something
; on the screen.
DRAW_THING:
  CALL SETUP_SPRITE_DRAW
; This entry point is used by the routine at SETUP_ALT_ENTRIES.
DRAW_THING_ALT:
  EXX
  XOR A
  LD (CLIP_COUNT),A
  LD C,A
  JP CLIP_ROWS

; Rub a record's sprite out
;
; Used by the routines at SPIN_SPELL, MOVE_871A, EAT_FOOD, REMEMBER_CARRIED and
; MUSHROOM_KILLED_PLAYER.
;
; The counterpart to DRAW_THING, working from the position saved in the
; workspace rather than the record's current one -- which is how something is
; erased from where it was rather than where it has just moved to.
ERASE_THING:
  CALL SETUP_ERASE
; This entry point is used by the routine at SETUP_ALT_ENTRIES.
ERASE_THING_ALT:
  EXX
  XOR A
  LD C,A
  LD (CLIP_LIMIT),A
  LD A,(CLIP_COUNT)
  LD (DRAW_SHIFT),A
  LD A,L
  AND $07
  LD A,$02
  JR Z,ERASE_THING_0
  INC A
ERASE_THING_0:
  LD (DRAW_WIDTH),A
  EXX
  JP CLIP_ROWS

; Set up the drawing address in both register banks
;
; Runs the same setup twice, once per bank, keeping DE across the first call so
; the second gets the same argument, and then joins the erase path at
; CLIP_BOTTOM.
;
; Like NEXT_PIXEL_ROW, nothing reaches it: no call, no jump, no table entry.
; SETUP_ERASE immediately after it is the version the game actually uses.
SETUP_BOTH_BANKS:
  PUSH DE                 ; DE is wanted twice, so it is kept over the first
  CALL SETUP_ERASE_ALT    ; call.
  EXX                     ; The second bank gets the same argument.
  POP DE                  ;
  CALL SETUP_AT_POSITION  ;
  EXX
  JR CLIP_BOTTOM

; Work out where a thing used to be
;
; Used by the routines at ERASE_THING and DRAW_CLIPPED.
;
; Looks the sprite up from the workspace and computes the display address of
; the position saved in $5E16, so ERASE_THING can blank exactly the cells the
; last frame filled.
SETUP_ERASE:
  CALL SPRITE_OF_WORKSPACE
; This entry point is used by the routines at SETUP_ALT_ENTRIES and
; SETUP_BOTH_BANKS.
SETUP_ERASE_ALT:
  LD HL,(WORK_X)
  LD A,L
  DEC A
  RLCA
  AND $0E
  CP $0E
  JR NZ,SETUP_ERASE_0
  LD A,$E8
SETUP_ERASE_0:
  LD (ERASE_JR+$0001),A   ; ERASE_JR+1: the jump's displacement
  CALL PIXEL_TO_SCREEN
  LD A,(DE)
  LD (CLIP_COUNT),A
; This entry point is used by the routine at SETUP_SPRITE_DRAW.
SETUP_DONE:
  LD C,$00
  INC DE
  RET

; Work out where a sprite goes, and how far to shift it
;
; Used by the routines at DRAW_THING and DRAW_CLIPPED.
;
; Sprites in this family are two bytes wide in the data and land on the screen
; straddling two or three, because x is a pixel position and not a character
; column. Rather than keep eight pre-shifted copies of every sprite, the game
; shifts at draw time -- and rather than loop, it computes where to jump into
; an unrolled chain of shifts and writes that into the jump itself.
;
; The displacement is 2 * ((x - 1) AND 7), which SHIFT_AND_PLOT's JR turns into
; "skip this many bytes of the chain". More shifts for a small offset, fewer
; for a large one. The one case that would need none is redirected to a plot
; routine that does not shift at all.
;
; IX The thing being drawn
SETUP_SPRITE_DRAW:
  CALL SPRITE_OF_ACTOR    ; Its graphics, through SPRITE_TABLE.
; This entry point is used by the routines at SETUP_ALT_ENTRIES and
; SETUP_BOTH_BANKS.
SETUP_AT_POSITION:
  LD L,(IX+$03)           ; Its position.
  LD H,(IX+$04)           ;
  LD A,L                  ; The low three bits of x, doubled: how far into the
  DEC A                   ; shift chain to start.
  RLCA                    ;
  AND $0E                 ;
  CP $0E                    ; A shift of none is a special case...
  JR NZ,SETUP_SPRITE_DRAW_0 ;
  LD A,$E8                ; ...redirected right out of the chain to a plot with
                          ; no shifting at all.
SETUP_SPRITE_DRAW_0:
  LD (DRAW_JR+$0001),A    ; Write it into the JR at DRAW_JR.
  LD A,$02                 ; Two bytes of sprite cover three columns unless it
  JR Z,SETUP_SPRITE_DRAW_1 ; lands square.
  INC A                    ;
SETUP_SPRITE_DRAW_1:
  LD (DRAW_WIDTH),A       ; How wide to erase and redraw.
  CALL PIXEL_TO_SCREEN
  LD A,(DE)               ; The first byte of a sprite's data is its height in
  LD (CLIP_LIMIT),A       ; rows.
  LD (DRAW_SHIFT),A       ;
  JR SETUP_DONE

; Draw a sprite that may not fit
;
; Used by the routine at UPDATE_KNIGHT.
;
; Sets the drawing up through SETUP_SPRITE_DRAW, then compares the thing's
; position against the workspace to work out how much of it is off the edge,
; handing the whole-sprite case and the two clipped cases to different
; routines. Called from the character handlers, which are the sprites most
; likely to be walking off the edge of the play area.
DRAW_CLIPPED:
  CALL SETUP_SPRITE_DRAW
  EXX
  CALL SETUP_ERASE
; This entry point is used by the routine at SETUP_BOTH_BANKS.
CLIP_BOTTOM:
  LD A,(WORK_Y)
  SUB (IX+$04)
  JP Z,CLIP_TOP
  JP M,DRAW_CLIPPED_0
  LD C,A
  LD A,(CLIP_COUNT)
  CP C
  JP C,CLIP_TOP
  SUB C
  LD (CLIP_COUNT),A
  JP CLIP_ROWS
DRAW_CLIPPED_0:
  EXX
  NEG
  LD C,A
  LD A,(CLIP_LIMIT)
  CP C
  JP C,CLIP_SWAP
  SUB C
  JP CLIP_STORE

; Copy an actor's position and sprite into the drawing workspace
;
; Used by the routines at SPIN_AXE, SPIN_SPELL, SPIN_SWORD, MOVE_BAT_ALT,
; MOVE_ACTOR, SPAWN_MONSTER, MOVE_BAT, MOVE_GHOST_ALT, MOVE_871A,
; COUNTDOWN_ACTOR, MOVE_GHOST, MOVE_MUMMY, MOVE_DRACULA, MOVE_FRANKENSTEIN,
; MOVE_DEVIL, MOVE_WITCH, MOVE_8A80, MOVE_HUMPBACK, EAT_FOOD, MOVE_PLAYER,
; PICK_UP and MUSHROOM.
;
; Lifts three fields out of the record IX points at into fixed locations at
; $5E15-$5E17, so the drawing code can reach them without IX.
;
; Called for the player and for every monster alike, which is how the two were
; shown to share one record layout: breaking here and collecting IX gives $EA90
; -- the player -- alongside the eight monster records at $EE60, $EE70, $EE80,
; $EE90, $EEA0, $EEB0, $EEC0 and $EED0.
;
; IX The record to read
ACTOR_TO_WORKSPACE:
  LD A,(IX+$03)           ; +$03 and +$04 are the position.
  LD (WORK_X),A           ;
  LD A,(IX+$04)           ;
  LD (WORK_Y),A           ;
  LD A,(IX+$00)           ; +$00 is the sprite.
  LD (WORK_SPRITE),A      ;
  RET
; The record is 16 bytes. The lower half describes the thing itself -- +$00
; sprite, +$01 room, +$03 x, +$04 y -- and in the player's copy the upper half
; describes the weapon it has in flight: +$08 type ($00 when nothing is in the
; air), +$09 room, +$0B x, +$0C y, +$0E signed velocity. Watched live: firing
; fills +$08 onwards, +$0B walks across the room while +$0C holds steady, and
; +$0E flips between $04 and $FC as the shot turns round off a wall.

; Note where a thing is, then draw it
;
; Used by the routines at DRAW_LIST and DRAW_TITLE_ICONS.
;
; Copies the position out of the record into $5E16 and $5E17 before falling
; into the drawing proper. Those two are what the erase pass reads to find
; where something was last frame, so recording them here is what lets the next
; pass rub it out cleanly.
;
; IX The thing to draw
WORKSPACE_AND_DRAW:
  LD A,(IX+$03)           ; Where it is now...
  LD (WORK_X),A           ;
  LD A,(IX+$04)           ; ...kept for the pass that will erase it.
  LD (WORK_Y),A           ;
; This entry point is used by the routines at SPIN_SPELL, MOVE_871A,
; UPDATE_KNIGHT, DRAW_AT_POSITION and REMEMBER_CARRIED.
DRAW_FROM_RECORD:
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD D,(IX+$05)
  LD A,(ROOM_COLOUR)
  LD E,A
  LD A,(DRAW_WIDTH)
  LD B,A
  LD A,(DRAW_SHIFT)
  RRCA
  RRCA
  INC A
  RRCA
  AND $1F
  INC A
  LD C,A
  PUSH BC
  LD B,$00
  LD A,(WORK_X)
  CP L
  JR Z,WORKSPACE_AND_DRAW_1
  JR C,WORKSPACE_AND_DRAW_0
  INC B
WORKSPACE_AND_DRAW_0:
  INC B
WORKSPACE_AND_DRAW_1:
  LD A,(WORK_Y)
  CP H
  LD A,B
  JR Z,WORKSPACE_AND_DRAW_3
  JR C,WORKSPACE_AND_DRAW_2
  ADD A,$04
WORKSPACE_AND_DRAW_2:
  ADD A,$04
WORKSPACE_AND_DRAW_3:
  LD B,A
  CALL PIXEL_TO_ATTR
  LD A,B
  POP BC
  PUSH HL
  LD HL,FILL_HANDLERS
  SLA A
  CALL ADD_A_TO_HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  JP (HL)

; Where to go for each way of filling a run
;
; Eleven addresses, picked up two at a time and entered with JP (HL). Two of
; the eleven are INERT_SPRITE rather than a routine in this group, which is the
; same trick the actor table uses: an entry that does nothing useful points at
; something harmless instead of being left out.
FILL_HANDLERS:
  DEFW FILL_ATTRS
  DEFW FILL_ATTRS_BACK
  DEFW FILL_ATTRS_2
  DEFW INERT_SPRITE
  DEFW FILL_ATTRS_3
  DEFW FILL_ATTRS_ALT
  DEFW FILL_ATTRS_4
  DEFW INERT_SPRITE
  DEFW FILL_ATTRS_ROW
  DEFW FILL_ATTRS_ROW_3
  DEFW FILL_ATTRS_ROW_2

; Write a sprite's colours into the attribute file
;
; The colour family's inner loop: a row of attribute cells written from D,
; stepping along with INC L. The seven routines that follow are the same loop
; with the direction reversed, the row stepped by $20 instead, or the second
; colour in E used -- one per drawing mode, exactly as the pixel family has one
; per mode.
FILL_ATTRS:
  POP HL
; This entry point is used by the routine at FILL_ATTRS_ROW.
FILL_ATTRS_BODY:
  PUSH BC
  PUSH HL
FILL_ATTRS_0:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_0
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_BODY
  RET

; The same, written backwards
;
; DEC L rather than INC L, for the mirrored drawing modes.
FILL_ATTRS_BACK:
  POP HL
; This entry point is used by the routine at FILL_ATTRS_ROW_3.
FILL_ATTRS_BACK_BODY:
  PUSH BC
  PUSH HL
  DEC L
  LD (HL),E
  INC L
FILL_ATTRS_BACK_0:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_BACK_0
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_BACK_BODY
  RET

; Another of the eight colour writers
;
; As FILL_ATTRS, for a different drawing mode.
FILL_ATTRS_2:
  POP HL
; This entry point is used by the routine at FILL_ATTRS_ROW_2.
FILL_ATTRS_SECOND_BODY:
  PUSH BC
  PUSH HL
FILL_ATTRS_2_0:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_2_0
  LD (HL),E
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_SECOND_BODY
  RET

; Another of the eight colour writers
;
; As FILL_ATTRS, for a different drawing mode.
FILL_ATTRS_3:
  POP HL
FILL_ATTRS_3_0:
  PUSH BC
  PUSH HL
FILL_ATTRS_3_1:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_3_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_3_0
; This entry point is used by the routines at FILL_ATTRS_ALT and FILL_ATTRS_4.
FILL_ATTRS_LIMIT:
  LD A,H
  CP $58
  RET C
FILL_ATTRS_3_2:
  LD (HL),E
  INC L
  DJNZ FILL_ATTRS_3_2
  RET

; A colour writer using the second colour
;
; Writes from E rather than D, so a sprite drawn through this mode comes out in
; its alternate colour.
FILL_ATTRS_ALT:
  POP HL
FILL_ATTRS_ALT_0:
  PUSH BC
  PUSH HL
  DEC L
  LD (HL),E
  INC L
FILL_ATTRS_ALT_1:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_ALT_1
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_ALT_0
  DEC L
  LD (HL),E
  INC L
  JR FILL_ATTRS_LIMIT

; A colour writer that steps a whole row
;
; Adds $20 between cells -- one attribute row -- so it fills a column rather
; than a line.
FILL_ATTRS_ROW:
  POP HL
  PUSH BC
  PUSH HL
  PUSH BC
  LD BC,$0020
  ADD HL,BC
  POP BC
FILL_ATTRS_ROW_0:
  LD (HL),E
  INC L
  DJNZ FILL_ATTRS_ROW_0
  POP HL
  POP BC
  JP FILL_ATTRS_BODY

; Another column-wise colour writer
;
; As FILL_ATTRS_ROW, for a different mode.
FILL_ATTRS_ROW_2:
  POP HL
  PUSH BC
  PUSH HL
  PUSH BC
  LD BC,$0020
  ADD HL,BC
  POP BC
  INC B
FILL_ATTRS_ROW_2_0:
  LD (HL),E
  INC L
  DJNZ FILL_ATTRS_ROW_2_0
  POP HL
  POP BC
  JR FILL_ATTRS_SECOND_BODY

; The last of the eight colour writers
;
; As FILL_ATTRS, for the remaining mode.
FILL_ATTRS_4:
  POP HL
FILL_ATTRS_4_0:
  PUSH BC
  PUSH HL
FILL_ATTRS_4_1:
  LD (HL),D
  INC L
  DJNZ FILL_ATTRS_4_1
  LD (HL),E
  POP HL
  LD BC,$0020
  AND A
  SBC HL,BC
  POP BC
  DEC C
  JR NZ,FILL_ATTRS_4_0
  INC B
  JP FILL_ATTRS_LIMIT

; A column-wise colour writer for the mirrored modes
;
; The $20 step of FILL_ATTRS_ROW with the reversal of FILL_ATTRS_BACK.
FILL_ATTRS_ROW_3:
  POP HL
  PUSH BC
  PUSH HL
  PUSH BC
  LD BC,$0020
  ADD HL,BC
  POP BC
  DEC L
  INC B
FILL_ATTRS_ROW_3_0:
  LD (HL),E
  INC L
  DJNZ FILL_ATTRS_ROW_3_0
  POP HL
  POP BC
  JP FILL_ATTRS_BACK_BODY

; Draw the three carried objects on the scroll
;
; Used by the routines at ENTER_ROOM, PICK_UP and PUT_DOWN.
;
; Walks the three inventory slots at $5E30 and draws each through DRAW_LIST,
; starting at $2CC8 -- so what the player is carrying is shown by drawing the
; objects themselves rather than by any separate icon. An empty slot draws
; nothing.
DRAW_INVENTORY:
  LD DE,$2CC8
  LD HL,CARRIED
  LD B,$03
DRAW_INVENTORY_0:
  CALL DRAW_LIST
  LD A,E
  ADD A,$10
  LD E,A
  DJNZ DRAW_INVENTORY_0
  RET

; Draw a list of things through the scratch record
;
; Used by the routine at DRAW_INVENTORY.
;
; Walks a list whose entries are drawn one at a time by loading each into
; UI_RECORD and using the ordinary sprite path, stopping at a zero pair. The
; same idea as DRAW_TITLE_ICONS, generalised: anything that has to be drawn
; without being an actor goes through here.
DRAW_LIST:
  PUSH BC
  PUSH DE
  PUSH IX
  LD IX,UI_RECORD
  LD A,(HL)
  INC HL
  OR (HL)
  INC HL
  LD A,(HL)
  JR NZ,DRAW_LIST_0
  LD A,$31
DRAW_LIST_0:
  INC HL
  LD (IX+$00),A
  LD (IX+$03),E
  LD (IX+$04),D
  LD A,(HL)
  INC HL
  LD (IX+$05),A
  PUSH HL
  CALL ERASE_STRIP
  CALL DRAW_THING
  CALL WORKSPACE_AND_DRAW
  POP HL
  POP IX
  POP DE
  POP BC
  RET

; A spare record for drawing things that are not actors
;
; Eight bytes of scratch. The sprite routines only know how to draw from a
; record, so anything that has to appear without being a creature -- the lives
; on the scroll, the pictures on the title screen -- is written in here first
; and drawn from here.
;
; That it is eight bytes and not sixteen is the useful part. A monster's record
; is sixteen, but only its first eight describe the thing itself: sprite, room,
; a flag, x, y, drawing mode. The doors above $EEE0 are eight bytes too. So the
; short form is the common one, and an actor is that plus another eight for how
; it moves and what it has in the air.
UI_RECORD:
  DEFS $08

; Blank twenty bytes where something was
;
; Used by the routines at DRAW_LIST and DRAW_LIVES.
;
; Works out the display address from a record's position and writes zero across
; twenty bytes -- the fastest way to rub out something that is about to be
; redrawn somewhere else.
ERASE_STRIP:
  LD L,(IX+$03)
  LD H,(IX+$04)
  CALL PIXEL_TO_SCREEN
  LD B,$14
ERASE_STRIP_0:
  LD (HL),$00
  INC L
  LD (HL),$00
  DEC L
  CALL SCREEN_ROW_UP
  DJNZ ERASE_STRIP_0
  RET

; Add to the score and redraw it
;
; Used by the routines at MOVE_871A and MOVE_FRANKENSTEIN.
;
; The score is three bytes of BCD at $5E2A-$5E2C, printed as six digits. The
; three DAAs carry across the whole of it, so a caller only has to hand over
; the amount in BC.
;
; Confirmed against a running game: with the panel reading SCORE 000310 the
; three bytes held $00 $03 $10.
;
; BC The amount to add, in BCD
ADD_SCORE:
  LD HL,SCORE_LOW         ; The least significant byte, working backwards from
                          ; there.
  LD A,(HL)               ; DAA after each addition is what keeps it decimal.
  ADD A,C                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ; Carry up through the middle and top bytes.
  LD A,(HL)               ;
  ADC A,B                 ;
  DAA                     ;
  LD (HL),A               ;
  DEC HL                  ;
  LD A,(HL)               ;
  ADC A,$00               ;
  DAA
  LD (HL),A
; This entry point is used by the routine at DRAW_SCROLL.
DRAW_SCORE:
  LD HL,FONT_DIGITS       ; Point the tile source at the digits before drawing
  LD (TILE_SOURCE),HL     ; -- this is the biased pointer PLOT_TILE's note
                          ; describes, TEXT_FONT + $80, so a digit value
                          ; indexes its own character.
  LD HL,$50C8
; This entry point is used by the routine at DRAW_SUMMARY.
DRAW_SCORE_AT:
  CALL PIXEL_TO_SCREEN
  LD DE,SCORE             ; Three bytes, two digits in each.
  LD B,$03                ;
; This entry point is used by the routines at TICK_CLOCK and DRAW_SUMMARY.
DRAW_DIGITS:
  LD A,(DE)               ; High nibble first, then the low one.
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  RRCA                    ;
  AND $0F                 ;
  CALL PLOT_TILE
; This entry point is used by the routine at TICK_CLOCK.
DRAW_LOW_DIGIT:
  LD A,(DE)
  AND $0F
  CALL PLOT_TILE
  INC DE
  DJNZ DRAW_DIGITS
  RET
; DRAW_SCORE and DRAW_SCORE_AT are entered on their own to redraw the score
; without changing it, and DRAW_DIGITS is the general digit printer: B bytes of
; BCD from DE, drawn at the screen address in HL. The status panel uses that
; last entry to print the rooms-explored figure from COUNT_ROOMS_EXPLORED as
; well.

; Plot one 8x8 tile and step right
;
; Used by the routines at ADD_SCORE, PRINT_STRING and DRAW_SCROLL.
;
; Copies eight bytes from the current tile source to a character cell. The
; source base is the pointer at $5E01, so the meaning of the tile code depends
; on what that currently points at -- see PLOT_TILE's note below.
;
; A Tile code; the source is ($5E01) + A * 8
; HL Display file address of the cell to draw into. On exit, advanced to the
;    next cell to the right.
PLOT_TILE:
  PUSH BC
  PUSH DE
  PUSH HL
  LD L,A                  ; A * 8 -- eight bytes per tile.
  LD H,$00                ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  ADD HL,HL               ;
  LD DE,(TILE_SOURCE)     ; The current tile source. Not a fixed font: callers
                          ; repoint it.
  ADD HL,DE
  EX DE,HL
  POP HL
  LD B,$08                ; INC H walks down the eight scan lines of a
PLOT_TILE_0:
  LD A,(DE)               ; character cell, which works because the cell never
  LD (HL),A               ; crosses a third boundary.
  INC DE                  ;
  INC H                   ;
  DJNZ PLOT_TILE_0        ;
  POP DE
  POP BC
  LD A,H                  ; Undo the eight INC Hs, then INC L to land on the
  SUB $08                 ; next cell to the right.
  LD H,A                  ;
  INC L
  RET
; The tile source at $5E01 is deliberately biased by its callers. Initialised
; to TEXT_FONT less $100, where a tile code is simply an ASCII character, it is
; repointed during play -- while the score is on screen it holds FONT_DIGITS,
; which is TEXT_FONT + $80, so that a raw digit 0-9 indexes the characters '0'
; to '9' directly with no adjustment at the call site.

; Print a string of tiles in a single colour
;
; Used by the routines at DRAW_MENU, GAME_OVER, DRAW_SUMMARY and
; SHOW_END_SCREEN.
;
; Draws consecutive tiles left to right, writing one attribute byte per cell as
; it goes. It keeps the display address and the attribute address live at the
; same time in the two register banks, swapping with EXX between the pixel
; write and the colour write rather than recomputing either.
;
; HL H = y (0-191), L = x -- where to start
; DE The string: one attribute byte, then the tile codes. Bit 7 set on a code
;    marks it as the last one.
PRINT_STRING:
  PUSH HL
  CALL PIXEL_TO_SCREEN    ; Display address into the main bank...
  LD A,(DE)               ; The first byte is the colour, not a character; it
  EX AF,AF'               ; is kept in A' for the whole run.
  INC DE                  ;
  EXX
  POP HL
  CALL PIXEL_TO_ATTR      ; ...and the attribute address into the alternate
                          ; one.
; This entry point is used by the routine at PRINT_MENU_LINE.
PRINT_STRING_REST:
  EXX                     ; }
  LD A,(DE)
  BIT 7,A                 ; Bit 7 is the end marker, not part of the code.
  JR NZ,PRINT_STRING_0
  CALL PLOT_TILE
  INC DE
  EXX
  EX AF,AF'
  LD (HL),A               ; Colour the cell PLOT_TILE just drew into.
  INC L                   ;
  EX AF,AF'
  JR PRINT_STRING_REST
PRINT_STRING_0:
  AND $7F                 ; Strip the end marker before drawing the final
                          ; character.
  CALL PLOT_TILE
  EXX
  EX AF,AF'
  LD (HL),A
  RET

; Draw the scroll down the side of the screen
;
; Used by the routine at START_GAME.
;
; Points the tile source at PANEL_TILES -- a set of tiles of its own, not the
; text font -- and lays out an eight by twenty-four block of them from
; PANEL_LAYOUT at x $C0. The parchment border, drawn once when a game starts
; and left alone after that.
DRAW_SCROLL:
  LD HL,PANEL_TILES
  LD (TILE_SOURCE),HL
  LD HL,$00C0
  LD DE,PANEL_LAYOUT
  LD BC,$0818
DRAW_SCROLL_0:
  PUSH BC
  PUSH HL
  CALL PIXEL_TO_SCREEN
DRAW_SCROLL_1:
  LD A,(DE)
  INC DE
  CALL PLOT_TILE
  DJNZ DRAW_SCROLL_1
  POP HL
  LD A,H
  ADD A,$08
  LD H,A
  POP BC
  DEC C
  JR NZ,DRAW_SCROLL_0
  JP DRAW_SCORE

; Colour the status panel to go with the room
;
; Used by the routine at ENTER_ROOM.
;
; The third and last step of a room change, after CLEAR_PLAY_AREA and
; DRAW_ROOM. It writes attributes only -- the scroll, the timer and the score
; are drawn elsewhere and simply take whatever colour is underneath them, which
; is why walking into a differently-coloured room recolours the whole panel
; without anything being redrawn.
;
; The colour is the room's own ink complemented: CPL then AND $07 keeps just
; the three ink bits and inverts them, so a red room gives a cyan panel, green
; gives magenta and so on. Complementing also throws away the bright and paper
; bits, which is why the panel comes out one shade darker than the room
; outline.
;
; Inks 0 and 1 -- black and blue -- would be unreadable against black paper, so
; anything below 2 is replaced outright by $44, bright green. Measured by
; writing each room colour into $5E1A in turn and re-running: $42 gives $05,
; $43 gives $04, $44 gives $03, $45 gives $02, and $46 and $47 both give $44.
PAINT_PANEL:
  LD HL,$00C0             ; x = 192, the first character column past the play
  CALL PIXEL_TO_ATTR      ; area.
  LD BC,$0818             ; 8 columns wide, 24 rows deep -- the rest of the
                          ; screen.
  LD A,(ROOM_COLOUR)      ; The room's colour, inverted.
  CPL                     ;
  AND $07                 ;
  CP $02                  ; Too dark to read against black...
  JR NC,PAINT_PANEL_0     ;
  LD A,$44                ; ...so use bright green instead.
PAINT_PANEL_0:
  LD E,A
  PUSH DE
PAINT_PANEL_1:
  PUSH BC
  PUSH HL
PAINT_PANEL_2:
  LD (HL),E               ; Fill one row of the panel.
  INC L                   ;
  DJNZ PAINT_PANEL_2      ;
  POP HL
  LD BC,$0020             ; 32 bytes to the row below.
  ADD HL,BC               ;
  POP BC
  DEC C
  JR NZ,PAINT_PANEL_1
  LD HL,$90C8             ; The little blocks below the scroll are coloured
  CALL PIXEL_TO_ATTR      ; separately...
  LD A,(ROOM_COLOUR)      ; ...in the room's own colour rather than the
  LD BC,$0303             ; complement.
  CALL FILL_BLOCK         ;
  INC L
  LD (HL),A
  ADD HL,DE
  LD BC,$0202
  CALL FILL_BLOCK
  LD HL,$98D0             ; One cell on its own.
  CALL PIXEL_TO_ATTR
  POP DE
  LD (HL),E
  LD HL,$7DC8
  CALL PIXEL_TO_ATTR
  LD BC,$0603             ; Bright white, for the part that never changes.
  LD A,$47                ;
  CALL FILL_BLOCK
  LD HL,$5FC8
  CALL PIXEL_TO_ATTR
  LD BC,$0604
  LD A,$46
  CALL FILL_BLOCK
  LD HL,$48C8
  CALL PIXEL_TO_ATTR
  LD BC,$0601
  LD A,$45
  CALL FILL_BLOCK
  LD BC,$0601
  LD A,$47
  CALL FILL_BLOCK
  LD HL,$38C8
  CALL PIXEL_TO_ATTR
  LD BC,$0601
  LD A,$43
  CALL FILL_BLOCK
  LD BC,$0601
  LD A,$47
  JP FILL_BLOCK

; Draw the remaining lives on the scroll
;
; Used by the routines at START_GAME and PLACE_PLAYER.
;
; Draws up to three small figures at the foot of the panel, sixteen pixels
; apart, in whichever character the player chose. The count comes from $5E21,
; and the loop always runs three times: the slots past the count are drawn over
; rather than skipped, so a life that has just been lost is erased.
;
; The sprite is worked out from the menu selection rather than stored. $5E00
; holds the character in bits 3 and 4, so shifting it up one and masking to $30
; gives $00, $10 or $20, and setting bit 0 makes it $01, $11 or $21 -- the
; first sprite of the knight, the wizard and the serf. Checked by starting a
; game as each: $5E00 reads $00, $08 and $10 and the player's own sprite byte
; comes out $08, $18 and $28, seven along from those bases.
DRAW_LIVES:
  PUSH IX
  LD IX,UI_RECORD         ; Not an actor, so borrow UI_RECORD to draw from.
  LD A,(SELECTION)        ; Turn the menu selection into the chosen character's
  RLCA                    ; first sprite.
  AND $30                 ;
  OR $01                  ;
  LD (IX+$00),A           ; Bright white.
  LD (IX+$05),$47
  LD HL,$8DC8             ; The foot of the scroll: x = 200, y = 141.
  LD (IX+$03),L           ; The record wants x then y, and HL holds them the
  LD (IX+$04),H           ; other way round.
  LD A,(LIVES)            ; Lives remaining, but three slots regardless.
  LD C,A                  ;
  LD B,$03                ;
DRAW_LIVES_0:
  PUSH BC
  CALL ERASE_STRIP
  LD A,C
  AND A
  JR Z,DRAW_LIVES_1
  CALL DRAW_THING
DRAW_LIVES_1:
  LD A,(IX+$03)           ; Sixteen pixels along for the next one.
  ADD A,$10               ;
  LD (IX+$03),A           ;
  POP BC
  DEC C                   ; Once the count runs out it stays at zero, and the
  JP P,DRAW_LIVES_2       ; rest are blanks.
  LD C,$00
DRAW_LIVES_2:
  DJNZ DRAW_LIVES_0
  POP IX
  RET

; Draw the nine pictures on the title screen
;
; Used by the routine at TITLE_SCREEN.
;
; Works through TITLE_ICONS, copying each eight-byte record into UI_RECORD and
; drawing it. Nine records, but only six pictures: the three control methods
; are each too wide for one sprite and are drawn as two halves side by side,
; while the three characters below are one sprite each.
DRAW_TITLE_ICONS:
  LD IX,UI_RECORD         ; Everything is drawn from the same scratch record...
  LD HL,TITLE_ICONS       ; ...one copy of it at a time.
  LD B,$09                ;
DRAW_TITLE_ICONS_0:
  PUSH BC
  LD DE,UI_RECORD         ; Eight bytes: the whole record.
  LD BC,$0008             ;
  LDIR                    ;
  PUSH HL
  PUSH DE
  CALL DRAW_THING         ; Put it on the screen, then its colours.
  CALL WORKSPACE_AND_DRAW ;
  POP DE
  POP HL
  POP BC
  DJNZ DRAW_TITLE_ICONS_0
  RET

; The nine pictures on the title screen
;
; Nine records of eight bytes, in the ordinary short form -- sprite, room,
; flag, x, y, drawing mode. Read out of the game: sprites $48 and $49 make the
; keyboard at the top, $4A and $4B the joystick, $32 and $33 the cursor keys,
; and then $01, $11 and $21 draw the knight, the wizard and the serf down the
; left, at the very sprite numbers DRAW_LIVES computes from the menu selection.
TITLE_ICONS:
  DEFB $32,$00,$00,$20,$4F,$46,$00,$00
  DEFB $33,$00,$00,$30,$4F,$46,$00,$00
  DEFB $4A,$00,$00,$20,$37,$44,$00,$00
  DEFB $4B,$00,$00,$30,$37,$44,$00,$00
  DEFB $48,$00,$00,$20,$1C,$43,$00,$00
  DEFB $49,$00,$00,$30,$1C,$43,$00,$00
  DEFB $01,$00,$00,$28,$67,$47,$00,$00
  DEFB $11,$00,$00,$28,$7F,$47,$00,$00
  DEFB $21,$00,$00,$28,$97,$47,$00,$00

; Another multiply
;
; Used by the routine at DRAW_LINE.
;
; The same shift-and-add as MULTIPLY, kept separately for the sound routines so
; that they do not disturb the registers the drawing code is using.
MULTIPLY_2:
  LD L,H
  LD H,$00
  EXX
  LD HL,$0000
  LD B,$08
MULTIPLY_2_0:
  EXX
  SLA L
  RL H
  PUSH HL
  AND A
  SBC HL,DE
  JR C,MULTIPLY_2_2
  POP AF
  EXX
  ADD HL,HL
  INC HL
MULTIPLY_2_1:
  DJNZ MULTIPLY_2_0
  PUSH HL
  EXX
  LD E,L
  LD D,H
  POP HL
  RET
MULTIPLY_2_2:
  POP HL
  EXX
  ADD HL,HL
  JR MULTIPLY_2_1

; Negate HL
;
; Used by the routine at DRAW_LINE.
;
; Subtracts HL from zero, which is the shortest way the Z80 has of negating a
; sixteen-bit value.
NEGATE_HL:
  PUSH DE
  EX DE,HL
  LD HL,$0000
  AND A
  SBC HL,DE
  POP DE
  RET

; Square wave on the beeper
;
; Used by the routines at TRAPDOOR_FALL, SOUND_SWEEP_A41B, SOUND_SWEEP_UP,
; SOUND_SWEEP_DOWN and SOUND_SPELL.
;
; Toggles bit 4 of port $FE with a busy-wait either side, which is the only way
; a 48K makes a sound. Every sound effect in the game is a call here, or a
; short sequence of them with different pitches.
;
; B Half-period: the delay between edges, so smaller is higher pitched
; C Number of complete cycles, i.e. how long the note lasts
BEEP:
  LD C,$01                ; The plain entry point plays exactly one cycle;
                          ; callers wanting a longer note enter below with C
                          ; already set.
; This entry point is used by the routines at BEEP_ENTRIES, SOUND_FOOTSTEP,
; SOUND_BONUS, SOUND_64, SOUND_65, SOUND_FROM_HEADING, SOUND_A0 and
; SOUND_SPELL_2.
BEEP_BC:
  LD A,$10                ; Speaker bit high.
  OUT ($FE),A             ;
  PUSH BC
BEEP_0:
  DJNZ BEEP_0             ; The pitch: burn B iterations doing nothing.
  POP BC
  PUSH BC
  XOR A                   ; Speaker bit low again. This also writes 0 to the
  OUT ($FE),A             ; border bits, which is why the border stays black
                          ; through every effect.
BEEP_1:
  DJNZ BEEP_1
  POP BC
  DEC C                   ; Repeat for C cycles.
  JR NZ,BEEP_BC           ;
  RET

; Two more ways into BEEP
;
; Used by the routine at REMEMBER_CARRIED.
;
; Each loads a pitch and a length and drops into BEEP a few bytes above, the
; same shape as the two footstep branches. $4040 is one long note; $2080 is a
; shorter, higher one. Reached from the JP at REMEMBER_CARRIED+35.
BEEP_ENTRIES:
  LD BC,$4040             ; One long note.
  JR BEEP_BC              ;
; This entry point is used by the routine at DROP_CARRIED.
SHORT_HIGH_BEEP:
  LD BC,$2080             ; Shorter and higher.
  JR BEEP_BC              ;

; The footstep, two tones alternating
;
; Used by the routines at UPDATE_WIZARD, UPDATE_SERF and UPDATE_KNIGHT.
;
; Called every frame by all three characters' handlers -- UPDATE_KNIGHT,
; UPDATE_WIZARD and UPDATE_SERF -- so walking sounds the same whoever is doing
; it. A counter at $5E2F advances on every call and its bottom two bits do all
; the work: bit 0 decides whether to make a sound at all, so only every other
; call does, and bit 1 chooses which of two notes.
;
; The two are $6004 and $4004 -- four cycles each, of half-period $60 and $40
; -- which measure at about 1360 Hz and 2005 Hz. They alternate, so a walking
; character produces low, high, low, high rather than one repeated click. That
; is the whole footstep: two tones and a counter.
;
; None; it reads and advances $5E2F itself
SOUND_FOOTSTEP:
  LD HL,STEP_COUNTER      ; The step counter, advanced on every call.
  INC (HL)                ;
  LD A,(HL)               ;
  BIT 1,A                 ; Bit 1 picks the note.
  JR Z,SOUND_FOOTSTEP_0   ;
  AND $01                 ; Bit 0 silences every other call, which is what sets
  RET Z                   ; the pace.
  LD BC,$4004             ; The higher of the two, about 2005 Hz.
  JR BEEP_BC              ;
SOUND_FOOTSTEP_0:
  AND $01                 ; The same gate on the other branch.
  RET Z                   ;
  LD BC,$6004             ; The lower, about 1360 Hz.
  JR BEEP_BC              ;

; The note that goes with the flashing score
;
; Used by the routine at FLASH_SCORE.
;
; One call from FLASH_SCORE, once every sixteen steps of its countdown. BC is
; $8060 -- half-period $80, and $60 is 96 cycles of it -- which measures as 96
; milliseconds at about 1030 Hz: a clear steady pip rather than a sweep, and
; long enough to be heard over everything else.
SOUND_BONUS:
  LD BC,$8060
  JR BEEP_BC

; Start a sound effect
;
; Used by the routines at CHECK_HIT and MUSHROOM_DRAIN.
;
; A sound is not played here and it is not played by a scheduler either: it is
; spawned as an actor. This writes a sprite and a count into the record at
; $EAA0, and from the next frame on the dispatcher finds it there like any
; other creature and calls its handler, which beeps once, counts down, and
; frees the slot when it reaches zero.
;
; So the second byte is a duration in frames rather than the room number the
; same field holds in every other record, and the sprite is one of the codes
; that draws nothing -- $64, $65 and $A0 are sounds wearing an actor's clothes.
;
; Three routines share the tail with different values: $6410 here, $650A from
; PLAY_SOUND_65 and $A010 from PLAY_SOUND_A0. Watched live, writing $64 and $10
; into the two bytes by hand makes the count fall 0C, 07, 03 over the following
; frames and then the slot empties itself.
;
; BC B = which sound, C = how many frames it lasts
PLAY_SOUND:
  LD BC,$6410             ; This entry's sound and length.
; This entry point is used by the routines at PLAY_SOUND_65 and PLAY_SOUND_A0.
PLAY_SOUND_BC:
  LD HL,SOUND_SLOT        ; Sprite first, then the count -- the field an
  LD (HL),B               ; ordinary record uses for its room.
  INC HL                  ;
  LD (HL),C               ;
  RET

; Sound $64, one frame of it
;
; Called once a frame while the sound lasts. The pitch is taken from however
; much of the countdown is left, so the note slides as it plays rather than
; holding steady, and the same handler gives a different sweep for a different
; starting count.
;
; IX The sound's record
SOUND_64:
  DEC (IX+$01)            ; One frame less to go; at zero the sound is over.
  JR Z,END_SOUND          ;
  LD A,(IX+$01)           ; What is left of the count is how many cycles to
  LD C,A                  ; sound.
  XOR $43                 ; And, folded about $43, the pitch -- so it glides.
  LD B,A                  ;
  JP BEEP_BC              ; Into BEEP, entered below its own first instruction
                          ; so the cycle count survives.

; Free the slot when a sound finishes
;
; Used by the routines at SOUND_64, SOUND_65 and SOUND_A0.
;
; Zeroing the sprite is all it takes: the dispatcher skips a record with sprite
; $00, so the sound simply stops being found. Shared by all three sound
; handlers.
END_SOUND:
  LD (IX+$00),$00
  RET

; Start sound $65
;
; Used by the routine at ENTER_ROOM.
;
; Hands $650A to PLAY_SOUND's tail: sound $65, lasting ten frames.
PLAY_SOUND_65:
  LD BC,$650A
  JR PLAY_SOUND_BC

; Sound $65, one frame of it
;
; The same shape as SOUND_64 with the pitch derived differently -- three
; rotations, complemented, folded about $40 -- which is what makes it a
; different effect rather than the same one at another speed.
SOUND_65:
  DEC (IX+$01)            ; Counting down.
  JR Z,END_SOUND          ;
  LD A,(IX+$01)           ; Cycles from the count.
  LD C,A                  ;
  RLCA                    ; Pitch from the count as well, but along a different
  RLCA                    ; curve.
  RLCA                    ;
  CPL                     ;
  XOR $40                 ;
  LD B,A                  ;
  JP BEEP_BC

; A short sweep
;
; Used by the routine at TRY_FIRE_THIRD.
;
; Twelve steps of BEEP with the pitch walked down, about nine milliseconds.
; Reached from TRY_FIRE_THIRD, so it is one of the three firing noises.
SOUND_SWEEP_A41B:
  LD D,$0C
SOUND_SWEEP_A41B_0:
  LD A,D
  RRCA
  LD B,A
  CALL BEEP
  DEC D
  JR NZ,SOUND_SWEEP_A41B_0
  RET

; A rising sweep
;
; Used by the routine at TRY_FIRE.
;
; Sixteen calls to BEEP with the pitch walked from one end to the other, so the
; note climbs. Measured at roughly 16 milliseconds, sweeping from about 500 Hz
; upwards. Reached from the serf's handler by way of TRY_FIRE.
SOUND_SWEEP_UP:
  LD D,$10                ; Sixteen steps.
SOUND_SWEEP_UP_0:
  LD A,D                  ; The pitch for this step, derived from the step
  RLCA                    ; number.
  RLCA                    ;
  XOR $07                 ;
  RLCA                    ;
  RLCA                    ;
  LD B,A
  CALL BEEP               ; One short note.
  DEC D
  JR NZ,SOUND_SWEEP_UP_0
  RET

; A short falling sweep
;
; Used by the routine at TRY_FIRE_ALT.
;
; Eight steps rather than sixteen, and the pitch complemented so it falls where
; SOUND_SWEEP_UP rises. About 14 milliseconds, and barely moving -- 520 to 556
; Hz -- so it lands as a blip rather than a slide.
SOUND_SWEEP_DOWN:
  LD D,$08                ; Eight steps.
SOUND_SWEEP_DOWN_0:
  LD A,D                  ; Complemented, so the pitch falls.
  CPL                     ;
  RLCA                    ;
  LD B,A
  CALL BEEP               ; One short note.
  DEC D
  JR NZ,SOUND_SWEEP_DOWN_0
  RET

; The wizard's spell
;
; Used by the routine at SPIN_SPELL.
;
; Called from SPIN_SPELL, along with SOUND_SPELL_2. Unlike the fixed sweeps
; this one takes its starting pitch from $5E25, the count of actors in the
; room, so the spell does not sound quite the same twice. Measured at about 6
; milliseconds across 1900 to 3700 Hz.
SOUND_SPELL:
  LD A,(ACTORS_HERE)
  INC A
  RLCA
  RLCA
  RLCA
  RLCA
  OR $0F
  AND $7F
  LD D,A
SOUND_SPELL_0:
  LD A,D
  XOR $20
  LD B,A
  CALL BEEP
  DEC D
  RET Z
  DEC D
  RET Z
  JR SOUND_SPELL_0

; A sound whose pitch comes from a creature's heading
;
; Used by the routine at MATERIALISING.
;
; Takes +$06, complements and masks it, and uses the result as the half-period
; -- so the noise a thing makes depends on which way it is going.
SOUND_FROM_HEADING:
  LD A,(IX+$06)
  CPL
  RLCA
  AND $3F
  OR $40
  LD B,A
  LD C,$10
  JP BEEP_BC

; A short burst of noise
;
; Used by the routines at WAIT_THEN_ACT and FLASH_AND_RASP.
;
; Run from a cold machine it lasts about 8 milliseconds and puts out 119
; speaker edges with the gaps between them swinging wildly -- 843 Hz at the
; widest and far above hearing at the narrowest. That is not a note; it is a
; rasp.
;
; Reached from FLASH_AND_RASP, and by JP rather than CALL, so it returns to
; whoever called that rather than to the jump. That also makes it awkward to
; capture on its own during play: there is no return address on the stack to
; stop at. An earlier note put the caller at WAIT_THEN_ACT, which was wrong --
; the call site sits inside a block the automatic pass had left as data, so it
; was attributed to the nearest entry above it.
;
; An earlier note here claimed this was a full second of sound sweeping the
; audible range, which was wrong. The measurement behind it came from running
; several sound routines in turn on one machine, so this one inherited the
; state the others left and took a longer path than it ever does in the game.
SOUND_NOISE_BURST:
  LD BC,$0830
  LD HL,$0000
SOUND_NOISE_BURST_0:
  LD E,(HL)
  INC HL
  PUSH BC
SOUND_NOISE_BURST_1:
  RRC E
  LD A,E
  AND $10
  OUT ($FE),A
  DJNZ SOUND_NOISE_BURST_1
  POP BC
  DEC C
  JR NZ,SOUND_NOISE_BURST_0
  RET

; Start sound $A0
;
; Used by the routine at EAT_FOOD.
;
; Hands $A010 to the same tail: sound $A0, sixteen frames.
PLAY_SOUND_A0:
  LD BC,$A010
  JP PLAY_SOUND_BC

; Sound $A0, one frame of it
;
; The third of the sound handlers, alongside SOUND_64 and SOUND_65. It takes
; its pitch from a table at SWEEP_PITCHES rather than computing it, so its
; sweep is a shape someone chose rather than an arithmetic accident.
SOUND_A0:
  DEC (IX+$01)
  JP M,END_SOUND
  LD C,(IX+$01)
  LD B,$00
  LD HL,SWEEP_PITCHES
  ADD HL,BC
  LD B,(HL)
  LD C,$08
  JP BEEP_BC

; The pitches the sweep steps through
;
; $80 and $90 alternating four times, then $80 walked down to $10 in steps of
; $10. So the sound wavers on one note and then climbs away from it, which is
; cheaper than computing a curve and is why the sweep sounds the way it does
; rather than gliding smoothly.
SWEEP_PITCHES:
  DEFB $80,$90,$80,$90,$80,$90,$80,$90,$80,$70,$60,$50,$40,$30,$20,$10

; The spell's second noise
;
; Used by the routine at SPIN_SPELL.
;
; The other of the two sounds SPIN_SPELL makes, alongside SOUND_SPELL.
SOUND_SPELL_2:
  LD D,$40
  DEC D
  RET Z
  LD A,D
  RRCA
  RRCA
  RRCA
  LD B,A
  LD C,$04
  JP BEEP_BC

; The address of every sprite's graphics
;
; 239 addresses, two bytes each, indexed by sprite number less one, running
; from SPRITE_TABLE up to the graphics. The graphics themselves start
; immediately after it.
;
; It is three tables end to end, which is why the count is 239. The first 161
; entries, up to FURNITURE_SPRITES, are the creatures and objects -- two bytes
; wide, one byte of row count. The next 39, from FURNITURE_SPRITES, are the
; pieces the rooms are furnished with, which carry a width as well. The last
; 39, from FURNITURE_COLOURS, are not pictures at all: they are those same
; pieces' attribute tables, one colour per character cell in the same
; width-and-height format.
;
; Entry N of the third table belongs to entry N of the second, which is how one
; picture serves four doors: $A9 to $AC all point at the graphic at GFX_A9 and
; differ only in their colours -- $43 $42 for red, $44 green, $45 cyan, $46
; yellow. The three bases the code uses, SPRITE_TABLE, FURNITURE_SPRITES and
; FURNITURE_COLOURS, are not a bias trick after all; they are simply where each
; table starts.
;
; The count is measured rather than assumed: every code was drawn on a machine
; of its own with its reads logged, and 239 is the highest whose entry points
; at something the drawing code can read. Entries beyond that hold values like
; $1804 and $33F8, which are not addresses in this game at all.
;
; FETCH_SPRITE and FETCH_SPRITE_ATTRS were read here as biased views of a
; single table, on the grounds that FURNITURE_SPRITES is its 161st entry and
; FURNITURE_COLOURS its 200th. That is arithmetically true and the wrong way
; round: they are separate tables, and the arithmetic works because they follow
; each other.
SPRITE_TABLE:
  DEFW GFX_01,GFX_02,GFX_03,GFX_02
  DEFW GFX_05,GFX_06,GFX_07,GFX_06
  DEFW GFX_09,GFX_0A,GFX_0B,GFX_0A
  DEFW GFX_0D,GFX_0E,GFX_0F,GFX_0E
  DEFW GFX_11,GFX_12,GFX_13,GFX_12
  DEFW GFX_15,GFX_16,GFX_17,GFX_16
  DEFW GFX_19,GFX_1A,GFX_1B,GFX_1A
  DEFW GFX_1D,GFX_1E,GFX_1F,GFX_1E
  DEFW GFX_21,GFX_22,GFX_23,GFX_22
  DEFW GFX_25,GFX_26,GFX_27,GFX_26
  DEFW GFX_29,GFX_2A,GFX_2B,GFX_2A
  DEFW GFX_2D,GFX_2E,GFX_2F,GFX_2E
  DEFW GFX_31,GFX_32,GFX_33,GFX_34
  DEFW GFX_35,GFX_35,GFX_37,GFX_38
  DEFW GFX_39,GFX_3A,GFX_3B,GFX_3C
  DEFW GFX_3D,GFX_3E,GFX_3F,GFX_40
  DEFW GFX_41,GFX_42,GFX_43,GFX_44
  DEFW GFX_45,GFX_46,GFX_47,GFX_48
  DEFW GFX_49,GFX_4A,GFX_4B,GFX_4C
  DEFW GFX_4D,GFX_4E,GFX_4F,GFX_50
  DEFW GFX_51,GFX_52,GFX_53,GFX_54
  DEFW GFX_55,GFX_56,GFX_57,GFX_58
  DEFW GFX_59,GFX_5A,GFX_5B,GFX_5C
  DEFW GFX_5D,GFX_5E,GFX_5F,GFX_60
  DEFW GFX_61,GFX_62,GFX_63,NO_GRAPHIC
  DEFW NO_GRAPHIC,NO_GRAPHIC,NO_GRAPHIC,GFX_68
  DEFW GFX_69,GFX_6A,GFX_6B,GFX_6C
  DEFW GFX_6D,GFX_6E,GFX_6F,GFX_70
  DEFW GFX_71,GFX_72,GFX_71,GFX_74
  DEFW GFX_75,GFX_76,GFX_75,GFX_78
  DEFW GFX_79,GFX_7A,GFX_79,GFX_7C
  DEFW GFX_7D,GFX_7E,GFX_7D,GFX_80
  DEFW GFX_81,GFX_82,GFX_83,GFX_84
  DEFW GFX_85,GFX_86,GFX_87,GFX_88
  DEFW GFX_89,GFX_8A,GFX_8B,GFX_8C
  DEFW GFX_8D,GFX_8E,GFX_8F,GFX_90
  DEFW GFX_91,GFX_92,GFX_93,GFX_94
  DEFW GFX_95,GFX_96,GFX_97,GFX_98
  DEFW GFX_99,GFX_9A,GFX_9B,GFX_9C
  DEFW GFX_9D,GFX_9E,GFX_9D,NO_GRAPHIC
  DEFW GFX_A1
FURNITURE_SPRITES:
  DEFW GFX_A2,GFX_A3,GFX_A4,NO_GRAPHIC
  DEFW NO_GRAPHIC,NO_GRAPHIC,NO_GRAPHIC,GFX_A9
  DEFW GFX_A9,GFX_A9,GFX_A9,GFX_AD
  DEFW GFX_AD,GFX_AD,GFX_AD,GFX_B1
  DEFW GFX_B2,GFX_B3,GFX_B4
ROAST_SPRITE:
  DEFW GFX_B5             ; The roast chicken's entry, which DRAW_FOOD moves on
                          ; past the rows eaten
  DEFW GFX_B6,GFX_B7,GFX_B8,GFX_B9
  DEFW GFX_BA,GFX_BB,GFX_BC,GFX_BD
  DEFW GFX_BE,GFX_BF,NO_GRAPHIC,GFX_C1
  DEFW GFX_A3,GFX_C3,GFX_A2,GFX_C5
  DEFW GFX_C6,GFX_C7,GFX_C8
FURNITURE_COLOURS:
  DEFW ATTRS_C9,ATTRS_CA,ATTRS_CB,NO_GRAPHIC
  DEFW NO_GRAPHIC,NO_GRAPHIC,NO_GRAPHIC,ATTRS_D0
  DEFW ATTRS_D1,ATTRS_D2,ATTRS_D3,ATTRS_D4
  DEFW ATTRS_D5,ATTRS_D6,ATTRS_D7,ATTRS_D8
  DEFW ATTRS_D9,ATTRS_DA,NO_GRAPHIC,NO_GRAPHIC
  DEFW ATTRS_DD,ATTRS_DE,ATTRS_DF,ATTRS_E0
  DEFW ATTRS_E1,ATTRS_E2,ATTRS_E3,ATTRS_E4
  DEFW ATTRS_E5,ATTRS_E6,NO_GRAPHIC,ATTRS_E8
  DEFW ATTRS_CA,ATTRS_EA,ATTRS_C9,ATTRS_EC
  DEFW ATTRS_ED,ATTRS_EE,ATTRS_EF

; Door, locked, red, drawn for sprite $A9, $AA, $AB, $AC
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
;
; Shared by 4 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_A9:
  DEFB $04,$18
  DEFB $FF,$1B,$30,$FF
  DEFB $1F,$1B,$30,$F8
  DEFB $02,$1B,$30,$40
  DEFB $3E,$1B,$30,$7C
  DEFB $7F,$33,$18,$3E
  DEFB $07,$33,$18,$20
  DEFB $F8,$33,$18,$1F
  DEFB $F8,$33,$00,$1F
  DEFB $08,$63,$07,$08
  DEFB $F0,$63,$17,$0F
  DEFB $F0,$63,$19,$0F
  DEFB $1E,$63,$0E,$08
  DEFB $FE,$C3,$00,$1F
  DEFB $F8,$C3,$06,$1F
  DEFB $CC,$C3,$06,$33
  DEFB $3E,$C3,$06,$7C
  DEFB $7D,$80,$01,$BE
  DEFB $3B,$F0,$0F,$DC
  DEFB $17,$BF,$FD,$E8
  DEFB $07,$7B,$DE,$E0
  DEFB $03,$7B,$DE,$C0
  DEFB $00,$77,$EE,$00
  DEFB $00,$07,$E0,$00
  DEFB $00,$00,$00,$00

; Colours for a graphic, entry $D0 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D0:
  DEFB $04,$03
  DEFB $43,$42,$42,$43
  DEFB $43,$42,$46,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $D1 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D1:
  DEFB $04,$03
  DEFB $43,$44,$44,$43
  DEFB $43,$44,$46,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $D2 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D2:
  DEFB $04,$03
  DEFB $43,$45,$45,$43
  DEFB $43,$45,$46,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $D3 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D3:
  DEFB $04,$03
  DEFB $43,$46,$46,$43
  DEFB $43,$46,$43,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $D4 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D4:
  DEFB $04,$03
  DEFB $FF,$42,$42,$FF
  DEFB $FF,$42,$46,$FF
  DEFB $FF,$FF,$FF,$FF

; Colours for a graphic, entry $D5 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D5:
  DEFB $04,$03
  DEFB $FF,$44,$44,$FF
  DEFB $FF,$44,$46,$FF
  DEFB $FF,$FF,$FF,$FF

; Colours for a graphic, entry $D6 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D6:
  DEFB $04,$03
  DEFB $FF,$45,$45,$FF
  DEFB $FF,$45,$46,$FF
  DEFB $FF,$FF,$FF,$FF

; Colours for a graphic, entry $D7 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D7:
  DEFB $04,$03
  DEFB $FF,$46,$46,$FF
  DEFB $FF,$46,$43,$FF
  DEFB $FF,$FF,$FF,$FF

; Door frame, drawn for sprite $A3, $C2
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_A3:
  DEFB $04,$18
  DEFB $FF,$00,$00,$FF
  DEFB $1F,$00,$00,$F8
  DEFB $02,$00,$00,$40
  DEFB $3E,$00,$00,$7C
  DEFB $7C,$00,$00,$3E
  DEFB $04,$00,$00,$20
  DEFB $F8,$00,$00,$1F
  DEFB $F8,$00,$00,$1F
  DEFB $08,$00,$00,$08
  DEFB $F0,$00,$00,$0F
  DEFB $F0,$00,$00,$0F
  DEFB $10,$00,$00,$08
  DEFB $F0,$00,$00,$1F
  DEFB $F8,$00,$00,$1F
  DEFB $CC,$00,$00,$33
  DEFB $3E,$00,$00,$7C
  DEFB $7D,$80,$01,$BE
  DEFB $3B,$F0,$0F,$DC
  DEFB $17,$BF,$FD,$E8
  DEFB $07,$7B,$DE,$E0
  DEFB $03,$7B,$DE,$C0
  DEFB $00,$77,$EE,$00
  DEFB $00,$07,$E0,$00
  DEFB $00,$00,$00,$00

; Colours for a graphic, entry $CA, $E9 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
ATTRS_CA:
  DEFB $04,$03
  DEFB $43,$00,$00,$43
  DEFB $43,$00,$00,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $C9, $EB of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
ATTRS_C9:
  DEFB $04,$03
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF

; Table, drawn for sprite $B3
;
; 22 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B3:
  DEFB $04,$16
  DEFB $60,$00,$00,$06
  DEFB $70,$00,$00,$0E
  DEFB $30,$00,$00,$0C
  DEFB $30,$00,$00,$0C
  DEFB $70,$00,$00,$0E
  DEFB $70,$00,$00,$0E
  DEFB $78,$00,$00,$1E
  DEFB $3F,$FF,$FF,$FC
  DEFB $7F,$FF,$FF,$FE
  DEFB $80,$00,$00,$01
  DEFB $7F,$FF,$FF,$FE
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF
  DEFB $7F,$FF,$FF,$FE
  DEFB $7F,$FF,$FF,$FE
  DEFB $7F,$FF,$FF,$FE
  DEFB $3F,$FF,$FF,$FC
  DEFB $3F,$FF,$FF,$FC
  DEFB $1F,$FF,$FF,$F8
  DEFB $1F,$FF,$FF,$F8
  DEFB $0F,$FF,$FF,$F0

; Colours for a graphic, entry $DA of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_DA:
  DEFB $04,$03
  DEFB $45,$45,$45,$45
  DEFB $42,$42,$42,$42
  DEFB $42,$42,$42,$42

; Colour and shape of each room
;
; Two bytes per room, indexed by room number: the first is the attribute the
; whole play area is filled with, the second is an index into ROOM_SHAPES. With
; 152 rooms sharing a much smaller set of outlines, this is most of what makes
; the castle fit in memory.
ROOM_TABLE:
  DEFB $42,$00,$43,$02,$44,$03,$45,$02
  DEFB $46,$04,$47,$02,$46,$03,$45,$02
  DEFB $44,$04,$43,$00,$42,$03,$43,$03
  DEFB $44,$03,$45,$00,$46,$04,$47,$04
  DEFB $46,$04,$45,$04,$44,$04,$43,$00
  DEFB $42,$03,$43,$03,$44,$03,$45,$00
  DEFB $46,$04,$47,$03,$46,$05,$45,$00
  DEFB $44,$08,$43,$01,$42,$04,$43,$02
  DEFB $44,$03,$45,$02,$46,$04,$47,$02
  DEFB $46,$03,$45,$02,$44,$05,$43,$00
  DEFB $42,$04,$43,$00,$44,$03,$45,$00
  DEFB $46,$04,$47,$00,$46,$03,$45,$05
  DEFB $44,$01,$43,$0A,$42,$0A,$43,$01
  DEFB $44,$0A,$45,$01,$46,$09,$47,$09
  DEFB $46,$01,$45,$01,$44,$01,$43,$01
  DEFB $42,$01,$43,$01,$44,$01,$45,$09
  DEFB $46,$01,$47,$01,$46,$0A,$45,$01
  DEFB $44,$09,$43,$01,$42,$01,$43,$09
  DEFB $45,$01,$45,$0A,$46,$09,$47,$01
  DEFB $46,$01,$45,$0A,$44,$01,$43,$09
  DEFB $42,$01,$43,$0A,$44,$09,$45,$01
  DEFB $46,$01,$47,$01,$46,$00,$45,$00
  DEFB $44,$00,$43,$00,$42,$00,$47,$00
  DEFB $43,$00,$44,$00,$45,$00,$46,$00
  DEFB $47,$00,$46,$00,$45,$00,$44,$00
  DEFB $43,$00,$42,$00,$43,$00,$44,$00
  DEFB $45,$00,$46,$00,$47,$00,$46,$00
  DEFB $45,$00,$44,$00,$43,$00,$42,$04
  DEFB $43,$00,$44,$05,$45,$05,$46,$03
  DEFB $47,$01,$46,$00,$45,$00,$44,$03
  DEFB $43,$00,$42,$04,$43,$00,$44,$03
  DEFB $45,$00,$46,$04,$47,$00,$46,$00
  DEFB $45,$00,$44,$00,$43,$00,$42,$00
  DEFB $43,$00,$44,$00,$45,$00,$46,$00
  DEFB $47,$00,$46,$00,$45,$00,$44,$04
  DEFB $43,$04,$42,$04,$47,$0B,$43,$01
  DEFB $44,$01,$45,$01,$46,$01,$47,$01
  DEFB $46,$01,$00,$00,$00,$0C

; Geometry of each room shape
;
; Six bytes per shape: how far the player may walk from the centre horizontally
; and vertically, then a pointer to the shape's vertex table, then a pointer to
; its edge list. Shape $00 reads 56, 56, SHAPE_VERTI_00, SHAPE_EDGES_00.
;
; A vertex table is two bytes per point, x then y; an edge list is the
; $FF-separated groups DRAW_OUTLINE walks.
ROOM_SHAPES:
  DEFB $38,$38,$DF,$A9,$EF,$A9,$28,$28
  DEFB $04,$AA,$78,$AA,$38,$38,$34,$AB
  DEFB $54,$AB,$38,$18,$7D,$AB,$EF,$A9
  DEFB $18,$38,$8D,$AB,$EF,$A9,$10,$30
  DEFB $4A,$AC,$E9,$AB,$10,$30,$9D,$AB
  DEFB $E9,$AB,$30,$10,$96,$AC,$E9,$AB
  DEFB $30,$10,$E2,$AC,$E9,$AB,$30,$18
  DEFB $D0,$BE,$7E,$BD,$18,$30,$54,$BE
  DEFB $7E,$BD,$38,$38,$D0,$A9,$D8,$A9
  DEFB $38,$38,$A9,$97,$09,$98

; The corners of shape $0B
;
; 4 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_0B:
  DEFB $04,$BF
  DEFB $04,$00
  DEFB $1F,$BF
  DEFB $1F,$00

; Which corners to join up, for shape $0B
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
SHAPE_EDGES_0B:
  DEFB $00,$01,$FF,$02,$03,$FF,$FF

; The corners of shape $00
;
; 8 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_00:
  DEFB $04,$BB
  DEFB $04,$04
  DEFB $BB,$04
  DEFB $BB,$BB
  DEFB $1F,$A0
  DEFB $1F,$1F
  DEFB $A0,$1F
  DEFB $A0,$A0

; Which corners to join up, for shape $00, $03, $04
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
;
; Shared by 3 shapes, which is how a room and its mirror image are drawn from
; one description.
SHAPE_EDGES_00:
  DEFB $00,$01,$03,$04,$FF,$02,$01,$03
  DEFB $06,$FF,$05,$01,$04,$06,$FF,$07
  DEFB $03,$04,$06,$FF,$FF

; The corners of shape $01
;
; 58 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_01:
  DEFB $93,$05
  DEFB $24,$7D
  DEFB $25,$7D
  DEFB $02,$8E
  DEFB $11,$AD
  DEFB $26,$B7
  DEFB $46,$AD
  DEFB $4F,$90
  DEFB $3B,$96
  DEFB $2E,$90
  DEFB $79,$AD
  DEFB $70,$90
  DEFB $8C,$B9
  DEFB $97,$B4
  DEFB $7A,$96
  DEFB $81,$93
  DEFB $8A,$99
  DEFB $82,$94
  DEFB $97,$85
  DEFB $A2,$BF
  DEFB $B9,$9C
  DEFB $B8,$9B
  DEFB $AD,$79
  DEFB $AE,$79
  DEFB $91,$71
  DEFB $90,$70
  DEFB $90,$4F
  DEFB $AD,$46
  DEFB $28,$72
  DEFB $2F,$70
  DEFB $12,$79
  DEFB $11,$78
  DEFB $0A,$74
  DEFB $12,$46
  DEFB $2F,$4F
  DEFB $26,$3C
  DEFB $2F,$3C
  DEFB $05,$2C
  DEFB $17,$2C
  DEFB $2F,$2B
  DEFB $17,$13
  DEFB $37,$24
  DEFB $38,$25
  DEFB $24,$02
  DEFB $23,$01
  DEFB $46,$12
  DEFB $4F,$2F
  DEFB $79,$12
  DEFB $70,$2F
  DEFB $83,$26
  DEFB $83,$2F
  DEFB $94,$2F
  DEFB $9C,$37
  DEFB $9B,$38
  DEFB $BE,$23
  DEFB $BF,$24
  DEFB $AC,$17
  DEFB $93,$17

; Which corners to join up, for shape $01
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
SHAPE_EDGES_01:
  DEFB $00,$2F,$31,$39,$FF,$01,$FF,$02
  DEFB $FF,$03,$01,$04,$20,$FF,$04,$FF
  DEFB $05,$06,$08,$04,$FF,$06,$FF,$07
  DEFB $06,$08,$0B,$FF,$08,$FF,$09,$08
  DEFB $04,$02,$FF,$0A,$0C,$0B,$06,$FF
  DEFB $0B,$FF,$0C,$FF,$0D,$13,$0C,$11
  DEFB $FF,$0E,$0F,$0C,$0B,$FF,$0F,$FF
  DEFB $10,$FF,$11,$10,$FF,$12,$15,$18
  DEFB $10,$FF,$13,$10,$FF,$14,$17,$13
  DEFB $FF,$15,$FF,$16,$19,$FF,$17,$FF
  DEFB $18,$FF,$19,$FF,$1A,$19,$35,$FF
  DEFB $1B,$1A,$36,$16,$FF,$1C,$02,$1D
  DEFB $1E,$FF,$1D,$FF,$1E,$FF,$1F,$FF
  DEFB $20,$1F,$FF,$21,$1E,$22,$25,$FF
  DEFB $22,$1D,$FF,$23,$22,$24,$25,$FF
  DEFB $24,$FF,$25,$FF,$26,$24,$25,$28
  DEFB $FF,$27,$24,$29,$28,$FF,$28,$FF
  DEFB $29,$FF,$2A,$FF,$2B,$29,$FF,$2C
  DEFB $28,$2D,$FF,$2D,$FF,$2E,$2A,$2D
  DEFB $FF,$2F,$2D,$30,$FF,$30,$31,$2E
  DEFB $FF,$31,$FF,$32,$31,$33,$39,$FF
  DEFB $33,$FF,$34,$33,$36,$FF,$35,$FF
  DEFB $36,$FF,$37,$FF,$38,$33,$37,$39
  DEFB $FF,$39,$FF,$FF

; The corners of shape $02
;
; 16 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_02:
  DEFB $02,$A3
  DEFB $02,$1C
  DEFB $1C,$02
  DEFB $A3,$02
  DEFB $BD,$1C
  DEFB $BD,$A3
  DEFB $A3,$BD
  DEFB $1C,$BD
  DEFB $30,$A0
  DEFB $1F,$8F
  DEFB $1F,$30
  DEFB $30,$1F
  DEFB $8F,$1F
  DEFB $A0,$30
  DEFB $A0,$8F
  DEFB $8F,$A0

; Which corners to join up, for shape $02
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
SHAPE_EDGES_02:
  DEFB $00,$09,$07,$01,$FF,$02,$01,$03
  DEFB $0B,$FF,$04,$03,$05,$0D,$FF,$06
  DEFB $05,$0F,$07,$FF,$08,$07,$09,$0F
  DEFB $FF,$0A,$01,$09,$0B,$FF,$0C,$03
  DEFB $0B,$0D,$FF,$0E,$05,$0D,$0F,$FF
  DEFB $FF

; The corners of shape $03
;
; 8 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_03:
  DEFB $03,$9C
  DEFB $03,$23
  DEFB $BC,$23
  DEFB $BC,$9C
  DEFB $1F,$80
  DEFB $1F,$3F
  DEFB $A0,$3F
  DEFB $A0,$80

; The corners of shape $04
;
; 8 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_04:
  DEFB $23,$03
  DEFB $9C,$03
  DEFB $9C,$BC
  DEFB $23,$BC
  DEFB $3F,$1F
  DEFB $80,$1F
  DEFB $80,$A0
  DEFB $3F,$A0

; The corners of shape $06
;
; 38 points, x then y, indexed by the numbers in the edge list.
;
; Nothing in ROOM_TABLE uses shape $06. That is not the same as never drawn --
; the table's last entry is the trapdoor fall rather than a room -- but for
; these there is no entry at all.
SHAPE_VERTI_06:
  DEFB $8A,$BA
  DEFB $08,$04
  DEFB $35,$BB
  DEFB $8A,$BB
  DEFB $B7,$04
  DEFB $38,$28
  DEFB $38,$3D
  DEFB $3D,$3D
  DEFB $3D,$51
  DEFB $41,$51
  DEFB $41,$63
  DEFB $45,$63
  DEFB $45,$73
  DEFB $48,$73
  DEFB $48,$81
  DEFB $4B,$81
  DEFB $4B,$8D
  DEFB $4E,$8D
  DEFB $4E,$97
  DEFB $50,$97
  DEFB $50,$9F
  DEFB $6F,$9F
  DEFB $6F,$97
  DEFB $71,$97
  DEFB $71,$8D
  DEFB $74,$8D
  DEFB $74,$81
  DEFB $77,$81
  DEFB $77,$73
  DEFB $7A,$73
  DEFB $7A,$63
  DEFB $7E,$63
  DEFB $7E,$51
  DEFB $82,$51
  DEFB $82,$3D
  DEFB $87,$3D
  DEFB $87,$28
  DEFB $35,$BA

; Which corners to join up, for shape $05, $06, $07, $08
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
;
; Shared by 4 shapes, which is how a room and its mirror image are drawn from
; one description.
;
; Nothing in ROOM_TABLE uses shape $06, $07. That is not the same as never
; drawn -- the table's last entry is the trapdoor fall rather than a room --
; but for these there is no entry at all.
SHAPE_EDGES_05:
  DEFB $01,$FF,$02,$03,$01,$FF,$03,$FF
  DEFB $04,$01,$03,$FF,$05,$01,$FF,$06
  DEFB $23,$05,$FF,$07,$FF,$08,$21,$07
  DEFB $FF,$09,$FF,$0A,$1F,$09,$FF,$0B
  DEFB $FF,$0C,$1D,$0B,$FF,$0D,$FF,$0E
  DEFB $1B,$0D,$FF,$0F,$FF,$10,$19,$0F
  DEFB $FF,$11,$FF,$12,$17,$11,$02,$FF
  DEFB $17,$03,$FF,$18,$17,$FF,$19,$FF
  DEFB $1A,$19,$FF,$1B,$FF,$1C,$1B,$FF
  DEFB $1D,$FF,$1E,$1D,$FF,$1F,$FF,$20
  DEFB $1F,$FF,$21,$FF,$22,$21,$FF,$23
  DEFB $FF,$24,$04,$05,$23,$FF,$25,$FF
  DEFB $FF

; The corners of shape $05
;
; 38 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_05:
  DEFB $8A,$05
  DEFB $08,$BB
  DEFB $38,$04
  DEFB $8A,$04
  DEFB $B7,$BB
  DEFB $38,$97
  DEFB $38,$82
  DEFB $3D,$82
  DEFB $3D,$6E
  DEFB $41,$6E
  DEFB $41,$5C
  DEFB $45,$5C
  DEFB $45,$4C
  DEFB $48,$4C
  DEFB $48,$3E
  DEFB $4B,$3E
  DEFB $4B,$32
  DEFB $4E,$32
  DEFB $4E,$28
  DEFB $50,$28
  DEFB $50,$20
  DEFB $6F,$20
  DEFB $6F,$28
  DEFB $71,$28
  DEFB $71,$32
  DEFB $74,$32
  DEFB $74,$3E
  DEFB $77,$3E
  DEFB $77,$4C
  DEFB $7A,$4C
  DEFB $7A,$5C
  DEFB $7E,$5C
  DEFB $7E,$6E
  DEFB $82,$6E
  DEFB $82,$82
  DEFB $87,$82
  DEFB $87,$97
  DEFB $35,$05

; The corners of shape $07
;
; 38 points, x then y, indexed by the numbers in the edge list.
;
; Nothing in ROOM_TABLE uses shape $07. That is not the same as never drawn --
; the table's last entry is the trapdoor fall rather than a room -- but for
; these there is no entry at all.
SHAPE_VERTI_07:
  DEFB $05,$8A
  DEFB $BB,$08
  DEFB $04,$38
  DEFB $04,$8A
  DEFB $BB,$B7
  DEFB $97,$38
  DEFB $82,$38
  DEFB $82,$3D
  DEFB $64,$3D
  DEFB $6E,$41
  DEFB $5C,$41
  DEFB $5C,$45
  DEFB $4C,$45
  DEFB $4C,$48
  DEFB $3E,$48
  DEFB $3E,$4B
  DEFB $32,$4B
  DEFB $32,$4E
  DEFB $28,$4E
  DEFB $28,$50
  DEFB $20,$50
  DEFB $20,$6F
  DEFB $28,$6F
  DEFB $28,$71
  DEFB $32,$71
  DEFB $32,$74
  DEFB $3E,$74
  DEFB $3E,$77
  DEFB $4C,$77
  DEFB $4C,$7A
  DEFB $5C,$7A
  DEFB $5C,$7E
  DEFB $6E,$7E
  DEFB $6E,$82
  DEFB $82,$82
  DEFB $82,$87
  DEFB $97,$87
  DEFB $05,$35

; The corners of shape $08
;
; 38 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_08:
  DEFB $BA,$8A
  DEFB $04,$08
  DEFB $BB,$35
  DEFB $BB,$8A
  DEFB $04,$B7
  DEFB $28,$38
  DEFB $3D,$38
  DEFB $3D,$3D
  DEFB $51,$3D
  DEFB $51,$41
  DEFB $63,$41
  DEFB $63,$45
  DEFB $73,$45
  DEFB $73,$48
  DEFB $81,$48
  DEFB $81,$4B
  DEFB $8D,$4B
  DEFB $8D,$4E
  DEFB $97,$4E
  DEFB $97,$50
  DEFB $9F,$50
  DEFB $9F,$6F
  DEFB $97,$6F
  DEFB $97,$71
  DEFB $8D,$71
  DEFB $8D,$74
  DEFB $81,$74
  DEFB $81,$77
  DEFB $73,$77
  DEFB $73,$7A
  DEFB $63,$7A
  DEFB $63,$7E
  DEFB $51,$7E
  DEFB $51,$82
  DEFB $3D,$82
  DEFB $3D,$87
  DEFB $28,$87
  DEFB $BA,$35

; The knight, drawn for sprite $0D
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_0D:
  DEFB $12
  DEFB $3C,$00
  DEFB $3C,$F0
  DEFB $1F,$78
  DEFB $1B,$94
  DEFB $05,$4E
  DEFB $6B,$6E
  DEFB $E9,$2C
  DEFB $EF,$E8
  DEFB $44,$40
  DEFB $26,$C8
  DEFB $20,$08
  DEFB $30,$18
  DEFB $3F,$F8
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $0E, $10
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_0E:
  DEFB $12
  DEFB $1E,$F0
  DEFB $0E,$E0
  DEFB $05,$40
  DEFB $03,$F0
  DEFB $65,$4C
  DEFB $EB,$6E
  DEFB $E9,$2E
  DEFB $6F,$EC
  DEFB $04,$40
  DEFB $26,$C8
  DEFB $20,$08
  DEFB $30,$18
  DEFB $3F,$F8
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $0F
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_0F:
  DEFB $12
  DEFB $00,$78
  DEFB $1E,$78
  DEFB $3D,$F0
  DEFB $53,$B0
  DEFB $E5,$40
  DEFB $EB,$6C
  DEFB $69,$2E
  DEFB $2F,$EE
  DEFB $04,$44
  DEFB $26,$C8
  DEFB $20,$08
  DEFB $30,$18
  DEFB $3F,$F8
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $09
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_09:
  DEFB $12
  DEFB $3C,$00
  DEFB $3C,$F0
  DEFB $1F,$78
  DEFB $1B,$94
  DEFB $07,$CE
  DEFB $6F,$EE
  DEFB $EF,$EC
  DEFB $EF,$E8
  DEFB $40,$00
  DEFB $3F,$F8
  DEFB $27,$F8
  DEFB $27,$F8
  DEFB $30,$38
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $0A, $0C
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_0A:
  DEFB $12
  DEFB $1E,$F0
  DEFB $0E,$E0
  DEFB $05,$40
  DEFB $03,$80
  DEFB $67,$CC
  DEFB $EF,$EE
  DEFB $EF,$EE
  DEFB $6F,$EC
  DEFB $00,$00
  DEFB $3F,$F8
  DEFB $27,$F8
  DEFB $27,$F8
  DEFB $30,$38
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $0B
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_0B:
  DEFB $12
  DEFB $00,$78
  DEFB $1E,$78
  DEFB $3D,$F0
  DEFB $53,$B0
  DEFB $E7,$C0
  DEFB $EF,$EC
  DEFB $6F,$EE
  DEFB $2F,$EE
  DEFB $00,$04
  DEFB $3F,$F8
  DEFB $27,$F8
  DEFB $27,$F8
  DEFB $30,$38
  DEFB $13,$F0
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $01
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_01:
  DEFB $12
  DEFB $0C,$70
  DEFB $1C,$38
  DEFB $3B,$98
  DEFB $37,$60
  DEFB $06,$10
  DEFB $37,$08
  DEFB $27,$98
  DEFB $1F,$F0
  DEFB $67,$80
  DEFB $6B,$7C
  DEFB $1A,$FC
  DEFB $01,$FC
  DEFB $1F,$FC
  DEFB $08,$08
  DEFB $09,$F8
  DEFB $04,$F0
  DEFB $02,$E0
  DEFB $01,$40

; The knight, drawn for sprite $02, $04
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_02:
  DEFB $12
  DEFB $07,$C0
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $03,$F0
  DEFB $06,$38
  DEFB $04,$18
  DEFB $0F,$98
  DEFB $1F,$F0
  DEFB $67,$80
  DEFB $6B,$7C
  DEFB $1A,$FC
  DEFB $01,$FC
  DEFB $1F,$FC
  DEFB $08,$08
  DEFB $09,$F8
  DEFB $04,$F0
  DEFB $02,$E0
  DEFB $01,$40

; The knight, drawn for sprite $03
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_03:
  DEFB $12
  DEFB $0C,$70
  DEFB $1C,$38
  DEFB $3B,$D8
  DEFB $37,$E0
  DEFB $04,$74
  DEFB $08,$3A
  DEFB $07,$1E
  DEFB $1F,$F8
  DEFB $67,$80
  DEFB $6B,$7C
  DEFB $1A,$FC
  DEFB $01,$FC
  DEFB $1F,$FC
  DEFB $08,$08
  DEFB $09,$F8
  DEFB $04,$F0
  DEFB $02,$E0
  DEFB $01,$40

; The knight, drawn for sprite $05
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_05:
  DEFB $12
  DEFB $0E,$30
  DEFB $1C,$38
  DEFB $1B,$DC
  DEFB $07,$EC
  DEFB $2E,$20
  DEFB $5C,$10
  DEFB $78,$E0
  DEFB $1F,$F8
  DEFB $01,$E6
  DEFB $3E,$D6
  DEFB $27,$58
  DEFB $27,$80
  DEFB $27,$F8
  DEFB $10,$30
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $06, $08
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_06:
  DEFB $12
  DEFB $03,$E0
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $0F,$C0
  DEFB $1C,$60
  DEFB $18,$20
  DEFB $19,$F0
  DEFB $0F,$F8
  DEFB $01,$E6
  DEFB $3E,$D6
  DEFB $27,$58
  DEFB $27,$80
  DEFB $27,$F8
  DEFB $10,$30
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80

; The knight, drawn for sprite $07
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_07:
  DEFB $12
  DEFB $0E,$30
  DEFB $1C,$38
  DEFB $18,$DC
  DEFB $06,$EC
  DEFB $08,$60
  DEFB $10,$EC
  DEFB $19,$E4
  DEFB $0F,$F8
  DEFB $01,$E6
  DEFB $3E,$D6
  DEFB $27,$58
  DEFB $27,$80
  DEFB $27,$F8
  DEFB $10,$30
  DEFB $13,$F0
  DEFB $09,$E0
  DEFB $05,$C0
  DEFB $02,$80
NO_GRAPHIC:
  DEFB $00,$00

; The graphics for sprite $31
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Every byte is zero, so this one draws nothing -- a blank frame in an
; animation.
GFX_31:
  DEFB $10
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
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $80
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_80:
  DEFB $10
  DEFB $00,$03
  DEFB $00,$3F
  DEFB $00,$FA
  DEFB $03,$F2
  DEFB $06,$0A
  DEFB $0F,$DA
  DEFB $1F,$BC
  DEFB $3F,$3C
  DEFB $20,$B8
  DEFB $7D,$B8
  DEFB $7B,$B0
  DEFB $F3,$A0
  DEFB $9B,$C0
  DEFB $DB,$80
  DEFB $DE,$00
  DEFB $F8,$00

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $81
;
; 10 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_81:
  DEFB $0A
  DEFB $0C,$00
  DEFB $1E,$17
  DEFB $12,$12
  DEFB $7B,$1A
  DEFB $CF,$FF
  DEFB $CF,$FF
  DEFB $7B,$00
  DEFB $12,$00
  DEFB $1E,$00
  DEFB $0C,$00

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $82
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_82:
  DEFB $14
  DEFB $19,$FC
  DEFB $19,$FC
  DEFB $19,$C0
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$DC
  DEFB $19,$C0
  DEFB $19,$FC
  DEFB $1C,$FC
  DEFB $0E,$F8
  DEFB $03,$60
  DEFB $01,$40
  DEFB $01,$40
  DEFB $01,$40
  DEFB $02,$E0
  DEFB $01,$C0

; Food, drawn for sprite $57
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_57:
  DEFB $14
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $19,$F0
  DEFB $09,$E0
  DEFB $0D,$E0
  DEFB $0D,$E0
  DEFB $05,$C0
  DEFB $05,$C0
  DEFB $06,$C0
  DEFB $02,$80
  DEFB $02,$80
  DEFB $02,$80
  DEFB $05,$C0
  DEFB $03,$80

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $84
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_84:
  DEFB $10
  DEFB $A0,$00
  DEFB $B0,$00
  DEFB $98,$00
  DEFB $AF,$80
  DEFB $D0,$00
  DEFB $DF,$C0
  DEFB $6F,$E0
  DEFB $73,$F0
  DEFB $3C,$74
  DEFB $3F,$88
  DEFB $1F,$F8
  DEFB $0F,$F8
  DEFB $07,$F8
  DEFB $03,$FC
  DEFB $00,$FE
  DEFB $00,$1F

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $85
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_85:
  DEFB $10
  DEFB $C0,$00
  DEFB $E0,$02
  DEFB $E0,$0C
  DEFB $00,$30
  DEFB $C0,$30
  DEFB $E0,$40
  DEFB $E0,$C0
  DEFB $40,$80
  DEFB $00,$30
  DEFB $E0,$36
  DEFB $70,$06
  DEFB $70,$03
  DEFB $2C,$1E
  DEFB $1E,$EC
  DEFB $0E,$E0
  DEFB $04,$60

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $86
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_86:
  DEFB $10
  DEFB $90,$08
  DEFB $B1,$0E
  DEFB $F6,$1E
  DEFB $7C,$37
  DEFB $78,$67
  DEFB $30,$CF
  DEFB $31,$9E
  DEFB $33,$3C
  DEFB $32,$78
  DEFB $76,$F0
  DEFB $76,$F0
  DEFB $75,$E0
  DEFB $E7,$C0
  DEFB $3F,$00
  DEFB $3E,$00
  DEFB $18,$00

; Food, drawn for sprite $55
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_55:
  DEFB $10
  DEFB $05,$E0
  DEFB $00,$00
  DEFB $33,$FC
  DEFB $67,$FE
  DEFB $00,$00
  DEFB $C7,$FF
  DEFB $FF,$FF
  DEFB $00,$00
  DEFB $6F,$FE
  DEFB $67,$3E
  DEFB $7B,$DE
  DEFB $3F,$EC
  DEFB $0B,$E8
  DEFB $0C,$F0
  DEFB $0F,$80
  DEFB $07,$00

; Food, drawn for sprite $56
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_56:
  DEFB $10
  DEFB $03,$E0
  DEFB $0F,$F8
  DEFB $1F,$FC
  DEFB $3F,$FE
  DEFB $7F,$FE
  DEFB $7F,$FF
  DEFB $7F,$FF
  DEFB $67,$FF
  DEFB $63,$FF
  DEFB $33,$FF
  DEFB $3B,$06
  DEFB $1F,$F8
  DEFB $0E,$DC
  DEFB $01,$86
  DEFB $07,$7B
  DEFB $06,$3C

; The character set the status panel is drawn from
;
; 94 characters, eight bytes each, top row first. DRAW_PANEL points the tile
; source at this and then draws 8 columns by 24 rows from PANEL_LAYOUT, so the
; parchment scroll down the right of the screen is not a bitmap at all -- it is
; a little character set, and a 192-byte map naming which piece goes in each
; cell.
;
; Running DRAW_PANEL and photographing the screen settles what it draws: the
; scroll, with the words TIME and SCORE on it and the compass at its foot. An
; earlier note here called it the title picture, which it is not.
;
; That the count is exactly 94 is confirmed by the map: the highest value in it
; is $5D, which is 93, the last character here.
PANEL_TILES:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$03,$0F,$1F,$3D,$7E,$79
  DEFB $00,$00,$FF,$FF,$FF,$B4,$4A,$00
  DEFB $00,$00,$80,$FE,$FF,$D5,$AD,$42
  DEFB $00,$00,$00,$00,$F0,$7F,$56,$50
  DEFB $00,$00,$00,$00,$03,$FF,$B5,$44
  DEFB $00,$00,$01,$1F,$FF,$DA,$25,$41
  DEFB $00,$07,$FF,$FE,$FC,$FC,$D8,$3F
  DEFB $00,$F0,$08,$04,$02,$02,$02,$F1
  DEFB $D0,$CA,$E0,$C0,$C0,$C0,$60,$60
  DEFB $3B,$1B,$1B,$1B,$1B,$19,$0C,$0C
  DEFB $89,$89,$85,$85,$FD,$81,$81,$81
  DEFB $0C,$06,$03,$03,$03,$01,$01,$01
  DEFB $41,$42,$FC,$00,$00,$80,$80,$80
  DEFB $60,$30,$1C,$06,$3E,$1C,$0C,$06
  DEFB $0C,$18,$18,$18,$0C,$0C,$0C,$0C
  DEFB $06,$06,$06,$06,$06,$06,$06,$06
  DEFB $06,$06,$06,$06,$06,$06,$0C,$0C
  DEFB $0C,$0C,$0C,$18,$18,$18,$18,$18
  DEFB $18,$30,$30,$30,$30,$30,$30,$30
  DEFB $30,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$30,$30,$30,$18
  DEFB $0C,$18,$18,$18,$30,$30,$18,$30
  DEFB $30,$38,$0C,$06,$0C,$18,$18,$18
  DEFB $0C,$0C,$0C,$0C,$0C,$06,$06,$06
  DEFB $06,$06,$06,$06,$03,$03,$03,$03
  DEFB $03,$03,$03,$03,$03,$03,$03,$03
  DEFB $03,$03,$03,$03,$03,$06,$06,$06
  DEFB $06,$06,$06,$06,$0C,$0C,$0C,$0C
  DEFB $0C,$18,$18,$18,$18,$30,$30,$30
  DEFB $30,$60,$60,$60,$7F,$7E,$0C,$18
  DEFB $00,$00,$0C,$1E,$1D,$0B,$07,$37
  DEFB $7F,$FF,$80,$7F,$FF,$C1,$80,$00
  DEFB $00,$80,$98,$3C,$DC,$E8,$F0,$76
  DEFB $01,$03,$03,$03,$06,$06,$0C,$7F
  DEFB $80,$00,$00,$00,$00,$00,$00,$FC
  DEFB $70,$F0,$18,$FC,$F8,$C0,$C0,$C0
  DEFB $6E,$EC,$EC,$EC,$EC,$EC,$6E,$37
  DEFB $3E,$49,$49,$49,$49,$2A,$1C,$08
  DEFB $3B,$1B,$1B,$1B,$1B,$1B,$3B,$76
  DEFB $00,$80,$80,$80,$80,$80,$00,$00
  DEFB $00,$03,$07,$0E,$07,$01,$00,$00
  DEFB $FD,$C3,$DF,$2F,$97,$EB,$77,$31
  DEFB $C2,$C1,$81,$81,$01,$FD,$05,$05
  DEFB $C0,$60,$60,$60,$30,$18,$0F,$07
  DEFB $07,$0B,$1D,$1E,$0C,$00,$00,$FF
  DEFB $80,$C1,$FF,$7F,$80,$FF,$7F,$3E
  DEFB $F0,$E8,$DC,$3C,$9B,$9F,$7C,$E0
  DEFB $00,$00,$00,$3F,$FF,$C0,$00,$00
  DEFB $00,$00,$00,$00,$F0,$FF,$0F,$00
  DEFB $30,$3F,$30,$18,$18,$0C,$FE,$FF
  DEFB $89,$F1,$01,$01,$02,$04,$08,$F0
  DEFB $FF,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $FF,$FF,$7F,$7B,$7B,$39,$39,$38
  DEFB $00,$00,$80,$80,$80,$80,$C0,$C0
  DEFB $10,$10,$10,$00,$00,$00,$00,$00
  DEFB $60,$20,$10,$00,$00,$00,$00,$00
  DEFB $C0,$C0,$C0,$60,$60,$60,$30,$30
  DEFB $30,$18,$18,$18,$18,$30,$30,$30
  DEFB $18,$0C,$0C,$0C,$0C,$0C,$0C,$0C
  DEFB $0C,$0C,$0C,$0C,$0C,$0C,$0C,$0C
  DEFB $0C,$0C,$0C,$0C,$18,$18,$18,$18
  DEFB $18,$30,$30,$30,$30,$60,$60,$60
  DEFB $60,$60,$60,$C0,$C0,$C0,$C0,$C0
  DEFB $C0,$C0,$C0,$C0,$C0,$C0,$C0,$C0
  DEFB $60,$60,$60,$60,$60,$30,$30,$30
  DEFB $18,$18,$18,$0C,$0C,$0C,$0C,$06
  DEFB $06,$06,$06,$06,$03,$03,$03,$03
  DEFB $03,$03,$03,$03,$03,$03,$03,$03
  DEFB $06,$06,$06,$06,$06,$0C,$0C,$0C
  DEFB $0C,$18,$18,$18,$18,$30,$30,$30
  DEFB $60,$60,$60,$C0,$C0,$C0,$80,$80
  DEFB $07,$0F,$0F,$07,$01,$0F,$07,$00
  DEFB $C3,$E7,$0F,$CE,$EF,$E7,$C3,$00
  DEFB $C3,$E7,$8F,$0E,$1F,$E7,$C3,$00
  DEFB $8F,$CF,$EE,$EF,$EF,$CE,$8E,$00
  DEFB $CF,$EF,$6E,$EF,$CE,$CF,$EF,$00
  DEFB $80,$80,$00,$C0,$00,$E0,$E0,$00
  DEFB $00,$00,$08,$1E,$27,$23,$71,$5F
  DEFB $00,$00,$40,$40,$80,$80,$00,$C3
  DEFB $00,$00,$00,$00,$00,$00,$00,$16
  DEFB $00,$00,$00,$05,$03,$03,$03,$33
  DEFB $00,$00,$00,$AC,$18,$18,$18,$18
  DEFB $4F,$22,$1F,$05,$7F,$47,$3B,$00
  DEFB $EF,$6C,$2C,$AC,$4C,$CE,$87,$00
  DEFB $BE,$18,$18,$18,$18,$9C,$0C,$00
  DEFB $FB,$DB,$DB,$DB,$DB,$FB,$61,$00
  DEFB $18,$18,$18,$18,$18,$DE,$8C,$00
  DEFB $FE,$FE,$FE,$38,$38,$38,$38,$00
  DEFB $7C,$7C,$38,$38,$38,$7C,$7C,$00
  DEFB $82,$EE,$FE,$FE,$D6,$D6,$D6,$00
  DEFB $F8,$F8,$E0,$FC,$E0,$FE,$FE,$00
  DEFB $00,$18,$18,$00,$00,$18,$18,$00

; The status panel, as tile numbers
;
; 24 rows of 8, each byte an index into PANEL_TILES. The loop at DRAW_SCROLL_0
; walks it a row at a time, calling PLOT_TILE for each cell and colouring it as
; it goes. The eight columns start at x=192, which is the first character
; column past the play area -- the same place PAINT_PANEL colours.
PANEL_LAYOUT:
  DEFB $01,$02,$03,$04,$05,$06,$07,$08
  DEFB $09,$4F,$50,$51,$52,$53,$0A,$0B
  DEFB $0E,$54,$55,$56,$57,$58,$0C,$0D
  DEFB $0F,$00,$00,$00,$00,$00,$00,$3A
  DEFB $10,$00,$00,$00,$00,$00,$00,$3B
  DEFB $11,$00,$00,$00,$00,$00,$00,$3C
  DEFB $12,$00,$00,$00,$00,$00,$00,$3D
  DEFB $13,$00,$59,$5A,$5B,$5C,$00,$3E
  DEFB $14,$00,$00,$00,$5D,$00,$00,$3F
  DEFB $15,$49,$4A,$4B,$4C,$4D,$4E,$40
  DEFB $16,$00,$00,$00,$00,$00,$00,$41
  DEFB $17,$00,$00,$00,$00,$00,$00,$42
  DEFB $18,$00,$00,$00,$00,$00,$00,$43
  DEFB $19,$00,$00,$00,$00,$00,$00,$44
  DEFB $1A,$00,$00,$00,$00,$00,$00,$45
  DEFB $1B,$00,$00,$00,$00,$00,$00,$46
  DEFB $1C,$00,$00,$00,$00,$00,$00,$47
  DEFB $1D,$00,$00,$00,$00,$00,$00,$48
  DEFB $1E,$1F,$20,$21,$00,$00,$22,$23
  DEFB $24,$25,$26,$27,$28,$29,$2A,$2B
  DEFB $2C,$2D,$2E,$2F,$30,$31,$32,$33
  DEFB $00,$34,$35,$00,$00,$00,$00,$00
  DEFB $00,$00,$36,$37,$00,$00,$00,$00
  DEFB $00,$00,$38,$39,$00,$00,$00,$00

; Big door frame, drawn for sprite $A4
;
; 32 rows of 48 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_A4:
  DEFB $06,$20
  DEFB $FF,$FE,$00,$00,$3F,$FF
  DEFB $00,$FE,$00,$00,$7F,$00
  DEFB $01,$FC,$00,$00,$3F,$80
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $01,$F8,$00,$00,$1F,$80
  DEFB $03,$F8,$00,$00,$1F,$C0
  DEFB $03,$F0,$00,$00,$0F,$C0
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $07,$E0,$00,$00,$07,$E0
  DEFB $0F,$E0,$00,$00,$07,$F0
  DEFB $0F,$C0,$00,$00,$03,$F0
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $1F,$80,$00,$00,$01,$F8
  DEFB $1F,$80,$00,$00,$01,$F8
  DEFB $1F,$80,$00,$00,$01,$F8
  DEFB $10,$00,$00,$00,$00,$08
  DEFB $07,$80,$00,$00,$01,$E0
  DEFB $1F,$80,$00,$00,$01,$F8
  DEFB $1F,$00,$00,$00,$00,$F8
  DEFB $0E,$40,$00,$00,$02,$70
  DEFB $08,$E0,$00,$00,$07,$10
  DEFB $03,$F4,$00,$00,$2F,$C0
  DEFB $07,$EF,$00,$00,$F7,$E0
  DEFB $03,$CE,$77,$EE,$73,$C0
  DEFB $01,$DE,$F6,$6F,$7B,$80
  DEFB $00,$9E,$F6,$6F,$79,$00
  DEFB $00,$3C,$E6,$67,$3C,$00
  DEFB $00,$1D,$EE,$EE,$B8,$00
  DEFB $00,$01,$EE,$77,$80,$00
  DEFB $00,$00,$08,$10,$00,$00
  DEFB $00,$00,$0F,$F0,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; Colours for a graphic, entry $CB of the attribute table
;
; One attribute per character cell, 6 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_CB:
  DEFB $06,$04
  DEFB $43,$43,$00,$00,$43,$43
  DEFB $43,$43,$00,$00,$43,$43
  DEFB $43,$43,$43,$43,$43,$43
  DEFB $43,$43,$43,$43,$43,$43

; Ghost picture, drawn for sprite $B2
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B2:
  DEFB $04,$18
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $03,$80,$01,$C0
  DEFB $07,$C6,$63,$E0
  DEFB $06,$7F,$FE,$60
  DEFB $03,$FF,$FF,$C0
  DEFB $01,$80,$01,$80
  DEFB $01,$80,$01,$80
  DEFB $03,$8C,$31,$C0
  DEFB $07,$8F,$F1,$E0
  DEFB $03,$0C,$30,$C0
  DEFB $0B,$0F,$F0,$D0
  DEFB $0F,$0C,$90,$F0
  DEFB $07,$0D,$B0,$E0
  DEFB $06,$07,$E0,$60
  DEFB $0E,$03,$C0,$70
  DEFB $1E,$00,$00,$78
  DEFB $37,$FF,$FF,$EC
  DEFB $1F,$FF,$FF,$F4
  DEFB $35,$FF,$FF,$AC
  DEFB $1B,$1C,$31,$D8
  DEFB $0E,$06,$60,$70
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00

; Colours for a graphic, entry $D9 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D9:
  DEFB $04,$03
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF
  DEFB $FF,$FF,$FF,$FF

; The serf, drawn for sprite $2D
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_2D:
  DEFB $12
  DEFB $1F,$38
  DEFB $17,$38
  DEFB $0E,$3C
  DEFB $01,$5E
  DEFB $03,$DE
  DEFB $27,$EE
  DEFB $77,$70
  DEFB $77,$F4
  DEFB $77,$74
  DEFB $45,$D0
  DEFB $00,$80
  DEFB $0A,$28
  DEFB $1B,$6C
  DEFB $08,$0C
  DEFB $1C,$14
  DEFB $17,$FC
  DEFB $0D,$E8
  DEFB $07,$50

; The serf, drawn for sprite $2E, $30
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_2E:
  DEFB $12
  DEFB $0F,$F8
  DEFB $0D,$68
  DEFB $06,$30
  DEFB $01,$40
  DEFB $23,$E2
  DEFB $37,$F6
  DEFB $37,$76
  DEFB $17,$F4
  DEFB $17,$74
  DEFB $05,$D0
  DEFB $00,$80
  DEFB $0A,$28
  DEFB $1B,$6C
  DEFB $08,$0C
  DEFB $1C,$14
  DEFB $17,$FC
  DEFB $0D,$E8
  DEFB $07,$50

; The serf, drawn for sprite $2F
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_2F:
  DEFB $12
  DEFB $07,$7C
  DEFB $07,$74
  DEFB $1F,$58
  DEFB $3D,$60
  DEFB $3D,$E0
  DEFB $3B,$F2
  DEFB $07,$77
  DEFB $17,$F7
  DEFB $17,$77
  DEFB $05,$D2
  DEFB $00,$80
  DEFB $0A,$28
  DEFB $1B,$6C
  DEFB $08,$0C
  DEFB $1C,$14
  DEFB $17,$FC
  DEFB $0D,$E8
  DEFB $07,$A0

; The serf, drawn for sprite $29
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_29:
  DEFB $12
  DEFB $1E,$40
  DEFB $1E,$70
  DEFB $0A,$B0
  DEFB $07,$D8
  DEFB $0F,$D8
  DEFB $4F,$E8
  DEFB $EF,$E0
  DEFB $EC,$6C
  DEFB $E2,$4C
  DEFB $8D,$A8
  DEFB $15,$70
  DEFB $1B,$D0
  DEFB $3A,$98
  DEFB $2B,$68
  DEFB $15,$D0
  DEFB $2F,$B8
  DEFB $13,$50
  DEFB $0A,$A0

; The serf, drawn for sprite $2A, $2C
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_2A:
  DEFB $12
  DEFB $0E,$E0
  DEFB $0E,$E0
  DEFB $02,$80
  DEFB $07,$C0
  DEFB $47,$C4
  DEFB $6F,$EC
  DEFB $6F,$EC
  DEFB $2C,$68
  DEFB $23,$88
  DEFB $0D,$A0
  DEFB $15,$70
  DEFB $1B,$D0
  DEFB $3A,$98
  DEFB $2B,$68
  DEFB $15,$D0
  DEFB $2F,$B8
  DEFB $13,$50
  DEFB $0A,$A0

; The serf, drawn for sprite $2B
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_2B:
  DEFB $12
  DEFB $04,$F0
  DEFB $1C,$F0
  DEFB $1A,$A0
  DEFB $37,$C0
  DEFB $37,$E0
  DEFB $2F,$E4
  DEFB $0F,$EE
  DEFB $6C,$3E
  DEFB $63,$8E
  DEFB $2D,$A2
  DEFB $15,$70
  DEFB $1B,$D0
  DEFB $3A,$98
  DEFB $2B,$68
  DEFB $15,$D0
  DEFB $2F,$B8
  DEFB $13,$50
  DEFB $0A,$A0

; The serf, drawn for sprite $21
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_21:
  DEFB $12
  DEFB $03,$70
  DEFB $0F,$78
  DEFB $3F,$1C
  DEFB $FB,$EC
  DEFB $CB,$10
  DEFB $77,$88
  DEFB $07,$C8
  DEFB $37,$88
  DEFB $77,$30
  DEFB $0F,$C0
  DEFB $11,$50
  DEFB $60,$B8
  DEFB $68,$68
  DEFB $19,$D0
  DEFB $07,$A8
  DEFB $19,$58
  DEFB $16,$F0
  DEFB $0A,$A0

; The serf, drawn for sprite $22, $24
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_22:
  DEFB $12
  DEFB $3F,$E0
  DEFB $2F,$E0
  DEFB $24,$C0
  DEFB $19,$E0
  DEFB $03,$F0
  DEFB $06,$38
  DEFB $06,$18
  DEFB $07,$18
  DEFB $07,$30
  DEFB $0F,$C0
  DEFB $11,$50
  DEFB $60,$B8
  DEFB $68,$68
  DEFB $19,$D0
  DEFB $07,$A8
  DEFB $19,$58
  DEFB $16,$F0
  DEFB $0A,$A0

; The serf, drawn for sprite $23
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_23:
  DEFB $12
  DEFB $03,$F0
  DEFB $3A,$F8
  DEFB $5A,$5C
  DEFB $4D,$9C
  DEFB $30,$30
  DEFB $07,$F8
  DEFB $08,$7A
  DEFB $18,$1A
  DEFB $07,$3C
  DEFB $0F,$C0
  DEFB $11,$50
  DEFB $60,$B8
  DEFB $68,$68
  DEFB $19,$D0
  DEFB $07,$A8
  DEFB $19,$58
  DEFB $16,$F0
  DEFB $0A,$A0

; The serf, drawn for sprite $25
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_25:
  DEFB $12
  DEFB $0F,$C0
  DEFB $1F,$5C
  DEFB $3A,$5A
  DEFB $39,$B2
  DEFB $0C,$0C
  DEFB $1F,$E0
  DEFB $5E,$10
  DEFB $58,$18
  DEFB $3C,$E0
  DEFB $03,$F0
  DEFB $05,$88
  DEFB $1D,$06
  DEFB $16,$16
  DEFB $0B,$98
  DEFB $15,$E0
  DEFB $1A,$98
  DEFB $0F,$E8
  DEFB $05,$50

; The serf, drawn for sprite $26, $28
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_26:
  DEFB $12
  DEFB $07,$FC
  DEFB $07,$F4
  DEFB $03,$24
  DEFB $07,$98
  DEFB $0F,$C0
  DEFB $1C,$60
  DEFB $18,$60
  DEFB $18,$E0
  DEFB $0C,$E0
  DEFB $03,$F0
  DEFB $05,$88
  DEFB $1D,$06
  DEFB $16,$16
  DEFB $0B,$98
  DEFB $15,$E0
  DEFB $1A,$98
  DEFB $0F,$E8
  DEFB $05,$50

; The serf, drawn for sprite $27
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_27:
  DEFB $12
  DEFB $0E,$C0
  DEFB $1E,$F0
  DEFB $31,$FC
  DEFB $37,$DF
  DEFB $08,$D3
  DEFB $11,$EE
  DEFB $13,$E0
  DEFB $11,$EC
  DEFB $0C,$EE
  DEFB $03,$F0
  DEFB $05,$88
  DEFB $1D,$06
  DEFB $16,$16
  DEFB $0B,$98
  DEFB $15,$E0
  DEFB $1A,$98
  DEFB $0F,$E8
  DEFB $05,$50

; Clock, drawn for sprite $B1
;
; 32 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B1:
  DEFB $04,$20
  DEFB $00,$3F,$FC,$00
  DEFB $00,$70,$0E,$00
  DEFB $00,$77,$EE,$00
  DEFB $00,$67,$E6,$00
  DEFB $00,$67,$E6,$00
  DEFB $00,$6B,$F6,$00
  DEFB $00,$E8,$F7,$00
  DEFB $00,$CF,$F3,$00
  DEFB $00,$DF,$FB,$00
  DEFB $00,$DF,$FB,$00
  DEFB $00,$C0,$03,$00
  DEFB $00,$FF,$FF,$00
  DEFB $00,$FF,$FF,$00
  DEFB $01,$F9,$9F,$80
  DEFB $01,$E0,$07,$80
  DEFB $01,$C0,$03,$80
  DEFB $01,$F7,$8F,$80
  DEFB $01,$C0,$43,$80
  DEFB $01,$E0,$27,$80
  DEFB $06,$79,$9E,$60
  DEFB $06,$9F,$F9,$60
  DEFB $06,$E7,$E7,$60
  DEFB $07,$69,$96,$E0
  DEFB $06,$EE,$77,$60
  DEFB $06,$F7,$6F,$60
  DEFB $07,$6E,$F6,$E0
  DEFB $06,$EF,$77,$60
  DEFB $06,$F6,$EF,$60
  DEFB $01,$6F,$76,$00
  DEFB $00,$6E,$F6,$00
  DEFB $00,$1F,$68,$00
  DEFB $00,$03,$E0,$00

; Colours for a graphic, entry $D8 of the attribute table
;
; One attribute per character cell, 4 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_D8:
  DEFB $04,$04
  DEFB $45,$45,$45,$45
  DEFB $45,$45,$45,$45
  DEFB $45,$45,$45,$45
  DEFB $45,$45,$45,$45

; The wizard, drawn for sprite $1D
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_1D:
  DEFB $14
  DEFB $3C,$00
  DEFB $4C,$F0
  DEFB $1F,$68
  DEFB $1B,$84
  DEFB $06,$6E
  DEFB $6C,$6E
  DEFB $EE,$EC
  DEFB $EF,$E8
  DEFB $44,$40
  DEFB $16,$D0
  DEFB $18,$30
  DEFB $1F,$F0
  DEFB $1E,$70
  DEFB $0C,$E0
  DEFB $0C,$E0
  DEFB $04,$C0
  DEFB $06,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; The wizard, drawn for sprite $1E, $20
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_1E:
  DEFB $14
  DEFB $1E,$F0
  DEFB $26,$C8
  DEFB $05,$40
  DEFB $03,$80
  DEFB $66,$CC
  DEFB $EC,$6E
  DEFB $EE,$EE
  DEFB $6F,$EC
  DEFB $04,$40
  DEFB $16,$D0
  DEFB $18,$30
  DEFB $1F,$F0
  DEFB $1E,$70
  DEFB $0C,$E0
  DEFB $0C,$E0
  DEFB $04,$C0
  DEFB $06,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; The wizard, drawn for sprite $1F
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_1F:
  DEFB $14
  DEFB $00,$78
  DEFB $1E,$64
  DEFB $2D,$F0
  DEFB $43,$B0
  DEFB $E6,$C0
  DEFB $EC,$6C
  DEFB $6E,$EE
  DEFB $2F,$EE
  DEFB $04,$44
  DEFB $16,$D0
  DEFB $18,$30
  DEFB $1F,$F0
  DEFB $1E,$70
  DEFB $0C,$E0
  DEFB $0C,$E0
  DEFB $04,$C0
  DEFB $06,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; The wizard, drawn for sprite $19
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_19:
  DEFB $14
  DEFB $1E,$00
  DEFB $26,$78
  DEFB $0F,$D4
  DEFB $0D,$C2
  DEFB $03,$E7
  DEFB $3E,$F7
  DEFB $FF,$F6
  DEFB $77,$F4
  DEFB $20,$00
  DEFB $0F,$F8
  DEFB $0D,$F8
  DEFB $08,$F8
  DEFB $0D,$F8
  DEFB $07,$F0
  DEFB $07,$70
  DEFB $02,$20
  DEFB $03,$60
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $1A, $1C
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_1A:
  DEFB $14
  DEFB $0F,$78
  DEFB $13,$64
  DEFB $02,$A0
  DEFB $01,$C0
  DEFB $33,$E6
  DEFB $77,$F7
  DEFB $77,$F7
  DEFB $37,$F6
  DEFB $00,$00
  DEFB $0F,$F8
  DEFB $0D,$F8
  DEFB $08,$F8
  DEFB $0D,$F8
  DEFB $07,$F0
  DEFB $07,$70
  DEFB $02,$20
  DEFB $03,$60
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $1B
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_1B:
  DEFB $14
  DEFB $00,$3C
  DEFB $0F,$32
  DEFB $16,$F8
  DEFB $21,$D8
  DEFB $73,$E0
  DEFB $77,$F6
  DEFB $37,$F7
  DEFB $17,$F7
  DEFB $00,$02
  DEFB $0F,$F8
  DEFB $0D,$F8
  DEFB $08,$F8
  DEFB $0D,$F8
  DEFB $07,$F0
  DEFB $07,$70
  DEFB $02,$20
  DEFB $03,$60
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $11
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_11:
  DEFB $14
  DEFB $0C,$F0
  DEFB $1C,$38
  DEFB $33,$98
  DEFB $47,$60
  DEFB $06,$10
  DEFB $37,$08
  DEFB $07,$98
  DEFB $31,$F0
  DEFB $35,$80
  DEFB $0D,$78
  DEFB $00,$D8
  DEFB $1F,$88
  DEFB $0F,$D8
  DEFB $05,$F0
  DEFB $05,$F0
  DEFB $02,$E0
  DEFB $02,$E0
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $12, $14
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_12:
  DEFB $14
  DEFB $07,$C0
  DEFB $09,$C0
  DEFB $00,$00
  DEFB $03,$F0
  DEFB $06,$38
  DEFB $04,$18
  DEFB $07,$98
  DEFB $31,$F0
  DEFB $35,$80
  DEFB $0D,$78
  DEFB $00,$D8
  DEFB $1F,$88
  DEFB $0F,$D8
  DEFB $05,$F0
  DEFB $05,$F0
  DEFB $02,$E0
  DEFB $02,$E0
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $13
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_13:
  DEFB $14
  DEFB $03,$F0
  DEFB $1C,$38
  DEFB $33,$D8
  DEFB $47,$E0
  DEFB $04,$74
  DEFB $08,$3A
  DEFB $07,$1E
  DEFB $31,$F8
  DEFB $35,$80
  DEFB $0D,$78
  DEFB $00,$D8
  DEFB $1F,$88
  DEFB $0F,$D8
  DEFB $05,$F0
  DEFB $05,$F0
  DEFB $02,$E0
  DEFB $02,$E0
  DEFB $01,$C0
  DEFB $01,$C0
  DEFB $00,$80

; The wizard, drawn for sprite $15
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_15:
  DEFB $14
  DEFB $0F,$30
  DEFB $1C,$38
  DEFB $1B,$CC
  DEFB $07,$E2
  DEFB $2E,$20
  DEFB $5C,$10
  DEFB $78,$E0
  DEFB $1F,$8C
  DEFB $01,$AC
  DEFB $1E,$B0
  DEFB $1B,$00
  DEFB $11,$F8
  DEFB $1B,$F0
  DEFB $0F,$A0
  DEFB $0F,$A0
  DEFB $07,$40
  DEFB $07,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; The wizard, drawn for sprite $16, $18
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_16:
  DEFB $14
  DEFB $03,$E0
  DEFB $03,$90
  DEFB $00,$00
  DEFB $0F,$C0
  DEFB $1C,$60
  DEFB $18,$20
  DEFB $19,$E0
  DEFB $0F,$8C
  DEFB $01,$AC
  DEFB $1E,$B0
  DEFB $1B,$00
  DEFB $11,$F8
  DEFB $1B,$F0
  DEFB $0F,$A0
  DEFB $0F,$A0
  DEFB $07,$40
  DEFB $07,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; The wizard, drawn for sprite $17
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_17:
  DEFB $14
  DEFB $0F,$30
  DEFB $1C,$38
  DEFB $19,$CC
  DEFB $06,$E2
  DEFB $08,$60
  DEFB $10,$EC
  DEFB $19,$E0
  DEFB $0F,$8C
  DEFB $01,$AC
  DEFB $1E,$B0
  DEFB $1B,$00
  DEFB $11,$F8
  DEFB $1B,$F0
  DEFB $0F,$A0
  DEFB $0F,$A0
  DEFB $07,$40
  DEFB $07,$40
  DEFB $03,$80
  DEFB $03,$80
  DEFB $01,$00

; Sword, spinning, thrown by the serf, drawn for sprite $3E
;
; 12 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3E:
  DEFB $0C
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$20
  DEFB $00,$10
  DEFB $00,$12
  DEFB $7F,$DF
  DEFB $FF,$DF
  DEFB $00,$12
  DEFB $00,$10
  DEFB $00,$20

; Sword, spinning, thrown by the serf, drawn for sprite $3B
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3B:
  DEFB $0D
  DEFB $00,$00
  DEFB $00,$1C
  DEFB $01,$DC
  DEFB $00,$7C
  DEFB $00,$30
  DEFB $00,$D8
  DEFB $01,$C8
  DEFB $03,$88
  DEFB $07,$00
  DEFB $0E,$00
  DEFB $1C,$00
  DEFB $18,$00
  DEFB $10,$00

; Sword, spinning, thrown by the serf, drawn for sprite $3C
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3C:
  DEFB $10
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $08,$10
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $00,$80

; Sword, spinning, thrown by the serf, drawn for sprite $3D
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3D:
  DEFB $0D
  DEFB $00,$00
  DEFB $00,$00
  DEFB $38,$00
  DEFB $3B,$80
  DEFB $3E,$00
  DEFB $0C,$00
  DEFB $1B,$00
  DEFB $13,$80
  DEFB $11,$C0
  DEFB $00,$E0
  DEFB $00,$70
  DEFB $00,$38
  DEFB $00,$1C

; Sword, spinning, thrown by the serf, drawn for sprite $3A
;
; 12 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3A:
  DEFB $0C
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $04,$00
  DEFB $08,$00
  DEFB $48,$00
  DEFB $FD,$FF
  DEFB $FD,$FE
  DEFB $48,$00
  DEFB $08,$00
  DEFB $04,$00

; Sword, spinning, thrown by the serf, drawn for sprite $39
;
; 12 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_39:
  DEFB $0C
  DEFB $00,$00
  DEFB $00,$08
  DEFB $00,$18
  DEFB $00,$38
  DEFB $00,$70
  DEFB $00,$E0
  DEFB $11,$C0
  DEFB $13,$80
  DEFB $1D,$00
  DEFB $0C,$00
  DEFB $3E,$00
  DEFB $3B,$80
  DEFB $38,$00

; Sword, spinning, thrown by the serf, drawn for sprite $38
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_38:
  DEFB $10
  DEFB $01,$00
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $08,$10
  DEFB $07,$E0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $01,$80

; Sword, spinning, thrown by the serf, drawn for sprite $3F
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_3F:
  DEFB $10
  DEFB $00,$00
  DEFB $00,$00
  DEFB $10,$00
  DEFB $18,$00
  DEFB $1C,$00
  DEFB $0E,$00
  DEFB $07,$00
  DEFB $03,$88
  DEFB $01,$C8
  DEFB $00,$D8
  DEFB $00,$30
  DEFB $00,$7C
  DEFB $01,$DC
  DEFB $00,$1C
  DEFB $00,$00
  DEFB $00,$00

; Axe, spinning, thrown by the knight, drawn for sprite $40
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_40:
  DEFB $10
  DEFB $00,$00
  DEFB $00,$00
  DEFB $3C,$00
  DEFB $7E,$00
  DEFB $C3,$00
  DEFB $3C,$00
  DEFB $18,$00
  DEFB $3D,$FF
  DEFB $3D,$FF
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Axe, spinning, thrown by the knight, drawn for sprite $41
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_41:
  DEFB $10
  DEFB $00,$00
  DEFB $00,$04
  DEFB $00,$0E
  DEFB $00,$1C
  DEFB $00,$38
  DEFB $3C,$70
  DEFB $60,$E0
  DEFB $D9,$C0
  DEFB $BA,$80
  DEFB $BF,$00
  DEFB $8E,$00
  DEFB $1C,$00
  DEFB $08,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; Axe, spinning, thrown by the knight, drawn for sprite $42
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_42:
  DEFB $10
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $09,$80
  DEFB $18,$00
  DEFB $35,$80
  DEFB $37,$80
  DEFB $37,$80
  DEFB $35,$80
  DEFB $18,$00
  DEFB $08,$00

; Axe, spinning, thrown by the knight, drawn for sprite $43
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_43:
  DEFB $10
  DEFB $00,$00
  DEFB $20,$00
  DEFB $70,$00
  DEFB $38,$00
  DEFB $1C,$00
  DEFB $0E,$00
  DEFB $07,$00
  DEFB $03,$80
  DEFB $01,$40
  DEFB $00,$E0
  DEFB $04,$70
  DEFB $05,$F8
  DEFB $05,$D0
  DEFB $06,$C0
  DEFB $03,$00
  DEFB $01,$E0

; Axe, spinning, thrown by the knight, drawn for sprite $44
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_44:
  DEFB $10
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF,$BC
  DEFB $FF,$BC
  DEFB $00,$18
  DEFB $00,$3C
  DEFB $00,$C3
  DEFB $00,$7E
  DEFB $00,$3C
  DEFB $00,$00
  DEFB $00,$00

; Axe, spinning, thrown by the knight, drawn for sprite $45
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_45:
  DEFB $10
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$10
  DEFB $00,$38
  DEFB $00,$71
  DEFB $00,$FD
  DEFB $01,$5D
  DEFB $03,$9B
  DEFB $07,$06
  DEFB $0E,$3C
  DEFB $1C,$00
  DEFB $38,$00
  DEFB $70,$00
  DEFB $20,$00
  DEFB $00,$00

; Axe, spinning, thrown by the knight, drawn for sprite $46
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_46:
  DEFB $10
  DEFB $00,$10
  DEFB $00,$18
  DEFB $01,$AC
  DEFB $01,$EC
  DEFB $01,$EC
  DEFB $01,$AC
  DEFB $00,$18
  DEFB $01,$90
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80

; Axe, spinning, thrown by the knight, drawn for sprite $47
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_47:
  DEFB $10
  DEFB $07,$80
  DEFB $00,$C0
  DEFB $03,$60
  DEFB $0B,$A0
  DEFB $1F,$A0
  DEFB $0E,$20
  DEFB $07,$00
  DEFB $02,$80
  DEFB $01,$C0
  DEFB $00,$E0
  DEFB $00,$70
  DEFB $00,$38
  DEFB $00,$1C
  DEFB $00,$0E
  DEFB $00,$04
  DEFB $00,$00

; Spell, thrown by the wizard, drawn for sprite $34
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_34:
  DEFB $0F
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$24
  DEFB $00,$80
  DEFB $09,$80
  DEFB $02,$D0
  DEFB $0D,$60
  DEFB $06,$F0
  DEFB $43,$42
  DEFB $05,$A0
  DEFB $12,$A0
  DEFB $00,$00
  DEFB $00,$00
  DEFB $01,$00

; Spell, thrown by the wizard, drawn for sprite $35, $36
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_35:
  DEFB $0F
  DEFB $00,$00
  DEFB $00,$08
  DEFB $00,$00
  DEFB $20,$80
  DEFB $01,$00
  DEFB $03,$A0
  DEFB $02,$08
  DEFB $15,$F0
  DEFB $05,$A8
  DEFB $06,$60
  DEFB $01,$80
  DEFB $08,$20
  DEFB $04,$80
  DEFB $00,$10
  DEFB $00,$00
  DEFB $0F,$00,$00,$00,$80,$00,$00,$01
  DEFB $00,$04,$10,$01,$82,$03,$60,$45
  DEFB $68,$0E,$B0,$07,$42,$09,$90,$01
  DEFB $00,$20,$00,$00,$08,$10,$80

; Spell, thrown by the wizard, drawn for sprite $37
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_37:
  DEFB $0F
  DEFB $00,$00
  DEFB $01,$00
  DEFB $10,$04
  DEFB $00,$00
  DEFB $00,$40
  DEFB $01,$90
  DEFB $07,$40
  DEFB $05,$E2
  DEFB $17,$68
  DEFB $03,$C0
  DEFB $09,$C0
  DEFB $00,$02
  DEFB $01,$00
  DEFB $00,$00
  DEFB $00,$00

; Cursor keys icon, in two halves, drawn for sprite $32
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_32:
  DEFB $14
  DEFB $00,$01
  DEFB $00,$03
  DEFB $00,$07
  DEFB $00,$0F
  DEFB $00,$1F
  DEFB $00,$43
  DEFB $00,$C3
  DEFB $01,$C3
  DEFB $03,$F8
  DEFB $07,$F8
  DEFB $07,$F8
  DEFB $03,$F8
  DEFB $01,$C3
  DEFB $00,$C3
  DEFB $00,$43
  DEFB $00,$1F
  DEFB $00,$0F
  DEFB $00,$07
  DEFB $00,$03
  DEFB $00,$01

; Cursor keys icon, in two halves, drawn for sprite $33
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_33:
  DEFB $14
  DEFB $80,$00
  DEFB $C0,$00
  DEFB $E0,$00
  DEFB $F0,$00
  DEFB $F8,$00
  DEFB $C2,$00
  DEFB $C3,$00
  DEFB $C3,$80
  DEFB $1F,$C0
  DEFB $1F,$E0
  DEFB $1F,$E0
  DEFB $1F,$C0
  DEFB $C3,$80
  DEFB $C3,$00
  DEFB $C2,$00
  DEFB $F8,$00
  DEFB $F0,$00
  DEFB $E0,$00
  DEFB $C0,$00
  DEFB $80,$00

; Keyboard icon, in two halves, drawn for sprite $48
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_48:
  DEFB $10
  DEFB $0F,$FF
  DEFB $0F,$FF
  DEFB $09,$24
  DEFB $09,$24
  DEFB $0F,$FF
  DEFB $09,$24
  DEFB $09,$24
  DEFB $0F,$FF
  DEFB $0C,$92
  DEFB $0C,$92
  DEFB $07,$FF
  DEFB $08,$00
  DEFB $0F,$FF
  DEFB $08,$45
  DEFB $0D,$11
  DEFB $07,$FF

; Keyboard icon, in two halves, drawn for sprite $49
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_49:
  DEFB $10
  DEFB $FF,$F8
  DEFB $FF,$F8
  DEFB $92,$48
  DEFB $92,$48
  DEFB $FF,$F8
  DEFB $92,$48
  DEFB $92,$48
  DEFB $FF,$F8
  DEFB $49,$38
  DEFB $49,$38
  DEFB $FF,$F0
  DEFB $00,$08
  DEFB $FF,$F8
  DEFB $FF,$F8
  DEFB $FF,$F8
  DEFB $FF,$F0

; Joystick icon, in two halves, drawn for sprite $4A
;
; 23 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4A:
  DEFB $17
  DEFB $00,$C7
  DEFB $01,$8F
  DEFB $03,$1F
  DEFB $00,$00
  DEFB $03,$1F
  DEFB $01,$8F
  DEFB $00,$C7
  DEFB $00,$00
  DEFB $00,$33
  DEFB $00,$0B
  DEFB $00,$0B
  DEFB $00,$0B
  DEFB $00,$01
  DEFB $00,$01
  DEFB $00,$00
  DEFB $00,$03
  DEFB $00,$07
  DEFB $00,$0F
  DEFB $00,$09
  DEFB $00,$09
  DEFB $00,$0C
  DEFB $00,$06
  DEFB $00,$03

; Joystick icon, in two halves, drawn for sprite $4B
;
; 23 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4B:
  DEFB $17
  DEFB $FF,$00
  DEFB $FF,$80
  DEFB $FF,$C0
  DEFB $00,$00
  DEFB $FF,$C0
  DEFB $FF,$80
  DEFB $FF,$00
  DEFB $00,$00
  DEFB $FC,$00
  DEFB $F0,$00
  DEFB $F0,$00
  DEFB $F0,$00
  DEFB $80,$00
  DEFB $80,$00
  DEFB $00,$00
  DEFB $C0,$00
  DEFB $E0,$00
  DEFB $F0,$00
  DEFB $F0,$00
  DEFB $F0,$00
  DEFB $70,$00
  DEFB $60,$00
  DEFB $C0,$00

; Cave door frame, drawn for sprite $A2, $C4
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_A2:
  DEFB $04,$18
  DEFB $FF,$00,$00,$FF
  DEFB $03,$00,$00,$B0
  DEFB $03,$00,$00,$B0
  DEFB $07,$00,$00,$98
  DEFB $0D,$00,$00,$98
  DEFB $18,$80,$01,$0E
  DEFB $38,$80,$01,$0C
  DEFB $78,$80,$01,$18
  DEFB $58,$80,$01,$30
  DEFB $CC,$80,$01,$38
  DEFB $8C,$40,$02,$2C
  DEFB $0C,$40,$02,$26
  DEFB $0C,$40,$02,$3B
  DEFB $1C,$40,$02,$E1
  DEFB $34,$40,$02,$83
  DEFB $62,$20,$04,$86
  DEFB $F2,$20,$04,$86
  DEFB $7F,$2C,$05,$4C
  DEFB $0F,$62,$25,$4C
  DEFB $03,$C1,$7D,$58
  DEFB $00,$F0,$DF,$78
  DEFB $00,$3D,$87,$F0
  DEFB $00,$0F,$00,$C0
  DEFB $00,$02,$00,$00

; Pumpkin, drawn for sprite $4C
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4C:
  DEFB $13
  DEFB $07,$E0
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $7D,$BE
  DEFB $7B,$9E
  DEFB $F5,$0F
  DEFB $EF,$67
  DEFB $F6,$67
  DEFB $FF,$FF
  DEFB $FF,$7F
  DEFB $EA,$47
  DEFB $F7,$CF
  DEFB $7B,$CE
  DEFB $7F,$FE
  DEFB $3F,$FC
  DEFB $0D,$B0
  DEFB $01,$C0
  DEFB $00,$E0
  DEFB $00,$60

; Pumpkin, drawn for sprite $4D
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4D:
  DEFB $13
  DEFB $07,$E0
  DEFB $1F,$F8
  DEFB $3F,$FC
  DEFB $7D,$FE
  DEFB $79,$BE
  DEFB $F0,$5F
  DEFB $E6,$EF
  DEFB $E6,$77
  DEFB $FF,$FF
  DEFB $FE,$FF
  DEFB $E2,$6F
  DEFB $F3,$DF
  DEFB $73,$FF
  DEFB $7F,$FE
  DEFB $3F,$FC
  DEFB $0D,$B0
  DEFB $01,$C0
  DEFB $00,$E0
  DEFB $00,$60

; Which corners to join up, for shape $09, $0A
;
; Groups of vertex numbers, each closed by an $FF, and a second $FF ends the
; list. DRAW_OUTLINE draws from the first number in a group to each of the
; others in turn.
;
; Shared by 2 shapes, which is how a room and its mirror image are drawn from
; one description.
SHAPE_EDGES_09:
  DEFB $00,$17,$01,$04,$FF,$01,$FF,$02
  DEFB $03,$19,$01,$FF,$03,$FF,$04,$FF
  DEFB $05,$06,$1B,$03,$FF,$06,$FF,$07
  DEFB $08,$06,$1D,$FF,$08,$FF,$09,$04
  DEFB $33,$0A,$FF,$0A,$FF,$0B,$0D,$1F
  DEFB $08,$FF,$0C,$FF,$0D,$FF,$0E,$0F
  DEFB $0D,$0C,$FF,$0F,$FF,$10,$31,$0A
  DEFB $35,$FF,$11,$12,$23,$0F,$FF,$12
  DEFB $FF,$13,$36,$35,$FF,$14,$25,$15
  DEFB $12,$FF,$15,$FF,$16,$17,$04,$33
  DEFB $FF,$17,$FF,$18,$19,$17,$01,$FF
  DEFB $19,$FF,$1A,$1B,$19,$03,$FF,$1B
  DEFB $FF,$1C,$1D,$1B,$06,$FF,$1D,$FF
  DEFB $1E,$1F,$1D,$08,$FF,$1F,$FF,$20
  DEFB $0D,$1F,$FF,$21,$FF,$22,$23,$21
  DEFB $0F,$FF,$23,$FF,$24,$25,$23,$12
  DEFB $FF,$25,$FF,$26,$25,$27,$15,$FF
  DEFB $27,$FF,$28,$27,$29,$3C,$FF,$29
  DEFB $FF,$2A,$2B,$3A,$29,$FF,$2B,$FF
  DEFB $2C,$2D,$2B,$38,$FF,$2D,$FF,$2E
  DEFB $2F,$2D,$36,$FF,$2F,$FF,$30,$13
  DEFB $31,$2F,$FF,$31,$FF,$32,$33,$31
  DEFB $0A,$FF,$33,$FF,$34,$FF,$35,$34
  DEFB $FF,$36,$FF,$37,$2D,$38,$36,$FF
  DEFB $38,$FF,$39,$2B,$38,$3A,$FF,$3A
  DEFB $FF,$3B,$3A,$29,$3C,$FF,$3C,$FF
  DEFB $3D,$15,$3C,$27,$FF,$FF

; The corners of shape $0A
;
; 62 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_0A:
  DEFB $79,$0A
  DEFB $86,$04
  DEFB $91,$04
  DEFB $A6,$19
  DEFB $46,$0A
  DEFB $9B,$38
  DEFB $A7,$4B
  DEFB $9A,$58
  DEFB $AA,$68
  DEFB $37,$01
  DEFB $2A,$07
  DEFB $9B,$7E
  DEFB $9B,$87
  DEFB $9B,$8F
  DEFB $A8,$8F
  DEFB $95,$A1
  DEFB $2A,$1E
  DEFB $95,$B8
  DEFB $88,$BE
  DEFB $24,$30
  DEFB $79,$B5
  DEFB $46,$B5
  DEFB $4F,$27
  DEFB $70,$27
  DEFB $79,$23
  DEFB $82,$23
  DEFB $8F,$30
  DEFB $84,$47
  DEFB $89,$52
  DEFB $80,$5B
  DEFB $8B,$66
  DEFB $85,$74
  DEFB $85,$7D
  DEFB $89,$80
  DEFB $81,$88
  DEFB $81,$99
  DEFB $77,$9D
  DEFB $70,$98
  DEFB $4F,$98
  DEFB $46,$9C
  DEFB $3D,$9C
  DEFB $30,$8F
  DEFB $3B,$78
  DEFB $36,$6D
  DEFB $3F,$64
  DEFB $34,$59
  DEFB $3A,$4C
  DEFB $3A,$42
  DEFB $36,$3F
  DEFB $3E,$37
  DEFB $3E,$26
  DEFB $47,$22
  DEFB $24,$38
  DEFB $18,$30
  DEFB $24,$41
  DEFB $15,$57
  DEFB $25,$67
  DEFB $18,$74
  DEFB $24,$87
  DEFB $18,$A6
  DEFB $2E,$BB
  DEFB $39,$BB

; The corners of shape $09
;
; 62 points, x then y, indexed by the numbers in the edge list.
SHAPE_VERTI_09:
  DEFB $0A,$79
  DEFB $04,$86
  DEFB $04,$91
  DEFB $19,$A6
  DEFB $0A,$46
  DEFB $38,$9B
  DEFB $4B,$A7
  DEFB $58,$9A
  DEFB $68,$AA
  DEFB $01,$37
  DEFB $07,$2A
  DEFB $7E,$9B
  DEFB $87,$9B
  DEFB $8F,$9B
  DEFB $8F,$A8
  DEFB $A1,$95
  DEFB $1E,$2A
  DEFB $B8,$95
  DEFB $BE,$88
  DEFB $30,$24
  DEFB $B5,$79
  DEFB $B5,$46
  DEFB $27,$4F
  DEFB $27,$70
  DEFB $23,$79
  DEFB $23,$82
  DEFB $30,$8F
  DEFB $47,$84
  DEFB $52,$89
  DEFB $5B,$80
  DEFB $66,$8B
  DEFB $74,$85
  DEFB $7D,$85
  DEFB $80,$89
  DEFB $88,$81
  DEFB $99,$81
  DEFB $9D,$77
  DEFB $98,$70
  DEFB $98,$4F
  DEFB $9C,$46
  DEFB $9C,$3D
  DEFB $8F,$30
  DEFB $78,$3B
  DEFB $6D,$36
  DEFB $64,$3F
  DEFB $59,$34
  DEFB $4C,$3A
  DEFB $42,$3A
  DEFB $3F,$36
  DEFB $37,$3E
  DEFB $26,$3E
  DEFB $22,$47
  DEFB $38,$24
  DEFB $30,$18
  DEFB $41,$24
  DEFB $57,$15
  DEFB $67,$25
  DEFB $74,$18
  DEFB $87,$24
  DEFB $A6,$18
  DEFB $BB,$2E
  DEFB $BB,$39

; The text font
;
; 59 characters, eight bytes each, for the codes $20 (space) to $5A ("Z") -- so
; the game can print spaces, digits, punctuation and capitals, and nothing
; else.
;
; The code never names this address. It loads TEXT_FONT less $100 into the tile
; source instead, which is this block less $20 characters, so that a
; character's own ASCII code indexes it. DRAW_SUMMARY+30 and DRAW_SCORE load
; FONT_DIGITS for the same reason one bias further on: that is where "0" lives,
; so a digit's value indexes its own glyph with no adjustment at all. Drawing
; the two glyphs out confirms it -- FONT_DIGITS is a nought, TEXT_FONT less
; $100 plus $41 characters is an A, and plus $5A is a Z.
TEXT_FONT:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $18,$18,$18,$18,$18,$00,$18,$18
  DEFB $28,$28,$00,$00,$00,$00,$00,$00
  DEFB $00,$18,$18,$00,$00,$18,$18,$00
  DEFB $00,$62,$64,$08,$10,$26,$46,$00
  DEFB $3C,$42,$99,$A1,$A1,$99,$42,$3C
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $10,$10,$00,$00,$00,$00,$00,$00
  DEFB $08,$18,$18,$18,$18,$18,$18,$08
  DEFB $10,$18,$18,$18,$18,$18,$18,$10
  DEFB $00,$14,$58,$3E,$7C,$1A,$28,$00
  DEFB $00,$18,$18,$7E,$78,$18,$18,$00
  DEFB $00,$00,$00,$00,$00,$00,$20,$20
  DEFB $00,$00,$00,$7E,$7E,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$18,$18
  DEFB $0C,$0C,$18,$18,$30,$30,$60,$60
FONT_DIGITS:
  DEFB $7C,$FE,$C6,$C6,$C6,$FE,$7C,$00
  DEFB $18,$38,$58,$18,$18,$18,$3C,$00
  DEFB $7C,$FE,$06,$7C,$C0,$FE,$FE,$00
  DEFB $FE,$FC,$08,$1C,$06,$FE,$FC,$00
  DEFB $0C,$1C,$3C,$6C,$FE,$0C,$0C,$00
  DEFB $FE,$FE,$C0,$FC,$06,$FE,$7C,$00
  DEFB $7C,$FE,$C0,$FC,$C6,$FE,$7C,$00
  DEFB $FE,$FC,$0C,$18,$18,$30,$30,$00
  DEFB $7C,$FE,$C6,$7C,$C6,$FE,$7C,$00
  DEFB $7C,$FE,$C6,$7E,$06,$FE,$7C,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $38,$38,$6C,$7C,$EE,$EE,$C6,$00
  DEFB $FC,$FE,$E6,$FC,$E6,$FE,$FC,$00
  DEFB $3C,$7E,$F8,$E0,$F8,$7E,$3C,$00
  DEFB $F8,$FC,$FE,$C6,$FE,$FC,$F8,$00
  DEFB $F8,$F8,$E0,$FC,$E0,$FE,$FE,$00
  DEFB $FE,$FE,$E0,$FC,$E0,$E0,$E0,$00
  DEFB $3C,$7E,$F8,$E0,$FE,$7E,$3A,$00
  DEFB $EE,$EE,$FE,$FE,$FE,$EE,$EE,$00
  DEFB $7C,$7C,$38,$38,$38,$7C,$7C,$00
  DEFB $0E,$0E,$0E,$0E,$EE,$7C,$38,$00
  DEFB $EE,$EC,$F8,$F8,$F8,$EC,$EE,$00
  DEFB $E0,$E0,$E0,$E0,$FE,$FE,$FE,$00
  DEFB $82,$EE,$FE,$FE,$D6,$D6,$D6,$00
  DEFB $8E,$CE,$EE,$FE,$EE,$E6,$E2,$00
  DEFB $38,$7C,$FE,$EE,$FE,$7C,$38,$00
  DEFB $FC,$FE,$E6,$FE,$FC,$E0,$E0,$00
  DEFB $38,$7C,$FE,$EE,$FE,$7C,$3E,$00
  DEFB $FC,$FE,$E6,$FE,$FC,$EC,$EE,$00
  DEFB $7C,$FE,$F0,$7C,$1E,$FE,$7C,$00
  DEFB $FE,$FE,$FE,$38,$38,$38,$38,$00
  DEFB $EE,$EE,$EE,$EE,$FE,$FE,$7C,$00
  DEFB $EE,$EE,$6C,$7C,$38,$38,$10,$00
  DEFB $D6,$D6,$D6,$FE,$FE,$EE,$82,$00
  DEFB $EE,$EE,$6C,$38,$6C,$EE,$EE,$00
  DEFB $EE,$6C,$7C,$38,$38,$38,$38,$00
  DEFB $FE,$FC,$F8,$10,$3E,$7E,$FE,$00

; Food, drawn for sprite $50
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_50:
  DEFB $14
  DEFB $07,$E0
  DEFB $18,$18
  DEFB $2F,$F4
  DEFB $7E,$1E
  DEFB $3E,$34
  DEFB $3E,$54
  DEFB $3E,$EC
  DEFB $3D,$DC
  DEFB $3D,$BC
  DEFB $39,$DC
  DEFB $23,$BC
  DEFB $27,$7C
  DEFB $26,$BC
  DEFB $2F,$FC
  DEFB $38,$1C
  DEFB $20,$C4
  DEFB $5D,$22
  DEFB $20,$C4
  DEFB $18,$18
  DEFB $07,$E0

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $88
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_88:
  DEFB $10
  DEFB $1F,$F8
  DEFB $7F,$7E
  DEFB $F8,$1E
  DEFB $F0,$4F
  DEFB $F8,$0F
  DEFB $F9,$7F
  DEFB $FC,$0F
  DEFB $7F,$7F
  DEFB $7F,$FF
  DEFB $3E,$1E
  DEFB $1D,$EE
  DEFB $87,$B4
  DEFB $7F,$18
  DEFB $CE,$04
  DEFB $11,$34
  DEFB $0E,$C8

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $83
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_83:
  DEFB $10
  DEFB $07,$A0
  DEFB $1F,$E8
  DEFB $3B,$74
  DEFB $6A,$9A
  DEFB $5F,$DA
  DEFB $D8,$CD
  DEFB $B0,$75
  DEFB $FC,$75
  DEFB $F2,$35
  DEFB $C0,$1D
  DEFB $C8,$1D
  DEFB $76,$3A
  DEFB $70,$3A
  DEFB $38,$74
  DEFB $1F,$E8
  DEFB $07,$A0

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $87
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_87:
  DEFB $0D
  DEFB $1F,$F8
  DEFB $28,$14
  DEFB $48,$12
  DEFB $9A,$B1
  DEFB $F7,$EF
  DEFB $D5,$58
  DEFB $A7,$B5
  DEFB $F7,$F1
  DEFB $08,$0F
  DEFB $F7,$F1
  DEFB $77,$52
  DEFB $37,$D4
  DEFB $17,$F8

; Food, drawn for sprite $51
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_51:
  DEFB $10
  DEFB $10,$00
  DEFB $38,$00
  DEFB $44,$00
  DEFB $82,$00
  DEFB $7F,$00
  DEFB $3F,$80
  DEFB $10,$40
  DEFB $08,$20
  DEFB $07,$F0
  DEFB $03,$F8
  DEFB $01,$04
  DEFB $00,$82
  DEFB $00,$7F
  DEFB $00,$3E
  DEFB $00,$14
  DEFB $00,$08

; Food, drawn for sprite $52
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_52:
  DEFB $14
  DEFB $0F,$FC
  DEFB $10,$02
  DEFB $11,$C1
  DEFB $11,$C3
  DEFB $18,$0E
  DEFB $0F,$FC
  DEFB $0F,$F8
  DEFB $07,$F8
  DEFB $07,$F0
  DEFB $07,$F0
  DEFB $03,$E0
  DEFB $03,$E0
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$C0
  DEFB $07,$E0
  DEFB $07,$60

; Food, drawn for sprite $53
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_53:
  DEFB $12
  DEFB $00,$18
  DEFB $00,$38
  DEFB $00,$30
  DEFB $00,$70
  DEFB $00,$60
  DEFB $00,$E0
  DEFB $0F,$40
  DEFB $3F,$C0
  DEFB $7F,$E0
  DEFB $7F,$E0
  DEFB $FF,$F0
  DEFB $CF,$F0
  DEFB $CF,$F0
  DEFB $C7,$F0
  DEFB $61,$E0
  DEFB $71,$E0
  DEFB $3F,$C0
  DEFB $0F,$00

; Food, drawn for sprite $54
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; The last 4 bytes of it are also the start of the next graphic, at $C23A,
; which begins inside this one. Both are real: running the game's own drawing
; code for each sprite reads each range in full. The listing below stops at
; $C23A so the two blocks do not claim the same bytes, so it is 2 rows short of
; the 18 this graphic actually has.
GFX_54:
  DEFB $12
  DEFB $00,$01
  DEFB $00,$0F
  DEFB $00,$54
  DEFB $03,$FE
  DEFB $15,$54
  DEFB $3F,$FC
  DEFB $7D,$54
  DEFB $07,$F8
  DEFB $C9,$D0
  DEFB $D0,$F8
  DEFB $E8,$D0
  DEFB $F2,$70
  DEFB $79,$50
  DEFB $74,$60
  DEFB $3D,$40
  DEFB $0F,$00

; Monster, spawning, drawn for sprite $58
;
; 12 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_58:
  DEFB $0C
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $02,$00
  DEFB $01,$40
  DEFB $04,$20
  DEFB $02,$80
  DEFB $0A,$A0
  DEFB $00,$50
  DEFB $01,$00
  DEFB $04,$40

; Monster, spawning, drawn for sprite $59
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_59:
  DEFB $0D
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$80
  DEFB $02,$00
  DEFB $09,$50
  DEFB $04,$80
  DEFB $02,$D0
  DEFB $0B,$88
  DEFB $01,$A0
  DEFB $15,$08
  DEFB $00,$A0
  DEFB $02,$00

; Monster, spawning, drawn for sprite $5A
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5A:
  DEFB $0F
  DEFB $00,$00
  DEFB $01,$20
  DEFB $02,$08
  DEFB $80,$A0
  DEFB $22,$14
  DEFB $14,$60
  DEFB $03,$50
  DEFB $55,$82
  DEFB $09,$74
  DEFB $13,$40
  DEFB $24,$50
  DEFB $01,$94
  DEFB $0A,$40
  DEFB $00,$10
  DEFB $01,$00

; Monster, spawning, drawn for sprite $5B
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5B:
  DEFB $10
  DEFB $00,$80
  DEFB $12,$08
  DEFB $00,$40
  DEFB $2A,$02
  DEFB $00,$A8
  DEFB $85,$40
  DEFB $12,$52
  DEFB $45,$A8
  DEFB $11,$14
  DEFB $05,$28
  DEFB $52,$52
  DEFB $05,$00
  DEFB $08,$90
  DEFB $22,$44
  DEFB $09,$20
  DEFB $00,$40

; Cave door, locked, red, drawn for sprite $AD, $AE, $AF, $B0
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
;
; Shared by 4 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_AD:
  DEFB $04,$18
  DEFB $FF,$1B,$18,$FF
  DEFB $03,$1B,$18,$B0
  DEFB $03,$1B,$18,$B0
  DEFB $07,$1B,$18,$98
  DEFB $0D,$33,$0C,$98
  DEFB $1A,$33,$0C,$98
  DEFB $3A,$33,$0C,$EC
  DEFB $7A,$33,$00,$58
  DEFB $5A,$63,$0E,$70
  DEFB $CE,$63,$17,$78
  DEFB $8C,$63,$19,$2C
  DEFB $0C,$63,$0E,$26
  DEFB $0C,$C3,$00,$23
  DEFB $1C,$C3,$03,$21
  DEFB $32,$C3,$03,$43
  DEFB $62,$43,$02,$46
  DEFB $F8,$00,$00,$86
  DEFB $7F,$C0,$03,$0C
  DEFB $0F,$38,$1C,$0C
  DEFB $03,$C7,$FC,$18
  DEFB $00,$F0,$DF,$38
  DEFB $00,$3D,$87,$F0
  DEFB $00,$0F,$00,$C0
  DEFB $00,$02,$00,$00

; Spider, drawn for sprite $5C
;
; 14 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5C:
  DEFB $0E
  DEFB $0C,$30
  DEFB $0C,$30
  DEFB $C0,$03
  DEFB $C6,$63
  DEFB $60,$06
  DEFB $1F,$F8
  DEFB $39,$9C
  DEFB $74,$2E
  DEFB $76,$6E
  DEFB $79,$9E
  DEFB $7F,$FE
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $0F,$F0

; Spider, drawn for sprite $5D
;
; 14 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5D:
  DEFB $0E
  DEFB $00,$00
  DEFB $60,$06
  DEFB $66,$66
  DEFB $06,$60
  DEFB $33,$CC
  DEFB $1F,$F8
  DEFB $39,$9C
  DEFB $74,$2E
  DEFB $76,$6E
  DEFB $79,$9E
  DEFB $7F,$FE
  DEFB $3F,$FC
  DEFB $1F,$F8
  DEFB $0F,$F0

; Monster, not yet identified, drawn for sprite $5E
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5E:
  DEFB $10
  DEFB $03,$FF
  DEFB $FF,$FC
  DEFB $3F,$F0
  DEFB $0F,$FC
  DEFB $3F,$FF
  DEFB $FF,$FC
  DEFB $3F,$F8
  DEFB $13,$9E
  DEFB $65,$2F
  DEFB $ED,$68
  DEFB $33,$9E
  DEFB $3F,$F1
  DEFB $67,$F8
  DEFB $03,$B8
  DEFB $03,$1C
  DEFB $02,$00

; Monster, not yet identified, drawn for sprite $5F
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_5F:
  DEFB $10
  DEFB $FF,$80
  DEFB $7F,$FF
  DEFB $0F,$FC
  DEFB $3F,$F0
  DEFB $FF,$FF
  DEFB $7F,$FE
  DEFB $1F,$FC
  DEFB $33,$98
  DEFB $65,$2F
  DEFB $7D,$6E
  DEFB $73,$98
  DEFB $1F,$F8
  DEFB $3F,$F8
  DEFB $7F,$6E
  DEFB $63,$62
  DEFB $01,$20

; Monster, not yet identified, drawn for sprite $60
;
; 11 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_60:
  DEFB $0B
  DEFB $0E,$E0
  DEFB $1F,$F0
  DEFB $39,$38
  DEFB $34,$90
  DEFB $36,$D8
  DEFB $39,$38
  DEFB $1F,$F0
  DEFB $0F,$E0
  DEFB $1C,$70
  DEFB $38,$38
  DEFB $F0,$1E

; Monster, not yet identified, drawn for sprite $61
;
; 9 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_61:
  DEFB $09
  DEFB $0E,$E0
  DEFB $1F,$F0
  DEFB $39,$38
  DEFB $34,$98
  DEFB $36,$D8
  DEFB $39,$38
  DEFB $1F,$F0
  DEFB $3F,$F8
  DEFB $F8,$3E

; Ghost, drawn for sprite $62
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_62:
  DEFB $14
  DEFB $01,$C0
  DEFB $03,$80
  DEFB $03,$00
  DEFB $03,$00
  DEFB $83,$81
  DEFB $87,$C1
  DEFB $8F,$E1
  DEFB $CF,$F3
  DEFB $DF,$F3
  DEFB $DF,$FB
  DEFB $DF,$FB
  DEFB $DF,$FB
  DEFB $D9,$9B
  DEFB $D9,$9B
  DEFB $19,$98
  DEFB $19,$98
  DEFB $19,$98
  DEFB $1F,$F8
  DEFB $0F,$F0
  DEFB $07,$E0

; Ghost, drawn for sprite $63
;
; 20 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_63:
  DEFB $14
  DEFB $03,$80
  DEFB $01,$C0
  DEFB $00,$C0
  DEFB $00,$C0
  DEFB $01,$C0
  DEFB $03,$E0
  DEFB $87,$F1
  DEFB $8F,$F1
  DEFB $8F,$F9
  DEFB $DF,$FB
  DEFB $DF,$FB
  DEFB $DF,$FB
  DEFB $D9,$9B
  DEFB $D9,$9B
  DEFB $D9,$9B
  DEFB $D9,$9B
  DEFB $99,$99
  DEFB $0F,$F0
  DEFB $0F,$F0
  DEFB $07,$E0

; Ghost, a second kind, drawn for sprite $68
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_68:
  DEFB $10
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $7F,$FE
  DEFB $FF,$FF
  DEFB $FF,$FF
  DEFB $7F,$FE
  DEFB $3F,$FE
  DEFB $1F,$FC
  DEFB $1C,$EC
  DEFB $18,$44
  DEFB $18,$44
  DEFB $1C,$44
  DEFB $0C,$CC
  DEFB $0F,$F8
  DEFB $07,$F0
  DEFB $03,$C0

; Ghost, a second kind, drawn for sprite $69
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_69:
  DEFB $10
  DEFB $78,$0C
  DEFB $FC,$1E
  DEFB $FE,$3F
  DEFB $FF,$FF
  DEFB $7F,$FF
  DEFB $3F,$FE
  DEFB $1F,$FC
  DEFB $1F,$FC
  DEFB $1C,$EC
  DEFB $18,$44
  DEFB $18,$44
  DEFB $1C,$44
  DEFB $0C,$CC
  DEFB $0F,$F8
  DEFB $07,$F0
  DEFB $03,$C0

; Bat, a second kind, drawn for sprite $6A
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6A:
  DEFB $12
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $04,$40
  DEFB $0C,$60
  DEFB $03,$80
  DEFB $07,$C0
  DEFB $06,$C0
  DEFB $0D,$60
  DEFB $1F,$F0
  DEFB $1C,$70
  DEFB $38,$38
  DEFB $30,$18
  DEFB $60,$0C
  DEFB $40,$04
  DEFB $C0,$06
  DEFB $80,$02
  DEFB $80,$02

; Bat, a second kind, drawn for sprite $6B
;
; 14 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6B:
  DEFB $0E
  DEFB $80,$02
  DEFB $80,$02
  DEFB $80,$02
  DEFB $40,$04
  DEFB $60,$0C
  DEFB $64,$4C
  DEFB $3C,$78
  DEFB $3B,$B8
  DEFB $17,$D0
  DEFB $06,$C0
  DEFB $05,$40
  DEFB $0F,$E0
  DEFB $0C,$60
  DEFB $08,$20

; Roast chicken, picked to the bones, drawn for sprite $B5
;
; 30 rows of 48 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B5:
  DEFB $06,$1E
  DEFB $00,$00,$0F,$FF,$F8,$00
  DEFB $00,$00,$FF,$FE,$3E,$00
  DEFB $00,$07,$FF,$FD,$DF,$80
  DEFB $00,$1F,$E7,$01,$E8,$C0
  DEFB $00,$7E,$E4,$F0,$E7,$60
  DEFB $01,$F6,$73,$FC,$73,$80
  DEFB $03,$33,$27,$F8,$33,$C0
  DEFB $04,$18,$0F,$FD,$38,$C0
  DEFB $08,$00,$0F,$FD,$18,$E0
  DEFB $00,$00,$1F,$FD,$18,$E0
  DEFB $00,$00,$1F,$FD,$18,$E0
  DEFB $00,$00,$3F,$FD,$18,$E0
  DEFB $00,$00,$3F,$FB,$38,$E0
  DEFB $00,$00,$7F,$FB,$38,$E8
  DEFB $00,$00,$7F,$F6,$71,$D8
  DEFB $00,$1E,$DF,$EE,$71,$DC
  DEFB $00,$0D,$3F,$DC,$F3,$BC
  DEFB $00,$02,$FF,$3C,$E3,$78
  DEFB $00,$05,$E0,$79,$E3,$70
  DEFB $00,$0B,$9E,$F1,$D8,$E0
  DEFB $00,$17,$3E,$E3,$BF,$C0
  DEFB $0C,$2E,$1F,$1B,$7F,$80
  DEFB $1E,$DC,$07,$FC,$FE,$00
  DEFB $37,$B8,$01,$BB,$F8,$00
  DEFB $33,$F0,$00,$3F,$E0,$00
  DEFB $1D,$E0,$00,$00,$00,$00
  DEFB $03,$C0,$00,$00,$00,$00
  DEFB $06,$E0,$00,$00,$00,$00
  DEFB $06,$60,$00,$00,$00,$00
  DEFB $03,$C0,$00,$00,$00,$00

; Roast chicken, whole -- the health indicator, drawn for sprite $B4
;
; 30 rows of 48 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B4:
  DEFB $06,$1E
  DEFB $00,$00,$FF,$FF,$FE,$00
  DEFB $00,$07,$FF,$FF,$FF,$80
  DEFB $00,$1F,$FF,$0F,$FF,$C0
  DEFB $00,$7F,$FE,$F7,$FF,$E0
  DEFB $01,$FF,$F9,$BB,$FF,$F0
  DEFB $03,$FF,$F7,$FD,$FF,$F8
  DEFB $07,$FF,$EF,$F5,$FF,$FC
  DEFB $0F,$FF,$DF,$DE,$FF,$EC
  DEFB $1F,$DF,$5D,$BE,$FF,$FE
  DEFB $36,$FD,$BF,$F6,$DE,$FE
  DEFB $3F,$FF,$B7,$FE,$FF,$FE
  DEFB $1B,$BF,$7E,$BE,$FF,$BA
  DEFB $0E,$FB,$7F,$FD,$BB,$FA
  DEFB $07,$BE,$F7,$7D,$FF,$FE
  DEFB $01,$F6,$FF,$DB,$FF,$FE
  DEFB $00,$DD,$FE,$F7,$FF,$7E
  DEFB $00,$3B,$77,$ED,$7F,$DE
  DEFB $00,$17,$FE,$DF,$FF,$EC
  DEFB $00,$0B,$FF,$3F,$FB,$F8
  DEFB $00,$1F,$C0,$FB,$FF,$B0
  DEFB $00,$1F,$BF,$FF,$BF,$E0
  DEFB $0C,$2F,$37,$BF,$FB,$C0
  DEFB $1E,$DE,$1D,$FB,$FF,$80
  DEFB $37,$B8,$07,$BF,$BE,$00
  DEFB $33,$F0,$01,$FB,$F8,$00
  DEFB $1D,$E0,$00,$3F,$E0,$00
  DEFB $03,$C0,$00,$00,$00,$00
  DEFB $06,$E0,$00,$00,$00,$00
  DEFB $06,$60,$00,$00,$00,$00
  DEFB $03,$C0,$00,$00,$00,$00

; Burst, expanding, drawn for sprite $6C
;
; 11 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6C:
  DEFB $0B
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $03,$40
  DEFB $05,$C0
  DEFB $07,$60
  DEFB $06,$A0
  DEFB $03,$C0
  DEFB $01,$00

; Burst, expanding, drawn for sprite $6D
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6D:
  DEFB $0D
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$80
  DEFB $01,$A0
  DEFB $0B,$48
  DEFB $02,$F0
  DEFB $1F,$40
  DEFB $06,$F8
  DEFB $07,$B0
  DEFB $09,$C8
  DEFB $02,$A0
  DEFB $02,$90

; Burst, expanding, drawn for sprite $6E
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6E:
  DEFB $0F
  DEFB $00,$00
  DEFB $05,$00
  DEFB $11,$10
  DEFB $09,$10
  DEFB $04,$24
  DEFB $38,$08
  DEFB $00,$10
  DEFB $70,$00
  DEFB $00,$0E
  DEFB $10,$00
  DEFB $64,$2C
  DEFB $0A,$92
  DEFB $12,$A8
  DEFB $02,$80
  DEFB $00,$80

; Burst, expanding, drawn for sprite $6F
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_6F:
  DEFB $10
  DEFB $01,$00
  DEFB $11,$10
  DEFB $08,$20
  DEFB $00,$02
  DEFB $40,$04
  DEFB $20,$00
  DEFB $00,$00
  DEFB $C0,$00
  DEFB $00,$03
  DEFB $00,$00
  DEFB $40,$02
  DEFB $80,$01
  DEFB $00,$00
  DEFB $20,$04
  DEFB $44,$82
  DEFB $04,$80

; Wall antlers, drawn for sprite $B6
;
; 16 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B6:
  DEFB $04,$10
  DEFB $00,$03,$C0,$00
  DEFB $00,$04,$20,$00
  DEFB $00,$08,$10,$00
  DEFB $00,$13,$C8,$00
  DEFB $00,$27,$E4,$00
  DEFB $00,$2D,$B4,$00
  DEFB $00,$49,$92,$00
  DEFB $00,$7F,$FE,$00
  DEFB $03,$F9,$9F,$C0
  DEFB $07,$F5,$AF,$E0
  DEFB $0F,$F6,$6F,$F0
  DEFB $1C,$B9,$9D,$38
  DEFB $30,$9F,$F9,$0C
  DEFB $20,$8F,$F1,$04
  DEFB $00,$C0,$03,$00
  DEFB $00,$3F,$FC,$00

; Wall trophy, drawn for sprite $B7
;
; 16 rows of 16 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B7:
  DEFB $02,$10
  DEFB $03,$C0
  DEFB $04,$20
  DEFB $08,$10
  DEFB $13,$C8
  DEFB $27,$E4
  DEFB $2D,$B4
  DEFB $4D,$B2
  DEFB $4F,$F2
  DEFB $49,$92
  DEFB $94,$29
  DEFB $B6,$6D
  DEFB $B9,$9D
  DEFB $BF,$FD
  DEFB $98,$19
  DEFB $C0,$03
  DEFB $3F,$FC

; Bookcase, drawn for sprite $B8
;
; 32 rows of 40 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B8:
  DEFB $05,$20
  DEFB $1F,$FF,$FF,$FF,$F8
  DEFB $18,$00,$00,$00,$18
  DEFB $14,$00,$00,$00,$28
  DEFB $13,$FF,$FF,$FF,$C8
  DEFB $12,$00,$00,$00,$48
  DEFB $12,$00,$00,$00,$48
  DEFB $12,$00,$00,$00,$48
  DEFB $3F,$FF,$FF,$FF,$FC
  DEFB $30,$00,$00,$00,$0C
  DEFB $28,$00,$00,$00,$14
  DEFB $24,$00,$00,$00,$24
  DEFB $23,$FF,$FF,$FF,$C4
  DEFB $22,$00,$00,$00,$44
  DEFB $22,$00,$00,$00,$44
  DEFB $22,$00,$00,$00,$44
  DEFB $7F,$FF,$FF,$FF,$FE
  DEFB $60,$00,$00,$00,$06
  DEFB $50,$C6,$F6,$EF,$0A
  DEFB $48,$C7,$F6,$ED,$12
  DEFB $47,$CE,$F6,$EB,$E2
  DEFB $44,$CE,$F6,$ED,$22
  DEFB $44,$DC,$F6,$EB,$22
  DEFB $44,$DC,$F6,$ED,$22
  DEFB $44,$F8,$F6,$EB,$22
  DEFB $FF,$FF,$FF,$FF,$FF
  DEFB $00,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF,$FF
  DEFB $7F,$FF,$FF,$FF,$FE
  DEFB $3F,$FF,$FF,$FF,$FC
  DEFB $1F,$FF,$FF,$FF,$F8
  DEFB $0F,$FF,$FF,$FF,$F0
  DEFB $07,$FF,$FF,$FF,$E0

; Trapdoor, open, drawn for sprite $BA
;
; 32 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BA:
  DEFB $04,$20
  DEFB $00,$3C,$F0,$00
  DEFB $0E,$66,$F9,$C0
  DEFB $1F,$5E,$BB,$F8
  DEFB $3F,$5C,$D1,$FC
  DEFB $77,$58,$55,$FE
  DEFB $7B,$6B,$56,$0E
  DEFB $DD,$BB,$77,$F6
  DEFB $DF,$D8,$01,$8E
  DEFB $4F,$00,$00,$76
  DEFB $63,$00,$00,$F2
  DEFB $3E,$00,$00,$F0
  DEFB $00,$00,$00,$CE
  DEFB $7E,$00,$00,$1F
  DEFB $3F,$00,$00,$7F
  DEFB $DE,$00,$00,$5F
  DEFB $DB,$00,$00,$63
  DEFB $BE,$00,$00,$3E
  DEFB $E0,$00,$00,$00
  DEFB $0E,$00,$00,$3E
  DEFB $7E,$00,$00,$7F
  DEFB $4E,$00,$00,$43
  DEFB $73,$00,$00,$7D
  DEFB $3F,$00,$00,$0F
  DEFB $00,$00,$00,$E3
  DEFB $3F,$36,$7D,$78
  DEFB $7F,$EE,$FE,$BC
  DEFB $6F,$EE,$BE,$BC
  DEFB $2F,$DA,$BE,$CC
  DEFB $37,$DE,$BF,$78
  DEFB $19,$DA,$C7,$60
  DEFB $0F,$CE,$7E,$00
  DEFB $01,$C6,$00,$00

; Trapdoor, closed, drawn for sprite $B9
;
; 32 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_B9:
  DEFB $04,$20
  DEFB $00,$3C,$F0,$00
  DEFB $0E,$66,$F9,$C0
  DEFB $1F,$5E,$BB,$F8
  DEFB $3F,$5C,$D1,$FC
  DEFB $77,$58,$55,$FE
  DEFB $7B,$6B,$56,$0E
  DEFB $DD,$BB,$77,$F6
  DEFB $DF,$D8,$01,$8E
  DEFB $4F,$FF,$FF,$76
  DEFB $63,$92,$49,$F2
  DEFB $3E,$92,$49,$F0
  DEFB $00,$FF,$F9,$CE
  DEFB $7E,$EA,$AD,$1F
  DEFB $3F,$FF,$F9,$7F
  DEFB $DE,$92,$49,$5F
  DEFB $DB,$92,$49,$63
  DEFB $BE,$92,$49,$3E
  DEFB $E0,$92,$49,$00
  DEFB $0E,$FF,$F9,$3E
  DEFB $7E,$EA,$AD,$7F
  DEFB $4E,$FF,$F9,$43
  DEFB $73,$92,$49,$7D
  DEFB $3F,$92,$49,$0F
  DEFB $00,$FF,$FF,$E3
  DEFB $3F,$36,$7D,$78
  DEFB $7F,$EE,$FE,$BC
  DEFB $6F,$EE,$BE,$BC
  DEFB $2F,$DA,$BE,$CC
  DEFB $37,$DE,$BF,$78
  DEFB $19,$DA,$C7,$60
  DEFB $0F,$CE,$7E,$00
  DEFB $01,$C6,$00,$00

; Rug, drawn for sprite $BC
;
; 39 rows of 48 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BC:
  DEFB $06,$27
  DEFB $00,$03,$80,$00,$02,$00
  DEFB $00,$07,$C0,$00,$0D,$00
  DEFB $00,$07,$C0,$00,$1E,$00
  DEFB $00,$07,$C0,$00,$1F,$00
  DEFB $00,$03,$C0,$00,$1F,$00
  DEFB $00,$03,$80,$00,$3E,$00
  DEFB $00,$03,$80,$00,$3C,$00
  DEFB $00,$03,$80,$00,$7C,$00
  DEFB $00,$03,$80,$00,$78,$00
  DEFB $00,$03,$80,$00,$70,$00
  DEFB $00,$02,$80,$00,$F0,$00
  DEFB $00,$07,$80,$00,$B0,$00
  DEFB $00,$07,$C7,$E1,$F0,$00
  DEFB $00,$06,$7E,$3B,$20,$00
  DEFB $00,$07,$FD,$DF,$E0,$00
  DEFB $03,$CF,$1E,$3C,$E0,$00
  DEFB $0F,$FE,$EF,$FB,$70,$00
  DEFB $79,$BF,$1C,$FC,$DE,$00
  DEFB $BB,$D9,$FB,$67,$F3,$F0
  DEFB $FF,$F6,$FC,$DB,$1E,$7F
  DEFB $BB,$D9,$8F,$E6,$EF,$CE
  DEFB $E9,$BF,$76,$3F,$1C,$03
  DEFB $0F,$FB,$8D,$D9,$F0,$00
  DEFB $03,$CC,$FE,$36,$E0,$00
  DEFB $00,$07,$C7,$F9,$E0,$00
  DEFB $00,$07,$FF,$FF,$20,$00
  DEFB $00,$04,$C7,$E1,$F0,$00
  DEFB $00,$07,$80,$00,$B0,$00
  DEFB $00,$02,$80,$00,$F0,$00
  DEFB $00,$03,$80,$00,$50,$00
  DEFB $00,$02,$80,$00,$78,$00
  DEFB $00,$03,$80,$00,$7C,$00
  DEFB $00,$03,$80,$00,$3C,$00
  DEFB $00,$03,$80,$00,$3E,$00
  DEFB $00,$03,$C0,$00,$1F,$00
  DEFB $00,$07,$C0,$00,$1F,$00
  DEFB $00,$07,$C0,$00,$1E,$00
  DEFB $00,$07,$C0,$00,$0D,$00
  DEFB $00,$03,$80,$00,$02,$00

; Colours for a graphic, entry $DD of the attribute table
;
; One attribute per character cell, 4 across by 2 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_DD:
  DEFB $04,$02
  DEFB $47,$47,$47,$47
  DEFB $47,$47,$47,$47

; Colours for a graphic, entry $DE of the attribute table
;
; One attribute per character cell, 2 across by 2 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_DE:
  DEFB $02,$02
  DEFB $45,$45
  DEFB $45,$45

; Colours for a graphic, entry $DF of the attribute table
;
; One attribute per character cell, 5 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_DF:
  DEFB $05,$04
  DEFB $46,$46,$46,$46,$46
  DEFB $46,$46,$46,$46,$46
  DEFB $46,$45,$43,$44,$46
  DEFB $46,$46,$46,$46,$46

; Colours for a graphic, entry $E1 of the attribute table
;
; One attribute per character cell, 4 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E1:
  DEFB $04,$04
  DEFB $43,$43,$43,$43
  DEFB $43,$00,$00,$43
  DEFB $43,$00,$00,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $E0 of the attribute table
;
; One attribute per character cell, 4 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E0:
  DEFB $04,$04
  DEFB $43,$43,$43,$43
  DEFB $43,$46,$46,$43
  DEFB $43,$46,$46,$43
  DEFB $43,$43,$43,$43

; Colours for a graphic, entry $E3 of the attribute table
;
; One attribute per character cell, 6 across by 5 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E3:
  DEFB $06,$05
  DEFB $07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07

; A.C.G. shield, drawn for sprite $BD
;
; 16 rows of 16 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BD:
  DEFB $02,$10
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $1F,$D8
  DEFB $30,$0C
  DEFB $3F,$DC
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $54,$42
  DEFB $D5,$DB
  DEFB $C5,$D3
  DEFB $D5,$DF
  DEFB $C4,$43
  DEFB $FF,$FF
  DEFB $E7,$E7
  DEFB $81,$81

; Wall shield, drawn for sprite $BE
;
; 16 rows of 16 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BE:
  DEFB $02,$10
  DEFB $01,$80
  DEFB $07,$E0
  DEFB $08,$10
  DEFB $19,$98
  DEFB $39,$9C
  DEFB $30,$0C
  DEFB $75,$AE
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $DC,$2F
  DEFB $D7,$EB
  DEFB $C4,$23
  DEFB $D7,$EB
  DEFB $FD,$7F
  DEFB $E7,$E7
  DEFB $81,$81

; Suit of armour, drawn for sprite $BF
;
; 32 rows of 16 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BF:
  DEFB $02,$20
  DEFB $30,$0C
  DEFB $1C,$38
  DEFB $1E,$7A
  DEFB $0E,$72
  DEFB $06,$62
  DEFB $0A,$52
  DEFB $1C,$3A
  DEFB $0A,$52
  DEFB $07,$E2
  DEFB $47,$E7
  DEFB $47,$E2
  DEFB $07,$E0
  DEFB $60,$06
  DEFB $67,$E6
  DEFB $A6,$65
  DEFB $CC,$33
  DEFB $AD,$B5
  DEFB $6D,$B6
  DEFB $7F,$FE
  DEFB $7F,$FE
  DEFB $78,$1E
  DEFB $37,$EC
  DEFB $03,$C0
  DEFB $07,$E0
  DEFB $0E,$70
  DEFB $19,$98
  DEFB $07,$E0
  DEFB $0F,$F0
  DEFB $07,$E0
  DEFB $03,$C0
  DEFB $00,$00
  DEFB $00,$00

; Colours for a graphic, entry $E4 of the attribute table
;
; One attribute per character cell, 2 across by 2 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E4:
  DEFB $02,$02
  DEFB $43,$47
  DEFB $47,$43

; Colours for a graphic, entry $E5 of the attribute table
;
; One attribute per character cell, 2 across by 2 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E5:
  DEFB $02,$02
  DEFB $FF,$FF
  DEFB $FF,$FF

; Colours for a graphic, entry $E6 of the attribute table
;
; One attribute per character cell, 2 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E6:
  DEFB $02,$04
  DEFB $45,$45
  DEFB $45,$45
  DEFB $45,$45
  DEFB $45,$45

; Colours for a graphic, entry $EA of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_EA:
  DEFB $04,$03
  DEFB $FF,$47,$47,$FF
  DEFB $FF,$47,$47,$FF
  DEFB $FF,$FF,$FF,$FF

; Colours for a graphic, entry $E8 of the attribute table
;
; One attribute per character cell, 4 across by 3 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E8:
  DEFB $04,$03
  DEFB $43,$47,$47,$43
  DEFB $43,$47,$47,$43
  DEFB $43,$43,$43,$43

; Door, shut, drawn for sprite $C1
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C1:
  DEFB $04,$18
  DEFB $FF,$3B,$DC,$FF
  DEFB $1F,$3B,$DC,$F8
  DEFB $0C,$3B,$DC,$40
  DEFB $3E,$3B,$DC,$7C
  DEFB $7C,$00,$00,$3E
  DEFB $04,$7B,$CE,$20
  DEFB $F8,$7B,$D7,$1F
  DEFB $F8,$7B,$D1,$1F
  DEFB $08,$7B,$CE,$08
  DEFB $F0,$7B,$C0,$0F
  DEFB $F0,$00,$00,$0F
  DEFB $10,$FB,$DF,$08
  DEFB $F0,$FB,$DF,$1F
  DEFB $F8,$7B,$DE,$1F
  DEFB $CC,$3B,$DC,$33
  DEFB $3F,$0B,$D0,$7C
  DEFB $7D,$80,$01,$BE
  DEFB $3B,$F0,$0F,$DC
  DEFB $17,$BF,$FD,$E8
  DEFB $07,$7B,$DE,$E0
  DEFB $03,$7B,$DE,$C0
  DEFB $00,$77,$EE,$00
  DEFB $00,$07,$E0,$00
  DEFB $00,$00,$00,$00

; Cave door, shut, drawn for sprite $C3
;
; 24 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C3:
  DEFB $04,$18
  DEFB $FF,$3B,$DC,$FF
  DEFB $03,$3B,$DC,$B0
  DEFB $03,$3B,$DC,$B0
  DEFB $07,$3B,$DC,$98
  DEFB $0D,$00,$00,$98
  DEFB $1A,$7B,$CE,$4E
  DEFB $3A,$7B,$D7,$EC
  DEFB $7A,$7B,$D1,$58
  DEFB $5A,$7B,$CE,$70
  DEFB $CE,$7B,$C0,$78
  DEFB $8C,$00,$00,$2C
  DEFB $0C,$FB,$DF,$26
  DEFB $0C,$FB,$DF,$23
  DEFB $1C,$7B,$DE,$21
  DEFB $32,$3B,$DC,$43
  DEFB $62,$0B,$D0,$46
  DEFB $F1,$00,$00,$86
  DEFB $7F,$C0,$03,$0C
  DEFB $0F,$38,$1C,$0C
  DEFB $03,$C7,$FC,$18
  DEFB $00,$F0,$DF,$38
  DEFB $00,$3D,$87,$F0
  DEFB $00,$0F,$00,$C0
  DEFB $00,$02,$00,$00

; Mummy, drawn for sprite $70
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_70:
  DEFB $18
  DEFB $0F,$00
  DEFB $0F,$78
  DEFB $03,$78
  DEFB $04,$30
  DEFB $07,$70
  DEFB $07,$40
  DEFB $01,$F0
  DEFB $07,$E0
  DEFB $0E,$20
  DEFB $0F,$E0
  DEFB $0F,$E0
  DEFB $04,$20
  DEFB $CF,$E5
  DEFB $E8,$67
  DEFB $F7,$CB
  DEFB $5B,$BE
  DEFB $17,$D4
  DEFB $03,$80
  DEFB $07,$C0
  DEFB $0C,$60
  DEFB $0F,$E0
  DEFB $0D,$60
  DEFB $07,$C0
  DEFB $03,$80

; Mummy, drawn for sprite $71, $73
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_71:
  DEFB $18
  DEFB $0F,$E8
  DEFB $0F,$E8
  DEFB $03,$30
  DEFB $04,$70
  DEFB $07,$40
  DEFB $07,$F0
  DEFB $01,$E0
  DEFB $07,$E0
  DEFB $07,$10
  DEFB $07,$F0
  DEFB $07,$F0
  DEFB $02,$10
  DEFB $AF,$E5
  DEFB $78,$67
  DEFB $F7,$CB
  DEFB $5B,$BE
  DEFB $17,$D4
  DEFB $03,$80
  DEFB $07,$C0
  DEFB $0C,$60
  DEFB $0F,$E0
  DEFB $0D,$60
  DEFB $07,$C0
  DEFB $03,$80

; Mummy, drawn for sprite $72
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_72:
  DEFB $18
  DEFB $00,$78
  DEFB $0F,$78
  DEFB $0F,$30
  DEFB $07,$70
  DEFB $04,$40
  DEFB $07,$70
  DEFB $07,$70
  DEFB $01,$E0
  DEFB $07,$10
  DEFB $07,$F0
  DEFB $07,$F0
  DEFB $02,$10
  DEFB $A7,$F5
  DEFB $E4,$37
  DEFB $F3,$EB
  DEFB $5B,$FE
  DEFB $17,$F4
  DEFB $01,$C0
  DEFB $03,$E0
  DEFB $06,$30
  DEFB $07,$F0
  DEFB $06,$B0
  DEFB $03,$E0
  DEFB $01,$C0

; Frankenstein's monster, drawn for sprite $74
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_74:
  DEFB $18
  DEFB $3E,$00
  DEFB $1E,$60
  DEFB $00,$F0
  DEFB $0E,$70
  DEFB $0E,$B0
  DEFB $0E,$C4
  DEFB $4F,$E4
  DEFB $4F,$EA
  DEFB $A0,$0A
  DEFB $AF,$EE
  DEFB $EE,$EE
  DEFB $FE,$FE
  DEFB $FF,$FE
  DEFB $7E,$FC
  DEFB $0F,$E0
  DEFB $20,$08
  DEFB $37,$D8
  DEFB $24,$48
  DEFB $0F,$E0
  DEFB $14,$50
  DEFB $16,$D0
  DEFB $10,$10
  DEFB $1A,$B0
  DEFB $0F,$E0

; Frankenstein's monster, drawn for sprite $75, $77
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_75:
  DEFB $18
  DEFB $1E,$F0
  DEFB $1E,$F0
  DEFB $00,$00
  DEFB $0E,$E0
  DEFB $4E,$E4
  DEFB $4E,$E4
  DEFB $AF,$EA
  DEFB $AF,$EA
  DEFB $E0,$0E
  DEFB $EF,$EE
  DEFB $EF,$EE
  DEFB $FE,$FE
  DEFB $FF,$FE
  DEFB $7E,$FC
  DEFB $0F,$E0
  DEFB $20,$08
  DEFB $37,$D8
  DEFB $24,$48
  DEFB $0F,$E0
  DEFB $14,$50
  DEFB $16,$D0
  DEFB $10,$10
  DEFB $1A,$B0
  DEFB $0F,$E0

; Frankenstein's monster, drawn for sprite $76
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_76:
  DEFB $18
  DEFB $00,$F8
  DEFB $0C,$F0
  DEFB $1E,$00
  DEFB $1C,$E0
  DEFB $1A,$E0
  DEFB $46,$E0
  DEFB $4F,$E0
  DEFB $AE,$E4
  DEFB $0A,$A0
  DEFB $EF,$EA
  DEFB $EF,$EE
  DEFB $FE,$FE
  DEFB $FF,$FE
  DEFB $7E,$FC
  DEFB $0F,$F0
  DEFB $20,$08
  DEFB $37,$D8
  DEFB $24,$48
  DEFB $0F,$E0
  DEFB $14,$50
  DEFB $16,$D0
  DEFB $10,$10
  DEFB $1A,$B0
  DEFB $0F,$E0

; Devil, drawn for sprite $78
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_78:
  DEFB $18
  DEFB $0C,$07
  DEFB $0C,$63
  DEFB $00,$65
  DEFB $0C,$04
  DEFB $0C,$EC
  DEFB $0E,$F8
  DEFB $0F,$D0
  DEFB $0F,$C0
  DEFB $05,$40
  DEFB $0B,$A0
  DEFB $0D,$60
  DEFB $AB,$A8
  DEFB $FF,$FF
  DEFB $3F,$FC
  DEFB $07,$C0
  DEFB $0A,$A0
  DEFB $11,$10
  DEFB $14,$50
  DEFB $16,$D0
  DEFB $31,$18
  DEFB $7B,$BC
  DEFB $6F,$EC
  DEFB $47,$C4
  DEFB $40,$04

; Devil, drawn for sprite $79, $7B
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_79:
  DEFB $18
  DEFB $06,$C7
  DEFB $06,$C3
  DEFB $00,$05
  DEFB $06,$C4
  DEFB $06,$CC
  DEFB $06,$D8
  DEFB $07,$D0
  DEFB $07,$C0
  DEFB $05,$40
  DEFB $0B,$A0
  DEFB $0D,$60
  DEFB $AB,$AA
  DEFB $FF,$FE
  DEFB $3F,$F8
  DEFB $07,$C0
  DEFB $0A,$A0
  DEFB $11,$10
  DEFB $14,$50
  DEFB $16,$D0
  DEFB $31,$18
  DEFB $7B,$BC
  DEFB $6F,$EC
  DEFB $47,$C4
  DEFB $40,$04

; Devil, drawn for sprite $7A
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_7A:
  DEFB $18
  DEFB $00,$37
  DEFB $06,$33
  DEFB $06,$05
  DEFB $00,$34
  DEFB $07,$3C
  DEFB $07,$78
  DEFB $03,$F0
  DEFB $07,$F0
  DEFB $02,$A0
  DEFB $05,$D0
  DEFB $06,$B0
  DEFB $A5,$D5
  DEFB $FF,$FF
  DEFB $3F,$FC
  DEFB $03,$E0
  DEFB $05,$50
  DEFB $08,$88
  DEFB $0A,$28
  DEFB $0B,$68
  DEFB $18,$8C
  DEFB $39,$CE
  DEFB $37,$F6
  DEFB $23,$E2
  DEFB $20,$02

; Dracula, drawn for sprite $7C
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_7C:
  DEFB $18
  DEFB $00,$F0
  DEFB $0C,$00
  DEFB $1C,$C0
  DEFB $38,$C0
  DEFB $B4,$C2
  DEFB $CE,$DE
  DEFB $F7,$DE
  DEFB $F7,$DE
  DEFB $F8,$3E
  DEFB $7F,$FC
  DEFB $7F,$FC
  DEFB $6B,$AC
  DEFB $23,$88
  DEFB $3F,$F8
  DEFB $0F,$E0
  DEFB $3A,$B8
  DEFB $72,$9C
  DEFB $41,$04
  DEFB $54,$54
  DEFB $16,$D0
  DEFB $19,$30
  DEFB $1B,$B0
  DEFB $0F,$E0
  DEFB $07,$C0

; Dracula, drawn for sprite $7D, $7F
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_7D:
  DEFB $18
  DEFB $1E,$F0
  DEFB $0E,$E0
  DEFB $00,$00
  DEFB $06,$C0
  DEFB $86,$C2
  DEFB $F6,$DE
  DEFB $F7,$DE
  DEFB $F7,$DE
  DEFB $F8,$3E
  DEFB $7F,$FC
  DEFB $7F,$FC
  DEFB $6B,$AC
  DEFB $23,$88
  DEFB $3F,$F8
  DEFB $0F,$E0
  DEFB $3A,$B8
  DEFB $72,$9C
  DEFB $41,$04
  DEFB $54,$54
  DEFB $16,$D0
  DEFB $19,$30
  DEFB $1B,$B0
  DEFB $0F,$E0
  DEFB $07,$C0

; Dracula, drawn for sprite $7E
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_7E:
  DEFB $18
  DEFB $1E,$00
  DEFB $00,$60
  DEFB $06,$70
  DEFB $06,$38
  DEFB $86,$5A
  DEFB $F6,$E6
  DEFB $F7,$DE
  DEFB $F7,$DE
  DEFB $F8,$3E
  DEFB $7F,$FC
  DEFB $7F,$EC
  DEFB $6B,$AC
  DEFB $23,$88
  DEFB $3F,$F8
  DEFB $0F,$E0
  DEFB $3A,$B8
  DEFB $72,$9C
  DEFB $41,$04
  DEFB $54,$54
  DEFB $16,$D0
  DEFB $19,$30
  DEFB $1B,$B0
  DEFB $0F,$E0
  DEFB $07,$C0

; Gravestone, left where the player died, drawn for sprite $8F
;
; 21 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8F:
  DEFB $15
  DEFB $22,$00
  DEFB $4B,$C0
  DEFB $56,$80
  DEFB $37,$60
  DEFB $FB,$00
  DEFB $7B,$80
  DEFB $FD,$80
  DEFB $7D,$CE
  DEFB $9E,$AE
  DEFB $9E,$77
  DEFB $2F,$F9
  DEFB $4F,$F6
  DEFB $07,$EC
  DEFB $07,$C0
  DEFB $0F,$D8
  DEFB $1F,$DC
  DEFB $3D,$EC
  DEFB $3D,$E2
  DEFB $3A,$DC
  DEFB $16,$B8
  DEFB $00,$70

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $8A
;
; 18 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8A:
  DEFB $12
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $66,$66
  DEFB $FD,$BF
  DEFB $FD,$BF
  DEFB $66,$66
  DEFB $03,$C0
  DEFB $01,$80
  DEFB $03,$C0
  DEFB $03,$C0
  DEFB $01,$80

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $89
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_89:
  DEFB $0F
  DEFB $02,$D0
  DEFB $03,$50
  DEFB $04,$A8
  DEFB $0C,$08
  DEFB $1C,$C8
  DEFB $38,$44
  DEFB $30,$84
  DEFB $76,$32
  DEFB $7B,$5A
  DEFB $73,$1A
  DEFB $79,$12
  DEFB $38,$02
  DEFB $3F,$02
  DEFB $1F,$FC
  DEFB $07,$F0

; Witch, drawn for sprite $90
;
; 22 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_90:
  DEFB $16
  DEFB $00,$0A
  DEFB $07,$DA
  DEFB $00,$BA
  DEFB $3C,$D8
  DEFB $07,$FC
  DEFB $07,$FE
  DEFB $07,$FE
  DEFB $05,$FF
  DEFB $1D,$FF
  DEFB $3E,$F7
  DEFB $E6,$F6
  DEFB $C3,$78
  DEFB $09,$60
  DEFB $0F,$C0
  DEFB $0F,$C0
  DEFB $2F,$20
  DEFB $3B,$40
  DEFB $16,$E0
  DEFB $0D,$F0
  DEFB $03,$F8
  DEFB $07,$FC
  DEFB $08,$1F

; Witch, drawn for sprite $91
;
; 22 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_91:
  DEFB $16
  DEFB $00,$80
  DEFB $07,$D5
  DEFB $00,$BA
  DEFB $3C,$D4
  DEFB $07,$FC
  DEFB $07,$FE
  DEFB $07,$FE
  DEFB $05,$FF
  DEFB $0D,$FF
  DEFB $1E,$F7
  DEFB $76,$F6
  DEFB $E3,$7C
  DEFB $49,$60
  DEFB $0F,$C0
  DEFB $0F,$00
  DEFB $2F,$20
  DEFB $3B,$40
  DEFB $16,$E0
  DEFB $0D,$F0
  DEFB $03,$F8
  DEFB $07,$FC
  DEFB $08,$1F

; Witch, drawn for sprite $92
;
; 22 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_92:
  DEFB $16
  DEFB $10,$00
  DEFB $AB,$E0
  DEFB $5D,$00
  DEFB $2B,$3C
  DEFB $3F,$E0
  DEFB $7F,$E0
  DEFB $7F,$E0
  DEFB $FF,$A0
  DEFB $FF,$B0
  DEFB $EF,$78
  DEFB $6F,$6E
  DEFB $3E,$C7
  DEFB $06,$92
  DEFB $03,$F0
  DEFB $00,$F0
  DEFB $04,$F4
  DEFB $02,$DC
  DEFB $07,$68
  DEFB $0F,$B0
  DEFB $1F,$C0
  DEFB $3F,$E0
  DEFB $F8,$10

; Witch, drawn for sprite $93
;
; 22 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_93:
  DEFB $16
  DEFB $50,$00
  DEFB $AB,$E0
  DEFB $5D,$00
  DEFB $2B,$3C
  DEFB $3F,$E0
  DEFB $7F,$E0
  DEFB $7F,$E0
  DEFB $FF,$A0
  DEFB $FF,$B8
  DEFB $EF,$7C
  DEFB $6F,$67
  DEFB $3E,$C3
  DEFB $06,$90
  DEFB $03,$F0
  DEFB $00,$F0
  DEFB $04,$F4
  DEFB $02,$DC
  DEFB $07,$68
  DEFB $0F,$B0
  DEFB $1F,$C0
  DEFB $3F,$E0
  DEFB $F8,$10

; The graphics for sprite $94
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_94:
  DEFB $13
  DEFB $0C,$CE
  DEFB $1F,$FC
  DEFB $3F,$F8
  DEFB $2F,$B0
  DEFB $17,$B0
  DEFB $3B,$10
  DEFB $3D,$B0
  DEFB $7E,$F0
  DEFB $FF,$70
  DEFB $E3,$70
  DEFB $1D,$70
  DEFB $0A,$E0
  DEFB $15,$C6
  DEFB $24,$3C
  DEFB $47,$FC
  DEFB $4F,$F8
  DEFB $7F,$E0
  DEFB $3F,$80
  DEFB $1E,$00

; The graphics for sprite $95
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_95:
  DEFB $13
  DEFB $03,$00
  DEFB $1F,$FF
  DEFB $0F,$FC
  DEFB $37,$B0
  DEFB $3B,$B0
  DEFB $7D,$10
  DEFB $7E,$D0
  DEFB $FF,$70
  DEFB $E7,$B0
  DEFB $0B,$B0
  DEFB $0D,$70
  DEFB $0C,$E0
  DEFB $17,$C0
  DEFB $26,$1F
  DEFB $47,$FC
  DEFB $4F,$F8
  DEFB $7F,$E0
  DEFB $3F,$80
  DEFB $1E,$00

; The graphics for sprite $96
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_96:
  DEFB $13
  DEFB $00,$C0
  DEFB $FF,$F8
  DEFB $3F,$F0
  DEFB $0D,$EC
  DEFB $0D,$DC
  DEFB $08,$BE
  DEFB $0D,$7E
  DEFB $0E,$FF
  DEFB $0D,$E7
  DEFB $0D,$D0
  DEFB $0E,$B0
  DEFB $07,$30
  DEFB $03,$E8
  DEFB $F8,$64
  DEFB $3F,$E2
  DEFB $1F,$F2
  DEFB $07,$F3
  DEFB $01,$FC
  DEFB $00,$78

; The graphics for sprite $97
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_97:
  DEFB $13
  DEFB $73,$30
  DEFB $3F,$F8
  DEFB $1F,$FC
  DEFB $0D,$F4
  DEFB $0D,$E8
  DEFB $08,$DC
  DEFB $0D,$BC
  DEFB $0F,$7E
  DEFB $0E,$FF
  DEFB $0E,$C7
  DEFB $0E,$B8
  DEFB $07,$50
  DEFB $63,$A8
  DEFB $3C,$24
  DEFB $3F,$E2
  DEFB $1F,$F2
  DEFB $07,$FE
  DEFB $01,$FC
  DEFB $00,$78

; Bat, a third kind, drawn for sprite $98
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_98:
  DEFB $13
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $67,$F0
  DEFB $FF,$FF
  DEFB $BF,$FE
  DEFB $DF,$80
  DEFB $F7,$F0
  DEFB $DC,$10
  DEFB $25,$F8
  DEFB $0B,$E8
  DEFB $0C,$18
  DEFB $07,$F8
  DEFB $03,$F8
  DEFB $00,$FC
  DEFB $00,$1F

; Bat, a third kind, drawn for sprite $99
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_99:
  DEFB $0D
  DEFB $00,$1F
  DEFB $00,$FC
  DEFB $03,$F8
  DEFB $07,$04
  DEFB $08,$38
  DEFB $07,$90
  DEFB $67,$E0
  DEFB $FF,$9F
  DEFB $BF,$FE
  DEFB $DF,$F0
  DEFB $F0,$00
  DEFB $B0,$00
  DEFB $20,$00

; Bat, a third kind, drawn for sprite $9A
;
; 13 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_9A:
  DEFB $0D
  DEFB $F8,$00
  DEFB $3F,$00
  DEFB $1F,$C0
  DEFB $2F,$E0
  DEFB $1C,$10
  DEFB $09,$E0
  DEFB $07,$E6
  DEFB $F9,$FF
  DEFB $7F,$FD
  DEFB $0F,$FB
  DEFB $00,$0F
  DEFB $00,$0D
  DEFB $00,$04

; Bat, a third kind, drawn for sprite $9B
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_9B:
  DEFB $13
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $0F,$E6
  DEFB $FF,$FF
  DEFB $7F,$FD
  DEFB $01,$FB
  DEFB $0F,$EF
  DEFB $08,$6D
  DEFB $1F,$A4
  DEFB $27,$D0
  DEFB $18,$30
  DEFB $1F,$E0
  DEFB $1F,$C0
  DEFB $3F,$00
  DEFB $F8,$00

; Barrel, drawn for sprite $BB
;
; 32 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_BB:
  DEFB $04,$20
  DEFB $00,$0F,$F0,$00
  DEFB $00,$70,$0E,$00
  DEFB $01,$87,$B1,$80
  DEFB $02,$7B,$DE,$40
  DEFB $04,$FD,$EF,$A0
  DEFB $0B,$7E,$F7,$D0
  DEFB $17,$BF,$7B,$E8
  DEFB $17,$DF,$BD,$E8
  DEFB $2F,$FF,$FF,$F4
  DEFB $6E,$63,$8F,$B6
  DEFB $5E,$49,$27,$BA
  DEFB $56,$49,$24,$2A
  DEFB $5E,$63,$8C,$BA
  DEFB $DC,$49,$24,$FB
  DEFB $EE,$49,$24,$F7
  DEFB $AF,$63,$8C,$B5
  DEFB $B7,$FF,$FF,$ED
  DEFB $BB,$DF,$F7,$DD
  DEFB $9D,$EF,$FB,$B9
  DEFB $CE,$77,$FE,$73
  DEFB $C7,$8F,$F1,$E3
  DEFB $63,$F0,$0F,$C6
  DEFB $70,$FF,$FF,$0E
  DEFB $38,$1F,$F8,$1C
  DEFB $1E,$00,$40,$78
  DEFB $0F,$C0,$23,$F0
  DEFB $03,$FF,$FF,$C0
  DEFB $00,$FF,$FF,$00
  DEFB $00,$1F,$F8,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00

; Colours for a graphic, entry $E2 of the attribute table
;
; One attribute per character cell, 4 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_E2:
  DEFB $04,$04
  DEFB $46,$46,$46,$46
  DEFB $46,$46,$46,$46
  DEFB $46,$46,$46,$46
  DEFB $46,$46,$46,$46

; A.C.G. door, drawn for sprite $C5
;
; 40 rows of 64 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C5:
  DEFB $08,$28
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$3C,$00,$00,$00,$00,$3C,$00
  DEFB $00,$42,$00,$00,$00,$00,$42,$00
  DEFB $00,$BD,$00,$00,$00,$00,$BD,$00
  DEFB $00,$EF,$00,$00,$00,$00,$F7,$00
  DEFB $FF,$EB,$FF,$FF,$7F,$FF,$F7,$FF
  DEFB $00,$6A,$1F,$FF,$7F,$F8,$56,$00
  DEFB $00,$5A,$3F,$FF,$7F,$FC,$52,$00
  DEFB $00,$D6,$3F,$E3,$63,$FC,$6B,$00
  DEFB $00,$D6,$7F,$D1,$51,$FE,$6B,$00
  DEFB $00,$B6,$7F,$D1,$51,$FE,$69,$00
  DEFB $00,$B6,$FF,$CD,$4D,$FF,$6D,$00
  DEFB $01,$B6,$FF,$E3,$63,$FF,$6D,$80
  DEFB $01,$A4,$FF,$FF,$FF,$FF,$25,$80
  DEFB $01,$2C,$FF,$36,$30,$FF,$34,$80
  DEFB $01,$6C,$FF,$34,$E6,$FF,$36,$80
  DEFB $03,$6C,$FF,$04,$E4,$FF,$36,$C0
  DEFB $03,$6C,$FF,$04,$E4,$FF,$36,$C0
  DEFB $02,$6C,$FF,$34,$E7,$FF,$36,$40
  DEFB $02,$6C,$FF,$34,$E7,$FF,$36,$40
  DEFB $06,$CC,$7F,$8E,$30,$FE,$33,$60
  DEFB $04,$CC,$7F,$FF,$FF,$FE,$33,$20
  DEFB $07,$F4,$3F,$FF,$7F,$FC,$2F,$E0
  DEFB $1F,$FC,$1F,$FF,$7F,$F8,$3F,$F8
  DEFB $38,$0E,$0F,$FF,$7F,$F0,$70,$1C
  DEFB $67,$F3,$03,$FF,$7F,$C0,$CF,$E6
  DEFB $5F,$FD,$00,$7F,$FE,$00,$BF,$FA
  DEFB $3F,$FE,$00,$07,$60,$00,$7F,$FC
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
  DEFB $55,$55,$55,$55,$55,$55,$55,$56
  DEFB $2A,$AA,$AA,$AA,$AA,$AA,$AA,$AC
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Colours for a graphic, entry $EC of the attribute table
;
; One attribute per character cell, 8 across by 5 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_EC:
  DEFB $08,$05
  DEFB $FF,$47,$43,$43,$43,$43,$47,$FF
  DEFB $FF,$47,$43,$43,$43,$43,$47,$FF
  DEFB $47,$47,$43,$43,$43,$43,$47,$47
  DEFB $47,$47,$43,$43,$43,$43,$47,$47
  DEFB $46,$46,$46,$46,$46,$46,$46,$46

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $8C
;
; 11 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8C:
  DEFB $0B
  DEFB $0C,$CE
  DEFB $0C,$DF
  DEFB $0F,$D8
  DEFB $0F,$D8
  DEFB $0C,$D8
  DEFB $0C,$DF
  DEFB $07,$FE
  DEFB $3F,$FF
  DEFB $5F,$FF
  DEFB $40,$00
  DEFB $3F,$FF

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $8D
;
; 15 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8D:
  DEFB $0F
  DEFB $3C,$00
  DEFB $7E,$00
  DEFB $66,$00
  DEFB $6E,$01
  DEFB $60,$01
  DEFB $7E,$03
  DEFB $3C,$0F
  DEFB $FF,$F0
  DEFB $FF,$FF
  DEFB $00,$0F
  DEFB $FF,$F0
  DEFB $00,$0F
  DEFB $00,$03
  DEFB $00,$01
  DEFB $00,$01

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $8E
;
; 19 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8E:
  DEFB $13
  DEFB $1C,$00
  DEFB $7F,$00
  DEFB $7F,$00
  DEFB $C3,$80
  DEFB $C3,$C0
  DEFB $81,$DC
  DEFB $81,$66
  DEFB $1B,$42
  DEFB $9F,$73
  DEFB $C7,$B1
  DEFB $C7,$B1
  DEFB $9F,$73
  DEFB $1B,$42
  DEFB $81,$66
  DEFB $81,$BC
  DEFB $C3,$80
  DEFB $F8,$80
  DEFB $7F,$00
  DEFB $1C,$00

; Mushroom, which drains the player's life force, drawn for sprite $A1
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_A1:
  DEFB $10
  DEFB $00,$70
  DEFB $00,$FC
  DEFB $00,$7E
  DEFB $00,$7E
  DEFB $00,$FC
  DEFB $00,$FC
  DEFB $7E,$3C
  DEFB $CF,$C8
  DEFB $6F,$F0
  DEFB $FF,$3C
  DEFB $7F,$3E
  DEFB $77,$F3
  DEFB $33,$F3
  DEFB $1F,$9E
  DEFB $0F,$FC
  DEFB $03,$F0

; Pumpkin picture, drawn for sprite $C6
;
; 16 rows of 32 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C6:
  DEFB $04,$10
  DEFB $01,$FF,$FF,$80
  DEFB $01,$FF,$FF,$80
  DEFB $01,$80,$01,$80
  DEFB $01,$87,$E1,$80
  DEFB $03,$8D,$31,$C0
  DEFB $03,$18,$98,$C0
  DEFB $03,$13,$C8,$C0
  DEFB $03,$16,$68,$C0
  DEFB $07,$1F,$F8,$E0
  DEFB $06,$19,$98,$60
  DEFB $06,$19,$98,$60
  DEFB $06,$0F,$F0,$60
  DEFB $0E,$00,$00,$70
  DEFB $0C,$00,$00,$30
  DEFB $0F,$FF,$FF,$F0
  DEFB $0F,$FF,$FF,$F0

; Colours for a graphic, entry $ED of the attribute table
;
; One attribute per character cell, 4 across by 2 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_ED:
  DEFB $04,$02
  DEFB $46,$46,$46,$46
  DEFB $46,$46,$46,$46

; Collectables: keys, and the objects that kill the mummy, Dracula, the devil
; and Frankenstein's monster, drawn for sprite $8B
;
; 16 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_8B:
  DEFB $10
  DEFB $20,$00
  DEFB $70,$00
  DEFB $78,$00
  DEFB $3C,$00
  DEFB $1E,$00
  DEFB $0F,$00
  DEFB $07,$80
  DEFB $03,$C0
  DEFB $01,$E0
  DEFB $00,$F8
  DEFB $00,$7E
  DEFB $00,$7F
  DEFB $00,$7F
  DEFB $00,$63
  DEFB $00,$63
  DEFB $00,$22

; Bat, drawn for sprite $4E
;
; 11 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4E:
  DEFB $0B
  DEFB $09,$10
  DEFB $DD,$B9
  DEFB $FF,$FF
  DEFB $7F,$FF
  DEFB $3F,$FE
  DEFB $1C,$9C
  DEFB $0A,$2C
  DEFB $0B,$6C
  DEFB $0C,$98
  DEFB $07,$F0
  DEFB $01,$E0

; Bat, drawn for sprite $4F
;
; 11 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_4F:
  DEFB $0B
  DEFB $00,$00
  DEFB $00,$00
  DEFB $01,$01
  DEFB $D7,$D7
  DEFB $FF,$FF
  DEFB $F9,$3E
  DEFB $74,$5C
  DEFB $36,$D8
  DEFB $19,$30
  DEFB $0F,$E0
  DEFB $03,$C0

; Skeleton, drawn for sprite $C7
;
; 40 rows of 40 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C7:
  DEFB $05,$28
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
  DEFB $00,$00,$60,$00,$00
  DEFB $00,$E0,$78,$00,$00
  DEFB $00,$FC,$EC,$40,$00
  DEFB $00,$6E,$C6,$70,$00
  DEFB $00,$C1,$C3,$60,$00
  DEFB $00,$C6,$A1,$C0,$00
  DEFB $00,$BF,$30,$80,$00
  DEFB $00,$7C,$1C,$00,$00
  DEFB $00,$6B,$9F,$00,$00
  DEFB $FF,$50,$4E,$FF,$00
  DEFB $00,$24,$E1,$00,$00
  DEFB $00,$28,$10,$00,$00
  DEFB $00,$12,$60,$00,$00
  DEFB $00,$14,$30,$00,$00
  DEFB $00,$14,$18,$00,$00
  DEFB $00,$14,$46,$00,$00
  DEFB $00,$0C,$99,$00,$00
  DEFB $00,$02,$AE,$E0,$00
  DEFB $00,$06,$7B,$60,$00
  DEFB $50,$0C,$E7,$30,$00
  DEFB $27,$18,$87,$18,$50
  DEFB $17,$78,$FF,$0B,$98
  DEFB $07,$00,$7E,$03,$B0
  DEFB $05,$00,$3C,$03,$80
  DEFB $05,$00,$00,$00,$E0
  DEFB $0B,$00,$00,$00,$40
  DEFB $14,$00,$00,$00,$F0
  DEFB $14,$00,$00,$00,$28
  DEFB $68,$00,$00,$00,$2E
  DEFB $F0,$00,$00,$00,$1F
  DEFB $B8,$00,$00,$00,$1B
  DEFB $F8,$00,$00,$00,$1F
  DEFB $70,$00,$00,$00,$0E

; Colours for a graphic, entry $EE of the attribute table
;
; One attribute per character cell, 5 across by 5 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_EE:
  DEFB $05,$05
  DEFB $FF,$FF,$FF,$FF,$FF
  DEFB $FF,$47,$47,$47,$FF
  DEFB $FF,$47,$47,$FF,$FF
  DEFB $47,$47,$47,$47,$47
  DEFB $47,$FF,$FF,$FF,$47

; Humpback, drawn for sprite $9C
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_9C:
  DEFB $18
  DEFB $00,$3C
  DEFB $3C,$38
  DEFB $1C,$00
  DEFB $00,$38
  DEFB $0E,$38
  DEFB $0E,$38
  DEFB $0F,$38
  DEFB $67,$F8
  DEFB $03,$F8
  DEFB $60,$00
  DEFB $77,$F8
  DEFB $37,$38
  DEFB $37,$78
  DEFB $43,$9C
  DEFB $1D,$8C
  DEFB $06,$C2
  DEFB $7B,$62
  DEFB $7F,$72
  DEFB $53,$62
  DEFB $73,$44
  DEFB $3E,$CC
  DEFB $1E,$F8
  DEFB $05,$F0
  DEFB $03,$E0

; Humpback, drawn for sprite $9D, $9F
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
;
; Shared by 2 codes, which is how the game gets a mirrored or repeated frame
; without a second copy of the picture.
GFX_9D:
  DEFB $18
  DEFB $0F,$3C
  DEFB $07,$38
  DEFB $00,$00
  DEFB $07,$38
  DEFB $07,$38
  DEFB $07,$38
  DEFB $07,$38
  DEFB $37,$F8
  DEFB $07,$F8
  DEFB $30,$00
  DEFB $27,$F8
  DEFB $26,$78
  DEFB $26,$F8
  DEFB $03,$9C
  DEFB $1D,$8C
  DEFB $06,$CC
  DEFB $7B,$66
  DEFB $7F,$66
  DEFB $53,$66
  DEFB $73,$4C
  DEFB $3E,$CC
  DEFB $1E,$F8
  DEFB $05,$F0
  DEFB $03,$E0

; Humpback, drawn for sprite $9E
;
; 24 rows of 16 pixels. The first byte is the row count; the rest are the rows,
; two bytes each, top down.
GFX_9E:
  DEFB $18
  DEFB $0F,$00
  DEFB $07,$3C
  DEFB $00,$38
  DEFB $07,$00
  DEFB $07,$38
  DEFB $07,$3C
  DEFB $07,$3C
  DEFB $67,$F8
  DEFB $07,$F8
  DEFB $60,$00
  DEFB $77,$F8
  DEFB $37,$38
  DEFB $37,$38
  DEFB $43,$9C
  DEFB $1D,$8C
  DEFB $06,$C2
  DEFB $7B,$62
  DEFB $7F,$72
  DEFB $53,$62
  DEFB $73,$44
  DEFB $3E,$CC
  DEFB $1E,$F8
  DEFB $05,$F0
  DEFB $03,$E0

; Barrel stack, drawn for sprite $C8
;
; 27 rows of 40 pixels. The first two bytes are the width in bytes and the
; height in rows; the rest are the rows, top down.
GFX_C8:
  DEFB $05,$1B
  DEFB $03,$C0,$3C,$03,$C0
  DEFB $0F,$F0,$FF,$0F,$F0
  DEFB $1F,$F9,$FF,$9F,$F8
  DEFB $1F,$F9,$FF,$9F,$F8
  DEFB $2F,$F6,$FF,$6F,$F4
  DEFB $43,$C0,$3C,$03,$C4
  DEFB $30,$0F,$00,$F0,$0C
  DEFB $2C,$3F,$C3,$FC,$34
  DEFB $23,$7F,$E7,$FE,$C4
  DEFB $30,$7F,$E7,$FE,$0C
  DEFB $2C,$BF,$DB,$FC,$34
  DEFB $13,$8F,$00,$F1,$C8
  DEFB $10,$C0,$3C,$03,$08
  DEFB $0C,$B0,$FF,$0D,$30
  DEFB $03,$8D,$FF,$B1,$C0
  DEFB $00,$C1,$FF,$83,$00
  DEFB $00,$D2,$FF,$4B,$00
  DEFB $00,$4E,$3C,$72,$00
  DEFB $00,$43,$00,$C2,$00
  DEFB $00,$32,$C3,$4C,$00
  DEFB $00,$0E,$3C,$70,$00
  DEFB $00,$03,$00,$C0,$00
  DEFB $00,$02,$C3,$40,$00
  DEFB $00,$01,$3C,$80,$00
  DEFB $00,$01,$00,$80,$00
  DEFB $00,$00,$C3,$00,$00
  DEFB $00,$00,$3C,$00,$00

; Colours for a graphic, entry $EF of the attribute table
;
; One attribute per character cell, 5 across by 4 down, behind the graphic this
; entry pairs with. The first two bytes are the width and the height.
ATTRS_EF:
  DEFB $05,$04
  DEFB $43,$43,$43,$43,$43
  DEFB $43,$43,$43,$43,$43
  DEFB $43,$43,$43,$43,$43
  DEFB $43,$43,$43,$43,$43

; The tail of the game image
;
; 251 bytes, of which three are not zero: a $01 seven bytes in, and $3A $85 at
; the very end. Nothing points here and nothing reads it -- it is the space
; between the last of the graphics and the end of what the tape loads.
TAIL_PADDING:
  DEFB $00,$00,$00,$00,$00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$85,$3A

