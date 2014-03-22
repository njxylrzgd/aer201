    #include <p18f4620.inc>

#define   RS        PORTD,2        ; for v 1.0 used PORTD.2
#define   E         PORTD,3        ; for v 1.0 used PORTD.3

temp_lcd  EQU       0x30           ; buffer for Instruction
dat       EQU       0x31           ; buffer for data
delay1	  EQU		0x35
delay2	  EQU		0x36
delay3	  EQU		0x37
delay4    equ       0x38

store       macro   var_name,   val
            movlw   val
            movwf   var_name
            endm

display     macro   table_name
            movlw		upper table_name
            movwf		TBLPTRU
            movlw		high table_name
            movwf		TBLPTRH
            movlw		low table_name
            movwf		TBLPTRL
            tblrd*
            movf		TABLAT, W
            call Again
            endm

            code

            global Home, CLR_PORTS, CLR_LCD, WR_DATA, delay2second, delay1second, INIT_LCD, delayquartersecond
            global log_menu, main_menu, operation, upload_msg, viewlog_msg, show_log
            global operation, finito, lapsed, test, ISR_message
            global delay5ms
;;;;;;;;;;;;;;Menu options;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Home
          call CLR_LCD   
          display Welcome_message       ;display welcome msg, wait for 2 sec
          call delay1second
          call CLR_LCD                  ;clear LCD and write Home message
          display Press_any_key
          return

main_menu
        call CLR_LCD
        display Menu
        return

;**********log related menu

test
        call CLR_LCD
        display input_now
        return 
log_menu
        call CLR_LCD
        display Log_menu
        call delay1second                  ;CHANGE THIS LATERRRRRRRRRR
        return

upload_msg
        call CLR_LCD
        display Upload_message
        call delay2second
        return

viewlog_msg
        call CLR_LCD
        display Log_secondary_menu
        call delay1second
        return 

show_log
        call CLR_LCD
        display Viewlog_menu
        call delay2second
        return

;**********operation related menu
operation
        call CLR_LCD
        display Working
        call delay2second                   ;CHANGE THIS LATEREEEEEEEEE
        return

finito
        call CLR_LCD
        display Finished
        call delay2second
        return 

lapsed
        call CLR_LCD
        display Time_lapsed
        return


ISR_message
        call CLR_LCD
        display Abort
        return 


        
;;;;;;;;;;;;;;;;;;;;;;;;;LCD commands;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CLR_PORTS
        store   TRISA,  B'00000000'     ;clear ports
        store   TRISB,  b'11110011'    ; Set required keypad inputs
		store	TRISC,  B'00111111'
	    store   TRISD,  B'00000001'    ; all output except RD0(IR)
;
;        clrf      LATA
;        clrf      LATB
;        clrf      LATC
;        clrf      LATD
        clrf      PORTA
        clrf      PORTB
        clrf      PORTC
        clrf      PORTD
        

        ;store   ADCON1, B'00001011'     ; set AD converter
        return

INIT_LCD
        call      delay5ms		;wait for LCD to start up
        call      delay5ms
        movlw     B'00110011'
        call      WR_INS
        movlw     B'00110010'
        call      WR_INS
        movlw     B'00101000'    ; 4 bits, 2 lines,5X7 dot
        call      WR_INS
        movlw     B'00001100'    ; display on/off
        call      WR_INS
        movlw     B'00000110'    ; Entry mode
        call      WR_INS
        movlw     B'00000001'    ; Clear ram
        call      WR_INS
        return


CLR_LCD
        movlw   B'11000000'         ; 2nd line
        call    WR_INS
        movlw   B'00000001'         ; clear 2nd line
        call    WR_INS
        movlw   B'10000000'         ; 1st line
        call    WR_INS
        movlw   B'00000001'         ; clear 1st line
        call    WR_INS
        return

WR_INS

		bcf		RS	  				; clear Register Status bit
		movwf	temp_lcd			; store instruction
		andlw	0xF0			  	; mask 4 bits MSB
		movwf	LATD			  	; send 4 bits MSB

		bsf		E					; pulse enable high
		swapf	temp_lcd, WREG		  	; swap nibbles
		andlw	0xF0			  	; mask 4 bits LSB
		bcf		E
		movwf	LATD			  	; send 4 bits LSB
		bsf		E					; pulse enable high
		nop
		bcf		E
		call	delay5ms

		return

WR_DATA

		bcf		RS					; clear Register Status bit
        movwf   dat				; store character
        movf	dat, WREG
		andlw   0xF0			  	; mask 4 bits MSB
        addlw   4			  	; set Register Status
        movwf   PORTD			  	; send 4 bits MSB

		bsf		E					; pulse enable high
        swapf   dat, WREG		  	; swap nibbles
        andlw   0xF0			  	; mask 4 bits LSB
		bcf		E
        addlw   4				; set Register Status
        movwf   PORTD			  	; send 4 bits LSB
		bsf		E					; pulse enable high
		nop
		bcf		E

		call	delay44us

        return


;******************************************************************************
; Delay44us (): wait exactly  110 cycles (44 us)
; <www.piclist.org>

delay44us
		movlw	0x23
		movwf	delay1, 0

        Delay44usLoop
                decfsz	delay1, f
                goto	Delay44usLoop
        return

delay5ms
		movlw	0xC2
		movwf	delay1,0        ;store 194 in delay1 in Access Bank
		movlw	0x0A
		movwf	delay2,0
        Delay5msLoop
                decfsz	delay1, 1
                bra	d2
                decfsz	delay2, 1
                d2
                    bra	Delay5msLoop
		return

delay2second
        movlw   D'40'
        movwf   delay3, 0
        d2sloop
            decf    delay3, 1
            call delay5ms
            bnz     d2sloop
        return

delay1second
        movlw   D'20'
        movwf   delay3, 0
        d1sloop
            decf    delay3, 1
            call delay5ms
            bnz     d1sloop
        return

delayquartersecond
    movlw   D'20'
    movwf   delay3, 0
    dqsloop
        decf    delay3, 1
        call delay5ms
        bnz     dqsloop
    return

Again
              call      WR_DATA
              tblrd+*
              movf		TABLAT, W
              bnz		Again
              return

Welcome_message         db	"Welcome User", 0
Press_any_key           db  "Press any key", 0
Menu                    db  "A-LOG 3-START", 0
Working                 db  "Working...", 0
Finished                db  "Task completed", 0
Abort                   db  "Aborted", 0
Log_menu                db  "A-VIEW 3-UPLOAD", 0
Upload_message          db  "uploading..."
Log_secondary_menu      db  "Select: 1,2,3", 0
Viewlog_menu               db  "0:_ 1:_ 2:_ 3:_", 0
Time_lapsed             db  "Lapsed: ", 0
input_now               db  "input now, 4s", 0

end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

