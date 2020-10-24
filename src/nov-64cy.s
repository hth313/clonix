;;; -*- mode: gas; gas-opcode-column: 8; gas-argument-column: 16; gas-comment-column: 32; -*-
;;;
; ******************** NoV-64CY project (32K) Sep 23rd, 2010 **************
;;;
;;; Written by Diego Díaz, adapted to NutStudio by Håkan Thörngren
;;;
;;;
;;; Emulating HP-41CY (not turbo) with NOV-64.
;;; Working on Fullnuts, does not work on Halfnuts
;;; Seeking for bugs to allow Halfnut operation.
;;; Bugs fixed Sep. 24th, 2010

#include "p18f2620.h"

; -*- Configuration constants

        .section config, rodata
        .byte   0xff                    ; Will be mapped to address 300000
        .byte   0x06                    ; -*- Enables PLL oscillator mode
        .byte   0x18                    ; -*- Prevents Brown out Reset
        .byte   0x00                    ; -*- Disables Watch Dog Timer
        .byte   0xff
        .byte   0x81                    ; -*-
        .byte   0x80                    ; -*- Disables Low Voltage Programming
                                        ;     and avoids Stack Overflow reset
        .byte   0xff


; -*- End NoV-64 Config *************************************************

; We emulate bank-switched HP41 ROMs using a PIC 18F2620.

; The 18LF2620 has 64K of memory.  We allocate it thus:
; 0000 - 0fff (4K) available for code
; 1000 - 3fff (12K) packed high-order bits of twelve 4K ROMs
; 4000 - ffff (48K) low-order bits of twelve 4K ROMs

; Definitions of I/O lines **********************************************

#define NUTDATA PORTB,7
#define NUTPHI2 PORTB,6
#define NUTSYNC PORTB,5
#define NUTISA  PORTB,4
#define NUTPHI1 PORTB,2

#define NUTPWO  PORTB,0

#define OUTISA  TRISB,4
;#define        OUTISA  INTCON2,7

; End I/O definitions ***************************************************

; FeRAM interface definitions *******************************************

#define RAMDAT  PORTA,0
#define RAMCLK  PORTA,1
#define RAMPOW0 PORTA,2
#define RAMPOW1 PORTA,3
#define RAMPOW2 PORTA,4
#define RAMPOW3 PORTA,5
#define DATDIR  TRISA,0

; End FeRAM interface definitions ***************************************

; Define where to map each page/bank, and variables *********************

        .section variables, bss
rom0b1map .space  1
rom1b1map .space  1
rom2b1map .space  1
rom3b1map .space  1
rom4b1map .space  1
rom5b1map .space  1
rom6b1map .space  1
rom7b1map .space  1
rom8b1map .space  1
rom9b1map .space  1
romab1map .space  1
rombb1map .space  1
romcb1map .space  1
romdb1map .space  1
romeb1map .space  1
romfb1map .space  1
rom0b3map .space  1
rom1b3map .space  1
rom2b3map .space  1
rom3b3map .space  1
rom4b3map .space  1
rom5b3map .space  1
rom6b3map .space  1
rom7b3map .space  1
rom8b3map .space  1
rom9b3map .space  1
romab3map .space  1
rombb3map .space  1
romcb3map .space  1
romdb3map .space  1
romeb3map .space  1
romfb3map .space  1
rom0b2map .space  1
rom1b2map .space  1
rom2b2map .space  1
rom3b2map .space  1
rom4b2map .space  1
rom5b2map .space  1
rom6b2map .space  1
rom7b2map .space  1
rom8b2map .space  1
rom9b2map .space  1
romab2map .space  1
rombb2map .space  1
romcb2map .space  1
romdb2map .space  1
romeb2map .space  1
romfb2map .space  1
rom0b4map .space  1
rom1b4map .space  1
rom2b4map .space  1
rom3b4map .space  1
rom4b4map .space  1
rom5b4map .space  1
rom6b4map .space  1
rom7b4map .space  1
rom8b4map .space  1
rom9b4map .space  1
romab4map .space  1
rombb4map .space  1
romcb4map .space  1
romdb4map .space  1
romeb4map .space  1
romfb4map .space  1

addrl   .space  1             ; lower 8 bits of ISA address
addru   .space  1             ; upper 8 bits of ISA address
opl8    .space  1             ; low eight bits of fetched word
oph2    .space  1             ; high two bits of fetched word
adrlw   .space  1             ; DATA line Higer byte received address
adrhg   .space  1             ; (You can guess for sure)
dtl8    .space  1             ; DATA line higher 2 bits of data
dth2    .space  1             ; (Do we bet? ;-)
enromoff  .space  1             ; 0x00, 0x20, 0x10 or 0x30 indicating ENBANK1, 2, 3, or 4
adrsource .space  1             ; bit0 = 0 address from ISA, bit0 = 1 address from DATA
RAMmode .space  1             ; RAM scheme AA, BB, AB or BA
ramchip .space  1             ; Active RAM chip(s) power, bits 2, 3, 4 or 5 respectively.

ramchipH .space  1             ; Active RAM chip for pages #C to #F
ramchipL .space  1             ; Active RAM chip for pages #8 to #B

dummy   .space  1


; End of variables and mapping/address definitions *************************

; Macros definition ********************************************************

wthi    .macro  nutport,nutsignal ; loops until signal is hi
1$      btfss   \nutport,\nutsignal
        bra     1$
        .endm

wtlo    .macro  nutport,nutsignal ; loops until signal is lo
1$      btfsc   \nutport,\nutsignal
        bra     1$
        .endm

wtre    .macro  nutport,nutsignal ; waits for rising edge
        wtlo    \nutport,\nutsignal
        wthi    \nutport,\nutsignal
        .endm

wtfe    .macro  nutport,nutsignal ; waits for falling edge
        wthi    \nutport,\nutsignal
        wtlo    \nutport,\nutsignal
        .endm

; End of macros definition *********************************************

;************************* CODE BEGINNING ******************************

; Reset vector

        .section reset
rst
        clrf    INTCON
        bsf     WDTCON,0
        bra     begin0

; Interrupt 0 (high priority) vector

        .section interrupt
itrrh                               ; Detected PWO falling edge
        clrf    STKPTR
        bra     start           ; Go to SLEEP and waits for PWO rising edge

        .section code
begin0
        movlw   0x3C            ; All RAM chips active, removed for test1
        movwf   ramchip

begin
        movlw   0x0F
        movwf   ADCON1          ; Port A is digital I/O
        clrf    PORTA           ; Initialize ports
        clrf    PORTB
        setf    PORTC

        clrf    TRISA           ;Port A is output
        clrf    TRISB           ;Ports B & C are outputs
        clrf    TRISC

        clrf    TBLPTRU

; clear PIC memory for variables and memory mapping

        clrf    FSR0H           ; lfsr causes problems!
        clrf    FSR0L
clr0    clrf    POSTINC0
        btfss   FSR0L,6         ; reached 0x40 yet?
        bra     clr0

        movlW   0x40            ; Initial RAMBOX 64a enabled
        movwf   rom8b1map

        clrf    RAMmode

        bsf     rom9b1map,0     ; Enables RAM at page 9
        bsf     romab1map,0     ; Enables RAM at page A
        bsf     rombb1map,0     ; Enables RAM at page B
        bsf     romcb1map,0     ; Enables RAM at page C
        bsf     romdb1map,0     ; Enables RAM at page D
        bsf     romeb1map,0     ; Enables RAM at page E
        bsf     romfb1map,0     ; Enables RAM at page F
remap


        clrf    adrsource       ; clears DATA/ISA address flag
;______________________________________________________________________________
;This code between the cont-lines is for the first [ON] after module plug-in or
;NUT wake up, when the relocation must be done.

        bsf     INTCON2,6       ; Activates INT0 on rising edge

        clrf    INTCON          ; Resets INT0 bit
        bsf     INTCON,4        ; Enables INTO
                                ; Globally disables interrupts.
        clrf    PORTA           ; Solves bug reported by Miki Mihajlovic. Thanks!! ;-)
        setf    TRISA           ; all of A is input (to prevent BAT from draining 1.2mA thru 10k RAM data&clk pull-up resistors)
        setf    TRISB

        sleep

        clrwdt
        bcf     WDTCON,0
        btfss   NUTPWO          ; Stop-Watch bug reported by Geir Isene (The nastiest bug up to date... :-)

frstslp
        sleep                   ; Waits until rising edge on PWO (PORTB,0)
        bsf     WDTCON,0

        clrf    TRISA           ; all of A is output (bug reported by Geir Isene... Thanks so much)

        bcf     INTCON,1        ; Resets INT0 bit after PWO rises. (First Power ON)
        bcf     INTCON2,6       ; Activates INT0 on falling edge
        bsf     INTCON,GIE      ; Globally enables interrupts.

        bra     syncseek

; End of first [ON]
;_______________________________________________________________________________

start
        bsf     INTCON2,6       ; Activates INT0 on rising edge

        clrf    INTCON          ; Resets INT0 bit
        bsf     INTCON,4        ; Enables INTO
                                ; Globally disables interrupts.
        movlw   0x03            ; 3 iterations of 7 cycles (83nS/cycle) delay loop (3*7*83.33 E-9=15 E-6) 1.75uS total delay

synlwt
        call    s4nop
        decfsz  WREG
        bra     synlwt          ; Delay required for the Halfnut to calm down nut bus signals. (1.75uS)

        btfss   NUTSYNC         ; If SYNC is Low then NUT is OFF, so relocation must be performed again, otherwise it's a normal SLEEP.
        bra     remap           ; Go to perform relocation again
        clrf    PORTA           ; RAM power off
        setf    TRISA           ; all of A is input (to prevent BAT from draining 1.2mA thru 10k RAM data&clk pull-up resistors)

;===============================================================================
;Fixin auto-OFF bug by allowing interrups on PORTB [7:4] change... NUTSYNC is in PORTB,5
;if NUTSYNC goes LOW while calc is on light sleep mode, is means that 10min timer has expired and Auto-OFF has occurred
;PIC should wake up and go to "begin" as if the module where just plugged in.

        movf    PORTB           ; reads PORTB to avoid mismatch conditions that may cause unwanted interrupts
        bcf     INTCON,0        ; clears RBIF (flag indicating that any PORTB [7:4] has chaged state)

        movlw   0x7f            ; filters only bit7 (DATA).
        movwf   TRISB

        bsf     INTCON,3        ; Enables PORTB interrupt on change

        clrwdt
        bcf     WDTCON,0

scndslp
        sleep
        bsf     WDTCON,0        ; Waits until rising edge on PWO (PORTB,0)
                                ; or PORTB change
        setf    TRISB           ; All PORTB is input
        btfsc   NUTPWO          ; If PWO is HIGH then no Auto-OFF
        bra     noauoff         ; go to normal sequence

        btfsc   NUTSYNC         ; Check if SYNC has gone LOW
        bra     start           ; if PWO is LOW and SYNC is HIGH then some noise in the bus has waked-up the PIC
                                ; ignore it and go to sleep again resetting interrupt pattern
        clrf    INTCON
        bra     begin           ; if POW is LOW and SYNC is LOW then Auto-OFF has occurred, go to begin to reinitialize PIC.


noauoff                         ; it'a normal keystroke sequence

        clrf    TRISA           ; all of A is output (bug reported by Geir Isene... Thanks so much)

        bcf     INTCON,1        ; Resets INT0 bit after PWO rises.
        bcf     INTCON2,6       ; Activates INT0 on falling edge
        bcf     INTCON,3        ; Disables interrupt on PORTB change
        bcf     INTCON,0        ; Resets flag of Interrupt on PORTB change
        bsf     INTCON,GIE      ; Globally enables interrupts.
;-----------------------------------------------------------------------------
syncseek                        ; The real work begins here

        wtfe    NUTSYNC         ; wait for SYNC to go low

pulse0                          ; we are now in pulse 0
        call    swtre1          ; 0 middle pulse 0
;---------------------------------------------------------------------------- 0

        call    swtre1          ; 1 after routine finishes, we are at the middle of pulse 1
;---------------------------------------------------------------------------- 12

        btfsc   NUTSYNC         ; test SYNC to avoid false sync. due to old 41's pulses
        bra     syncseek        ; restart syncing due to false SYNC detection.
        clrf    dtl8            ; Clears data low8 for WRITE S&X
        clrf    dth2            ; Clears data high2 for WRITE S&X
        clrf    adrsource       ; Clears RAM address selection pointer
        clrf    adrhg           ; Clears higher address ROM/RAM read pointer
        clrf    adrlw           ; Clears lower address ROM/RAM read pointer
        clrf    addru           ; Clears upper address RAM write pointer
        clrf    addrl           ; Clears lower address RAM write pointer

        clrwdt                  ; Clears Watch Dog Timer
        movff   ramchip,PORTA   ; Powers ON RAM chip(s)

        call    swtre1          ; 2 (Data valid strobe on phase 2)
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,0          ; DATA line data low, bit 0

        call    swtre1          ; 3
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,1          ; DATA line data low, bit 1

        call    swtre1          ; 4
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,2          ; DATA line data low, bit 2

        call    swtre1          ; 5
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,3          ; DATA line data low, bit 3

        call    swtre1          ; 6
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,4          ; DATA line data low, bit 4

        call    swtre1          ; 7
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,5          ; DATA line data low, bit 5

        call    swtre1          ; 8
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dtl8,6          ; DATA line data low, bit 6

        wtre    NUTPHI1         ; 9
;---------------------------------------------------------------------------- 15
        btfsc   NUTDATA
        bsf     dtl8,7          ; DATA line data low, bit 7

                                ; Reserved for Bankswitching
        movf    oph2,W          ; Test if the last opcode fetched was ENBANK1, 2, 3 or 4
        andlw   0x07            ; bit 2 was set if SYNC was hi, indicating an opcode fetch
        sublw   0x05
        bnz     notenbank       ;-*- if it's not zero then no ENBANK opcode.
        movf    opl8,W
        andlw   0x3F
        bnz     notenbank       ;-*- if not B'xx000000 not enbank
        movf    opl8,W
        andlw   0xC0            ;-*- filters bits 7 & 6 from the opcode
        rrncf   WREG
        rrncf   WREG            ;-*- puts 7 & 6 in 5 & 4 places
        swapf   WREG            ;-*- and then into 1 & 0. End of ENBANK process
        incf    enromoff
        bra     endenbank
notenbank
        clrf    enromoff
endenbank

        wtre    NUTPHI1         ; 10
;---------------------------------------------------------------------------- 26
        btfsc   NUTDATA
        bsf     dth2,0          ; DATA line data high, bit 0

        movff   enromoff,dummy  ; no ENBANKx received
        bz      notenbank2      ; go away
        btfsc   enromoff,1      ; 1st ENBANK?
        bra     secenbank       ; no, go to second

; First ENBANK code received, it can be 100 or 180

        iorwf   WREG            ; Sets flags
        bz      bankA           ; 100
        decf    WREG
        bz      notenbank2      ; 140 not allowed as first EB
bank01                          ; 1st = 180
        clrf    RAMmode
        bsf     RAMmode,1       ; Sets RAMmode=0000 0010 (Bx)
        bra     notenbank2

bankA                           ; 1st = 100
        bcf     rom8b1map,4     ; sets RAMBOX 64a
        clrf    RAMmode         ; Sets RAMmode=0000 0000 (AA)
        bra     notenbank2

; Second ENBANK code received, it can be 140 or 180

secenbank
        iorwf   WREG            ; sets flags
        bz      notenbank2      ; 100 not allowed as 2nd EB
        decf    WREG
        bz      bank10          ; 140

        bsf     RAMmode,1       ; 180 Sets RAMmode=0000 0010 (AB)
        bra     notenbank2
bank10
        bsf     rom8b1map,4     ; Sets RAMBOX 64b
        bsf     RAMmode,0       ; Sets RAMmode 1 (BA) or 3 (BB)

notenbank2

        wtre    NUTPHI1         ; 11
;---------------------------------------------------------------------------- 2
        btfsc   NUTDATA
        bsf     dth2,1          ; DATA line data high, bit 1

        wtre    NUTPHI1         ; 12
;---------------------------------------------------------------------------- 8

                                ; This Phase is used for WRITE S&X (H'040) detection
                                ; Depending on whether a Write cycle is detected or not
        movf    oph2,W          ; we set adrsource,0 to 0 or 1 (ISA or DATA).
        andlw   0x07            ; Bit 2 set if it was a Fetch cycle!
        sublw   0x04            ; checks that U2 bits are both 0's
        bnz     adrisa          ; if they're not, it isn't a WRITE s&x opcode
        movf    opl8,W          ; if U2 are 0's check L8
        sublw   0x40            ; if it's 0x40 we've got a WRITE s&x code
        bnz     adrisa          ; If it isn't get address from ISA
        bsf     adrsource,0     ; WRITE CYCLE, Address from DATA
adrisa                          ; No Write s&x cycle so address must be taken from ISA

        wtre    NUTPHI1         ; 13
;---------------------------------------------------------------------------- 0

#include        "addrs08y.s"

;------------------------------------------------------------------------------

memrd

;******* Switches OFF the unwanted RAM CHIP****
        movf    ramchipH,W
        btfss   addru,6
        movf    ramchipL,W
        movwf   PORTA
;**********************************************

        bsf     DATDIR          ; Set RAMDAT as Input for ACK
        call    ferclk
        bcf     DATDIR          ; Set RAMDAT as output again.

        wthi    NUTPHI1         ; 31
;---------------------------------------------------------------------------- 22
        btfsc   NUTISA
        bsf     addru,7         ; ISA line address high, bit 7

        movf    addru,W
        andlw   0xF0            ; use the upper four bits ...
        swapf   WREG
        movwf   FSR0L           ; as a pointer to the map table
        btfsc   INDF0,0         ; If map is B'XXXXXXX1 then is RAM
        bra     ouramrd         ; go reading RAM
        clrf    PORTA           ; if not, switch OFF RAM chips.
        bra     checkrom        ; We've verified that it's not our RAM
                                ; but it can still be our ROM... go check it!

ouramrd                         ; Read sequence

        nop
        bsf     RAMDAT          ; Sends START sequence again
        nop
        nop
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop
        nop                     ;Added to search Geir's RAM trouble
        nop                     ;**********************************
        nop
        bcf     RAMDAT          ;
        nop
        nop
        bcf     RAMCLK


;So it's our RAM after all, good let's trate those bits... ;-)
;Phi# |    32   |    33   |    34   |    35   |    36   |    37   |    38   |    39   |    40   |    41   |    42   |    43   |    44   |    45   |

;CLK __/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__/¯\__

;DAT _/¯¯¯\_____/¯¯¯\____________________/¯¯¯\_____XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX_____XXXXXXXXXX______________________________/¯¯¯\__/¯\_
;       ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^    ^     ^
;       1    0    1    0    0    0    0    1   ACK  D0   D1   D2   D3   D4   D5   D6   D7   ACK  D8   D9   D10  D11  D12  D13  D14  D15 NO-ACK STOP
;      |----SLAVE ID----|  |-DEVICE AD-| READ

        wtre    NUTPHI1         ; 32
;-------------------------------------------------------------------------------
        bsf     RAMDAT          ; SDT to "1" (Start slave address "B'10100001")
        call    ferclk
        clrf    opl8
;------------------- 12
        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 2nd bit)
        call    ferclk
        bcf     oph2,0
;------------------- 24
        bsf     RAMDAT          ; SDT to "1" (Slave address "B'10100001" 3rd bit)
        call    ferclk
        bcf     oph2,1
;------------------- 36
        bcf     RAMDAT          ; SDT to "0" (Slave address "B'10100001" 4th bit)
        call    ferclk
        nop
;------------------- 48
        nop                     ; SDT to "0" (Slave address "B'10100001" 5th bit)
        call    ferclk
        nop
;------------------- 60
        nop                     ; SDT to "0" (Slave address "B'10100001" 6th bit)
        call    ferclk
        nop
;------------------- 72
        nop                     ; SDT to "0" (Slave address "B'10100001" 7th bit)
        call    ferclk
        nop
;------------------- 84
        bsf     RAMDAT          ; SDT to "1" (Slave address "B'10100001" 8th bit)
        call    ferclk
        bcf     RAMDAT
;------------------- 96
        bsf     DATDIR          ; Set RAMDAT as Input for ACK and Data
        call    ferclk
        call    s4nop
;------------------- 111
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,0          ; 3, b0L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 123
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,1          ; 3, b1L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 135
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,2          ; 3, b2L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 147
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,3          ; 3, b3L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
;------------------- 153

        wtre    NUTPHI1         ; 37 (re-syncronize after 5 Phi pulses)
;-------------------------------------------------------------------------------
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,4          ; 3, b4L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 12
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,5          ; 3, b5L
        nop                     ; 5
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 24
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,6          ; 3, b6L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 36
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     opl8,7          ; 3, b7L
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        nop
        nop
;------------------- 44
        bcf     RAMDAT          ; Acknowledge: DAT = "0"
        bcf     DATDIR          ; Set RAMDAT as Output for ACK
        call    ferclk
        bsf     DATDIR          ; Set RAMDAT as Input again.
        call    s4nop
;------------------- 61
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     oph2,0          ; 3, b0H
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s6nop
;------------------- 73
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        nop                     ; 1
        btfsc   RAMDAT          ; 2
        bsf     oph2,1          ; 3, b1H
        nop                     ; 4
        bcf     RAMCLK          ; and 5, go down...
        call    s4nop
;------------------- 83
        call    ferclk          ; b2H
        nop
        nop
;------------------- 95
        call    ferclk          ; b3H
        nop
        nop
;------------------- 107
        call    ferclk          ; b4H
        nop
        nop
;------------------- 119
        call    ferclk          ; b5H
        nop
        nop
;------------------- 131
        call    ferclk          ; b6H
        nop
        nop
;------------------- 143
        call    ferclk          ; b7H
;------------------- 153

        wtre    NUTPHI1         ;42
;------------------------------------------------------------------------------
        bsf     RAMDAT          ;Not ACK sequence
        bcf     DATDIR
        call    ferclk

        movff   ramchip,PORTA   ; Powers both chips

        wtre    NUTPHI1         ; 43
;-------------------------------------------------------------------------------

        wtre    NUTPHI1         ; 44
;-------------------------------------------------------------------------------

        wtre    NUTPHI2         ; 45
;-------------------------------------------------------------------------------
        bra     outfromisa

;********End of RAM read sequence**********************************************

checkrom
        wtre    NUTPHI1         ; 32
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 33
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 34
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 35
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 36
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 37
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 38
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 39
;---------------------------------------------------------------------------- 0
endwrite2
        call    swtre2          ; 40
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 41
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 42
;---------------------------------------------------------------------------- 12

;; The address of the opcode to fetch is in
;; We compute where in the table to find oph2 and opl8
;; get the upper four bits of the address, and see where
;; it maps in our tables.

        movf    addru,W
        andlw   0xF0            ; use the upper four bits ...
        swapf   WREG
        movwf   FSR0L           ; as a pointer to the map table
        movf    INDF0,W
        btfsc   WREG,0
        bsf     adrsource,1     ; RAM has been WRITTEN and intended to be READ!!
                                ; Send NOP!!!!
        andlw   0xF0            ; only the upper nibble is useful for ROM.
        bnz     ours
        movlw   0x08
        goto    notours         ; eat the next 14 pulses, saving the op code

ours
        call    swtre2          ; 43
;---------------------------------------------------------------------------- 17

        movwf   TBLPTRH
        movf    addru,W
        andlw   0x0f
        iorwf   TBLPTRH,F
        movf    addrl,W
        movwf   TBLPTRL
        tblrd   *
        movff   TABLAT,opl8

        rrcf    TBLPTRH
        rrcf    TBLPTRL
        rrcf    TBLPTRH
        rrcf    TBLPTRL
        bcf     TBLPTRH,7
        bcf     TBLPTRH,6
        tblrd   *
        movff   TABLAT,oph2

        call    swtre2          ; 44
;---------------------------------------------------------------------------- 10

        btfss   addrl,1
        bra     norot4
        rrcf    oph2
        rrcf    oph2
        rrcf    oph2
        rrcf    oph2
norot4
        btfss   addrl,0
        bra     norot2
        rrcf    oph2
        rrcf    oph2
norot2
        wtre    NUTPHI2         ; 45
;----------------------------------------------------------------------------

outfromisa
        movlw   0x03
        andwf   oph2,F          ; good time to mask this
        movlw   0x42            ; Points to opl8
        movwf   FSR0L

;       wtlo    NUTPHI2         ; 45; start Word output (ISA)

        call    OUTL8H2         ; 46

        call    OUTL8H2         ; 47

        call    OUTL8H2         ; 48

        call    OUTL8H2         ; 49

        call    OUTL8H2         ; 50

        call    OUTL8H2         ; 51

        call    OUTL8H2         ; 52

        call    OUTL8H2         ; 53

        incf    FSR0L           ; Points to oph2

        call    OUTL8H2         ; 54

        btfsc   NUTSYNC         ; are we an opcode fetch?
        bsf     oph2,1          ; indicate that (this does not affect ISA output)

        call    OUTL8H2         ; 55

        rlncf   oph2            ; Puts oph2 bits back in place.
        rlncf   oph2

        wtre    NUTPHI2         ; 0

;       bcf     NUTISA          ; prevent a glitch?
        setf    TRISB

        goto    pulse0

notours
        call    swtre2          ; 43

        btfsc   adrsource,1
        bra     sendnop
        call    swtre2          ; 44
        call    swtre1          ; 44
        call    swtre1          ; 45

keepeating
        call    swtre1          ; 46 - 53
        decfsz  WREG
        bra     keepeating

        call    swtre1          ; 54
        call    swtre1          ; 55
        goto    pulse0

sendnop
        call    swtre2          ; 44
        clrf    opl8
        clrf    oph2
        bra     norot2

;------------------------------ Subroutines area
swtre1
        btfsc   NUTPHI1
        bra     swtre1
lo1     btfss   NUTPHI1
        bra     lo1
        return

swtre2
        btfsc   NUTPHI2
        bra     swtre2
lo2     btfss   NUTPHI2
        bra     lo2
        return

ferclk
        bsf     RAMCLK          ; SCL to "1" (Must be kept for 5 cycles)
        call    s4nop           ; 1-4
        bcf     RAMCLK          ; and 5, go down...
        return

s7nop
        nop
s6nop
        nop
s5nop
        nop
s4nop
        return

OUTL8H2
        wtre    NUTPHI2         ; Sincronizes with Phi2 falling edge

;       bcf     NUTISA          ; Bus pre-charge LOW
;       bcf     OUTISA          ; To avoid noise

        bsf     OUTISA          ; Make sure ISA is input again
        bsf     NUTISA          ; ISA line = High

;       nop                     ; Required?

        btfsc   INDF0,0         ; Check bit to send if 0 then do nothing
        bcf     OUTISA          ; If bit =  1 then ISA is output
;       wtre    NUTPHI1         ; Sincronizes with Phi1 rising edge (HP41 read)
        rrncf   INDF0           ; Shifts to the next bit
;       bsf     OUTISA          ; Make sure ISA is input again.
        return
