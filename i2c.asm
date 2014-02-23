    #include <p18f4620.inc>

temp_i2c_1  EQU       0x43           ; buffer for Instruction
temp_i2c_2  EQU       0x44

;****************MACRO ************************************************
store    macro   var_name,   val
         movlw   val
         movwf   var_name
         endm



    code

    global INIT_I2C, SET_RTC_VAL, INIT_READ
    global  read_RTC_Nack, read_RTC_ack

;****************** global subroutines *********************************

INIT_I2C
    store   SSPCON1, B'00101000'    ; enable MSSP mode, set to I2C master mode
    store   SSPSTAT, B'10000000'    ; disable slew rate control for 100kHz
    store   SSPADD, D'24'           ; F_osc/(4*(SSPADD+1))

    call    initiate            ; enable start
    movlw   0xD0                    ; slave address
    call    write
    movlw   0x07                    ; RTC register address
    call    write
    movlw   0x90                    ; set square wave output
    call    write                ; refer DS1307 datasheet
    call    stop

    return

SET_RTC_VAL
    store temp_i2c_1, 0x06      ;set year, address then data
    store temp_i2c_2, 0x14
    call write_temps
    store temp_i2c_1, 0x05      ;set month, address then data
    store temp_i2c_2, 0x02
    call write_temps
    store temp_i2c_1, 0x04      ;set date, address then data
    store temp_i2c_2, 0x23
    call write_temps
    store temp_i2c_1, 0x03      ;set day, address then data
    store temp_i2c_2, 0x01
    call write_temps
    store temp_i2c_1, 0x02      ;set hour, address then data
    store temp_i2c_2, 0x01
    call write_temps
    store temp_i2c_1, 0x01      ;set minutes, address then data
    store temp_i2c_2, 0x02
    call write_temps
    store temp_i2c_1, 0x00      ;set second
    store temp_i2c_2, 0x00
    call write_temps
    return

INIT_READ
    call    initiate
    movlw   0xD0                    ; RTC slave addr | write
    call    write
    movlw   0x00                    ; points to register 0x00
    call    write
    call    stop

    call    initiate
    movlw   0xD1                    ; RTC slave addr | read
    call    write
    return
;************** helpers ****************************
wait
    btfss   PIR1,SSPIF              ; wait for SSPIF = 1
    bra wait                        ;changed from goto $-2 ******************
    bcf     PIR1,SSPIF              ; clear SSPIF in software
    return

initiate
    bsf     SSPCON2,SEN             ; enable start
    call    wait
    return

stop
    bsf     SSPCON2,PEN             ; enable stop
    call    wait
    return

write
    movwf   SSPBUF
    call    wait
    return

write_temps
;input: temp1(address), temp2 (data)
;writes data to the designated location
    call    initiate
    movlw   0xD0                    ; slave address
    call    write
    movf    temp_i2c_1, WREG    ; points to RTC register address
    call    write
    movf    temp_i2c_2, WREG
    call    stop
    return

ack
    bcf     SSPCON2, ACKDT          ; acknowledge receiving
    bsf     SSPCON2, ACKEN
    call    wait
    return

nack
    bsf     SSPCON2, ACKDT          ; not acknowledge receiving
    bsf     SSPCON2, ACKEN
    call    wait
    return

read_RTC_ack
    btfsc   SSPSTAT, 2              ; check if address needs to be updated
    bra     read_RTC_ack
    bsf     SSPCON2, RCEN           ; enable receive
    call    wait
    bcf     PIR1, SSPIF             ; clear interrupt flag
    call    ack                     ; send ACK bit to keep reading
    movf    SSPBUF, W               ; move data from buffer to W register
    return

read_RTC_Nack
    btfsc   SSPSTAT, 2              ; check if address needs to be updated
    bra     read_RTC_ack
    bsf     SSPCON2, RCEN           ; enable receive
    call    wait
    bcf     PIR1, SSPIF             ; clear interrupt flag
    call    nack                     ; send ACK bit to keep reading
    movf    SSPBUF, W               ; move data from buffer to W register
    return

END