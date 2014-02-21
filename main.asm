;Available functions
;INITIALIZE_LCD, DISPLAY_TABLE
#include <p18f4620.inc>
#include <lcd.inc>
		list P=18F4620, F=INHX32, C=160, N=80, ST=OFF, MM=OFF, R=DEC

PORTB_data              equ     0x40
keypad_probing_result   equ     0x41

;;;;;;Configuration Bits;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		CONFIG OSC=INTIO67, FCMEN=OFF, IESO=OFF
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

			org		0x0000
			goto	welcome
			org		0x08				;high priority ISR
			retfie
			org		0x18				;low priority ISR
			retfie

;;;;;;;;;;;;;;;;;;;Main function;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
welcome
		  call Home                     ;display Home
          bra menu                     ;poll keys and display menu accordingly

menu
; shows menu if any key is pressed
         movff  PORTB, PORTB_data   ;store at another variable

         main_menu_loop
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
         call operation     ;display operation
         call finito        ;display finish message after operation
         bra    welcome     ;goes back to home

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
        bra welcome

;*************** user chooses to view log ***********************************
viewlog_selected
        call viewlog_msg
        bra log_secondary_menu_selected
        
log_secondary_menu_selected
        movff PORTB, PORTB_data     ;store data from PORTB

        ;test 1,2,3, if nothing then loop to itself
;
;        logsec_menu_loop
;             movff  PORTB, PORTB_data   ;store at another variable
;             btfsc  PORTB_data, 1       ;test if key is pressed
;                 bra log_3_selected                ;skip if PORTB 2 is clear (none pressed)
;             bra logsec_menu_loop         ;branches back to itself, keep polling
;        test if 3 is pressed
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
        bra welcome
end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;