marker mcp3008.fs

\ To Read data from a MCP3008 connected to a RPI for Gforth through the Spi interface
\ Tested under Jessie

needs Common-extensions.f
needs unix/libc.fs
needs wiringPi.fs \ From: https://github.com/kristopherjohnson/wiringPi_gforth/blob/master/wiringPi.fs


1000000 constant spiSpeed             0 constant spiMcp3008 \ SpiChannel of the Mcp3008
8       constant #Channels         3.3e fconstant vRef      \ When vRef is connected to 3.3V
0       value    fdSpi            1023e fconstant #StepsAdc
8       constant CHAN_CONFIG_SINGLE   0 constant CHAN_CONFIG_DIFF

#StepsAdc 100e f/ fconstant (Adc%)

: spiSetup  ( spiChannel spiSpeed - fd ) wiringPiSPISetup dup ?ior ;
: initSpi     ( - )           spiMcp3008 spiSpeed spiSetup to fdSpi ;

: Adc@ ( spiChannel ADcChannel - RawData )
   upad off   1 upad c!   CHAN_CONFIG_SINGLE or 4 lshift upad 1+ c!
   upad 3 wiringPiSPIDataRW ?ior
   upad 1+ c@ 3 and 8 lshift   upad 2 + c@ or ;

: Adc% ( RawData - %OfTotal ) s>f (Adc%) f/ ;

: .Adc ( spiChannel - )
   #Channels 0  do  dup cr i . i Adc@ .  loop  drop ;

\\\ Eg:
0 value fdAdc
0 spiSpeed spiSetup to fdAdc

0 2 Adc@ cr cr . cr
0 .Adc abort

\\\ Output:

224

0 0
1 56
2 224
3 19
4 32
5 67
6 96
7 148
\\\

