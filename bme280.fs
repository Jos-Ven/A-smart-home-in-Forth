Marker bme280.fs       \ Ported from python.
require unix/libc.fs
require wiringPi.fs
require Common-extensions.f

\  To compensate for PCB temperature, sensor element self-heating and ambient temperature:
-2.0e fvalue ftemp-trim

\    I2C ADDRESS DEFINITIONS
\ sudo i2cdetect -y 1

0x76 constant BME280_I2C_ADDRESS1 0x77 constant BME280_I2C_ADDRESS2

\   POWER MODE DEFINITIONS
0x00 constant BME280_SLEEP_MODE   0x01 constant BME280_FORCED_MODE
0x03 constant BME280_NORMAL_MODE  0xB6 constant BME280_SOFT_RESET_CODE

0xD0 constant BME280_CHIP_ID_REG              \ Chip ID Register
0xE0 constant BME280_RST_REG                  \ Softreset Register
0xF3 constant BME280_STAT_REG                 \ Status Register
0xF4 constant BME280_CTRL_MEAS_REG            \ Ctrl Measure Register
0xF2 constant BME280_CTRL_HUMIDITY_REG        \ Ctrl Humidity Register

0xF5 constant  BME280_CONFIG_REG              \ Configuration Register

\ OVER SAMPLING DEFINITIONS
0x00 constant BME280_OVERSAMP_SKIPPED 0x01 constant BME280_OVERSAMP_1X
0x02 constant BME280_OVERSAMP_2X     0x03 constant BME280_OVERSAMP_4X
0x04 constant BME280_OVERSAMP_8X     0x05 constant BME280_OVERSAMP_16X

\  CALIBRATION REGISTER ADDRESS DEFINITIONS
0x88 constant BME280_TEMPERATURE_CALIB_DIG_T1_LSB_REG
0x89 constant BME280_TEMPERATURE_CALIB_DIG_T1_MSB_REG
0x8A constant BME280_TEMPERATURE_CALIB_DIG_T2_LSB_REG
0x8B constant BME280_TEMPERATURE_CALIB_DIG_T2_MSB_REG
0x8C constant BME280_TEMPERATURE_CALIB_DIG_T3_LSB_REG
0x8D constant BME280_TEMPERATURE_CALIB_DIG_T3_MSB_REG

0x8E constant BME280_PRESSURE_CALIB_DIG_P1_LSB_REG
0x8F constant BME280_PRESSURE_CALIB_DIG_P1_MSB_REG
0x90 constant BME280_PRESSURE_CALIB_DIG_P2_LSB_REG
0x91 constant BME280_PRESSURE_CALIB_DIG_P2_MSB_REG
0x92 constant BME280_PRESSURE_CALIB_DIG_P3_LSB_REG
0x93 constant BME280_PRESSURE_CALIB_DIG_P3_MSB_REG
0x94 constant BME280_PRESSURE_CALIB_DIG_P4_LSB_REG
0x95 constant BME280_PRESSURE_CALIB_DIG_P4_MSB_REG
0x96 constant BME280_PRESSURE_CALIB_DIG_P5_LSB_REG
0x97 constant BME280_PRESSURE_CALIB_DIG_P5_MSB_REG
0x98 constant BME280_PRESSURE_CALIB_DIG_P6_LSB_REG
0x99 constant BME280_PRESSURE_CALIB_DIG_P6_MSB_REG
0x9A constant BME280_PRESSURE_CALIB_DIG_P7_LSB_REG
0x9B constant BME280_PRESSURE_CALIB_DIG_P7_MSB_REG
0x9C constant BME280_PRESSURE_CALIB_DIG_P8_LSB_REG
0x9D constant BME280_PRESSURE_CALIB_DIG_P8_MSB_REG
0x9E constant BME280_PRESSURE_CALIB_DIG_P9_LSB_REG
0x9F constant BME280_PRESSURE_CALIB_DIG_P9_MSB_REG

0xA1 constant BME280_HUMIDITY_CALIB_DIG_H1_REG
0xE1 constant BME280_HUMIDITY_CALIB_DIG_H2_LSB_REG
0xE2 constant BME280_HUMIDITY_CALIB_DIG_H2_MSB_REG
0xE3 constant BME280_HUMIDITY_CALIB_DIG_H3_REG
0xE4 constant BME280_HUMIDITY_CALIB_DIG_H4_MSB_REG
0xE5 constant BME280_HUMIDITY_CALIB_DIG_H4_LSB_REG \ *
0xE6 constant BME280_HUMIDITY_CALIB_DIG_H5_MSB_REG
0xE5 constant BME280_HUMIDITY_CALIB_DIG_H5_LSB_REG \ *
0xE7 constant BME280_HUMIDITY_CALIB_DIG_H6_REG

\ FILTER DEFINITIONS
0x00 constant BME280_FILTER_COEFF_OFF
0x01 constant BME280_FILTER_COEFF_2
0x02 constant BME280_FILTER_COEFF_4
0x03 constant BME280_FILTER_COEFF_8
0x04 constant BME280_FILTER_COEFF_16

0 value bme280_i2c_address

: ?IorCodeBme280 ( result - result ior )
   dup  -1 =  if  dup  -512 errno - .error space else  0  then ;

: Set_Bme280_Address ( bme280_i2c_address - fd ior )
   dup wiringPiI2CSetup ?IorCodeBme280  rot to bme280_i2c_address ;

: SetupBme280 ( - fd )
   BME280_I2C_ADDRESS2           Set_Bme280_Address  ?IorCodeBme280 2drop
   dup BME280_CONFIG_REG                0            wiringPiI2CWriteReg8 ?IorCodeBme280 2drop
   dup BME280_CTRL_HUMIDITY_REG  BME280_FORCED_MODE  wiringPiI2CWriteReg8 ?IorCodeBme280 2drop ;

: ChipId@ ( fd - id ) BME280_CHIP_ID_REG wiringPiI2CReadReg8 ;
: .ChipId ( fd - )   ." ChipId: "  ChipId@ ?IorCodeBme280 drop h. ;

: DumpBme280  ( fd - )
  dup cr .ChipId  0xFF 0x88
    do   cr i h. dup i wiringPiI2CReadReg8 h.
    loop drop ;

: ReadBme280 { fd -- p_msb p_lsb p_xlsb   t_msb t_lsb t_xlsb   h_msb h_lsb }
  0xFF 0xF7  \ 0xF7...FE
    do    fd i wiringPiI2CReadReg8 loop ;

: >>  ( n1 #shifts - ) \ Python's way to perform a logical right shift
    >r dup 0<
       if    abs r> rshift negate
       else  r> rshift
       then ;

: ctrl_meas! ( fd Pressure_oversampling  Temperature_oversampling  mode - )
   >r 5 lshift swap 2 lshift or r> or
   BME280_CTRL_MEAS_REG swap wiringPiI2CWriteReg8 ?IorCodeBme280 2drop ;

\ Forced mode: Perform one measurement, to get results and return to sleep mode
: ForceBme280 ( fd - )
    BME280_OVERSAMP_4X BME280_OVERSAMP_4X BME280_FORCED_MODE  ctrl_meas! 200 ms ;

: 8lShiftOr ( b1 b2 - b1b2 ) 8 lshift or ;

: 20b>s ( msb lsb xlsb - n )
   rot 12 lshift  rot 4 lshift  or   swap 4 >>  or  ;

: signed-short ( s16bit - signed )
   dup 0x7fff >
    if  [ -1 0xffff xor ] literal or
    then ;

: signed-char  ( s8bit - signed )
   dup 0x7f >
    if   [ -1 0xff xor ] literal or
    then ;

: calib.u16 ( fd calib_Lsb_reg -  calib )
   2dup wiringPiI2CReadReg8 -rot 1+ wiringPiI2CReadReg8  8lShiftOr  ;

: calib.s16 ( fd calib_Lsb_reg - calib )   calib.u16 signed-short ;

: calib.H4 ( fd calib_Lsb_reg - calib )
    2dup  wiringPiI2CReadReg8
   -rot 1 - wiringPiI2CReadReg8
   signed-char 24 lshift 20 >>  or ;


: calib.H5 ( fd calib_Lsb_reg -  calib )
   2dup  1+ wiringPiI2CReadReg8 signed-char 24 lshift 20 >>
   -rot wiringPiI2CReadReg8 4 >> 0xf and  or ;

0   value dig_t1   0   value dig_t2   0   value dig_t3
0e fvalue dig_h1   0e fvalue dig_h2   0e fvalue dig_h3
0e fvalue dig_h4   0e fvalue dig_h5   0e fvalue dig_h6
0e fvalue dig_P1   0e fvalue dig_P2   0e fvalue dig_P3
0e fvalue dig_P4   0e fvalue dig_P5   0e fvalue dig_P6
0e fvalue dig_P7   0e fvalue dig_P8   0e fvalue dig_P9

: digT ( fd - )
   dup BME280_TEMPERATURE_CALIB_DIG_T1_LSB_REG calib.u16 to dig_t1
   dup BME280_TEMPERATURE_CALIB_DIG_T2_LSB_REG calib.s16 to dig_t2
       BME280_TEMPERATURE_CALIB_DIG_T3_LSB_REG calib.s16 to dig_t3 ;

: digH ( fd - )
   dup BME280_HUMIDITY_CALIB_DIG_H1_REG     wiringPiI2CReadReg8 s>f to dig_h1  \ unsigned char
   dup BME280_HUMIDITY_CALIB_DIG_H2_LSB_REG calib.s16           s>f to dig_h2  \ signed short
   dup BME280_HUMIDITY_CALIB_DIG_H3_REG     wiringPiI2CReadReg8 s>f to dig_h3  \ unsigned char
   dup BME280_HUMIDITY_CALIB_DIG_H4_LSB_REG calib.H4            s>f to dig_h4  \ signed short
   dup BME280_HUMIDITY_CALIB_DIG_H5_LSB_REG calib.H5            s>f to dig_h5  \ signed short
       BME280_HUMIDITY_CALIB_DIG_H6_REG     wiringPiI2CReadReg8 signed-char s>f to dig_h6 ; \ signed char

: digP ( fd - )
   dup BME280_PRESSURE_CALIB_DIG_P1_LSB_REG calib.u16 s>f to dig_P1
   dup BME280_PRESSURE_CALIB_DIG_P2_LSB_REG calib.s16 s>f to dig_P2
   dup BME280_PRESSURE_CALIB_DIG_P3_LSB_REG calib.s16 s>f to dig_P3
   dup BME280_PRESSURE_CALIB_DIG_P4_LSB_REG calib.s16 s>f to dig_P4
   dup BME280_PRESSURE_CALIB_DIG_P5_LSB_REG calib.s16 s>f to dig_P5
   dup BME280_PRESSURE_CALIB_DIG_P6_LSB_REG calib.s16 s>f to dig_P6
   dup BME280_PRESSURE_CALIB_DIG_P7_LSB_REG calib.s16 s>f to dig_P7
   dup BME280_PRESSURE_CALIB_DIG_P8_LSB_REG calib.s16 s>f to dig_P8
       BME280_PRESSURE_CALIB_DIG_P9_LSB_REG calib.s16 s>f to dig_P9 ;

: ReadCalibrations ( fd - )  dup digT dup digH digP ;

0e fvalue var1      0e fvalue var2
0  value t_fine     0e fvalue humidity  0e fvalue pressure

\ The BME280 raw output consists of the ADC output values.

: dig_h*fact ( f: dig_h - 1.0 dig_h*fact )  1.0e fswap 6.7108864e7 f/ humidity f* ;


: raw_hum>f   ( hum_msb  hum_lsb  - ) ( f: - hum )
   swap 8lShiftOr  s>f
   dig_h4  64.0e f* dig_h5  16384.8e f/
   t_fine  s>f  76800e  f- fdup to humidity f* f+ f-
   dig_h2 65536.0e f/
   dig_h6 dig_h*fact
   dig_h3 dig_h*fact  f+ f* f+ f* f*
   1.0e dig_h1 2 fpick f*  524288.0e  f/ f- f*
   976e-3 f*      \  otherwise the result will be too high.
   0e fmax 100e fmin  fdup to humidity ;

: bNegate ( bx - -bx ) 128 - 0xff and ;

: corr<0   ( temp_msb temp_lsb temp_xlsb - Stemp_msb Stemp_lsb temp_xlsb flag )
   >r 2dup swap 8 lshift or 0x70C0 <  r> swap ;

: raw_temp>f  ( temp_msb  temp_lsb  temp_xlsb - ) ( f: - temp )
   corr<0 >r 20b>s r>
      if  -1
      else 1
      then >r
   dup  3 >>    dig_T1 1 lshift -       dig_T2 *   11 >> >r
   4 >>    dig_T1 -   dup  * 12 >>      dig_T3 *   14 >>
   r>  + dup to t_fine 5 * 128 + 8 >>  r> * s>f 100e f/ ftemp-trim f+ ;

: raw_pressure>f   ( press_msb press_lsb press_xlsb - ) ( f: - pres ) \ Not optimized
   20b>s  t_fine s>f 2.0e f/ 64000.0e f-     to var1
   var1 var1 f* dig_p6 f*  32768.0e f/       to var2
   var2 var1 dig_p5  f* 2.0e f* f+           to var2
    var2 4.0e f/ dig_p4 65536.0e  f* f+      to var2
   dig_p3 var1 f* var1 f* 524288.0e  f/ dig_p2  var1 f* f+  524288.0e  f/ to var1
   1.0e var1 32768.0e f/  f+ dig_p1 f* fdup  to var1 f0<
     if    drop 0e
     else  1048576.0e s>f f-
           var2 4096.0e  f/ f- 6250.0e f* var1 f/
           fdup fdup f* dig_p9 f* \ 4.39442E13
           2147483648.0e f/ to var1
           fdup dig_p8 f* 32768.0e f/  to var2
           var1 var2 f+ dig_p7 f+  16.0e f/ f+
           100e f/
     then ;

: Bme280>f   ( fd-Bme280 - ) ( f: - Humidity Temperature Pressure )
   dup 0<>
     if   dup ForceBme280  ReadBme280
          2>r raw_temp>f 2r> raw_hum>f fswap  raw_Pressure>f
     else drop 0e 0e 0e
     then ;

: InitBme280 ( - fd-Bme280 ) SetupBme280  dup ReadCalibrations ;

: 2f.        ( F: n - ) 7 2 0 f.rdp space ;

: .bme280    ( fd-Bme280 - )
   Bme280>f fswap
   4 set-precision  cr ." Temperature : " 2f. ." C"
   6 set-precision  cr ."    Pressure : " 2f. ." hPa"
   4 set-precision  cr ."    Humidity : " 2f. ." %" ;



 0 value fdBme280

CheckI2c
     [IF]    cr cr .( Bme280: )
             InitBme280 dup to fdBme280  ChipId@ 0>
             [IF]   bme280_i2c_address
                    cr .(   I2c addres: ) h. 2 spaces
                    fdBme280  .ChipId fdBme280 .bme280
             [ELSE] cr .( No Bme280 sensor detected!)
             [THEN]
     [ELSE]  cr cr .( The I2c interface is NOT activated!) cr
     [THEN]

\ 111 135 128 dbg raw_temp>f abort

\\\ Output:

  I2c addres: 77   ChipId: 60
Temperature :   25.68 C
   Pressure : 1018.14 hPa
   Humidity :   49.25 %

\\\
