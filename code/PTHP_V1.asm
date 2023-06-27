; ###############################################################
; #                                                             #
; #  Print Technik Help Plus V1 source code                     #
; #  Version 1.0 (2023.03.13)                                   #
; #  Copyright (c) 2023 Claus Schlereth                         #
; #                                                             #
; #  This source code is based on the basic extension modul     #
; #  from the company Print-Technik                             #
; #                                                             #
; #  This source is available at:                               #
; #  https://github.com/LeshanDaFo/PTHP                         #
; #                                                             #
; #  This version of the source code is under MIT License       #
; ###############################################################

CHRGET          = $0073
CHRGOT          = $0079

IONO            = $0131

INLIN           = $A560                         ; call for BASIC input and return
CRUNCH          = $A579                         ; crunch keywords into BASIC tokens
ISCNTC          = $A82C                         ; LISTEN FOR CONT-C
CRDO            = $AAD7                         ; ;PRINT CRLF TO START WITH
FRMNUM          = $ad8a                         ; evaluate expression and check is numeric, else do type mismatch
SNERR           = $AF08                         ; handle syntax error
ERRFC           = $B248                         ; illegal quantity error
GETADR          = $B7F7                         ; convert FAC_1 to integer in temporary integer
ADD             = $BC49                         ; Addition
INTOUT          = $BDCD                         ; Output Positive Integer in A/X
INTOUT1         = $BDD1                         ; Output Positive Integer in A/X
FLPSTR          = $BDDD                         ; Convert FAC#1 to ASCII String
EREXIT          = $E0F9                         ; Error exit
READY           = $E386                         ; go handle error message
SECND           = $FF93                         ; send SA after LISTEN
TKSA            = $FF96                         ; Set secondary address
IECIN           = $FFA5                         ; Read byte from IEC bus
CIOUT           = $FFA8                         ; handshake IEEE byte out
UNTALK          = $FFAB                         ; send UNTALK out IEEE
UNLSN           = $FFAE                         ; send UNLISTEN out IEEE
LISTN           = $FFB1                         ; send LISTEN out IEEE
TALK            = $FFB4                         ; send TALK out IEEE
OPEN            = $FFC0                         ; OPEN Vector
CLOSE           = $FFC3                         ; CLOSE Vector
CHKOUT          = $FFC9                         ; Set Output
CLRCHN          = $FFCC                         ; Restore I/O Vector
CHRIN           = $FFCF                         ; Input Vector
CHROUT          = $FFD2                         ; Output Vector
SAVE            = $FFD8                         ; Save Vector
STOPT           = $FFE1                         ; Test STOP Vector
NMI             = $FE5E                         ; NMI after found Modul
GETIN           = $FFE4                         ; Vector: Kernal GETIN Routine

; seems there is an error at address $8182
; is:           bcs $810c
; should:       bcs $810e

!to"build/PTHP-V1.crt",plain
; ----------------------------------------------
; -------- Modul Part --------------------------
; ----------------------------------------------
  
!zone main

        *=$8000                                 ; Modul start address

        !byte   <reset, >reset                  ; $8000 RESET-Vector 
        !byte   <NMI, >NMI                      ; $8002 NMI-Vector   
        !byte   $c3, $c2, $cd                   ; ab $8004 CBM80 (bei den Buchstaben muss
        !text   "80"                            ; das 7. Bit gesetzt sein!)

reset:                                          ; Einsprung bei einem Reset
        ldx     #$05
        stx     $d016
        jsr     $fda3                           ; initialise SID, CIA and IRQ
        jsr     $fd50                           ; RAM test and find RAM end
        jsr     $fd15                           ; set Ram end and restore default I/O vectors
        jsr     $FF5B                           ; initialise VIC and screen editor, set own colors
        cli
        jsr     $e453                           ; initialise the BASIC vector table
        jsr     $e3bf                           ; initialise the BASIC RAM locations
        jsr     $e422                           ; print the start up message and initialise the memory pointers
        ldx     #$fb                            ; set x for stack
        txs                                     ; set stack
        jsr     MPREP                           ; initialize the Modul, and print the message
        jmp     READY                           ; go handle error message
-----------------------------------
L802d:  jmp     L85cd
-----------------------------------
MPREP = $80e8
FILL1:  !fi     MPREP-FILL1, $aa                ; fill bytes


MPREP:
; ----------------------------------------------
; -------- Modul Start prepare -----------------
; ----------------------------------------------
        ldx     #$00
        stx     $0132
        lda     #$08
        sta     IONO
L80f2:  lda     SCNMSG,X                        ; load screen message char
        beq     L80fd                           ; branch if end
        jsr     CHROUT                          ; output char on screen
        inx                                     ; increase counter
        bne     L80f2                           ; go for next char
; patch basic warm start
L80fd:  lda     #<START                         ; new BASIC warm start low byte
        ldx     #>START                         ; new BASIC warm start high byte
        bne     L8107                           ; 'jmp' set vector
; restore basic warm start values
L8103:  lda     #$83                            ; old BASIC warm start low byte
        ldx     #$a4                            ; old BASIC warm start low high
L8107:  sta     $0302                           ; set vector low byte
        stx     $0303                           ; set vector high byte
        rts
---------------------------------
START:  jsr     INLIN
        stx     $7a
        sty     $7b
        jsr     CHRGET
        tax
        beq     START
        bcc     L8149
        ldx     #$00
        stx     $0132
        ldx     #$11
L8124:  cmp     DMCHAR,x                        ; DOS and monitor command char
        beq     L8134
        dex
        bpl     L8124
L812c:  stx     $3a
        jsr     CRUNCH                          ; do crunch BASIC tokens
        jmp     $a7e1                           ; go scan and interpret code
---------------------------------
L8134:  lda     DMLBYT,x                        ; DOS and monitor low byte
        sta     $55
        lda     DMHBYT,x                        ; DOS and monitor high byte
        sta     $56
        jmp     ($0055)                         ; execute command
; ----------------------------------------------
; - $8141  basic command GENLINE -------------
; ----------------------------------------------
GENLINE:
        jsr     L8457
        lda     #$80
        sta     $0132
L8149:  bit     $0132
        bpl     L817b
        lda     $0133
        ldy     $0134
        jsr     L8195
        ldy     #$00
L8159:  lda     $0100,y
        beq     L8164
        sta     $0277,y
        iny
        bne     L8159
L8164:  lda     #$20
        sta     $0277,y
        iny
        sty     $c6
        lda     $0133
        ldy     $0134
        jsr     L8187
        sta     $0133
        sty     $0134
L817b:  ldx     #$ff
        stx     $3a
        jsr     CHRGOT
        bcs     START-2
        jmp     $a49c
---------------------------------
L8187:  clc
        adc     $0135
        bcc     L8194
        iny
        cpy     #$fa
        bcc     L8194
        ldy     #$00
L8194:  rts
---------------------------------
L8195:  sta     $63
        sty     $62
L8199:  ldx     #$90
        sec
        jsr     ADD
        jmp     FLPSTR
; ----------------------------------------------
; - #81A2  basic commands call -----------------
; ----------------------------------------------
BASCMD:  ldy     #$01
        lda     ($7a),y
        ldx     #$0e
L81a8:  cmp     BCCHAR,x                        ; basic command char table
        beq     L81b3
        dex
        bpl     L81a8
        jmp     L812c
---------------------------------
L81b3:  lda     BCLBYT,x                        ; basic command low byte table
        sta     $55
        lda     BCHBYT,x                        ; basic command high byte table
        sta     $56
        inc     $7a
        jmp     ($0055)
; ----------------------------------------------
; - #81C2  Matrix and Variable dump ------------
; ------- start $8239 and $82F7 ----------------
; ----------------------------------------------
L81c2:  jsr     CRDO
L81c5:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        beq     L81c5
        ldy     #$00
        lda     ($45),y
        tax
        and     #$7f
        jsr     CHROUT
        iny
        lda     ($45),y
        tay
        and     #$7f
        beq     L81e4
        jsr     CHROUT
L81e4:  txa
        bpl     L81eb
        lda     #$25
        bne     L81f0
L81eb:  tya
        bpl     L81f3
        lda     #$24
L81f0:  jsr     CHROUT
L81f3:  rts
---------------------------------
L81f4:  jsr     CHROUT
L81f7:  jsr     L88a8
        lda     #$3d
        jmp     CHROUT
---------------------------------
L81ff:  ldy     #$00
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        tay
        txa
        jsr     $b395
        jmp     $bdd7
---------------------------------
L820f:  jsr     $bba6
        jmp     $bdd7
---------------------------------
L8215:  jsr     L8234
        ldy     #$02
        lda     ($22),y
        sta     $25
        dey
        lda     ($22),y
        sta     $24
        dey
        lda     ($22),y
        sta     $26
        beq     L8234
L822a:  lda     ($24),y
        jsr     CHROUT
        iny
        cpy     $26
        bne     L822a
L8234:  lda     #$22
        jmp     CHROUT
; - $8239  basic command MATRIX DUMP -----------
M_DUMP: ldx     $30
        lda     $2f
L823d:  sta     $45
        stx     $46
        cpx     $32
        bne     L8247
        cmp     $31
L8247:  bcc     L824c
        jmp     READY                           ; go handle error message
---------------------------------
L824c:  ldy     #$04
        adc     #$05
        bcc     L8253
        inx
L8253:  sta     $0b
        stx     $0c
        lda     ($45),y
        asl
        tay
        adc     $0b
        bcc     L8260
        inx
L8260:  sta     $fb
        stx     $fc
        dey
        sty     $55
        lda     #$00
L8269:  sta     $0205,y
        dey
        bpl     L8269
        bmi     L82a3
L8271:  ldy     $55
L8273:  dey
        sty     $fd
        tya
        tax
        inc     $0206,x
        bne     L8280
        inc     $0205,x
L8280:  lda     $0205,y
        cmp     ($0b),y
        bne     L828d
        iny
        lda     $0205,y
        cmp     ($0b),y
L828d:  bcc     L82a3
        lda     #$00
        ldy     $fd
        sta     $0205,y
        sta     $0206,y
        dey
        bpl     L8273
        lda     $fb
        ldx     $fc
        jmp     L823d
---------------------------------
L82a3:  jsr     L81c2
        ldy     $55
        lda     #$28
L82aa:  jsr     CHROUT
        lda     $0204,y
        ldx     $0205,y
        sty     $fd
        jsr     INTOUT
        lda     #$2c
        ldy     $fd
        dey
        dey
        bpl     L82aa
        lda     #$29
        jsr     L81f4
        lda     $fb
        ldx     $fc
        sta     $22
        stx     $23
        ldy     #$00
        lda     ($45),y
        bpl     L82da
        jsr     L81ff
        lda     #$02
        bne     L82eb
L82da:  iny
        lda     ($45),y
        bmi     L82e6
        jsr     L820f
        lda     #$05
        bne     L82eb
L82e6:  jsr     L8215
        lda     #$03
L82eb:  clc
        adc     $fb
        sta     $fb
        bcc     L82f4
        inc     $fc
L82f4:  jmp     L8271
; - $82F7  basic command VAR DUMP --------------
V_DUMP: lda     $2d
        ldy     $2e
L82fb:  sta     $45
        sty     $46
        cpy     $30
        bne     L8305
        cmp     $2f
L8305:  bcc     L830a
        jmp     READY                           ; go handle error message
---------------------------------
L830a:  adc     #$02
        bcc     L830f
        iny
L830f:  sta     $22
        sty     $23
        jsr     L81c2
        jsr     L81f7
        txa
        bpl     L8322
        jsr     L81ff
        jmp     L832e
---------------------------------
L8322:  tya
        bmi     L832b
        jsr     L820f
        jmp     L832e
---------------------------------
L832b:  jsr     L8215
L832e:  lda     $45
        ldy     $46
        clc
        adc     #$07
        bcc     L82fb
        iny
        bcs     L82fb
; ----------------------------------------------
; ------- Matrix and Variable dump end ---------
; ----------------------------------------------

; ----------------------------------------------
; - $833A  basic command FIND ------------------
; ----------------------------------------------
FIND:   inc     $7a
        lda     $3d
        pha
        jsr     CRUNCH
        jsr     CHRGET
        ldy     #$00
        cmp     #$22
        bne     L834e
        dey
        inc     $7a
L834e:  sty     $fe
        lda     $2b
        ldx     $2c
L8354:  sta     $3d
        stx     $23
        sta     $22
        sta     $5f
        stx     $60
L835e:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        beq     L835e
        ldy     #$00
        sty     $0f
        iny
        lda     ($5f),y
        bne     L8377
        pla
        sta     $3d
        jmp     READY                           ; go handle error message
---------------------------------
L8377:  lda     #$04
        !by     $2c
L837a:  lda     #$01
        clc
        adc     $22
        sta     $22
        bcc     L8385
        inc     $23
L8385:  ldy     #$00
        lda     ($22),y
        beq     L83a6
        cmp     #$22
        bne     L8395
        lda     $0f
        eor     #$ff
        sta     $0f
L8395:  lda     $0f
        cmp     $fe
        bne     L837a
L839b:  lda     ($7a),y
        beq     L83ac
        cmp     ($22),y
        bne     L837a
        iny
        bne     L839b
L83a6:  lda     $22
        ldx     $23
        bne     L83b5
L83ac:  inc     $3d
        jsr     L83d0
        lda     $5f
        ldx     $60
L83b5:  clc
        adc     #$01
        bcc     L8354
        inx
        bcs     L8354
; ----------------------------------------------
; - $83BD  basic command HELP ------------------
; ----------------------------------------------
HELP:   lda     $3a
        sta     $15
        lda     $39
        sta     $14
        jsr     $a613
        bcc     L83cd
        jsr     L83d0
L83cd:  jmp     READY                           ; go handle error message
---------------------------------
L83d0:  jsr     CRDO
        ldy     #$02
        sty     $0f
        lda     ($5f),y
        tax
        iny
        lda     ($5f),y
        jsr     INTOUT
        jsr     L88a8
        ldx     $5f
        dex
        cpx     $3d
        bne     L83ec
        sty     $c7
L83ec:  lda     #$04
        !by     $2c
L83ef:  lda     #$01
        clc
        adc     $5f
        ldx     $5f
        sta     $5f
        bcc     L83fc
        inc     $60
L83fc:  cpx     $3d
        bne     L8404
        lda     #$01
        sta     $c7
L8404:  ldy     #$00
        lda     ($5f),y
        bne     L840b
        rts
---------------------------------
L840b:  cmp     #$3a
        bne     L8411
        sty     $c7
L8411:  cmp     #$22
        bne     L841d
        lda     $0f
        eor     #$ff
        sta     $0f
        lda     #$22
L841d:  tax
        bmi     L8428
L8420:  and     #$7f
L8422:  jsr     CHROUT
        jmp     L83ef
---------------------------------
L8428:  cmp     #$ff
        beq     L8422
        bit     $0f
        bmi     L8422
        ldy     #$a0
        sty     $23
        ldy     #$9e
        sty     $22
        ldy     #$00
        asl
        beq     L844d
L843d:  dex
        bpl     L844c
L8440:  inc     $22
        bne     L8446
        inc     $23
L8446:  lda     ($22),y
        bpl     L8440
        bmi     L843d
L844c:  iny
L844d:  lda     ($22),y
        bmi     L8420
        jsr     CHROUT
        iny
        bne     L844d
L8457:  jsr     CHRGET
        bne     L8464
        ldx     #$0a
        ldy     #$00
        lda     #$64
        bne     L8476
L8464:  jsr     $b7eb
        lda     $14
        ldy     $15
        cpy     #$fa
        bcc     L8472
L846f:  jmp     SNERR                           ; syntax error
---------------------------------
L8472:  cpx     #$00
        beq     L846f
L8476:  stx     $0135
        sta     $0133
        sty     $0134
        rts
; ----------------------------------------------
; - $8480  basic command DELETE ----------------
; ----------------------------------------------
DELETE: jsr     CHRGET
        beq     L846f
        bcc     L848b
        cmp     #$2d
        bne     L846f
L848b:  jsr     $a96b
        jsr     $a613
        jsr     CHRGOT
        beq     L84a2
        cmp     #$2d
        bne     L8464
        jsr     CHRGET
        jsr     $a96b
        bne     L846f
L84a2:  lda     $14
        ora     $15
        bne     L84ac
        lda     #$ff
        sta     $15
L84ac:  ldx     $5f
        lda     $60
        stx     $fb
        sta     $fc
L84b4:  stx     $22
        sta     $23
        ldy     #$01
        lda     ($22),y
        beq     L84d9
        iny
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        cmp     $15
        bne     L84cd
        cpx     $14
        beq     L84cf
L84cd:  bcs     L84d9
L84cf:  ldy     #$00
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        bne     L84b4
L84d9:  lda     $2d
        sta     $24
        lda     $2e
        sta     $25
        jsr     L8c02
        lda     $26
        sta     $2d
        lda     $27
        sta     $2e
        jmp     $a52a
; ----------------------------------------------
; - $84EF  basic command KILL ------------------
; ----------------------------------------------
KILL:   jsr     L8103
; ----------------------------------------------
; - $84F2  basic command END TRACE -------------
; ----------------------------------------------
ENDTRACE:
        lda     #$e4
        ldx     #$a7
L84f6:  sta     $0308
        stx     $0309
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $84FF  basic command LIST PAGE -------------
; ----------------------------------------------
LPAGE:  jsr     CHRGET
        jsr     $a96b
        jsr     $a613
        jsr     $abb7
        lda     $3d
        pha
L850e:  lda     $5f
        sta     $fd
        lda     $60
        sta     $fe
        lda     #$93
        jsr     CHROUT
L851b:  ldx     $5f
        inx
        stx     $3d
        ldy     #$01
        lda     ($5f),y
        beq     L8535
        jsr     L83d0
        inc     $5f
        bne     L852f
        inc     $60
L852f:  lda     $d6
        cmp     #$16
        bcc     L851b
L8535:  lda     #$17
        sta     $d6
        jsr     CRDO
L853c:  jsr     GETIN
        cmp     #$03
        bne     L8549
        pla
        sta     $3d
        jmp     START
---------------------------------
L8549:  cmp     #$0d
        bne     L8555
        ldy     #$01
        lda     ($5f),y
        beq     L853c
        bne     L850e
L8555:  cmp     #$5e
        bne     L853c
        jsr     L85bf
        bcs     L8535
        lda     #$93
        jsr     CHROUT
        lda     $fe
        pha
        lda     $fd
        pha
        ldx     #$16
L856b:  stx     $d6
        stx     $fc
        lda     $fd
        sta     $24
        lda     $fe
        sta     $25
L8577:  ldy     #$00
L8579:  lda     $24
        bne     L857f
        dec     $25
L857f:  dec     $24
        lda     ($24),y
        bne     L8579
        iny
        lda     ($24),y
        cmp     $fd
        bne     L8577
        iny
        lda     ($24),y
        cmp     $fe
        bne     L8577
        ldx     $24
        ldy     $25
        inx
        bne     L859b
        iny
L859b:  stx     $fd
        stx     $5f
        sty     $fe
        sty     $60
        inx
        stx     $3d
        jsr     L83d0
        jsr     L85bf
        bcc     L85b7
L85ae:  pla
        sta     $5f
        pla
        sta     $60
        jmp     L8535
---------------------------------
L85b7:  ldx     $fc
        dex
        dex
        bpl     L856b
        bmi     L85ae
L85bf:  lda     $2c
        cmp     $fe
        bne     L85c9
        lda     $2b
        cmp     $fd
L85c9:  rts
; ----------------------------------------------
; - $85CA  basic command RENUMBER --------------
; ----------------------------------------------
RENUMBER:
        jsr     L8457
L85cd:  jsr     $a68e
L85d0:  ldy     #$02
        lda     ($7a),y
        bne     L860c
        lda     $2b
        ldx     $2c
        sta     $22
L85dc:  stx     $23
        ldy     #$01
        lda     ($22),y
        tax
        bne     L85e8
        jmp     $a52a
---------------------------------
L85e8:  iny
        lda     $0133
        sta     ($22),y
        iny
        lda     $0134
        sta     ($22),y
        ldy     #$00
        lda     ($22),y
        sta     $22
        lda     $0133
        ldy     $0134
        jsr     L8187
        sta     $0133
        sty     $0134
        jmp     L85dc
---------------------------------
L860c:  lda     $7a
        clc
        adc     #$04
        sta     $7a
        bcc     L8617
        inc     $7b
L8617:  jsr     CHRGET
L861a:  tax
        beq     L85d0
        cmp     #$89
        beq     L862d
        cmp     #$8a
        beq     L862d
        cmp     #$8d
        beq     L862d
        cmp     #$a7
        bne     L8617
L862d:  lda     $7a
        sta     $28
        lda     $7b
        sta     $29
        jsr     CHRGET
        bcs     L861a
        jsr     $a96b
        lda     $2b
        ldx     $2c
        sta     $24
        lda     $0133
        ldy     $0134
L8649:  stx     $25
        sta     $63
        sty     $62
        ldy     #$01
        lda     ($24),y
        tax
        bne     L865d
        dex
        stx     $62
        stx     $63
        bne     L867b
L865d:  iny
        lda     ($24),y
        cmp     $14
        beq     L8674
L8664:  ldy     #$00
        lda     ($24),y
        sta     $24
        lda     $63
        ldy     $62
        jsr     L8187
        jmp     L8649
---------------------------------
L8674:  iny
        lda     ($24),y
        cmp     $15
        bne     L8664
L867b:  jsr     L8199
        lda     $28
        sta     $7a
        lda     $29
        sta     $7b
        ldx     #$00
L8688:  lda     $0101,x
        beq     L86c4
        pha
        jsr     CHRGET
        bcc     L86bc
        lda     $2d
        sta     $22
        lda     $2e
        sta     $23
        inc     $2d
        bne     L86a1
        inc     $2e
L86a1:  lda     $22
        bne     L86a7
        dec     $23
L86a7:  dec     $22
        ldy     #$00
        lda     ($22),y
        iny
        sta     ($22),y
        lda     $22
        cmp     $7a
        bne     L86a1
        lda     $23
        cmp     $7b
        bne     L86a1
L86bc:  pla
        ldy     #$00
        sta     ($7a),y
        inx
        bne     L8688
L86c4:  jsr     CHRGET
        bcs     L86f7
L86c9:  lda     $7a
        sta     $22
        lda     $7b
        sta     $23
L86d1:  ldy     #$01
        lda     ($22),y
        dey
        sta     ($22),y
        inc     $22
        bne     L86de
        inc     $23
L86de:  lda     $22
        cmp     $2d
        bne     L86d1
        lda     $23
        cmp     $2e
        bne     L86d1
        lda     $2d
        bne     L86f0
        dec     $2e
L86f0:  dec     $2d
        jsr     CHRGOT
        bcc     L86c9
L86f7:  pha
        jsr     $a533
        pla
        cmp     #$2c
        bne     L8703
        jmp     L862d
---------------------------------
L8703:  jmp     L861a
; ----------------------------------------------
; - $8704  basic command SINGLE STEP -----------
; ----------------------------------------------
S_STEP: lda     #$00
        !by     $2c
; ----------------------------------------------
; - $871F  basic command TRACE -----------------
; ----------------------------------------------
TRACE:  lda     #$80
        sta     $0130
        lda     #<L8715
        ldx     #>L8715
        jmp     L84f6
---------------------------------
L8715:  lda     $39
        ldx     $3a
        cmp     $0124
        bne     L8726
        cpx     $0125
        bne     L8726
L8723:  jmp     $a7e4
---------------------------------
L8726:  cpx     #$ff
        bne     L872f
        stx     $0125
        beq     L8723
L872f:  sta     $0122
        stx     $0123
        ldx     #$0b
L8737:  lda     $0122,x
        sta     $0124,x
        dex
        bpl     L8737
        lda     $d1
        pha
        lda     $d2
        pha
        lda     $d3
        pha
        lda     $d6
        pha
        lda     $0286
        pha
        lda     #$13
        jsr     CHROUT
        ldx     #$78
L8757:  lda     #$20
        jsr     CHROUT
        dex
        bne     L8757
        lda     #$13
        jsr     CHROUT
        ldy     #$00
L8766:  tya
        pha
        lda     $0124,y
        tax
        lda     $0125,y
        cmp     #$ff
        beq     L8785
        jsr     INTOUT
        lda     #$20
        jsr     CHROUT
        pla
        tay
        iny
        iny
        cpy     #$0c
        bcc     L8766
        bcs     L8786
L8785:  pla
L8786:  lda     $da
        ora     #$80
        sta     $da
        jsr     CRDO
        ldx     #$05
        ldy     #$00
        sty     $0f
        lda     ($3d),y
        beq     L879b
        ldx     #$01
L879b:  txa
        clc
        adc     $3d
        sta     $5f
        tya
        adc     $3e
        sta     $60
        jsr     L8404
        jsr     CRDO
        bit     $0130
        bmi     L87bd
L87b1:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        bne     L87b1
        beq     L87c8
L87bd:  lda     #$03
        ldx     $028e
        cpx     #$01
        bne     L87c8
        lda     #$00
L87c8:  sta     $0122
        ldy     #$78
L87cd:  dex
        bne     L87cd
        dey
        bne     L87cd
        dec     $0122
        bpl     L87cd
        pla
        sta     $0286
        pla
        sta     $d6
        pla
        sta     $d3
        pla
        sta     $d2
        pla
        sta     $d1
        jmp     $a7e4
; ----------------------------------------------
; - #87EB  basic command APPEND ----------------
; ----------------------------------------------
APPEND: inc     $7a
        jsr     $e1d4
        ldx     $2b
        lda     $2c
L87f4:  stx     $5f
        sta     $60
        ldy     #$00
        lda     ($5f),y
        tax
        iny
        lda     ($5f),y
        bne     L87f4
        ldy     $60
        ldx     $5f
        sta     $0133
        sta     $0a
        sta     $b9
        jsr     $ffd5
        jmp     L8954
; ----------------------------------------------
; - $8813 -- print free memory -----------------
; ----------------------------------------------
PRTFRE: jsr     $b526                           ; Garbage Collection
        sec
        lda     $33
        sbc     $31
        tax
        lda     $34
        sbc     $32
        jsr     INTOUT
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8826 -- switch to uppercase ---------------
; ----------------------------------------------
UPCASE: lda     #$8e
        !by     $2C
; ----------------------------------------------
; - $8829 -- switch to lower case --------------
; ----------------------------------------------
LOWCASE:lda     #$0e
        jsr     $e716
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8831 -- close command and file ------------
; ----------------------------------------------
CLFILE: jsr     CLRCHN
        lda     #$ff
        jsr     CLOSE
        jmp     READY                           ; go handle error message
---------------------------------
L883c:  jsr     $e206
        jmp     $b79e
; ----------------------------------------------
; - $8842 -- open file with cmd file -----------
; ----------------------------------------------
OPNFILE:inc     $7a
        ldx     #$04
        jsr     L883c
        stx     $ba
        lda     #$ff
        sta     $b8
        sta     $b9
        jsr     OPEN
        ldx     #$ff
        jsr     $e118
        jmp     START
; ----------------------------------------------
; - $885C jump in for convert - "!$", "!#" -----
; ----------------------------------------------
CONVERT:
        jsr     CHRGET                          ; get next char
        cmp     #$24                            ; cmpare with "$"
        bne     CKNXT                           ; if not, check next
; convert dec to hex ---------------------------
        jsr     CHRGET                          ; get next char
        jsr     FRMNUM                          ; evaluate expression and check is numeric, else do type mismatch                                
        jsr     GETADR                          ; convert FAC_1 to integer in temporary integer
        jsr     HEXOUT                          ; output high byte as hex
        tya                                     ; get low byte
        jsr     HEXOUT                          ; output low byte as hex
        jmp     READY                           ; go handle error message
; - $8876 - check for # ------------------------
CKNXT:  cmp     #$23                            ; compare with "#"
        beq     CNVDEC                          ; branch if ok
        jmp     START                           ; command not known, go back do start over
; - $887D - convert hex to dec -----------------
CNVDEC: lda     #$00                            ; loaad 00
        sta     $62                             ; clear $62
        sta     $63                             ; clear $63
        ldx     #$05                            ; load counter
L8885:  jsr     CHRGET                          ; get next char, should be a number
        beq     OUT                             ; if there is nothing more
        dex                                     ; dec counter
        bne     ISCHAR                          ; have a char
L888d:  jmp     ERRFC                           ; llegal quantity error
; - $8890 --------------------------------------
ISCHAR: jsr     L88ad                           ; check if "0-9" or "A-F", if "A-F" convert to 3A-3F, get back values from $30 to $3F
        bcs     L888d                           ; if carry was set, no valid value was found, go output error
L8895:  rol
        rol     $63
        rol     $62
        dey
        bne     L8895
        beq     L8885
OUT:    jsr     INTOUT1
        jmp     READY                           ; ready
---------------------------------
L88a5:  jsr     L88a8
L88a8:  lda     #$20
        jmp     CHROUT
---------------------------------
L88ad:  bcc     ISNUM                           ; is number
        cmp     #$41                            ; cmp "A"
        bcs     IF_F                            ; branch if equal or higher
L88b3:  sec                                     ; set carry for error
        rts
; - $88B5 - is char ----------------------------
IF_F:   cmp     #$47                            ; cmp "F"
        bcs     L88b3                           ; go set carry for error
        sbc     #$06
; - $88BB - is number --------------------------
ISNUM:  ldy     #$04
        asl
        asl
        asl
        asl
        clc
        rts
; - $88C3 output accu as hex value -------------
HEXOUT: pha
        lsr
        lsr
        lsr
        lsr
        jsr     L88cc
        pla
L88cc:  and     #$0f
        ora     #$30
        cmp     #$3a
        bcc     L88d6
        adc     #$06
L88d6:  jmp     CHROUT
; ----------------------------------------------
; - $88D9 Save a programm ----------------------
; ----------------------------------------------
SAVEPRG:jsr     L8995                           ; get name
L88dc:  ldx     $2d                             ; end low byte
        ldy     $2e                             ; end high byte
        lda     #$2b                            ; start adress low byte
        jsr     SAVE                            ; save prg
        bcc     L88ea                           ; no error
        jmp     EREXIT                          ;
---------------------------------
L88ea:  jsr     L8b06
        lda     $0100
        cmp     #$30
        bne     L88f7
        jmp     READY                           ; go handle error message
---------------------------------
L88f7:  cmp     #$36
        beq     L88fe
L88fb:  jmp     READY                           ; go handle error message
---------------------------------
L88fe:  lda     $0101
        cmp     #$33
        bne     L88fb
        ldy     #$00
L8907:  lda     OVWTXT,y
        beq     L8912
        jsr     CHROUT
        iny
        bne     L8907
L8912:  jsr     GETIN
        cmp     #$4e
        beq     L88fb
        cmp     #$4a
        bne     L8912
        lda     #$53
        sta     $01ff
        lda     #$3a
        cmp     $0202
        bne     L892b
        lda     #$20
L892b:  sta     $0200
        lda     #$ff
        sta     $bb
        dec     $bc
        inc     $b7
        inc     $b7
        jsr     L8b4d
        dec     $b7
        dec     $b7
        jsr     L89ad
        jmp     L88dc
; ----------------------------------------------
; - $8945 load prg relative --------------------
; ----------------------------------------------
LDREL:  lda     #$00
        !by     $2c
; ----------------------------------------------
; - $8948 load and run prg relative ------------
; ----------------------------------------------
LDRUN:  lda     #$80
        sta     $0133
        lda     #$00
        sta     $b9
L8951:  jsr     L89bf
L8954:  bcc     L8959
        jmp     EREXIT
---------------------------------
L8959:  jsr     $ffb7
        and     #$bf
        beq     L8963
        jmp     L8b00
---------------------------------
L8963:  stx     $2d
        sty     $2e
        bit     $0133
        bmi     L896f
        jmp     $e1ab
---------------------------------
L896f:  jsr     $a659
        jsr     $a533
        jsr     $a68e
        jmp     $a7ae
; ----------------------------------------------
; - $897B Verify "<" ---------------------------
; ----------------------------------------------
VERIFY: lda     #$00
        sta     $b9
        lda     #$01
        jsr     L89bf
        jsr     $e17e
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $898A load prg absolut ---------------------
; ----------------------------------------------
LDABS:  lda     #$01
        sta     $b9
        lda     #$00
        sta     $0133
        beq     L8951
L8995:  ldy     #$00
L8997:  iny
        lda     $0200,y
        bne     L8997
        dey
        sty     $b7
L89a0:  lda     $b8
        sta     $0134
        lda     $9a
        sta     $0135
        jsr     CLRCHN
L89ad:  ldy     #$01
        sty     $bb
        ldy     #$02
        sty     $bc
        ldy     #$00
        sty     $90
        lda     IONO
        sta     $ba
        rts
---------------------------------
L89bf:  sta     $0a
        jsr     L8995
        lda     $0a
        ldx     $2b
        ldy     $2c
        jmp     $ffd5
; ----------------------------------------------
; - $89CD load directory -----------------------
; ----------------------------------------------
LDDIR:  lda     $9a
        cmp     #$03
        bne     L89d8
        lda     #$93
        jsr     CHROUT
L89d8:  jsr     L8995
        dec     $bb
        inc     $b7
        lda     #$60
        sta     $b9
        jsr     $f3d5
        bcc     L89eb
        jmp     L8a9f
---------------------------------
L89eb:  lda     #$00
        sta     $90
        ldy     #$06
L89f1:  sty     $b7
        lda     IONO
        sta     $ba
        jsr     TALK
        lda     #$60
        sta     $b9
        jsr     TKSA
        ldy     #$00
        lda     $90
        bne     L8a1f
L8a08:  jsr     IECIN
        sta     $0200,y
        cpy     $b7
        bcc     L8a15
        tax
        beq     L8a1f
L8a15:  iny
        lda     $90
        beq     L8a08
        lda     #$00
        sta     $0200,y
L8a1f:  sty     $fb
        lda     $90
        sta     $fc
        jsr     UNTALK
        lda     $0135
        cmp     #$03
        beq     L8a35
        ldx     $0134
        jsr     CHKOUT
L8a35:  ldy     $b7
        cpy     $fb
        bcs     L8a57
        lda     $01ff,y
        ldx     $01fe,y
        jsr     INTOUT
        jsr     L88a8
        ldy     $b7
L8a49:  lda     $0200,y
        beq     L8a54
        jsr     CHROUT
        iny
        bne     L8a49
L8a54:  jsr     CRDO
L8a57:  jsr     CLRCHN
        lda     $fc
        bne     L8a86
L8a5e:  jsr     STOPT
        beq     L8a86
        lda     $028e
        cmp     #$01
        beq     L8a5e
        lda     $0135
        cmp     #$03
        bne     L8a81
        lda     $d6
        cmp     #$18
        bne     L8a81
        jsr     GETIN
        beq     L8a5e
        lda     #$93
        jsr     CHROUT
L8a81:  ldy     #$04
        jmp     L89f1
---------------------------------
L8a86:  lda     #$60
        sta     $b9
        lda     IONO
        sta     $ba
        jsr     $f642
        lda     $0135
        cmp     #$03
        beq     L8a9f
        ldx     $0134
        jsr     CHKOUT
L8a9f:  jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8AA2  set IO number -----------------------
; ----------------------------------------------
SETIONO:jsr     CHRGET                          ; get char
        bcs     L8ab3                           ; branch if not a number
        and     #$0f
        beq     SETIONO                         ; branch if zero
        tax                                     ; save to X
        jsr     CHRGET                          ; get next char
        beq     L8ac6
        bcc     L8ab6
L8ab3:  jmp     SNERR                           ; syntax error
---------------------------------
L8ab6:  pha
        jsr     CHRGET
        bne     L8ab3
        pla
        and     #$0f
        cpx     #$01
        bne     L8ab3
        adc     #$09
        tax
L8ac6:  cpx     #$04
        bcc     L8ab3
        cpx     #$10
        bcs     L8ab3
        stx     IONO
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; -- $8AD3 read chanel 15 ">" ------------------
; ----------------------------------------------
RDCH15: ldy     #$01
        lda     ($7a),y
        bne     L8af1
        jsr     L89a0
        jsr     L8b41
        jsr     IECIN
        pha
        jsr     UNTALK
        pla
        jsr     HEXOUT
        jsr     CRDO
        jmp     READY                           ; go handle error message
---------------------------------
L8af1:  jsr     L8995
        jsr     L8b4d
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8B0A read disk channel --------------------
; ----------------------------------------------
RDDCH:  ldy     #$01
        lda     ($7a),y
        bne     L8af1
L8b00:  jsr     L8b06
        jmp     READY                           ; go handle error message
---------------------------------
L8b06:  jsr     L89a0
        jsr     L8b41
        ldy     #$00
L8b0e:  jsr     IECIN
        sta     $0100,y
        cmp     #$0d
        beq     L8b22
        iny
        lda     $90
        beq     L8b0e
        lda     #$0d
        sta     $0100,y
L8b22:  jsr     UNTALK
        jsr     CRDO
        ldy     #$00
L8b2a:  lda     $0100,y
        jsr     CHROUT
        iny
        cmp     #$0d
        bne     L8b2a
        rts
---------------------------------
        jsr     L8b40
        jsr     CHROUT
        lda     #$6f
        sta     $b9
L8b40:  rts
---------------------------------
L8b41:  lda     $ba
        jsr     TALK
        lda     #$6f
        sta     $b9
        jmp     TKSA
---------------------------------
L8b4d:  lda     $ba
        jsr     LISTN
        lda     #$6f
        sta     $b9
        jmp     $f3ea
; ----------------------------------------------
; - $8B59  Monitorcommand handling -------------
; ----------------------------------------------
MONI:   ldx     #$00
        stx     $0133
        stx     $0134
L8b61:  stx     $0135
L8b64:  jsr     L8c8a
; ----------------------------------------------
; ----- check monitor commands: ----------------
; ----------------------------------------------
        jsr     GETIN
        ldx     #$02
        cmp     #$2f                            ; "/" modify data
        beq     L8b61
        dex
        dex
        cmp     #$2b                            ; "+" modify address
        beq     L8b61
        cmp     #$5d                            ; "]" output to screen
        beq     L8b96
        cmp     #$3e                            ; ">" computer memory
        beq     L8b83
        dex
        cmp     #$3c                            ; "<" floppy memory
        bne     L8b89
L8b83:  stx     $0133
        jsr     L8c7f
L8b89:  cmp     #$2a                            ; "*" run
        bne     L8b92
        jsr     L8cfe
        lda     #$00
L8b92:  cmp     #$5b                            ; "[" output to printer
        bne     L8b9b
L8b96:  stx     $0134
        beq     L8b64
L8b9b:  cmp     #$0d                            ; "RETURN" inc address
        bne     L8ba2
        jsr     L8c70
L8ba2:  cmp     #$5e                            ; "^" dec address"
        bne     L8bb1
        ldx     $fb
        bne     L8bac
        dec     $fc
L8bac:  dec     $fb
        jsr     L8c7f
L8bb1:  cmp     #$20                            ; " " dissasemble continous
        bne     L8bb8
        jsr     L8d0b
L8bb8:  cmp     #$2d                            ; "-" dissasemble 1 line
        bne     L8bbf
        jsr     L8d3a
L8bbf:  cmp     #$40                            ; "@" transfer
        bne     L8bc8
        jsr     L8c02
        lda     #$00
L8bc8:  cmp     #$3d                            ; "=" exit monitor
        bne     L8bcf
        jmp     READY                           ; go handle error message
---------------------------------
L8bcf:  jsr     $007c
        jsr     L88ad
        bcs     L8bff
        ldx     $0135
L8bda:  rol
        rol     $fb,x
        rol     $fc,x
        dey
        bne     L8bda
        txa
        beq     L8bef
        ldx     $0133
        beq     L8bfb
        ldx     #$57
        jsr     L8cac
L8bef:  ldx     $0133
        beq     L8bff
        ldx     #$52
        jsr     L8cac
        beq     L8bff
L8bfb:  lda     $fd
        sta     ($fb),y
L8bff:  jmp     L8b64
---------------------------------
L8c02:  ldx     $fb
        stx     $26
        lda     $fc
        sta     $27
        cmp     $23
        bne     L8c10
        cpx     $22
L8c10:  bcc     L8c50
        beq     L8c50
        lda     $24
        sec
        sbc     $22
        tax
        lda     $25
        sbc     $23
        tay
        txa
        clc
        adc     $26
        sta     $26
        tya
        adc     $27
        sta     $27
L8c2a:  lda     $24
        bne     L8c30
        dec     $25
L8c30:  dec     $24
        lda     $26
        bne     L8c38
        dec     $27
L8c38:  dec     $26
        lda     $25
        cmp     $23
        bne     L8c44
        lda     $24
        cmp     $22
L8c44:  bcc     L8c4f
        ldy     #$00
        lda     ($24),y
        sta     ($26),y
        tya
        beq     L8c2a
L8c4f:  rts
---------------------------------
L8c50:  lda     $23
        cmp     $25
        bne     L8c5a
        lda     $22
        cmp     $24
L8c5a:  bcs     L8c4f
        ldy     #$00
        lda     ($22),y
        sta     ($26),y
        inc     $22
        bne     L8c68
        inc     $23
L8c68:  inc     $26
        bne     L8c50
        inc     $27
        bne     L8c50
L8c70:  jsr     CRDO
L8c73:  inc     $fb
        bne     L8c79
        inc     $fc
L8c79:  ldy     #$00
        lda     ($fb),y
        sta     $fd
L8c7f:  lda     $0133
        beq     L8c89
        ldx     #$52
        jsr     L8cac
L8c89:  rts
---------------------------------
L8c8a:  ldy     #$00
        sty     $d3
        ldx     $0133
        bne     L8c97
        lda     ($fb),y
        sta     $fd
L8c97:  lda     $fc
        jsr     HEXOUT
        lda     $fb
        jsr     HEXOUT
        jsr     L88a5
        lda     $fd
        jsr     HEXOUT
        jmp     L88a8
---------------------------------
L8cac:  lda     IONO
        sta     $ba
        jsr     LISTN
        lda     #$6f
        sta     $b9
        jsr     SECND
        lda     #$4d
        jsr     CIOUT
        lda     #$2d
        jsr     CIOUT
        txa
        jsr     CIOUT
        lda     $fb
        jsr     CIOUT
        lda     $fc
        jsr     CIOUT
        cpx     #$57
        bne     L8ce1
        lda     #$01
        jsr     CIOUT
        lda     $fd
        jsr     CIOUT
L8ce1:  jsr     UNLSN
        cpx     #$52
        bne     L8cfb
        lda     IONO
        jsr     TALK
        lda     $b9
        jsr     TKSA
        jsr     IECIN
        sta     $fd
        jsr     UNTALK
L8cfb:  lda     #$00
        rts
---------------------------------
L8cfe:  ldx     $0133
        beq     L8d08
        ldx     #$45
        jmp     L8cac
---------------------------------
L8d08:  jmp     ($00fb)
---------------------------------
L8d0b:  jsr     STOPT
        bne     L8d11
        rts
---------------------------------
L8d11:  lda     $028e
        cmp     #$01
        beq     L8d0b
        jsr     L8d3a
        jmp     L8d0b
---------------------------------
L8d1e:  jsr     CLRCHN
        jsr     L8c73
L8d24:  bit     $0134
        bpl     L8d39
        lda     #$04
        sta     $9a
        sta     $ba
        jsr     LISTN
        lda     #$ff
        sta     $b9
        jmp     SECND
---------------------------------
L8d39:  rts
---------------------------------
L8d3a:  jsr     L8d24
        jsr     L8c8a
        lda     $fd
        tay
        lsr
        bcc     L8d51
        lsr
        bcs     L8d60
        cmp     #$22
        beq     L8d60
        and     #$07
        ora     #$80
L8d51:  lsr
        tax
        lda     L8e3f,x
        bcs     L8d5c
        lsr
        lsr
        lsr
        lsr
L8d5c:  and     #$0f
        bne     L8d64
L8d60:  lda     #$00
        ldy     #$80
L8d64:  tax
        lda     L8e83,x
        sta     $0113
        and     #$03
        sta     $0112
        tya
        and     #$8f
        tax
        tya
        ldy     #$03
        cpx     #$8a
        beq     L8d86
L8d7b:  lsr
        bcc     L8d86
        lsr
L8d7f:  lsr
        ora     #$20
        dey
        bne     L8d7f
        iny
L8d86:  tax
        dey
        bne     L8d7b
        lda     L8e9d,x
        sta     $0110
        lda     L8edd,x
        sta     $0111
        ldx     #$00
L8d98:  stx     $0114
        cpx     $0112
        bcc     L8da5
        jsr     L88a5
        bne     L8db2
L8da5:  jsr     L8d1e
        lda     $fd
        ldx     $0114
        sta     $fe,x
        jsr     HEXOUT
L8db2:  jsr     L88a8
        ldx     $0114
        inx
        cpx     #$03
        bne     L8d98
L8dbd:  lda     #$00
        ldy     #$05
L8dc1:  asl     $0111
        rol     $0110
        rol
        dey
        bne     L8dc1
        ora     #$40
        cmp     #$40
        bne     L8dd3
        lda     #$2a
L8dd3:  jsr     CHROUT
        dex
        bne     L8dbd
        jsr     L88a5
        ldx     #$06
L8dde:  cpx     #$04
L8de0:  bne     L8e05
        lda     $0111
        bne     L8dea
        jsr     L88a8
L8dea:  ldy     $0112
        beq     L8e05
        lda     $0113
        cmp     #$84
        bcs     L8e27
L8df6:  lda     $00fd,y
        stx     $0114
        jsr     HEXOUT
        ldx     $0114
        dey
        bne     L8df6
L8e05:  asl     $0113
        bcc     L8e1b
        inc     $0111
        lda     L8e90,x
        jsr     CHROUT
        lda     L8e96,x
        beq     L8e1b
        jsr     CHROUT
L8e1b:  dex
        bne     L8dde
L8e1e:  jsr     CRDO
        jsr     L8d1e
        jmp     CLRCHN
---------------------------------
L8e27:  ldx     $fc
        lda     $fe
        bpl     L8e2e
        dex
L8e2e:  adc     $fb
        bcc     L8e33
        inx
L8e33:  tay
        txa
        jsr     HEXOUT
        tya
        jsr     HEXOUT
        jmp     L8e1e
---------------------------------
L8e3f:  !by     $40,$02,$45,$03,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $30,$22,$45,$33,$d0,$08,$40,$09 ; 0"e3P.@.
        !by     $40,$02,$45,$33,$d0,$08,$40,$09 ; @.e3P.@.
        !by     $40,$02,$45,$b3,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $00,$22,$44,$33,$d0,$8c,$44,$00 ; ."d3P.d.
        !by     $11,$22,$44,$33,$d0,$8c,$44,$9a ; ."d3P.d.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $62,$13,$78,$a9
L8e83:  !by     $00,$41,$01,$02,$00,$20,$99,$8d
        !by     $11,$12,$06,$8a,$05
L8e90:  !by     $21,$2c,$29,$2c,$41,$23
L8e96:  !by     $28,$59,$00,$58,$00,$00,$00
L8e9d:  !by     $14,$82,$14,$1b,$54,$83,$13,$99
        !by     $95,$82,$15,$1b,$95,$83,$15,$99
        !by     $00,$21,$10,$a6,$61,$a0,$10,$1b
        !by     $1c,$4b,$13,$1b,$1c,$4b,$11,$99
        !by     $00,$12,$53,$53,$9d,$61,$1c,$1c
        !by     $a6,$a6,$a0,$a4,$21,$00,$73,$00
        !by     $0c,$93,$64,$93,$9d,$61,$21,$4b
        !by     $7c,$0b,$2b,$09,$9d,$61,$1b,$98

L8edd:  !by     $96,$20,$18,$06,$e4,$20,$52,$46
        !by     $12,$02,$86,$12,$26,$02,$a6,$52
        !by     $00,$72,$c6,$42,$32,$72,$e6,$2c
        !by     $32,$b2,$8a,$08,$30,$b0,$62,$48
        !by     $00,$68,$60,$60,$32,$32,$32,$30
        !by     $02,$26,$70,$f0,$70,$00,$e0,$00
        !by     $d8,$d8,$e4,$e4,$30,$30,$46,$86
        !by     $82,$88,$e4,$06,$02,$02,$60,$86

; - $8F1D  module information message ----------
SCNMSG: !by     $0d,$0d,$2a,$2a,$2a,$20,$20,$48 ; ..***  h
        !by     $45,$4c,$50,$20,$20,$43,$2d,$36 ; elp  c-6
        !by     $34,$20,$20,$50,$4c,$55,$53,$20 ; 4  plus 
        !by     $20,$2a,$2a,$2a,$0d,$00         ;  ***..
; - $8F3B  overwrite message text --------------
OVWTXT: !by     $0d,$4f,$56,$45,$52,$57,$52,$49 ; .overwri
        !by     $54,$45,$3f,$20,$12,$4a,$92,$41 ; te? .j.a
        !by     $2f,$12,$4e,$92,$45,$49,$4e,$0d ; /.n.ein.
        !by     $00
; - $8F54  DOS and monitor commands char ------- 
DMCHAR: !by     $3e,$40,$3c,$2f,$5e,$24,$5d,$23 ; .>@</^$]#
        !by     $21,$5f,$2a,$2b,$2d,$28,$29,$25 ; !_*+-()%
        !by     $5c,$5b                         ; £[
; - $8F66  commands low byte -------------------
DMLBYT: !by     <RDCH15,<RDDCH,<VERIFY,<LDREL,<LDRUN,<LDDIR,<MONI,<BASCMD
        !by     <CONVERT,<SAVEPRG,<PRTFRE,<UPCASE,<LOWCASE,<OPNFILE,<CLFILE,<LDABS
        !by     <SETIONO,<ASSEMBLER
; - $8f78  commands high byte ------------------
DMHBYT: !by     >RDCH15,>RDDCH,>VERIFY,>LDREL,>LDRUN,>LDDIR,>MONI,>BASCMD
        !by     >CONVERT,>SAVEPRG,>PRTFRE,>UPCASE,>LOWCASE,>OPNFILE,>CLFILE,>LDABS
        !by     >SETIONO,>ASSEMBLER
; - $8F8A  basic commands char -----------------
BCCHAR: !by     $41,$44,$45,$46,$47,$48,$4b,$4c ; adefghkl
        !by     $4d,$52,$53,$54,$56,$55,$43     ; mrstvuc
; - $8F99  basic commands low byte -------------
BCLBYT: !by     <APPEND,<DELETE,<ENDTRACE,<FIND,<GENLINE,<HELP,<KILL,<LPAGE
        !by     <M_DUMP,<RENUMBER,<S_STEP,<TRACE,<V_DUMP,<UNDEF,<COMPACTOR
; - $8FA8  basic commands high byte ------------
BCHBYT: !by     >APPEND,>DELETE,>ENDTRACE,>FIND,>GENLINE,>HELP,>KILL,>LPAGE
        !by     >M_DUMP,>RENUMBER,>S_STEP,>TRACE,>V_DUMP,>UNDEF,>COMPACTOR

FILL2   !fi     $9000-FILL2, $aa

; ----------------------------------------------
; - $9000 - Start of assembler byte ------------
; ----------------------------------------------
ASSEMBLER:
        lda     $2b
        sta     $2d
        lda     $2c
        sta     $2e
        lda     #<L9b64
        ldy     #>L9b64
        jsr     $ab1e
        ldx     #$00
        stx     $44
        stx     $43
L9015:  jsr     CHRIN
        cmp     #$0d
        beq     L9024
        sta     $0120,x
        inx
        cpx     #$10
        bcc     L9015
L9024:  stx     $b7
        txa
        bne     L902c
        jmp     READY                           ; go handle error message
---------------------------------
L902c:  lda     #<L9b76
        ldy     #>L9b76
        jsr     $ab1e
L9033:  jsr     CHRIN
        cmp     #$30
        bcc     L9058
        cmp     #$3a
        bcc     L9048
        cmp     #$41
        bcc     L9058
        cmp     #$47
        bcs     L9058
        sbc     #$06
L9048:  asl
        asl
        asl
        asl
        ldy     #$04
L904e:  asl
        rol     $43
        rol     $44
        dey
        bne     L904e
        beq     L9033
L9058:  lda     #<L9b88
        ldy     #>L9b88
        jsr     $ab1e
        ldx     #$00
        stx     $57
        stx     $58
        stx     $59
        stx     $5a
L9069:  jsr     CHRIN
        cmp     #$0d
        beq     L907b
        cpx     #$04
        bcs     L9069
        and     #$01
        sta     $57,x
        inx
        bne     L9069
L907b:  jsr     CRDO
        ldx     #$00
        stx     $3e
        stx     $3f
        stx     $40
        stx     $2f
        stx     $30
L908a:  stx     $2a
        ldx     #$00
        stx     $7a
        stx     $29
        stx     $31
        stx     $32
        ldx     #$10
        stx     $7b
        lda     #$01
        sta     $bc
        lda     #$20
        sta     $bb
        lda     IONO
        sta     $ba
        lda     #$60
        sta     $b9
        jsr     $f3d5
        lda     $ba
        jsr     TALK
        lda     #$60
        jsr     TKSA
        jsr     IECIN
        jsr     IECIN
        jsr     UNTALK
        ldx     $3f
        bne     L90c8
        jsr     L9317
L90c8:  jsr     L9858
        jsr     L935c
        lda     $2a
        beq     L90d9
        lda     $58
        beq     L90d9
        jsr     L9271
L90d9:  lda     $7a
        clc
        adc     $4d
        sta     $7a
        bcc     L90e4
        inc     $7b
L90e4:  inc     $31
        bne     L90ea
        inc     $32
L90ea:  lda     $29
        beq     L90c8
        lda     IONO
        sta     $ba
        jsr     $f648
        ldx     $2a
        bne     L90fd
        inx
        bne     L908a
L90fd:  jsr     L92ec
L9100:  lda     #<L9b9a
        ldy     #>L9b9a
        jsr     $ab1e
        lda     $32
        ldx     $31
        jsr     INTOUT
        lda     #<L9ba2
        ldy     #>L9ba2
        jsr     $ab1e
        lda     $30
        ldx     $2f
        jsr     INTOUT
        lda     #<L9bae
        ldy     #>L9bae
        jsr     $ab1e
        lda     #$00
        ldx     $40
        jsr     INTOUT
        jsr     L92ef
        bcs     L9100
        jsr     L92ec
        lda     $59
        beq     L916a
        jsr     L91ee
        ldy     #$05
        lda     #$00
L913d:  sta     $0110,y
        dey
        bpl     L913d
L9143:  ldy     #$05
        lda     #$ff
L9147:  sta     $0100,y
        dey
        bpl     L9147
        ldx     $2b
        lda     $2c
L9151:  stx     $22
        sta     $23
        cmp     $2e
        bne     L915b
        cpx     $2d
L915b:  bcc     L9173
        lda     $0100
        bpl     L916d
        jsr     L91dc
L9165:  jsr     L92ef
        bcs     L9165
L916a:  jmp     READY                           ; go handle error message
---------------------------------
L916d:  jsr     L91ac
        jmp     L9143
---------------------------------
L9173:  ldy     #$00
L9175:  lda     ($22),y
        cmp     $0110,y
        bne     L9183
        iny
        cpy     #$06
        bne     L9175
        beq     L919f
L9183:  bcc     L919f
        ldy     #$00
L9187:  lda     ($22),y
        cmp     $0100,y
        bne     L9193
        iny
        cpy     #$06
        bne     L9187
L9193:  bcs     L919f
        ldy     #$07
L9197:  lda     ($22),y
        sta     $0100,y
        dey
        bpl     L9197
L919f:  lda     $22
        clc
        adc     #$08
        tax
        lda     $23
        adc     #$00
        jmp     L9151
---------------------------------
L91ac:  ldx     $28
        ldy     #$00
L91b0:  lda     $0100,y
        sta     $0110,y
        sta     $0200,x
        inx
        iny
        cpy     #$06
        bne     L91b0
        lda     #$3d
        sta     $0200,x
        inx
        lda     $0106
        jsr     L91fc
        lda     $0107
        jsr     L91fc
        inx
        inx
        cpx     #$27
        bne     L91d8
        inx
L91d8:  cpx     #$48
        bcc     L91f9
L91dc:  ldx     #$00
L91de:  lda     $0200,x
        jsr     CHROUT
        inx
        cpx     #$4f
        bne     L91de
        jsr     L92ef
        bcs     L91dc
L91ee:  lda     #$20
        ldx     #$4f
L91f2:  sta     $0200,x
        dex
        bpl     L91f2
        inx
L91f9:  stx     $28
        rts
---------------------------------
L91fc:  pha
        lsr
        lsr
        lsr
        lsr
        jsr     L9207
        pla
        and     #$0f
L9207:  ora     #$30
        cmp     #$3a
        bcc     L920f
        adc     #$06
L920f:  sta     $0200,x
        inx
        rts
---------------------------------
L9214:  ldy     $46
        inc     $46
        lda     $0140,y
        bne     L9222
L921d:  lda     #$00
        sty     $46
        rts
---------------------------------
L9222:  cmp     #$3b
        beq     L921d
        rts
---------------------------------
L9227:  ldy     $46
        inc     $46
        lda     $0140,y
        beq     L921d
        rts
---------------------------------
L9231:  cpx     #$01
        bne     L923e
L9235:  lda     $63
        ldy     $62
L9239:  sta     $69
        sty     $68
        rts
---------------------------------
L923e:  cpx     #$2a
        bne     L9249
        lda     $7a
        ldy     $7b
        jmp     L9239
---------------------------------
L9249:  cpx     #$03
        beq     L9250
        jmp     L94ba
---------------------------------
L9250:  lda     $49
        and     $48
        sta     $49
        lda     $48
        bne     L9265
        lda     $2a
        beq     L9235
        ldy     #>L9b35
        lda     #<L9b35
        jmp     L94c9
---------------------------------
L9265:  ldy     #$06
        lda     ($22),y
        sta     $68
        iny
        lda     ($22),y
        sta     $69
        rts
---------------------------------
L9271:  ldy     $7a
        lda     $7b
        ldx     $4d
        bpl     L9281
        ldx     #$00
        stx     $4d
        ldy     $67
        lda     $66
L9281:  sty     $fb
        sta     $fc
L9285:  jsr     L99bf
        jsr     L99ba
        ldy     #$00
L928d:  cpy     $4d
        bcs     L929a
        lda     $004e,y
        jsr     L99c6
        jmp     L929d
---------------------------------
L929a:  jsr     L99b7
L929d:  jsr     L99ba
        iny
        cpy     #$03
        bcc     L928d
        ldy     #$00
L92a7:  lda     $0139,y
        jsr     CHROUT
        iny
        cpy     #$07
        bne     L92a7
        ldx     $27
        beq     L92ce
        ldx     #$00
L92b8:  lda     $0139,y
        cmp     #$20
        beq     L92d3
        cmp     #$3d
        beq     L92d3
        jsr     CHROUT
        iny
        inx
        cpx     #$06
        bne     L92b8
        beq     L92d3
L92ce:  lda     #$20
        jsr     CHROUT
L92d3:  inx
        cpx     #$07
        bne     L92ce
L92d8:  lda     $0139,y
        beq     L92e3
        jsr     CHROUT
        iny
        bne     L92d8
L92e3:  jsr     L92ef
        bcs     L92e9
        rts
---------------------------------
L92e9:  jmp     L9285
---------------------------------
L92ec:  jsr     L92ef
L92ef:  jsr     CRDO
L92f2:  ldx     $5a
        beq     L9315
        ldx     #$04
        cpx     $9a
        beq     L930c
        stx     $9a
        stx     $ba
        jsr     LISTN
        lda     #$ff
        sta     $b9
        jsr     SECND
        sec
        rts
---------------------------------
L930c:  dec     $9a
        jsr     UNLSN
        dec     $3d
        beq     L9317
L9315:  clc
        rts
---------------------------------
L9317:  ldx     $5a
        beq     L9315
        jsr     L92f2
        ldx     $3f
L9320:  jsr     CRDO
        dex
        bpl     L9320
        ldx     #$05
        stx     $3f
        ldx     #$41
        stx     $3d
        inc     $3e
        ldx     #$00
L9332:  lda     $0120,x
L9335:  jsr     CHROUT
        inx
        cpx     $b7
        bcc     L9332
        lda     #$20
        cpx     #$3c
        bcc     L9335
        lda     #<L9bb9
        ldy     #>L9bb9
        jsr     $ab1e
        lda     #$00
        sta     $68
        ldx     $3e
        jsr     INTOUT
        jsr     CRDO
        jsr     CRDO
        jmp     L930c
---------------------------------
L935c:  ldy     #$00
        sty     $27
        sty     $46
        sty     $4d
        jsr     L950b
        txa
        beq     L93bc
        cpx     #$03
        bne     L93c8
        inc     $27
        ldy     $2a
        bne     L938f
        inc     $2f
        bne     L937a
        inc     $30
L937a:  ldy     #$05
L937c:  lda     $0110,y
        sta     ($2d),y
        dey
        bpl     L937c
        lda     $48
        beq     L938f
        ldy     #>L9b24
        lda     #<L9b24
        jsr     L94c9
L938f:  jsr     L950b
        cpx     #$3d
        bne     L93bd
        lda     #$ff
        sta     $4d
        jsr     L965d
        lda     $6b
        ldx     $6a
L93a1:  sta     $67
        stx     $66
        ldy     $2a
        bne     L93bc
        ldy     #$07
        sta     ($2d),y
        txa
        dey
        sta     ($2d),y
        lda     $2d
        clc
        adc     #$08
        sta     $2d
        bcc     L93bc
        inc     $2e
L93bc:  rts
---------------------------------
L93bd:  stx     $28
        lda     $7a
        ldx     $7b
        jsr     L93a1
        ldx     $28
L93c8:  cpx     #$02
        bne     L93cf
        jmp     L96ce
---------------------------------
L93cf:  cpx     #$2a
        bne     L93e9
        jsr     L950b
        cpx     #$3d
        beq     L93dd
L93da:  jmp     L94ba
---------------------------------
L93dd:  jsr     L965d
        lda     $6b
        sta     $7a
        lda     $6a
        sta     $7b
        rts
---------------------------------
L93e9:  cpx     #$2e
        bne     L93da
        ldy     $46
        ldx     #$00
L93f1:  lda     L9b4d,x
        cmp     $0140,y
        bne     L9402
        iny
        inx
        cpx     #$03
        bne     L93f1
        inc     $29
        rts
---------------------------------
L9402:  lda     L9b50,x
        cmp     $0140,y
        bne     L9435
        iny
        inx
        cpx     #$04
        bne     L9402
        lda     #$ff
L9412:  sta     $28
        sty     $46
L9416:  jsr     L9214
        bne     L941e
L941b:  jmp     L94ba
---------------------------------
L941e:  cmp     #$27
        bne     L9416
L9422:  jsr     L9227
        beq     L941b
        cmp     #$27
        beq     L9432
        and     $28
        jsr     L94a0
        bne     L9422
L9432:  jmp     L94b3
---------------------------------
L9435:  lda     L9b58,x
        cmp     $0140,y
        bne     L9447
        iny
        inx
        cpx     #$04
        bne     L9435
        lda     #$3f
        bne     L9412
L9447:  lda     L9b54,x
        cmp     $0140,y
        bne     L9459
        iny
        inx
        cpx     #$04
        bne     L9447
        lda     #$00
        beq     L9469
L9459:  lda     L9b5c,x
        cmp     $0140,y
        bne     L9482
        iny
        inx
        cpx     #$04
        bne     L9459
        lda     #$ff
L9469:  sta     $28
        sty     $46
L946d:  jsr     L965d
        lda     $6b
        jsr     L94a0
        bit     $28
        bpl     L9493
        jsr     L94c0
L947c:  cpx     #$2c
        beq     L946d
        bne     L94b3
L9482:  lda     L9b60,x
        cmp     $0140,y
        bne     L949a
        iny
        inx
        cpx     #$04
        bne     L9482
        jmp     L9932
---------------------------------
L9493:  lda     $6a
        jsr     L94a0
        bne     L947c
L949a:  lda     #<L9b10
        ldy     #>L9b10
        bne     L94c9
L94a0:  pha
        jsr     L984a
        pla
        ldy     $4d
        sta     ($41),y
        cpy     #$03
        bcs     L94b0
        sta     $004e,y
L94b0:  inc     $4d
        rts
---------------------------------
L94b3:  jsr     L950b
        txa
        bne     L94ba
        rts
---------------------------------
L94ba:  lda     #<L9adb
        ldy     #>L9adb
        bne     L94c9
L94c0:  lda     $6a
        bne     L94c5
        rts
---------------------------------
L94c5:  lda     #<L9ae2
        ldy     #>L9ae2
L94c9:  sty     $63
        sta     $62
        stx     $28
        cmp     #$24
        beq     L94d7
        lda     $2a
        beq     L9508
L94d7:  inc     $40
        lda     $57
        beq     L9508
L94dd:  ldy     #$00
L94df:  lda     $0139,y
        jsr     CHROUT
        iny
        cpy     #$07
        bne     L94df
        ldy     #$00
L94ec:  lda     ($62),y
        beq     L94f6
        jsr     CHROUT
        iny
        bne     L94ec
L94f6:  ldy     #$00
L94f8:  lda     L9b46,y
        beq     L9503
        jsr     CHROUT
        iny
        bne     L94f8
L9503:  jsr     L92ef
        bcs     L94dd
L9508:  ldx     $28
        rts
---------------------------------
L950b:  ldx     #$00
        stx     $62
        stx     $63
        jsr     L9214
        bne     L9517
        rts
---------------------------------
L9517:  cmp     #$20
        beq     L950b
        inx
        cmp     #$27
        bne     L9526
        jsr     L9227
        sta     $63
        rts
---------------------------------
L9526:  cmp     #$24
        bne     L9554
L952a:  jsr     L9214
        beq     L9553
        cmp     #$30
        bcc     L9551
        cmp     #$3a
        bcc     L9541
        cmp     #$41
        bcc     L9551
        cmp     #$47
        bcs     L9551
        sbc     #$06
L9541:  asl
        asl
        asl
        asl
        ldy     #$04
L9547:  asl
        rol     $63
        rol     $62
        dey
        bne     L9547
        beq     L952a
L9551:  dec     $46
L9553:  rts
---------------------------------
L9554:  cmp     #$40
        bne     L9576
L9558:  jsr     L9214
        beq     L9553
        cmp     #$30
        bcc     L9551
        cmp     #$38
        bcs     L9551
        asl
        asl
        asl
        asl
        asl
        ldy     #$03
L956c:  asl
        rol     $63
        rol     $62
        dey
        bne     L956c
        beq     L9558
L9576:  cmp     #$25
        bne     L958f
L957a:  jsr     L9214
        beq     L9553
        cmp     #$30
        beq     L9587
        cmp     #$31
        bne     L9551
L9587:  lsr
        rol     $63
        rol     $62
        jmp     L957a
---------------------------------
L958f:  cmp     #$30
        bcc     L95d1
        cmp     #$3a
        bcs     L95d1
        bcc     L95a6
L9599:  jsr     L9214
        beq     L9553
        cmp     #$30
        bcc     L9551
        cmp     #$3a
        bcs     L9551
L95a6:  and     #$0f
        pha
        lda     $63
        ldy     $62
        rol     $63
        rol     $62
        rol     $63
        rol     $62
        clc
        adc     $63
        sta     $63
        tya
        adc     $62
        sta     $62
        rol     $63
        rol     $62
        pla
        adc     $63
        sta     $63
        lda     $62
        adc     #$00
        sta     $62
        jmp     L9599
---------------------------------
L95d1:  tax
        cmp     #$41
        bcs     L95d7
L95d6:  rts
---------------------------------
L95d7:  cmp     #$5b
        bcs     L95d6
        ldy     #$04
        lda     #$20
L95df:  sta     $0111,y
        dey
        bpl     L95df
        stx     $0110
        ldx     #$01
L95ea:  jsr     L9214
        beq     L960b
        cmp     #$30
        bcc     L9609
        cmp     #$3a
        bcc     L95ff
        cmp     #$41
        bcc     L9609
        cmp     #$5b
        bcs     L9609
L95ff:  sta     $0110,x
        inx
        cpx     #$06
        bcc     L95ea
        bcs     L960b
L9609:  dec     $46
L960b:  dex
        bne     L961d
        ldx     $0110
        cpx     #$41
        beq     L95d6
        cpx     #$59
        beq     L95d6
        cpx     #$58
        beq     L95d6
L961d:  cpx     #$02
        bne     L962b
        jsr     L9962
        beq     L962b
        ldx     #$02
        sta     $47
        rts
---------------------------------
L962b:  ldx     #$03
        ldy     #$00
        sty     $48
        ldy     $2b
        lda     $2c
L9635:  sty     $22
        sta     $23
        cmp     $2e
        bne     L963f
        cpy     $2d
L963f:  bcc     L9642
        rts
---------------------------------
L9642:  ldy     #$05
L9644:  lda     $0110,y
        cmp     ($22),y
        bne     L9651
        dey
        bpl     L9644
        inc     $48
        rts
---------------------------------
L9651:  lda     $22
        clc
        adc     #$08
        tay
        lda     $23
        adc     #$00
        bne     L9635
L965d:  jsr     L950b
        txa
        bne     L9664
        rts
---------------------------------
L9664:  lda     #$01
        sta     $49
        jsr     L9231
        lda     $69
        ldy     $68
        sta     $6b
        sty     $6a
        jmp     L9699
---------------------------------
L9676:  lda     $4a
        cmp     #$2b
        bne     L968c
        lda     $6b
        clc
        adc     $69
        sta     $6b
        lda     $6a
        adc     $68
        sta     $6a
        jmp     L9699
---------------------------------
L968c:  lda     $6b
        sec
        sbc     $69
        sta     $6b
        lda     $6a
        sbc     $68
        sta     $6a
L9699:  jsr     L950b
        beq     L96b1
        stx     $4a
        cpx     #$2b
        beq     L96a8
        cpx     #$2d
        bne     L96b1
L96a8:  jsr     L950b
        jsr     L9231
        jmp     L9676
---------------------------------
L96b1:  ldy     $49
        bne     L96ba
        sty     $6b
        iny
        sty     $6a
L96ba:  cpx     #$5b
        bne     L96c9
        ldy     $6a
        sty     $6b
L96c2:  ldy     #$00
        sty     $6a
        jmp     L950b
---------------------------------
L96c9:  cpx     #$5d
        beq     L96c2
        rts
---------------------------------
L96ce:  ldx     #$01
        stx     $4d
        ldy     $47
        cpy     #$05
        beq     L96f5
        jsr     L950b
        cpx     #$41
        bne     L96e5
        lda     #$0a
        sta     $4c
        bne     L96f5
L96e5:  inc     $4d
        cpx     #$23
        bne     L96f8
        lda     #$02
        sta     $4c
        jsr     L965d
        jsr     L94c0
L96f5:  jmp     L9770
---------------------------------
L96f8:  cpx     #$28
        bne     L973e
        jsr     L965d
        cpx     #$2c
        bne     L971d
        lda     #$00
        sta     $4c
        jsr     L94c0
        jsr     L950b
        cpx     #$58
        beq     L9714
L9711:  jmp     L979e
---------------------------------
L9714:  jsr     L950b
        cpx     #$29
        bne     L9711
        beq     L9770
L971d:  lda     #$04
        sta     $4c
        cpx     #$29
        bne     L9711
        jsr     L950b
        txa
        bne     L9731
        lda     #$08
        sta     $4c
        bne     L9770
L9731:  cpx     #$2c
        bne     L9711
        jsr     L950b
        cpx     #$59
        bne     L9711
        beq     L9770
L973e:  lda     #$01
        sta     $4c
        jsr     L9664
        cpx     #$2c
        bne     L975c
        jsr     L950b
        lda     #$05
        sta     $4c
        cpx     #$58
        beq     L975c
        cpx     #$59
        bne     L9711
        lda     #$09
        sta     $4c
L975c:  lda     $6a
        beq     L9770
        inc     $4c
        inc     $4c
        inc     $4d
        lda     $4c
        cmp     #$09
        bcc     L9770
        lda     #$06
        sta     $4c
L9770:  jsr     L94b3
        lda     $6b
        sta     $4f
        lda     $6a
        sta     $50
        ldx     $47
        dex
        bne     L97b0
        lda     $4c
        cmp     #$09
        bne     L978e
        lda     #$06
        sta     $4c
        lda     #$03
        sta     $4d
L978e:  lda     $4c
        cmp     #$08
        bcs     L979e
        cmp     #$02
        bne     L97a5
        lda     $4b
        cmp     #$81
        bne     L97a5
L979e:  lda     #<L9b00
        ldy     #>L9b00
        jmp     L94c9
---------------------------------
L97a5:  lda     $4c
        asl
        asl
        adc     $4b
        sta     $4b
        jmp     L9815
---------------------------------
L97b0:  dex
        bne     L97ce
        lda     $4c
        cmp     #$09
        bcs     L97be
        lsr
        bcs     L97a5
        bcc     L979e
L97be:  cmp     #$0a
        bne     L979e
        lda     $4b
        cmp     #$63
        bcs     L979e
        adc     #$08
        sta     $4b
        bne     L9815
L97ce:  dex
        bne     L9818
        lda     #$02
        sta     $4d
        lda     $6b
        sec
        sbc     $7a
        sta     $69
        lda     $6a
        sbc     $7b
        sta     $68
        lda     $69
        sec
        sbc     #$02
        sta     $69
        lda     $68
        sbc     #$00
        sta     $68
        bmi     L9809
        bne     L97f7
        lda     $69
        bpl     L9811
L97f7:  lda     #$00
        sta     $69
        lda     $2a
        beq     L9811
        lda     #<L9af1
        ldy     #>L9af1
        jsr     L94c9
        jmp     L9811
---------------------------------
L9809:  cmp     #$ff
        bne     L97f7
        lda     $69
        bpl     L97f7
L9811:  lda     $69
        sta     $4f
L9815:  jmp     L9837
---------------------------------
L9818:  dex
        bne     L9837
        lda     $4b
        cmp     #$14
        beq     L9825
        cmp     #$0a
        bne     L9829
L9825:  ldy     #$03
        sty     $4d
L9829:  clc
        adc     $4c
        tay
        lda     L9a84,y
        bne     L9835
        jmp     L979e
---------------------------------
L9835:  sta     $4b
L9837:  lda     $4b
        sta     $4e
        jsr     L984a
        ldy     $4d
        dey
L9841:  lda     $004e,y
        sta     ($41),y
        dey
        bpl     L9841
        rts
---------------------------------
L984a:  lda     $7a
        sec
        sbc     $43
        sta     $41
        lda     $7b
        sbc     $44
        sta     $42
        rts
---------------------------------
L9858:  ldy     #$00
        sty     $68
        sty     $90
        lda     IONO
        sta     $ba
        jsr     TALK
        lda     #$60
        jsr     TKSA
        jsr     IECIN
        jsr     IECIN
        jsr     IECIN
        tax
        jsr     IECIN
        ldy     $90
        beq     L9880
        lda     #$ff
        ldx     #$ff
L9880:  sta     $62
        stx     $63
        ldx     #$90
        sec
        jsr     ADD
        jsr     FLPSTR
        ldy     #$05
        ldx     #$ff
L9891:  inx
        lda     $0100,x
        bne     L9891
L9897:  dex
        bmi     L989d
        lda     $0100,x
L989d:  sta     $0200,y
        dey
        bpl     L9897
        ldy     #$06
        sta     $0200,y
        iny
        ldx     $90
        bne     L98bd
L98ad:  jsr     IECIN
        ldx     $90
        bne     L98bd
        tax
        beq     L98cb
        sta     $0200,y
        iny
        bne     L98ad
L98bd:  lda     #$2e
        sta     $0200,y
        iny
        lda     #$80
        sta     $0200,y
        iny
        lda     #$00
L98cb:  sta     $0200,y
        jsr     UNTALK
        ldy     #$00
        sty     $0c
        sty     $23
        sty     $22
L98d9:  ldy     $22
        inc     $22
        lda     $0200,y
        bmi     L98fb
        cmp     #$22
        bne     L98ee
        lda     $0c
        eor     #$ff
        sta     $0c
        lda     #$22
L98ee:  ldy     $23
        sta     $0139,y
        tax
        bne     L98f7
        rts
---------------------------------
L98f7:  inc     $23
        bne     L98d9
L98fb:  cmp     #$ff
        beq     L98ee
        bit     $0c
        bmi     L98ee
        tax
        ldy     #$9e
        sty     $62
        ldy     #$a0
        sty     $63
        ldy     #$00
        asl
        beq     L9923
L9911:  dex
        bpl     L9922
L9914:  inc     $62
        bne     L991a
        inc     $63
L991a:  lda     ($62),y
        bpl     L9914
        bmi     L9911
L9920:  inc     $23
L9922:  iny
L9923:  ldx     $23
        lda     ($62),y
        pha
        and     #$7f
        sta     $0139,x
        pla
        bpl     L9920
        bmi     L98f7
L9932:  iny
        tya
        clc
        adc     #$40
        sta     $bb
        lda     #$01
        sta     $bc
        lda     IONO
        sta     $ba
        jsr     $f648
        lda     #$60
        sta     $b9
        jsr     $f3d5
        jsr     TALK
        lda     #$60
        jsr     TKSA
        jsr     IECIN
        jsr     IECIN
        jsr     UNTALK
        pla
        pla
        jmp     L90c8
---------------------------------
L9962:  ldy     #$02
L9964:  lda     $0110,y
        sta     $0024,y
        and     #$40
        beq     L9990
        dey
        bpl     L9964
        lda     $26
        asl
        asl
        asl
        ldx     #$03
L9978:  asl
        rol     $25
        dex
        bpl     L9978
        rol     $24
        cpx     #$fd
        bne     L9978
        ldy     #$37
L9986:  lda     $24
        cmp     L99dc,y
        beq     L9993
L998d:  dey
        bpl     L9986
L9990:  lda     #$00
        rts
---------------------------------
L9993:  lda     $25
        cmp     L9a14,y
        bne     L998d
        lda     L9a4c,y
        ldx     #$05
        cpy     #$1f
        bcs     L99b3
        dex
        cpy     #$16
        bcs     L99b3
        dex
        cpy     #$0e
        bcs     L99b3
        dex
        cpy     #$08
        bcs     L99b3
        dex
L99b3:  sta     $4b
        txa
        rts
---------------------------------
L99b7:  jsr     L99ba
L99ba:  lda     #$20
        jmp     CHROUT
---------------------------------
L99bf:  lda     $fc
        jsr     L99c6
        lda     $fb
L99c6:  pha
        lsr
        lsr
        lsr
        lsr
        jsr     L99cf
        pla
L99cf:  and     #$0f
        ora     #$30
        cmp     #$3a
        bcc     L99d9
        adc     #$06
L99d9:  jmp     CHROUT
---------------------------------
L99dc:  !by     $09,$0b,$1b,$2b,$61,$7c,$98,$9d
        !by     $0c,$21,$4b,$64,$93,$93,$10,$10
        !by     $11,$13,$13,$14,$15,$15,$12,$1c
        !by     $1c,$53,$54,$61,$61,$9d,$9d,$14
        !by     $1b,$1b,$1b,$1b,$21,$21,$4b,$4b
        !by     $73,$82,$82,$83,$83,$95,$95,$99
        !by     $99,$99,$a0,$a0,$a4,$a6,$a6,$a6
L9a14:  !by     $06,$88,$60,$e4,$02,$82,$86,$02
        !by     $d8,$46,$86,$e4,$d8,$e4,$c6,$e6
        !by     $62,$52,$8a,$18,$86,$a6,$68,$30
        !by     $32,$60,$e4,$30,$32,$30,$32,$96
        !by     $06,$08,$12,$2c,$70,$72,$b0,$b2
        !by     $e0,$02,$20,$02,$20,$12,$26,$46
        !by     $48,$52,$70,$72,$f0,$02,$26,$42
L9a4c:  !by     $61,$21,$c1,$41,$a1,$01,$e1,$81
        !by     $02,$c2,$e2,$42,$22,$62,$90,$b0
        !by     $f0,$30,$d0,$10,$50,$70,$00,$1e
        !by     $28,$0a,$14,$32,$3c,$46,$50,$00
        !by     $18,$d8,$58,$b8,$ca,$88,$e8,$c8
        !by     $ea,$48,$08,$68,$28,$40,$60,$38
        !by     $f8,$78,$aa,$a8,$ba,$8a,$9a,$98
L9a84:  !by     $00,$24,$00,$2c,$00,$00,$00,$00
        !by     $00,$00,$00,$4c,$00,$4c,$00,$00
        !by     $00,$00,$6c,$00,$00,$20,$00,$20
        !by     $00,$00,$00,$00,$00,$00,$00,$e4
        !by     $e0,$ec,$00,$00,$00,$00,$00,$00
        !by     $00,$c4,$c0,$cc,$00,$00,$00,$00
        !by     $00,$00,$00,$a6,$a2,$ae,$00,$00
        !by     $be,$00,$00,$b6,$00,$a4,$a0,$ac
        !by     $00,$b4,$00,$bc,$00,$00,$00,$86
        !by     $00,$8e,$00,$00,$00,$00,$00,$96
        !by     $00,$84,$00,$8c,$00,$94,$00

L9adb:  !by     $53,$59,$4e,$54,$41,$58,$00     ; syntax.

L9ae2:  !by     $4f,$4e,$45,$20,$42,$59,$54,$45 ; one byte
        !by     $20,$52,$41,$4e,$47,$45,$00     ;  range.

L9af1:  !by     $52,$45,$4c,$41,$54,$49,$56,$20 ; relativ 
        !by     $42,$52,$41,$4e,$43,$48,$00     ; branch.

L9b00:  !by     $49,$4c,$4c,$45,$47,$41,$4c,$20 ; illegal 
        !by     $4f,$50,$45,$52,$41,$4e,$44,$00 ; operand.

L9b10:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$44,$49,$52,$45,$43,$54 ; e direct
        !by     $49,$56,$45,$00                 ; ive.

L9b24:  !by     $44,$55,$50,$4c,$49,$43,$41,$54 ; duplicat
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00                             ; .

L9b35:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00                             ; .

L9b46:  !by     $20,$45,$52,$52,$4f,$52,$00     ;  error.    
L9b4d:  !by     $45,$4e,$44                     ; end
L9b50:  !by     $54,$45,$58,$54                 ; text
L9b54:  !by     $57,$4f,$52,$54                 ; wort
L9b58:  !by     $44,$49,$53,$50                 ; disp
L9b5c:  !by     $42,$59,$54,$45                 ; byte
L9b60:  !by     $4c,$4f,$41,$44                 ; load
L9b64:  !by     $0d,$50,$52,$4f,$47,$52,$41,$4d ; .program
        !by     $4d,$4e,$41,$4d,$45,$20,$20,$3a ; mname  :
        !by     $20,$00                         ;  .
L9b76:  !by     $0d,$48,$45,$58,$41,$20         ; .hexa
        !by     $4b,$4f,$52,$52,$2d,$50,$4f,$4b ; korr-pok
        !by     $45,$3a,$20,$00                 ; e: .
L9b88:  !by     $0d,$41,$55,$53,$44,$52,$55,$43 ; .ausdruc
        !by     $4b,$2d,$43,$4f,$44,$45,$20,$3a ; k-code :
        !by     $20,$00                         ;  .
L9b9a:  !by     $5a,$45,$49,$4c,$45,$4e,$3a,$00 ; zeilen:.
L9ba2:  !by     $20,$20,$20,$53,$59,$4d,$42,$4f ;    symbo
        !by     $4c,$45,$3a,$00                 ; le:.
L9bae:  !by     $20,$20,$20,$46,$45,$48,$4c,$45 ;    fehle
        !by     $52,$3a,$00                     ; r:.
L9bb9:  !by     $53,$45,$49,$54,$45,$3a,$00     ; seite:.
ASS_END:

FILL3:  !fi     $9c00-FILL3, $aa

; - $9C00  basic command CHECK UNDEF'D ---------
UNDEF:  jmp     L9c34
; - $9C03  basic command COMPACTOR -------------
COMPACTOR:
        jsr     L9c15
        ldx     #$01
        stx     $0133
        stx     $0135
        dex
        stx     $0134
        jmp     L802d
---------------------------------
L9c15:  ldx     #$f0
        jsr     CHRGET
        beq     L9c29
        jsr     $b79e
        txa
        bne     L9c25
L9c22:  jmp     ERRFC                           ; llegal quantity error
---------------------------------
L9c25:  cpx     #$f1
        bcs     L9c22
L9c29:  stx     $fc
        jsr     L9c37
        jsr     L9c83
        jmp     $a533
---------------------------------
L9c34:  lda     #$01
        !by     $2c
L9c37:  lda     #$00
        sta     $0133
        jsr     L9c52
        lda     $0133
        bne     L9c45
        rts
---------------------------------
L9c45:  lda     #$00
        sta     $c6
        ldx     #$fa
        txs
        jsr     $a533
        jmp     READY                           ; go handle error message
---------------------------------
L9c52:  jsr     $a68e
L9c55:  jsr     L9d94
L9c58:  jsr     CHRGET
L9c5b:  tax
        beq     L9c55
        jsr     L9deb
        bcc     L9c5b
        jsr     L9daa
        bne     L9c58
L9c68:  jsr     CHRGET
        bcs     L9c5b
        jsr     $a96b
        jsr     L9e6a
        bcs     L9c7a
        ldx     #$5a
        jsr     L9dc3
L9c7a:  jsr     CHRGOT
        cmp     #$2c
        bne     L9c5b
        beq     L9c68
L9c83:  ldy     #$00
        sty     $0133
        sty     $0134
        sty     $0135
        jsr     $a68e
L9c91:  lda     $7a
        sta     $47
        lda     $7b
        sta     $48
        jsr     L9d94
        inc     $7a
        bne     L9ca2
        inc     $7b
L9ca2:  jsr     L9de2
        lda     $0133
        bne     L9cb1
L9caa:  lda     #$00
        sta     $0135
        beq     L9ce9
L9cb1:  ldy     #$ff
L9cb3:  iny
        lda     ($3d),y
        bne     L9cb3
        tya
        clc
        adc     $0135
        bcs     L9caa
        cmp     $fc
        bcs     L9caa
        ldy     #$02
        lda     ($47),y
        cmp     #$ff
        beq     L9caa
        ldy     #$00
        lda     $0134
        beq     L9cdc
        lda     #$22
        sta     ($47),y
        inc     $47
        bne     L9cdc
        inc     $48
L9cdc:  lda     #$3a
        sta     ($47),y
        inc     $47
        bne     L9ce6
        inc     $48
L9ce6:  jsr     L9e1f
L9ce9:  ldx     #$00
        stx     $0134
        inx
        stx     $0133
        inc     $0135
L9cf5:  ldy     #$00
L9cf7:  lda     ($7a),y
        bne     L9cfe
        jmp     L9c91
---------------------------------
L9cfe:  inc     $7a
        bne     L9d04
        inc     $7b
L9d04:  inc     $0135
        cmp     #$22
        bne     L9d23
L9d0b:  lda     ($7a),y
        bne     L9d14
        inc     $0134
        bne     L9cf7
L9d14:  inc     $7a
        bne     L9d1a
        inc     $7b
L9d1a:  inc     $0135
        cmp     #$22
        bne     L9d0b
        beq     L9cf7
L9d23:  cmp     #$8b
        bne     L9d2e
L9d27:  lda     #$00
        sta     $0133
        beq     L9cf7
L9d2e:  cmp     #$8d
        beq     L9cf7
        jsr     L9daa
        beq     L9d27
        cmp     #$20
        bne     L9d47
        jsr     L9e9e
L9d3e:  jsr     L9de2
        jsr     L9e1f
        jmp     L9cf5
---------------------------------
L9d47:  cmp     #$8f
        bne     L9d68
        jsr     L9e9e
        lda     #$3a
        sta     ($47),y
        inc     $47
        bne     L9d58
        inc     $48
L9d58:  lda     ($7a),y
L9d5a:  beq     L9cf7
L9d5c:  inc     $7a
        bne     L9d62
        inc     $7b
L9d62:  lda     ($7a),y
        bne     L9d5c
        beq     L9d3e
L9d68:  cmp     #$83
        bne     L9cf7
L9d6c:  lda     ($7a),y
L9d6e:  beq     L9cf7
        inc     $7a
        bne     L9d76
        inc     $7b
L9d76:  inc     $0135
        cmp     #$3a
        beq     L9d5a
        cmp     #$22
        bne     L9d6c
L9d81:  lda     ($7a),y
        beq     L9d6e
        inc     $7a
        bne     L9d8b
        inc     $7b
L9d8b:  inc     $0135
        cmp     #$22
        bne     L9d81
        beq     L9d6c
L9d94:  ldy     #$02
        lda     ($7a),y
        bne     L9d9d
        pla
        pla
        rts
---------------------------------
L9d9d:  iny
        lda     ($7a),y
        sta     $39
        iny
        lda     ($7a),y
        sta     $3a
        jmp     $a8fb
---------------------------------
L9daa:  cmp     #$cb
        bne     L9db4
        jsr     CHRGET
        cmp     #$a4
        rts
---------------------------------
L9db4:  cmp     #$a7
        beq     L9dc2
        cmp     #$89
        beq     L9dc2
        cmp     #$8d
        beq     L9dc2
        cmp     #$8a
L9dc2:  rts
---------------------------------
L9dc3:  lda     $a225,x                         ; verweisst auf "data" im ROM
        pha
        and     #$7f
        jsr     CHROUT
        inx
        pla
        bpl     L9dc3
        lda     #$6a
        ldy     #$a3
        jsr     $ab1e
        jsr     $bdc2
        lda     #$ff
        sta     $0133
        jmp     CRDO
---------------------------------
L9de2:  ldx     $7a
        stx     $3d
        ldx     $7b
        stx     $3e
        rts
---------------------------------
L9deb:  cmp     #$22
        bne     L9e07
        ldy     #$00
        inc     $7a
        bne     L9df7
        inc     $7b
L9df7:  lda     ($7a),y
        beq     L9e0e
        inc     $7a
        bne     L9e01
        inc     $7b
L9e01:  cmp     #$22
        bne     L9df7
        beq     L9e0e
L9e07:  cmp     #$8f
        bne     L9e13
        jsr     $a93b
L9e0e:  jsr     CHRGOT
        clc
        rts
---------------------------------
L9e13:  cmp     #$83
        bne     L9e1d
        jsr     $a8f8
        jmp     L9e0e
---------------------------------
L9e1d:  sec
        rts
---------------------------------
L9e1f:  lda     $47
        sta     $7a
        lda     $48
        sta     $7b
        lda     $3e
        sta     $23
        lda     $2d
        sta     $22
        lda     $48
        sta     $25
        lda     $47
        sec
        sbc     $3d
        clc
        adc     $2d
        sta     $2d
        sta     $24
        lda     $2e
        adc     #$ff
        sta     $2e
        sbc     $48
        tax
        lda     $47
        sec
        sbc     $2d
        tay
        bcs     L9e53
        inx
        dec     $25
L9e53:  clc
        adc     $22
        bcc     L9e5b
        dec     $23
        clc
L9e5b:  lda     ($22),y
        sta     ($24),y
        iny
        bne     L9e5b
        inc     $23
        inc     $25
        dex
        bne     L9e5b
        rts
---------------------------------
L9e6a:  lda     $2b
        ldx     $2c
L9e6e:  ldy     #$01
        sta     $5f
        stx     $60
        lda     ($5f),y
        beq     L9e9c
        ldy     #$03
        lda     $15
        cmp     ($5f),y
        bcc     L9e9d
        bne     L9e91
        dey
        lda     $14
        cmp     ($5f),y
        bcc     L9e9d
        bne     L9e91
        dey
        lda     #$ff
        sta     ($5f),y
        rts
---------------------------------
L9e91:  ldy     #$00
        lda     ($5f),y
        cmp     $5f
        bcs     L9e6e
        inx
        bcc     L9e6e
L9e9c:  clc
L9e9d:  rts
---------------------------------
L9e9e:  lda     $7b
        sta     $48
        ldx     $7a
        bne     L9ea8
        dec     $48
L9ea8:  dex
        stx     $47
        rts

FILL4:  !fi     $a000-FILL4, $aa

