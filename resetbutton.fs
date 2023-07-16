marker resetbutton.fs

\ When the reset button at GPIO 16 is pressed for more
\ than 300 ms the power will invert and there are 2 options.
\ 1) When the reset button is released within 1 second
\    then CPU-led will invert and the system will shutdown.
\ 2).When the reset button is NOT released within 1 second
\    then the power led will invert again and the system will reboot.

\ The button is connected between GPIO16 and GND

needs Common-extensions.f
needs gpio.fs

[undefined] Reset    [if]   cr .( Assigned GPio pins in resetbutton.fs )

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#    Name    Resistor         Input OR Output
 16 GpioPin: Reset    +PullUpResistor  dup AsActiveLow AsPinInput
 cr dup . .( Gpio pin[s] used.) to #pins        \ Lock table and save the actual number of used pins
 InitPins  .pins cr  .( Gpio table locked.) cr  \ Start and list the used GPio pins

 [then]

: Reboot/shutdown
   1000 ms  ReadPins Reset \State
     if   s" sudo reboot "         InvertCpuLed
     else s" sudo shutdown 0 -h "  InvertPowerLed
     then
   ShGet bye ;

: OnRestartButton
  begin  ReadPins Reset \State
         if  InvertPowerLed  Reboot/shutdown
         then
  300 ms again ;

: RebootCheck ( - ) ['] OnRestartButton execute-task drop ;

RebootCheck
\\\
