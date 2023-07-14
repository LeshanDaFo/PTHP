; ###############################################################
; #                                                             #
; #  Print Technik Help Plus V3 source code                     #
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
FRMNUM          = $AD8A                         ; evaluate expression and check is numeric, else do type mismatch
SNERR           = $AF08                         ; handle syntax error
ERRFC           = $B248                         ; illegal quantity error
GETADR          = $B7F7                         ; convert FAC_1 to integer in temporary integer
FLOATC          = $BC49                         ; FLOAT UNSIGNED VALUE IN FAC+1,2
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


!to"build/PTHP-V3.crt",plain
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
L802d:  jmp     L85e3
-----------------------------------
MPREP = $80e8
FILL1:  !fi     MPREP-FILL1, $aa                ; fill bytes

MPREP:
; ----------------------------------------------
; -------- Modul Start -------------------------
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
L80fd:  lda     #<START                         ; new BASIC warm start low byte
        ldx     #>START                         ; new BASIC warm start high byte
        bne     L8107                           ; 'jmp' set vector
; restore basic warm start values
L8103:  lda     #$83                            ; old BASIC warm start low byte
        ldx     #$a4                            ; old BASIC warm start low high
L8107:  sta     $0302                           ; set vector low byte
        stx     $0303                           ; set vector high byte
        rts
-----------------------------------
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
-----------------------------------
L8134:  lda     DMLBYT,x                        ; DOS and monitor low byte
        sta     $55
        lda     DMHBYT,x                        ; DOS and monitor high byte
        sta     $56
        jmp     ($0055)                         ; execute command
; ----------------------------------------------
; - $8141  basic command GENLINE ---------------
; ----------------------------------------------
GENLINE:
        jsr     L846d
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
-----------------------------------
L8187:  clc
        adc     $0135
        bcc     L8194
        iny
        cpy     #$fa
        bcc     L8194
        ldy     #$00
L8194:  rts
-----------------------------------
L8195:  sta     $63
        sty     $62
L8199:  ldx     #$90
        sec
        jsr     FLOATC
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
-----------------------------------
L81b3:  lda     BCLBYT,x                        ; basic command low byte table
        sta     $55
        lda     BCHBYT,x                        ; basic command high byte table
        sta     $56
        inc     $7a
        jmp     ($0055)
; ----------------------------------------------
; - #81C2  Matrix and Variable dump ------------
; ------- start $8249 and $8307 ----------------
; ----------------------------------------------
L81c2:  jsr     CRDO
L81c5:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        beq     L81c5
        ldy     #$00
        lda     ($45),y
        tax
        bpl     L81dc
        iny
        lda     ($45),y
        bmi     L81dc
        rts
-----------------------------------
L81dc:  ldy     #$00
        lda     ($45),y
        and     #$7f
        jsr     CHROUT
        iny
        lda     ($45),y
        tay
        and     #$7f
        beq     L81f0
        jsr     CHROUT
L81f0:  txa
        bpl     L81f7
        lda     #$25
        bne     L81fc
L81f7:  tya
        bpl     L81ff
        lda     #$24
L81fc:  jsr     CHROUT
L81ff:  rts
-----------------------------------
L8200:  jsr     CHROUT
L8203:  jsr     L88be
        lda     #$3d
        jmp     CHROUT
-----------------------------------
L820b:  ldy     #$00
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        tay
        txa
        jsr     $b395
        ldy     #$01        
        jmp     $bdd7
-----------------------------------
L821d:  jsr     $bba6
        ldy     #$01
        jmp     $bdd7
-----------------------------------
L8225:  jsr     L8244
        ldy     #$02
        lda     ($22),y
        sta     $25
        dey
        lda     ($22),y
        sta     $24
        dey
        lda     ($22),y
        sta     $26
        beq     L8244
L823a:  lda     ($24),y
        jsr     CHROUT
        iny
        cpy     $26
        bne     L823a
L8244:  lda     #$22
        jmp     CHROUT
; - $8249  basic command MATRIX DUMP -----------
M_DUMP: ldx     $30
        lda     $2f
L824d:  sta     $45
        stx     $46
        cpx     $32
        bne     L8257
        cmp     $31
L8257:  bcc     L825c
        jmp     READY                           ; go handle error message
-----------------------------------
L825c:  ldy     #$04
        adc     #$05
        bcc     L8263
        inx
L8263:  sta     $0b
        stx     $0c
        lda     ($45),y
        asl
        tay
        adc     $0b
        bcc     L8270
        inx
L8270:  sta     $fb
        stx     $fc
        dey
        sty     $55
        lda     #$00
L8279:  sta     $0205,y
        dey
        bpl     L8279
        bmi     L82b3
L8281:  ldy     $55
L8283:  dey
        sty     $fd
        tya
        tax
        inc     $0206,x
        bne     L8290
        inc     $0205,x
L8290:  lda     $0205,y
        cmp     ($0b),y
        bne     L829d
        iny
        lda     $0205,y
        cmp     ($0b),y
L829d:  bcc     L82b3
        lda     #$00
        ldy     $fd
        sta     $0205,y
        sta     $0206,y
        dey
        bpl     L8283
        lda     $fb
        ldx     $fc
        jmp     L824d
-----------------------------------
L82b3:  jsr     L81c2
        ldy     $55
        lda     #$28
L82ba:  jsr     CHROUT
        lda     $0204,y
        ldx     $0205,y
        sty     $fd
        jsr     INTOUT
        lda     #$2c
        ldy     $fd
        dey
        dey
        bpl     L82ba
        lda     #$29
        jsr     L8200
        lda     $fb
        ldx     $fc
        sta     $22
        stx     $23
        ldy     #$00
        lda     ($45),y
        bpl     L82ea
        jsr     L820b
        lda     #$02
        bne     L82fb
L82ea:  iny
        lda     ($45),y
        bmi     L82f6
        jsr     L821d
        lda     #$05
        bne     L82fb
L82f6:  jsr     L8225
        lda     #$03
L82fb:  clc
        adc     $fb
        sta     $fb
        bcc     L8304
        inc     $fc
L8304:  jmp     L8281
; - $8307  basic command VAR DUMP --------------
V_DUMP: lda     $2d
        ldy     $2e
L830b:  sta     $45
        sty     $46
        cpy     $30
        bne     L8315
        cmp     $2f
L8315:  bcc     L831a
        jmp     READY                           ; go handle error message
-----------------------------------
L831a:  adc     #$02
        bcc     L831f
        iny
L831f:  sta     $22
        sty     $23
        jsr     L81c2        
        txa
        bpl     L8335
        tya
        bpl     L8344
        jsr     L8203
        jsr     L820b
        jmp     L8344
-----------------------------------
L8335:  jsr     L8203
        tya
        bmi     L8341
        jsr     L821d
        jmp     L8344
-----------------------------------
L8341:  jsr     L8225
L8344:  lda     $45
        ldy     $46
        clc
        adc     #$07
        bcc     L830b
        iny
        bcs     L830b
; ----------------------------------------------
; ------- Matrix and Variable dump end ---------
; ----------------------------------------------

; ----------------------------------------------
; - $8350  basic command FIND ------------------
; ----------------------------------------------
FIND:   inc     $7a
        lda     $3d
        pha
        jsr     CRUNCH
        jsr     CHRGET
        ldy     #$00
        cmp     #$22
        bne     L8364
        dey
        inc     $7a
L8364:  sty     $fe
        lda     $2b
        ldx     $2c
L836a:  sta     $3d
        stx     $23
        sta     $22
        sta     $5f
        stx     $60
L8374:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        beq     L8374
        ldy     #$00
        sty     $0f
        iny
        lda     ($5f),y
        bne     L838d
        pla
        sta     $3d
        jmp     READY                           ; go handle error message
-----------------------------------
L838d:  lda     #$04
        !by     $2c
L8390:  lda     #$01
        clc
        adc     $22
        sta     $22
        bcc     L839b
        inc     $23
L839b:  ldy     #$00
        lda     ($22),y
        beq     L83bc
        cmp     #$22
        bne     L83ab
        lda     $0f
        eor     #$ff
        sta     $0f
L83ab:  lda     $0f
        cmp     $fe
        bne     L8390
L83b1:  lda     ($7a),y
        beq     L83c2
        cmp     ($22),y
        bne     L8390
        iny
        bne     L83b1
L83bc:  lda     $22
        ldx     $23
        bne     L83cb
L83c2:  inc     $3d
        jsr     L83e6
        lda     $5f
        ldx     $60
L83cb:  clc
        adc     #$01
        bcc     L836a
        inx
        bcs     L836a
; ----------------------------------------------
; - $83D3  basic command HELP ------------------
; ----------------------------------------------
HELP:   lda     $3a
        sta     $15
        lda     $39
        sta     $14
        jsr     $a613
        bcc     L83e3
        jsr     L83e6
L83e3:  jmp     READY                           ; go handle error message
-----------------------------------
L83e6:  jsr     CRDO
        ldy     #$02
        sty     $0f
        lda     ($5f),y
        tax
        iny
        lda     ($5f),y
        jsr     INTOUT
        jsr     L88be
        ldx     $5f
        dex
        cpx     $3d
        bne     L8402
        sty     $c7
L8402:  lda     #$04
        !by     $2c
L8405:  lda     #$01
        clc
        adc     $5f
        ldx     $5f
        sta     $5f
        bcc     L8412
        inc     $60
L8412:  cpx     $3d
        bne     L841a
        lda     #$01
        sta     $c7
L841a:  ldy     #$00
        lda     ($5f),y
        bne     L8421
        rts
-----------------------------------
L8421:  cmp     #$3a
        bne     L8427
        sty     $c7
L8427:  cmp     #$22
        bne     L8433
        lda     $0f
        eor     #$ff
        sta     $0f
        lda     #$22
L8433:  tax
        bmi     L843e
L8436:  and     #$7f
L8438:  jsr     CHROUT
        jmp     L8405
-----------------------------------
L843e:  cmp     #$ff
        beq     L8438
        bit     $0f
        bmi     L8438
        ldy     #$a0
        sty     $23
        ldy     #$9e
        sty     $22
        ldy     #$00
        asl
        beq     L8463
L8453:  dex
        bpl     L8462
L8456:  inc     $22
        bne     L845c
        inc     $23
L845c:  lda     ($22),y
        bpl     L8456
        bmi     L8453
L8462:  iny
L8463:  lda     ($22),y
        bmi     L8436
        jsr     CHROUT
        iny
        bne     L8463
L846d:  jsr     CHRGET
        bne     L847a
        ldx     #$0a
        ldy     #$00
        lda     #$64
        bne     L848c
L847a:  jsr     $b7eb
        lda     $14
        ldy     $15
        cpy     #$fa
        bcc     L8488
L8485:  jmp     SNERR                           ; syntax error
-----------------------------------
L8488:  cpx     #$00
        beq     L8485
L848c:  stx     $0135
        sta     $0133
        sty     $0134
        rts
; ----------------------------------------------
; - $8496  basic command DELETE ----------------
; ----------------------------------------------
DELETE: jsr     CHRGET
        beq     L8485
        bcc     L84a1
        cmp     #$2d
        bne     L8485
L84a1:  jsr     $a96b
        jsr     $a613
        jsr     CHRGOT
        beq     L84b8
        cmp     #$2d
        bne     L847a
        jsr     CHRGET
        jsr     $a96b
        bne     L8485
L84b8:  lda     $14
        ora     $15
        bne     L84c2
        lda     #$ff
        sta     $15
L84c2:  ldx     $5f
        lda     $60
        stx     $fb
        sta     $fc
L84ca:  stx     $22
        sta     $23
        ldy     #$01
        lda     ($22),y
        beq     L84ef
        iny
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        cmp     $15
        bne     L84e3
        cpx     $14
        beq     L84e5
L84e3:  bcs     L84ef
L84e5:  ldy     #$00
        lda     ($22),y
        tax
        iny
        lda     ($22),y
        bne     L84ca
L84ef:  lda     $2d
        sta     $24
        lda     $2e
        sta     $25
        jsr     L8c1f
        lda     $26
        sta     $2d
        lda     $27
        sta     $2e
        jmp     $a52a
; ----------------------------------------------
; - $8505  basic command KILL ------------------
; ----------------------------------------------
KILL:   jsr     L8103
; ----------------------------------------------
; - $8508  basic command END TRACE -------------
; ----------------------------------------------
ENDTRACE:
        lda     #$e4
        ldx     #$a7
L850c:  sta     $0308
        stx     $0309
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8515  basic command LIST PAGE -------------
; ----------------------------------------------
LPAGE:  jsr     CHRGET
        jsr     $a96b
        jsr     $a613
        jsr     $abb7
        lda     $3d
        pha
L8524:  lda     $5f
        sta     $fd
        lda     $60
        sta     $fe
        lda     #$93
        jsr     CHROUT
L8531:  ldx     $5f
        inx
        stx     $3d
        ldy     #$01
        lda     ($5f),y
        beq     L854b
        jsr     L83e6
        inc     $5f
        bne     L8545
        inc     $60
L8545:  lda     $d6
        cmp     #$16
        bcc     L8531
L854b:  lda     #$17
        sta     $d6
        jsr     CRDO
L8552:  jsr     GETIN
        cmp     #$03
        bne     L855f
        pla
        sta     $3d
        jmp     START
-----------------------------------
L855f:  cmp     #$0d
        bne     L856b
        ldy     #$01
        lda     ($5f),y
        beq     L8552
        bne     L8524
L856b:  cmp     #$5e
        bne     L8552
        jsr     L85d5
        bcs     L854b
        lda     #$93
        jsr     CHROUT
        lda     $fe
        pha
        lda     $fd
        pha
        ldx     #$16
L8581:  stx     $d6
        stx     $fc
        lda     $fd
        sta     $24
        lda     $fe
        sta     $25
L858d:  ldy     #$00
L858f:  lda     $24
        bne     L8595
        dec     $25
L8595:  dec     $24
        lda     ($24),y
        bne     L858f
        iny
        lda     ($24),y
        cmp     $fd
        bne     L858d
        iny
        lda     ($24),y
        cmp     $fe
        bne     L858d
        ldx     $24
        ldy     $25
        inx
        bne     L85b1
        iny
L85b1:  stx     $fd
        stx     $5f
        sty     $fe
        sty     $60
        inx
        stx     $3d
        jsr     L83e6
        jsr     L85d5
        bcc     L85cd
L85c4:  pla
        sta     $5f
        pla
        sta     $60
        jmp     L854b
-----------------------------------
L85cd:  ldx     $fc
        dex
        dex
        bpl     L8581
        bmi     L85c4
L85d5:  lda     $2c
        cmp     $fe
        bne     L85df
        lda     $2b
        cmp     $fd
L85df:  rts
; ----------------------------------------------
; - $85E0  basic command RENUMBER --------------
; ----------------------------------------------
RENUMBER:
        jsr     L846d
L85e3:  jsr     $a68e
L85e6:  ldy     #$02
        lda     ($7a),y
        bne     L8622
        lda     $2b
        ldx     $2c
        sta     $22
L85f2:  stx     $23
        ldy     #$01
        lda     ($22),y
        tax
        bne     L85fe
        jmp     $a52a
-----------------------------------
L85fe:  iny
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
        jmp     L85f2
-----------------------------------
L8622:  lda     $7a
        clc
        adc     #$04
        sta     $7a
        bcc     L862d
        inc     $7b
L862d:  jsr     CHRGET
L8630:  tax
        beq     L85e6
        cmp     #$89
        beq     L8643
        cmp     #$8a
        beq     L8643
        cmp     #$8d
        beq     L8643
        cmp     #$a7
        bne     L862d
L8643   lda     $7a
        sta     $28
        lda     $7b
        sta     $29
        jsr     CHRGET
        bcs     L8630
        jsr     $a96b
        lda     $2b
        ldx     $2c
        sta     $24
        lda     $0133
        ldy     $0134
L865f:  stx     $25
        sta     $63
        sty     $62
        ldy     #$01
        lda     ($24),y
        tax
        bne     L8673
        dex
        stx     $62
        stx     $63
        bne     L8691
L8673:  iny
        lda     ($24),y
        cmp     $14
        beq     L868a
L867a:  ldy     #$00
        lda     ($24),y
        sta     $24
        lda     $63
        ldy     $62
        jsr     L8187
        jmp     L865f
-----------------------------------
L868a:  iny
        lda     ($24),y
        cmp     $15
        bne     L867a
L8691:  jsr     L8199
        lda     $28
        sta     $7a
        lda     $29
        sta     $7b
        ldx     #$00
L869e:  lda     $0101,x
        beq     L86da
        pha
        jsr     CHRGET
        bcc     L86d2
        lda     $2d
        sta     $22
        lda     $2e
        sta     $23
        inc     $2d
        bne     L86b7
        inc     $2e
L86b7:  lda     $22
        bne     L86bd
        dec     $23
L86bd:  dec     $22
        ldy     #$00
        lda     ($22),y
        iny
        sta     ($22),y
        lda     $22
        cmp     $7a
        bne     L86b7
        lda     $23
        cmp     $7b
        bne     L86b7
L86d2:  pla
        ldy     #$00
        sta     ($7a),y
        inx
        bne     L869e
L86da:  jsr     CHRGET
        bcs     L870d
L86df:  lda     $7a
        sta     $22
        lda     $7b
        sta     $23
L86e7:  ldy     #$01
        lda     ($22),y
        dey
        sta     ($22),y
        inc     $22
        bne     L86f4
        inc     $23
L86f4:  lda     $22
        cmp     $2d
        bne     L86e7
        lda     $23
        cmp     $2e
        bne     L86e7
        lda     $2d
        bne     L8706
        dec     $2e
L8706:  dec     $2d
        jsr     CHRGOT
        bcc     L86df
L870d:  pha
        jsr     $a533
        pla
        cmp     #$2c
        bne     L8719
        jmp     L8643
-----------------------------------
L8719:  jmp     L8630
; ----------------------------------------------
; - $871C  basic command SINGLE STEP -----------
; ----------------------------------------------
S_STEP: lda     #$00
        !by     $2c
; ----------------------------------------------
; - $871F  basic command TRACE -----------------
; ----------------------------------------------
TRACE:  lda     #$80
        sta     $0130
        lda     #<L872b
        ldx     #>L872b
        jmp     L850c
-----------------------------------
L872b:  lda     $39
        ldx     $3a
        cmp     $0124
        bne     L873c
        cpx     $0125
        bne     L873c
L8739:  jmp     $a7e4
-----------------------------------
L873c:  cpx     #$ff
        bne     L8745
        stx     $0125
        beq     L8739
L8745:  sta     $0122
        stx     $0123
        ldx     #$0b
L874d:  lda     $0122,x
        sta     $0124,x
        dex
        bpl     L874d
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
L876d:  lda     #$20
        jsr     CHROUT
        dex
        bne     L876d
        lda     #$13
        jsr     CHROUT
        ldy     #$00
L877c:  tya
        pha
        lda     $0124,y
        tax
        lda     $0125,y
        cmp     #$ff
        beq     L879b
        jsr     INTOUT
        lda     #$20
        jsr     CHROUT
        pla
        tay
        iny
        iny
        cpy     #$0c
        bcc     L877c
        bcs     L879c
L879b:  pla
L879c:  lda     $da
        ora     #$80
        sta     $da
        jsr     CRDO
        ldx     #$05
        ldy     #$00
        sty     $0f
        lda     ($3d),y
        beq     L87b1
        ldx     #$01
L87b1:  txa
        clc
        adc     $3d
        sta     $5f
        tya
        adc     $3e
        sta     $60
        jsr     L841a
        jsr     CRDO
        bit     $0130
        bmi     L87d3
L87c7:  jsr     ISCNTC
        lda     $028e
        cmp     #$01
        bne     L87c7
        beq     L87de
L87d3:  lda     #$03
        ldx     $028e
        cpx     #$01
        bne     L87de
        lda     #$00
L87de:  sta     $0122
        ldy     #$78
L87e3:  dex
        bne     L87e3
        dey
        bne     L87e3
        dec     $0122
        bpl     L87e3
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
; - #8801  basic command APPEND ----------------
; ----------------------------------------------
APPEND: inc     $7a
        jsr     $e1d4
        ldx     $2b
        lda     $2c
L880a:  stx     $5f
        sta     $60
        ldy     #$00
        lda     ($5f),y
        tax
        iny
        lda     ($5f),y
        bne     L880a
        ldy     $60
        ldx     $5f
        sta     $0133
        sta     $0a
        sta     $b9
        jsr     $ffd5
        jmp     L896a
; ----------------------------------------------
; - $8829 -- print free memory -----------------
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
; - $883C -- switch to uppercase ---------------
; ----------------------------------------------
UPCASE: lda     #$8e
        !by     $2c
; ----------------------------------------------
; - $883F -- switch to lower case --------------
; ----------------------------------------------
LOWCASE:lda     #$0e        
        jsr     $e716
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8847 -- close command and file ------------
; ----------------------------------------------
CLFILE: jsr     CLRCHN
        lda     #$ff
        jsr     CLOSE
        jmp     READY                           ; go handle error message
-----------------------------------
L8852:  jsr     $e206
        jmp     $b79e
; ----------------------------------------------
; - $8858 -- open file with cmd ----------------
; ----------------------------------------------
OPNFILE:inc     $7a
        ldx     #$04
        jsr     L8852
        stx     $ba
        lda     #$ff
        sta     $b8
        sta     $b9
        jsr     OPEN
        ldx     #$ff
        jsr     $e118
        jmp     START
; ----------------------------------------------
; - $8872 jump in for convert - "!$", "!#" -----
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
; - $888C - check for # ------------------------
CKNXT:  cmp     #$23                            ; compare with "#"
        beq     CNVDEC                          ; branch if ok
        jmp     START                           ; command not known, go back do start over
; - $8893 - convert hex to dec -----------------
CNVDEC: lda     #$00                            ; loaad 00
        sta     $62                             ; clear $62
        sta     $63                             ; clear $63
        ldx     #$05                            ; load counter
L889b:  jsr     CHRGET                          ; get next char, should be a number
        beq     OUT                             ; if there is nothing more
        dex                                     ; dec counter
        bne     ISCHAR                          ; have a char
L88a3:  jmp     ERRFC                           ; llegal quantity error
; - $88A6 --------------------------------------
ISCHAR: jsr     L88c3                           ; check if "0-9" or "A-F", if "A-F" convert to 3A-3F, get back values from $30 to $3F
        bcs     L88a3                           ; if carry was set, no valid value was found, go output error
L88ab:  rol
        rol     $63
        rol     $62
        dey
        bne     L88ab
        beq     L889b
L88b5
OUT:    jsr     INTOUT1
        jmp     READY                           ; ready
-----------------------------------
L88bb:  jsr     L88be
L88be:  lda     #$20
        jmp     CHROUT
-----------------------------------
L88c3:  bcc     ISNUM                           ; is number
        cmp     #$41                            ; cmp "A"
        bcs     IF_F                            ; branch if equal or higher
L88c9:  sec                                     ; set carry for error
        rts                                     ; 
; - $88CB - is number --------------------------
IF_F:   cmp     #$47                            ; cmp "F"
        bcs     L88c9                           ; go set carry for error
        sbc     #$06
; - $88d1 - is number --------------------------
ISNUM:  ldy     #$04
        asl
        asl
        asl
        asl
        clc
        rts

; - $88D9 output accu as hex value -------------
HEXOUT: pha
        lsr
        lsr
        lsr
        lsr
        jsr     L88e2
        pla
L88e2:  and     #$0f
        ora     #$30
        cmp     #$3a
        bcc     L88ec
        adc     #$06
L88ec:  jmp     CHROUT
; ----------------------------------------------
; - $88EF Save a programm ----------------------
; ----------------------------------------------
SAVEPRG:jsr     L89ab                           ; get name
L88f2:  ldx     $2d                             ; end low byte
        ldy     $2e                             ; end high byte
        lda     #$2b                            ; start adress low byte
        jsr     SAVE                            ; save prg
        bcc     L8900                           ; no error
        jmp     EREXIT                          ;
-----------------------------------
L8900:  jsr     L8b22
        lda     $0100
        cmp     #$30
        bne     L890d
        jmp     READY                           ; go handle error message
-----------------------------------
L890d:  cmp     #$36
        beq     L8914
L8911:  jmp     READY                           ; go handle error message
-----------------------------------
L8914:  lda     $0101
        cmp     #$33
        bne     L8911
        ldy     #$00
L891d:  lda     OVWTXT,y
        beq     L8928
        jsr     CHROUT
        iny
        bne     L891d
L8928:  jsr     GETIN
        cmp     #$4e                            ; "n"
        beq     L8911
        cmp     #$4a                            ; "j"
        bne     L8928
        lda     #$53                            ; "s"
        sta     $01ff
        lda     #$3a                            ; ":"
        cmp     $0202
        bne     L8941
        lda     #$20
L8941:  sta     $0200
        lda     #$ff
        sta     $bb
        dec     $bc
        inc     $b7
        inc     $b7
        jsr     L8b6a
        dec     $b7
        dec     $b7
        jsr     L89c3
        jmp     L88f2
; ----------------------------------------------
; - $895B load prg relative --------------------
; ----------------------------------------------
LDREL:  lda     #$00
        !by     $2C
; ----------------------------------------------
; - $895E load and run prg relative ------------
; ----------------------------------------------
LDRUN:  lda     #$80
        sta     $0133
        lda     #$00
        sta     $b9
L8967:  jsr     L89d5
L896a:  bcc     L896f
        jmp     EREXIT
-----------------------------------
L896f:  jsr     $ffb7
        and     #$bf
        beq     L8979
        jmp     L8b1c
-----------------------------------
L8979:  stx     $2d
        sty     $2e
        bit     $0133
        bmi     L8985
        jmp     $e1ab
-----------------------------------
L8985:  jsr     $a659
        jsr     $a533
        jsr     $a68e
        jmp     $a7ae
; ----------------------------------------------
; - $8991 Verify "<" ---------------------------
; ----------------------------------------------
VERIFY: lda     #$00
        sta     $b9
        lda     #$01
        jsr     L89d5
        jsr     $e17e
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $89A0 load prg absolut ---------------------
; ----------------------------------------------
LDABS:  lda     #$01
        sta     $b9
        lda     #$00
        sta     $0133
        beq     L8967
L89ab:  ldy     #$00
L89ad:  iny
        lda     $0200,y
        bne     L89ad
        dey
        sty     $b7
L89b6:  lda     $b8
        sta     $0134
        lda     $9a
        sta     $0135
        jsr     CLRCHN
L89c3:  ldy     #$01
        sty     $bb
        ldy     #$02
        sty     $bc
        ldy     #$00
        sty     $90
        lda     IONO
        sta     $ba
        rts
-----------------------------------
L89d5:  sta     $0a
        jsr     L89ab
        lda     $0a
        ldx     $2b
        ldy     $2c
        jmp     $ffd5
; ----------------------------------------------
; - $89E3 load directory -----------------------
; ----------------------------------------------
LDDIR:  lda     $9a
        cmp     #$03
        bne     L89ee
        lda     #$93
        jsr     CHROUT
L89ee:  jsr     L89ab
        dec     $bb
        inc     $b7
        lda     #$60
        sta     $b9
        jsr     L8aba
        bcc     L8a01
        jmp     EREXIT
-----------------------------------
L8a01:  lda     #$00
        sta     $90
        ldy     #$06
L8a07:  sty     $b7
        lda     IONO
        sta     $ba
        jsr     TALK
        lda     #$60
        sta     $b9
        jsr     TKSA
        ldy     #$00
        lda     $90
        bne     L8a35
L8a1e:  jsr     IECIN
        sta     $0200,y
        cpy     $b7
        bcc     L8a2b
        tax
        beq     L8a35
L8a2b:  iny
        lda     $90
        beq     L8a1e
        lda     #$00
        sta     $0200,y
L8a35:  sty     $fb
        lda     $90
        sta     $fc
        jsr     UNTALK
        lda     $0135
        cmp     #$03
        beq     L8a4b
        ldx     $0134
        jsr     CHKOUT
L8a4b:  ldy     $b7
        cpy     $fb
        bcs     L8a6d
        lda     $01ff,y
        ldx     $01fe,y
        jsr     INTOUT
        jsr     L88be
        ldy     $b7
L8a5f:  lda     $0200,y
        beq     L8a6a
        jsr     CHROUT
        iny
        bne     L8a5f
L8a6a:  jsr     CRDO
L8a6d:  jsr     CLRCHN
        lda     $fc
        bne     L8a9e
L8a74:  jsr     STOPT
        beq     L8a9e
        lda     $028e
        cmp     #$01
        beq     L8a74
        lda     $0135
        cmp     #$03
        bne     L8a99
        lda     $d6
        cmp     #$18
        bne     L8a99
        jsr     GETIN
        cmp     #$04
        bcc     L8a74
        lda     #$93
        jsr     CHROUT
L8a99:  ldy     #$04
        jmp     L8a07
-----------------------------------
L8a9e:  lda     #$60
        sta     $b9
        lda     IONO
        sta     $ba
        jsr     $f642
        lda     $0135
        cmp     #$03
        beq     L8ab7
        ldx     $0134
        jsr     CHKOUT
L8ab7:  jmp     READY                           ; go handle error message
-----------------------------------
L8aba:  jsr     $f3d5
        rts
; ----------------------------------------------
; - $8ABE  set IO number -----------------------
; ----------------------------------------------
SETIONO:jsr     CHRGET                          ; get char
        bcs     L8acf                           ; branch if not a number
        and     #$0f                            
        beq     SETIONO                         ; branch if zero
        tax                                     ; save to X
        jsr     CHRGET                          ; get next char
        beq     L8ae2                           ; 
        bcc     L8ad2
L8acf:  jmp     SNERR                           ; syntax error
-----------------------------------
L8ad2:  pha
        jsr     CHRGET
        bne     L8acf
        pla
        and     #$0f
        cpx     #$01
        bne     L8acf
        adc     #$09
        tax
L8ae2:  cpx     #$04
        bcc     L8acf
        cpx     #$10
        bcs     L8acf
        stx     IONO
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; -- $8AF0 read chanel 15 ">" ------------------
; ----------------------------------------------
RDCH15: ldy     #$01
        lda     ($7a),y
        bne     L8b0d
        jsr     L89b6
        jsr     L8b5d
        jsr     IECIN
        pha
        jsr     UNTALK
        pla
        jsr     HEXOUT
        jsr     CRDO
        jmp     READY                           ; go handle error message
-----------------------------------
L8b0d:  jsr     L89ab
        jsr     L8b6a
        jmp     READY                           ; go handle error message
; ----------------------------------------------
; - $8B16 read disk channel --------------------
; ----------------------------------------------
RDDCH:  ldy     #$01
        lda     ($7a),y
        bne     L8b0d
L8b1c:  jsr     L8b22
        jmp     READY                           ; go handle error message
-----------------------------------
L8b22:  jsr     L89b6
        jsr     L8b5d
        ldy     #$00
L8b2a:  jsr     IECIN
        sta     $0100,y
        cmp     #$0d
        beq     L8b3e
        iny
        lda     $90
        beq     L8b2a
        lda     #$0d
        sta     $0100,y
L8b3e:  jsr     UNTALK
        jsr     CRDO
        ldy     #$00
L8b46:  lda     $0100,y
        jsr     CHROUT
        iny
        cmp     #$0d
        bne     L8b46
        rts
-----------------------------------
        jsr     L8b5c
        jsr     CHROUT
        lda     #$6f
        sta     $b9
L8b5c:  rts
-----------------------------------
L8b5d:  lda     $ba
        jsr     TALK
        lda     #$6f
        sta     $b9
        jmp     TKSA
-----------------------------------
        rts
-----------------------------------
L8b6a:  lda     $ba
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
L8b7e:  stx     $0135
L8b81:  jsr     L8ca7
; ----------------------------------------------
; ----- check monitor commands: ----------------
; ----------------------------------------------
        jsr     GETIN
        ldx     #$02
        cmp     #$2f                            ; "/" modify data
        beq     L8b7e
        dex
        dex
        cmp     #$2b                            ; "+" modify address
        beq     L8b7e
        cmp     #$5d                            ; "]" output to screen
        beq     L8bb3
        cmp     #$3e                            ; ">" computer memory
        beq     L8ba0
        dex
        cmp     #$3c                            ; "<" floppy memory
        bne     L8ba6
L8ba0:  stx     $0133
        jsr     L8c9c
L8ba6:  cmp     #$2a                            ; "*" run
        bne     L8baf
        jsr     L8d1b
        lda     #$00
L8baf:  cmp     #$5b                            ; "[" output to printer
        bne     L8bb8
L8bb3:  stx     $0134
        beq     L8b81
L8bb8:  cmp     #$0d                            ; "RETURN" inc address
        bne     L8bbf
        jsr     L8c8d
L8bbf:  cmp     #$5e                            ; "^" dec address"
        bne     L8bce
        ldx     $fb
        bne     L8bc9
        dec     $fc
L8bc9:  dec     $fb
        jsr     L8c9c
L8bce:  cmp     #$20                            ; " " dissasemble continous
        bne     L8bd5
        jsr     L8d28
L8bd5:  cmp     #$2d                            ; "-" dissasemble 1 line
        bne     L8bdc
        jsr     L8d57
L8bdc:  cmp     #$40                            ; "@" transfer
        bne     L8be5
        jsr     L8c1f
        lda     #$00
L8be5:  cmp     #$3d                            ; "=" exit monitor
        bne     L8bec
        jmp     READY                           ; go handle error message
-----------------------------------
L8bec:  jsr     $007c
        jsr     L88c3
        bcs     L8c1c
        ldx     $0135
L8bf7:  rol
        rol     $fb,x
        rol     $fc,x
        dey
        bne     L8bf7
        txa
        beq     L8c0c
        ldx     $0133
        beq     L8c18
        ldx     #$57
        jsr     L8cc9
L8c0c:  ldx     $0133
        beq     L8c1c
        ldx     #$52
        jsr     L8cc9
        beq     L8c1c
L8c18:  lda     $fd
        sta     ($fb),y
L8c1c:  jmp     L8b81
-----------------------------------
L8c1f:  ldx     $fb
        stx     $26
        lda     $fc
        sta     $27
        cmp     $23
        bne     L8c2d
        cpx     $22
L8c2d:  bcc     L8c6d
        beq     L8c6d
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
L8c47:  lda     $24
        bne     L8c4d
        dec     $25
L8c4d:  dec     $24
        lda     $26
        bne     L8c55
        dec     $27
L8c55:  dec     $26
        lda     $25
        cmp     $23
        bne     L8c61
        lda     $24
        cmp     $22
L8c61:  bcc     L8c6c
        ldy     #$00
        lda     ($24),y
        sta     ($26),y
        tya
        beq     L8c47
L8c6c:  rts
-----------------------------------
L8c6d:  lda     $23
        cmp     $25
        bne     L8c77
        lda     $22
        cmp     $24
L8c77:  bcs     L8c6c
        ldy     #$00
        lda     ($22),y
        sta     ($26),y
        inc     $22
        bne     L8c85
        inc     $23
L8c85:  inc     $26
        bne     L8c6d
        inc     $27
        bne     L8c6d
L8c8d:  jsr     CRDO
L8c90:  inc     $fb
        bne     L8c96
        inc     $fc
L8c96:  ldy     #$00
        lda     ($fb),y
        sta     $fd
L8c9c:  lda     $0133
        beq     L8ca6
        ldx     #$52
        jsr     L8cc9
L8ca6:  rts
-----------------------------------
L8ca7:  ldy     #$00
        sty     $d3
        ldx     $0133
        bne     L8cb4
        lda     ($fb),y
        sta     $fd
L8cb4:  lda     $fc
        jsr     HEXOUT
        lda     $fb
        jsr     HEXOUT
        jsr     L88bb
        lda     $fd
        jsr     HEXOUT
        jmp     L88be
-----------------------------------
L8cc9:  lda     IONO
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
        bne     L8cfe
        lda     #$01
        jsr     CIOUT
        lda     $fd
        jsr     CIOUT
L8cfe:  jsr     UNLSN
        cpx     #$52
        bne     L8d18
        lda     IONO
        jsr     TALK
        lda     $b9
        jsr     TKSA
        jsr     IECIN
        sta     $fd
        jsr     UNTALK
L8d18:  lda     #$00
        rts
-----------------------------------
L8d1b:  ldx     $0133
        beq     L8d25
        ldx     #$45
        jmp     L8cc9
-----------------------------------
L8d25:  jmp     ($00fb)
-----------------------------------
L8d28:  jsr     STOPT
        bne     L8d2e
        rts
-----------------------------------
L8d2e:  lda     $028e
        cmp     #$01
        beq     L8d28
        jsr     L8d57
        jmp     L8d28
-----------------------------------
L8d3b:  jsr     CLRCHN
        jsr     L8c90
L8d41:  bit     $0134
        bpl     L8d56
        lda     #$04
        sta     $9a
        sta     $ba
        jsr     LISTN
        lda     #$ff
        sta     $b9
        jmp     $edbe
-----------------------------------
L8d56:  rts
-----------------------------------
L8d57:  jsr     L8d41
        jsr     L8ca7
        lda     $fd
        tay
        lsr
        bcc     L8d6e
        lsr
        bcs     L8d7d
        cmp     #$22
        beq     L8d7d
        and     #$07
        ora     #$80
L8d6e:  lsr
        tax
        lda     L8e5c,x
        bcs     L8d79
        lsr
        lsr
        lsr
        lsr
L8d79:  and     #$0f
        bne     L8d81
L8d7d:  lda     #$00
        ldy     #$80
L8d81:  tax
        lda     L8ea0,x
        sta     $0113
        and     #$03
        sta     $0112
        tya
        and     #$8f
        tax
        tya
        ldy     #$03
        cpx     #$8a
        beq     L8da3
L8d98:  lsr
        bcc     L8da3
        lsr
L8d9c:  lsr
        ora     #$20
        dey
        bne     L8d9c
        iny
L8da3:  tax
        dey
        bne     L8d98
        lda     L8eba,x
        sta     $0110
        lda     L8efa,x
        sta     $0111
        ldx     #$00
L8db5:  stx     $0114
        cpx     $0112
        bcc     L8dc2
        jsr     L88bb
        bne     L8dcf
L8dc2:  jsr     L8d3b
        lda     $fd
        ldx     $0114
        sta     $fe,x
        jsr     HEXOUT
L8dcf:  jsr     L88be
        ldx     $0114
        inx
        cpx     #$03
        bne     L8db5
L8dda:  lda     #$00
        ldy     #$05
L8dde:  asl     $0111
        rol     $0110
        rol
        dey
        bne     L8dde
        ora     #$40
        cmp     #$40
        bne     L8df0
        lda     #$2a
L8df0:  jsr     CHROUT
        dex
        bne     L8dda
        jsr     L88bb
        ldx     #$06
L8dfb:  cpx     #$04
        bne     L8e22
        lda     $0111
        bne     L8e07
        jsr     L88be
L8e07:  ldy     $0112
        beq     L8e22
        lda     $0113
        cmp     #$84
        bcs     L8e44
L8e13:  lda     $00fd,y
        stx     $0114
        jsr     HEXOUT
        ldx     $0114
        dey
        bne     L8e13
L8e22:  asl     $0113
        bcc     L8e38
        inc     $0111
        lda     L8ead,x
        jsr     CHROUT
        lda     L8eb3,x
        beq     L8e38
        jsr     CHROUT
L8e38:  dex
        bne     L8dfb
L8e3b:  jsr     CRDO
        jsr     L8d3b
        jmp     CLRCHN
-----------------------------------
L8e44:  ldx     $fc
        lda     $fe
        bpl     L8e4b
        dex
L8e4b:  adc     $fb
        bcc     L8e50
        inx
L8e50:  tay
        txa
        jsr     HEXOUT
        tya
        jsr     HEXOUT
        jmp     L8e3b
-----------------------------------
L8e5c   !by     $40,$02,$45,$03,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $30,$22,$45,$33,$d0,$08,$40,$09 ; 0"e3P.@.
        !by     $40,$02,$45,$33,$d0,$08,$40,$09 ; @.e3P.@.
        !by     $40,$02,$45,$b3,$d0,$08,$40,$09 ; @.e.P.@.
        !by     $00,$22,$44,$33,$d0,$8c,$44,$00 ; ."d3P.d.
        !by     $11,$22,$44,$33,$d0,$8c,$44,$9a ; ."d3P.d.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $10,$22,$44,$33,$d0,$08,$40,$09 ; ."d3P.@.
        !by     $62,$13,$78,$a9 
L8ea0:  !by     $00,$41,$01,$02,$00,$20,$99,$8d
        !by     $11,$12,$06,$8a,$05
L8ead:  !by     $21,$2c,$29,$2c,$41,$23
L8eb3:  !by     $28,$59,$00,$58,$00,$00,$00   
L8eba:  !by     $14,$82,$14,$1b,$54,$83,$13,$99
        !by     $95,$82,$15,$1b,$95,$83,$15,$99
        !by     $00,$21,$10,$a6,$61,$a0,$10,$1b
        !by     $1c,$4b,$13,$1b,$1c,$4b,$11,$99
        !by     $00,$12,$53,$53,$9d,$61,$1c,$1c
        !by     $a6,$a6,$a0,$a4,$21,$00,$73,$00
        !by     $0c,$93,$64,$93,$9d,$61,$21,$4b
        !by     $7c,$0b,$2b,$09,$9d,$61,$1b,$98

L8efa:  !by     $96,$20,$18,$06,$e4,$20,$52,$46
        !by     $12,$02,$86,$12,$26,$02,$a6,$52
        !by     $00,$72,$c6,$42,$32,$72,$e6,$2c
        !by     $32,$b2,$8a,$08,$30,$b0,$62,$48
        !by     $00,$68,$60,$60,$32,$32,$32,$30
        !by     $02,$26,$70,$f0,$70,$00,$e0,$00
        !by     $d8,$d8,$e4,$e4,$30,$30,$46,$86
        !by     $82,$88,$e4,$06,$02,$02,$60,$86   

; - $8F3A  module information message ---------- 
SCNMSG: !by     $0d,$0d,$20,$2a,$50,$52,$49,$4e ; .. *prin   
        !by     $54,$2d,$54,$45,$43,$48,$4e,$49 ; t-techni
        !by     $4b,$2d,$48,$45,$4c,$50,$2d,$50 ; k-help-p
        !by     $4c,$55,$53,$2a,$0d,$00         ; lus*.
; - $8F58  overwrite message text --------------
OVWTXT: !by     $0d,$4f,$56,$45,$52,$57,$52,$49 ; .overwri
        !by     $54,$45,$3f,$20,$12,$4a,$92,$41 ; te? .j.a
        !by     $2f,$12,$4e,$92,$45,$49,$4e,$0d ; /.n.ein.
        !by     $00 
; - $8F71  DOS and monitor commands char -------
DMCHAR: !by     $3e,$40,$3c,$2f,$5e,$24,$5d,$23 ; >@</^$]#
        !by     $21,$5f,$2a,$2b,$2d,$28,$29,$25 ; !_*+-()%
        !by     $5c,$5b                         ; £[
; - $8F83  commands low byte -------------------
DMLBYT: !by     <RDCH15,<RDDCH,<VERIFY,<LDREL,<LDRUN,<LDDIR,<MONI,<BASCMD
        !by     <CONVERT,<SAVEPRG,<PRTFRE,<UPCASE,<LOWCASE,<OPNFILE,<CLFILE,<LDABS
        !by     <SETIONO,<ASSEMBLER
; - $8F95  commands high byte ------------------
DMHBYT: !by     >RDCH15,>RDDCH,>VERIFY,>LDREL,>LDRUN,>LDDIR,>MONI,>BASCMD
        !by     >CONVERT,>SAVEPRG,>PRTFRE,>UPCASE,>LOWCASE,>OPNFILE,>CLFILE,>LDABS
        !by     >SETIONO,>ASSEMBLER

; - #8FA7  basic commands char -----------------
BCCHAR: !by     $41,$44,$45,$46,$47,$48,$4b,$4c ; adefghkl
        !by     $4d,$52,$53,$54,$56,$55,$43,$42 ; mrstvucb
; - #8FB7  basic commands low byte -------------
BCLBYT: !by     <APPEND,<DELETE,<ENDTRACE,<FIND,<GENLINE,<HELP,<KILL,<LPAGE
        !by     <M_DUMP,<RENUMBER,<S_STEP,<TRACE,<V_DUMP,<UNDEF,<COMPACTOR,<RENEW
; - $8FC7  basic commands high byte ------------
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
        lda     #<L9b98
        ldy     #>L9b98
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
L902c:  lda     #<L9baa
        ldy     #>L9baa
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
L9058:  lda     #<L9bbc
        ldy     #>L9bbc
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
L9102:  lda     #<L9bce
        ldy     #>L9bce
        jsr     $ab1e
        lda     $32
        ldx     $31
        jsr     INTOUT
        lda     #<L9bd6
        ldy     #>L9bd6
        jsr     $ab1e
        lda     $30
        ldx     $2f
        jsr     INTOUT
        lda     #<L9be2
        ldy     #>L9be2
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
        ldy     #>L9b69
        lda     #<L9b69
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
L9291:  jsr     L99f3
        jsr     L99ee
        ldy     #$00
L9299:  cpy     $4d
        bcs     L92a6
        lda     $004e,y
        jsr     L99fa
        jmp     L92a9
-----------------------------------
L92a6:  jsr     L99eb
L92a9:  jsr     L99ee
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
        lda     #<L9bed
        ldy     #>L9bed
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
        ldy     #>L9b58
        lda     #<L9b58
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
L93fb:  lda     L9b81,x
        cmp     $0140,y
        bne     L940c
        iny
        inx
        cpx     #$03
        bne     L93fb
        inc     $29
        rts
-----------------------------------
L940c:  lda     L9b84,x
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
        bne     L9430
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
L9445:  lda     L9b8c,x
        cmp     $0140,y
        bne     L9457
        iny
        inx
        cpx     #$04
        bne     L9445
        lda     #$3f
        bne     L941c
L9457:  lda     L9b88,x
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
L9471:  lda     L9b90,x
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
L949a:  lda     L9b94,x
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
L94b2:  lda     #<L9b44
        ldy     #>L9b44
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
L94d2:  lda     #<L9b0f
        ldy     #>L9b0f
        bne     L94e1
L94d8:  lda     $6a
        bne     L94dd
        rts
-----------------------------------
L94dd:  lda     #<L9b16
        ldy     #>L9b16
L94e1:  sty     $63
        sta     $62
        stx     $28
        cmp     #$58
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
L9510:  lda     L9b7a,y
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
        jsr     L9996
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
L97c2:  lda     #<L9b34
        ldy     #>L9b34
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
        lda     #<L9b25
        ldy     #>L9b25
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
        lda     $9ab8,y
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
        jsr     FLOATC
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
L9988:  jsr     L998e
        bcs     L9993
L998d:  rts
-----------------------------------
L998e:  jsr     $f3d5
        bcc     L998d
L9993:  jmp     EREXIT
-----------------------------------
L9996:  ldy     #$02
L9998:  lda     $0110,y
        sta     $0024,y
        and     #$40
        beq     L99c4
        dey
        bpl     L9998
        lda     $26
        asl
        asl
        asl
        ldx     #$03
L99ac:  asl
        rol     $25
        dex
        bpl     L99ac
        rol     $24
        cpx     #$fd
        bne     L99ac
        ldy     #$37
L99ba:  lda     $24
        cmp     L9a10,y
        beq     L99c7
L99c1:  dey
        bpl     L99ba
L99c4:  lda     #$00
        rts
-----------------------------------
L99c7:  lda     $25
        cmp     L9a48,y
        bne     L99c1
        lda     L9a80,y
        ldx     #$05
        cpy     #$1f
        bcs     L99e7
        dex
        cpy     #$16
        bcs     L99e7
        dex
        cpy     #$0e
        bcs     L99e7
        dex
        cpy     #$08
        bcs     L99e7
        dex
L99e7:  sta     $4b
        txa
        rts
-----------------------------------
L99eb:  jsr     L99ee
L99ee:  lda     #$20
        jmp     CHROUT
-----------------------------------
L99f3:  lda     $fc
        jsr     L99fa
        lda     $fb
L99fa:  pha
        lsr
        lsr
        lsr
        lsr
        jsr     L9a03
        pla
L9a03:  and     #$0f
        ora     #$30
        cmp     #$3a
        bcc     L9a0d
        adc     #$06
L9a0d:  jmp     CHROUT
-----------------------------------
L9a10:  !by     $09,$0b,$1b,$2b,$61,$7c,$98,$9d
        !by     $0c,$21,$4b,$64,$93,$93,$10,$10
        !by     $11,$13,$13,$14,$15,$15,$12,$1c
        !by     $1c,$53,$54,$61,$61,$9d,$9d,$14
        !by     $1b,$1b,$1b,$1b,$21,$21,$4b,$4b
        !by     $73,$82,$82,$83,$83,$95,$95,$99
        !by     $99,$99,$a0,$a0,$a4,$a6,$a6,$a6
L9a48:  !by     $06,$88,$60,$e4,$02,$82,$86,$02
        !by     $d8,$46,$86,$e4,$d8,$e4,$c6,$e6
        !by     $62,$52,$8a,$18,$86,$a6,$68,$30
        !by     $32,$60,$e4,$30,$32,$30,$32,$96
        !by     $06,$08,$12,$2c,$70,$72,$b0,$b2
        !by     $e0,$02,$20,$02,$20,$12,$26,$46
        !by     $48,$52,$70,$72,$f0,$02,$26,$42
L9a80:  !by     $61,$21,$c1,$41,$a1,$01,$e1,$81
        !by     $02,$c2,$e2,$42,$22,$62,$90,$b0
        !by     $f0,$30,$d0,$10,$50,$70,$00,$1e
        !by     $28,$0a,$14,$32,$3c,$46,$50,$00
        !by     $18,$d8,$58,$b8,$ca,$88,$e8,$c8
        !by     $ea,$48,$08,$68,$28,$40,$60,$38
        !by     $f8,$78,$aa,$a8,$ba,$8a,$9a,$98
L9ab8:  !by     $00,$24,$00,$2c,$00,$00,$00,$00
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

L9b0f:  !by     $53,$59,$4e,$54,$41,$58,$00     ; syntax.

L9b16:  !by     $4f,$4e,$45,$20,$42,$59,$54,$45 ; one byte
        !by     $20,$52,$41,$4e,$47,$45,$00     ;  range.

L9b25:  !by     $52,$45,$4c,$41,$54,$49,$56,$20 ; relativ 
        !by     $42,$52,$41,$4e,$43,$48,$00     ; branch.

L9b34:  !by     $49,$4c,$4c,$45,$47,$41,$4c,$20 ; illegal 
        !by     $4f,$50,$45,$52,$41,$4e,$44,$00 ; operand.

L9b44:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$44,$49,$52,$45,$43,$54 ; e direct
        !by     $49,$56,$45,$00                 ; ive.

L9b58:  !by     $44,$55,$50,$4c,$49,$43,$41,$54 ; duplicat
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00

L9b69:  !by     $55,$4e,$44,$45,$46,$49,$4e,$44 ; undefind
        !by     $45,$20,$53,$59,$4d,$42,$4f,$4c ; e symbol
        !by     $00                             ; .
                                      
L9b7a:  !by     $20,$45,$52,$52,$4f,$52,$00     ;  error.
L9b81:  !by     $45,$4e,$44                     ; end
L9b84:  !by     $54,$45,$58,$54                 ; text
L9b88:  !by     $57,$4f,$52,$54                 ; wort
L9b8c:  !by     $44,$49,$53,$50                 ; disp
L9b90:  !by     $42,$59,$54,$45                 ; byte
L9b94:  !by     $4c,$4f,$41,$44                 ; load
L9b98:  !by     $0d,$50,$52,$4f,$47,$52,$41,$4d ; .program
        !by     $4d,$4e,$41,$4d,$45,$20,$20,$3a ; mname  :
        !by     $20,$00                         ;  . 
L9baa:  !by     $0d,$48,$45,$58,$41,$20         ; .hexa
        !by     $4b,$4f,$52,$52,$2d,$50,$4f,$4b ; korr-pok
        !by     $45,$3a,$20,$00                 ; e: .
L9bbc:  !by     $0d,$41,$55,$53,$44,$52,$55,$43 ; .ausdruc
        !by     $4b,$2d,$43,$4f,$44,$45,$20,$3a ; k-code :
        !by     $20,$00                         ;  .
L9bce:  !by     $5a,$45,$49,$4c,$45,$4e,$3a,$00 ; .zeilen:.
L9bd6:  !by     $20,$20,$20,$53,$59,$4d,$42,$4f ;    symbo
        !by     $4c,$45,$3a,$00                 ; le:.
L9be2:  !by     $20,$20,$20,$46,$45,$48,$4c,$45 ;    fehle
        !by     $52,$3a,$00                     ; r:.
L9bed:  !by     $53,$45,$49,$54,$45,$3a,$00     ; seite:.

FILL3:  !fi     $9c00-FILL3, $00

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

