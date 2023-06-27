; ###############################################################
; #                                                             #
; #  Print Technik Help Plus V2 source code                     #
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


!to"build/PTHP-V2.crt",plain
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
L80f2:  lda     SCNMSG,x                        ; load screen message char
        beq     L80fd                           ; branch if end
        jsr     CHROUT                          ; output char on screen
        inx                                     ; increase counter
        bne     L80f2                           ; go for next char
; patch basic warm start
L80fd:  lda     #$0e                            ; new BASIC warm start low byte
        ldx     #$81                            ; new BASIC warm start high byte
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
; - $8141  basic command GENLINE ---------------
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
        bcs     START
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
        ldx     #$0f
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
        !by     $2C
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
        jsr     L8c09
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
; - $8842 -- open file with cmd ile ------------
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
L88ea:  jsr     L8b0c
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
        jsr     L8b54
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
        jmp     L8b06
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
        jsr     L8aa4
        bcc     L89eb
        jmp     EREXIT
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
        bne     L8a88
L8a5e:  jsr     STOPT
        beq     L8a88
        lda     $028e
        cmp     #$01
        beq     L8a5e
        lda     $0135
        cmp     #$03
        bne     L8a83
        lda     $d6
        cmp     #$18
        bne     L8a83
        jsr     GETIN
        cmp     #$04
        bcc     L8a5e
        lda     #$93
        jsr     CHROUT
L8a83:  ldy     #$04
        jmp     L89f1
---------------------------------
L8a88:  lda     #$60
        sta     $b9
        lda     IONO
        sta     $ba
        jsr     $f642
        lda     $0135
        cmp     #$03
        beq     L8aa1
        ldx     $0134
        jsr     CHKOUT
L8aa1:  jmp     READY                           ; go handle error message
---------------------------------
L8aa4:  jsr     $f3d5
        rts
; ----------------------------------------------
; - $8ABE  set IO number -----------------------
; ----------------------------------------------
SETIONO:jsr     CHRGET                          ; get char
        bcs     L8ab9                           ; branch if not a number
        and     #$0f                            
        beq     SETIONO                         ; branch if zero
        tax                                     ; save to X
        jsr     CHRGET                          ; get next char
        beq     L8acc                           ; 
        bcc     L8abc
L8ab9:  jmp     SNERR                           ; syntax error
---------------------------------
L8abc:  pha
        jsr     CHRGET
        bne     L8ab9
        pla
        and     #$0f
        cpx     #$01
        bne     L8ab9
        adc     #$09
        tax
L8acc:  cpx     #$04
        bcc     L8ab9
        cpx     #$10
        bcs     L8ab9
        stx     IONO
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; -- $8AF0 read chanel 15 ">" ------------------
; ----------------------------------------------
RDCH15: ldy     #$01
        lda     ($7a),y
        bne     L8af7
        jsr     L89a0
        jsr     L8b47
        jsr     IECIN
        pha
        jsr     UNTALK
        pla
        jsr     HEXOUT
        jsr     CRDO
        jmp     READY                           ; go handle error message
-----------------------------------
L8af7:  jsr     L8995
        jsr     L8b54
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8B16 read disk channel --------------------
; ----------------------------------------------
RDDCH:  ldy     #$01
        lda     ($7a),y
        bne     L8af7
L8b06:  jsr     L8b0c
        jmp     READY                           ; go handle error message   
---------------------------------
L8b0c:  jsr     L89a0
        jsr     L8b47
        ldy     #$00
L8b14:  jsr     IECIN
        sta     $0100,y
        cmp     #$0d
        beq     L8b28
        iny
        lda     $90
        beq     L8b14
        lda     #$0d
        sta     $0100,y
L8b28:  jsr     UNTALK
        jsr     CRDO
        ldy     #$00
L8b30:  lda     $0100,y
        jsr     CHROUT
        iny
        cmp     #$0d
        bne     L8b30
        rts
---------------------------------
        jsr     L8b46
        jsr     CHROUT
        lda     #$6f
        sta     $b9
L8b46:  rts
---------------------------------
L8b47:  lda     $ba
        jsr     TALK
        lda     #$6f
        sta     $b9
        jmp     TKSA
---------------------------------
        rts
---------------------------------
L8b54:  lda     $ba
        jsr     LISTN
        lda     #$6f
        sta     $b9
        jmp     $f3ea
; ----------------------------------------------
; - $8B76  Monitor commands handling -----------
; ----------------------------------------------
MONI:   ldx     #$00
        stx     $0133
        stx     $0134
L8b68:  stx     $0135
L8b6b:  jsr     L8c91
; ----------------------------------------------
; ----- check monitor commands: ----------------
; ----------------------------------------------
        jsr     GETIN
        ldx     #$02
        cmp     #$2f                            ; "/" modify data
        beq     L8b68
        dex
        dex
        cmp     #$2b                            ; "+" modify address
        beq     L8b68
        cmp     #$5d                            ; "]" output to screen
        beq     L8b9d
        cmp     #$3e                            ; ">" computer memory
        beq     L8b8a
        dex
        cmp     #$3c                            ; "<" floppy memory
        bne     L8b90
L8b8a:  stx     $0133
        jsr     L8c86
L8b90:  cmp     #$2a                            ; "*" run
        bne     L8b99
        jsr     L8d05
        lda     #$00
L8b99:  cmp     #$5b                            ; "[" output to printer
        bne     L8ba2
L8b9d:  stx     $0134
        beq     L8b6b
L8ba2:  cmp     #$0d                            ; "RETURN" inc address
        bne     L8ba9
        jsr     L8c77
L8ba9:  cmp     #$5e                            ; "^" dec address"
        bne     L8bb8
        ldx     $fb
        bne     L8bb3
        dec     $fc
L8bb3:  dec     $fb
        jsr     L8c86
L8bb8:  cmp     #$20                            ; " " dissasemble continous
        bne     L8bbf
        jsr     L8d12
L8bbf:  cmp     #$2d                            ; "-" dissasemble 1 line
        bne     L8bc6
        jsr     L8d41
L8bc6:  cmp     #$40                            ; "@" transfer
        bne     L8bcf
        jsr     L8c09
        lda     #$00
L8bcf:  cmp     #$3d                            ; "=" exit monitor
        bne     L8bd6
        jmp     READY                           ; go handle error message
---------------------------------
L8bd6:  jsr     $007c
        jsr     L88ad
        bcs     L8c06
        ldx     $0135
L8be1:  rol
        rol     $fb,x
        rol     $fc,x
        dey
        bne     L8be1
        txa
        beq     L8bf6
        ldx     $0133
        beq     L8c02
        ldx     #$57
        jsr     L8cb3
L8bf6:  ldx     $0133
        beq     L8c06
        ldx     #$52
        jsr     L8cb3
        beq     L8c06
L8c02:  lda     $fd
        sta     ($fb),y
L8c06:  jmp     L8b6b
---------------------------------
L8c09:  ldx     $fb
        stx     $26
        lda     $fc
        sta     $27
        cmp     $23
        bne     L8c17
        cpx     $22
L8c17:  bcc     L8c57
        beq     L8c57
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
L8c31:  lda     $24
        bne     L8c37
        dec     $25
L8c37:  dec     $24
        lda     $26
        bne     L8c3f
        dec     $27
L8c3f:  dec     $26
        lda     $25
        cmp     $23
        bne     L8c4b
        lda     $24
        cmp     $22
L8c4b:  bcc     L8c56
        ldy     #$00
        lda     ($24),y
        sta     ($26),y
        tya
        beq     L8c31
L8c56:  rts
---------------------------------
L8c57:  lda     $23
        cmp     $25
        bne     L8c61
        lda     $22
        cmp     $24
L8c61:  bcs     L8c56
        ldy     #$00
        lda     ($22),y
        sta     ($26),y
        inc     $22
        bne     L8c6f
        inc     $23
L8c6f:  inc     $26
        bne     L8c57
        inc     $27
        bne     L8c57
L8c77:  jsr     CRDO
L8c7a:  inc     $fb
        bne     L8c80
        inc     $fc
L8c80:  ldy     #$00
        lda     ($fb),y
        sta     $fd
L8c86:  lda     $0133
        beq     L8c90
        ldx     #$52
        jsr     L8cb3
L8c90:  rts
---------------------------------
L8c91:  ldy     #$00
        sty     $d3
        ldx     $0133
        bne     L8c9e
        lda     ($fb),y
        sta     $fd
L8c9e:  lda     $fc
        jsr     HEXOUT
        lda     $fb
        jsr     HEXOUT
        jsr     L88a5
        lda     $fd
        jsr     HEXOUT
        jmp     L88a8
---------------------------------
L8cb3:  lda     IONO
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
        bne     L8ce8
        lda     #$01
        jsr     CIOUT
        lda     $fd
        jsr     CIOUT
L8ce8:  jsr     UNLSN
        cpx     #$52
        bne     L8d02
        lda     IONO
        jsr     TALK
        lda     $b9
        jsr     TKSA
        jsr     IECIN
        sta     $fd
        jsr     UNTALK
L8d02:  lda     #$00
        rts
---------------------------------
L8d05:  ldx     $0133
        beq     L8d0f
        ldx     #$45
        jmp     L8cb3
-----------------------------------
L8d0f:  jmp     ($00fb)
-----------------------------------
L8d12:  jsr     STOPT
        bne     L8d18
        rts
---------------------------------
L8d18:  lda     $028e
        cmp     #$01
        beq     L8d12
        jsr     L8d41
        jmp     L8d12
---------------------------------
L8d25:  jsr     CLRCHN
        jsr     L8c7a
L8d2b:  bit     $0134
        bpl     L8d40
        lda     #$04
        sta     $9a
        sta     $ba
        jsr     LISTN
        lda     #$ff
        sta     $b9
        jmp     $edbe
---------------------------------
L8d40:  rts
---------------------------------
L8d41:  jsr     L8d2b
        jsr     L8c91
        lda     $fd
        tay
        lsr
        bcc     L8d58
        lsr
        bcs     L8d67
        cmp     #$22
        beq     L8d67
        and     #$07
        ora     #$80
L8d58:  lsr
        tax
        lda     L8e46,x
        bcs     L8d63
        lsr
        lsr
        lsr
        lsr
L8d63:  and     #$0f
        bne     L8d6b
L8d67:  lda     #$00
        ldy     #$80
L8d6b:  tax
        lda     L8e8a,x
        sta     $0113
        and     #$03
        sta     $0112
        tya
        and     #$8f
        tax
        tya
        ldy     #$03
        cpx     #$8a
        beq     L8d8d
L8d82:  lsr
        bcc     L8d8d
        lsr
L8d86:  lsr
        ora     #$20
        dey
        bne     L8d86
        iny
L8d8d:  tax
        dey
        bne     L8d82
        lda     L8ea4,x
        sta     $0110
        lda     L8ee4,x
        sta     $0111
        ldx     #$00
L8d9f:  stx     $0114
        cpx     $0112
        bcc     L8dac
        jsr     L88a5
        bne     L8db9
L8dac:  jsr     L8d25
        lda     $fd
        ldx     $0114
        sta     $fe,x
        jsr     HEXOUT
L8db9:  jsr     L88a8
        ldx     $0114
        inx
        cpx     #$03
        bne     L8d9f
L8dc4:  lda     #$00
        ldy     #$05
L8dc8:  asl     $0111
        rol     $0110
        rol
        dey
        bne     L8dc8
        ora     #$40
        cmp     #$40
        bne     L8dda
        lda     #$2a
L8dda:  jsr     CHROUT
        dex
        bne     L8dc4
        jsr     L88a5
        ldx     #$06
L8de5:  cpx     #$04
        bne     L8e0c
        lda     $0111
        bne     L8df1
        jsr     L88a8
L8df1:  ldy     $0112
        beq     L8e0c
        lda     $0113
        cmp     #$84
        bcs     L8e2e
L8dfd:  lda     $00fd,y
        stx     $0114
        jsr     HEXOUT
        ldx     $0114
        dey
        bne     L8dfd
L8e0c:  asl     $0113
        bcc     L8e22
        inc     $0111
        lda     L8e97,x
        jsr     CHROUT
        lda     L8e9d,x
        beq     L8e22
        jsr     CHROUT
L8e22:  dex
        bne     L8de5
L8e25:  jsr     CRDO
        jsr     L8d25
        jmp     CLRCHN
---------------------------------
L8e2e:  ldx     $fc
        lda     $fe
        bpl     L8e35
        dex
L8e35:  adc     $fb
        bcc     L8e3a
        inx
L8e3a:  tay
        txa
        jsr     HEXOUT
        tya
        jsr     HEXOUT
        jmp     L8e25
---------------------------------
L8e46:  !by     $40,$02,$45,$03,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $30,$22,$45,$33,$d0,$08,$40,$09 ; 0"e3P.@.
        !by     $40,$02,$45,$33,$d0,$08,$40,$09 ; @.e3P.@.
        !by     $40,$02,$45,$b3,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $00,$22,$44,$33,$d0,$8c,$44,$00 ; ."d3P.d.
        !by     $11,$22,$44,$33,$d0,$8c,$44,$9a ; ."d3P.d.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $62,$13,$78,$a9 
L8e8a:  !by     $00,$41,$01,$02,$00,$20,$99,$8d
        !by     $11,$12,$06,$8a,$05
L8e97:  !by     $21,$2c,$29,$2c,$41,$23
L8e9d:  !by     $28,$59,$00,$58,$00,$00,$00 
L8ea4:  !by     $14,$82,$14,$1b,$54,$83,$13,$99
        !by     $95,$82,$15,$1b,$95,$83,$15,$99
        !by     $00,$21,$10,$a6,$61,$a0,$10,$1b
        !by     $1c,$4b,$13,$1b,$1c,$4b,$11,$99
        !by     $00,$12,$53,$53,$9d,$61,$1c,$1c
        !by     $a6,$a6,$a0,$a4,$21,$00,$73,$00
        !by     $0c,$93,$64,$93,$9d,$61,$21,$4b
        !by     $7c,$0b,$2b,$09,$9d,$61,$1b,$98

L8ee4:  !by     $96,$20,$18,$06,$e4,$20,$52,$46
        !by     $12,$02,$86,$12,$26,$02,$a6,$52
        !by     $00,$72,$c6,$42,$32,$72,$e6,$2c
        !by     $32,$b2,$8a,$08,$30,$b0,$62,$48
        !by     $00,$68,$60,$60,$32,$32,$32,$30
        !by     $02,$26,$70,$f0,$70,$00,$e0,$00
        !by     $d8,$d8,$e4,$e4,$30,$30,$46,$86
        !by     $82,$88,$e4,$06,$02,$02,$60,$86 

; - $8F24  module information message ---------- 
SCNMSG: !by     $0d,$0d,$2a,$2a,$2a,$20,$20,$48 ; ..***  h
        !by     $45,$4c,$50,$20,$20,$43,$2d,$36 ; elp  c-6
        !by     $34,$20,$20,$50,$4c,$55,$53,$20 ; 4  plus 
        !by     $20,$2a,$2a,$2a,$0d,$00         ;  ***..
; - $8F42  overwrite message text --------------
OVWTXT: !by     $0d,$4f,$56,$45,$52,$57,$52,$49 ; .overwri
        !by     $54,$45,$3f,$20,$12,$4a,$92,$41 ; te? .j.a
        !by     $2f,$12,$4e,$92,$45,$49,$4e,$0d ; /.n.ein.
        !by     $00
; - $8F5B  DOS and monitor commands char -------
DMCHAR: !by     $3e,$40,$3c,$2f,$5e,$24,$5d,$23 ; >@</^$]#
        !by     $21,$5f,$2a,$2b,$2d,$28,$29,$25 ; !_*+-()%
        !by     $5c,$5b                         ; £[
; - $8F6D  commands low byte -------------------
DMLBYT: !by     <RDCH15,<RDDCH,<VERIFY,<LDREL,<LDRUN,<LDDIR,<MONI,<BASCMD
        !by     <CONVERT,<SAVEPRG,<PRTFRE,<UPCASE,<LOWCASE,<OPNFILE,<CLFILE,<LDABS
        !by     <SETIONO,<ASSEMBLER
; - $8f7F  commands high byte ------------------
DMHBYT: !by     >RDCH15,>RDDCH,>VERIFY,>LDREL,>LDRUN,>LDDIR,>MONI,>BASCMD
        !by     >CONVERT,>SAVEPRG,>PRTFRE,>UPCASE,>LOWCASE,>OPNFILE,>CLFILE,>LDABS
        !by     >SETIONO,>ASSEMBLER

; - #8F91  basic commands char -----------------
BCCHAR: !by     $41,$44,$45,$46,$47,$48,$4b,$4c ; adefghkl
        !by     $4d,$52,$53,$54,$56,$55,$43,$42 ; mrstvucb
; - #8FA1  basic commands low byte -------------
BCLBYT: !by     <APPEND,<DELETE,<ENDTRACE,<FIND,<GENLINE,<HELP,<KILL,<LPAGE
        !by     <M_DUMP,<RENUMBER,<S_STEP,<TRACE,<V_DUMP,<UNDEF,<COMPACTOR,<RENEW
; - $8FB1  basic commands high byte ------------
BCHBYT: !by     >APPEND,>DELETE,>ENDTRACE,>FIND,>GENLINE,>HELP,>KILL,>LPAGE
        !by     >M_DUMP,>RENUMBER,>S_STEP,>TRACE,>V_DUMP,>UNDEF,>COMPACTOR,>RENEW

FILL2   !fi     $9000-FILL2, $aa

; ----------------------------------------------
; - $9000 - Start of assembler -----------------
; ----------------------------------------------
ASSEMBLER:
        lda     $2b
        sta     $2d
        lda     $2c
        sta     $2e
        lda     #<L9b8e
        ldy     #>L9b8e
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
-----------------------------------
L902c:  lda     #<L9ba0
        ldy     #>L9ba0
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
L9058:  lda     #<L9bb2
        ldy     #>L9bb2
        jsr     $ab1e
        ldx     #$00
        stx     $57
        stx     $58
        stx     $59
        stx     $5a
L9069:  jsr     CHRIN
        cmp     #$0d
        beq     L907b
        cpx     #$03
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
        jsr     L9988
        lda     $ba
        jsr     TALK
        lda     #$60
        jsr     TKSA
        jsr     IECIN
        jsr     IECIN
        jsr     UNTALK
        ldx     $3f
        bne     L90c8
        jsr     L9325
L90c8:  jsr     L987c
        jsr     L9366
        lda     $2a
        beq     L90d9
        lda     $58
        beq     L90d9
        jsr     L927d
L90d9:  lda     $4d
        bmi     L90e6
        clc
        adc     $7a
        sta     $7a
        bcc     L90e6
        inc     $7b
L90e6:  inc     $31
        bne     L90ec
        inc     $32
L90ec:  lda     $29
        beq     L90c8
        lda     IONO
        sta     $ba
        jsr     $f648
        ldx     $2a
        bne     L90ff
        inx
        bne     L908a
L90ff:  jsr     L92fc
L9102:  lda     #<L9bc4
        ldy     #>L9bc4
        jsr     $ab1e
        lda     $32
        ldx     $31
        jsr     INTOUT
        lda     #<L9bcc
        ldy     #>L9bcc
        jsr     $ab1e
        lda     $30
        ldx     $2f
        jsr     INTOUT
        lda     #<L9bd8
        ldy     #>L9bd8
        jsr     $ab1e
        lda     #$00
        ldx     $40
        jsr     INTOUT
        jsr     L92ff
        bcs     L9102
        jsr     L92fc
        lda     $59
        beq     L916c
        jsr     L91f0
        ldy     #$05
        lda     #$00
L913f:  sta     $0110,y
        dey
        bpl     L913f
L9145:  ldy     #$05
        lda     #$ff
L9149:  sta     $0100,y
        dey
        bpl     L9149
        ldx     $2b
        lda     $2c
L9153:  stx     $22
        sta     $23
        cmp     $2e
        bne     L915d
        cpx     $2d
L915d:  bcc     L9175
        lda     $0100
        bpl     L916f
        jsr     L91de
L9167:  jsr     L92ff
        bcs     L9167
L916c:  jmp     READY                           ; go handle error message
-----------------------------------
L916f:  jsr     L91ae
        jmp     L9145
-----------------------------------
L9175:  ldy     #$00
L9177:  lda     ($22),y
        cmp     $0110,y
        bne     L9185
        iny
        cpy     #$06
        bne     L9177
        beq     L91a1
L9185:  bcc     L91a1
        ldy     #$00
L9189:  lda     ($22),y
        cmp     $0100,y
        bne     L9195
        iny
        cpy     #$06
        bne     L9189
L9195:  bcs     L91a1
        ldy     #$07
L9199:  lda     ($22),y
        sta     $0100,y
        dey
        bpl     L9199
L91a1:  lda     $22
        clc
        adc     #$08
        tax
        lda     $23
        adc     #$00
        jmp     L9153
-----------------------------------
L91ae:  ldx     $28
        ldy     #$00
L91b2:  lda     $0100,y
        sta     $0110,y
        sta     $0200,x
        inx
        iny
        cpy     #$06
        bne     L91b2
        lda     #$3d
        sta     $0200,x
        inx
        lda     $0106
        jsr     L91fe
        lda     $0107
        jsr     L91fe
        inx
        inx
        cpx     #$27
        bne     L91da
        inx
L91da:  cpx     #$48
        bcc     L91fb
L91de:  ldx     #$00
L91e0:  lda     $0200,x
        jsr     CHROUT
        inx
        cpx     #$4f
        bne     L91e0
        jsr     L92ff
        bcs     L91de
L91f0:  lda     #$20
        ldx     #$4f
L91f4:  sta     $0200,x
        dex
        bpl     L91f4
        inx
L91fb:  stx     $28
        rts
-----------------------------------
L91fe:  pha
        lsr
        lsr
        lsr
        lsr
        jsr     L9209
        pla
        and     #$0f
L9209   ora     #$30
        cmp     #$3a
        bcc     L9211
        adc     #$06
L9211:  sta     $0200,x
        inx
        rts
-----------------------------------
L9216:  ldy     $46
        inc     $46
        lda     $0140,y
        bne     L9224
L921f:  lda     #$00
        sty     $46
        rts
-----------------------------------
L9224:  cmp     #$3b
        beq     L921f
        rts
-----------------------------------
L9229:  ldy     $46
        inc     $46
        lda     $0140,y
        beq     L921f
        rts
-----------------------------------
L9233:  cpx     #$01
        bne     L9240
L9237:  lda     $63
        ldy     $62
L923b:  sta     $69
        sty     $68
        rts
-----------------------------------
L9240:  cpx     #$2a
        bne     L924b
        lda     $7a
        ldy     $7b
        jmp     L923b
-----------------------------------
L924b:  cpx     #$03
        beq     L9252
        jmp     L94d2
-----------------------------------
L9252:  lda     $49
        and     $48
        sta     $49
        lda     $48
        bne     L9267
        lda     $2a
        beq     L9237
        ldy     #>L9b5f
        lda     #<L9b5f
        jmp     L94e1
-----------------------------------
L9267:  ldy     #$06
        lda     ($22),y
        sta     $68
        iny
        lda     ($22),y
        sta     $69
L9272:  rts
-----------------------------------
L9273:  lda     $0139,y
        cmp     #$20
        bne     L9272
        iny
        bne     L9273
L927d:  ldy     $7a
        lda     $7b
        ldx     $4d
        bpl     L928d
        ldx     #$00
        stx     $4d
        ldy     $67
        lda     $66
L928d:  sty     $fb
        sta     $fc
L9291:  jsr     L99e9
        jsr     L99e4
        ldy     #$00
L9299:  cpy     $4d
        bcs     L92a6
        lda     $004e,y
        jsr     L99f0
        jmp     L92a9
-----------------------------------
L92a6:  jsr     L99e1
L92a9:  jsr     L99e4
        iny
        cpy     #$03
        bcc     L9299
        ldy     #$00
L92b3:  lda     $0139,y
        jsr     CHROUT
        iny
        cpy     #$07
        bne     L92b3
        ldx     $27
        beq     L92db
        jsr     L9273
        ldx     #$00
L92c7:  lda     $0139,y
        cmp     #$20
        beq     L92db
        cmp     #$3d
        beq     L92db
        jsr     CHROUT
        iny
        inx
        cpx     #$06
        bne     L92c7
L92db:  lda     #$20
        jsr     CHROUT
        inx
        cpx     #$07
        bne     L92db
        jsr     L9273
L92e8:  lda     $0139,y
        beq     L92f3
        jsr     CHROUT
        iny
        bne     L92e8
L92f3:  jsr     L92ff
        bcs     L92f9
        rts
-----------------------------------
L92f9:  jmp     L9291
-----------------------------------
L92fc:  jsr     L92ff
L92ff:  jsr     CRDO
L9302:  lda     #$04
        cmp     $9a
        beq     L9318
        sta     $9a
        sta     $ba
        jsr     LISTN
        lda     #$ff
        sta     $b9
        jsr     $edbe
        sec
        rts
-----------------------------------
L9318:  ldx     #$03
        stx     $9a
        jsr     UNLSN
        dec     $3d
        beq     L9325
        clc
        rts
-----------------------------------
L9325:  jsr     L9302
        ldx     $3f
L932a:  jsr     CRDO
        dex
        bpl     L932a
        ldx     #$05
        stx     $3f
        ldx     #$41
        stx     $3d
        inc     $3e
        ldx     #$00
L933c:  lda     $0120,x
L933f:  jsr     CHROUT
        inx
        cpx     $b7
        bcc     L933c
        lda     #$20
        cpx     #$3c
        bcc     L933f
        lda     #<L9be3
        ldy     #>L9be3
        jsr     $ab1e
        lda     #$00
        sta     $68
        ldx     $3e
        jsr     INTOUT
        jsr     CRDO
        jsr     CRDO
        jmp     L9318
-----------------------------------
L9366:  ldy     #$00
        sty     $27
        sty     $46
        sty     $4d
        jsr     L9523
        txa
        beq     L93c6
        cpx     #$03
        bne     L93d2
        inc     $27
        ldy     $2a
        bne     L9399
        inc     $2f
        bne     L9384
        inc     $30
L9384:  ldy     #$05
L9386:  lda     $0110,y
        sta     ($2d),y
        dey
        bpl     L9386
        lda     $48
        beq     L9399
        ldy     #>L9b4e
        lda     #<L9b4e
        jsr     L94e1
L9399:  jsr     L9523
        cpx     #$3d
        bne     L93c7
        lda     #$ff
        sta     $4d
        jsr     L9679
        lda     $6b
        ldx     $6a
L93ab:  sta     $67
        stx     $66
        ldy     $2a
        bne     L93c6
        ldy     #$07
        sta     ($2d),y
        txa
        dey
        sta     ($2d),y
        lda     $2d
        clc
        adc     #$08
        sta     $2d
        bcc     L93c6
        inc     $2e
L93c6:  rts
-----------------------------------
L93c7:  stx     $28
        lda     $7a
        ldx     $7b
        jsr     L93ab
        ldx     $28
L93d2:  cpx     #$02
        bne     L93d9
        jmp     L96f2
-----------------------------------
L93d9:  cpx     #$2a
        bne     L93f3
        jsr     L9523
        cpx     #$3d
        beq     L93e7
L93e4:  jmp     L94d2
-----------------------------------
L93e7:  jsr     L9679
        lda     $6b
        sta     $7a
        lda     $6a
        sta     $7b
        rts
-----------------------------------
L93f3:  cpx     #$2e
        bne     L93e4
        ldy     $46
        ldx     #$00
L93fb:  lda     L9b77,x
        cmp     $0140,y
        bne     L940c
        iny
        inx
        cpx     #$03
        bne     L93fb
        inc     $29
        rts
-----------------------------------
L940c:  lda     L9b7a,x
        cmp     $0140,y
        bne     L9445
        iny
        inx
        cpx     #$04
        bne     L940c
        lda     #$ff
L941c:  sta     $28
        sty     $46
L9420:  jsr     L9216
        bne     L9428
L9425:  jmp     L94d2
-----------------------------------
L9428:  cmp     #$27
        beq     L9430
        cmp     #$22
        bne     L9420
L9430:  sta     $07
L9432:  jsr     L9229
        beq     L9425
        cmp     $07
        beq     L9442
        and     $28
        jsr     L94b8
        bne     L9432
L9442:  jmp     L94cb
-----------------------------------
L9445:  lda     L9b82,x
        cmp     $0140,y
        bne     L9457
        iny
        inx
        cpx     #$04
        bne     L9445
        lda     #$3f
        bne     L941c
L9457:  lda     L9b7e,x
        cmp     $0140,y
        bne     L9469
L945f:  iny
        inx
        cpx     #$04
        bne     L9457
        lda     #$00
        beq     L9481
L9469:  cpx     #$03
        bne     L9471
        cmp     #$44
        beq     L945f
L9471:  lda     L9b86,x
        cmp     $0140,y
        bne     L949a
        iny
        inx
        cpx     #$04
        bne     L9471
        lda     #$ff
L9481:  sta     $28
        sty     $46
L9485:  jsr     L9679
        lda     $6b
        jsr     L94b8
        bit     $28
        bpl     L94ab
        jsr     L94d8
L9494:  cpx     #$2c
        beq     L9485
        bne     L94cb
L949a:  lda     L9b8a,x
        cmp     $0140,y
        bne     L94b2
        iny
        inx
        cpx     #$04
        bne     L949a
        jmp     L9956
-----------------------------------
L94ab:  lda     $6a
        jsr     L94b8
        bne     L9494
L94b2:  lda     #<L9b3a
        ldy     #>L9b3a
        bne     L94e1
L94b8:  pha
        jsr     L986e
        pla
        ldy     $4d
        sta     ($41),y
        cpy     #$03
        bcs     L94c8
        sta     $004e,y
L94c8:  inc     $4d
        rts
-----------------------------------
L94cb:  jsr     L9523
        txa
        bne     L94d2
        rts
-----------------------------------
L94d2:  lda     #<L9b05
        ldy     #>L9b05
        bne     L94e1
L94d8:  lda     $6a
        bne     L94dd
        rts
-----------------------------------
L94dd:  lda     #<L9b0c
        ldy     #>L9b0c
L94e1:  sty     $63
        sta     $62
        stx     $28
        cmp     #$4e
        beq     L94ef
        lda     $2a
        beq     L9520
L94ef:  inc     $40
        lda     $57
        beq     L9520
L94f5:  ldy     #$00
L94f7:  lda     $0139,y
        jsr     CHROUT
        iny
        cpy     #$07
        bne     L94f7
        ldy     #$00
L9504:  lda     ($62),y
        beq     L950e
        jsr     CHROUT
        iny
        bne     L9504
L950e:  ldy     #$00
L9510:  lda     L9b70,y
        beq     L951b
        jsr     CHROUT
        iny
        bne     L9510
L951b:  jsr     L92ff
        bcs     L94f5
L9520:  ldx     $28
        rts
-----------------------------------
L9523:  ldx     #$00
        stx     $62
        stx     $63
        jsr     L9216
        bne     L952f
        rts
-----------------------------------
L952f:  cmp     #$20
        beq     L9523
        inx
        cmp     #$27
        bne     L953e
L9538:  jsr     L9229
        sta     $63
        rts
-----------------------------------
L953e:  cmp     #$22
        beq     L9538
        cmp     #$24
        bne     L9570
L9546:  jsr     L9216
        beq     L956f
        cmp     #$30
        bcc     L956d
        cmp     #$3a
        bcc     L955d
        cmp     #$41
        bcc     L956d
        cmp     #$47
        bcs     L956d
        sbc     #$06
L955d:  asl
        asl
        asl
        asl
        ldy     #$04
L9563:  asl
        rol     $63
        rol     $62
        dey
        bne     L9563
        beq     L9546
L956d:  dec     $46
L956f:  rts
-----------------------------------
L9570:  cmp     #$40
        bne     L9592
L9574:  jsr     L9216
        beq     L956f
        cmp     #$30
        bcc     L956d
        cmp     #$38
        bcs     L956d
        asl
        asl
        asl
        asl
        asl
        ldy     #$03
L9588:  asl
        rol     $63
        rol     $62
        dey
        bne     L9588
        beq     L9574
L9592:  cmp     #$25
        bne     L95ab
L9596:  jsr     L9216
        beq     L956f
        cmp     #$30
        beq     L95a3
        cmp     #$31
        bne     L956d
L95a3:  lsr
        rol     $63
        rol     $62
        jmp     L9596
-----------------------------------
L95ab:  cmp     #$30
        bcc     L95ed
        cmp     #$3a
        bcs     L95ed
        bcc     L95c2
L95b5:  jsr     L9216
        beq     L956f
        cmp     #$30
        bcc     L956d
        cmp     #$3a
        bcs     L956d
L95c2:  and     #$0f
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
        jmp     L95b5
-----------------------------------
L95ed:  tax
        cmp     #$41
        bcs     L95f3
L95f2:  rts
-----------------------------------
L95f3:  cmp     #$5b
        bcs     L95f2
        ldy     #$04
        lda     #$20
L95fb:  sta     $0111,y
        dey
        bpl     L95fb
        stx     $0110
        ldx     #$01
L9606:  jsr     L9216
        beq     L9627
        cmp     #$30
        bcc     L9625
        cmp     #$3a
        bcc     L961b
        cmp     #$41
        bcc     L9625
        cmp     #$5b
        bcs     L9625
L961b:  sta     $0110,x
        inx
        cpx     #$06
        bcc     L9606
        bcs     L9627
L9625:  dec     $46
L9627:  dex
        bne     L9639
        ldx     $0110
        cpx     #$41
        beq     L95f2
        cpx     #$59
        beq     L95f2
        cpx     #$58
        beq     L95f2
L9639:  cpx     #$02
        bne     L9647
        jsr     L998c
        beq     L9647
        ldx     #$02
        sta     $47
        rts
-----------------------------------
L9647:  ldx     #$03
        ldy     #$00
        sty     $48
        ldy     $2b
        lda     $2c
L9651:  sty     $22
        sta     $23
        cmp     $2e
        bne     L965b
        cpy     $2d
L965b:  bcc     L965e
        rts
-----------------------------------
L965e:  ldy     #$05
L9660:  lda     $0110,y
        cmp     ($22),y
        bne     L966d
        dey
        bpl     L9660
        inc     $48
        rts
-----------------------------------
L966d:  lda     $22
        clc
        adc     #$08
        tay
        lda     $23
        adc     #$00
        bne     L9651
L9679:  jsr     L9523
        txa
        bne     L9680
        rts
-----------------------------------
L9680:  lda     #$01
        sta     $49
        jsr     L9233
        lda     $69
        ldy     $68
        sta     $6b
        sty     $6a
        jmp     L96b5
-----------------------------------
L9692:  lda     $4a
        cmp     #$2b
        bne     L96a8
        lda     $6b
        clc
        adc     $69
        sta     $6b
        lda     $6a
        adc     $68
        sta     $6a
        jmp     L96b5
-----------------------------------
L96a8:  lda     $6b
        sec
        sbc     $69
        sta     $6b
        lda     $6a
        sbc     $68
        sta     $6a
L96b5:  jsr     L9523
        beq     L96cd
        stx     $4a
        cpx     #$2b
        beq     L96c4
        cpx     #$2d
        bne     L96cd
L96c4:  jsr     L9523
        jsr     L9233
        jmp     L9692
-----------------------------------
L96cd:  ldy     $49
        bne     L96d6
        sty     $6b
        iny
        sty     $6a
L96d6:  cpx     #$5b
        beq     L96de
        cpx     #$3e
        bne     L96e9
L96de:  ldy     $6a
        sty     $6b
L96e2:  ldy     #$00
        sty     $6a
        jmp     L9523
-----------------------------------
L96e9:  cpx     #$5d
        beq     L96e2
        cpx     #$3c
        beq     L96e2
        rts
-----------------------------------
L96f2:  ldx     #$01
        stx     $4d
        ldy     $47
        cpy     #$05
        beq     L9719
        jsr     L9523
        cpx     #$41
        bne     L9709
        lda     #$0a
        sta     $4c
        bne     L9719
L9709:  inc     $4d
        cpx     #$23
        bne     L971c
        lda     #$02
        sta     $4c
        jsr     L9679
        jsr     L94d8
L9719:  jmp     L9794
-----------------------------------
L971c:  cpx     #$28
        bne     L9762
        jsr     L9679
        cpx     #$2c
        bne     L9741
        lda     #$00
        sta     $4c
        jsr     L94d8
        jsr     L9523
        cpx     #$58
        beq     L9738
L9735:  jmp     L97c2
-----------------------------------
L9738:  jsr     L9523
        cpx     #$29
        bne     L9735
        beq     L9794
L9741:  lda     #$04
        sta     $4c
        cpx     #$29
        bne     L9735
        jsr     L9523
        txa
        bne     L9755
        lda     #$08
        sta     $4c
        bne     L9794
L9755:  cpx     #$2c
        bne     L9735
        jsr     L9523
        cpx     #$59
        bne     L9735
        beq     L9794
L9762:  lda     #$01
        sta     $4c
        jsr     L9680
        cpx     #$2c
        bne     L9780
        jsr     L9523
        lda     #$05
        sta     $4c
        cpx     #$58
        beq     L9780
        cpx     #$59
        bne     L9735
        lda     #$09
        sta     $4c
L9780:  lda     $6a
        beq     L9794
        inc     $4c
        inc     $4c
        inc     $4d
        lda     $4c
        cmp     #$09
        bcc     L9794
        lda     #$06
        sta     $4c
L9794:  jsr     L94cb
        lda     $6b
        sta     $4f
        lda     $6a
        sta     $50
        ldx     $47
        dex
        bne     L97d4
        lda     $4c
        cmp     #$09
        bne     L97b2
        lda     #$06
        sta     $4c
        lda     #$03
        sta     $4d
L97b2:  lda     $4c
        cmp     #$08
        bcs     L97c2
        cmp     #$02
        bne     L97c9
        lda     $4b
        cmp     #$81
        bne     L97c9
L97c2:  lda     #<L9b2a
        ldy     #>L9b2a
        jmp     L94e1
-----------------------------------
L97c9:  lda     $4c
        asl
        asl
        adc     $4b
        sta     $4b
        jmp     L9839
-----------------------------------
L97d4:  dex
        bne     L97f2
        lda     $4c
        cmp     #$09
        bcs     L97e2
        lsr
        bcs     L97c9
        bcc     L97c2
L97e2:  cmp     #$0a
        bne     L97c2
        lda     $4b
        cmp     #$63
        bcs     L97c2
        adc     #$08
        sta     $4b
        bne     L9839
L97f2:  dex
        bne     L983c
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
        bmi     L982d
        bne     L981b
        lda     $69
        bpl     L9835
L981b:  lda     #$00
        sta     $69
        lda     $2a
        beq     L9835
        lda     #<L9b1b
        ldy     #>L9b1b
        jsr     L94e1
        jmp     L9835
-----------------------------------
L982d:  cmp     #$ff
        bne     L981b
        lda     $69
        bpl     L981b
L9835:  lda     $69
        sta     $4f
L9839:  jmp     L985b
-----------------------------------
L983c:  dex
        bne     L985b
        lda     $4b
        cmp     #$14
        beq     L9849
        cmp     #$0a
        bne     L984d
L9849:  ldy     #$03
        sty     $4d
L984d:  clc
        adc     $4c
        tay
        lda     $9aae,y
        bne     L9859
        jmp     L97c2
-----------------------------------
L9859:  sta     $4b
L985b:  lda     $4b
        sta     $4e
        jsr     L986e
        ldy     $4d
        dey
L9865:  lda     $004e,y
        sta     ($41),y
        dey
        bpl     L9865
        rts
-----------------------------------
L986e:  lda     $7a
        sec
        sbc     $43
        sta     $41
        lda     $7b
        sbc     $44
        sta     $42
        rts
-----------------------------------
L987c:  ldy     #$00
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
        beq     L98a4
        lda     #$ff
        ldx     #$ff
L98a4:  sta     $62
        stx     $63
        ldx     #$90
        sec
        jsr     ADD
        jsr     FLPSTR
        ldy     #$05
        ldx     #$ff
L98b5:  inx
        lda     $0100,x
        bne     L98b5
L98bb:  dex
        bmi     L98c1
        lda     $0100,x
L98c1:  sta     $0200,y
        dey
        bpl     L98bb
        ldy     #$06
        sta     $0200,y
        iny
        ldx     $90
        bne     L98e1
L98d1:  jsr     IECIN
        ldx     $90
        bne     L98e1
        tax
        beq     L98ef
        sta     $0200,y
        iny
        bne     L98d1
L98e1:  lda     #$2e
        sta     $0200,y
        iny
        lda     #$80
        sta     $0200,y
        iny
        lda     #$00
L98ef:  sta     $0200,y
        jsr     UNTALK
        ldy     #$00
        sty     $0c
        sty     $23
        sty     $22
L98fd:  ldy     $22
        inc     $22
        lda     $0200,y
        bmi     L991f
        cmp     #$22
        bne     L9912
        lda     $0c
        eor     #$ff
        sta     $0c
        lda     #$22
L9912:  ldy     $23
        sta     $0139,y
        tax
        bne     L991b
        rts
-----------------------------------
L991b:  inc     $23
        bne     L98fd
L991f:  cmp     #$ff
        beq     L9912
        bit     $0c
        bmi     L9912
        tax
        ldy     #$9e
        sty     $62
        ldy     #$a0
        sty     $63
        ldy     #$00
        asl
        beq     L9947
L9935:  dex
        bpl     L9946
L9938:  inc     $62
        bne     L993e
        inc     $63
L993e:  lda     ($62),y
        bpl     L9938
        bmi     L9935
L9944:  inc     $23
L9946:  iny
L9947:  ldx     $23
        lda     ($62),y
        pha
        and     #$7f
        sta     $0139,x
        pla
        bpl     L9944
        bmi     L991b
L9956:  iny
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
        jsr     L9988
        lda     $ba
        jsr     TALK
        lda     #$60
        jsr     TKSA
        jsr     IECIN
        jsr     IECIN
        jsr     UNTALK
        pla
        pla
        jmp     L90c8
-----------------------------------
L9988:  jsr     $F3D5
L998b:  rts
-----------------------------------
L998c:  ldy     #$02
L998e:  lda     $0110,y
        sta     $0024,y
        and     #$40
        beq     L99ba
        dey
        bpl     L998e
        lda     $26
        asl
        asl
        asl
        ldx     #$03
L99a2:  asl
        rol     $25
        dex
        bpl     L99a2
        rol     $24
        cpx     #$fd
        bne     L99a2
        ldy     #$37
L99b0:  lda     $24
        cmp     L9a06,y
        beq     L99bd
L99b7:  dey
        bpl     L99b0
L99ba:  lda     #$00
        rts
-----------------------------------
L99bd:  lda     $25
        cmp     L9a3e,y
        bne     L99b7
        lda     L9a76,y
        ldx     #$05
        cpy     #$1f
        bcs     L99dd
        dex
        cpy     #$16
        bcs     L99dd
        dex
        cpy     #$0e
        bcs     L99dd
        dex
        cpy     #$08
        bcs     L99dd
        dex
L99dd:  sta     $4b
        txa
        rts
-----------------------------------
L99e1:  jsr     L99e4
L99e4:  lda     #$20
        jmp     CHROUT
-----------------------------------
L99e9:  lda     $fc
        jsr     L99f0
        lda     $fb
L99f0:  pha
        lsr
        lsr
        lsr
        lsr
        jsr     L9af9
        pla
L9af9:  and     #$0f
        ora     #$30
        cmp     #$3a
        bcc     L9a03
        adc     #$06
L9a03:  jmp     CHROUT
-----------------------------------
L9a06:  !by     $09,$0b,$1b,$2b,$61,$7c,$98,$9d
        !by     $0c,$21,$4b,$64,$93,$93,$10,$10
        !by     $11,$13,$13,$14,$15,$15,$12,$1c
        !by     $1c,$53,$54,$61,$61,$9d,$9d,$14
        !by     $1b,$1b,$1b,$1b,$21,$21,$4b,$4b
        !by     $73,$82,$82,$83,$83,$95,$95,$99
        !by     $99,$99,$a0,$a0,$a4,$a6,$a6,$a6
L9a3e:  !by     $06,$88,$60,$e4,$02,$82,$86,$02
        !by     $d8,$46,$86,$e4,$d8,$e4,$c6,$e6
        !by     $62,$52,$8a,$18,$86,$a6,$68,$30
        !by     $32,$60,$e4,$30,$32,$30,$32,$96
        !by     $06,$08,$12,$2c,$70,$72,$b0,$b2
        !by     $e0,$02,$20,$02,$20,$12,$26,$46
        !by     $48,$52,$70,$72,$f0,$02,$26,$42
L9a76:  !by     $61,$21,$c1,$41,$a1,$01,$e1,$81
        !by     $02,$c2,$e2,$42,$22,$62,$90,$b0
        !by     $f0,$30,$d0,$10,$50,$70,$00,$1e
        !by     $28,$0a,$14,$32,$3c,$46,$50,$00
        !by     $18,$d8,$58,$b8,$ca,$88,$e8,$c8
        !by     $ea,$48,$08,$68,$28,$40,$60,$38
        !by     $f8,$78,$aa,$a8,$ba,$8a,$9a,$98
L9aae:  !by     $00,$24,$00,$2c,$00,$00,$00,$00
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

L9b05:  !by     $53,$59,$4e,$54,$41,$58,$00     ; syntax.

L9b0c:  !by     $4f,$4e,$45,$20,$42,$59,$54,$45 ; one byte
        !by     $20,$52,$41,$4e,$47,$45,$00     ;  range.         

L9b1b:  !by     $52,$45,$4c,$41,$54,$49,$56,$20 ; relativ 
        !by     $42,$52,$41,$4e,$43,$48,$00     ; branch.

L9b2a:  !by     $49,$4c,$4c,$45,$47,$41,$4c,$20 ; illegal 
        !by     $4f,$50,$45,$52,$41,$4e,$44,$00 ; operand.

L9b3a:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$44,$49,$52,$45,$43,$54 ; e direct
        !by     $49,$56,$45,$00                 ; ive.

L9b4e:  !by     $44,$55,$50,$4c,$49,$43,$41,$54 ; duplicat
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00 ; .

L9b5f:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00                             ; . 

L9b70:  !by     $20,$45,$52,$52,$4f,$52,$00     ;  error

L9b77:  !by     $45,$4e,$44                     ; end

L9b7a:  !by     $54,$45,$58,$54                 ; text

L9b7e:  !by     $57,$4f,$52,$54                 ; wort

L9b82:  !by     $44,$49,$53,$50                 ; disp

L9b86:  !by     $42,$59,$54,$45                 ; byte

L9b8a:  !by     $4c,$4f,$41,$44                 ; load

L9b8e:  !by     $0d,$50,$52,$4f,$47,$52,$41,$4d ; .program
        !by     $4d,$4e,$41,$4d,$45,$20,$20,$3a ; mname  :
        !by     $20,$00                         ;  . 

L9ba0:  !by     $0d,$48,$45,$58,$41,$20         ; .hexa
        !by     $4b,$4f,$52,$52,$2d,$50,$4f,$4b ; korr-pok
        !by     $45,$3a,$20,$00                 ; e: .

L9bb2:  !by     $0d,$41,$55,$53,$44,$52,$55,$43 ; .ausdruc
        !by     $4b,$2d,$43,$4f,$44,$45,$20,$3a ; k-code :
        !by     $20,$00                         ;  .

L9bc4:  !by     $5a,$45,$49,$4c,$45,$4e,$3a,$00 ; zeilen:.

L9bcc:  !by     $20,$20,$20,$53,$59,$4d,$42,$4f ;    symbo
        !by     $4c,$45,$3a,$00                 ; le:.

L9bd8:  !by     $20,$20,$20,$46,$45,$48,$4c,$45 ;    fehle
        !by     $52,$3a,$00                     ; r:.

L9be3:  !by     $53,$45,$49,$54,$45,$3a,$00     ; seite:.
ASS_END:

FILL3:  !fi     $9c00-FILL3, $aa

; - $9C00  basic command RENEW -----------------
RENEW:  jmp     L9eaf
; - $9C03  basic command CHECK UNDEF'D ---------
UNDEF:  jmp     L9c37
; - $9C06  basic command COMPACTOR -------------
COMPACTOR:
        jsr     L9c18
        ldx     #$01
        stx     $0133
        stx     $0135
        dex
        stx     $0134
        jmp     L802d
-----------------------------------
L9c18:  ldx     #$f0
        jsr     CHRGET
        beq     L9c2c
        jsr     $b79e
        txa
        bne     L9c28
L9c25:  jmp     ERRFC                           ; llegal quantity error
-----------------------------------
L9c28:  cpx     #$f1
        bcs     L9c25
L9c2c:  stx     $fc
        jsr     L9c3a
        jsr     L9c86
        jmp     $a533
-----------------------------------
L9c37:  lda     #$01
        !by     $2c
L9c3a:  lda     #$00
        sta     $0133
        jsr     L9c55
        lda     $0133
        bne     L9c48
        rts
-----------------------------------
L9c48:  lda     #$00
        sta     $c6
        ldx     #$fa
        txs
        jsr     $a533
        jmp     READY                           ; go handle error message
-----------------------------------
L9c55:  jsr     $a68e
L9c58:  jsr     L9d97
L9c5b:  jsr     CHRGET
L9c5e:  tax
        beq     L9c58
        jsr     L9dee
        bcc     L9c5e
        jsr     L9dad
        bne     L9c5b
L9c6b:  jsr     CHRGET
        bcs     L9c5e
        jsr     $a96b
        jsr     L9e6d
        bcs     L9c7d
        ldx     #$5a
        jsr     L9dc6
L9c7d:  jsr     CHRGOT
        cmp     #$2c
        bne     L9c5e
        beq     L9c6b
L9c86:  ldy     #$00
        sty     $0133
        sty     $0134
        sty     $0135
        jsr     $a68e
L9c94:  lda     $7a
        sta     $47
        lda     $7b
        sta     $48
        jsr     L9d97
        inc     $7a
        bne     L9ca5
        inc     $7b
L9ca5:  jsr     L9de5
        lda     $0133
        bne     L9cb4
L9cad:  lda     #$00
        sta     $0135
        beq     L9cec
L9cb4:  ldy     #$ff
L9cb6:  iny
        lda     ($3d),y
        bne     L9cb6
        tya
        clc
        adc     $0135
        bcs     L9cad
        cmp     $fc
        bcs     L9cad
        ldy     #$02
        lda     ($47),y
        cmp     #$ff
        beq     L9cad
        ldy     #$00
        lda     $0134
        beq     L9cdf
        lda     #$22
        sta     ($47),y
        inc     $47
        bne     L9cdf
        inc     $48
L9cdf:  lda     #$3a
        sta     ($47),y
        inc     $47
        bne     L9ce9
        inc     $48
L9ce9:  jsr     L9e22
L9cec:  ldx     #$00
        stx     $0134
        inx
        stx     $0133
        inc     $0135
L9cf8:  ldy     #$00
L9cfa:  lda     ($7a),y
        bne     L9d01
        jmp     L9c94
-----------------------------------
L9d01:  inc     $7a
        bne     L9d07
        inc     $7b
L9d07:  inc     $0135
        cmp     #$22
        bne     L9d26
L9d0e:  lda     ($7a),y
        bne     L9d17
        inc     $0134
        bne     L9cfa
L9d17:  inc     $7a
        bne     L9d1d
        inc     $7b
L9d1d:  inc     $0135
        cmp     #$22
        bne     L9d0e
        beq     L9cfa
L9d26:  cmp     #$8b
        bne     L9d31
L9d2a:  lda     #$00
        sta     $0133
        beq     L9cfa
L9d31:  cmp     #$8d
        beq     L9cfa
        jsr     L9dad
        beq     L9d2a
        cmp     #$20
        bne     L9d4a
        jsr     L9ea1
L9d41:  jsr     L9de5
        jsr     L9e22
        jmp     L9cf8
-----------------------------------
L9d4a:  cmp     #$8f
        bne     L9d6b
        jsr     L9ea1
        lda     #$3a
        sta     ($47),y
        inc     $47
        bne     L9d5b
        inc     $48
L9d5b:  lda     ($7a),y
L9d5d:  beq     L9cfa
L9d5f:  inc     $7a
        bne     L9d65
        inc     $7b
L9d65:  lda     ($7a),y
        bne     L9d5f
        beq     L9d41
L9d6b:  cmp     #$83
        bne     L9cfa
L9d6f:  lda     ($7a),y
L9d71:  beq     L9cfa
        inc     $7a
        bne     L9d79
        inc     $7b
L9d79:  inc     $0135
        cmp     #$3a
        beq     L9d5d
        cmp     #$22
        bne     L9d6f
L9d84:  lda     ($7a),y
        beq     L9d71
        inc     $7a
        bne     L9d8e
        inc     $7b
L9d8e:  inc     $0135
        cmp     #$22
        bne     L9d84
        beq     L9d6f
L9d97:  ldy     #$02
        lda     ($7a),y
        bne     L9da0
        pla
        pla
        rts
-----------------------------------
L9da0:  iny
        lda     ($7a),y
        sta     $39
        iny
        lda     ($7a),y
        sta     $3a
        jmp     $a8fb
-----------------------------------
L9dad:  cmp     #$cb
        bne     L9db7
        jsr     CHRGET
        cmp     #$a4
        rts
-----------------------------------
L9db7:  cmp     #$a7
        beq     L9dc5
        cmp     #$89
        beq     L9dc5
        cmp     #$8d
        beq     L9dc5
        cmp     #$8a
L9dc5:  rts
-----------------------------------
L9dc6:  lda     $a225,x                         ; verweisst auf "data" im ROM
        pha
        and     #$7f
        jsr     CHROUT
        inx
        pla
        bpl     L9dc6
        lda     #$6a
        ldy     #$a3
        jsr     $ab1e
        jsr     $bdc2
        lda     #$ff
        sta     $0133
        jmp     CRDO
-----------------------------------
L9de5:  ldx     $7a
        stx     $3d
        ldx     $7b
        stx     $3e
        rts
-----------------------------------
L9dee:  cmp     #$22
        bne     L9e0a
        ldy     #$00
        inc     $7a
        bne     L9dfa
        inc     $7b
L9dfa:  lda     ($7a),y
        beq     L9e11
        inc     $7a
        bne     L9e04
        inc     $7b
L9e04:  cmp     #$22
        bne     L9dfa
        beq     L9e11
L9e0a:  cmp     #$8f
        bne     L9e16
        jsr     $a93b
L9e11:  jsr     CHRGOT
        clc
        rts
-----------------------------------
L9e16:  cmp     #$83
        bne     L9e20
        jsr     $a8f8
        jmp     L9e11
-----------------------------------
L9e20:  sec
        rts
-----------------------------------
L9e22:  lda     $47
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
        bcs     L9e56
        inx
        dec     $25
L9e56:  clc
        adc     $22
        bcc     L9e5e
        dec     $23
        clc
L9e5e:  lda     ($22),y
        sta     ($24),y
        iny
        bne     L9e5e
        inc     $23
        inc     $25
        dex
        bne     L9e5e
        rts
-----------------------------------
L9e6d:  lda     $2b
        ldx     $2c
L9e71:  ldy     #$01
        sta     $5f
        stx     $60
        lda     ($5f),y
        beq     L9e9f
        ldy     #$03
        lda     $15
        cmp     ($5f),y
        bcc     L9ea0
        bne     L9e94
        dey
        lda     $14
        cmp     ($5f),y
        bcc     L9ea0
        bne     L9e94
        dey
        lda     #$ff
        sta     ($5f),y
        rts
-----------------------------------
L9e94:  ldy     #$00
        lda     ($5f),y
        cmp     $5f
        bcs     L9e71
        inx
        bcc     L9e71
L9e9f:  clc
L9ea0:  rts
-----------------------------------
L9ea1:  lda     $7b
        sta     $48
        ldx     $7a
        bne     L9eab
        dec     $48
L9eab:  dex
        stx     $47
        rts
-----------------------------------
L9eaf:  lda     $2b
        ldx     $2c
        sta     $22
        stx     $23
L9eb7:  ldy     #$03
L9eb9:  iny
        beq     L9efb
        lda     ($22),y
        bne     L9eb9
        tya
        sec
        adc     $22
        tax
        ldy     #$00
        tya
        adc     $23
        cmp     $38
        bne     L9ed0
        cpx     $37
L9ed0:  bcs     L9efb
        pha
        txa
        sta     ($22),y
        iny
        pla
        sta     ($22),y
        stx     $22
        sta     $23
        lda     ($22),y
        bne     L9eb7
        dey
        lda     ($22),y
        bne     L9eb7
L9ee7:  clc
        lda     $22
        ldy     $23
        adc     #$02
        bcc     L9ef1
        iny
L9ef1:  sta     $2d
        sty     $2e
        jsr     $a660
        jmp     READY                           ; go handle error message
-----------------------------------
L9efb:  tya
        sta     ($22),y
        iny
        sta     ($22),y
        bne     L9ee7

FILL4:  !fi     $a000-FILL4, $aa