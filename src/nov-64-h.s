;;; -*- mode: gas; gas-opcode-column: 8; gas-argument-column: 16; gas-comment-column: 32; -*-
;;;
;;; ******************** NoV-64 project (32K) Apr 16th, 2010 **************
;;;
;;; Written by Diego Díaz, adapted to NutStudio by Håkan Thörngren
;;;
;;; ver 08q: Apr 16th 2010. Changes to allow 32K all in a row.
;;; Ver 08r: Apr 18th 2010. Includes RAM2Flash functionality
;;; and chip oriented Page Write Protection.
;;; Modified to allow RAM page shadowing using the technique from CY (28-02-11)
;;; original and functional code saved as NoV-64-H(safe)
;;; Reducing power drain. STBY & SLEEP. (05-09-12)

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

;#define        OUTISA  PORTB,4
#define OUTISA  TRISB,4

; End I/O definitions ***************************************************

#include "FeRAM.h"

; Define where to map each page/bank, and variables *********************

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
rom0b1map .space 1
rom1b1map .space 1
rom2b1map .space 1
rom3b1map .space 1
rom4b1map .space 1
rom5b1map .space 1
rom6b1map .space 1
rom7b1map .space 1
rom8b1map .space 1
rom9b1map .space 1
romab1map .space 1
rombb1map .space 1
romcb1map .space 1
romdb1map .space 1
romeb1map .space 1
romfb1map .space 1
rom0b3map .space 1
rom1b3map .space 1
rom2b3map .space 1
rom3b3map .space 1
rom4b3map .space 1
rom5b3map .space 1
rom6b3map .space 1
rom7b3map .space 1
rom8b3map .space 1
rom9b3map .space 1
romab3map .space 1
rombb3map .space 1
romcb3map .space 1
romdb3map .space 1
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
locpend   .space  1             ; ROM re-location pending Bit 0=1, re-location done Bit 0=0
rammap00  .space  1             ; Low RAM active chip # (0, 1, 2 or 3)
rammap01  .space  1             ; High RAM active chip # (0, 1 or 2)
ramchip   .space  1             ; Active RAM chip(s) power, according to rammap00: RAM0=4, RAM1=8, RAM2=16 & RAM3=32
                                    ; bits 2, 3, 4 or 5 respectively.
rommap00 .space  1
ramchipH .space  1             ; Active RAM chip for pages #C to #F
ramchipL .space  1             ; Active RAM chip for pages #8 to #B
ctrlwrd  .space  1             ; B'00xx00xx, active RAM map.
ctrlRR   .space  1             ; Temporary control word for RAM2ROM
flashdisable .space  1             ; bit0 = 1 if #E or #F are used in MAPPING2
flashstat    .space  1             ; byte to show Flash status to user at H'4101

;-------------------------These are for RAM2 ROM Routine
DAL     .space  1             ; DumpAddressLow RAM
DAH     .space  1             ; DumpAddressHigh RAM
DDL8    .space  1             ; DumpDataLow8
DDH2    .space  1             ; DumpDataHigh2
DASL    .space  1             ; Holds Low address for L8 Dump
DASH    .space  1             ; Holds High address for L8 Dump
COUNTER .space  1             ; 32Words
COUNTER_HI .space  1
LOOPCOUNT .space  1             ; 128 times (32 x 128 = 4096 words)
DASL2   .space  1             ; Holds Low address for H2 Dump
DASH2   .space  1             ; Holds High address for H2 Dump
ram00WP .space  1
ram01WP .space  1
ram02WP .space  1
ram03WP .space  1
ram10WP .space  1
ram11WP .space  1
ram12WP .space  1
ram13WP .space  1
ram20WP .space  1
ram21WP .space  1
ram22WP .space  1
ram23WP .space  1
ram30WP .space  1
ram31WP .space  1
ram32WP .space  1
ram33WP .space  1
PACKH2  .space  1
HEPpage .space  1

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

        .public flashdisable, flashstat, LOOPCOUNT
        .public romfb1map, romfb2map, romfb3map, romfb4map
        .public ctrlRR, DAH, DAL, DASH, DASH2, DASL, DASL2
        .public rammap01, ramchip, ramchipH, ramchipL
        .public ctrlRR, ctrlwrd, DDH2, DDL8, s4nop, s6nop, ferclk
        .public COUNTER, COUNTER_HI, PACKH2

        .extern RAM2ROM4, ROMERASE

;************************* CODE BEGINNING ******************************

; Reset vector

        .section reset
rst
        clrf    INTCON
        bsf     WDTCON,0
        bra     begin0

; Interrupt 0 (high priority) vector

        .section interrupt

itrrh                                   ; Detected PWO falling edge
        clrf    STKPTR
        bra     start           ; Go to SLEEP and waits for PWO rising edge

        .section code

begin0
        clrf    rammap00
        clrf    rommap00        ;
        bsf     rommap00,0      ; Activates ROM block 1
        clrf    ramchip
        bsf     ramchip,2       ; Activates RAM chip 0

        clrf    rammap01
        clrf    ramchipL
        bsf     ramchipL,2      ;
        clrf    ramchipH
        clrf    ctrlwrd         ;H & L to RAM chip #0 at plug in,
        clrf    flashdisable

begin
        movlw   0x0F
        movwf   ADCON1          ; Port A is digital I/O

        clrf    TRISA           ;Port A is output
        setf    TRISB           ;Ports B is inputs
        bcf     TRISB,1         ;except unused pins
        bcf     TRISB,3
        clrf    TRISC           ;Port C is unused and set to output

        clrf    PORTA           ; Initialize ports
        setf    PORTB
;       bcf     PORTB,1
;       bcf     PORTB,3
        setf    PORTC

        clrf    TBLPTRU

;------------------------------------------------------------------
; This is to detect if Flash at #F is available for RAM2ROM

        movlw   0xF0
        movwf   TBLPTRH
        clrf    TBLPTRL
        tblrd   *
        btfss   TABLAT,7
        bsf     flashdisable,0  ; Flash is used, disable RAM2ROM

;------------------------------------------------------------------

; clear PIC memory for variables and memory mapping

        clrf    FSR0H           ; lfsr causes problems!
        clrf    FSR0L
clr0    clrf    POSTINC0
        btfss   FSR0L,6         ; reached 0x40 yet?
        bra     clr0

        bsf     FSR0L,5         ; Sets pointer to H'060 (WR RAM array)
clr2    clrf    POSTINC0        ; Clears WP RAM array at plug in.
        btfss   FSR0L,4         ; 16 positions
        bra     clr2

remap2

        btfss   rommap00,0      ; Checks if ROM block 1 is active
        bra     norom1          ; if it's not go check ROM block 2

;#include        "MAPPING1.asm"  ; Loads ROM block 1 mapping

        .extern Mapping1, Mapping2

        call    Mapping1

        bra     endmap          ;

norom1

        btfss   rommap00,1      ; Checks if ROM block 2 is active
        bra     endmap

; #include        "MAPPING2.asm"  ; Loads ROM block 2 mapping
        call    Mapping2

;------------------------------------------------------------------
; This is to detect if Flash at #F has been used for RAM2ROM
; if it is mapping #F will be set.

        btfss   flashdisable,0  ; If #F is not filled
        bra     endcheckflash   ; then nothing to map
        movf    romfb1map,W     ; If its filled by user
        bnz     endmap          ; again nothing to map
        movlw   0xF0            ; If it's filled by RAM2ROM
        movwf   romfb1map       ; map accordingly.
        movwf   romfb2map
        movwf   romfb3map
        movwf   romfb4map
        bra     endmap
endcheckflash
        clrf    romfb1map
        clrf    romfb2map
        clrf    romfb3map
        clrf    romfb4map
;------------------------------------------------------------------

endmap

        bsf     rom9b1map,0     ; Enables RAM at page 9
        bsf     romab1map,0     ; Enables RAM at page A
        bsf     rombb1map,0     ; Enables RAM at page B

        movlw   0x40            ; Maps 1st HEPAX ROM page
        movwf   rom8b1map       ; to page 8 bank 1

        movlw   0x50            ; Maps 2nd HEPAX ROM page
        movwf   rom8b2map       ; to page 8 bank 2

        movlw   0x60            ; Maps 3rd HEPAX ROM page
        movwf   rom8b3map       ; to page 8 bank 3

        movlw   0x70            ; Maps 4th HEPAX ROM page
        movwf   rom8b4map       ; to page 8 bank 4

        clrf    enromoff        ; ROM map offset for BankSwitching
        clrf    adrsource       ; clears DATA/ISA address flag
        clrf    flashstat
;______________________________________________________________________________
;This code between the cont-lines is for the first [ON] after module plug-in or NUT wake up, when the relocation must be done.

                                ; ROM not yet re-located, sets the corresponding flag
        clrf    locpend
        clrf    HEPpage
        bsf     INTCON2,6       ; Activates INT0 on rising edge

        clrf    INTCON          ; Resets INT0 bit
        bsf     INTCON,4        ; Enables INTO
                                ; Globally disables interrupts.
        clrf    PORTA           ; Solves bug reported by Miki Mihajlovic. Thanks!! ;-)
        setf    TRISA           ; all of A is input (to prevent BAT from draining 1.2mA thru 10k RAM data&clk pull-up resistors)
        setf    TRISB
        bcf     TRISB,1
        bcf     TRISB,3

        sleep                   ; WDT is running now, Waits TO and then go to "real" sleep

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

        clrf    enromoff        ; * Important!! Prevents HEPAX bank-switch scheme to stuck on page 3 added in ver 02.

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
        bcf     TRISB,3
        bcf     TRISB,1

        bsf     INTCON,3        ; Enables PORTB interrupt on change

        clrwdt
        bcf     WDTCON,0

        btfsc   flashdisable,0  ; If bit0 = 1 Flash dump is disabled
        bra     scndslp         ; Then go SLEEP
        btfsc   flashdisable,1  ; If bit1 = 1 Flash dump is in progress.
        call    RAM2ROM4        ; Proceed with Flash dump.
        btfsc   flashdisable,2  ; If bit2 = 1 Flash ERASE is in progress.
        call    ROMERASE        ; Proceed with Flash ERASE.
        btfss   locpend,1       ; It has not been a normal start-up
;       bsf     locpend,2       ; ENTER-ON or <- ON (Reset mode), disable RAM read
        call    RST_mode
scndslp
        sleep
        bsf     WDTCON,0        ; Waits until rising edge on PWO (PORTB,0)
                                ; or PORTB change
        setf    TRISB           ; All PORTB is input
        bcf     TRISB,3
        bcf     TRISB,1
        btfsc   NUTPWO          ; If PWO is HIGH then no Auto-OFF
        bra     noauoff         ; go to normal sequence

        btfsc   NUTSYNC         ; Check if SYNC has gone LOW
        bra     start           ; if PWO is LOW and SYNC is HIGH then some noise in the bus has waked-up the PIC
                                ; ignore it and go to sleep again resetting interrupt pattern
        clrf    INTCON
        bra     begin           ; if POW is LOW and SYNC is LOW then Auto-OFF has occurred, go to begin to reinitialize PIC.

remap
        clrf    FSR0L
clr1    btfss   INDF0,0
        clrf    INDF0

        incf    FSR0L
        btfss   FSR0L,6         ; reached 0x40 yet?
        bra     clr1
        bra     remap2


noauoff                         ; it'a normal keystroke sequence

        clrf    TRISA           ; all of A is output (bug reported by Geir Isene... Thanks so much)

        bcf     INTCON,1        ; Resets INT0 bit after PWO rises.
        bcf     INTCON2,6       ; Activates INT0 on falling edge
        bcf     INTCON,3        ; Disables interrupt on PORTB change
        bcf     INTCON,0        ; Resets flag of Interrupt on PORTB change
        bsf     INTCON,GIE      ; Globally enables interrupts.

syncseek
        btfss   flashdisable,0
        bra     endfld
        movlw   0xFD            ; Flash Disable warning.
        movwf   flashstat

endfld
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
        clrf    enromoff
        movf    opl8,W
        andlw   0xC0            ;-*- filters bits 7 & 6 from the opcode
        rrncf   WREG
        rrncf   WREG            ;-*- puts 7 & 6 in 5 & 4 places
        iorwf   enromoff,f      ;-*- inserts bits 5 & 4 into enromoff. End of ENBANK process

notenbank

        wtre    NUTPHI1         ; 10
;---------------------------------------------------------------------------- 26
        btfsc   NUTDATA
        bsf     dth2,0          ; DATA line data high, bit 0

                                ; Reserved for RAMTOG (H'1F0)
        movf    oph2,W          ; Test if the last opcode fetched was RAMTOG
        andlw   0x07            ; bit 2 was set if SYNC was hi, indicating an opcode fetch
        sublw   0x05
        bnz     noramtog        ; if it's not zero then no RAMTOG opcode.
        movf    opl8,W
        sublw   0xF0
        bra     noramtog        ; if not H'F0 then not RAMTOG
        movf    dtl8,W          ; if it is get the page number
        andlw   0x0F            ; from DATA lower nibble
        movwf   FSR0L           ; points to map table
        btfss   INDF0,0         ; is it RAM??
        bra     noramtog        ; no RAM get out of here...
        btg     INDF0,1         ; It is RAMTOG so toggle WP flag of addressed page
        movf    rammap00,W      ; RAMblock 0?
        btfsc   dtl8,2
        movf    rammap01,W      ; or RAMblock 1?
        rlncf   WREG            ; shift to bits 3 & 2 of WREG (WP array pointer)
        rlncf   WREG
        bcf     dtl8,2          ; clears bits 3 & 2,
        bcf     dtl8,3          ; just the page # in the chip is left.
        addwf   dtl8,W          ; then added to WREG...
        addlw   0x60            ; and the array offset...
        movwf   FSR0L           ; place WREG as pointer
        btg     INDF0,1         ; ... and togle WP array flag.

noramtog

        wthi    NUTPHI1         ; 11
;---------------------------------------------------------------------------- 14
        btfsc   NUTDATA
        bsf     dth2,1          ; DATA line data high, bit 1

                                ; This Phase is used for WRITE S&X (H'040) and Move ROM (H'030) detection
                                ; Depending on whether a Write cycle is detected or not
        movf    oph2,W          ; we set adrsource,0 to 0 or 1 (ISA or DATA).
        andlw   0x07            ; Bit 2 set if it was a Fetch cycle!
        sublw   0x04            ; checks that U2 bits are both 0's
        bnz     adrisa          ; if they're not, it isn't a WRITE s&x opcode
        movf    opl8,W          ; if U2 are 0's check L8
        sublw   0x40            ; if it's 0x40 we've got a WRITE s&x code
        bnz     adris0          ; If it isn't get address from ISA
        bsf     adrsource,0     ; WRITE CYCLE, Address from DATA
        bra     adrisa
adris0
        movf    opl8,W          ; Checks if it's H'030
        sublw   0x30
        bnz     adrisa          ; If it isn't go ahead...
        bsf     locpend,0       ; if it's Mov ROM, set "Relocation OP" flag

adrisa                          ; No Write s&x cycle so address must be taken from ISA

        wtre    NUTPHI1         ; 12
;---------------------------------------------------------------------------- 22
        btfss   locpend,0       ; Relocation process 1st part (ROM banks 1, 2, 3 & 4)
        bra     noreloc
        movf    dtl8,W          ; Use the Lower 4 bits
        andlw   0x0F
        movwf   HEPpage
        movwf   FSR0L           ; as a pointer to the map table
        movlw   0x40            ;
        movwf   INDF0           ;

        bsf     FSR0L,4
        movlw   0x60
        movwf   INDF0

        bsf     FSR0L,5
        movlw   0x70
        movwf   INDF0

        bcf     FSR0L,4
        movlw   0x50
        movwf   INDF0

        movf    rom9b1map,w     ; Relocation process 2nd part (RAM recovery)
        movwf   rom8b1map
        clrf    rom8b2map
        clrf    rom8b3map
        clrf    rom8b4map
        rlncf   locpend         ; Set bit 1: relocation performed

noreloc

        wtre    NUTPHI1         ; 13
;---------------------------------------------------------------------------- 0

#include        "addrs08r.s"

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
;       nop
;       nop

        btfsc   locpend,2       ; avoids RAM reading if HP-41 is reset
        clrf    opl8            ; preventing poling-point loops on power-up.
;------------------- 107
        call    ferclk          ; b4H
;       nop
;       nop

        btfsc   locpend,2       ; avoids RAM reading if HP-41 is reset
        bcf     oph2,0          ; preventing poling-point loops on power-up.
;------------------- 119
        call    ferclk          ; b5H
;       nop
;       nop

        btfsc   locpend,2       ; avoids RAM reading if HP-41 is reset
        bcf     oph2,1          ; preventing poling-point loops on power-up.
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

checkrom2
        wtre    NUTPHI1         ; 33
;---------------------------------------------------------------------------- 27
;This is for processing the mapping of 32K RAM in a row

        movf    ctrlwrd,W
        swapf   WREG
        cpfseq  ctrlwrd
        bra     set32K
        bra     no32K
set32K
        andlw   0x03
        bz      no32K
        movlw   0x01
        movwf   romcb1map,c
        movwf   romdb1map,c
        movwf   romeb1map,c
        movwf   romfb1map,c
        movf    ctrlwrd,W
        swapf   WREG
        subfwb  ctrlwrd,w
        bn      noswp32K
        swapf   ctrlwrd

noswp32K
        movf    ctrlwrd,W
        andlw   0x03
        movwf   rammap00
        movf    ctrlwrd,W
        andlw   0x30
        swapf   WREG
        movwf   rammap01
        bra     proc32Kend

no32K
        btfss   romcb1map,0             ; If H was not RAM then
        bra     proc32Kend0             ; just clear rammap01
        movff   romcb2map,romcb1map     ; if it was RAM then recover it.
        movff   romdb2map,romdb1map
        movff   romeb2map,romeb1map
        movff   romfb2map,romfb1map

proc32Kend0
        clrf    rammap01
        bcf     ctrlwrd,4
        bcf     ctrlwrd,5

proc32Kend

        wtre    NUTPHI1         ; 34
;---------------------------------------------------------------------------- 20
;This is for preparing the variables to turn the unwanted chip OFF

        movf    rammap01,W
        bz      endramHproc
        decf    WREG
        bz      ramHis1
        decf    WREG
        bz      ramHis2
        bsf     ramchipH,5
        bra     endramHproc

ramHis1
        bsf     ramchipH,3
        bra     endramHproc

ramHis2
        bsf     ramchipH,4

endramHproc

        movf    rammap00,W      ; place it into Ram map register
        bz      ramis0
        decf    WREG
        bz      ramis1
        decf    WREG
        bz      ramis2
        bsf     ramchipL,5
        bra     endramproc
ramis0
        bsf     ramchipL,2
        bra     endramproc
ramis1
        bsf     ramchipL,3
        bra     endramproc
ramis2
        bsf     ramchipL,4

endramproc

        movf    ramchipH,w
        iorwf   ramchipL,w
        movwf   ramchip
endRP
        wtre    NUTPHI1         ; 35
;---------------------------------------------------------------------------- 17
; This is for RAM protection flags recovery Bank 0.

        movf    rammap00,W
        rlncf   WREG
        rlncf   WREG
        addlW   0x60
        movwf   FSR0L
        bcf     rom8b1map,1
        btfsc   POSTINC0,1
        bsf     rom8b1map,1
        bcf     rom9b1map,1
        btfsc   POSTINC0,1
        bsf     rom9b1map,1
        bcf     romab1map,1
        btfsc   POSTINC0,1
        bsf     romab1map,1
        bcf     rombb1map,1
        btfsc   POSTINC0,1
        bsf     rombb1map,1
endWP0
        wtre    NUTPHI1         ; 36
;---------------------------------------------------------------------------- 18
; This is for RAM protection flags recovery Bank 1.

        movf    rammap01,W
        bz      endWPproc
        rlncf   WREG
        rlncf   WREG
        addlW   0x60
        movwf   FSR0L
        bcf     romcb1map,1
        btfsc   POSTINC0,1
        bsf     romcb1map,1
        bcf     romdb1map,1
        btfsc   POSTINC0,1
        bsf     romdb1map,1
        bcf     romeb1map,1
        btfsc   POSTINC0,1
        bsf     romeb1map,1
        bcf     romfb1map,1
        btfsc   POSTINC0,1
        bsf     romfb1map,1

endWPproc

        wtre    NUTPHI1         ; 37
;---------------------------------------------------------------------------- 0

        call    swtre2          ; 38
;---------------------------------------------------------------------------- 12
        movf    addru,W         ; Gets address upper byte
        sublw   0x41            ; Is it H'41?
        bnz     check41map      ; If it ist'n go to check41map
        movf    addrl,W         ; Gets address lower byte
                                ; If it ist'n go to ramcheck
        bnz     ramcheck
        movf    ctrlwrd,W       ; Gets RAM map byte
        movwf   opl8            ; place it as code L for output on ISA line
        movf    rommap00,W      ; Gets ROM map byte
        movwf   oph2            ; place it as code H for output on ISA line
        bra     endRAMshw
ramcheck
        clrf    opl8
        clrf    oph2
        decf    WREG            ; If it's H'4101
        bnz     endRAMshw       ; Get Flash disable warning and
        movff   flashstat,opl8  ; place it as code L for output on ISA line
endRAMshw

        call    swtre2          ; 39
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 40
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 41
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 42
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 43
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 44
;---------------------------------------------------------------------------- 0
        call    swtre2          ; 45
        bra     outfromisa

check41map
        call    swtre2          ; 39
endwrite2
        call    swtre2          ; 40

        call    swtre2          ; 41
endwrite
        wtre    NUTPHI2         ; 42

;; The address of the opcode to fetch is in
;; We compute where in the table to find oph2 and opl8
;; get the upper four bits of the address, and see where
;; it maps in our tables.

        movf    addru,W
        andlw   0xF0            ; use the upper four bits ...
        swapf   WREG
        addwf   enromoff,W
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
        call    swtre2          ; 45

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
;       setf    TRISB
        bsf     OUTISA          ; sets ISA as input again.

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
        nop                     ; 1
        nop                     ; 2
        nop                     ; 3
        nop                     ; 4
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
        wtre    NUTPHI2         ; Sincronizes with Phi2 rising edge
        bcf     NUTISA          ; Bus pre-charge LOW > Activated for testing 06 Apr. 2011 Geir detected bug.
        bcf     OUTISA          ; To avoid noise     > with ARCLIP (NoVCHAP) and Zenrom.

        bsf     OUTISA          ; Make sure ISA is input again
        bsf     NUTISA          ; ISA line = High

        call    s5nop           ; Required?
        call    s5nop

        btfsc   INDF0,0         ; Check bit to send if 0 then do nothing
        bcf     OUTISA          ; If bit =  1 then ISA is output
        rrncf   INDF0           ; Shifts to the next bit
;       wtfe    NUTPHI1         ; Sincronizes with Phi1 falling edge (HP41 read)
;       call    s5nop
;       bsf     OUTISA          ; Make sure ISA is input again.
        return

RST_mode                        ; Sets RAM in Write-Only mode for crash recovery.
        bsf     locpend,2
        bsf     rom8b1map,0     ; Enables RAM at page 8
        bsf     rom9b1map,0     ; Enables RAM at page 9
        bsf     romab1map,0     ; Enables RAM at page A
        bsf     rombb1map,0     ; Enables RAM at page B

        movlw   0x40            ; Maps 1st HEPAX ROM page
        movwf   romcb1map       ; to page 8 bank 1

        movlw   0x50            ; Maps 2nd HEPAX ROM page
        movwf   romcb2map       ; to page 8 bank 2

        movlw   0x60            ; Maps 3rd HEPAX ROM page
        movwf   romcb3map       ; to page 8 bank 3

        movlw   0x70            ; Maps 4th HEPAX ROM page
        movwf   romcb4map       ; to page 8 bank 4
        return

;-------------------- Flash ROM page #F erasing.

;#include        "romerase.s"

;-------------------- RAM to Flash subroutine

;#include        "ram2rom4.s"
