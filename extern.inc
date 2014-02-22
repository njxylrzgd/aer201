    extern Home, CLR_PORTS, CLR_LCD, WR_DATA, delay2second, delay1second
    extern log_menu, main_menu, operation, upload_msg, viewlog_msg, show_log
    extern operation, finito


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

store       macro   var_name,   val
            movlw   val
            movwf   var_name
            endm
