;Available functions
;INITIALIZE_LCD, DISPLAY_TABLE
#include <p18f4620.inc>
#include <extern.inc>
		list P=18F4620, F=INHX32, C=160, N=80, ST=OFF, MM=OFF, R=DEC

PORTC_data              equ     0x3F
PORTB_data              equ     0x40
keypad_probing_result   equ     0x41
EEPROM_LOCH             equ     0x42
EEPROM_LOCL             equ     0x43

curr_light_num          equ     0x44
not_working             equ     0x45
one_working             equ     0x46
two_working             equ     0x47
three_working           equ     0x48
num_present             equ     0x58    

temp1                   equ     0x49
temp2                   equ     0x4A

RTC_Minute              equ     0x4B
RTC_Second              equ     0x4C
RTC_Year              equ     0x4D
RTC_Date              equ     0x4E
RTC_Day              equ     0x4F
RTC_Hour              equ     0x50
RTC_Hour_Old          equ       0x59
W_TEMP                  equ     0x5A
STATUS_TEMP             equ     0x5B
BSR_TEMP                equ     0x5C
BACK_FLAG               equ     0x5D
TOTAL_LIGHT             equ     0x5E
END_FLAG                equ     0x5F ;999999999
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
            goto    high_ISR
			org		0018h				;low priority ISR
            retfie      ;goto    IR_ISR

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
    store temp2, 0x22
    call WriteToI2CBuffer
    store temp1, 0x03 ; set day
    store temp2, 0x05
    call WriteToI2CBuffer
    store temp1, 0x04 ; set date
    store temp2, 0x22
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
    movlw   " "     ;blank space 
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
        movff RTC_Second, WREG  ;store new in temp1
        andlw 0x0F ; read lower nibble only
        movwf temp1

        movff RTC_Second_Old, WREG  ;store old in temp2
        andlw 0x0F
        movwf temp2

        ; temp1 (new) - temp2 (old)
        movff temp2, WREG
        subwf temp1, 0 ; put result in WREG
        bnn HighSecond_temp ; if result not negative, go deal with higher bit
        
        addlw d'10' ; else if negative, then add 10 to it
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


;*************************** EEPROM stuff ***************************************
;*******************************************************************************
store_EEPROM_log
;used in the end of detection process
;store results in the permanent log by shifting everything down one row
    store EEPROM_LOCH, 0x00     ;initialize counters for swaps
    store EEPROM_LOCL, 0x33

    lower_byte_loop
        movlw 0x30      ;OR the address with 0x30
        iorwf EEPROM_LOCL, 1    ;store result back in Address

        higher_byte_loop                  ;loop for higher bit addresses
            movlw 0x30      ;0011 0000 in binary, OR to check if 0
            andwf EEPROM_LOCL, 0    ;store in WREG, the other byte for outer loop

            tstfsz EEPROM_LOCL
            bra end_higher_byte_loop
            call test
            call delayquartersecond
            movff EEPROM_LOCL, WREG    ;read from LOCL - 0x10 Address
            sublw 0x10
            RD_EEPROM WREG, EEPROM_LOCH, temp1
            WR_EEPROM EEPROM_LOCL, EEPROM_LOCH, temp1 ; store at LOCL

            movff WREG, EEPROM_LOCL ;load the decremented address
            bra higher_byte_loop

        end_higher_byte_loop
        store temp1, 0x03
        beq temp1, EEPROM_LOCL, store_three     ;store data at the respective locations

        store temp1, 0x02
        beq temp1, EEPROM_LOCL, store_two

        store temp1, 0x01
        beq temp1, EEPROM_LOCL, store_one

        store temp1, 0x00
        beq temp1, EEPROM_LOCL, store_zero

        return

store_three
    WR_EEPROM   EEPROM_LOCL, EEPROM_LOCH, three_working
    decf EEPROM_LOCL
    bra lower_byte_loop

store_two
    WR_EEPROM   EEPROM_LOCL, EEPROM_LOCH, two_working
    decf EEPROM_LOCL
    bra lower_byte_loop

store_one
    WR_EEPROM   EEPROM_LOCL, EEPROM_LOCH, one_working
    decf EEPROM_LOCL
    bra lower_byte_loop

store_zero
    WR_EEPROM   EEPROM_LOCL, EEPROM_LOCH, not_working
    return
;
;test_EEPROM
;    movlw 0x04
;    movff WREG, temp1
;    movlw 0x00
;    movff WREG, EEPROM_LOCL
;    movlw 0x00
;    movff WREG, EEPROM_LOCH
;
;    WR_EEPROM EEPROM_LOCL, EEPROM_LOCH, temp1
;    return



;********************* INSPECTION SUBROUTINES *********************************
;******************************************************************************
display_quantity
    call  CLR_LCD
    movlw "3"
    call WR_DATA
    movlw ":"
    call WR_DATA
    movff three_working, WREG
    addlw 0x30
    call WR_DATA

    movlw " "
    call WR_DATA
    movlw "2"
    call WR_DATA
    movlw ":"
    call WR_DATA
    movff two_working, WREG
    addlw 0x30
    call WR_DATA

    movlw " "
    call WR_DATA
    movlw "1"
    call WR_DATA
    movlw ":"
    call WR_DATA
    movff one_working, WREG
    addlw 0x30
    call WR_DATA

    movlw " "
    call WR_DATA
    movlw "0"
    call WR_DATA
    movlw ":"
    call WR_DATA
    movff not_working, WREG
    addlw 0x30
    call WR_DATA

;    call delay2second
;    call delay2second
;    call delay2second
    disp_loop
        btfss   PORTB, 1
        bra disp_loop
    return

display_time_lapsed
    call ReadRTC
    call CLR_LCD
    call lapsed
    call CalculateTimeDiff
 
    movff RTC_Minute_Diff, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA


    movlw ":"
    call WR_DATA

    movff RTC_Second_Diff, WREG
    call ConvertRTC
    movff RTC_H, WREG
    call WR_DATA
    movff RTC_L, WREG
    call WR_DATA

    call delay2second
    return


;;;;;;;;;;;;;;;;;;;;;;******************************
;;;****************************ISR *****************************************
high_ISR
    MOVWF W_TEMP ; W_TEMP is in virtual bank
    MOVFF STATUS, STATUS_TEMP ; STATUS_TEMP located anywhere
    MOVFF BSR, BSR_TEMP ; BSR_TMEP located anywhere
    ;
    ; USER ISR CODE
    call ISR_message

    bcf PORTC, 6    ;clear motor signal
    bcf PORTC, 7    ;clear motor signal
    bsf PORTD, 0    ;make RD0 1
    inf_loop_isr
        bra inf_loop_isr        ;infinite loop, do nothing once emergency is activated
    ;
    MOVFF BSR_TEMP, BSR ; Restore BSR
    MOVF W_TEMP, WREG ; Restore WREG
    MOVFF STATUS_TEMP, STATUS ; Restore STATUS
    retfie

sense_light
    bcf PORTC, 6
    bcf PORTC, 7
    store temp2, 0x00
    store temp1, 0x00       ;temp1 stores the number of LEDs that are working
;    call test

;    call delayquartersecond
    ;read from RA1-3
    movff PORTC, PORTC_data
    movlw   0x1
    btfsc PORTC_data, 1  ;test if the first light is activated, TRUE -> add 1 to temp1
    addwf   temp1, 1
    btfsc PORTC_data, 2  ;test if the second light is activated, TRUE -> add 1 to temp1
    addwf   temp1, 1
    btfsc PORTC_data, 5  ;test if the third light is activated, TRUE -> add 1 to temp1
    addwf   temp1, 1

    ;increment the corresponding register
    movff temp1, WREG
    btfsc STATUS, Z   ;check if temp1 is 0 (if the Z bit is set)
    incf not_working    ;add to the not_working counter (no light is lit)

    sublw 1
    btfsc STATUS, Z   ;check if 1
    incf one_working  ;add if true

    movff temp1, WREG        ;WREG is changed, reload
    sublw 2           ;check if 2
    btfsc STATUS, Z
    incf two_working  ; add if it becomes 0 (TRUE)

    movff temp1, WREG        ;WREG is changed, reload
    sublw 3           ;check if 3
    btfsc STATUS, Z
    incf three_working  ; add if true

    ;incf TOTAL_LIGHT
    bcf PORTC, 6        ;run the motor again
    bsf PORTC, 7

    ;call delay44us
    ;call delay44us
    ;call delay44us

    li_loop
        call delay44us
        call delay44us
        btfsc PORTD, 0
        bra li_loop

    return 

IR_back
    bcf PORTC, 6
    bcf PORTC, 7
    call delayquartersecond
    bsf PORTC, 6
    call delay2second
    call delay2second
    back_loop
        bcf PORTC, 6
        bcf PORTC, 7
        call delay44us
        bsf PORTC, 6
        call delay44us

        btfss PORTC, 0  ;test if IR2 senses anything on the way back
        bra back_loop
    goto THE_END

THE_END
        ;turns off motor
        bcf PORTC, 6
        bcf PORTC, 7

        call display_time_lapsed
        call display_quantity
        ;call display_time_lapsed
        call finito        ;display finish message after operation

        goto    welcome     ;goes back to home

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;Main function;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
boot
;*initialize everything
        call CLR_PORTS                ;clear the ports
		call INIT_LCD                 ;initialize LCD
;        store   EEPROM_LOCH, 0x02     ;specify EEPROM location
;        store   EEPROM_LOCL, 0x00
;        store   BACK_FLAG, 0x0
;        store   END_FLAG, 0x0
;        store   TOTAL_LIGHT, 0x0
        call InitializeI2C
        ;call SetRTC
        ;call test_EEPROM
        ;Set ISR
        ;bsf RCON, 7         ;enable priority levels on interrupts
        bsf RCON, IPEN ;enables levels of interrupt
        clrf INTCON
        bsf INTCON, INT0IE    ;enables external interrupt    
        clrf INTCON2
        bsf INTCON2, INTEDG0 ;rising edge interrupt
        ;bsf INTCON2, INTEDG2 ;rising edge interrupt RB2
        ;clrf INTCON3
        ;bcf INTCON3, INT2IP  ;INT2 low priority
        ;bsf INTCON3, INT2IE  ;enables INT2/RB2 as an interrupt
        bsf INTCON, GIEH     ;enable global
        ;bsf INTCON, GIEL


welcome
		call Home                     ;display Home
        call delay1second
        store curr_light_num, 9       ;light counter, decrements after each inspection
        store not_working, 0
        store one_working, 0
        store two_working, 0
        store three_working, 0
        goto menu                     ;poll keys and display menu accordingly

menu
; shows menu if any key is pressed
         call CLR_LCD
         call DisplayRTC_BottomLeft

         main_menu_loop
             movff  PORTB, PORTB_data   ;store at another variable
             btfsc  PORTB_data, 1       ;test if key is pressed
                 bra pressed                ;skip if PORTB 2 is clear (none pressed)
             bra main_menu_loop         ;branches back to itself, keep polling

         pressed
                call CLR_LCD
                call main_menu
                call delayquartersecond
                goto menu_selection
          
menu_selection
; user decides whether LOG or OPERATION

        movff PORTB, PORTB_data     ;store data from PORTB

        ;test A and 3, if nothing then loop to itself

        ;test 3
        store temp1, b'00100010'
        beq     PORTB_data, temp1, operation_selected

        ;else, test if A is pressed
        store temp1, b'00110010'
        beq     PORTB_data, temp1, log_selected

        store temp1, b'11000010'
        beq     PORTB_data, temp1, debugger_mode
        bra menu_selection    ;loop back to itself if no valid input
        

debugger_mode
    store temp1, b'10000010'
    beq PORTB, temp1, turn_left

    bra debugger_mode
    turn_left
        store temp1, b'10000010'
        bcf PORTC, 7
        bsf PORTC, 6
        beq PORTB, temp1, turn_left
        bcf PORTC, 6
        goto welcome

operation_selected
; what to do if operation selected

        ; capture start time here
        call CLR_LCD
        call ReadRTC
        movff   RTC_Second, RTC_Second_Old
        movff   RTC_Minute, RTC_Minute_Old
        movff   RTC_Hour, RTC_Hour_Old

        call operation     ;display operation

        ;run motor, loop
        bcf PORTC, 6
        bsf PORTC, 7
;
;        wait_op
;            btfsc PORTD, 0
;            bra wait_op
;            btfsc PORTC, 0
;            bra wait_op

        call delayquartersecond
        call delayquartersecond

        op_loop
            btfsc PORTC, 0; test if IR2 senses anything
            goto IR_back
;
;            bcf PORTC, 6
;            bcf PORTC, 7
;            call delay44us
;            bcf PORTC, 6
;            bsf PORTC, 7

            btfsc PORTD, 0; test if IR senses anything (0->nothing)
            call sense_light

;            call delay44us
            bra op_loop
        ;goto THE_END

log_selected
; what to do if log selected
        call log_menu       ;display log menu
        goto probe_log_menu_selection

probe_log_menu_selection
; test what input is selected in LOG menu
; test A and 3, if nothing then loop to itself
        movff PORTB , PORTB_data     ;store data from PORTB

        ;test 3
        store temp1, b'00100010'
        beq     PORTB_data, temp1, upload_selected

        ;test A
        store temp1, b'00110010'
        beq     PORTB_data, temp1, viewlog_selected

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

        store temp1, b'00100010'
        beq     PORTB_data, temp1, log_3_selected

        store temp1, b'00010010'
        beq     PORTB_data, temp1, log_2_selected

        store temp1, b'00000010'
        beq     PORTB_data, temp1, log_1_selected

        store temp1, b'01000010'
        beq     PORTB_data, temp1, log_4_selected

        bra log_secondary_menu_selected    ;loop back to itself if no valid input

log_3_selected
        call    CLR_LCD

        RD_EEPROM_LIT   0x00, 0x20, WREG    ;load data to WREG
        call zero_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x21, WREG    ;load data to WREG
        call one_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x22, WREG    ;load data to WREG
        call two_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x23, WREG    ;load data to WREG
        call three_message
        addlw 0x30
        call WR_DATA                ;write EEPROM data to LCD

        goto     home_select_probe

log_2_selected
        call    CLR_LCD

        RD_EEPROM_LIT   0x00, 0x10, WREG    ;load data to WREG
        call zero_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x11, WREG    ;load data to WREG
        call one_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x12, WREG    ;load data to WREG
        call two_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x13, WREG    ;load data to WREG
        call three_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        goto     home_select_probe

log_1_selected
        call    CLR_LCD

        RD_EEPROM_LIT   0x00, 0x00, WREG    ;load data to WREG
        call zero_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x01, WREG    ;load data to WREG
        call one_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x02, WREG    ;load data to WREG
        call two_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x03, WREG    ;load data to WREG
        call three_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        goto     home_select_probe

log_4_selected
        call    CLR_LCD

        RD_EEPROM_LIT   0x00, 0x30, WREG    ;load data to WREG
        call zero_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x31, WREG    ;load data to WREG
        call one_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x32, WREG    ;load data to WREG
        call two_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        RD_EEPROM_LIT   0x00, 0x33, WREG    ;load data to WREG
        call three_message
        addlw 0x30
        call WR_DATA                ;write to LCD

        bra     home_select_probe

home_select_probe
        movff PORTB, PORTB_data     ;store data from PORTB

        ;test A, if nothing then loop to itself

        store temp1, b'00110010'
        beq     PORTB_data, temp1, menu
        bra home_select_probe

    end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


