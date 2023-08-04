Marker gpio.fs   \ To control and administer GPio pins

needs Common-extensions.f
needs wiringPi.fs

17 value #pins

begin-structure /GpioPins
  lfield: >Switch
  lfield: >GpioPin#   \ Translation to the Pin number on the Raspberry Pi
  lfield: >Init       \ Initial state
  lfield: >ActiveHigh \ Active high means function is done when the input is in a high state.
  lfield: >Resistor
  lfield: >State      \ Current state after Readpins
  lfield: >pDevice    \ CFA of a constant that is connected on its pin
end-structure

0 value &pins

: r>Gpio      ( n - recordGpio ) /GpioPins * &pins + ;

: r>Switch     ( n - addr ) r>Gpio >Switch     ;
: r>GpioPin#   ( n - addr ) r>Gpio >GpioPin#   ;
: r>Init       ( n - addr ) r>Gpio >Init       ;
: r>ActiveHigh ( n - addr ) r>Gpio >ActiveHigh ;
: r>Resistor   ( n - addr ) r>Gpio >Resistor   ;
: r>State      ( n - addr ) r>Gpio >State      ;
: r>pDevice    ( n - addr ) r>Gpio >pDevice    ;
: r>IncPin     ( n - )      1 swap r>Init +! ;

: \Switch     ( n - val ) r>Switch     @ ;
: \GpioPin#   ( n - val ) r>GpioPin#   @ ;
: \Seen       ( n - val ) r>Init       @ ;
: \ActiveHigh ( n - val ) r>ActiveHigh @ ;
: \Resistor   ( n - val ) r>Resistor   @ ;
: \State      ( n - val ) r>State      @ ;
: \pDevice    ( n - cfa ) r>pDevice    @ ;

/GpioPins #pins * dup here swap allot  dup to &pins swap erase

: -- ( n flag - ) cr swap . . ." Inputs cannot be switched by Forth " ;

: DefaultForPins ( - )
   #pins 0
     do            i r>ActiveHigh on
          ['] --   i r>Switch !
          ['] noop i r>pDevice !
     loop ;

DefaultForPins

: InvertActiveLow ( flag n - flag' )
    \ActiveHigh 0=
      if  not   \  Invert when defined as active LOW.
      then ;

: ReadPin     ( n - )
     dup \GpioPin# digitalRead 0<> over InvertActiveLow
     2dup swap r>State !
          if   dup \seen 0=
                  if \ drop \  r>IncPin \
                    1 swap r>Init !
                  else drop
                  then
          else  drop
          then ;

: ReadPins ( - )
   #pins 0
     do   i ReadPin
     loop ;

: LogSwPin ( n flag - n flag )
  s" SwPin " upad place over (.) +upad
  space" +upad dup (.) +upad" +log ;

: SwPin ( n flag  - )
    dup
        if   over dup r>IncPin r>state on
        else over r>state off
        then
    over InvertActiveLow swap \GpioPin# swap
    abs digitalWrite ;

\ When a resistor has been set you may have to power down the Rpi before
\ the setting disapears.

PUD_OFF   constant NoResistor  \ Default.
PUD_DOWN  constant PullDownResistor
PUD_UP    constant PullUpResistor

: SetResistor          ( n Resistor - n ) over r>Resistor ! ;
: +NoResistor          ( n - n ) NoResistor          SetResistor ;
: +PullDownResistor    ( n - n ) PullDownResistor    SetResistor ;
: +PullUpResistor      ( n - n ) PullUpResistor      SetResistor ;
: -on                  ( n - )  true  over r>Switch perform ;
: -off                 ( n - )  false over r>Switch perform ;
: AsPinInput           ( n - )  ['] --    swap r>Switch ! ;
: AsPinOutput          ( n - )  ['] SwPin swap r>Switch ! ;
: AsActiveLow          ( n - )  r>ActiveHigh off ;
: AsActiveHigh         ( n - )  r>ActiveHigh on  ;
: AsActiveLowRelays    ( n - )  dup AsPinOutput AsActiveLow ;
: InitInput            ( n - )  \GpioPin# INPUT  pinMode ;
: InitOutput           ( n - )  \GpioPin# OUTPUT pinMode ;
: GpioPin!             ( GpioPin# n - ) r>GpioPin#  ! ;
: InitWiringPi         ( - ) wiringPiSetupGpio abort" wiringPiSetupGpio failed" ;

: GpioPin:  ( n GpioPin# - n+1 n ) \ Defines a new constant for a new device on a GpioPin.
   over #pins >=                   \ and create an entry in the device table.
      if   cr cr ." Error: #pins contains:" #pins . swap 1+ .
           ." used. #pins too small." abort
      then
   over constant
   last @ 2 pick  r>pDevice !
   over GpioPin! dup 1+ swap ;

: Output? ( n - flag ) \Switch ['] SwPin = ;

: ConfigureResistor ( pin n - )
   dup \GpioPin# swap \Resistor dup 0<> if pullUpDnControl else 2drop then ;

: ConfigurePins ( - ) \ Needs to be done in each new thread
   #pins 0
     do   i dup Output?
             if   InitOutput
             else dup ConfigureResistor InitInput
             then
     loop ;

: flag1/0  ( flag - 1|0 ) 0<> if 1 else 0 then ;
: .on/off  ( flag - )     flag1/0 . ;
: InitPins ( - )          InitWiringPi  ConfigurePins ReadPins ;

: pin-header ( - header$ cnt ) s"  id Switch Gpio Seen aHL R012 State Device " ;

: .pins ( - )
   cr pin-header type
   #pins 0
     do   i cr dup        3 u.r
          dup \Switch     space name>string tuck type 8 swap - 1 max spaces
          dup \GpioPin#   2 u.r
          dup \Seen       2 spaces (.) dup>r type 5 r> - 1 max spaces
          dup \ActiveHigh   space .on/off
          dup \Resistor   4 u.r
          dup \State      4 spaces .on/off
              \pDevice name>string 2 spaces type
     loop cr ;

: w-crlf    ( hndl - )            s" " rot  write-line throw ;
: fwrite    ( adr n hndl - )      write-file throw ;
: w-spaces  ( n hndl - )          >r spaces$ r>  fwrite ;
: w-on/off  ( flag hndl - adr n ) >r flag1/0 (.) r> fwrite ;

: w-pins    ( - )
   0 locals| hndl |
   s" devices.html" r/w create-file  abort" can't create device file" to hndl
   pin-header hndl fwrite
   #pins 0
     do   i hndl w-crlf dup    3 (u.r) hndl fwrite
          dup \Switch     1 hndl w-spaces name>string tuck hndl fwrite
                          8 swap - 1 max   hndl w-spaces
          dup \GpioPin#   2 (u.r) hndl fwrite
          dup \Seen       2 hndl w-spaces
                          (.) dup>r hndl fwrite 5 r> - 1 max
                          spaces$ hndl fwrite
          dup \ActiveHigh 1 hndl w-spaces hndl w-on/off
          dup \Resistor   5 (u.r) hndl fwrite
          dup \State      4 hndl w-spaces hndl w-on/off
              \pDevice name>string 3 hndl w-spaces hndl fwrite
     loop
   hndl close-file drop ;

\s EG:

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#    Name    Resistor         Input OR Output
   21 GpioPin: ForthLed  AsPinOutput
 cr dup . .( Gpio pin[s] used.) to #pins \ Lock table and save the actual number of used pins

 InitPins  .pins cr               \ Start and list the used GPio pins.

: ForthLedOff ( - )  ForthLed -off ;
: ForthLedOn  ( - )  ForthLed -on  ;

ForthLedOn .pins cr
cr .( Switching off the led.) cr 2000 ms
ForthLedOff .pins cr .( End demo.)



\s  A more extended example of a GPio table:
0 \ 1st device in the table.
\ GPIOpin#    Name       Input OR Output
\  1 GpioPin: Reserved1  AsPinInputOrOutput
\  2 GpioPin: N/A        For I2c SDA
\  3 GpioPin: N/A        For I2c SCL
\  4 GpioPin: Reserved4  AsPinInputOrOutput
\  5 GpioPin: Reserved5  AsPinInputOrOutput
   6 GpioPin: PirDoor   +PullDownResistor AsPinInput
\  7 GpioPin: N/A        For SPI0 CE1
\  8 GpioPin: N/A        For SPI0 CE0
\  9 GpioPin: N/A        For SPI0 MISO
\ 10 GpioPin: N/A        For SPI0 MOSI
\ 11 GpioPin: N/A        For SPI0 SCLK
\ 12 GpioPin: N/A        For PWM0
\ 13 GpioPin: N/A        For PWM1
\ 14 GpioPin: N/A        For UART TXD
\ 15 GpioPin: N/A        For UART RXD
\ 16 GpioPin: Reserved16 AsPinInputOrOutput
\ 17 GpioPin: N/A        For IrLed
\ 18 GpioPin: N/A        For IrSensor
\ 19 GpioPin: Reserved19 AsPinInputOrOutput
\ 20 GpioPin: Reserved20 AsPinInputOrOutput
  21 GpioPin: ForthLed   AsPinOutput
  22 GpioPin: PirRoom    AsPinInput
  23 GpioPin: TV         AsActiveLowRelays
  24 GpioPin: Amplifier  AsActiveLowRelays
\ 25 GpioPin: N/A        For Alt SDcard SD0 DAT1
\ 26 GpioPin: Reserved26 AsPinInputOrOutput
  27 GpioPin: UsbSensor  AsPinInput
 cr dup . .( #pins used.) to #pins \ Lock table and save the actual number of used pins
 .pins
\s
