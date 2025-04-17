needs multiport_gate.f
marker LightsControl.fs  .latest

\ Commucicates over UDP / TCP with lightservers
\ Change LightsOff and LightsOn for your situation.
\ Activate from the home page in the schedule 'Reset sleep' to start a new cycle.
\ Then the lights will then be put off when they are on. 04:00 sounds nice.
\ The multi port gates allows you to see what is going on.

\ -------------- Settings ---------------------------

      30  value MinutesBeforeSunSet   \ When to use an LDR to seen that it is getting dark
  f# 2.1e fvalue ldr_lights_low       \ To trigger the lights
       4  value lights-#changes-max   \ No automates changes today when this has been reached.

\ -------------- Switching --------------------------

0  value lights-#changes       \ Actual #changes
0  value previous-state-lights \ Prevent duplicate automatic switching.

: LightsOff ( - )
\ Message                               ServerID Communication / GPIO
  s" -2130706452 F1 Q:1"                      12 SendConfirmUdp$ drop \ nrs
  s" nn=On  NoReply-HTTP"                      6 SendTcpInBackground
  s" /BForm?nn=OnSwitchOff NoReply-HTTP"      11 SendTcpInBackground
  23 17 do   s" LedsOff NoReply-HTTP"          i SendTcpInBackground
        loop ;

: LightsOn ( - )
   lights-#changes  1+ to lights-#changes
   s" -2130706452 F1 Q:2 On"                  12 (SendUdp) \ show
   s" nn=Off  NoReply-HTTP"                    6 SendTcpInBackground
   s" /BForm?nn=OnSwitchOn NoReply-HTTP "     11 SendTcpInBackground
   s" LedsOn NoReply-HTTP "                   17 SendTcpInBackground
   23 18 do  s" LightShowOn NoReply-HTTP"      i SendTcpInBackground
         loop ;


\ -------------- Multi port gates ------------------
                                              \   - Step 1: Create a 2variable for a multiport gate
2variable lights-multiport                    \   - Step 2: Enumerate and name the input bits
0 lights-multiport bInput: i_lights_present   \ 0     Triggered when I am at home. See Gforth::Standby
                   bInput: i_lights_Ldr       \ 1     Triggered when it getting dark and i_lights_sunset active
                   bInput: i_lights_sunset    \ 2     Active after sunset - MinutesBeforeSunSet
                   bInput: i_night-mode       \ 3     Active when it is getting dark after sunset - MinutesBeforeSunSet
                   bInput: i_lights_automatic \ 4     Inverted i_Manual_lights
                   bInput: i_lights_#changes  \ 5     Active when lights-#changes-max <= i_lights_#changes
          2dup    >#bInputs  c!               \ 6 - Step 3: Store the  >#bInputs  ( #bits &multiport - )
                  >threshold c!               \             properties >threshold ( #bits &multiport - )
                                              \ Result to i_autom of gui-mp

2variable gui-mp
0 gui-mp bInput: i_switch         \ 0  Manual switch on / off
         bInput: i_Manual_lights  \ 1  Active for manual control
         bInput: i_sleep_lights   \ 2  Active: Freezes until the next day
                 >#bInputs c!     \ 3  Result to i_gui of out-mp

2variable out-mp
0 out-mp bInput: i_autom      \ 0 from the result of lights-multiport
         bInput: i_gui        \ 1 from the result of gui-mp
                 >#bInputs c! \ 2 The result will control the lights

\ -------------- Relations between the multi port gates ---

: set-lights-override  ( - )
    i_sleep_lights bInput@  i_Manual_lights bInput@ or 0=  i_lights_automatic bInput! ;


: reset-lights ( - )   \ See also schedule_daily.fs
  i_lights_sunset bInputOff          0 to           lights-#changes
  i_night-mode    bInputOff          i_lights_Ldr   bInputOff
  i_Manual_lights bInputOff          i_sleep_lights bInputOff ;

 ' reset-lights   reset-sleep-chain chained

: inq_ldr_lights ( - )
  Ldrf@% ldr_lights_low f<  i_night-mode bInput@ and
     if    i_lights_Ldr bInputOn
     then ;

: inq_sunset ( - )
    i_Manual_lights bInput@ 0=   i_night-mode  bInput@ 0= and
      if  sunset-still-today?
          if  MinutesBeforeSunSet - 0<    \ after sunset - MinutesBeforeSunSet
              if    i_lights_sunset bInputOn i_night-mode bInputOn
              else  i_lights_Ldr bInputOff i_lights_sunset bInputOff
              then
          else  drop
          then
      then  ;

: inq-lights-#changes ( - )
    lights-#changes lights-#changes-max <= i_lights_#changes bInput! ;

: eval-light-net ( - flag )  \ evaluates all inputs and returns a flag for the lights.
   set-lights-override
   inq-lights-#changes  inq_sunset   inq_ldr_lights
   [ lights-multiport all-bits ] literal lights-multiport match-mp i_autom  bInput!
   i_Manual_lights  bInput@     i_switch bInput@   and    i_gui bInput!
   out-mp any-mp ;

: .eval-light-net ( - ) \ uses eval-light-net and shows the multi port gates.
   ." lights-mp: "  eval-light-net lights-multiport .inputs-mp
   cr ." gui-mp:"    gui-mp .inputs-mp
   cr ." out-mp:"    out-mp .inputs-mp ." Result: " . ;

\ -------------- out-mp controlled ------------------

create Lightchange$ 20 allot

: Lightchange    ( - ) (time) Lightchange$ place ;
: LightchangeOn  ( - ) Lightchange s" :On"  Lightchange$ +place LightsOn ;
: LightchangeOff ( - ) Lightchange s" :Off" Lightchange$ +place LightsOff ;

: lights-on/off ( - ) \ Used at EachMinuteJob in job_support.fs
   eval-light-net dup previous-state-lights <>
     if dup to previous-state-lights PingTcpServers 150 ms
          if   LightchangeOn
          else LightchangeOff
          then
     else drop
     then
  50 ms ; \ 50 ms to be sure that all has been sent

: ForceChange ( - )  3 to previous-state-lights lights-on/off ;

\ ------------ Used chains --------------------------

: Set_lights_present ( - )
  (standby) not i_lights_present bInput! ForceChange ;

' Set_lights_present standby-chain  chained

: 200Down-lights        ( - )
  i_lights_present bInputOff  i_switch        bInputOff
  i_night-mode     bInputOff  i_lights_sunset bInputOff lights-on/off ;

' 200Down-lights 200Down-chain  chained

\ ------------- Initial settings---------------------

sunset-still-today? dup      i_lights_sunset bInput!    i_night-mode bInput! drop
i_lights_present  bInputOn   i_switch        bInputOff
reset-lights                 i_Manual_lights bInputOn
Lightchange s" :Started." Lightchange$ +place

\ -------------- Html page --------------------------

ALSO HTML

: lights-header ( - )
   <td> HTML| Item |   <<strong>> </td>
   <td> HTML| Flag |   <<strong>> </td>
   <td> HTML| Actual | <<strong>> </td>
   <td> HTML| On |     <<strong>> </td> ;

: Lights-data ( eval-light-net-flag - )
  <tr> <tdL> +HTML| ldr% | </td>
      <td>  i_lights_Ldr bInput@ .html </td>
      <tdR> Ldrf@%   .fHtml </td>
      <tdR>  +HTML| <| .HtmlSpace ldr_lights_low  .fHtml </td>
  </tr>

  <tr> <tdL> +HTML| #limit | </td>
        <td>  i_lights_#changes bInput@ .html </td>
        <tdR> lights-#changes .html </td>
        2 <#tdC> +HTML| <| .HtmlSpace lights-#changes-max 1+ .html </td>
  </tr>


  <tr> <tdL> +HTML| WaitTime | </td>
       <td>   i_lights_sunset bInput@ .html </td>
       3 <#tdC>  sunset-still-today?
                if    MinutesBeforeSunSet - 0 max s>f fdays&time" 4 - 3 /string +html
                else  drop +HTML| -|
                then  </td>
  </tr>

  <tr> <tdL> +HTML| NightMode | </td>
       <td>   i_night-mode bInput@ .html </td>
       3 <#tdC>   .HtmlBl </td>
  </tr>

  <tr> <tdL> +HTML| Present | </td>
        <td>  i_lights_present bInput@ .html </td>
        3 <#tdC>   .HtmlBl </td>
  </tr>

  <tr> <tdL> +HTML| Automatic | </td>
        <td>   i_Manual_lights  bInput@ 0= abs .html </td>
        3 <#tdC>   .HtmlBl </td>
  </tr>

  <tr> <tdL> +HTML| Result | </td>
        <td>  abs .Html    ( eval-light-net-flag - )
        </td>
        3 <#tdC>   Lightchange$ count +HTML  </td>
   </tr> ;

: LightsButtons ( eval-light-net-flag - )
  <tr><td>  .HtmlSpace </td></tr>
  <tr><td>   >r s" On" s" AutoLightOn"
             r@ <CssBlue|GrayButton>  </td></tr>
  <tr><td>   s" Off"       s" AutoLightOff"  r> 0=
             <CssBlue|GrayButton>  </td></tr>
  <tr><td>   s" Sleep"     s" SetSleep"  i_sleep_lights bInput@  i_lights_automatic bInput@ 0= and
             <CssBlue|GrayButton>  </td></tr>
  <tr><td>  .HtmlSpace </td></tr>
  <tr><td>   s" Automatic" s" AutoLight"  i_Manual_lights bInput@  0=
             <CssBlue|GrayButton>  </td></tr> ;

: Report-light ( id  - )
   dup r>Online @ 0=
    if    .html +HTML| :Offline.| <br>
    else  dup .html  +HTML| :| Sitelink <br>
    then  ;

: Report-lights  ( - )
    <tr> <tdL>
    6 Report-light    11 Report-light    12 Report-light
    23 17
      do   i Report-light
      loop
    </td> </tr> ;

: lights-control  ( - )
      s" LightsControl" NearWhite 0 <HtmlLayout>
      eval-light-net >r
       <tdLTop> <fieldset>
                <legend> <aHREF" +homelink  +HTML| /lightscontrol">| +HTML| Statistics | </a> </legend>
             +HTML| <table border="1" cellpadding="4px" cellspacing="0"  width="10%" height="280px">|
                           lights-header r@ Lights-data
                    </table> </fieldset>
      </td>
      <tdLTop> <fieldset> s" Lights" <<legend>>
              +HTML| <table border="0" cellpadding="1px" cellspacing="2"  width="10%"  height="280px">|
                     Report-lights
                     </table> </fieldset>
      </td>
       <tdLTop> <fieldset> s" Settings" <<legend>>
                  +HTML| <table border="0" cellpadding="4px" cellspacing="0"  width="10%"  height="280px">|
                            <Form>   r> LightsButtons  </form>
                    </table> </fieldset>
      </td>
      <EndHtmlLayout> ;

\ -------------- Incomming through tcp --------------

ALSO TCP/IP DEFINITIONS

: /LightsControl ( - ) ['] lights-control set-page ;
: AutoLightOn    ( - ) i_switch bInputOn  i_Manual_lights bInputOn  ForceChange ;
: AutoLightOff   ( - ) i_switch bInputOff i_Manual_lights bInputOff ForceChange ;

: AutoLight      ( - )
    i_Manual_lights  bInput@ 0=
       if  eval-light-net i_switch bInput!
       then
    0 to lights-#changes  i_Manual_lights invert-bit-input
    i_sleep_lights  bInputOff
    lights-on/off ;

: SetSleep       ( - )
    i_Manual_lights  bInput@ 0=
       if   eval-light-net i_switch bInput!
       then
    i_sleep_lights invert-bit-input
    i_Manual_lights  bInputOn  lights-on/off  ;

FORTH DEFINITIONS PREVIOUS PREVIOUS

\ \s
