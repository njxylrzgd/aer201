    extern Home, CLR_PORTS, CLR_LCD, WR_DATA, delay2second, delay1second, INIT_LCD
    extern log_menu, main_menu, operation, upload_msg, viewlog_msg, show_log
    extern operation, finito
    ;extern INIT_I2C, SET_RTC_VAL, INIT_READ, read_RTC_Nack, read_RTC_ack

;************** GENERAL *********************
;************** MACRO   *********************

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


;************** EEPROM **********************
;************** MACRO  **********************

READ_EEPROM macro   addL, addH, eeprom_target
;   addresses - literals, eeprom_target a register
;   read from specified EEPROM address and store at target
    movlw   addL        ;load address into EEADR registers
    movwf   EEADR
    movlw   addH
    movwf   EEADRH

    bcf     EECON1, EEPGD       ;clear the EEPGD, now operates on data memory
    bcf     EECON1, CFGS       ; Access EEPROM
    bsf     EECON1, RD       ; initiates read
    movff   EEDATA, eeprom_target       ;move data into target
    endm

WR_EEPROM   macro   addH,   addL,  eeprom_data
;   params all literals
;   write to a EEPROM location
    movlw   addL        ;load address into EEADR registers
    movwf   EEADR
    movlw   addH
    movwf   EEADRH
    movlw   eeprom_data
    movwf   EEDATA

    bcf     EECON1, EEPGD       ;clear the EEPGD, now operates on data memory
    bcf     EECON1, CFGS       ; Access EEPROM
    bsf     EECON1, WREN       ; enables write

    bcf     INTCON, GIE         ;disables interrupt
    movlw   55h                 ;required
    movwf   EECON2
    movlw   0AAh
    movwf   EECON2
    bsf     EECON1, WR          ;initiates write
    bsf     INTCON, GIE         ;enables interrupt

    bcf     EECON1, WREN        ;disables write

    endm

;************** RTC  **********************
;************** MACRO  **********************
READ_RTC     macro   sec, min, hour, day, date, month, year
    call    INIT_READ
    call    read_RTC_ack
    movwf   sec
    call    read_RTC_ack
    movwf   min
    call    read_RTC_ack
    movwf   hour
    call    read_RTC_ack
    movwf   day
    call    read_RTC_ack
    movwf   date
    call    read_RTC_ack
    movwf   month
    call    read_RTC_Nack
    movwf   year

    bsf     SSPCON2,PEN             ; enable stop
    btfss   PIR1,SSPIF              ; wait for SSPIF = 1
    bra wait                        ;changed from goto $-2 ******************
    bcf     PIR1,SSPIF              ; clear SSPIF in software
    endm

RTC_DECODER macro   var, H, L					; convert upper and lower nibble into ASCII
	movwf	var
	swapf	var, WREG
	andlw	B'00001111'
	addlw	0x30                    ; add hex30 to convert to ASCII
	movwf	H
	movf	var, WREG
	andlw	B'00001111'             ; do the same thing for the lower byte
	addlw	0x30
	movwf	L
	endm
