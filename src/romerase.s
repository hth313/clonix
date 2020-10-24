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

        .public ROMERASE
        .extern flashdisable, flashstat, LOOPCOUNT
        .extern romfb1map, romfb2map, romfb3map, romfb4map

        .section code2
ROMERASE
RRW0                            ; Accepts an HP-41 address, in the RAM area (DAH & DAL)
                                ; and returns the 10bit word (DDH2 & DDL8) contained in that address
        bcf     WDTCON,0

        bcf     flashdisable,2  ; Flash erase process enabled.
        clrf    flashstat
        clrf    romfb1map       ; Remmoves ROM page #F mapping
        clrf    romfb2map
        clrf    romfb3map
        clrf    romfb4map

        clrf    PORTA           ; PORTA is all "0's" and output.
        setf    TRISA

        clrf    TBLPTRU
        movlw   0xF0
        movwf   TBLPTRH         ; To Dump Address High for L8
        clrf    TBLPTRL         ; Points to Flash area (H'E000 - H'FFFF)
        movlw   0x40            ; 64 loops x 64bytes = 4096
        movwf   LOOPCOUNT


        call    EraseRow

        movlw   0x3C            ; Sets ponter to flash ares (H'3C00-H'3FFF)
        movwf   TBLPTRH
        clrf    TBLPTRL
        movlw   0x10            ; 16 loops x 64 bytes = 1024
        movwf   LOOPCOUNT
        movlw   0x40

        call    EraseRow

        return

EraseRow
        bsf     EECON1, EEPGD   ; point to Flash program memory
        bcf     EECON1, CFGS    ; access Flash program memory
        bsf     EECON1, WREN    ; enable write to memory
        bsf     EECON1, FREE    ; enable Row Erase operation
;       BCF     INTCON, GIE     ; disable interrupts
        movlW   0x55
        movwf   EECON2          ; write 55h
        movlw   0xAA
        movwf   EECON2          ; write 0AAh
        bsf     EECON1, WR      ; start erase (CPU stall)
;       BSF     INTCON, GIE     ; re-enable interrupts

        movlw   0x40
        addwf   TBLPTRL
        bnc     loopcont
        incf    TBLPTRH
loopcont
        decfsz  LOOPCOUNT
        bra     EraseRow

        return

