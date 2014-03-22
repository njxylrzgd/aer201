    extern Home, CLR_PORTS, CLR_LCD, WR_DATA, delay2second, delay1second, INIT_LCD, delayquartersecond
    extern log_menu, main_menu, operation, upload_msg, viewlog_msg, show_log
    extern operation, finito, lapsed, test, ISR_message
    extern delay5ms
    ;extern INIT_I2C, SET_RTC_VAL, INIT_READ, read_RTC_Nack, read_RTC_ack

TRUE    equ     B'1'
FALSE   equ     B'0'

;************** GENERAL *********************
;************** MACRO   *********************

store       macro   var_name,   val
            movlw   val
            movwf   var_name
            endm

beq    macro   var1, var2, label
        movff var1, WREG        ;store var1 in W
        subwf var2, 0           ;subtract W from var2, store in W
        btfsc STATUS, Z
        goto label              ;if W is 0, go to label
        endm

bne    macro   var1, var2, label
        movff var1, WREG        ;store var1 in W
        subwf var2, 0           ;subtract W from var2, store in W
        btfss STATUS, Z
        goto label              ;if W is 0, go to label
        endm

;************** EEPROM **********************
;************** MACRO  **********************

RD_EEPROM_LIT macro   addL, addH, eeprom_target
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

WR_EEPROM_LIT   macro   addL,   addH,  eeprom_data
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


RD_EEPROM macro   addL, addH, eeprom_target
;   addresses - literals, eeprom_target a register
;   read from specified EEPROM address and store at target
    movff   addL, WREG        ;load address into EEADR registers
    movwf   EEADR
    movff   addH, WREG
    movwf   EEADRH

    bcf     EECON1, EEPGD       ;clear the EEPGD, now operates on data memory
    bcf     EECON1, CFGS       ; Access EEPROM
    bsf     EECON1, RD       ; initiates read
    movff   EEDATA, eeprom_target       ;move data into target
    endm

WR_EEPROM   macro   addL,   addH,  eeprom_data
;   params all literals
;   write to a EEPROM location
    movff   addL, WREG        ;load address into EEADR registers
    movwf   EEADR
    movff   addH, WREG
    movwf   EEADRH
    movff   eeprom_data, WREG
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

