\ ---- Assigning GPio pins ---------------------------------------------------------------------------
cr .( Assigned GPio pins in CentralHeating.fs )

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#    Name     Resistor         Input OR Output
 16 GpioPin:  Reset    +PullUpResistor  dup AsActiveLow AsPinInput
 24 GpioPin:  CvNight  AsPinOutput      \ Connected to the night mode input of a thermostat through a relais.

 cr dup . .( Gpio pin[s] used.) to #pins \ Lock table and save the actual number of used pins
    InitPins  .pins                      \ Start and list the used GPio pins.

\ ----------------------------------------------------------------------------------------------------

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


needs cHeating_mpn.f

: i_Automatic@ ( - value ) i_Automatic bInput@ ;

ALSO HTML

: .helpCv ( - )
  +HTML| <font size="2">|
   HTML| Abstract:| <<strong>> <br>
   i_Automatic@
      if    +HTML| Between | StartTimeOutTempLimit @ .html
            +HTML|  and | EndTimeOutTempLimit @ .html
            +HTML|  the thermostat will execute its schedule.|
            <br> +HTML| When no one is at home the thermostat should be in night mode.|
      else  CvNight \State
                if     +HTML| The night mode is permanent.|
                else   +HTML| The thermostat runs the CV.|
                then
      then
   </font> ;

: +Nightmode ( -)    CvNight \State  flag1/0  if +HTML| on|  else  +HTML| off|  then ;

: .StatisticsCv ( - )
     <tdLTop> <fieldset>  s" Statistics" <<legend>>
     </form> <form>
     100 230 0 4 1 <tablepx>   ( wPx hPx cellspacing padding border -- )
         <tr><td>  HTML| Item|  <<strong>> </td>
             <td>  HTML| Flag|  <<strong>> </td>
             <td>  HTML| Start| <<strong>> </td>
             <td>  HTML| End|   <<strong>> </td></tr>
         <tr><tdL>  ButtonWhite black s" SetTimespan"   nn"  <StyledButton> \ 1 ...
         <td>  OpeningHours- i_Automatic@  and .y|n </td>
         </td><td>    s" tStart" StartTimeOutTempLimit @  <InputTime> </td>
         </td><td>    s" tEnd"   EndTimeOutTempLimit @    <InputTime> </td>
         <tr><tdL> +HTML| Present: |   </td><td>
                   i_Present bInput@ .y|n  </td>  2 <#tdL> </td></tr>
         <tr> 4 <#tdL>   HTML| State: |  <<strong>>
                <br> +HTML| The night mode is | +Nightmode +HTML| .|
                <br> +HTML| The job | i_Automatic@
                          if    +HTML| runs. Entry count:| #Jobs .Html
                          else  +HTML| has been stopped. |
                          then  </td></tr>
      </table> </form> <form> </fieldset> </td>  ;

: (+.Nightmode)  ( - )
         +HTML| Nightmode:|   +Nightmode
   <br>  i_Automatic@
            if   +HTML| Automatic |   else  +HTML| Forced |  then ;

: OnOffColors ( - ColorButton ColorText )
   if ltBlue  else ButtonWhite  then black ;

: .ControllButtons ( - )
   <tdLTop> <fieldset> s" Schedule thermostat" <<legend>>
          100 230 14 0 0 <tablepx>   ( wPx hPx cellspacing padding border -- )

          <tr><tdL>  out-mp any-mp dup 0=
                     OnOffColors s" Night mode"  nn" <StyledButton>
              </td> <tdL> i_Automatic@
                          OnOffColors s" Job"   nn" <StyledButton> </td></tr>
          <tr><tdL> ( out-mp fire ) OnOffColors s" Thermostat"   nn" <StyledButton>
              </td> <tdL>  s" Shutdown" s" AskShutDownPage"  <CssButton>  </td></tr>
          <tr><tdL> .HtmlSpace </td></tr>
      </table> </fieldset> </td> ;

: CvMenu ( - ) \  Central heating options
    s" Central heating" NearWhite 0 <HtmlLayout>
       <tr> .StatisticsCv  .ControllButtons  </tr>
       <tr> 2 <#tdL> .helpCv </td> </tr>
    <EndHtmlLayout> ;

: set-cv ( flag - )
   if   CvNight -Off
   else CvNight -On
   then ;

: Run/StopJob ( - )
   i_Present bInputon
   i_Automatic@ dup                                            \ Change from automatic to manual?
     if     [ autom-mp all-bits ] literal autom-mp match-mp
            i_Mode bInput!                                      \ keep the current state
     then
   not i_Automatic bInput!
   eval-ch-net set-cv ;

: set-Nightmode ( i_Mode - )
    i_Mode      bInput!
    i_Automatic bInputOff
    eval-ch-net dup set-cv  out-mp >last-out c! ;

: SetStandby ( f - )
    dup
      if    log" Starting standby"  \ When you are going away.
      else  log" Standby cancelled" \ When you are getting at home.
      then  not i_Present bInput!  ;

true SetStandby

: OnStandby ( parm from  - )
   drop \  SendConfirmation
   SetStandby ;

: SwitchNightservice ( flag - )
   dup out-mp  >last-out c@ 0<> <>
    if  dup out-mp >last-out c! dup set-cv
          if    log" Night mode off"
          else  log" Night mode on"
          then
    else drop
    then ;

: ConditionsNightMode ( - )
   i_Automatic@
     if  1 +to #Jobs eval-ch-net SwitchNightservice
     then ;

: JobNightService  ( - )
   60000 ms
     begin   web-server-sock
     while   ConditionsNightMode   WaitTillNextMinute
     repeat
   cr  .date space .time ."  Bye JobNightService" Bye  ;

0 value TidJobNightService  9 out-mp >last-out c!  eval-ch-net set-cv

 ' JobNightService      execute-task to TidJobNightService


ALSO TCP/IP DEFINITIONS \ Adding the page and it's actions to the tcp/ip dictionary

: /CV%20menu ( - ) ['] CvMenu set-page  ;
: Job         ( - ) Run/StopJob  ;
: Night+mode  ( - ) false set-Nightmode ;
: Thermostat  ( - ) true  set-Nightmode ;

: parse-time ( <hh%3Amm> - time ) parse-name 2drop parse-name ExtractTime ;

\ For: http://192.168.0.207:8080/CV%20menu?nn=SetTimespan&tStart=11%3A30&tEnd=23%3A59
: SetTimespan ( - )
   parse-time  StartTimeOutTempLimit ! parse-time  EndTimeOutTempLimit ! ;

FORTH DEFINITIONS PREVIOUS PREVIOUS

\s

