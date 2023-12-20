marker CentralHeating.fs .latest \ The central heating page
\ The value of StandBy- is used to detect if you are present.
\ StandBy- is Changed by HandleGForthResponse. That should be adapted for your situation.

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
  [IF]  \ Iniitial between 11:30 and 23:59
        1130 StartTimeOutTempLimit !
        2359 EndTimeOutTempLimit !
  [THEN]


2 value NightMode-
true value Job-
0 value #Jobs
2variable new-timespan
variable  Enter-Timespan

: .y|n            ( flag - )  if  +HTML| Y| else +HTML| N| then ;

: GetStartParams ( f: - @time  StartTimeOutTempLimitTics)
    @time LocalTics-from-UtcTics StartTimeOutTempLimit @ UtcTics-from-hm  ;

: OpeningHours-   ( - flag ) \ For nightmode
   GetStartParams  EndTimeOutTempLimit @ UtcTics-from-hm fbetween ;

: ConditionsNightModeOn ( - SwitchNightservice- )
   GetStartParams f<       if true exit  then
   StandBy-                if true exit  then
   OpeningHours- not       if true exit  then
   false ;

ALSO HTML

: .helpCv ( - )
  +HTML| <font size="2">|
   HTML| Abstract:| <<strong>> <br>
   Job-
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
     100 230 0 4 1 <tablepx>   ( wPx hPx cellspacing padding border -- )
         <tr><td>  HTML| Item|  <<strong>> </td>
             <td>  HTML| Flag|  <<strong>> </td>
             <td>  HTML| Start| <<strong>> </td>
             <td>  HTML| End|   <<strong>> </td></tr>

         <tr><tdL>  ButtonWhite black s" SetTimespan"  nn" <StyledButton>
         <td>  OpeningHours- Job- and .y|n </td>
         </td><td>    s" tStart" StartTimeOutTempLimit @  <InputTime> </td>
         </td><td>    s" tEnd"   EndTimeOutTempLimit @    <InputTime> </td>

         <tr><tdL> +HTML| Present: |   </td><td>  StandBy- not .y|n  </td>  2 <#tdL> </td></tr>

         <tr> 4 <#tdL>   HTML| State: |  <<strong>>
                <br> +HTML| The night mode is | +Nightmode +HTML| .|
                <br> +HTML| The job | Job-
                          if    +HTML| runs. Entry count:| #Jobs .Html
                          else  +HTML| has been stopped. |
                          then  </td></tr>
      </table> </fieldset> </td>  ;

: (+.Nightmode)  ( - )
         +HTML| Nightmode:|   +Nightmode
   <br>  Job-   if   +HTML| Automatic |   else  +HTML| Forced |  then ;

: ExtractTimes ( adr cnt - Endtime Starttime ) \ for: GET /CV%20menu?203=SetTimespan&tStart=12%3A30&X=&tEnd=23%3A59&X= HTTP/1.1
   2dup  s" tStart" ExtractTime >r
         s" tEnd"   ExtractTime r> ;

: OnOffColors ( - ColorButton ColorText )
   if ltBlue  else ButtonWhite  then black ;

: .ControllButtons ( - )
   <tdLTop> <fieldset> s" Schedule thermostat" <<legend>>
          100 230 14 0 0 <tablepx>   ( wPx hPx cellspacing padding border -- )
          <tr><tdL>  NightMode- OnOffColors s" Night mode"  nn" <StyledButton>
              </td> <tdL> Job- OnOffColors s" Job"   nn" <StyledButton> </td></tr>
          <tr><tdL> NightMode- not OnOffColors s" Thermostat"   nn" <StyledButton>
              </td> <tdL>  s" Shutdown" s" AskShutDownPage"  <CssButton>  </td></tr>
              s" nn" s" EnterTimespan"   <<HiddenInput>>
          <tr><tdL> .HtmlSpace </td></tr>
      </table> </fieldset> </td> ;

: CvMenu ( - ) \  Central heating options
    s" Central heating" NearWhite 0 <HtmlLayout>
       <tr> .StatisticsCv  .ControllButtons  </tr>
       <tr> 2 <#tdL> .helpCv </td> </tr>
    <EndHtmlLayout> ;

: UpdateTimeSpan ( - )
    new-timespan 2@ 2dup <
      if   EndTimeOutTempLimit ! StartTimeOutTempLimit !
      else 2drop
      then  ;

: Run/StopJob ( - )  false to StandBy- Job- not to Job-  ;

: SetNightMode ( mode - htmlpage$ lcount )
   to NightMode-  false to Job-  ;

: NightmodeOn  ( - )  true  SetNightMode CvNight -On    ;
: NightmodeOff ( - )  false SetNightMode CvNight -Off   ;

9 constant NoChange

: DetectStandby ( packet cnt - flag ) \ Flag: -1:Standby 0:NoStandby  9:Error
   dup 0=
     if  2drop NoChange exit
     then
   s" InStandby" compare 0= ;

: NightServiceChanged? ( new - flag )
   dup NightMode- <>
     if    to NightMode- true
     else  drop false
     then ;

: SwitchNightservice ( flag - )
    case
        true     of true  NightServiceChanged?  if  log" Night mode on"  CvNight -On   then  endof
        false    of false NightServiceChanged?  if  log" Night mode off" CvNight -Off  then  endof
         log" NoChange."
    endcase ;

: SetStandby ( f - )
      dup
        if    log" Starting standby"  \ When you are going away.
        else  log" Standby cancelled" \ When you are getting at home.
        then  to StandBy- ;

: OnStandby ( parm from  - )
  drop \  SendConfirmation
  SetStandby ;


: ConditionsNightMode ( - )
   Job-
     if  1 +to #Jobs ConditionsNightModeOn   SwitchNightservice
     then ;

: JobNightService  ( - )
   60000 ms
     begin   web-server-sock
     while   ConditionsNightMode   WaitTillNextMinute
     repeat
   cr  .date space .time ."  Bye JobNightService" Bye  ;

0 value TidJobNightService

 ' JobNightService      execute-task to TidJobNightService
 ConditionsNightModeOn  SwitchNightservice


ALSO TCP/IP DEFINITIONS \ Adding the page and it's actions to the tcp/ip dictionary

: /CV%20menu ( - ) ['] CvMenu set-page  ;
: tStart      ( <hh%3Amm> - time )  parse-name ExtractTime ;
: tEnd        ( start-time -  )     tStart  new-timespan 2! ;
: Job         ( - ) Run/StopJob  ;
: Night+mode  ( - ) NightmodeOn  ;
: Thermostat  ( - ) NightmodeOff ;

: EnterTimespan ( - )
     Enter-Timespan @
        if   UpdateTimeSpan   Enter-Timespan off
        then  ;

: SetTimespan ( - )  Enter-Timespan on ;

\ ShutDownOptions  s" Shutdown" s" AskShutDownPage"  <CssButton>

FORTH DEFINITIONS PREVIOUS PREVIOUS



\s

