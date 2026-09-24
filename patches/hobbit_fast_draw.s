; The Hobbit, with the pictures drawn faster.
;
; Assembled on top of the byte-exact disassembly: the original is included
; whole, with all its labels, and the plotting code is then written over in
; place. Nothing else changes. See docs/hobbit-fast-draw-plan.md for why this
; is safe and how it is checked.
;
; The new FLOOD_FILL and DRAW_LINE visit exactly the pixels the old ones do, in
; the same order, push exactly the same fill seeds, and keep every edge test on
; D and E as it was. Only how a pixel's screen byte is found changes: the old
; code rebuilt the address from (D,E) for every pixel it touched -- PIXEL_ADDRESS
; was half of all the time spent drawing -- where this carries the address and
; the bit mask along with the point and steps them with it.
;
; The block from FLOOD_FILL to the end of PIXEL_ADDRESS is called from nowhere
; but RUN_PICTURE, and only through FLOOD_FILL, DRAW_LINE and the four ATTR_
; routines, which stay where they are. So the new code goes into the two
; stretches either side of them: $8071-$80F4 and $812B-$820A.
;
; Build: sjasmplus hobbit_fast_draw.s (build_hobbit.py --fast-draw does it).

    INCLUDE "../game_disassembly/hobbit/hobbit.asm"

; --------------------------------------------------------------------------
; FLOOD_FILL, in place: the same scanline fill, with the address carried.
;
; Registers through the fill: D,E the point, as before; HL its screen byte and
; C its bit mask; B the two seeded flags the old code kept in SEEDED_ABOVE and
; SEEDED_BELOW (bit 0 above, bit 1 below), written back to them at the end so
; memory is left as the old code left it. The caller's BC is kept in FILL_BC
; rather than on the stack, so the seeds sit exactly where they always did.
; --------------------------------------------------------------------------

    ORG FLOOD_FILL
    LD (PLOT_INK),A          ; The ink, as before
    PUSH DE
    PUSH HL
    LD HL,$0080              ; The sentinel that ends the fill
    PUSH HL
    LD (FILL_BC),BC
    CALL FAST_SET_INK        ; This fill's ink, into PLOT's comparisons
FILL_SEED:
    CALL FAST_ADDRESS        ; A seed: its byte and mask, worked out once
    LD C,A
FILL_LEFT:
    LD A,(HL)                ; Walk left until a pixel is set...
    AND C
    JR NZ,FILL_HIT
    LD A,D                   ; ...or the left edge: DEC_X would refuse at x=0
    AND A
    JR Z,FILL_SWEEP
    DEC D
    RLC C                    ; One pixel left: the mask, and the byte when it wraps
    JR NC,FILL_LEFT
    DEC L
    JR FILL_LEFT
FILL_HIT:
    CALL FAST_PLOT           ; The set pixel is plotted, then one step right,
    CALL FILL_RIGHT          ; which INC_X refuses at x=255 -- and the old code
FILL_SWEEP:                  ; carried on regardless, as this does
    LD B,$00                 ; Neither row seeded yet
FILL_PIXEL:
    LD A,E                   ; Above: nothing past y=127
    CP $7F
    JR Z,FILL_NO_ABOVE
    PUSH HL
    CALL FAST_UP
    LD A,(HL)
    AND C
    POP HL
    JR NZ,FILL_NO_ABOVE      ; Set above: the run there has ended
    BIT 0,B                  ; Unset: a seed at the start of each run
    JR NZ,FILL_BELOW
    INC E
    PUSH DE
    DEC E
    SET 0,B
    JR FILL_BELOW
FILL_NO_ABOVE:
    RES 0,B
FILL_BELOW:
    LD A,E                   ; Below: nothing past y=0
    AND A
    JR Z,FILL_NO_BELOW
    PUSH HL
    CALL FAST_DOWN
    LD A,(HL)
    AND C
    POP HL
    JR NZ,FILL_NO_BELOW
    BIT 1,B
    JR NZ,FILL_PLOT
    DEC E
    PUSH DE
    INC E
    SET 1,B
    JR FILL_PLOT
FILL_NO_BELOW:
    RES 1,B
FILL_PLOT:
    CALL FAST_PLOT           ; This pixel
    CALL FILL_RIGHT          ; Right one, or the sweep ends at x=255
    JR Z,FILL_NEXT
    LD A,(HL)                ; Unset: on along the sweep. Set: plot it, and done
    AND C
    JR Z,FILL_PIXEL
    CALL FAST_PLOT
FILL_NEXT:
    POP DE                   ; The next seed, or the sentinel
    LD A,E
    CP $80
    JR NZ,FILL_SEED
    JP FILL_FINISH

    ASSERT $ <= ATTR_UP, "the fill has run into ATTR_UP"
    DISPLAY "fill region ends at ",/H,$," (limit ",/H,ATTR_UP,")"

; --------------------------------------------------------------------------
; After the ATTR_ routines, before DRAW_LINE: the mask table and the two steps.
; --------------------------------------------------------------------------

    ORG INC_Y                ; $812B, where INC_Y was
FAST_MASKS:
    DB $80,$40,$20,$10,$08,$04,$02,$01
    ASSERT high(FAST_MASKS) == high(FAST_MASKS + 7), "the mask table crosses a page"

; One scanline up the screen -- up the canvas, since y is measured upwards.
; The usual Spectrum previous-line step.
FAST_UP:
    LD A,H
    DEC H
    AND $07
    RET NZ
    LD A,L
    SUB $20
    LD L,A
    RET C
    LD A,H
    ADD A,$08
    LD H,A
    RET

; One scanline down.
FAST_DOWN:
    INC H
    LD A,H
    AND $07
    RET NZ
    LD A,L
    ADD A,$20
    LD L,A
    RET C
    LD A,H
    SUB $08
    LD H,A
    RET

    DISPLAY "steps end at ",/H,$," (limit ",/H,DRAW_LINE,")"
    ASSERT $ <= DRAW_LINE, "the steps have run into DRAW_LINE"

; --------------------------------------------------------------------------
; DRAW_LINE, in place: the same two Bresenham halves, with the address carried
; in HL' and the mask in C' so that D, E, B, C and L mean what they always did.
; --------------------------------------------------------------------------

    ORG DRAW_LINE
    PUSH HL                  ; As before: the length and the step counter are
    PUSH BC                  ; kept, and B is reloaded from here
    CALL FAST_SET_INK
    CALL FAST_ADDRESS        ; The first pixel's byte and mask, into HL' and C'
    PUSH HL
    EXX
    POP HL
    LD C,A
    EXX
    POP BC                   ; The length back in L
    POP HL
    PUSH HL
    PUSH BC
    BIT 0,C                  ; Which axis is the major one
    JR NZ,LINE_Y_MAJOR
LINE_X_LOOP:
    EXX
    CALL FAST_PLOT
    EXX
    BIT 2,C
    JR Z,LINE_X_RIGHT
    LD A,D                   ; Left, unless at x=0
    AND A
    JR Z,LINE_END
    DEC D
    EXX
    RLC C
    JR NC,LINE_X_LEFT_DONE
    DEC L
LINE_X_LEFT_DONE:
    EXX
    JR LINE_X_MINOR
LINE_X_RIGHT:
    LD A,D                   ; Right, unless at x=255
    INC A
    JR Z,LINE_END
    LD D,A
    EXX
    RRC C
    JR NC,LINE_X_RIGHT_DONE
    INC L
LINE_X_RIGHT_DONE:
    EXX
LINE_X_MINOR:
    DEC B                    ; Time for a step on y?
    JR NZ,LINE_X_COUNT
    CALL LINE_STEP_Y
    JR Z,LINE_END
    POP BC
    PUSH BC
LINE_X_COUNT:
    DEC L
    JR NZ,LINE_X_LOOP
LINE_END:
    POP BC
    POP HL
    RET
LINE_Y_MAJOR:
    EXX
    CALL FAST_PLOT
    EXX
    CALL LINE_STEP_Y
    JR Z,LINE_END
    DEC B                    ; Time for a step on x?
    JR NZ,LINE_Y_COUNT
    BIT 2,C
    JR Z,LINE_Y_RIGHT
    LD A,D
    AND A
    JR Z,LINE_END
    DEC D
    EXX
    RLC C
    JR NC,LINE_Y_LEFT_DONE
    DEC L
LINE_Y_LEFT_DONE:
    EXX
    JR LINE_Y_RELOAD
LINE_Y_RIGHT:
    LD A,D
    INC A
    JR Z,LINE_END
    LD D,A
    EXX
    RRC C
    JR NC,LINE_Y_RIGHT_DONE
    INC L
LINE_Y_RIGHT_DONE:
    EXX
LINE_Y_RELOAD:
    POP BC
    PUSH BC
LINE_Y_COUNT:
    DEC L
    JR NZ,LINE_Y_MAJOR
    JR LINE_END

; One pixel right, for the fill: D, and the mask in C and the byte in HL with
; it. Z, and nothing moved, at x=255, where INC_X refuses; NZ otherwise.
FILL_RIGHT:
    LD A,D
    INC A
    RET Z
    LD D,A
    RRC C
    RET NC                   ; The mask is never 0, so NZ
    INC L
    AND A                    ; A is the new x, not 0: NZ
    RET

; Plot the pixel at HL, mask C, and colour its cell: PLOT_PIXEL's rule, that
; the ink is flipped where it would match the paper, with the three values
; FAST_SET_INK wrote into the immediates below.
FAST_PLOT:
    LD A,(HL)
    OR C
    LD (HL),A
    PUSH HL
    LD A,H                   ; Screen address to attribute address
    RRCA
    RRCA
    RRCA
    AND $03
    OR $58
    LD H,A
    LD A,(HL)                ; Keep the paper
    AND $38
PLOT_PAPER_TEST:
    CP $00                   ; The ink, shifted to where the paper is
    JR Z,PLOT_FLIP
PLOT_INK_AS_IS:
    OR $00
    LD (HL),A
    POP HL
    RET
PLOT_FLIP:
PLOT_INK_FLIPPED:
    OR $00
    LD (HL),A
    POP HL
    RET

    ASSERT $ <= CLEAR_CANVAS, "the line drawer has run into CLEAR_CANVAS"
    DISPLAY "line region ends at ",/H,$," (limit ",/H,CLEAR_CANVAS,")"


; --------------------------------------------------------------------------
; What does not fit beside them goes where special word slot 0's handler was:
; $82FD-$8390, 148 bytes nothing ever runs. SPECIAL_WORDS names $8315 as slot
; 0's handler, but slot 0 holds no word, so PARSE_SPECIAL can never choose it,
; and nothing else leads into these bytes (see the disassembly's note there).
; --------------------------------------------------------------------------

    ORG UNREACHED_SPECIAL_ZERO
; The end of a fill: the seeded flags back where the old code left them, the
; caller's BC and the ink put back, and the registers the fill saved.
FILL_FINISH:
    LD A,B
    AND $01
    LD (SEEDED_ABOVE),A
    LD A,B
    RRCA
    AND $01
    LD (SEEDED_BELOW),A
    LD BC,(FILL_BC)
    XOR A
    LD (PLOT_INK),A
    POP HL
    POP DE
    RET
FILL_BC:
    DW $0000

; Set the ink the comparisons in FAST_PLOT use, from PLOT_INK: the ink as it
; is, the ink with its three bits flipped, and the ink shifted up to where a
; paper colour sits -- PLOT_PIXEL's own arithmetic, done once per fill or line
; instead of once per pixel.
FAST_SET_INK:
    LD A,(PLOT_INK)
    LD (PLOT_INK_AS_IS+1),A
    XOR $07
    LD (PLOT_INK_FLIPPED+1),A
    LD A,(PLOT_INK)
    RLCA
    RLCA
    RLCA
    LD (PLOT_PAPER_TEST+1),A
    RET

; One step on y in the direction bit 1 of C says, with the address in HL'.
; Z if it would leave the canvas, as INC_Y and DEC_Y report it; NZ if taken.
LINE_STEP_Y:
    BIT 1,C
    JR Z,LINE_STEP_UP
    LD A,E                   ; Down, unless at y=0
    AND A
    RET Z
    DEC E
    EXX
    CALL FAST_DOWN
    EXX
    OR $01
    RET
LINE_STEP_UP:
    LD A,E                   ; Up, unless at y=127
    CP $7F
    RET Z
    INC E
    EXX
    CALL FAST_UP
    EXX
    OR $01
    RET

; The screen address and mask for (D,E), as PIXEL_ADDRESS worked them out, but
; with the mask from a table rather than a bit rotated into place.
FAST_ADDRESS:
    LD A,$7F                 ; Scanline = $7F - y
    SUB E
    LD L,A
    AND $07
    OR $40
    LD H,A
    LD A,L
    AND $C0
    RRCA
    RRCA
    RRCA
    OR H
    LD H,A
    LD A,L
    AND $38
    RLCA
    RLCA
    LD L,A
    LD A,D
    RRCA
    RRCA
    RRCA
    AND $1F
    OR L
    LD L,A
    PUSH HL
    LD A,D
    AND $07
    ADD A,low(FAST_MASKS)
    LD L,A
    LD H,high(FAST_MASKS)
    LD A,(HL)
    POP HL
    RET

    DISPLAY "spare code ends at ",/H,$," (limit ",/H,UNREACHED_SPECIAL_ZERO+148,")"
    ASSERT $ <= UNREACHED_SPECIAL_ZERO + 148, "the spare code has run past slot 0's handler"

    SAVEBIN "../game_disassembly/hobbit/hobbit_fast.bin", $6000, 40000
