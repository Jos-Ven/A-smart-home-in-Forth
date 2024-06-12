marker job_support.fs .latest   \ To exexute tasks in the background

[DEFINED] PushBme280Data       [IF]

needs bme280-logger.fs

create &Bme280Data 200 allot

2 constant Bme280DataReceiver \ Server that needs the Bme280Data

: ReadFile+lPlace { fd len dest -- flag }
   dest dup @ + len fd read-file
     if    drop
     else  len =
            if   len dest +! true exit
            then
     then
   false ;

: AddLastKnownBme280Record ( dest - flag )
  yearToday (.) utmp$ place  extension$ count +utmp$
  utmp" r/w bin open-file
    if    2drop false
    else  tuck dup dup file-size
            if    3drop 2drop false
            else  /bme280Record 2* cell +  \ 2* to be sure not to get a last empty record
                  s>d d- rot reposition-file
                    if    2drop false
                    else  /bme280Record rot ReadFile+lPlace
                    then
            then  swap CloseFile
    then ;

: +Bme280Int ( str cnt letter - )
    bl sp@ 1 &Bme280Data +place drop
       sp@ 1 &Bme280Data +place drop
    &Bme280Data +place ;

: +Bme280F ( f: f - ) ( char - ) 1000e f* f>s (.) rot +Bme280Int ;

: SendBme280Data  (  Server# -- )
   UdpOut$ dup off AddLastKnownBme280Record
     if  s" Gforth::Bme280Data"  &Bme280Data place  UdpOut$ cell+
         dup >Date        @  (.)   [char] D +Bme280Int
         dup >Time        @  (.)   [char] T +Bme280Int
         dup >Pressure    f@ [char] P +Bme280F
         dup >Temperature f@ [char] C +Bme280F
         dup >Humidity    f@ [char] H +Bme280F
         dup >Pollution   f@ [char] U +Bme280F
             >Light       f@ [char] L +Bme280F
         &Bme280Data count rot SendUdp$
     else  drop
     then ;

[THEN]

[DEFINED] SendingState [IF]

create Floor-data 80 allot

: +char>floor-data ( char - ) sp@ 1 Floor-data +lplace drop ;

: +floor-data      ( letter n -- )
  swap   +char>floor-data
  (.)    Floor-data +lplace
  bl     +char>floor-data ;

coded char - negate + dup    value Prev-Temperature   value Prev-Humidity

  12 constant MsgBoard                 \ Server number of the MsgBoard
2.0e fvalue   HumidityDecreaseLim      \ Humidity (%)
  10 value    HumidityDecreaseTimeSpan \ Minimal 1 minute
  10 value    HumidityIncreaseTimeSpan \ Minimal 15 minutes


: f@100*>s ( adr - n )    f@ 100e f* f>s ;
: temp100* ( - temp100* ) &bme280Record >Temperature f@100*>s ;
: hum100*  ( - hum100* )  &bme280Record >Humidity    f@100*>s ;

: sent-temp-hum-to-msgboard  ( - )
     [DEFINED] FloordataToMsgBoard
            [IF]  s" -2130706452 F0 T:" tmp$ place
                  hum100* 10 / temp100* 10 / word-join (.)  tmp$ +place
                  tmp$ count MsgBoard SendUdp$
            [THEN] ;

:  Send-Floor ( - )
     Floor-data off
         s" /Floor " Floor-data lplace
         [char] F 0 +floor-data
         [char] T temp100* +floor-data
         [char] H hum100*  +floor-data
         [char] 1 -4175 +floor-data  \ NA
         [char] 2 -4175 +floor-data  \ NA
         Floor-data lcount AdminServer SendUdp$  \ All floor data go to the AdminServer
  ;

: Toobig? ( n1 n2 - f )  - abs 10 > ;

HumidityDecreaseTimeSpan HumidityIncreaseTimeSpan 1 + max constant #minmalFiledRecs


: send-data-humidity ( f:HumDif - )
\   sent-temp-hum-to-msgboard
    s" Gforth::HumIncrease _" Floor-data lplace
    10e f* fround f>s (.)  Floor-data +lplace Floor-data lcount AdminServer SendUdp$  ;


: HumUpDown? ( vLengthFile - flag )  ( -  f:HumDif )
   /bme280Record /                          \ #records
   1- dup  r>Humidity f@                   \ Get latest Humidity
    HumidityDecreaseTimeSpan -  r>Humidity f@ f-  \ dif decr
   fdup  HumidityDecreaseLim  f<            \ Down? or less than HumidityDecreaseLim
   0e fmax ;

: send-humidity-increase ( - UpDown )
   yearToday SetFilename MapBme280Data dup #minmalFiledRecs >
      if    dup HumUpDown? dup
               if    fdrop
               else  10e f* fround send-data-humidity
               then
      then -rot
   UnMapBme280Data ;


: Send-floor-data ( - )    Send-Floor send-humidity-increase drop  ;

[then]



: SendFloorDataRequests  ( - )
   AdminServer ServerHost =
    if    s" /I0"  0 SendUdp$   \  To be adapted for your network
          s" /I0"  2 SendUdp$
          s" /I0"  3 SendUdp$
          s" /I0" 13 SendUdp$
          s" /I0" 14 SendUdp$
    then  ;


 [DEFINED] WarningLight [IF]

: LowLevelPressureWarning      ( - )
   PressureSamples  AverageSamples 1007e f<  \ Give a warning when the presure gets below 1007 Hpa
            if    s" /w10" 11 SendTcp drop       \ The 11th server is an ESP8266F
            then ;
[THEN]

: SendLowLightLevel   ( - )
     [DEFINED]  ControlLights   [IF]  lights-on/off        [THEN]
     [DEFINED]  ControlWindow   [IF]  open/close-window    [THEN]  ;

\ Jobs

0 value #MinuteJobs   0 value TidEachMinuteJob

: Each10MinuteJob ( - )
   [DEFINED] PushBme280Data       [IF]  Bme280DataReceiver SendBme280Data  [THEN]
   [DEFINED] FloordataToMsgBoard  [IF]  0e send-data-humidity sent-temp-hum-to-msgboard Send-Floor  [THEN]  ;

: EachMinuteJob ( - )
   60000 ms
   [DEFINED] SendingState   [IF] Send-Floor 0e  send-data-humidity sent-temp-hum-to-msgboard [THEN]
     begin    web-server-sock
     while    #MinuteJobs 10 /mod drop 0=  if    Each10MinuteJob    then
              [DEFINED] WarningLight       [IF]  LowLevelPressureWarning  [THEN]
              [DEFINED] ControlLights      [IF]  SendLowLightLevel        [THEN]
              [DEFINED] SendingState       [IF]  send-humidity-increase   [THEN]
              WaitTillNextMinute
   repeat ;


cr .( Starting the support jobs. )  \ Receiving servers should be adapted

' EachMinuteJob   execute-task to TidEachMinuteJob

: (KillTasks ( - )
    TidEachMinuteJob       kill
    [DEFINED] CentralHeating      [IF] TidJobNightService       kill [THEN] ;

' (KillTasks is KillTasks


TCP/IP DEFINITIONS

: Gforth::Standby     ( parm from - )  s" OnStandby" +log  drop  to (standby) standby-chain chainperform  ;

[DEFINED] SendingState [IF]

: /I0   ( - ) Send-floor-data ;
: /IM   ( - ) sent-temp-hum-to-msgboard ;

[THEN]

[DEFINED] OnFloor [IF]
: /floor ( <FN> - )
    udpin$ lcount parse-name s" W0" compare
      if     OnFloor
      else   OnWindow0
      then
    Ignore-remainder ;
[THEN]

[DEFINED] PushBme280Data  [IF]

: Gforth_Bme280Data  ( - )
    udpin$ lcount  FindSender
      if    SendBme280Data
      else  drop
      then
    Ignore-remainder ;

[THEN]

FORTH DEFINITIONS

