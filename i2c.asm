	#include <p16f877.inc>

    code

    global INIT_I2C

INIT_I2C
    store   SSPCON1, B'00101000'    ; enable MSSP mode, set to I2C master mode
    store   SSPSTAT, B'10000000'    ; disable slew rate control for 100kHz
    store   SSPADD, D'24'           ; F_osc/(4*(SSPADD+1))

    bsf     SSPCON2,SEN             ; enable start
    


END