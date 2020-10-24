; -*- mode: gas; gas-opcode-column: 8; gas-argument-column: 16; gas-comment-column: 32; -*-
;
; new variables:

;       DAL             ; DumpAddressLow RAM
;       DAH             ; DumpAddressHigh RAM
;       DDL8            ; DumpDataLow8
;       DDH2            ; DumpDataHigh2
;       DASL            ; DumpAddressLowShifted Flash (Every RAM Word requires TWO Flash bytes!)
;       DASH            ; DumpAddressHighShifted Flash
;       DASL2
;       DASH2
;       COUNTER         ; 32Words
;       COUNTER_HI
;       LOOPCOUNT       ; 128 times (32 x 128 = 4096 words)
;       PACKH2

#include "p18f2620.h"
#include "FeRAM.h"

        .extern flashdisable, ctrlRR, DAH, DAL, DASH, DASH2, DASL, DASL2
        .extern LOOPCOUNT, rammap01, ramchip, ramchipH, ramchipL
        .extern ctrlRR, ctrlwrd, DDH2, DDL8, s4nop, s6nop, ferclk
        .extern COUNTER, COUNTER_HI, PACKH2


;********************************************************************************************************
;
; Flash EPROM programming block routine for NoV-64 version 08r.
;
; This routine will take about 2.5 seconds to complete RAM to Flash programming.
;
; H'4100 register detail
;
; b9 b8 = oph2. Must be 3 to trigger RAM to Flash dumping
;
; b7 b6 b5 b4 b3 b2 b1 b0 = opl8.
;- Bits 1 & 0 indicate the active RAM chip (up to 4 chips in NoV-64)
;- Bits 5 & 4 indicate the page number to be copied into Flash (within the active chip)
;
;                       bit 5=0 & bit 4=0, RAM page #8 in HP-41
;                       bit 5=0 & bit 4=1, RAM page #9 in HP-41
;                       bit 5=1 & bit 4=0, RAM page #A in HP-41
;                       bit 5=1 & bit 4=1, RAM page #B in HP-41
;__________________________________________________________________________________

        .section code2
        .public  RAM2ROM4
RAM2ROM4
RRW                             ; Accepts an HP-41 address, in the RAM area (DAH & DAL)
                                ; and returns the 10bit word (DDH2 & DDL8) contained in that address
        bcf     WDTCON,0
        bsf     flashdisable,0
        clrf    PORTA           ; PORTA is all "0's" and output.
        clrf    TRISA

        movf    ctrlRR,W

        andlw   0x30            ; filters bits 5 & 4
                                ; put them into address bits A12 & A13
        movwf   DAH             ; Points to desired page into selected chip
        clrf    DAL             ; Address initialized

        clrf    TBLPTRU
        movlw   0xEF
        movwf   DASH            ; To Dump Address High for L8
        movlw   0x3B
        movwf   DASH2           ; To Dump Address High for H2
        setf    DASL            ; Points to Flash area (H'E000 - H'FFFF)
        setf    DASL2

        movlw   0x10
        movwf   LOOPCOUNT       ; 16 Loops 512 bytes each
;       tblrd*-

        clrf    rammap01
        clrf    ramchipH
        movf    ctrlRR,W        ; Gets control byte
        andlw   0x03            ; And turns ON selected RAM chip.
        movwf   ctrlwrd
        bz      chipis0
        decf    WREG
        bz      chipis1
        decf    WREG
        bz      chipis2
        bsf     ramchipL,5
        bsf     ramchip,5
        bsf     PORTA,5
        bra     flashing
chipis0
        bsf     PORTA,2
        bsf     ramchipL,2
        bsf     ramchip,2
        bra     flashing
chipis1
        bsf     PORTA,3
        bsf     ramchipL,3
        bsf     ramchip,3
        bra     flashing
chipis2
        bsf     PORTA,4
        bsf     ramchipL,4
        bsf     ramchip,4
flashing
RAMbytes

        movlw   0x02
        movwf   FSR2H
        clrf    FSR2L           ; PIC-RAM Buffer initialized (H'0200 - H'03FF)

RAMREADS
        call    ReadFeRAM

        movff   DDH2,POSTINC2
        movff   DDL8,POSTINC2

        incf    DAL
        bnc     nextadd
        incf    DAH
nextadd
        btfss   FSR2H,2         ; Reached RAM buffer limit (512bytes)?
        bra     RAMREADS        ; NO, keep on reading RAM

Write512                        ; RAM buffer is full, time to burn Flash

        rrcf    FSR2H           ; re-initializes PIC-RAM buffer
        call    WrBufferBack    ; Writes Flash buffer
        decfsz  LOOPCOUNT
        bra     RAMbytes
        return

ReadFeRAM
        bsf     RAMCLK          ; Set SCL high
        nop                     ; CLK ___/¯¯¯¯¯¯
        nop
        bsf     RAMDAT          ; Set SDT high (STOP condition)
        call    s4nop           ; DAT _______/¯¯
        bcf     RAMDAT          ; SDT to "0" (Start sequence)
        nop                     ; DAT ¯\________
        nop
        bcf     RAMCLK          ; Sets SCL low
        call    s6nop

        bsf     RAMDAT          ; SDT to "1" (Start slave address "B'10100000")
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 2nd bit)
        call    ferclk
        call    s4nop

        bsf     RAMDAT          ; SDT to "1" (Slave address "B'10100000" 3rd bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 4th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 5th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 6th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 7th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100000" 8th bit)
        call    ferclk
        call    s4nop

        bsf     DATDIR          ; Set RAMDAT as Input for ACK
        call    ferclk
        call    s4nop

        bcf     DATDIR          ; Set RAMDAT as output again.

        bcf     RAMDAT          ; SDT to "0", first Address to RAM (A15) always "0"
        call    ferclk
        call    s4nop

        btfsc   DAL,0
        bsf     RAMDAT          ; Write SDT to address L,0 sent as A14
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,1
        bsf     RAMDAT          ; Write SDT to address L,1 sent as A13
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,2
        bsf     RAMDAT          ; Write SDT to address L,2 sent as A12
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,3
        bsf     RAMDAT          ; Write SDT to address L,3 sent as A11
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,4
        bsf     RAMDAT          ; Write SDT to address L,4 sent as A10
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,5
        bsf     RAMDAT          ; Write SDT to address L,5 sent as A9
        call    ferclk

        bcf     RAMDAT
        btfsc   DAL,6
        bsf     RAMDAT          ; Write SDT to address L,6 sent as A8
        call    ferclk

        bsf     DATDIR          ; Set RAMDAT as Input for ACK
        call    ferclk
        bcf     DATDIR          ; Set RAMDAT as output again.
        call    s4nop

        bcf     RAMDAT
        btfsc   DAL,7
        bsf     RAMDAT          ; Write SDT to address L,7 sent as A7
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,0
        bsf     RAMDAT          ; Write SDT to address H,0 sent as A6
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,1
        bsf     RAMDAT          ; Write SDT to address H,1 sent as A5
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,2
        bsf     RAMDAT          ; Write SDT to address H,2 sent as A4
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,3
        bsf     RAMDAT          ; Write SDT to address H,3 sent as A3
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,4
        bsf     RAMDAT          ; Write SDT to address H,4 sent as A2
        call    ferclk

        bcf     RAMDAT
        btfsc   DAH,5
        bsf     RAMDAT          ; Write SDT to address H,5 sent as A1
        call    ferclk

        bcf     RAMDAT          ; SDT to "0", last Address to RAM (A0) always "0"
        call    ferclk

        bsf     DATDIR          ; Set RAMDAT as Input for ACK
        call    ferclk
        bcf     DATDIR          ; Set RAMDAT as output again.
        call    s4nop

        bsf     RAMDAT          ; Sends START sequence again
        nop
        nop
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop
        nop
        bcf     RAMDAT
        nop
        nop
        bcf     RAMCLK
        call    s4nop

        bsf     RAMDAT          ; SDT to "1" (Start slave address "B'10100001")
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 2nd bit)
        call    ferclk
        call    s4nop

        bsf     RAMDAT          ; SDT to "1" (Slave address "B'10100001" 3rd bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 4th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 5th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 6th bit)
        call    ferclk
        call    s4nop

        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 7th bit)
        call    ferclk
        call    s4nop

        bsf     RAMDAT          ; SDT to "1" (Slave address "B'10100001" 8th bit)
        call    ferclk
        call    s4nop

        bsf     DATDIR          ; Set RAMDAT as Input for ACK and Data
        call    ferclk

        clrf    DDL8
        clrf    DDH2
        call    s4nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,0          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,1          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,2          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,3          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,4          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,5          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,6          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDL8,7          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s4nop

        bcf     RAMDAT          ; Acknowledge: DAT = "0"
        bcf     DATDIR          ; Set RAMDAT as Output for ACK
        call    ferclk
        bsf     DATDIR          ; Set RAMDAT as Input again.
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDH2,0          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop

        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     DDH2,1          ; 3
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s4nop

        call    ferclk          ; bit2
        call    s4nop

        call    ferclk          ; bit3
        call    s4nop

        call    ferclk          ; bit4
        call    s4nop

        call    ferclk          ; bit5
        call    s4nop

        call    ferclk          ; bit6
        call    s4nop

        call    ferclk          ; bit7
        call    s4nop

        bsf     RAMDAT          ; NOT Acknowledge: DAT = "1"
        bcf     DATDIR          ; Set RAMDAT as Output for NO-ACK
        call    ferclk
        bcf     RAMDAT

        return

;--------------------------------- Writes into Flash
WrBufferBack                    ; First we write L8
        movff   DASH,TBLPTRH    ; Points to L8 Flash area at F000-FFFF
        movff   DASL,TBLPTRL

        MOVLW   0x20            ; number of write buffer groups of 8 bytes
        MOVWF   COUNTER_HI

ProgramLoop
        MOVLW   0x08            ; number of bytes in holding register
        MOVWF   COUNTER
WrWord2Hregs
        MOVF    POSTINC2, W     ; Dummy read to skip H2 data
        MOVF    POSTINC2, W     ; get low byte of buffer data
        MOVWF   TABLAT          ; present data to table latch
        TBLWT   +*              ; write data, perform a short write
                                ; to internal TBLWT holding register.
        DECFSZ  COUNTER         ; loop until buffers are full
        BRA     WrWord2Hregs

;******************************** Program Memory

        BSF     EECON1,EEPGD    ; point to FLASH program memory
        BCF     EECON1,CFGS     ; access FLASH program memory
        BSF     EECON1,WREN     ; enable write to memory
;       BCF     INTCON,GIE      ; disable interrupts

        MOVLW   0x55
        MOVWF   EECON2          ; write 55h
        MOVLW   0xAA
        MOVWF   EECON2          ; write AAh

        BSF     EECON1,WR       ; start program (CPU stall)
;       BSF     INTCON,GIE      ; re-enable interrupts
        DECFSZ  COUNTER_HI      ; loop until done
        BRA     ProgramLoop
        BCF     EECON1,WREN     ; disable write to memory

        movff   TBLPTRH,DASH
        movff   TBLPTRL,DASL
;--------------------------------- Then we write H2
WrBufferBack2
        rrcf    FSR2H           ; re-initializes PIC-RAM buffer
        movff   DASH2,TBLPTRH   ; Points to H2 Flah area at 3C00-3FFF
        movff   DASL2,TBLPTRL

        MOVLW   0x08            ; number of write buffer groups of 8 bytes
        MOVWF   COUNTER_HI

ProgramLoop2
        MOVLW   0x08            ; number of bytes in holding register
        MOVWF   COUNTER
WrWord2Hregs2

        movf    POSTINC2, W
        andlw   0x03
        movwf   PACKH2
        movf    POSTINC2, W     ; Dummy read

        movf    POSTINC2, W
        andlw   0x03
        rlncf   WREG
        rlncf   WREG
        addwf   PACKH2
        movf    POSTINC2, W     ; Dummy read

        movf    POSTINC2, W
        andlw   0x03
        swapf   WREG
        addwf   PACKH2
        movf    POSTINC2, W     ; Dummy read

        movf    POSTINC2, W
        andlw   0x03
        rrncf   WREG
        rrncf   WREG
        addwf   PACKH2
        movf    POSTINC2, W     ; Dummy read
        movf    PACKH2,W

        MOVWF   TABLAT          ; present data to table latch
        TBLWT   +*              ; write data, perform a short write
                                ; to internal TBLWT holding register.
        DECFSZ  COUNTER         ; loop until buffers are full
        BRA     WrWord2Hregs2

;******************************** Program Memory

        BSF     EECON1,EEPGD    ; point to FLASH program memory
        BCF     EECON1,CFGS     ; access FLASH program memory
        BSF     EECON1,WREN     ; enable write to memory
;       BCF     INTCON,GIE      ; disable interrupts

        MOVLW   0x55
        MOVWF   EECON2          ; write 55h
        MOVLW   0xAA
        MOVWF   EECON2          ; write AAh

        BSF     EECON1,WR       ; start program (CPU stall)
;       BSF     INTCON,GIE      ; re-enable interrupts
        DECFSZ  COUNTER_HI      ; loop until done
        BRA     ProgramLoop2
        BCF     EECON1,WREN     ; disable write to memory

        movff   TBLPTRH,DASH2
        movff   TBLPTRL,DASL2


        RETURN
