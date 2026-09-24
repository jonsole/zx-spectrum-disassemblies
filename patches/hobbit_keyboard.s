; The Hobbit, with the keyboard read under interrupt.
;
; The original reads the keyboard only when it is waiting for a key: nothing
; typed while a picture draws or the story scrolls is ever seen. This reads it
; fifty times a second from an interrupt, and keeps each new key in a buffer
; until the game asks for one, so a command can be typed ahead.
;
; INCLUDEd by hobbit_fast_draw.s, after the drawing changes and before the
; SAVEBIN. What changes:
;
; - An IM 2 interrupt, set up once the title screen's key is pressed. It runs
;   the second half of SCAN_KEYBOARD -- the game's own scan, with its own
;   masks, its own new-key test against KEYS_LAST_SEEN and its own key maps --
;   and puts what it finds into a 16-byte ring.
; - SCAN_KEYBOARD itself keeps its 7.4ms debounce delay, since GET_KEY's
;   PATIENCE is a count of scans and "time passes" must come as soon as it
;   did, then takes the next key from the ring instead of scanning.
; - The wait after a picture (WAIT_FOR_ANY_KEY) returns at once if something
;   has been typed ahead, and leaves it to be read. Otherwise it waits for a key
;   and throws it away, as before: that key means "carry on", not a letter.
; - NEW_KEYPRESS, the wait in PAUSE and SAVE, empties the ring and waits for a
;   new key, which it throws away.
; - The two DIs after the tape routines become EIs, so reading goes on after a
;   SAVE or a LOAD.
;
; The game never enables interrupts and borrows IY freely, so the ROM's IM 1
; routine, which needs IY at the system variables, could not be used. IM 2
; with I = $39 takes its vector from the ROM at $39FF-$3A00, which is $FFFF
; like everything from $386E to $3CFF: the jump is to $FFFF, where a JR takes
; its offset from the ROM's first byte, $F3, and so lands on $FFF4. Both are
; in the ROM's user-defined-graphics area, which the game never uses, above
; the end of WORLD_COPY at $FFED; they are written when the interrupt is set
; up, since the patched image stops at $FC3F.

KEY_VECTOR_PAGE EQU $39             ; I: the ROM's $FF bytes supply the vector
KEY_JUMP        EQU $FFF4           ; Where the JR at $FFFF lands
KEY_RING_SIZE   EQU 16
SCAN_BODY       EQU SCAN_KEYBOARD+7 ; SCAN_KEYBOARD after its pushes and delay

    ASSERT {b SCAN_BODY} == $ED && {b SCAN_BODY+1} == $43, "SCAN_BODY is not LD (NEW_KEY),BC"
    ASSERT {b TITLE_WAIT+18} == $21, "the title's LD HL,$50E0 has moved"
    ASSERT {b $8488} == $F3 && {b TAPE_DONE} == $F3, "the DIs after the tape routines have moved"

; --------------------------------------------------------------------------
; The ring: head, tail, then the keys, all in one page. Where UNREACHED_
; WALK_HELD was -- 26 bytes that read as a routine nothing calls.
; --------------------------------------------------------------------------

    ORG UNREACHED_WALK_HELD
KEY_HEAD:
    DB 0                            ; The next key to be taken
KEY_TAIL:
    DB 0                            ; Where the next key found goes
KEY_RING:
    DS KEY_RING_SIZE,0
    ASSERT high(KEY_HEAD) == high(KEY_RING + KEY_RING_SIZE - 1), "the ring crosses a page"
    ASSERT $ <= UNREACHED_WALK_HELD + 26, "the ring has run past UNREACHED_WALK_HELD"

; --------------------------------------------------------------------------
; The game's own routines, rewritten in place.
; --------------------------------------------------------------------------

; The title screen's key: the interrupt starts here, in place of the
; LD HL,$50E0 that KEYS_ON does instead.
    ORG TITLE_WAIT+18
    CALL KEYS_ON

; After LOAD and after SAVE's verify: interrupts back on, not off.
    ORG $8488
    EI
    ORG TAPE_DONE
    EI

; Wait for all keys up and then one down, for PAUSE and SAVE: now, anything
; typed ahead is thrown away, then the next key is waited for and thrown away.
    ORG NEW_KEYPRESS
    CALL NEXT_KEY
    AND A
    JR NZ,NEW_KEYPRESS
NEW_KEYPRESS_WAIT:
    CALL NEXT_KEY
    AND A
    JR Z,NEW_KEYPRESS_WAIT
    RET
    ASSERT $ <= NEW_KEYPRESS + 19, "NEW_KEYPRESS has outgrown itself"

; The next key, after the scan's delay: the delay kept because PATIENCE counts
; calls here, then the key from the ring rather than from the keyboard.
    ORG SCAN_KEYBOARD
    PUSH BC
    CALL DEBOUNCE_DELAY
    JP NEXT_KEY_1
    ASSERT $ == SCAN_BODY, "SCAN_KEYBOARD's replacement is not seven bytes"

; After a picture: carry on at once if something was typed while it drew,
; and leave it to be read; otherwise wait for a key, which means only "carry
; on". Then the white border, as before.
    ORG WAIT_FOR_ANY_KEY
    CALL AWAIT_KEY
    LD A,$07
    OUT ($FE),A
    RET
    ASSERT $ <= WAIT_FOR_ANY_KEY + 14, "WAIT_FOR_ANY_KEY has outgrown itself"

; --------------------------------------------------------------------------
; The interrupt, and the game's scan as it calls it. In the fill's region,
; after the fill's helpers.
; --------------------------------------------------------------------------

    ORG FILL_REGION_END
; Fifty times a second: scan, and keep any new key. A full ring loses the key.
; The foreground cannot run in the middle of this, so the order of the two
; writes does not matter here; it does in NEXT_KEY.
KEY_INTERRUPT:
    PUSH AF
    CALL KEY_SCAN
    AND A
    JR Z,KEY_INTERRUPT_DONE
    PUSH HL
    PUSH BC
    LD B,A                   ; The key
    LD HL,KEY_TAIL
    LD A,(HL)
    LD C,A                   ; Its slot
    INC A
    AND KEY_RING_SIZE-1
    DEC HL                   ; KEY_HEAD: full if the tail would reach it
    CP (HL)
    JR Z,KEY_INTERRUPT_FULL
    INC HL
    LD (HL),A                ; The tail on one
    LD A,C
    ADD A,low(KEY_RING)
    LD L,A
    LD (HL),B                ; The key in its slot
KEY_INTERRUPT_FULL:
    POP BC
    POP HL
KEY_INTERRUPT_DONE:
    POP AF
    EI
    RETI

; SCAN_KEYBOARD without its delay: its own pushes, the zero in BC the delay
; would have left, and on into the scan. A = the new key, or 0.
KEY_SCAN:
    PUSH HL
    PUSH IX
    PUSH BC
    LD BC,$0000
    JP SCAN_BODY

    ASSERT $ <= ATTR_UP, "the keyboard has run into ATTR_UP"
    DISPLAY "keyboard in the fill region ends at ",/H,$," (limit ",/H,ATTR_UP,")"

; --------------------------------------------------------------------------
; Taking a key, in the line drawer's region.
; --------------------------------------------------------------------------

    ORG LINE_REGION_END
; The next key from the ring, or 0; only AF changes. The key is read before
; the head moves on, since that gives its slot back to the interrupt.
NEXT_KEY:
    PUSH BC
NEXT_KEY_1:
    PUSH HL
    LD HL,KEY_HEAD
    LD A,(KEY_TAIL)
    CP (HL)
    LD B,$00                 ; Empty: 0
    JR Z,NEXT_KEY_DONE
    LD C,(HL)                ; The head
    LD A,C
    ADD A,low(KEY_RING)
    LD L,A
    LD B,(HL)                ; Its key
    LD L,low(KEY_HEAD)
    LD A,C
    INC A
    AND KEY_RING_SIZE-1
    LD (HL),A                ; The head on one
NEXT_KEY_DONE:
    LD A,B
    POP HL
    POP BC
    RET

    ASSERT $ <= CLEAR_CANVAS, "the keyboard has run into CLEAR_CANVAS"
    DISPLAY "keyboard in the line region ends at ",/H,$," (limit ",/H,CLEAR_CANVAS,")"

; --------------------------------------------------------------------------
; Waiting, in low memory after the drawing code's.
; --------------------------------------------------------------------------

    ORG SPARE_REGION_END
; Return at once if a key is waiting, leaving it there; otherwise wait for one
; and take it.
AWAIT_KEY:
    PUSH HL
    LD HL,KEY_HEAD
    LD A,(KEY_TAIL)
    CP (HL)
    POP HL
    RET NZ
AWAIT_KEY_WAIT:
    CALL NEXT_KEY
    AND A
    JR Z,AWAIT_KEY_WAIT
    RET

    ASSERT $ <= LOW_CODE + LOW_CODE_SIZE, "the keyboard has run past LOW_CODE_SIZE"
    DISPLAY "keyboard in low memory ends at ",/H,$," (limit ",/H,LOW_CODE+LOW_CODE_SIZE,")"

; --------------------------------------------------------------------------
; Setting it up, once the title screen's key is down: where UNREACHED_WIPE_
; EXIT was (20 bytes nothing calls), then after the fill's sweep loop.
; --------------------------------------------------------------------------

    ORG UNREACHED_WIPE_EXIT
KEYS_ON:
    LD HL,KEY_JUMP           ; JP KEY_INTERRUPT where the JR lands...
    LD (HL),$C3
    INC HL
    LD (HL),low(KEY_INTERRUPT)
    INC HL
    LD (HL),high(KEY_INTERRUPT)
    LD L,$FF                 ; ...and the JR at the vector, $FFFF
    LD (HL),$18
    JP KEYS_ON_1
    ASSERT $ <= UNREACHED_WIPE_EXIT + 20, "KEYS_ON has run past UNREACHED_WIPE_EXIT"

    ORG AFTER_PICTURES_END
KEYS_ON_1:
    LD A,KEY_VECTOR_PAGE
    LD I,A
    IM 2
    CALL KEY_SCAN            ; The keyboard as it is now, so the title's key,
    LD A,(KEY_TAIL)          ; still down, is not new; and an empty ring
    LD (KEY_HEAD),A
    EI
    LD HL,$50E0              ; What the CALL here replaced
    RET

    ASSERT $ <= WORLD_COPY, "the keyboard has run into WORLD_COPY"
    DISPLAY "keyboard after the pictures ends at ",/H,$," (limit ",/H,WORLD_COPY,")"
