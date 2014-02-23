;Available functions
;INITIALIZE_LCD, DISPLAY_TABLE
#include <p18f4620.inc>
#include <extern.inc>
		list P=18F4620, F=INHX32, C=160, N=80, ST=OFF, MM=OFF, R=DEC

PORTB_data              equ     0x40
keypad_probing_result   equ     0x41
EEPROM_LOCH             equ     0x42
EEPROM_LOCL             equ     0x43

curr_light_num          equ     0x44
not_working             equ     0x45
one_working             equ     0x46
two_working             equ     0x47
three_working           equ     0x48

temp1                   equ     0x49
temp2                   equ     0x4A

RTC_Minute              equ     0x4B
RTC_Second              equ     0x4C
RTC_Year              equ     0x4D
RTC_Date              equ     0x4E
RTC_Day              equ     0x4F
RTC_Hour              equ     0x50
RTC_Second_Diff       equ       0x51
RTC_Second_Old       equ       0x52
RTC_Minute_Diff       equ       0x53
RTC_Minute_Old       equ       0x54
RTC_L               equ         0x55
RTC_H               equ         0x56
RTC_Month              equ     0x57

;;;;;;Configuration Bits;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		CONFIG OSC=INTIO7, FCMEN=OFF, IESO=OFF
		CONFIG PWRT = OFF, BOREN = SBORDIS, BORV = 3
		CONFIG WDT = OFF, WDTPS = 32768
		CONFIG MCLRE = ON, LPT1OSC = OFF, PBADEN = OFF, CCP2MX = PORTC
		CONFIG STVREN = ON, LVP = OFF, XINST = OFF
		CONFIG DEBUG = OFF
		CONFIG CP0 = OFF, CP1 = OFF, CP2 = OFF, CP3 = OFF
		CONFIG CPB = OFF, CPD = OFF
		CONFIG WRT0 = OFF, WRT1 = OFF, WRT2 = OFF, WRT3 = OFF
		CONFIG WRTB = OFF, WRTC = OFF, WRTD = OFF
		CONFIG EBTR0 = OFF, EBTR1 = OFF, EBTR2 = OFF, EBTR3 = OFF
		CONFIG EBTRB = OFF




;;;;;;Vectors;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            code 
			org		0x0000
			goto	boot
			org		0x08				;high priority ISR
			retfie
			org		0x18				;low priority ISR
			retfie


;*********************************
; RTC Routines
;*********************************
InitializeI2C
    store SSPCON1, B'00101000' ; enable MSSP mode, set to I2C master mode
    store SSPSTAT, B'10000000' ; disable slew rate control for 100kHz
    store SSPADD, D'24' ; F_osc/(4*(SSPADD+1))
    call StartI2CBit
    movlw 0xD0 ; RTC slave address | write bit
    call WriteI2C
    movlw 0x07 ; points to RTC register address
    call WriteI2C
    movlw 0x90 ; Enable square wave output on RTC
    call WriteI2C ; refer DS1307 datasheet
    call StopI2CBit
    return
StartI2CBit
    bsf SSPCON2,SEN ; enable start
    call WaitI2C
    return
StopI2CBit
    bsf SSPCON2,PEN ; enable stop
    call WaitI2C
    return
WriteI2C
    movwf SSPBUF
    call WaitI2C
    return
WaitI2C
    btfss PIR1,SSPIF ; wait for SSPIF = 1
    goto $-2
    bcf PIR1,SSPIF ; clear SSPIF in software
    return
SetRTC ; NOTE: only for initialization purpose
; when battery is removed
    store temp1, 0x00 ; set second
    store temp2, 0x00
    call WriteToI2CBuffer
    store temp1, 0x01 ; set minutes
    store temp2, 0x00
    call WriteToI2CBuffer
    store temp1, 0x02 ; set hour
    store temp2, 0x23
    call WriteToI2CBuffer
    store temp1, 0x03 ; set day
    store temp2, 0x05
    call WriteToI2CBuffer
    store temp1, 0x04 ; set date
    store temp2, 0x21
    call WriteToI2CBuffer
    store temp1, 0x05 ; set month
    store temp2, 0x02
    call WriteToI2CBuffer
    store temp1, 0x06 ; set year
    store temp2, 0x14
    call WriteToI2CBuffer
    return
WriteToI2CBuffer ; take temp1 as address
; take temp2 as data
    call StartI2CBit
    movlw 0xD0 ; RTC slave address | write bit
    call WriteI2C
    movf temp1, w ; points to RTC register address
    call WriteI2C
    movf temp2, w
    call WriteI2C
    call StopI2CBit
    return
ReadFromI2CBuffer ; output to WREG
    btfsc SSPSTAT, 2 ; check if address needs to be updated
    bra $-2
    bsf SSPCON2, RCEN ; enable receive
    call WaitI2C
    bcf PIR1, SSPIF ; clear interrupt flag
    call I2C_ACK ; send ACK bit to keep reading
    movf SSPBUF, W ; move data from buffer to W register
    return
ReadFromI2CBufferNACK ; output to WREG
    btfsc SSPSTAT, 2 ; check if address needs to be updated
    bra $-2
    bsf SSPCON2, RCEN ; enable receive
    call WaitI2C
    bcf PIR1, SSPIF ; clear interrupt flag
    call I2C_NACK ; send NACK bit to stop reading
    movf SSPBUF, W ; move data from buffer to W register
    return
ReadRTC
    call StartI2CBit
    movlw 0xD0 ; RTC slave addr | write
    call WriteI2C
    movlw 0x00 ; points to register 0x00
    call WriteI2C
    call StopI2CBit
    call StartI2CBit
    movlw 0xD1 ; RTC slave addr | read
    call WriteI2C
    call ReadFromI2CBuffer
    movwf RTC_Second
    call ReadFromI2CBuffer
    movwf RTC_Minute
    call ReadFromI2CBuffer
    movwf RTC_Hour
    call ReadFromI2CBuffer
    movwf RTC_Day
    call ReadFromI2CBuffer
    movwf RTC_Date
    call ReadFromI2CBuffer
    movwf RTC_Month
    call ReadFromI2CBufferNACK
    movwf RTC_Year
    call StopI2CBit
    return
I2C_ACK
    bcf SSPCON2, ACKDT ; acknowledge receiving
    bsf SSPCON2, ACKEN
    call WaitI2C
    return
I2C_NACK
    bsf SSPCON2, ACKDT ; not acknowledge receiving
    bsf SSPCON2, ACKEN
    call WaitI2C
    return
ConvertRTC ; convert upper and lower nibble into ASCII
; input: WREG, output: RTC_H, RTC_L
    movwf temp1
    swapf temp1,W
    andlw B'00001111'
    addlw 0x30
    movwf RTC_H
    movf temp1,W
    andlw B'00001111'
    addlw 0x30
    movwf RTC_L
    return
DisplayRTC_BottomLeft
    call ReadRTC
    ; display time and date
;    display TableTime, B'11000000'
    movff RTC_Hour, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA
    movlw 0x3A ; : character
    call WR_DATA
    movff RTC_Minute, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA
;    DisplayOnLCD TableDate, B'10000000'
    movlw   " "
    call WR_DATA
    movff RTC_Year, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA
    movlw 0x2D ; - character
    call WR_DATA
    movff RTC_Month, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA
    movlw 0x2D ; - character
    call WR_DATA
    movff RTC_Date, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA
    return
CalculateTimeDiff
    LowSecond
        ; lower digit of second
        movff RTC_Second, WREG
        andlw 0x0F ; read lower nibble only
        movwf temp1
        movff RTC_Second_Old, WREG
        andlw 0x0F
        movwf temp2
        ; temp1 (new) - temp2 (old)
        movff temp2, WREG
        subwf temp1, 0 ; put result in WREG
        bnn HighSecond_temp ; if result not negative
        ; go deal with higher bit
        ; if negative, then add 10 to it
        addlw d'10'
        andlw 0x0F ; mask to have lower bit only
        movwf RTC_Second_Diff
        ; and add 1 to the high digit of second of the OLD one
        swapf RTC_Second_Old, 0 ; swap to lower nibble and store in W
        andlw 0x0F ; mask it
        incf WREG ; add one
        swapf WREG ; swap back to upper nibble
        movwf RTC_Second_Old ; move it back to old data
        bra HighSecond
    HighSecond_temp
        andlw 0x0F
        movwf RTC_Second_Diff
    HighSecond
    ; high digit of second
        swapf RTC_Second, w
        andlw 0x0F ; read lower nibble only
        movwf temp1
        swapf RTC_Second_Old, w
        andlw 0x0F
        movwf temp2
        ; temp1 (new) - temp2 (old)
        movff temp2, WREG
        subwf temp1, 0 ; put result in WREG
        bnn LowMinute_temp ; if result not negative
        ; go deal with higher bit
        ; if negative, then add 6 to it
        addlw d'6'
        swapf WREG
        andlw 0xF0 ; mask to only have upper bit
        addwf RTC_Second_Diff, 1 ; add to store into the second difference
        ; and add 1 to the low digit of minute of the OLD one
        ; before adding it, need to check if it's 9. If it is, then will need
        ; to add one to HighMinute
        sublw d'9'
        bnz MinuteLowAddOne
    MinuteHighAddOne
        movlw 0xF0 ; make the lower bit 0 (bcoz 9+1=10)
        andwf RTC_Minute_Old, 1
        movlw 0x10
        addwf RTC_Minute_Old, 1 ; add 1 to the high nibble
        bra LowMinute
    MinuteLowAddOne
        ; simply add 1 to the RTC_Minute_Old
        incf RTC_Minute_Old, 1
        bra LowMinute
    LowMinute_temp
        andlw 0x0F
        swapf WREG
        addwf RTC_Second_Diff
    LowMinute
        ; lower digit of minute
        movff RTC_Minute, WREG
        andlw 0x0F ; read lower nibble only
        movwf temp1
        movff RTC_Minute_Old, WREG
        andlw 0x0F
        movwf temp2
        ; temp1 (new) - temp2 (old)
        movff temp2, WREG
        subwf temp1, 0 ; put result in WREG
        bnn HighMinute_temp ; if result not negative
        ; go deal with higher bits
        ; if negative, then add 10 to it
        addlw d'10'
        andlw 0x0F ; mask to have lower bit only
        movwf RTC_Minute_Diff
        ; and add 1 to the high digit of minute of the OLD one
        swapf RTC_Minute_Old, 0 ; swap to lower nibble and store in W
        andlw 0x0F ; mask it
        incf WREG ; add one
        swapf WREG ; swap back to upper nibble
        movwf RTC_Minute_Old ; move it back to old data
        bra HighMinute
    HighMinute_temp
        andlw 0x0F
        movwf RTC_Minute_Diff
    HighMinute
        ; high digit of minute
        swapf RTC_Minute, w
        andlw 0x0F ; read lower nibble only
        movwf temp1
        swapf RTC_Minute_Old, w
        andlw 0x0F
        movwf temp2
        ; temp1 (new) - temp2 (old)
        movff temp2, WREG
        subwf temp1, 0 ; put result in WREG
        bnn EndCalculation_temp ; if result not negative
        ; go deal with higher bit
        ; if negative, then add 6 to it
        addlw d'6'
        swapf WREG
        andlw 0xF0 ; mask to only have upper bit ; mask to only have upper bit
        addwf RTC_Minute_Diff, 1 ; add to store into the second difference
        ; and add 1 to the low digit of hour of the OLD one
    bra EndCalculation
    EndCalculation_temp
        andlw 0x0F
        swapf WREG
        addwf RTC_Minute_Diff
    EndCalculation
    return
;;;;;;;;;;;;;;;;;;;Main function;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boot
;*initialize everything
        call CLR_PORTS                ;clear the ports
		call INIT_LCD                 ;initialize LCD
        store   EEPROM_LOCH, 0x01     ;specify EEPROM location
        store   EEPROM_LOCL, 0x00
        store curr_light_num, 9       ;light counter, decrements after each inspection
        store not_working, 0           
        store one_working, 0           
        store two_working, 0            
        store three_working, 0
        call InitializeI2C
        ;call SetRTC


welcome
		  call Home                     ;display Home
          goto menu                     ;poll keys and display menu accordingly

menu
; shows menu if any key is pressed
         movff  PORTB, PORTB_data   ;store at another variable

         main_menu_loop
             call CLR_LCD
             call DisplayRTC_BottomLeft
             movff  PORTB, PORTB_data   ;store at another variable
             btfsc  PORTB_data, 1       ;test if key is pressed
                 bra pressed                ;skip if PORTB 2 is clear (none pressed)
             bra main_menu_loop         ;branches back to itself, keep polling

         pressed
                call CLR_LCD
                call main_menu
                call delay1second
                bra menu_selection
          
menu_selection
; user decides whether LOG or OPERATION

        movff PORTB, PORTB_data     ;store data from PORTB

        ;test A and 3, if nothing then loop to itself

        ;test 3
        movlw b'00100010'   ;move B into W
        xorwf PORTB_data, 0 ;XOR PORTB with B, store in W
        ;if W becomes 0, then B is pressed, else B not pressed
        bnz test_A         ;will branch if anything else than B pressed
        bra operation_selected



        ;else, test if A is pressed
        test_A
            movlw b'00110010'           ;move A's complement into W
            xorwf PORTB_data, 0         ;XOR PORTB with A, becomes 0 if pressed
            bnz none_pressed_menu_select
            bra log_selected

        none_pressed_menu_select
            bra menu_selection    ;loop back to itself if no valid input
        
            
operation_selected
; what to do if operation selected

        ; capture start time here
         call operation     ;display operation

         ; do stuff here



         call finito        ;display finish message after operation
         ;capture end time, find differences and display it
         ;delay for 2 seconds
         goto    welcome     ;goes back to home

log_selected
; what to do if log selected
        call log_menu       ;display log menu
        bra probe_log_menu_selection

probe_log_menu_selection
; test what input is selected in LOG menu
        movff PORTB, PORTB_data     ;store data from PORTB

        ;test A and 3, if nothing then loop to itself

        ;test 3
        movlw b'00100010'   ;move B into W
        xorwf PORTB_data, 0 ;XOR PORTB with B, store in W
        ;if W becomes 0, then B is pressed, else B not pressed
        bnz test_A_log_select         ;will branch if anything else than B pressed
        bra upload_selected

        ;else, test if A is pressed (user chooses "view log")
        test_A_log_select
            movlw b'00110010'           ;move A into W
            xorwf PORTB_data, 0         ;XOR PORTB with A, becomes 0 if pressed
            bnz none_pressed_log_select
            bra viewlog_selected

        none_pressed_log_select
            bra probe_log_menu_selection    ;loop back to itself if no valid input

;************** user chooses to upload ********************************
upload_selected
;upload stuff if it's selected
        call upload_msg
        call finito
        goto welcome

;*************** user chooses to view log ***********************************
viewlog_selected
        call viewlog_msg
        bra log_secondary_menu_selected
        
log_secondary_menu_selected
        movff PORTB, PORTB_data     ;store data from PORTB

        test_3
            movlw b'00100010'           ;move 3 into W
            xorwf PORTB_data, 0         ;XOR PORTB with 3, becomes 0 if pressed
            bnz test_2                  ;branches if not 0 (not 3)
            bra log_3_selected          ;else display task 3 info

        test_2
            movlw b'00010010'           ;move 2 into W
            xorwf PORTB_data, 0         ;XOR PORTB with A, becomes 0 if pressed
            bnz test_1
            bra log_2_selected

        test_1
            movlw b'00000010'           ;move 1 into W
            xorwf PORTB_data, 0         ;XOR PORTB with A, becomes 0 if pressed
            bnz viewlog_no_valid_input
            bra log_1_selected

        viewlog_no_valid_input
            bra log_secondary_menu_selected    ;loop back to itself if no valid input

log_3_selected
        call    show_log
        bra     home_select_probe
log_2_selected
        call    show_log
        bra     home_select_probe
log_1_selected
        call    show_log
        bra     home_select_probe

home_select_probe
        movff PORTB, PORTB_data     ;store data from PORTB

        ;test A, if nothing then loop to itself

        ;test A
        movlw b'00110010'   ;move A into W
        xorwf PORTB_data, 0 ;XOR PORTB with A, store in W
        bnz home_select_probe         ;will loop if anything else than A pressed
        goto menu
    end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;********************* INSPECTION SUBROUTINES *********************************
detection
    ;rotate plate once, send pulse to motor

    ;read from RA0(IR), if not true branch to storage

    ;read from RA1-3

    status_storage
        ;increment the corresponding register

    ;decrement curr_light_num, if not 0, loop

    ;store at EEPROM

    return
