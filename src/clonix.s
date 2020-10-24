;;; -*- mode: gas; gas-opcode-column: 16; gas-argument-column: 24; gas-comment-column: 40; -*-
;;;
;;; Standard Clonix module, 6 HP-41 ROM pages.
;;;
;;; Written by Diego Díaz, adapted to NutStudio by Håkan Thörngren
;;;


#include "p18f252.h"


; Definitions of I/O lines

#define NUTPHI1 PORTB,2
#define NUTPHI2 PORTB,6
#define NUTSYNC PORTB,5
#define NUTISA  PORTB,4
#define NUTPWO  PORTB,0

                .section config, rodata
                .byte   0xff            ; Will be mapped to address 300000
                .byte   0x22            ; -*- Enables HS oscillator mode
                .byte   0x0d            ; -*- Prevents Brown out Reset
                .byte   0x0e            ; -*- Disables Watch Dog Timer
                .byte   0xff
                .byte   0xff
                .byte   0x80            ; -*- Disables Low Voltage Programming
                .byte   0xff

                .section variables, bss
                .public rom0b1map, rom1b1map, rom2b1map, rom3b1map, rom4b1map, rom5b1map
                .public rom6b1map, rom7b1map, rom8b1map, rom9b1map, romab1map, rombb1map
                .public romcb1map, romdb1map, romeb1map, romfb1map
                .public rom0b2map, rom1b2map, rom2b2map, rom3b2map, rom4b2map, rom5b2map
                .public rom6b2map, rom7b2map, rom8b2map, rom9b2map, romab2map, rombb2map
                .public romcb2map, romdb2map, romeb2map, romfb2map
                .public rom0b3map, rom1b3map, rom2b3map, rom3b3map, rom4b3map, rom5b3map
                .public rom6b3map, rom7b3map, rom8b3map, rom9b3map, romab3map, rombb3map
                .public romcb3map, romdb3map, romeb3map, romfb3map
                .public rom0b4map, rom1b4map, rom2b4map, rom3b4map, rom4b4map, rom5b4map
                .public rom6b4map, rom7b4map, rom8b4map, rom9b4map, romab4map, rombb4map
                .public romcb4map, romdb4map, romeb4map, romfb4map
rom0b1map       .space  1
rom1b1map       .space  1
rom2b1map       .space  1
rom3b1map       .space  1
rom4b1map       .space  1
rom5b1map       .space  1
rom6b1map       .space  1
rom7b1map       .space  1
rom8b1map       .space  1
rom9b1map       .space  1
romab1map       .space  1
rombb1map       .space  1
romcb1map       .space  1
romdb1map       .space  1
romeb1map       .space  1
romfb1map       .space  1
rom0b3map       .space  1
rom1b3map       .space  1
rom2b3map       .space  1
rom3b3map       .space  1
rom4b3map       .space  1
rom5b3map       .space  1
rom6b3map       .space  1
rom7b3map       .space  1
rom8b3map       .space  1
rom9b3map       .space  1
romab3map       .space  1
rombb3map       .space  1
romcb3map       .space  1
romdb3map       .space  1
romeb3map       .space  1
romfb3map       .space  1
rom0b2map       .space  1
rom1b2map       .space  1
rom2b2map       .space  1
rom3b2map       .space  1
rom4b2map       .space  1
rom5b2map       .space  1
rom6b2map       .space  1
rom7b2map       .space  1
rom8b2map       .space  1
rom9b2map       .space  1
romab2map       .space  1
rombb2map       .space  1
romcb2map       .space  1
romdb2map       .space  1
romeb2map       .space  1
romfb2map       .space  1
rom0b4map       .space  1
rom1b4map       .space  1
rom2b4map       .space  1
rom3b4map       .space  1
rom4b4map       .space  1
rom5b4map       .space  1
rom6b4map       .space  1
rom7b4map       .space  1
rom8b4map       .space  1
rom9b4map       .space  1
romab4map       .space  1
rombb4map       .space  1
romcb4map       .space  1
romdb4map       .space  1
romeb4map       .space  1
romfb4map       .space  1

addru           .space  1               ; upper 8 bits of ISA address
addrl           .space  1               ; lower 8 bits of ISA address
oph2            .space  1               ; high two bits of fetched word
opl8            .space  1               ; low eight bits of fetched word
romoff          .space  1               ; Bank-switching offset (0x00=bank1, 0x10=bank2)
bsmask          .space  1               ; Bank-Switching mask 0xEF


; Reset vector

                .section reset
                goto    begin

; Interrupt 0 (high priority) vector

                .section interrupt
itrrh                                   ; Detected PWO falling edge
                clrf    STKPTR
                bra     start           ; Go to SLEEP and waits for PWO rising edge

                .section code
begin

                clrf    PORTB           ; initialize ports
                clrf    TRISC
                clrf    TRISA
                movlw   0xff            ; port B is input
                movwf   TRISB
                movwf   PORTA
                movwf   PORTC

                clrf    TBLPTRU

; clear memory

                clrf    rom0b1map
                clrf    rom1b1map
                clrf    rom2b1map
                clrf    rom3b1map
                clrf    rom4b1map
                clrf    rom5b1map
                clrf    rom6b1map
                clrf    rom7b1map
                clrf    rom8b1map
                clrf    rom9b1map
                clrf    romab1map
                clrf    rombb1map
                clrf    romcb1map
                clrf    romdb1map
                clrf    romeb1map
                clrf    romfb1map
                clrf    rom0b2map
                clrf    rom1b2map
                clrf    rom2b2map
                clrf    rom3b2map
                clrf    rom4b2map
                clrf    rom5b2map
                clrf    rom6b2map
                clrf    rom7b2map
                clrf    rom8b2map
                clrf    rom9b2map
                clrf    romab2map
                clrf    rombb2map
                clrf    romcb2map
                clrf    romdb2map
                clrf    romeb2map
                clrf    romfb2map
                clrf    rom0b3map
                clrf    rom1b3map
                clrf    rom2b3map
                clrf    rom3b3map
                clrf    rom4b3map
                clrf    rom5b3map
                clrf    rom6b3map
                clrf    rom7b3map
                clrf    rom8b3map
                clrf    rom9b3map
                clrf    romab3map
                clrf    rombb3map
                clrf    romcb3map
                clrf    romdb3map
                clrf    romeb3map
                clrf    romfb3map
                clrf    rom0b4map
                clrf    rom1b4map
                clrf    rom2b4map
                clrf    rom3b4map
                clrf    rom4b4map
                clrf    rom5b4map
                clrf    rom6b4map
                clrf    rom7b4map
                clrf    rom8b4map
                clrf    rom9b4map
                clrf    romab4map
                clrf    rombb4map
                clrf    romcb4map
                clrf    romdb4map
                clrf    romeb4map
                clrf    romfb4map

                clrf    addru           ; upper 8 bits of ISA address
                clrf    addrl           ; lower 8 bits of ISA address
                clrf    oph2            ; high two bits of fetched word
                clrf    opl8            ; low eight bits of fetched word
                clrf    romoff
                movlw   0xEF
                movwf   bsmask

;; load rom mapping

; #include        "mapping.asm"
                .extern Mapping
                rcall   Mapping

;; end load rom mapping

start
                bsf     INTCON2,6       ; Activates INT0 on rising edge
                bcf     INTCON,1        ; Resets INT0 bit
                bsf     INTCON,4        ; Enables INTO
                bcf     INTCON,GIE      ; Globally disables interrupts.

                sleep                   ; Waits until rising edge on PWO (PORTB,0)

                bcf     INTCON,1        ; Resets INT0 bit after PWO rises.
                bcf     INTCON2,6       ; Activates INT0 on falling edge
                bsf     INTCON,GIE      ; Globally enables interrupts.
                clrf    romoff

syncseek
                btfsc   NUTSYNC         ; wait for SYNC to go low
                bra     syncseek
                btfsc   NUTSYNC         ; wait for SYNC to go low
                bra     syncseek
syncfind
                btfss   NUTSYNC
                bra     syncfind
;---------------------------------------------------------
PULSE46x0
                nop
;               nop
;               nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE47x0       ; (1, 1bis)
PULSE47x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE48x0       ; (1, 1bis)
PULSE48x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE49x0       ; (1, 1bis)
PULSE49x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE50x0       ; (1, 1bis)
PULSE50x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE51x0       ; (1, 1bis)
PULSE51x0
                nop
                nop
                nop
;               nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE52x0       ; (1, 1bis)
PULSE52x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE53x0       ; (1, 1bis)
PULSE53x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE54x0       ; (1, 1bis)
PULSE54x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE55x0       ; (1, 1bis)
PULSE55x0
                nop
                nop
                nop
                nop
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     pulse00x        ; (1, 1bis)
pulse00x
                nop                     ; (2)
                nop                     ; (3)
;---------------------------------------------------------

pulse0                                  ; we are now in pulse 0 (detected between 2 and 5 instructions before... assumed 4)
                bsf     TRISB,4         ; (4) bit 4 is input again
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE1          ; (1, 1bis)
PULSE1
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE2          ; (1, 1bis)
PULSE2
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE3          ; (1, 1bis)
PULSE3
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE4          ; (1, 1bis)
PULSE4
                clrf    addru
                clrf    addrl
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE5          ; (1, 1bis)
PULSE5
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE6          ; (1, 1bis)
PULSE6
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE7          ; (1, 1bis)
PULSE7
                nop                     ; (2)
                setf    bsmask          ; (3)
                bcf     bsmask,5        ; (4)
                bcf     bsmask,4        ; (5)
                movf    oph2,W          ; (6)
                andlw   0x07            ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE8          ; (1, 1bis)
PULSE8
                sublw   0x05            ; (2)
                bz      bs              ; (3)
                bsf     opl8,0          ; (4)
bs              rrncf   opl8            ; (5)
                rrncf   opl8            ; (6)
                movf    opl8,W          ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE9          ; (1, 1bis)
PULSE9
                andwf   bsmask,F        ; (2)
                bnz     nobs            ; (3)
                movwf   romoff          ; (4)
nobs            nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE10         ; (1, 1bis)
PULSE10
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE11         ; (1, 1bis)
PULSE11
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
;               nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE12         ; (1, 1bis)
PULSE12
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE13         ; (1, 1bis)
PULSE13
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE14         ; (1, 1bis)
PULSE14
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE15         ; (1, 1bis)
PULSE15
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE16         ; (1, 1bis)
PULSE16
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,0
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE17         ; (1, 1bis)
PULSE17
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,1
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE18         ; (1, 1bis)
PULSE18
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,2
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE19         ; (1, 1bis)
PULSE19
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,3
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE20         ; (1, 1bis)
PULSE20
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,4
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE21         ; (1, 1bis)
PULSE21
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,5
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE22         ; (1, 1bis)
PULSE22
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,6
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE23         ; (1, 1bis)
PULSE23
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addrl,7
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE24         ; (1, 1bis)
PULSE24
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,0
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE25         ; (1, 1bis)
PULSE25
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,1
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE26         ; (1, 1bis)
PULSE26
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,2
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE27         ; (1, 1bis)
PULSE27
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,3
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE28         ; (1, 1bis)
PULSE28
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,4
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE29         ; (1, 1bis)
PULSE29
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,5
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE30         ; (1, 1bis)
PULSE30
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,6
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE31         ; (1, 1bis)
PULSE31
                nop                     ; (2)
                nop                     ; (3)
                btfsc   NUTISA
                bsf     addru,7
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE32         ; (1, 1bis)
PULSE32
                nop                     ; (2)
                movf    addru,W
                andlw   0xF0            ; use the upper four bits ...
                swapf   WREG
                addwf   romoff,W
                movwf   FSR0L           ; as a pointer to the map table
                btfss   NUTPHI2         ; (8)
                bra     PULSE33         ; (1, 1bis)
PULSE33
                nop                     ; (2)
                movf    INDF0,W
                bnz     ours
                goto    notours         ; eat the next 23 pulses, saving the op code (notours must begin at instr (7))
ours            nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE34         ; (1, 1bis)
PULSE34
                nop                     ; (2)
                movwf   TBLPTRH
                movf    addru,W
                andlw   0x0f
                iorwf   TBLPTRH,F
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE35         ; (1, 1bis)
PULSE35
                movf    addrl,W
                movwf   TBLPTRL
                tblrd   *
                movff   TABLAT,opl8
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE36         ; (1, 1bis)
PULSE36
                rrcf    TBLPTRH
                rrcf    TBLPTRL
                rrcf    TBLPTRH
                rrcf    TBLPTRL
                movf    TBLPTRH,W
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE37         ; (1, 1bis)
PULSE37
                andlw   0x1f
                movwf   TBLPTRH
                tblrd   *
                movff   TABLAT,oph2
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE38         ; (1, 1bis)
PULSE38
                btfss   addrl,1
                bra     norot4          ; (must begin on instr. (5))
                rrcf    oph2
                rrcf    oph2
                rrcf    oph2
                rrcf    oph2
                btfss   NUTPHI2         ; (8)
                bra     PULSE39         ; (1, 1bis)
PULSE39
                nop                     ; (2)
                nop                     ; (3)
PULSE39b        nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE40         ; (1, 1bis)
PULSE40
                btfss   addrl,0
                bra     norot2
                rrcf    oph2
                rrcf    oph2
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE41         ; (1, 1bis)
PULSE41
                nop                     ; (2)
                nop                     ; (3)
PULSE41b        nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE42         ; (1, 1bis)
PULSE42
                nop                     ; (2)
                nop                     ; (3)
                movlw   0x03
                andwf   oph2,F          ; good time to mask this
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE43         ; (1, 1bis)
PULSE43
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE44         ; (1, 1bis)
PULSE44
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE45         ; (1, 1bis)
PULSE45
                bcf     NUTISA          ; prevent a glitch?
                movf    opl8,w
                swapf   WREG
                movwf   PORTB
                bcf     TRISB,4         ; bit 0 is out
                nop
                btfss   NUTPHI2         ; (8)
                bra     PULSE46         ; (1, 1bis)
PULSE46
                rrncf   WREG
                nop                     ; (3)
                nop                     ; (4)
                btfsc   NUTSYNC         ; are we an opcode fetch?
                bsf     oph2,2          ; indicate that.
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE47         ; (1, 1bis)
PULSE47
                movwf   PORTB           ; bit 1 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE48         ; (1, 1bis)
PULSE48
                movwf   PORTB           ; bit 2 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE49         ; (1, 1bis)
PULSE49
                movwf   PORTB           ; bit 3 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE50         ; (1, 1bis)
PULSE50
                movwf   PORTB           ; bit 4 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE51         ; (1, 1bis)
PULSE51
                movwf   PORTB           ; bit 5 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
;               nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE52         ; (1, 1bis)
PULSE52
                movwf   PORTB           ; bit 6 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE53         ; (1, 1bis)
PULSE53
                movwf   PORTB           ; bit 7 is out
                movf    oph2,w          ; (3)
                swapf   WREG            ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE54         ; (1, 1bis)
PULSE54
                movwf   PORTB           ; bit 8 is out
                rrncf   WREG            ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE55         ; (1, 1bis)
PULSE55
                movwf   PORTB           ; bit 9 is out
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop
                btfss   NUTPHI2         ; (8)
                bra     PULSE00         ; (1, 1bis)
PULSE00
                bra     pulse0          ; (2, 3)

norot4
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE39         ; (1, 1bis)
                bra     PULSE39b        ; (2, 3)

norot2
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE41         ; (1, 1bis)
                bra     PULSE41b        ; (2, 3)

; END of our ROM loop *********************************

notours
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE34x        ; (1, 1bis)
PULSE34x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE35x        ; (1, 1bis)
PULSE35x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE36x        ; (1, 1bis)
PULSE36x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE37x        ; (1, 1bis)
PULSE37x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE38x        ; (1, 1bis)
PULSE38x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE39x        ; (1, 1bis)
PULSE39x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE40x        ; (1, 1bis)
PULSE40x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE41x        ; (1, 1bis)
PULSE41x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE42x        ; (1, 1bis)
PULSE42x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE43x        ; (1, 1bis)
PULSE43x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE44x        ; (1, 1bis)
PULSE44x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE45x        ; (1, 1bis)
PULSE45x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE46x        ; (1, 1bis)
PULSE46x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE47x        ; (1, 1bis)
PULSE47x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE48x        ; (1, 1bis)
PULSE48x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE49x        ; (1, 1bis)
PULSE49x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE50x        ; (1, 1bis)
PULSE50x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE51x        ; (1, 1bis)
PULSE51x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
;               nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE52x        ; (1, 1bis)
PULSE52x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE53x        ; (1, 1bis)
PULSE53x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE54x        ; (1, 1bis)
PULSE54x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE55x        ; (1, 1bis)
PULSE55x
                nop                     ; (2)
                nop                     ; (3)
                nop                     ; (4)
                nop                     ; (5)
                nop                     ; (6)
                nop                     ; (7)
                btfss   NUTPHI2         ; (8)
                bra     PULSE00x        ; (1, 1bis)
PULSE00x
                bra     pulse0          ; (2, 3)

; END of Not Our ROM loop ********************************************************************
