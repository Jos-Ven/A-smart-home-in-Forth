needs multiport_gate.f
marker CentralHeating.fs .latest

\ -------------- Settings ---------------------------

cr .( Assigned GPio pins )

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#    Name     Resistor         Input OR Output
 16 GpioPin:  Reset    +PullUpResistor  dup AsActiveLow AsPinInput
 24 GpioPin:  chNight  AsPinOutput      \ Connected to the night mode input of a thermostat through a relais.

 cr dup . .( Gpio pin[s] used.) to #pins \ Lock table and save the actual number of used pins
    InitPins  .pins                      \ Start and list the used GPio pins.


\ -------------- Settings ---------------------------
\ Mapped in Config.dat

ConfigVariable StartTimeOutTempLimit
ConfigVariable EndTimeOutTempLimit
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
              bInput: i_ch_Present   \ 1 inverted StandBy-
              bInput: i_ch_Automatic \ 2 inverted i_ch_Manual bInput@
>#bInputs c!                   \ 3

2variable ch-gui-mp
0 ch-gui-mp bInput: i_ch_Mode        \ 0 Active when the central heating is set to the nightmode
            bInput: i_ch_Sleep       \ 1 Active: Freezes until the next day
            bInput: i_ch_Manual      \ 2  Active for manual control
>#bInputs c!                   \ 3

2variable ch-out-mp
0 ch-out-mp bInput: i_ch_autom       \ 0  Output from the result of ch-autom-mp
            bInput: i_ch_gui         \ 1  Output from the result of ch-gui-mp
>#bInputs c!                         \ 2 The result will control the ventral heating


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
   i_ch_Manual bInputOn ;

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

FORTH DEFINITIONS PREVIOUS PREVIOUS
\s
