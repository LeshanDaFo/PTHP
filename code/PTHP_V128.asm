; ###############################################################
; #                                                             #
; #  Print Technik Help Plus V128 source code                   #
; #  Version 1.2 (2023.03.16)                                   #
; #  Copyright (c) 2023 Claus Schlereth                         #
; #                                                             #
; #  This source code is based on the basic extension modul     #
; #  from the company Print-Technik                             #
; #                                                             #
; #  This source is available at:                               #
; #  https://github.com/LeshanDaFo/PTHP                         #
; #                                                             #
; #  Special thanks goes to Johann Klasek who has supported me  #
; #  to make this source possible and contributed to it.        #
; #                                                             #
; #  This version of the source code is under MIT License       #
; ###############################################################

CHRGET          = $0073
CHRGOT          = $0079

IONO            = $0131

INLIN           = $A560                         ; call for BASIC input and return
CRUNCH          = $A579                         ; crunch keywords into BASIC tokens
CLEARC          = $A660
STXTP           = $A68E
CRDO            = $AAD7                         ; ;PRINT CRLF TO START WITH
STROUT          = $AB1E
FRMNUM          = $AD8A                         ; evaluate expression and check is numeric, else do type mismatch
ERRFC           = $B248                         ; illegal quantity error
GETADR          = $B7F7                         ; convert FAC_1 to integer in temporary integer
FLOATC          = $BC49                         ; FLOAT UNSIGNED VALUE IN FAC+1,2
INTOUT          = $BDCD                         ; Output Positive Integer in A/X
INTOUT1         = $BDD1                         ; Output Positive Integer in A/X
FLPSTR          = $BDDD                         ; Convert FAC#1 to ASCII String
EREXIT          = $E0F9                         ; Error exit
SCATN           = $EDBE                         ; set serial ATN high
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
LOAD            = $FFD5                         ; Load Vector
SAVE            = $FFD8                         ; Save Vector
STOP            = $FFE1                         ; Test STOP Vector
NMI             = $FE5E                         ; NMI after found Modul
GETIN           = $FFE4                         ; Vector: Kernal GETIN Routine

!to"build/PTHP-128.crt",plain
        *=$8000                                 ; Modul sytart address

        !byte   <reset, >reset                  ; $8000 RESET-Vector 
        !byte   <NMI, >NMI                      ; $8002 NMI-Vector   
        !pet  $c3, $c2, $cd,"80"                ; $8004 CBM80

reset:
        LDX #$05 
        STX $D016
        JSR $FDA3                               ; initialise SID, CIA and IRQ
        LDA #$50                                ; RAM test and find RAM end
        LDY #$FD                                ;
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        JSR $FD15                               ; set Ram end and restore default I/O vectors
        JSR $FF5B                               ; initialise VIC and screen editor, set own colors
        CLI
        JSR $E453                               ; initialise the BASIC vector table
        JSR $E3BF                               ; initialise the BASIC RAM locations
        JSR $E422                               ; print the start up message and initialise the memory pointers
        LDX #$FB                                ; set x for stack
        TXS                                     ; set stack
L802B   JSR L8031                               ; initialize the Modul, and print the message
        JMP L84A7                               ; basic cold start
--------------------------------- 
L8031   LDX #$00 
        STX $0132
        LDA #$08 
        STA $0131
        LDA #<L9D39                             ; message address low byte
        LDY #>L9D39                             ; message address high byte
        JSR STROUT                              ; print message
; patch basic warm start
        LDA #<LDE20                             ; new BASIC warm start low byte
        LDX #>LDE20                             ; new BASIC warm start high byte
        BNE L804C                               ; 'jmp' set vector
; restore basic warm start values
L8048   LDA #$83                                ; old BASIC warm start low byte
        LDX #$A4                                ; old BASIC warm start low high
L804C   STA $0302                               ; set vector low byte
        STX $0303                               ; set vector high byte
        RTS
--------------------------------- 
L8053   JSR INLIN
        STX $7A
        STY $7B
        JSR CHRGET
        TAX
        BEQ L8053
        BCC L808B
        LDX #$00 
        STX $0132
        LDX #$0F 
L8069   CMP L9D94,X                             ; DOS and monitor commands char
        BEQ L8076
        DEX
        BPL L8069
L8071   STX $3A
        JMP LDE28                               ; go crunch and interpret
--------------------------------- 
L8076   LDA DMLBYT,x                            ; DOS and monitor commands low byte
        STA $55
        LDA DMHBYT,x                            ; DOS and monitor commands high byte
        STA $56
        JMP ($0055)                             ; execute command
; - $8083  basic command GENLINE --------------- 
GENLINE:
        JSR L83E2
        LDA #$80 
        STA $0132
L808B   BIT $0132
        BPL L80BD
        LDA $0133
        LDY $0134
        JSR L80DD
        LDY #$00 
L809B   LDA $0100,Y
        BEQ L80A6
        STA $0277,Y
        INY
        BNE L809B
L80A6   LDA #$20 
        STA $0277,Y
        INY
        STY $C6
        LDA $0133
        LDY $0134
        JSR L80CF
        STA $0133
        STY $0134
L80BD   LDX #$FF 
        STX $3A
        JSR CHRGOT
        BCS L8053
        LDY #$9C 
        STY $55
        LDY #$A4 				; handle new BASIC line
        JMP LDE16				; JMP $A49C with module off
--------------------------------- 
L80CF   CLC
        ADC $0135
        BCC L80DC
        INY
        CPY #$FA 
        BCC L80DC
        LDY #$00 
L80DC   RTS
--------------------------------- 
L80DD   STA $63
        STY $62
L80E1   LDX #$90 
        SEC
        JSR FLOATC
        JMP FLPSTR
; - #80EA  basic commands call ----------------- 
BASCMD:  LDY     #$01 
        LDA ($7A),Y
        LDX #$0F 
L80F0   CMP L9DC4,X                             ; basic command char tabl
        BEQ L80FB
        DEX
        BPL L80F0
        JMP L8071
--------------------------------- 
L80FB   LDA L9DD4,X                             ; basic command low byte table
        STA $55
        LDA L9DE4,X                             ; basic command high byte table
        STA $56
        INC $7A
        JMP ($0055)                             ; execute command
; ----------------------------------------------
; - #810A  Matrix and Variable dump ------------
; ------- start $81B1 and $8274 ----------------
; ----------------------------------------------
L810A   JSR STOP 				; stop pressed?
        BEQ L8116
        LDA $028E
        CMP #$01 				; shift pressed?
        BEQ L810A				; wait until shift released
L8116   RTS
---------------------------------
L8117   JSR L810A				; check for break and wait
        BNE L8116				; end wait
        LDA #$49 				; breaking with stop key
        LDY #$A8 				; $A849 print 'break' and warmstart
        JMP LDE14				; setup $55/$56 and JMP ($55) with module off
---------------------------------
L8123   JSR CRDO
        JSR L8117				; break or wait
        LDY #$00 
        JSR LDE32				; LDA ($45),Y with module off
        TAX
        BPL L8138
        INY
        JSR LDE32				; LDA ($45),Y with module off
        BMI L8138
        RTS
--------------------------------- 
L8138   LDY #$00 
        JSR LDE32				; LDA ($45),Y with module off
        AND #$7F 
        JSR CHROUT
        INY
        JSR LDE32				; LDA ($45),Y with module off
        TAY
        AND #$7F 
        BEQ L814E
        JSR CHROUT
L814E   TXA
        BPL L8155
        LDA #$25 
        BNE L815A
L8155   TYA
        BPL L815D
        LDA #$24 
L815A   JSR CHROUT
L815D   RTS
--------------------------------- 
L815E   JSR CHROUT
L8161   JSR L8857
        LDA #$3D 
        JMP CHROUT
--------------------------------- 
L8169   LDY #$00 
        JSR LDE44				; LDA ($22),Y with module off
        TAX
        INY
        JSR LDE44				; LDA ($22),Y with module off
        TAY
        TXA
        JSR $B395
        LDY #$01 
        JMP $BDD7
--------------------------------- 
L817D   LDA #$A6 
        LDY #$BB 
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        LDY #$01 
        JMP $BDD7
--------------------------------- 
L8189   JSR L81AC
        LDY #$02 
        JSR LDE44				; LDA ($22),Y with module off
        STA $60
        DEY
        JSR LDE44				; LDA ($22),Y with module off
        STA $5F
        DEY
        JSR LDE44				; LDA ($22),Y with module off
        STA $26
        BEQ L81AC
L81A1   JSR LDE00				; LDA ($5F),Y with module off
        JSR CHROUT
        INY
        CPY $26
        BNE L81A1
L81AC   LDA #$22 
        JMP CHROUT
; - $81B1  basic command MATRIX DUMP -----------
M_DUMP: LDX $30
        LDA $2F
L81B5   STA $45
        STX $46
        CPX $32
        BNE L81BF
        CMP $31
L81BF   BCC L81C4
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L81C4   LDY #$04 
        ADC #$05 
        BCC L81CB
        INX
L81CB   STA $0B
        STX $0C
        JSR LDE32				; LDA ($45),Y with module off
        ASL
        TAY
        ADC $0B
        BCC L81D9
        INX
L81D9   STA $FB
        STX $FC
        DEY
        STY $FE
        LDA #$00 
L81E2   STA $0205,Y
        DEY
        BPL L81E2
        BMI L821E
L81EA   LDY $FE
L81EC   DEY
        STY $FD
        TYA
        TAX
        INC $0206,X
        BNE L81F9
        INC $0205,X
L81F9   LDA $0205,Y
        JSR LDE4D				; LDA ($0B),Y with module off
        BNE L8208
        INY
        LDA $0205,Y
        JSR LDE4D				; LDA ($0B),Y with module off
L8208   BCC L821E
        LDA #$00 
        LDY $FD
        STA $0205,Y
        STA $0206,Y
        DEY
        BPL L81EC
        LDA $FB
        LDX $FC
        JMP L81B5
--------------------------------- 
L821E   JSR L8123
        LDY $FE
        LDA #$28 
L8225   JSR CHROUT
        LDA $0204,Y
        LDX $0205,Y
        STY $FD
        JSR INTOUT
        LDA #$2C 
        LDY $FD
        DEY
        DEY
        BPL L8225
        LDA #$29 
        JSR L815E
        LDA $FB
        LDX $FC
        STA $22
        STX $23
        LDY #$00 
        JSR LDE32				; LDA ($45),Y with module off
        BPL L8256
        JSR L8169
        LDA #$02 
        BNE L8268
L8256   INY
        JSR LDE32				; LDA ($45),Y with module off
        BMI L8263
        JSR L817D
        LDA #$05 
        BNE L8268
L8263   JSR L8189
        LDA #$03 
L8268   CLC
        ADC $FB
        STA $FB
        BCC L8271
        INC $FC
L8271   JMP L81EA
; - $8274  basic command VAR DUMP -------------- 
V_DUMP: LDA $2D
        LDY $2E
L8278   STA $45
        STY $46
        CPY $30
        BNE L8282
        CMP $2F
L8282   BCC L8287
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8287   ADC #$02 
        BCC L828C
        INY
L828C   STA $22
        STY $23
        JSR L8123
        TXA
        BPL L82A2
        TYA
        BPL L82B1
        JSR L8161
        JSR L8169
        JMP L82B1
--------------------------------- 
L82A2   JSR L8161
        TYA
        BMI L82AE
        JSR L817D
        JMP L82B1
--------------------------------- 
L82AE   JSR L8189
L82B1   LDA $45
        LDY $46
        CLC
        ADC #$07 
        BCC L8278
        INY
        BCS L8278
; ----------------------------------------------
; ------- Matrix and Variable dump end ---------
; ----------------------------------------------

; ----------------------------------------------
; - $82BD  basic command FIND ------------------
; ----------------------------------------------
FIND:   INC $7A
        JSR CRUNCH
        JSR LDE60				; next CHRGET with module off
        LDY #$00 
        CMP #$22 				; '"' string beginning?
        BNE L82CE
        DEY					; = $FF
        INC $7A
L82CE   STY $FE					; search in strings ($FF) or code ($00)
        LDA $2B					; BASIC start
        LDX $2C
L82D4   STX $23
        STA $22
        STA $5F
        STX $60
        JSR L8117				; break or wait
        LDA $028E				; last control key (not used)
        LDY #$00 
        STY $0F					; clear in-string flag
        INY					; = 0
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L82EF				; end of program?
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L82EF   LDA #$04 				; advance 4 bytes
        !by $2C					; BIT $HHLL: skip following instruction
L82F2   LDA #$01				; advance 1 byte
        CLC
        ADC $22
        STA $22
        BCC L82FD
        INC $23
L82FD   LDY #$00 
        JSR LDE44				; LDA ($22),Y with module off
        BEQ L8325
        CMP #$22 				; '"'
        BNE L830E
        LDA $0F
        EOR #$FF 
        STA $0F					; toggle in-string flag
L830E   LDA $0F
        CMP $FE					; in same area? (code/string)
        BNE L82F2				; skip if the other one
L8314   JSR LDE3B				; LDA ($7A),Y with module off
        BEQ L832B				; search string (empty?)
        STA $0B
        JSR LDE44				; LDA ($22),Y with module off
        CMP $0B					; match char?
        BNE L82F2				; advance in line
        INY					; next character
        BNE L8314				; branch always
L8325   LDA $22
        LDX $23
        BNE L8332
L832B   JSR L835B				; found, search string matched
        LDA $5F
        LDX $60
L8332  CLC
        ADC #$01 
        BCC L82D4				; next line
        INX
        BCS L82D4				; next line
; - $833A  basic command HELP ----------------
HELP:   LDA $3A
        STA $15
        LDA $39
        STA $14
        JSR L90C8
        BCC L8358
        LDA $3D
        ADC #$00 
        CMP $5F
        BNE L8351
        ADC #$03 
L8351   STA $0A
        LDA #$40 
        JSR L835D
L8358   JMP L848B				; check cartridge and warm start
--------------------------------- 
L835B   LDA #$00 
L835D   STA $0B
        JSR CRDO
        LDY #$02 
        STY $0F
        JSR LDE00				; LDA ($5F),Y with module off
        TAX
        INY
        JSR LDE00				; LDA ($5F),Y with module off
        JSR INTOUT
        JSR L8857
        LDA #$04 
        !by $2C					; BIT $HHLL: skip following instruction
L8377   LDA #$01
        CLC
        ADC $5F
        STA $5F
        BCC L8382
        INC $60
L8382   BIT $0B
        BVC L838E
        CMP $0A
        BNE L838E
        LDA #$01 
        STA $C7
L838E   LDY #$00 
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L8396
        RTS
--------------------------------- 
L8396   CMP #$3A 
        BNE L839C
        STY $C7
L839C   CMP #$22 
        BNE L83A8
        LDA $0F
        EOR #$FF 
        STA $0F
        LDA #$22 
L83A8   TAX
        BMI L83B3
L83AB   AND #$7F 
L83AD   JSR CHROUT
        JMP L8377
--------------------------------- 
L83B3   CMP #$FF 
        BEQ L83AD
        BIT $0F
        BMI L83AD
        LDY #$A0 
        STY $23
        LDY #$9E 
        STY $22
        LDY #$00 
        ASL
        BEQ L83D8
L83C8   DEX
        BPL L83D7
L83CB   INC $22
        BNE L83D1
        INC $23
L83D1   LDA ($22),Y
        BPL L83CB
        BMI L83C8
L83D7   INY
L83D8   LDA ($22),Y
        BMI L83AB
        JSR CHROUT
        INY
        BNE L83D8
L83E2   JSR LDE60				; next CHRGET with module off
        BNE L83EF
        LDX #$0A 
        LDY #$00 
        LDA #$64 
        BNE L8409
L83EF   LDA #$EB 
        LDY #$B7 				; $b7eb get parameter poke/wait
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        LDA $14
        LDY $15
        CPY #$FA 
        BCC L8405
L83FE   LDA #$08                                ; syntax error 
        LDY #$AF 
        JMP LDE14				; setup $55/$56 and JMP ($55) with module off
--------------------------------- 
L8405   CPX #$00 
        BEQ L83FE
L8409   STX $0135
        STA $0133
        STY $0134
        RTS
; ----------------------------------------------
; - $8413  basic command DELETE ----------------
; ----------------------------------------------
DELETE: JSR LDE60				; next CHRGET with module off
        BEQ L83FE
        BCC L841E
        CMP #$2D 
        BNE L83FE
L841E   JSR $A96B
        LDA #$13 
        LDY #$A6 				; $a613 search BASIC for temporary integer line number
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        JSR LDE66				; CHRGOT with module off
        BEQ L8439
        CMP #$2D 
        BNE L83EF
        JSR LDE60				; next CHRGET with module off
        JSR $A96B
        BNE L83FE
L8439   LDA $14
        ora $15
        BNE L8443
        LDA #$FF 
        STA $15
L8443   LDX $5F
        LDA $60
        STX $FB
        STA $FC
L844B   STX $22
        STA $23
        LDY #$01 
        JSR LDE44				; LDA ($22),Y with module off
        BEQ L8475
        INY
        JSR LDE44				; LDA ($22),Y with module off
        TAX
        INY
        JSR LDE44				; LDA ($22),Y with module off
        CMP $15
        BNE L8467
        CPX $14
        BEQ L8469
L8467   BCS L8475
L8469   LDY #$00 
        JSR LDE44				; LDA ($22),Y with module off
        TAX
        INY
        JSR LDE44				; LDA ($22),Y with module off
        BNE L844B
L8475   LDA $2D
        STA $24
        LDA $2E
        STA $25
        JSR L8BB8
        LDA $26
        STA $2D
        LDA $27
        STA $2E
        JMP L85A1
; - copy protection/module verification --------
L848B   BIT $A2                                 ; low jiffy clock byte, bit 7
        BPL L84A7                               ; only in a 2.13 seconds interval (128 1/60 jiffies)
        LDA #$CF                                ; high byte calculation base
L8491   LDY #$02                                ; upper index (to check 3 bytes)
        STY $22
        ASL                                     ; $9E, C=1
        STA $23
        ADC #$3F                                ; $9E
        STA $25                                 ; $DE
        STY $24                                 ; $02
L849E   LDA ($24),Y                             ; $DE04 ... $DE02
        CMP ($22),Y                             ; $9E04 ... $9E02
        BNE L8491+1                             ; illegal opcode $02: KIL (make C64 hang)
        DEY                                     ; check 3 bytes
        BPL L849E
L84A7   LDA #$86                                ; finishing up a command:
        LDY #$E3                                ; basic warm start
        JMP LDE14                               ; setup $55/$56 and JMP ($55) with module off
; ----------------------------------------------
; - $84AE  basic command KILL ------------------
; ----------------------------------------------
KILL:   JSR     L8048
; ----------------------------------------------
; - $8508  basic command END TRACE -------------
; ----------------------------------------------
ENDTRACE:
        LDA #$E4 
        LDX #$A7 				; $a7e4 standard BASIC interpreter loop entry
L84B5   STA $0308
        STX $0309
        JMP L848B				; check cartridge and warm start
; ----------------------------------------------
; - $84BE  basic command LIST PAGE -------------
; ----------------------------------------------
LPAGE:  JSR LDE60				; next CHRGET with module off
        JSR $A96B
        JSR L90C8
        JSR $ABB7
L84CA   LDA $5F
        STA $FD
        LDA $60
        STA $FE
        LDA #$93 
        JSR CHROUT
L84D7   LDX $5F
        LDY #$01 
        JSR LDE00				; LDA ($5F),Y with module off
        BEQ L84EF
        JSR L835B
        INC $5F
        BNE L84E9
        INC $60
L84E9   LDA $D6
        CMP #$16 
        BCC L84D7
L84EF   LDA #$17 
        STA $D6
        JSR CRDO
L84F6   JSR GETIN
        CMP #$03 
        BNE L8500
        JMP LDE20				; direct mode input basic line and execute
--------------------------------- 
L8500   CMP #$0D 
        BNE L850D
        LDY #$01 
        JSR LDE00				; LDA ($5F),Y with module off
        BEQ L84F6
        BNE L84CA
L850D   CMP #$5E 
        BNE L84F6
        JSR L8577
        BCS L84EF
        LDA #$93 
        JSR CHROUT
        LDA $FE
        PHA
        LDA $FD
        PHA
        LDX #$16 
L8523   STX $D6
        STX $FC
        LDA $FD
        STA $22
        LDA $FE
        STA $23
L852F   LDY #$00 
L8531   LDA $22
        BNE L8537
        DEC $23
L8537   DEC $22
        JSR LDE44				; LDA ($22),Y with module off
        BNE L8531
        INY
        JSR LDE44				; LDA ($22),Y with module off
        CMP $FD
        BNE L852F
        INY
        JSR LDE44				; LDA ($22),Y with module off
        CMP $FE
        BNE L852F
        LDX $22
        LDY $23
        INX
        BNE L8556
        INY
L8556   STX $FD
        STX $5F
        STY $FE
        STY $60
        JSR L835B
        JSR L8577
        BCC L856F
L8566   PLA
        STA $5F
        PLA
        STA $60
        JMP L84EF
--------------------------------- 
L856F   LDX $FC
        DEX
        DEX
        BPL L8523
        BMI L8566
L8577   LDA $2C
        CMP $FE
        BNE L8581
        LDA $2B
        CMP $FD
L8581   RTS
; ----------------------------------------------
; - $8582  basic command RENUMBER --------------
; ---------------------------------------------- 
RENUMBER:
        JSR L83E2
        JSR L8E8D
        JSR L8E83
L858B   JSR STXTP
        JSR L85CF
        LDA $2B
        LDX $2C
        STA $22
L8597   STX $23
        LDY #$01 
        JSR LDE44				; LDA ($22),Y with module off
        TAX
        BNE L85AA
L85A1   JSR L8E83
        JSR CLEARC
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L85AA   INY
        LDA $0133
        STA ($22),Y
        INY
        LDA $0134
        STA ($22),Y
        LDY #$00 
        JSR LDE44				; LDA ($22),Y with module off
        STA $22
        LDA $0133
        LDY $0134
        JSR L80CF
        STA $0133
        STY $0134
        JMP L8597
--------------------------------- 
L85CF   JSR L8FF9
L85D2   JSR LDE60				; next CHRGET with module off
L85D5   TAX
        BEQ L85CF
        JSR L9012
        BEQ L85F0
        TAX
        BEQ L85CF
        CMP #$22 
        BNE L85D2
L85E4   JSR LDE60				; next CHRGET with module off
        TAX
        BEQ L85CF
        CMP #$22 
        BNE L85E4
        BEQ L85D2
L85F0   LDA $7A
        STA $28
        LDA $7B
        STA $29
        JSR LDE60
        BCS L85D5
        LDY #$6B 
        STY $55
        LDY #$A9  				; $A96B get fixed-point number into temporary integer
        JSR LDE0B				; JMP $A96B with module off
        LDA $2B
        LDX $2C
        STA $22
        LDA $0133
        LDY $0134
L8612   STX $23
        STA $63
        STY $62
        LDY #$02 
        JSR LDE44				; LDA ($22),Y with module off
        CMP $14
        BEQ L8637
L8621   LDY #$01 
        JSR LDE44				; LDA ($22),Y with module off
        TAX
        DEY
        JSR LDE44				; LDA ($22),Y with module off
        STA $22
        LDA $63
        LDY $62
        JSR L80CF
        JMP L8612
--------------------------------- 
L8637   INY
        JSR LDE44				; LDA ($22),Y with module off
        CMP $15
        BNE L8621
        JSR L80E1
        LDA $28
        STA $7A
        LDA $29
        STA $7B
        LDX #$00 
L864C   LDA $0101,X
        BEQ L8670
        PHA
        JSR LDE60				; next CHRGET with module off
        BCC L8668
        LDA $2D
        STA $22
        LDA $2E
        STA $23
        INC $2D
        BNE L8665
        INC $2E
L8665   JSR LDE78				; copy ($22) one byte up until $7a/$7b with module off
L8668   PLA
        LDY #$00 
        STA ($7A),Y
        INX
        BNE L864C
L8670   JSR LDE60				; next CHRGET with module off
        BCS L868D
L8675   LDA $7A
        STA $22
        LDA $7B
        STA $23
        JSR LDEC3				; copy ($22) one byte down until $2d/$2e with module off
        LDA $2D
        BNE L8686
        DEC $2E
L8686   DEC $2D
        JSR LDE66				; CHRGOT with module off
        BCC L8675
L868D   PHA
        JSR L8E83
        PLA
        CMP #$2C 
        BNE L8699
        JMP L85F0
--------------------------------- 
L8699  JMP L85D5
; ----------------------------------------------
; - $879C  basic command SINGLE STEP -----------
; ----------------------------------------------
S_STEP: LDA #$00 
        !by $2C					; BIT $HHLL: skip following instruction
; ----------------------------------------------
; - $869F  basic command TRACE -----------------
; ----------------------------------------------
TRACE:  LDA #$80
        STA $0130				; trace flag
        LDA #<LDE98				; hook $0308/$0309
        LDX #>LDE98
        JMP L84B5
--------------------------------- 
L86AB   LDA $39
        LDX $3A
        CMP $0124
        BNE L86BC
        CPX $0125
        BNE L86BC
L86B9   JMP L878B
--------------------------------- 
L86BC   CPX #$FF 
        BNE L86C5
        STX $0125
        BEQ L86B9
L86C5   STA $0122
        STX $0123
        LDX #$0B 
L86CD   LDA $0122,X
        STA $0124,X
        DEX
        BPL L86CD
        LDA $D1
        PHA
        LDA $D2
        PHA
        LDA $D3
        PHA
        LDA $D6
        PHA
        LDA $0286
        PHA
        LDA #$13 
        JSR CHROUT
        LDX #$78 
L86ED   LDA #$20 
        JSR CHROUT
        DEX
        BNE L86ED
        LDA #$13 
        JSR CHROUT
        LDY #$00 
L86FC   TYA
        PHA
        LDA $0124,Y
        TAX
        LDA $0125,Y
        CMP #$FF 
        BEQ L871B
        JSR INTOUT
        LDA #$20 
        JSR CHROUT
        PLA
        TAY
        INY
        INY
        CPY #$0C 
        BCC L86FC
        BCS L871C
L871B   PLA
L871C   LDA $DA
        ORA #$80 
        STA $DA
        JSR CRDO
        LDX #$05 
        LDY #$00 
        STY $0F
        STY $0B
        LDA $3D
        STA $5F
        LDA $3E
        STA $60
        JSR LDE00				; LDA ($5F),Y with module off
        BEQ L873C
        LDX #$01 
L873C   TXA
        CLC
        ADC $5F
        STA $5F
        TYA
        ADC $60
        STA $60
        JSR L838E
        JSR CRDO
        BIT $0130				; trace flag set?
        BMI L8760
L8752   JSR STOP 
        BEQ L877B
        LDA $028E
        CMP #$01 
        BNE L8752
        BEQ L876B
L8760   LDA #$03 
        LDX $028E
        CPX #$01 
        BNE L876B
        LDA #$00 
L876B   STA $0122
        LDY #$78 
-       DEX
        BNE -
        DEY
        BNE -
        DEC $0122
        BPL -
L877B   PLA
        STA $0286
        PLA
        STA $D6
        PLA
        STA $D3
        PLA
        STA $D2
        PLA
        STA $D1
L878B   LDA #$E4                                ; execute statement
        LDY #$A7 
        JMP LDE14				; setup $55/$56 and JMP ($55) with module off
; ----------------------------------------------
; - #8801  basic command APPEND ----------------
; ----------------------------------------------
APPEND  INC $7A
        LDA #$D4 
        LDY #$E1 				; $e1d4 get parameters for LOAD/SAVE
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        LDX $2B					; BASIC start
        LDA $2C
L879F   STX $5F					; BASIC text pointer
        STA $60
        LDY #$00 
        JSR LDE00				; LDA ($5F),Y with module off
        TAX					; BASIC line link low
        INY					; BASIC line link high
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L879F				; not end of program
        LDY #<LOAD
        STY $55
        LDY #>LOAD
        STY $56
        LDY $60					; load address high
        LDX $5F					; load address low
        STA $0133
        STA $0A
        STA $B9					; secondary address
        JSR LDEE1				; do LOAD with module off
        JMP L88E4
; ----------------------------------------------
; - $88C8 -- print free memory -----------------
; ----------------------------------------------
PRTFRE: JSR $B526				; garbage collection
        SEC
        LDA $33					; bottom of string space
        SBC $31					; minus end of arrays
        TAX
        LDA $34
        SBC $32
        JSR INTOUT				; print free bytes as unsigned integer
        JMP L848B				; check cartridge and warm start
; ----------------------------------------------
; - $87DB -- close command and file ------------
; ---------------------------------------------- 
CLFILE: JSR CLRCHN
        LDA #$FF 
        JSR CLOSE
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L87E6   JSR LDE60				; next CHRGET with module off
        BEQ L87F2
        LDA #$9E 
        LDY #$B7 				; $b79e get byte parameter
        JMP LDE09                               ; set $55/$56 and JSR ($55) with module off
--------------------------------- 
L87F2   RTS
; ----------------------------------------------
; - $87F3 -- open file with cmd file -----------
; ---------------------------------------------- 
OPNFILE:
        LDX #$04 
        JSR L87E6
        STX $BA
        LDA #$FF 
        STA $B8
        STA $B9
        JSR OPEN
        LDX #$FF 
        JSR $E118
        JMP LDE20				; direct mode input basic line and execute
; ----------------------------------------------
; - $880B jump in for convert - "!$", "!#" -----
; ----------------------------------------------
CONVERT:
        JSR LDE60				; next CHRGET with module off
        CMP #$24 
        BNE L8825
; convert dec to hex ---------------------------
        JSR LDE60				; next CHRGET with module off
        JSR FRMNUM
        JSR GETADR
        JSR L9B2B
        TYA
        JSR L9B2B
        JMP L848B				; check cartridge and warm start
; - $888C - check for # ------------------------ 
L8825   CMP #$23 
        BEQ L882C
        JMP LDE20				; direct mode input basic line and execute
; - $8893 - convert hex to dec ----------------- 
L882C   LDA #$00 
        STA $62
        STA $63
        LDX #$05 
L8834   JSR LDE60				; next CHRGET with module off
        BEQ L884E
        DEX
        BNE L883F
L883C   JMP ERRFC
; - $883F -------------------------------------- 
L883F   JSR L885C
        BCS L883C
L8844   ROL
        ROL $63
        ROL $62
        DEY
        BNE L8844
        BEQ L8834
L884E   JSR INTOUT1
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8854   JSR L8857
L8857   LDA #$20 
        JMP CHROUT
--------------------------------- 
L885C   BCC L886A
        CMP #$41 
        BCS L8864
L8862   SEC
        RTS
--------------------------------- 
L8864   CMP #$47 
        BCS L8862
        SBC #$06 
L886A   LDY #$04 
        ASL
        ASL
        ASL
        ASL
        CLC
        RTS
; ----------------------------------------------
; - $8872 Save a programm ----------------------
; ---------------------------------------------- 
SAVEPRG:
        JSR L892D
L8875   LDX $2D
        LDY $2E
        LDA #$2B 
        JSR LDE70				; SAVE with module off
        BCC L8883
        JMP EREXIT
--------------------------------- 
L8883   JSR L8A78
        LDA $0100
        CMP #$36 
        BEQ L8890
L888D   JMP L848B				; check cartridge and warm start
--------------------------------- 
L8890   LDA $0101
        CMP #$33 
        BNE L888D
        LDA #<L9D7C 
        LDY #>L9D7C 
        JSR STROUT
L889E   JSR GETIN
        CMP #$4E				; "n"
        BEQ L888D
        CMP #$59				; 'y'
        BEQ L88AD
        CMP #$4A				; "j"
        BNE L889E
L88AD   LDA #$53				; "s"
        STA $01FF
        LDA #$3A				; ":"
        CMP $0202
        BNE L88BB
        LDA #$20 
L88BB   STA $0200
        LDA #$FF 
        STA $BB
        DEC $BC
        INC $B7
        INC $B7
        JSR L8AC0
        DEC $B7
        DEC $B7
        JSR L8945
        JMP L8875
; ----------------------------------------------
; - $88D5 load prg relative --------------------
; ----------------------------------------------
LDREL:  LDA #$00 
        !by $2C					; BIT $HHLL: skip following instruction
; ----------------------------------------------
; - $88D8 load and run prg relative ------------
; ----------------------------------------------
LDRUN:  LDA #$80
        STA $0133
        LDA #$00 
        STA $B9
L88E1   JSR L8957
L88E4   BCC L88E9
        JMP EREXIT
--------------------------------- 
L88E9   JSR $FFB7
        AND #$BF 
        BEQ L88F3
        JMP L8A72
--------------------------------- 
L88F3   STX $2D
        STY $2E
        BIT $0133
        BMI L8903
        LDA #$AB                                ; print 'ready'   
        LDY #$E1 
        JMP LDE14				; setup $55/$56 and JMP ($55) with module off
--------------------------------- 
L8903   JSR $A659
        JSR L8E83
        JSR STXTP
        LDA #$AE                                ; PERFORM NEXT STATEMENT 
        LDY #$A7 
        JMP LDE14				; setup $55/$56 and JMP ($55) with module off
; ----------------------------------------------
; - $8913 Verify "<" ---------------------------
; ---------------------------------------------- 
VERIFY: LDA #$00 
        STA $B9
        LDA #$01 
        JSR L8957
        JSR $E17E
        JMP L848B				; check cartridge and warm start
; ----------------------------------------------
; - $8922 load prg absolut ---------------------
; ---------------------------------------------- 
LDABS:  LDA #$01 
        STA $B9
        LDA #$00 
        STA $0133
        BEQ L88E1
L892D   LDY #$00 
L892F   INY
        LDA $0200,Y
        BNE L892F
        DEY
        STY $B7
L8938   LDA $B8
        STA $0134
        LDA $9A
        STA $0135
        JSR CLRCHN
L8945   LDY #$01 
        STY $BB
        LDY #$02 
        STY $BC
        LDY #$00 
        STY $90
        LDA $0131
        STA $BA
        RTS
--------------------------------- 
L8957   STA $0A
        JSR L892D
        LDA $0A
        LDX $2B
        LDY $2C
        JMP $FFD5
; ----------------------------------------------
; - $8965 load directory -----------------------
; ---------------------------------------------- 
LDDIR:  LDA $9A
        CMP #$03 
        BNE L8970
        LDA #$93 
        JSR CHROUT
L8970   JSR L892D
        DEC $BB
        INC $B7
        LDA #$60 
        STA $B9
        JSR L9AC3
        LDA #$00 
        STA $90
        LDY #$06 
L8984   STY $B7
        LDA $0131
        STA $BA
        JSR TALK
        LDA #$60 
        STA $B9
        JSR TKSA
        LDY #$00 
        LDA $90
        BNE L89B2
L899B   JSR IECIN
        STA $0200,Y
        CPY $B7
        BCC L89A8
        TAX
        BEQ L89B2
L89A8   INY
        LDA $90
        BEQ L899B
        LDA #$00 
        STA $0200,Y
L89B2   STY $FB
        LDA $90
        STA $FC
        JSR UNTALK
        LDA $0135
        CMP #$03 
        BEQ L89C8
        LDX $0134
        JSR CHKOUT
L89C8   LDY $B7
        CPY $FB
        BCS L89EA
        LDA $01FF,Y
        LDX $01FE,Y
        JSR INTOUT
        JSR L8857
        LDY $B7
L89DC   LDA $0200,Y
        BEQ L89E7
        JSR CHROUT
        INY
        BNE L89DC
L89E7   JSR CRDO
L89EA   JSR CLRCHN
        LDA $FC
        BNE L8A14
L89F1   JSR L810A
        BEQ L8A14
        LDA $0135
        CMP #$03 
        BNE L8A0F
        LDA $D6
        CMP #$18 
        BNE L8A0F
        JSR GETIN
        CMP #$04 
        BCC L89F1
        LDA #$93 
        JSR CHROUT
L8A0F   LDY #$04 
        JMP L8984
--------------------------------- 
L8A14   LDA #$60 
        STA $B9
        LDA $0131
        STA $BA
        JSR $F642
        LDA $0135
        CMP #$03 
        BEQ L8A2D
        LDX $0134
        JSR CHKOUT
L8A2D   JMP L848B				; check cartridge and warm start
; ----------------------------------------------
; - $8A30  set IO number -----------------------
; ---------------------------------------------- 
SETIONO:
        LDX #$08 
        JSR L87E6
        CPX #$04 
        BCC L8A43
        CPX #$10 
        BCS L8A43
        STX $0131
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8A43   JMP L883C
; ----------------------------------------------
; -- $8A46 read chanel 15 ">" ------------------
; ---------------------------------------------- 
RDCH15: LDY #$01 
        LDA ($7A),Y
        BNE L8A63
        JSR L8938
        JSR L8AB3
        JSR IECIN
        PHA
        JSR UNTALK
        PLA
        JSR L9B2B
        JSR CRDO
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8A63   JSR L892D
        JSR L8AC0
        JMP L848B				; check cartridge and warm start
; ----------------------------------------------
; - $8A6C read disk channel --------------------
; ----------------------------------------------
RDDCH:  LDY #$01 
        LDA ($7A),Y
        BNE L8A63
L8A72   JSR L8A78
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8A78   JSR L8938
        JSR L8AB3
        LDY #$00 
L8A80   JSR IECIN
        STA $0100,Y
        CMP #$0D 
        BEQ L8A94
        INY
        LDA $90
        BEQ L8A80
        LDA #$0D 
        STA $0100,Y
L8A94   JSR UNTALK
        JSR CRDO
        LDY #$00 
L8A9C   LDA $0100,Y
        JSR CHROUT
        INY
        CMP #$0D 
        BNE L8A9C
        RTS
--------------------------------- 
        JSR L8AB2
        JSR CHROUT
        LDA #$6F 
        STA $B9
L8AB2   RTS
--------------------------------- 
L8AB3   LDA $BA
        JSR TALK
        LDA #$6F 
        STA $B9
        JMP TKSA
--------------------------------- 
        RTS
--------------------------------- 
L8AC0   LDA $BA
        JSR LISTN
        LDA #$6F 
        STA $B9
        JMP $F3EA
; ----------------------------------------------
; - $8ACC  Monitor commands handling -----------
; ---------------------------------------------- 
MONI:   LDX #$01 
        STX $0A
        DEX
        STX $0133
        STX $0134
L8AD7   STX $0135
L8ADA   JSR L8C58
        JSR L8857
        LDA $FD
        TAX
        AND #$7F 
        CMP #$20 
        BCS L8AEB
        LDX #$20 
L8AEB   TXA
        JSR CHROUT
; ----------------------------------------------
; ----- check monitor commands: ----------------
; ----------------------------------------------
        JSR GETIN
        LDX #$02 
        CMP #$2F                                ; "/" modify data
        BEQ L8AD7
        DEX
        DEX
        CMP #$2B                                ; "+" modify address
        BEQ L8AD7
        CMP #$5D                                ; "]" output on screen
        BEQ L8B1E
        CMP #$3E                                ; ">" computer memory
        BEQ L8B0B
        DEX
        CMP #$3C                                ; "<" floppy memory
        BNE L8B11
L8B0B   STX $0133
        JSR L8C4D
L8B11   CMP #$2A                                ; "*" run
        BNE L8B1A
        JSR L8D1B
        LDA #$00 
L8B1A   CMP #$5B                                ; "[" output on printer
        BNE L8B23
L8B1E   STX $0134
        BEQ L8ADA
L8B23   CMP #$0D                                ; "RETURN" inc address
        BNE L8B2A
        JSR L8C3F
L8B2A   CMP #$2E 
        BNE L8B36
        INC $0A
        LDA $0A
        AND #$01 
        STA $0A
L8B36   CMP #$5E                                ; "^" dec address"
        BNE L8B45
        LDX $FB
        BNE L8B40
        DEC $FC
L8B40   DEC $FB
        JSR L8C4D
L8B45   CMP #$20                                ; " " dissasemble continous
        BNE L8B4C
        JSR L8D28
L8B4C   CMP #$2D                                ; "-" dissasemble 1 line
        BNE L8B53
        JSR L8D52
L8B53   CMP #$40                                ; "@" transfer
        BNE L8B5C
        JSR L8B96
        LDA #$00 
L8B5C   CMP #$3D                                ; "=" exit monitor
        BNE L8B63
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L8B63   JSR $007C
        JSR L885C
        BCS L8B93
        LDX $0135
L8B6E   ROL
        ROL $FB,X
        ROL $FC,X
        DEY
        BNE L8B6E
        TXA
        BEQ L8B83
        LDX $0133
        BEQ L8B8F
        LDX #$57 
        JSR L8C7E
L8B83   LDX $0133
        BEQ L8B93
        LDX #$52 
        JSR L8C7E
        BEQ L8B93
L8B8F   LDA $FD
        STA ($FB),Y
L8B93   JMP L8ADA
--------------------------------- 
L8B96   LDA $0A
        BEQ L8BBC
        LDA $25
        BPL L8BBC
        CMP #$A0 
        BCS L8BA8
L8BA2   JSR L8BB8
        INC $0A
        RTS
--------------------------------- 
L8BA8   LDX $23
        CPX #$A0 
        BCC L8BA2
        CMP #$DE 
        BCC L8BBC
        CPX #$DF 
        BCS L8BBC
        BCC L8BA2
L8BB8   LDA #$00 
        STA $0A
L8BBC   JSR L8CDD
        LDX $FB
        STX $26
        LDA $FC
        STA $27
        CMP $23
        BNE L8BCD
        CPX $22
L8BCD   BCC L8C17
        BEQ L8C17
        LDX #$24 
        STX $0254
        LDA $24
        SEC
        SBC $22
        TAX
        LDA $25
        SBC $23
        TAY
        TXA
        CLC
        ADC $26
        STA $26
        TYA
        ADC $27
        STA $27
        LDX #$37 
L8BEE   LDA $24
        BNE L8BF4
        DEC $25
L8BF4   DEC $24
        LDA $26
        BNE L8BFC
        DEC $27
L8BFC   DEC $26
        LDA $25
        CMP $23
        BNE L8C08
        LDA $24
        CMP $22
L8C08   BCC L8C14
        LDY #$00 
        JSR $024C
        STA ($26),Y
        TYA
        BEQ L8BEE
L8C14   JMP L8CDD
--------------------------------- 
L8C17   LDX #$22 
        STX $0254
        LDX #$37 
L8C1E   LDA $23
        CMP $25
        BNE L8C28
        LDA $22
        CMP $24
L8C28   BCS L8C14
        LDY #$00 
        JSR $024C
        STA ($26),Y
        INC $22
        BNE L8C37
        INC $23
L8C37   INC $26
        BNE L8C1E
        INC $27
        BNE L8C1E
L8C3F   JSR CRDO
L8C42   INC $FB
        BNE L8C48
        INC $FC
L8C48   LDY #$00 
        JSR L8CEC
L8C4D   LDA $0133
        BEQ L8C57
        LDX #$52 
        JSR L8C7E
L8C57   RTS
--------------------------------- 
L8C58   LDY #$00 
        STY $D3
        LDA #$40 
        LDX $0133
        BNE L8C6A
        JSR L8CE9
        LDA $0A
        ORA #$30 
L8C6A   JSR CHROUT
        JSR L8857
        JSR L9B24
        JSR L8854
        LDA $FD
        JSR L9B2B
        JMP L8857
--------------------------------- 
L8C7E   LDA $0131
        STA $BA
        JSR LISTN
        LDA #$6F 
        STA $B9
        JSR SECND
        LDA #$4D 
        JSR CIOUT
        LDA #$2D 
        JSR CIOUT
        TXA
        JSR CIOUT
        LDA $FB
        JSR CIOUT
        LDA $FC
        JSR CIOUT
        CPX #$57 
        BNE L8CB3
        LDA #$01 
        JSR CIOUT
        LDA $FD
        JSR CIOUT
L8CB3   JSR UNLSN
        CPX #$52 
        BNE L8CCD
        LDA $0131
        JSR TALK
        LDA $B9
        JSR TKSA
        JSR IECIN
        STA $FD
        JSR UNTALK
L8CCD   LDA #$00 
        RTS
--------------------------------- 
L8CD0   SEI
        LDA $0A
        BNE L8CD7
        STY $01
L8CD7   LDA ($FB),Y
        STX $01
        CLI
        RTS
--------------------------------- 
L8CDD   LDX #$0C 
L8CDF   LDA L8CD0,X
        STA $024C,X
        DEX
        BPL L8CDF
        RTS
--------------------------------- 
L8CE9   JSR L8CDD
L8CEC   LDX #$37 
        LDA $0A
        BEQ L8D15
        LDA $FC
        BPL L8D08
        CMP #$DE 
        BEQ L8D0D
        CMP #$A0 
        BCS L8D08
        LDA #$00 
        STA $0A
        JSR L8D15
        INC $0A
        RTS
--------------------------------- 
L8D08   LDA ($FB),Y
        STA $FD
        RTS
--------------------------------- 
L8D0D   INC $FC
        LDA ($FB),Y
        DEC $FC
        BNE L8D18
L8D15   JSR $024C
L8D18   STA $FD
        RTS
--------------------------------- 
L8D1B   LDX $0133
        BEQ L8D25
        LDX #$45 
        JMP L8C7E
--------------------------------- 
L8D25   JMP ($00FB)
--------------------------------- 
L8D28   JSR L810A
        BNE L8D30
        RTS
--------------------------------- 
        BEQ L8D28
L8D30   JSR L8D52
        JMP L8D28
--------------------------------- 
L8D36   JSR CLRCHN
        JSR L8C42
L8D3C   BIT $0134
        BPL L8D51
        LDA #$04 
        STA $9A
        STA $BA
        JSR LISTN
        LDA #$FF 
        STA $B9
        JMP SCATN
--------------------------------- 
L8D51  RTS
--------------------------------- 
L8D52   JSR L8D3C
        JSR L8C58
        LDA $FD
        TAY
        LSR
        BCC L8D69
        LSR
        BCS L8D78
        CMP #$22 
        BEQ L8D78
        AND #$07 
        ORA #$80 
L8D69   LSR
        TAX
        LDA L9C5B,X
        BCS L8D74
        LSR
        LSR
        LSR
        LSR
L8D74   AND #$0F 
        BNE L8D7C
L8D78   LDA #$00 
        LDY #$80 
L8D7C   TAX
        LDA L9C9F,X
        STA $0113
        AND #$03 
        STA $0112
        TYA
        AND #$8F 
        TAX
        TYA
        LDY #$03 
        CPX #$8A 
        BEQ L8D9E
L8D93   LSR
        BCC L8D9E
        LSR
L8D97   LSR
        ORA #$20 
        DEY
        BNE L8D97
        INY
L8D9E   TAX
        DEY
        BNE L8D93
        LDA L9CB9,X
        STA $0110
        LDA L9CF9,X
        STA $0111
        LDX #$00 
L8DB0   STX $0114
        CPX $0112
        BCC L8DBD
        JSR L8854
         BNE L8DCA
L8DBD  JSR L8D36
        LDA $FD
        LDX $0114
        STA $FE,X
        JSR L9B2B
L8DCA   JSR L8857
        LDX $0114
        INX
        CPX #$03 
        BNE L8DB0
L8DD5   LDA #$00 
        LDY #$05 
L8DD9   ASL $0111
        ROL $0110
        ROL
        DEY
        BNE L8DD9
        ORA #$40 
        CMP #$40 
        BNE L8DEB
        LDA #$2A 
L8DEB   JSR CHROUT
        DEX
        BNE L8DD5
        JSR L8854
        LDX #$06 
L8DF6   CPX #$04 
        BNE L8E1D
        LDA $0111
        BNE L8E02
        JSR L8857
L8E02   LDY $0112
        BEQ L8E1D
        LDA $0113
        CMP #$84 
        BCS L8E3F
L8E0E   LDA $00FD,Y
        STX $0114
        JSR L9B2B
        LDX $0114
        DEY
        BNE L8E0E
L8E1D   ASL $0113
        BCC L8E33
        INC $0111
        LDA L9CAC,X
        JSR CHROUT
        LDA L9CB2,X
        BEQ L8E33
        JSR CHROUT
L8E33   DEX
        BNE L8DF6
L8E36   JSR CRDO
        JSR L8D36
        JMP CLRCHN
--------------------------------- 
L8E3F   LDX $FC
        LDA $FE
        BPL L8E46
        DEX
L8E46   ADC $FB
        BCC L8E4B
        INX
L8E4B   TAY
        TXA
        JSR L9B2B
        TYA
        JSR L9B2B
        JMP L8E36
; - $8E57  basic command CHECK UNDEF'D --------- 
UNDEF:  JSR L8E8A
; - $8E5A  basic command COMPACTOR -------------
COMPACTOR:
        JSR L8E6C
        LDX #$01 
        STX $0133
        STX $0135
        DEX
        STX $0134
        JMP L858B
--------------------------------- 
L8E6C   LDX #$F0 
        JSR L87E6
        TXA
        BNE L8E77
L8E74   JMP L883C
--------------------------------- 
L8E77   CPX #$F1 
        BCS L8E74
        STX $FD
        JSR L8E8D
        JSR L8ED3
L8E83   LDA #$33 
        LDY #$A5 				; $a533 rebuild BASIC line chaining
        JMP LDE09                               ; set $55/$56 and JSR ($55) with module off
--------------------------------- 
L8E8A   LDA #$01 
        !by $2C					; BIT $HHLL: skip following instruction
L8E8D   LDA #$00
        STA $0112
        JSR L8EA0
        LDA $0112
        BNE L8E9B
        RTS
--------------------------------- 
L8E9B   PLA
        PLA
        JMP L85A1
--------------------------------- 
L8EA0   JSR STXTP
L8EA3   JSR L8FF9
L8EA6   JSR LDE60				; next CHRGET with module off
L8EA9   TAX
        BEQ L8EA3
        JSR L9044
        BCC L8EA9
        JSR L9012
        BNE L8EA6
L8EB6   JSR LDE60				; next CHRGET with module off
        BCS L8EA9
        JSR L90BF
        BCS L8ECC
        JSR L902B
L8EC3   JSR LDE66				; CHRGOT with module off
        CMP #$2C 
        BNE L8EA9
        BEQ L8EB6
L8ECC   DEY
        LDA #$FF 
        STA ($5F),Y
        BMI L8EC3
L8ED3   LDY #$00 
        STY $0112
        STY $0113
        STY $0114
        JSR STXTP
L8EE1   LDA $7A
        STA $45
        LDA $7B
        STA $46
        JSR L8FF9
        INC $7A
        BNE L8EF2
        INC $7B
L8EF2   JSR L903B
        LDA $0112
        BNE L8F01
L8EFA   LDA #$00 
        STA $0114
        BEQ L8F43
L8F01   LDY #$FF 
        LDA $3D
        STA $22
        LDA $3E
        STA $23
L8F0B   INY
        JSR LDE44				; LDA ($22),Y with module off
        BNE L8F0B
        TYA
        CLC
        ADC $0114
        BCS L8EFA
        CMP $FD
        BCS L8EFA
        LDY #$02 
        JSR LDE32				; LDA ($45),Y with module off
        CMP #$FF 
        BEQ L8EFA
        LDY #$00 
        LDA $0113
        BEQ L8F36
        LDA #$22 
        STA ($45),Y
        INC $45
        BNE L8F36
        INC $46
L8F36   LDA #$3A 
        STA ($45),Y
        INC $45
        BNE L8F40
        INC $46
L8F40   JSR L9081
L8F43   LDX #$00 
        STX $0113
        INX
        STX $0112
        INC $0114
L8F4F   LDY #$00 
L8F51   JSR LDE3B				; LDA ($7A),Y with module off
        BNE L8F59
        JMP L8EE1
--------------------------------- 
L8F59   INC $7A
        BNE L8F5F
        INC $7B
L8F5F   INC $0114
        CMP #$22 
        BNE L8F7F
L8F66   JSR LDE3B				; LDA ($7A),Y with module off
        BNE L8F70
        INC $0113
        BNE L8F51
L8F70   INC $7A
        BNE L8F76
        INC $7B
L8F76   INC $0114
        CMP #$22 
        BNE L8F66
        BEQ L8F51
L8F7F   CMP #$8B 
        BNE L8F8A
L8F83   LDA #$00 
        STA $0112
        BEQ L8F51
L8F8A   CMP #$8D 
        BEQ L8F51
        JSR L9012
        BEQ L8F83
        CMP #$20 
        BNE L8FA3
        JSR L90F9
L8F9A   JSR L903B
        JSR L9081
        JMP L8F4F
--------------------------------- 
L8FA3   CMP #$8F 
        BNE L8FC6
        JSR L90F9
        LDA #$3A 
        STA ($45),Y
        INC $45
        BNE L8FB4
        INC $46
L8FB4   JSR LDE3B				; LDA ($7A),Y with module off
L8FB7   BEQ L8F51
L8FB9   INC $7A
        BNE L8FBF
        INC $7B
L8FBF   JSR LDE3B				; LDA ($7A),Y with module off
        BNE L8FB9
        BEQ L8F9A
L8FC6   CMP #$83 
        BNE L8F51
L8FCA   JSR LDE3B				; LDA ($7A),Y with module off
        BEQ L8F51
        INC $7A
        BNE L8FD5
        INC $7B
L8FD5   INC $0114
        CMP #$3A 
        BEQ L8FB7
        CMP #$22 
        BNE L8FCA
L8FE0   JSR LDE3B				; LDA ($7A),Y with module off
        BNE L8FEA
        INC $0113
        BNE L8FCA
L8FEA   INC $7A
        BNE L8FF0
        INC $7B
L8FF0   INC $0114
        CMP #$22 
        BNE L8FE0
        BEQ L8FCA
L8FF9   LDY #$02 
        JSR LDE3B				; LDA ($7A),Y with module off
        BNE L9003
        PLA
        PLA
        RTS
--------------------------------- 
L9003   INY
        JSR LDE3B				; LDA ($7A),Y with module off
        STA $39
        INY
        JSR LDE3B				; LDA ($7A),Y with module off
        STA $3A
        JMP $A8FB
--------------------------------- 
L9012   CMP #$CB                                ; go
        BNE L901C
        JSR LDE60				; next CHRGET with module off
        CMP #$A4                                ; to
        RTS
--------------------------------- 
L901C   CMP #$A7                                ; then
        BEQ L902A
        CMP #$89                                ; goto
        BEQ L902A
        CMP #$8D                                ; gosub
        BEQ L902A
        CMP #$8A                                ; run
L902A   RTS
--------------------------------- 
L902B   LDA #<L9D63
        LDY #>L9D63 				; undef'd statement error
        STY $0112
        JSR STROUT
        JSR $BDC2
        JMP CRDO
--------------------------------- 
L903B   LDX $7A
        STX $3D
        LDX $7B
        STX $3E
        RTS
--------------------------------- 
L9044   CMP #$22 				; '"'
        BNE L9061
        LDY #$00 
        INC $7A
        BNE L9050
        INC $7B
L9050   JSR LDE3B				; LDA ($7A),Y with module off
        BEQ L906C				; end of BASIC line?
        INC $7A					; skip string character
        BNE L905B
        INC $7B
L905B   CMP #$22 				; skip until '"'
        BNE L9050
        BEQ L906C
L9061   CMP #$8F 				; REM token
        BNE L9071
        LDA #$3B 
        LDY #$A9 				; $a93b perform REM
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
L906C   JSR LDE66				; CHRGOT with module off
        CLC
        RTS
--------------------------------- 
L9071   CMP #$83 				; DATA token
        BNE L907F
        LDA #$F8 
        LDY #$A8 				; $a8f8 perform DATA
        JSR LDE09                               ; set $55/$56 and JSR ($55) with module off
        JMP L906C
--------------------------------- 
L907F   SEC
        RTS
--------------------------------- 
L9081   LDA $45
        STA $7A
        LDX $46
        STX $7B
        LDA $3E
        STA $23
        LDA $2D
        STA $22
        LDA $46
        STA $25
        LDA $45
        SEC
        SBC $3D
        CLC
        ADC $2D
        STA $2D
        STA $24
        LDA $2E
        ADC #$FF 
        STA $2E
        SBC $46
        TAX
        LDA $45
        SEC
        SBC $2D
        TAY
        BCS L90B5
        INX
        DEC $25
L90B5   CLC
        ADC $22
        BCC L90BC
        DEC $23
L90BC   JMP $DEB0				; copy ($22) to ($24) X pages upwards with module off
--------------------------------- 
L90BF   LDY #$6B 
        STY $55
        LDY #$A9 				; $A96B get fixed-point number into temporary integer
        JSR LDE0B				; JMP $A96B with module off
L90C8   LDA $2B
        LDX $2C
L90CC   LDY #$01 
        STA $5F
        STX $60
        JSR LDE00				; LDA ($5F),Y with module off
        BEQ L90F7
        LDY #$03 
        JSR LDE00				; LDA ($5F),Y with module off
        CMP $15
        BNE L90E6
        DEY
        JSR LDE00				; LDA ($5F),Y with module off
        CMP $14
L90E6   BCC L90EB
        BNE L90F7
        RTS
--------------------------------- 
L90EB   LDY #$00 
        JSR LDE00				; LDA ($5F),Y with module off
        CMP $5F
        BCS L90CC
        INX
        BCC L90CC
L90F7   CLC
        RTS
--------------------------------- 
L90F9   LDA $7B
        STA $46
        LDX $7A
        BNE L9103
        DEC $46
L9103   DEX
        STX $45
        RTS
; - $9107  basic command RENEW -----------------
RENEW:  LDA $2B
        LDX $2C
        STA $5F
        STX $60
L910F   LDY #$03 
L9111   INY
        BEQ L9156
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L9111
        TYA
        SEC
        ADC $5F
        TAX
        LDY #$00 
        TYA
        ADC $60
        CMP $38
        BNE L9129
        CPX $37
L9129   BCS L9156
        PHA
        TXA
        STA ($5F),Y
        INY
        PLA
        STA ($5F),Y
        STX $5F
        STA $60
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L910F
        DEY
        JSR LDE00				; LDA ($5F),Y with module off
        BNE L910F
L9142   CLC
        LDA $5F
        LDY $60
        ADC #$02 
        BCC L914C
        INY
L914C   STA $2D
        STY $2E
        JSR CLEARC
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L9156   TYA
        STA ($5F),Y
        INY
        STA ($5F),Y
        BNE L9142
; ----------------------------------------------
; - $915E - Start of assembler -----------------
; ----------------------------------------------
ASSEMBLER:
        LDA #$00 
        STA $2D
        LDA #$A0 
        STA $2E
        LDX #$47 
L9168   LDA L9BCE,X                             ; copy part of assembler to RAM
        STA $0347,X
        DEX
        BPL L9168
        LDA #<L9C15 
        LDY #>L9C15				; "programname  :"
        JSR STROUT
        LDX #$00 
L917A   JSR CHRIN
        CMP #$0D 
        BEQ L9189
        STA $0120,X
        INX
        CPX #$10 
        BCC L917A
L9189   STX $B7
        TXA
        BNE L9191
        JMP L848B				; check cartridge and warm start
--------------------------------- 
L9191   LDA #<L9C26 
        LDY #>L9C26 				; "printout mode:"
        JSR STROUT
        LDX #$00 
        STX $57
        STX $58
        STX $59
        STX $5A
L91A2   JSR CHRIN
        CMP #$0D 
        BEQ L91B4
        CPX #$03 
        BCS L91A2
        AND #$01 
        STA $57,X
        INX
        BNE L91A2
L91B4   JSR CRDO
        LDX #$00 
        STX $3E
        STX $3F
        STX $40
        STX $2F
        STX $30
L91C3   STX $2A
        LDX #$00 
        STX $7A
        STX $29
        STX $43
        STX $44
        STX $31
        STX $32
        LDX #$10 
        STX $7B
        LDA #$01 
        STA $BC
        LDA #$20 
        STA $BB
        JSR L9A9E
        LDX $3F
        BNE L91E9
        JSR L944B
L91E9   JSR L99BD
        JSR L948C
        LDA $2A
        BEQ L91FA
        LDA $58
        BEQ L91FA
        JSR L93A3
L91FA   LDA $4D
        BMI L9207
        CLC
        ADC $7A
        STA $7A
        BCC L9207
        INC $7B
L9207   INC $31
        BNE L920D
        INC $32
L920D   LDA $29
        BEQ L91E9
        LDA $0131
        STA $BA
        JSR $F648
        LDX $2A
        BNE L9220
        INX
        BNE L91C3
L9220   JSR L9422
L9223   LDA #<L9C37 
        LDY #>L9C37 				; "   lines:"
        JSR STROUT
        LDA $32
        LDX $31
        JSR INTOUT
        LDA #<L9C3E 
        LDY #>L9C3E 				; "   symbols:"
        JSR STROUT
        LDA $30
        LDX $2F
        JSR INTOUT
        LDA #<L9C4A
        LDY #>L9C4A 				; "   errors:"
        JSR STROUT
        LDA #$00 
        LDX $40
        JSR INTOUT
        JSR L9425
        BCS L9223
        JSR L9422
        LDA $59
        BEQ L928D
        JSR L9314
        LDY #$05 
        LDA #$00 
L9260   STA $0110,Y
        DEY
        BPL L9260
L9266   LDY #$05 
        LDA #$FF 
L926A   STA $0100,Y
        DEY
        BPL L926A
        LDX #$00 
        LDA #$A0 
L9274   STX $22
        STA $23
        CMP $2E
        BNE L927E
        CPX $2D
L927E   BCC L9296
        LDA $0100
        BPL L9290
        JSR L9302
L9288   JSR L9425
        BCS L9288
L928D   JMP L848B				; check cartridge and warm start
--------------------------------- 
L9290   JSR L92D2
        JMP L9266
--------------------------------- 
L9296   LDY #$00 
L9298   JSR $0373
        CMP $0110,Y
        BNE L92A7
        INY
        CPY #$06 
        BNE L9298
        BEQ L92C5
L92A7   BCC L92C5
        LDY #$00 
L92AB   JSR $0373
        CMP $0100,Y
        BNE L92B8
        INY
        CPY #$06 
        BNE L92AB
L92B8   BCS L92C5
        LDY #$07 
L92BC   JSR $0373
        STA $0100,Y
        DEY
        BPL L92BC
L92C5   LDA $22
        CLC
        ADC #$08 
        TAX
        LDA $23
        ADC #$00 
        JMP L9274
--------------------------------- 
L92D2   LDX $28
        LDY #$00 
L92D6   LDA $0100,Y
        STA $0110,Y
        STA $0200,X
        INX
        INY
        CPY #$06 
        BNE L92D6
        LDA #$3D 
        STA $0200,X
        INX
        LDA $0106
        JSR L9322
        LDA $0107
        JSR L9322
        INX
        INX
        CPX #$27 
        BNE L92FE
        INX
L92FE   CPX #$48 
        BCC L931F
L9302   LDX #$00 
L9304   LDA $0200,X
        JSR CHROUT
        INX
        CPX #$4F 
        BNE L9304
        JSR L9425
        BCS L9302
L9314   LDA #$20 
        LDX #$4F 
L9318   STA $0200,X
        DEX
        BPL L9318
        INX
L931F   STX $28
        RTS
--------------------------------- 
L9322   PHA
        LSR
        LSR
        LSR
        LSR
        JSR L932D
        PLA
        AND #$0F 
L932D   ORA #$30 
        CMP #$3A 
        BCC L9335
        ADC #$06 
L9335   STA $0200,X
        INX
        RTS
--------------------------------- 
L933A   LDY $46
        INC $46
        LDA $0140,Y
        BNE L9348
L9343   LDA #$00 
        STY $46
        RTS
--------------------------------- 
L9348   CMP #$3B 
        BEQ L9343
        RTS
--------------------------------- 
L934D   LDY $46
        INC $46
        LDA $0140,Y
        BEQ L9343
        RTS
--------------------------------- 
L9357   CPX #$01 
        BNE L9364
L935B   LDA $63
        LDY $62
L935F   STA $69
        STY $68
        RTS
--------------------------------- 
L9364   CPX #$2A 
        BNE L936F
        LDA $7A
        LDY $7B
        JMP L935F
--------------------------------- 
L936F   CPX #$03 
        BEQ L9376
        JMP L9619
--------------------------------- 
L9376   LDA $49
        AND $48
        STA $49
        LDA $48
        BNE L938B
        LDA $2A
        BEQ L935B
        LDY #$9B 
        LDA #$9B 
        JMP L9628
--------------------------------- 
L938B   LDY #$06 
        JSR $0373
        STA $68
        INY
        JSR $0373
        STA $69
L9398   RTS
--------------------------------- 
L9399   LDA $0139,Y
        CMP #$20 
        BNE L9398
        INY
        BNE L9399
L93A3   LDY $7A
        LDA $7B
        LDX $4D
        BPL L93B3
        LDX #$00 
        STX $4D
        LDY $67
        LDA $66
L93B3   STY $FB
        STA $FC
L93B7   JSR L9B24
        JSR L8857
        LDY #$00 
L93BF   CPY $4D
        BCS L93CC
        LDA $004E,Y
        JSR L9B2B
        JMP L93CF
--------------------------------- 
L93CC   JSR L8854
L93CF   JSR L8857
        INY
        CPY #$03 
        BCC L93BF
        LDY #$00 
L93D9   LDA $0139,Y
        JSR CHROUT
        INY
        CPY #$07 
        BNE L93D9
        LDX $27
        BEQ L9401
        JSR L9399
        LDX #$00 
L93ED   LDA $0139,Y
        CMP #$20 
        BEQ L9401
        CMP #$3D 
        BEQ L9401
        JSR CHROUT
        INY
        INX
        CPX #$06 
        BNE L93ED
L9401   LDA #$20 
        JSR CHROUT
        INX
        CPX #$07 
        BNE L9401
        JSR L9399
L940E   LDA $0139,Y
        BEQ L9419
        JSR CHROUT
        INY
        BNE L940E
L9419   JSR L9425
        BCS L941F
        RTS
--------------------------------- 
L941F   JMP L93B7
--------------------------------- 
L9422   JSR L9425
L9425   JSR CRDO
L9428   LDA #$04 
        CMP $9A
        BEQ L943E
        STA $9A
        STA $BA
        JSR LISTN
        LDA #$FF 
        STA $B9
        JSR SCATN
        SEC
        RTS
--------------------------------- 
L943E   LDX #$03 
        STX $9A
        JSR UNLSN
        DEC $3D
        BEQ L944B
        CLC
        RTS
--------------------------------- 
L944B   JSR L9428
        LDX $3F
L9450   JSR CRDO
        DEX
        BPL L9450
        LDX #$05 
        STX $3F
        LDX #$41 
        STX $3D
        INC $3E
        LDX #$00 
L9462   LDA $0120,X
L9465   JSR CHROUT
        INX
        CPX $B7
        BCC L9462
        LDA #$20 
        CPX #$3C 
        BCC L9465
        LDA #<L9C55 
        LDY #>L9C55				; "page:"
        JSR STROUT
        LDA #$00 
        STA $68
        LDX $3E
        JSR INTOUT
        JSR CRDO
        JSR CRDO
        JMP L943E
--------------------------------- 
L948C   LDY #$00 
        STY $27
        STY $46
        STY $4D
        JSR L966A
        TXA
        BEQ L94EF
        CPX #$03 
        BNE L94FB
        INC $27
        LDY $2A
        BNE L94C0
        INC $2F
        BNE L94AA
        INC $30
L94AA   LDY #$05 
L94AC   LDA $0110,Y
        JSR $0382
        DEY
        BPL L94AC
        LDA $48
        BEQ L94C0
        LDY #$9B 
        LDA #$8A 
        JSR L9628
L94C0   JSR L966A
        CPX #$3D 
        BNE L94F0
        LDA #$FF 
        STA $4D
        JSR L979C
        LDA $6B
        LDX $6A
L94D2   STA $67
        STX $66
        LDY $2A
        BNE L94EF
        LDY #$07 
        JSR $0382
        TXA
        DEY
        JSR $0382
        LDA $2D
        CLC
        ADC #$08 
        STA $2D
        BCC L94EF
        INC $2E
L94EF   RTS
--------------------------------- 
L94F0   STX $28
        LDA $7A
        LDX $7B
        JSR L94D2
        LDX $28
L94FB   CPX #$02 
        BNE L9502
        JMP L9815
--------------------------------- 
L9502   CPX #$2A 
        BNE L951C
        JSR L966A
        CPX #$3D 
        BEQ L9510
L950D   JMP L9619
--------------------------------- 
L9510   JSR L979C
        LDA $6B
        STA $7A
        LDA $6A
        STA $7B
        RTS
--------------------------------- 
L951C   CPX #$2E 
        BNE L950D
        LDY $46
        LDX #$00 
L9524   LDA L9BB3,X                             ; 'end'
        CMP $0140,Y
        BNE L9535
        INY
        INX
        CPX #$03 
        BNE L9524
        INC $29
        RTS
--------------------------------- 
L9535   LDA L9BB6,X                             ; 'text'
        CMP $0140,Y
        BNE L956E
        INY
        INX
        CPX #$04 
        BNE L9535
        LDA #$FF 
L9545   STA $28
        STY $46
L9549   JSR L933A
        BNE L9551
L954E   JMP L9619
--------------------------------- 
L9551   CMP #$27 
        BEQ L9559
        CMP #$22 
        BNE L9549
L9559   STA $07
L955B   JSR L934D
        BEQ L954E
        CMP $07
        BEQ L956B
        AND $28
        JSR L9601
        BNE L955B
L956B   JMP L9612
--------------------------------- 
L956E   LDA L9BBE,X                             ; 'disp'
        CMP $0140,Y
        BNE L9580
        INY
        INX
        CPX #$04 
        BNE L956E
        LDA #$3F 
        BNE L9545
L9580   LDA $0140,Y
        CMP L9BBA,X                             ; 'wort'
        BNE L9592
L9588   INY
        INX
        CPX #$04 
        BNE L9580
        LDA #$00 
        BEQ L95AA
L9592   CPX #$03 
        BNE L959A
        CMP #$44 
        BEQ L9588
L959A   LDA L9BC2,X                             ; 'byte'
        CMP $0140,Y
        BNE L95C3
        INY
        INX
        CPX #$04 
        BNE L959A
        LDA #$FF 
L95AA   STA $28
        STY $46
L95AE   JSR L979C
        LDA $6B
        JSR L9601
        BIT $28
        BPL L95D4
        JSR L961F
L95BD   CPX #$2C 
        BEQ L95AE
        BNE L9612
L95C3   LDA L9BC6,X                             ; 'load'
        CMP $0140,Y
        BNE L95DB
        INY
        INX
        CPX #$04 
        BNE L95C3
        JMP L9A87
--------------------------------- 
L95D4   LDA $6A
        JSR L9601
        BNE L95BD
L95DB   LDA L9BCA,X                             ; 'corr'
        CMP $0140,Y
        BNE L95FB
        INY
        INX
        CPX #$04 
        BNE L95DB
        STY $46
        JSR L979C
        LDA $6B
        LDY $6A
        STA $43
        STY $44
L95F6   PLA
        PLA
        JMP L91E9
--------------------------------- 
L95FB   LDA #$76 
        LDY #$9B 
        BNE L9628
L9601   PHA
        PLA
        LDY $4D
        JSR L998F
        CPY #$03 
        BCS L960F
        STA $004E,Y
L960F   INC $4D
        RTS
--------------------------------- 
L9612   JSR L966A
        TXA
        BNE L9619
        RTS
--------------------------------- 
L9619   LDA #$41 
        LDY #$9B 
        BNE L9628
L961F   LDA $6A
        BNE L9624
        RTS
--------------------------------- 
L9624   LDA #$48 
        LDY #$9B 
L9628   STY $63
        STA $62
        STX $28
        CMP #$8A 
        BEQ L9636
        LDA $2A
        BEQ L9667
L9636   INC $40
        LDA $57
        BEQ L9667
L963C   LDY #$00 
L963E   LDA $0139,Y
        JSR CHROUT
        INY
        CPY #$07 
        BNE L963E
        LDY #$00 
L964B   LDA ($62),Y
        BEQ L9655
        JSR CHROUT
        INY
        BNE L964B
L9655   LDY #$00 
L9657   LDA L9BAC,Y                             ; 'error'
        BEQ L9662
        JSR CHROUT
        INY
        BNE L9657
L9662   JSR L9425
        BCS L963C
L9667   LDX $28
        RTS
--------------------------------- 
L966A   LDX #$00 
        STX $62
        STX $63
        JSR L933A
        BNE L9676
        RTS
--------------------------------- 
L9676   CMP #$20 
        BEQ L966A
        INX
        CMP #$27 
        BNE L9685
L967F   JSR L934D
        STA $63
        RTS
--------------------------------- 
L9685   CMP #$22 
        BEQ L967F
        CMP #$24 
        BNE L96B7
L968D   JSR L933A
        BEQ L96B6
        CMP #$30 
        BCC L96B4
        CMP #$3A 
        BCC L96A4
        CMP #$41 
        BCC L96B4
        CMP #$47 
        BCS L96B4
        SBC #$06 
L96A4   ASL
        ASL
        ASL
        ASL
        LDY #$04 
L96AA   ASL
        ROL $63
        ROL $62
        DEY
        BNE L96AA
        BEQ L968D
L96B4   DEC $46
L96B6   RTS
--------------------------------- 
L96B7   CMP #$40 
        BNE L96D9
L96BB   JSR L933A
        BEQ L96B6
        CMP #$30 
        BCC L96B4
        CMP #$38 
        BCS L96B4
        ASL
        ASL
        ASL
        ASL
        ASL
        LDY #$03 
L96CF   ASL
        ROL $63
        ROL $62
        DEY
        BNE L96CF
        BEQ L96BB
L96D9   CMP #$25 
        BNE L96F2
L96DD   JSR L933A
        BEQ L96B6
        CMP #$30 
        BEQ L96EA
        CMP #$31 
        BNE L96B4
L96EA   LSR
        ROL $63
        ROL $62
        JMP L96DD
--------------------------------- 
L96F2   CMP #$30 
        BCC L9734
        CMP #$3A 
        BCS L9734
        BCC L9709
L96FC   JSR L933A
        BEQ L96B6
        CMP #$30 
        BCC L96B4
        CMP #$3A 
        BCS L96B4
L9709   AND #$0F 
        PHA
        LDA $63
        LDY $62
        ROL $63
        ROL $62
        ROL $63
        ROL $62
        CLC
        ADC $63
        STA $63
        TYA
        ADC $62
        STA $62
        ROL $63
        ROL $62
        PLA
        ADC $63
        STA $63
        LDA $62
        ADC #$00 
        STA $62
        JMP L96FC
--------------------------------- 
L9734   TAX
        CMP #$41 
        BCS L973A
L9739   RTS
--------------------------------- 
L973A   CMP #$5B 
        BCS L9739
        LDY #$04 
        LDA #$20 
L9742   STA $0111,Y
        DEY
        BPL L9742
        STX $0110
        LDX #$01 
L974D   JSR L933A
        BEQ L976E
        CMP #$30 
        BCC L976C
        CMP #$3A 
        BCC L9762
        CMP #$41 
        BCC L976C
        CMP #$5B 
        BCS L976C
L9762   STA $0110,X
        INX
        CPX #$06 
        BCC L974D
        BCS L976E
L976C   DEC $46
L976E   DEX
        BNE L9780
        LDX $0110
        CPX #$41 
        BEQ L9739
        CPX #$59 
        BEQ L9739
        CPX #$58 
        BEQ L9739
L9780   CPX #$02 
        BNE L978E
        JSR L9ACF
        BEQ L978E
        LDX #$02 
        STA $47
        RTS
--------------------------------- 
L978E   LDX #$00 
        LDY #$00 
        STY $48
        LDA #$00 
        LDY #$A0 
        SEI
        JMP $0347
--------------------------------- 
L979C   JSR L966A
        TXA
        BNE L97A3
        RTS
--------------------------------- 
L97A3   LDA #$01 
        STA $49
        JSR L9357
        LDA $69
        LDY $68
        STA $6B
        STY $6A
        JMP L97D8
--------------------------------- 
L97B5   LDA $4A
        CMP #$2B 
        BNE L97CB
        LDA $6B
        CLC
        ADC $69
        STA $6B
        LDA $6A
        ADC $68
        STA $6A
        JMP L97D8
--------------------------------- 
L97CB   LDA $6B
        SEC
        SBC $69
        STA $6B
        LDA $6A
        SBC $68
        STA $6A
L97D8   JSR L966A
        BEQ L97F0
        STX $4A
        CPX #$2B 
        BEQ L97E7
        CPX #$2D 
        BNE L97F0
L97E7   JSR L966A
        JSR L9357
        JMP L97B5
--------------------------------- 
L97F0   LDY $49
        BNE L97F9
        STY $6B
        INY
        STY $6A
L97F9   CPX #$5B 
        BEQ L9801
        CPX #$3E 
        BNE L980C
L9801   LDY $6A
        STY $6B
L9805   LDY #$00 
        STY $6A
        JMP L966A
--------------------------------- 
L980C   CPX #$5D 
        BEQ L9805
        CPX #$3C 
        BEQ L9805
        RTS
--------------------------------- 
L9815   LDX #$01 
        STX $4D
        LDY $47
        CPY #$05 
        BEQ L983C
        JSR L966A
        CPX #$41 
        BNE L982C
        LDA #$0A 
        STA $4C
        BNE L983C
L982C   INC $4D
        CPX #$23 
        BNE L983F
        LDA #$02 
        STA $4C
        JSR L979C
        JSR L961F
L983C   JMP L98B7
--------------------------------- 
L983F   CPX #$28 
        BNE L9885
        JSR L979C
        CPX #$2C 
        BNE L9864
        LDA #$00 
        STA $4C
        JSR L961F
        JSR L966A
        CPX #$58 
        BEQ L985B
L9858   JMP L98E5
--------------------------------- 
L985B   JSR L966A
        CPX #$29 
        BNE L9858
        BEQ L98B7
L9864   LDA #$04 
        STA $4C
        CPX #$29 
        BNE L9858
        JSR L966A
        TXA
        BNE L9878
        LDA #$08 
        STA $4C
        BNE L98B7
L9878   CPX #$2C 
        BNE L9858
        JSR L966A
        CPX #$59 
        BNE L9858
        BEQ L98B7
L9885   LDA #$01 
        STA $4C
        JSR L97A3
        CPX #$2C 
        BNE L98A3
        JSR L966A
        LDA #$05 
        STA $4C
        CPX #$58 
        BEQ L98A3
        CPX #$59 
        BNE L9858
        LDA #$09 
        STA $4C
L98A3   LDA $6A
        BEQ L98B7
        INC $4C
        INC $4C
        INC $4D
        LDA $4C
        CMP #$09 
        BCC L98B7
        LDA #$06 
        STA $4C
L98B7   JSR L9612
        LDA $6B
        STA $4F
        LDA $6A
        STA $50
        LDX $47
        DEX
        BNE L98F7
        LDA $4C
        CMP #$09 
        BNE L98D5
        LDA #$06 
        STA $4C
        LDA #$03 
        STA $4D
L98D5   LDA $4C
        CMP #$08 
        BCS L98E5
        CMP #$02 
        BNE L98EC
        LDA $4B
        CMP #$81 
        BNE L98EC
L98E5   LDA #$66 
        LDY #$9B 
        JMP L9628
--------------------------------- 
L98EC   LDA $4C
        ASL
        ASL
        ADC $4B
        STA $4B
        JMP L995C
--------------------------------- 
L98F7   DEX
        BNE L9915
        LDA $4C
        CMP #$09 
        BCS L9905
        LSR
        BCS L98EC
        BCC L98E5
L9905   CMP #$0A 
        BNE L98E5
        LDA $4B
        CMP #$63 
        BCS L98E5
        ADC #$08 
        STA $4B
        BNE L995C
L9915   DEX
        BNE L995F
        LDA #$02 
        STA $4D
        LDA $6B
        SEC
        SBC $7A
        STA $69
        LDA $6A
        SBC $7B
        STA $68
        LDA $69
        SEC
        SBC #$02 
        STA $69
        LDA $68
        SBC #$00 
        STA $68
        BMI L9950
        BNE L993E
        LDA $69
        BPL L9958
L993E   LDA #$00 
        STA $69
        LDA $2A
        BEQ L9958
        LDA #$57 
        LDY #$9B 
        JSR L9628
        JMP L9958
--------------------------------- 
L9950   CMP #$FF 
        BNE L993E
        LDA $69
        BPL L993E
L9958   LDA $69
        STA $4F
L995C   JMP L997E
--------------------------------- 
L995F   DEX
        BNE L997E
        LDA $4B
        CMP #$14 
        BEQ L996C
        CMP #$0A 
        BNE L9970
L996C   LDY #$03 
        STY $4D
L9970   CLC
        ADC $4C
        TAY
        LDA L9FA8,Y
        BNE L997C
        JMP L98E5
--------------------------------- 
L997C   STA $4B
L997E   LDA $4B
        STA $4E
        LDY $4D
        DEY
L9985   LDA $004E,Y
        JSR L998F
        DEY
        BPL L9985
        RTS
--------------------------------- 
L998F   PHA
        LDA $7A
        SEC
        SBC $43
        STA $41
        LDA $7B
        SBC $44
        STA $42
        TYA
        CLC
        ADC $41
        BCC L99A5
        INC $42
L99A5   STA $41
        LDA $42
        CMP #$08 
        BCC L99BB
        CMP #$A0 
        BCS L99BB
        PLA
        STY $0B
        LDY #$00 
        STA ($41),Y
        LDY $0B
        RTS
--------------------------------- 
L99BB   PLA
        RTS
--------------------------------- 
L99BD   LDY #$00 
        STY $68
        STY $90
        JSR L9AB0
        JSR IECIN
        TAX
        JSR IECIN
        LDY $90
        BEQ L99D5
        LDA #$FF 
        LDX #$FF 
L99D5   STA $62
        STX $63
        LDX #$90 
        SEC
        JSR FLOATC
        JSR FLPSTR
        LDY #$05 
        LDX #$FF 
L99E6   INX
        LDA $0100,X
        BNE L99E6
L99EC   DEX
        BMI L99F2
        LDA $0100,X
L99F2   STA $0200,Y
        DEY
        BPL L99EC
        LDY #$06 
        STA $0200,Y
        INY
        LDX $90
        BNE L9A12
L9A02   JSR IECIN
        LDX $90
        BNE L9A12
        TAX
        BEQ L9A20
        STA $0200,Y
        INY
        BNE L9A02
L9A12   LDA #$2E 
        STA $0200,Y
        INY
        LDA #$80 
        STA $0200,Y
        INY
        LDA #$00 
L9A20   STA $0200,Y
        JSR UNTALK
        LDY #$00 
        STY $0C
        STY $23
        STY $22
L9A2E   LDY $22
        INC $22
        LDA $0200,Y
        BMI L9A50
        CMP #$22 
        BNE L9A43
        LDA $0C
        EOR #$FF 
        STA $0C
        LDA #$22 
L9A43   LDY $23
        STA $0139,Y
        TAX
        BNE L9A4C
        RTS
--------------------------------- 
L9A4C   INC $23
        BNE L9A2E
L9A50   CMP #$FF 
        BEQ L9A43
        BIT $0C
        BMI L9A43
        TAX
        LDY #$9E 
        STY $62
        LDY #$A0 
        STY $63
        LDY #$00 
        ASL
        BEQ L9A78
L9A66   DEX
        BPL L9A77
L9A69   INC $62
        BNE L9A6F
        INC $63
L9A6F   LDA ($62),Y
        BPL L9A69
        BMI L9A66
L9A75   INC $23
L9A77   INY
L9A78   LDX $23
        LDA ($62),Y
        PHA
        AND #$7F 
        STA $0139,X
        PLA
        BPL L9A75
        BMI L9A4C
L9A87   TYA
        ADC #$40 
        STA $BB
        LDA #$01 
        STA $BC
        LDA $0131
        STA $BA
        JSR $F648
        JSR L9A9E
        JMP L95F6
--------------------------------- 
L9A9E   LDA $0131
        STA $BA
        LDA #$60 
        STA $B9
        JSR L9AC3
        JSR L9AB0
        JMP UNTALK
--------------------------------- 
L9AB0   LDA $0131
        STA $BA
        JSR TALK
        LDA #$60 
        JSR TKSA
        JSR IECIN
        JMP IECIN
--------------------------------- 
L9AC3   JSR L9ACB
        BCC L9ACE
        JMP EREXIT
--------------------------------- 
L9ACB   JSR $F3D5
L9ACE   RTS
--------------------------------- 
L9ACF   LDY #$02 
L9AD1   LDA $0110,Y
        STA $0024,Y
        AND #$40 
        BEQ L9AFD
        DEY
        BPL L9AD1
        LDA $26
        ASL
        ASL
        ASL
        LDX #$03 
L9AE5   ASL
        ROL $25
        DEX
        BPL L9AE5
        ROL $24
        CPX #$FD 
        BNE L9AE5
        LDY #$37 
L9AF3   LDA $24
        CMP L9F00,Y
        BEQ L9B00
L9AFA   DEY
        BPL L9AF3
L9AFD   LDA #$00 
        RTS
--------------------------------- 
L9B00   LDA $25
        CMP L9F38,Y
        BNE L9AFA
        LDA L9F70,Y
        LDX #$05 
        CPY #$1F 
        BCS L9B20
        DEX
        CPY #$16 
        BCS L9B20
        DEX
        CPY #$0E 
        BCS L9B20
        DEX
        CPY #$08 
        BCS L9B20
        DEX
L9B20   STA $4B
        TXA
        RTS
--------------------------------- 
L9B24   LDA $FC
        JSR L9B2B
        LDA $FB
L9B2B   PHA
        LSR
        LSR
        LSR
        LSR
        JSR L9B34
        PLA
L9B34   AND #$0F 
        ORA #$30 
        CMP #$3A 
        BCC L9B3E
        ADC #$06 
L9B3E   JMP CHROUT
--------------------------------- 
L9B41   !by $53,$59,$4E,$54,$41,$58,$00     ; SYNTAX.

L9B48   !by $4F,$4E,$45,$20,$42,$59,$54,$45 ; ONE BYTE
        !by $20,$52,$41,$4E,$47,$45,$00     ; RANGE.

L9B57   !by $52,$45,$4C,$41,$54,$49,$56,$20 ; RELATIV 
        !by $42,$52,$41,$4E,$43,$48,$00     ; BRANCH.

L9B66   !by $49,$4C,$4C,$45,$47,$41,$4C,$20 ; ILLEGAL 
        !by $4F,$50,$45,$52,$41,$4E,$44,$00 ; OPERAND.

L9B76   !by $55,$4E,$44,$45,$46,$49,$4E,$45 ; UNDEFINE 
        !by $44,$20,$44,$49,$52,$45,$43,$54 ; D DIRECT
        !by $49,$56,$45,$00                 ; IVE.

L9B8A   !by $44,$55,$50,$4C,$49,$43,$41,$54 ; DUPLICAT
        !by $45,$20,$53,$59,$4D,$42,$4F,$4C ; E SYMBOL
        !by $00
L9B9B   !by $55,$4E,$44,$45,$46,$49,$4E,$45 ; UNDEFINE
        !by $44,$20,$53,$59,$4D,$42,$4F,$4C ; D SYMBOL
        !by $00

L9BAC   !by $20,$45,$52,$52,$4F,$52,$00     ; ERROR.
L9BB3   !by $45,$4E,$44                     ; END
L9BB6   !by $54,$45,$58,$54                 ; TEXT
L9BBA   !by $57,$4F,$52,$54                 ; WORT
L9BBE   !by $44,$49,$53,$50                 ; DISP
L9BC2   !by $42,$59,$54,$45                 ; BYTE
L9BC6   !by $4C,$4F,$41,$44                 ; LOAD
L9BCA   !by $43,$4F,$52,$52                 ; CORR

; ----------------------------------------------
; - part of Assembler, will be copied to RAM ---
; ----------------------------------------------
L9BCE   STX $01
        LDX #$03 
L9BD2   STA $22
        STY $23
        CPY $2E
        BNE L9BDC
        CMP $2D
L9BDC   BCS L9C01
        LDY #$05 
L9BE0   LDA ($22),Y
        CMP $0110,Y
        BNE L9BEE
        DEY
        BPL L9BE0
        INC $48
        BNE L9C01
L9BEE   LDY $23
        LDA $22
        CLC
        ADC #$08 
        BCC L9BD2
        INY
        BCS L9BD2
        LDA #$00 
        SEI
        STA $01
        LDA ($22),Y
L9C01   PHA
        LDA #$37 
        STA $01
        PLA
        CLI
        RTS
--------------------------------- 
        PHA
        LDA #$00 
        SEI
        STA $01
        PLA
        STA ($2D),Y
        JMP $037A
--------------------------------- 

L9C15   !by $0D,$50,$52,$4F,$47,$52,$41,$4D ; .PROGRAM
        !by $4E,$41,$4D,$45,$20,$20,$3A,$20 ; NAME  : 
        !by $00 

L9C26   !by $0D,$50,$52,$49,$4E,$54,$4F,$55 ;.PRINTOU
        !by $54,$20,$4D,$4F,$44,$45,$3A,$20 ; T MODE: 
        !by $00

L9C37   !by $4C,$49,$4E,$45,$53,$3A,$00     ; LINES:.

L9C3E   !by $20,$20,$20,$53,$59,$4D,$42,$4F ;   SYMBO
        !by $4C,$53,$3A,$00                 ; LS:.

L9C4A   !by $20,$20,$20,$45,$52,$52,$4F,$52 ;    ERROR
        !by $53,$3A,$00                     ; S:.

L9C55   !by $50,$41,$47,$45,$3A,$00         ; PAGE:.

L9C5B   !by $40,$02,$45,$03,$D0,$08,$40,$09 ; @.E...@.
        !by $30,$22,$45,$33,$D0,$08,$40,$09 ; 0"E3..@.
        !by $40,$02,$45,$33,$D0,$08,$40,$09 ; @.E3..@.
        !by $40,$02,$45,$B3,$D0,$08,$40,$09 ; @.E...@.
        !by $00,$22,$44,$33,$D0,$8C,$44,$00 ; ."D3..D.
        !by $11,$22,$44,$33,$D0,$8C,$44,$9A ; ."D3..D.
        !by $10,$22,$44,$33,$D0,$08,$40,$09 ; ."D3..@.
        !by $10,$22,$44,$33,$D0,$08,$40,$09 ; ."D3..@.
        !by $62,$13,$78,$A9
L9C9F   !by $00,$41,$01,$02,$00,$20,$99,$8D
        !by $11,$12,$06,$8A,$05
L9CAC   !by $21,$2C,$29,$2C,$41,$23
L9CB2   !by $28,$59,$00,$58,$00,$00,$00
L9CB9   !by $14,$82,$14,$1B,$54,$83,$13,$99
        !by $95,$82,$15,$1B,$95,$83,$15,$99
        !by $00,$21,$10,$A6,$61,$A0,$10,$1B
        !by $1C,$4B,$13,$1B,$1C,$4B,$11,$99
        !by $00,$12,$53,$53,$9D,$61,$1C,$1C
        !by $A6,$A6,$A0,$A4,$21,$00,$73,$00
        !by $0C,$93,$64,$93,$9D,$61,$21,$4B
        !by $7C,$0B,$2B,$09,$9D,$61,$1B,$98
L9CF9   !by $96,$20,$18,$06,$E4,$20,$52,$46
        !by $12,$02,$86,$12,$26,$02,$A6,$52
        !by $00,$72,$C6,$42,$32,$72,$E6,$2C
        !by $32,$B2,$8A,$08,$30,$B0,$62,$48
        !by $00,$68,$60,$60,$32,$32,$32,$30
        !by $02,$26,$70,$F0,$70,$00,$E0,$00
        !by $D8,$D8,$E4,$E4,$30,$30,$46,$86
        !by $82,$88,$E4,$06,$02,$02,$60,$86
; - $9D39  module information message ----------
L9D39   !by $0D,$20,$20,$20,$20,$2A,$2A ; .. ;,$**
        !by $2A,$2A,$20,$20,$20,$20,$48,$45 ; ** ;,$HE
        !by $4C,$50,$20,$20,$43,$2D,$36,$34 ; LP  C-64
        !by $20,$20,$50,$4C,$55,$53,$20,$20 ;   PLUS  
        !by $20,$2A,$2A,$2A,$2A,$20,$20,$20 ; ,$**** ;
        !by $20,$0D,$00 ;  ..

; - $9D63  undef'd statement error -------------
L9D63   !by $55,$4E,$44,$45,$46,$27,$44,$20 ; UNDEF'D 
        !by $53,$54,$41,$54,$45,$4D,$45,$4E ; STATEMEN
        !by $54,$20,$45,$52,$52,$4F,$52,$20 ; T ERROR 
        !by $00

; - $9D7C  overwrite message text --------------
L9D7C   !by $0D,$4F,$56,$45,$52,$57,$52,$49 ; .OVERWRI
        !by $54,$45,$3F,$20,$12,$59,$92,$45 ; TE? .Y.E
        !by $53,$2F,$12,$4E,$92,$4F,$0D,$00 ; S/.N.O..

; - $9D94  DOS and monitor commands char -------
L9D94   !by $3E,$40,$3C,$2F,$5E,$24,$5D,$23 ; >@</^$]#
        !by $21,$5F,$2A,$28,$29,$25,$5C,$5B ; !_*()%£[

; - $9DA4  commands low byte -------------------
DMLBYT  !by <RDCH15,<RDDCH,<VERIFY,<LDREL,<LDRUN,<LDDIR,<MONI,<BASCMD
        !by <CONVERT,<SAVEPRG,<PRTFRE,<OPNFILE,<CLFILE,<LDABS,<SETIONO,<ASSEMBLER

; - $9DB4  commands high byte ------------------
DMHBYT  !by >RDCH15,>RDDCH,>VERIFY,>LDREL,>LDRUN,>LDDIR,>MONI,>BASCMD
        !by >CONVERT,>SAVEPRG,>PRTFRE,>OPNFILE,>CLFILE,>LDABS,>SETIONO,>ASSEMBLER

; - #9DC4  basic commands char -----------------
L9DC4   !by $41,$44,$45,$46,$47,$48,$4B,$4C ; ADEFGHKL
        !by $4D,$52,$53,$54,$56,$55,$43,$42 ; MRSTVUCB
; - #9DD4  basic commands low byte -------------
L9DD4   !by <APPEND,<DELETE,<ENDTRACE,<FIND,<GENLINE,<HELP,<KILL,<LPAGE
        !by <M_DUMP,<RENUMBER,<S_STEP,<TRACE,<V_DUMP,<UNDEF,<COMPACTOR,<RENEW
; - #9DE4  basic commands high byte ------------
L9DE4   !by >APPEND,>DELETE,>ENDTRACE,>FIND,>GENLINE,>HELP,>KILL,>LPAGE
        !by >M_DUMP,>RENUMBER,>S_STEP,>TRACE,>V_DUMP,>UNDEF,>COMPACTOR,>RENEW

	!align 255, 0, 0

!pseudopc $DE00 {

; thsi part will be mirrored to $DE00 ------------
LDE00   DEC $01					; no cartridge, no BASIC ROM, RAM below readable

        LDA ($5F),Y
        PHA
        INC $01					; activate cartridge and BASIC ROM
        PLA
        RTS
--------------------------------- 
LDE09   STA $55					; set $55,
LDE0B   JSR LDE16				; set $56 and JMP ($55) with module off
        LDY #$80
        STY LDE09				; module on, again
        RTS
--------------------------------- 
LDE14   STA $55
LDE16   STY $56
        LDY #$F2 
        STY LDE14				; module off
LDE1D   JMP ($0055)
--------------------------------- 
LDE20   LDA #$04 
        STA LDE20				; module on
        JMP L8053				; direct mode: read BASIC line from keyboard and execute
--------------------------------- 
LDE28   DEX
        STX LDE28				; module off
        JSR CRUNCH				; Crunch BASIC tockens (vector $0304)
        JMP $A7E1				; start into interpreter loop (vector $0308)
--------------------------------- 
LDE32   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        LDA ($45),Y
        PHA
        INC $01					; activate cartridge and BASIC ROM
        PLA
        RTS
--------------------------------- 
LDE3B   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        LDA ($7A),Y
        PHA
        INC $01					; activate cartridge and BASIC ROM
        PLA
        RTS
--------------------------------- 
LDE44   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        LDA ($22),Y
        PHA
        INC $01					; activate cartridge and BASIC ROM
        PLA
        RTS
--------------------------------- 
LDE4D   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        CMP ($0B),Y
        PHP
        INC $01					; activate cartridge and BASIC ROM
        PLP
        RTS
--------------------------------- 
	!fill 10, 0
--------------------------------- 
LDE60   INC $7A					; increment CHRGET pointer
        BNE +
        INC $7B
+
LDE66   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        JSR CHRGOT
        PHP
        INC $01					; activate cartridge and BASIC ROM
        PLP
        RTS
--------------------------------- 
LDE70   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
        JSR SAVE
        INC $01					; activate cartridge and BASIC ROM
        RTS
--------------------------------- 
; copy ($22) one byte up until $7a/$7b with module off
LDE78   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
-       LDA $22
        BNE +
        DEC $23
+       DEC $22
        LDY #$00 
        LDA ($22),Y
        INY
        STA ($22),Y
        LDA $22
        CMP $7A
        BNE -
        LDA $23
        CMP $7B
        BNE -
        INC $01					; activate cartridge and BASIC ROM
        RTS
--------------------------------- 
LDE98   LDA #$28 
        STA LDE98				; module on
        JMP L86AB				; continue TRACE
--------------------------------- 

        !by $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff

--------------------------------- 
LDEA8   LDY #$44 
        STY LDEA8
        JMP L802B				; initialize the modul
--------------------------------- 
; copy ($22) to ($24) X pages upwards with module off
LDEB0   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
-       LDA ($22),Y
        STA ($24),Y
        INY
        BNE -
        INC $23
        INC $25
        DEX
        BNE -
        INC $01					; activate cartridge and BASIC ROM
        RTS
--------------------------------- 
; copy ($22) one byte down until $2d/$2e with module off
LDEC3   DEC $01					; no cartridge, no BASIC ROM, RAM below readable
-       LDY #$01 
        LDA ($22),Y
        DEY
        STA ($22),Y
        INC $22
        BNE +
        INC $23
+       LDA $22
        CMP $2D
        BNE -
        LDA $23
        CMP $2E
        BNE -
        INC $01					; activate cartridge and BASIC ROM
        RTS
--------------------------------- 
LDEE1   LDA #$EE 
        STA LDEE1				; module off
        LDA #$00 
        JSR LDE1D				; JMP ($55)
        PHA					; keep return value
        LDA #$F4 
        STA LDEE1				; module on
        PLA					; return A
        RTS
--------------------------------- 
}

	!align 255, 0, 0

L9F00   !by $09,$0B,$1B,$2B,$61,$7C,$98,$9D ;...+....
        !by $0C,$21,$4B,$64,$93,$93,$10,$10 ;.!K.....
        !by $11,$13,$13,$14,$15,$15,$12,$1C ;........
        !by $1C,$53,$54,$61,$61,$9D,$9D,$14 ;.ST.....
        !by $1B,$1B,$1B,$1B,$21,$21,$4B,$4B ;....!!KK
        !by $73,$82,$82,$83,$83,$95,$95,$99 ;........
        !by $99,$99,$A0,$A0,$A4,$A6,$A6,$A6 ;........

L9F38   !by $06,$88,$60,$E4,$02,$82,$86,$02 ;........
        !by $D8,$46,$86,$E4,$D8,$E4,$C6,$E6 ;.F......
        !by $62,$52,$8A,$18,$86,$A6,$68,$30 ;.R.....0
        !by $32,$60,$E4,$30,$32,$30,$32,$96 ;2..0202.
        !by $06,$08,$12,$2C,$70,$72,$B0,$B2 ;...,....
        !by $E0,$02,$20,$02,$20,$12,$26,$46 ;.. . .&F
        !by $48,$52,$70,$72,$F0,$02,$26,$42 ;HR....&B

L9F70   !by $61,$21,$C1,$41,$A1,$01,$E1,$81 ;.!.A....
        !by $02,$C2,$E2,$42,$22,$62,$90,$B0 ;...B"...
        !by $F0,$30,$D0,$10,$50,$70,$00,$1E ;.0..P...
        !by $28,$0A,$14,$32,$3C,$46,$50,$00 ;(..2<FP.
        !by $18,$D8,$58,$B8,$CA,$88,$E8,$C8 ;..X.....
        !by $EA,$48,$08,$68,$28,$40,$60,$38 ;.H..(@.8
        !by $F8,$78,$AA,$A8,$BA,$8A,$9A,$98 ;........

L9FA8   !by $00,$24,$00,$2C,$00,$00,$00,$00 ;.$.,....
        !by $00,$00,$00,$4C,$00,$4C,$00,$00 ;...L.L..
        !by $00,$00,$6C,$00,$00,$20,$00,$20 ;..... . 
        !by $00,$00,$00,$00,$00,$00,$00,$E4 ;........
        !by $E0,$EC,$00,$00,$00,$00,$00,$00 ;........
        !by $00,$C4,$C0,$CC,$00,$00,$00,$00 ;........
        !by $00,$00,$00,$A6,$A2,$AE,$00,$00 ;........
        !by $BE,$00,$00,$B6,$00,$A4,$A0,$AC ;........
        !by $00,$B4,$00,$BC,$00,$00,$00,$86 ;........
        !by $00,$8E,$00,$00,$00,$00,$00,$96 ;........
        !by $00,$84,$00,$8C,$00,$94,$00,$00 ;........