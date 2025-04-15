needs multiport_gate.f
marker CentralHeating.fs .latest

0 [if]
14-04-2025    Now the Forth takes the warming up by the sun in account before switching
              the central system on. To update the input:
              1. Set the time with the button SetTimespan on page: Central heating
              2. Set Start / End on the history page in part: Settings with the button Range
              3. Hit the button ColdTrend on the page Central heating.
              Delete file TempChar.dat to disable this feature.
[then]
\ -------------- Settings ---------------------------

cr .( Assigned GPio pins )

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#    Name     Resistor         Input OR Output
 16 GpioPin:  Reset    +PullUpResistor  dup AsActiveLow AsPinInput
 24 GpioPin:  chNight  AsPinOutput       \ Connected to the night mode input of a thermostat through a relais.

 cr dup . .( Gpio pin[s] used.) to #pins \ Lock table and save the actual number of used pins
    InitPins  .pins                      \ Start and list the used GPio pins.


\ -------------- Settings ---------------------------
\ Mapped in Config.dat
ConfigVariable StartTimeOutTempLimit
ConfigVariable EndTimeOutTempLimit
ConfigVariable GrabDate
EnableConfigFile

StartTimeOutTempLimit @ EndTimeOutTempLimit @ + 0=
  [IF]  \ Initial between 11:30 and 23:59
        1130 StartTimeOutTempLimit !
        2359 EndTimeOutTempLimit !
  [THEN]

0 value #Jobs
: .y|n            ( flag - )  if  +HTML| Y| else +HTML| N| then ;

: GetStartParams ( f: - @time  StartTimeOutTempLimitTics)
    @time LocalTics-from-UtcTics StartTimeOutTempLimit @ UtcTics-from-hm  ;

: OpeningHours-   ( - flag ) \ For nightmode
   GetStartParams  EndTimeOutTempLimit @ UtcTics-from-hm fbetween ;


\ -------------- Multi port gates -------------------

2variable ch-autom-mp
0 ch-autom-mp bInput: i_ch_TimeSpan  \ 0 OpeningHours-
              bInput: i_ch_ColdTrend \ 1 The sun does not heatup
              bInput: i_ch_Present   \ 2 inverted StandBy-
              bInput: i_ch_Automatic \ 3 inverted i_ch_Manual bInput@
>#bInputs c!                   \ 3

2variable ch-gui-mp
0 ch-gui-mp bInput: i_ch_Mode        \ 0 Active when the central heating is set to the nightmode
            bInput: i_ch_Sleep       \ 1 Active: Freezes until the next day
            bInput: i_ch_Manual      \ 2 Active for manual control
>#bInputs c!                   \ 3

2variable ch-out-mp
0 ch-out-mp bInput: i_ch_autom       \ 0 Output from the result of ch-autom-mp
            bInput: i_ch_gui         \ 1 Output from the result of ch-gui-mp
>#bInputs c!                         \ 2 The result will control the ventral heating


\ -------------- Sun heating --------------

\ TempChar
begin-structure /TempChar
   field: >TcTime          \ Time to measure
  xfield: >TcTemperature   \ Measured temperature
  xfield: >TcMinimal       \ Minimal predicted
end-structure

0 value &TempChar          5 constant #TempCharRecords

: &TempChar-Size  ( -  &TempChar Size ) &TempChar #TempCharRecords /TempChar * ;
: >TempChar       ( n - adr )           /TempChar * &TempChar + ;

here &TempChar-Size allot drop to &TempChar

: >NeedsTempChar! ( time-mmhh n - ) ( f: TcMinimal - )
     >TempChar tuck  >TcTime !  >TcMinimal f! ;

: .TempChars ( - )
   &TempChar-Size bounds
      do  cr i dup .
            dup >TcTime  @ .
            dup >TcTemperature f@ f.
                >TcMinimal     f@ f. /TempChar
      +loop ;

: grabrec# (  vadr count -  vadr count record# ) ( f: localtics - )
   Time&DateLocal-from-UtcTics
   3drop 100 * + 100 * nip GrabDate @ here 2!
   here findDateTarget ;

1800e fconstant 30minutes

: SaveGrabbedRecord ( >TempChar record# - )
   >r dup >TcTime  r@ r>TimeBme280 @ 100 / swap !
   r> r>Temperature f@ fdup
   dup >TcTemperature f!
   dup &TempChar <>
     if   fdup dup /TempChar - >TcTemperature f@ f/ f*
     then
   >TcMinimal f! ;

: ClrTcTemperature ( - )
    &TempChar-Size bounds
       do   0e0 i >TcTemperature f!   /TempChar +loop ;

create TempCharFile ," TempChar.dat"

: WriteGrabbed ( - ) &TempChar-Size TempCharFile count file-it ;
: ReadGrabbed  ( - ) &TempChar-Size TempCharFile count @file drop ;

TempCharFile count file-exist?
  [if]   ReadGrabbed
  [else] 0 GrabDate !
 1100 67.18e0 0 >NeedsTempChar!  \ Forcing the ColdTrend to Y, so it will not block the central heating
 1130 68.0495365729766e0 1 >NeedsTempChar!
 1200 68.5511265447632e0 2 >NeedsTempChar!
 1230 69.2051284177007e0 3 >NeedsTempChar!
 1300 69.4829664224991e0 4 >NeedsTempChar!
  [then]

: grabchars ( - )
   MapBme280Data
   0 StartTimeOutTempLimit @       \ Uses StartTimeOutTempLimit from page: central heating  part: start time
   100 /mod
   Startdate 2@ nip dup GrabDate ! \ Uses Startdate from the history page in part: settings button range
   100 /mod 100 /mod               \  -  ss mm uu dd mm yearLocal
   UtcTics-from-Time&Date fdup UtcOffset f- 30minutes f- \ Must start 30 minutes earlier
   #TempCharRecords 0
      do  fdup i s>f  30minutes f*  f+  grabrec#  i >TempChar swap  SaveGrabbedRecord
      loop
   UnMapBme280Data  fdrop .TempChars cr ClrTcTemperature WriteGrabbed ;

: TooCold? ( >TempChar - flagCold )
   dup >TcTemperature f@
   dup &TempChar =
    if    false i_ch_ColdTrend bInput!
          >TcMinimal f@ f<
    else  dup  /TempChar - >TcTemperature f@
          fover fswap
          f/ f*  >TcMinimal f@ f<
    then ;

: TCmeasure! ( >TempChar - flagCold ) ( f: TcTemp - )
    dup >TcTemperature f! TooCold? ;

: MonitorTrend1Day ( - )
    ClrTcTemperature true i_ch_ColdTrend bInput!    &TempChar-Size bounds
      do    i >TcTime @ WaitUntil
            fdBme280  Bme280>f fdrop fnip i TCmeasure!
            i &TempChar <> and
                if leave then
            /TempChar
      +loop   log" Exit." ;

0 value TidMonitorTrendJob

: MonitorTrendJob ( - )
   .time .TempChars cr
   make-task dup to  TidMonitorTrendJob activate
   begin  MonitorTrend1Day again ;


\ -------------- Relations between the multi port gates ---

: set-ch-override ( - )
   i_ch_Manual bInput@  0=  i_ch_Automatic bInput! ;

: eval_gui ( - )
   i_ch_Sleep  bInput@  i_ch_Manual bInput@ or
      if   i_ch_Mode  bInput@
      else 0
      then i_ch_gui   bInput! ;


: reset-sleep-ch   ( - )   i_ch_Sleep bInputOff ;
 ' reset-sleep-ch  reset-sleep-chain chained

: eval-ch-net ( - output-ch-net ) \ Updates all relations and evaluate the network.
   set-ch-override \ add_inputs            \ Flag Output  To destination
   eval_gui
   [ ch-autom-mp all-bits ] literal ch-autom-mp match-mp  i_ch_autom bInput!
   ch-out-mp any-mp ;

: .eval-ch-net   ( - )
   eval-ch-net drop               \ Update all relations and evaluate the network.
   cr .line-- space .time         \ Output for each mp:
   cr ." Automation " [ ch-autom-mp all-bits ] literal ch-autom-mp .match-mp
   cr ." Gui "  ch-gui-mp .inputs-mp cr
   cr ." Out "  ch-out-mp .any-mp ;

: init-ch-net ( - )
   3 ch-autom-mp >threshold c!
   3 ch-gui-mp   >threshold c!
   1 ch-out-mp   >threshold c!
   0 ch-autom-mp !   0 ch-gui-mp !   0 ch-out-mp ! eval-ch-net drop
   i_ch_Manual bInputOn MonitorTrendJob ;

init-ch-net

0 [if] \ Simulation
    i_ch_TimeSpan   bInputOn
    i_ch_Present    bInputOn
    i_ch_Automatic  bInputOn
    i_ch_Sleep bInputOn  .eval-ch-net
 quit

    i_ch_Automatic  bInputOff  .eval-ch-net  \ Ignore the job
    i_ch_Sleep      bInputOn   i_ch_Mode bInputOn  .eval-ch-net
    i_ch_Mode       bInputOff  .eval-ch-net

    i_ch_Automatic  bInputOn  .eval-ch-net  \ Use the job
  eval-ch-net .

abort
[then]


: i_ch_Automatic@ ( - value ) i_ch_Automatic bInput@ ;

\ -------------- Html page --------------------------

ALSO HTML

: .helpch ( - )
  +HTML| <font size="2">|
   Comment" +HTML <br>
   i_ch_Automatic@
      if    +HTML| Between | StartTimeOutTempLimit @ .html
            +HTML|  and | EndTimeOutTempLimit @ .html
            +HTML|  the thermostat will execute its schedule.|
            <br> +HTML| When no one is at home the thermostat should be in night mode.|
      else  chNight \State
                if     +HTML| The night mode is permanent.|
                else   +HTML| The thermostat runs the central heating.|
                then
      then
   </font> ;

: +Nightmode ( -)    chNight \State  flag1/0  if +HTML| On|  else  +HTML| Off|  then ;

: .Statisticsch ( - )  \ >.1
     <tdLTop> <fieldset>
              <legend> <aHREF" +homelink  +HTML| /ch%20menu">| +HTML| Statistics | </a> </legend>
     </form> <form>
     100 230 0 4 1 <tablepx>   ( wPx hPx cellspacing padding border -- )
         <tr><td>  HTML| Item|  <<strong>> </td>
             <td>  HTML| Flag|  <<strong>> </td>
             <td>  HTML| Start| <<strong>> </td>
             <td>  HTML| End|   <<strong>> </td></tr>
         <tr><tdL>  ButtonWhite black s" SetTimespan"   nn"  <StyledButton> \ 1 ...
         <td>  OpeningHours- i_ch_Automatic@  and .y|n </td>
         </td><td>    s" tStart" StartTimeOutTempLimit @  <InputTime> </td>
         </td><td>    s" tEnd"   EndTimeOutTempLimit @    <InputTime> </td>
    <tr><tdL>  </form> <form> ButtonWhite black s" ColdTrend"    nn"  <StyledButton> </form> <form>  </td><td>
      i_ch_ColdTrend bInput@ .y|n  </td>  2 <#tdL>

<aHREF" +homelink  +HTML| /home">| +HTML| Date&nbsp;setting:| GrabDate @ .Html </a>
\ +HTML| From: | GrabDate @ .Html
</td></tr>
         <tr><tdL> +HTML| Present: |   </td><td>
                   i_ch_Present bInput@ .y|n  </td>  2 <#tdL> </td></tr>
         <tr> 4 <#tdL>   HTML| State: |  <<strong>>
                <br> +HTML| The night mode is | +Nightmode +HTML| .|
                <br> +HTML| The job | i_ch_Manual bInput@ 0=
                          if    +HTML| runs. Entry count:| #Jobs .Html
                          else  +HTML| has been stopped. |
                          then
                i_ch_Sleep bInput@
                          if <br> +HTML| Sleeping schedule active. |
                          then
          </td></tr>
          </table> </form> <form> </fieldset> </td> ;

: (+.Nightmode)  ( - )
       +HTML| Nightmode:|   +Nightmode
       <br>   i_ch_Sleep  bInput@
              if    +HTML| Sleeping |
              else  i_ch_Manual  bInput@
                    if   +HTML| Manual |
                    else +HTML| Automatic |
                   then
              then ;

: OnOffColors ( - ColorButton ColorText )
   if ltBlue  else ButtonWhite  then black ;

: .ControllButtons ( - ) \ >.2
   <tdLTop> <fieldset> s" Schedule thermostat" <<legend>>
          100 230 14 0 0 <tablepx>   ( wPx hPx cellspacing padding border -- )
          <tr><tdL>  ch-out-mp any-mp dup 0=
                     OnOffColors s" Night mode"  nn" <StyledButton>
              </td> <tdL> i_ch_Manual bInput@ 0= i_ch_Sleep bInput@ 0= and
                          OnOffColors s" Job"   nn" <StyledButton> </td></tr>

          <tr><tdL> ( ch-out-mp fire ) OnOffColors s" Thermostat"   nn" <StyledButton>
              </td> <tdL>  i_ch_Sleep bInput@
                          OnOffColors s" Sleep "   nn" <StyledButton>  </td></tr>
          <tr><tdL> .HtmlSpace </td></tr>
      </table> </fieldset> </td> ;

: chMenu ( - ) \  Central heating options
    s" Central heating" NearWhite 0 <HtmlLayout>
       <tr> .Statisticsch  .ControllButtons  </tr>
       <tr> 2 <#tdL> .helpch </td> </tr>
    <EndHtmlLayout> ;

: set-ch ( flag - )
   if   chNight -Off
   else chNight -On
   then ;

: Run/StopJob ( - )
   i_ch_Present bInputon
   i_ch_Manual  bInput@ 0= i_ch_Manual bInput!
    eval-ch-net set-ch ;

: set-Nightmode ( i_ch_Mode - )
    i_ch_Mode      bInput!
    i_ch_Manual bInputOn
    eval-ch-net  dup set-ch  ch-out-mp >last-out c! ;

: Standby-central-heating ( - )
     (standby) not dup
      if    log" Standby cancelled" \ When you are getting at home.
      else  log" Starting standby"  \ When you are going away.
      then  i_ch_Present bInput!  eval-ch-net set-ch ;

' Standby-central-heating standby-chain chained

: SwitchNightservice ( flag - )
   dup ch-out-mp  >last-out c@ 0<> <>
    if  dup ch-out-mp >last-out c! dup set-ch
          if    log" Night mode off"
          else  log" Night mode on"
          then
    else drop
    then ;

: ConditionsNightMode ( - )
   i_ch_Automatic@
     if  1 +to #Jobs
          OpeningHours- i_ch_TimeSpan bInput!
          eval-ch-net SwitchNightservice
     then ;

: JobNightService  ( - )
   spawn-task  60000 ms
     begin   web-server-sock
     while   ConditionsNightMode   WaitTillNextMinute
     repeat
   cr  .date space .time ."  Bye JobNightService" (bye  ;

   i_ch_Mode bInputOff   i_ch_Manual bInputOn 0 SwitchNightservice

JobNightService

\ -------------- Incomming through tcp --------------

ALSO TCP/IP DEFINITIONS \ Adding the page and it's actions to the tcp/ip dictionary

: /ch%20menu  ( - ) ['] chMenu set-page  ;
: Job         ( - ) Run/StopJob ConditionsNightMode ;
: Night+mode  ( - )  false set-Nightmode ;
: Thermostat  ( - )  true  set-Nightmode ;
: parse-time  ( <hh%3Amm> - time ) parse-name 2drop parse-name ExtractTime ;

: Sleep+      ( - )
  i_ch_Sleep bInput@ 0=
  i_ch_Sleep bInput!   eval-ch-net drop ;


\ For: http://192.168.0.207:8080/ch%20menu?nn=SetTimespan&tStart=11%3A30&tEnd=23%3A59
: SetTimespan ( - )
   parse-time  StartTimeOutTempLimit ! parse-time  EndTimeOutTempLimit ! ConditionsNightMode ;

: ColdTrend ( - )  TidMonitorTrendJob kill  grabchars  MonitorTrendJob ;

FORTH DEFINITIONS PREVIOUS PREVIOUS
\s
