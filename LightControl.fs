needs multiport_gate.f
needs cHeating_mpn.f    \ For i_Present


\ -------------- Settings --------------

f# 2.0e fvalue ldr_lights_low       f# 3e0 fvalue ldr_lights_high
    90  value MinutesBeforeSunSet    0300  value reset_time_lights
     0  value lights-#changes           1  value lights-#changes-max


: day-profile   ( - ) f# 2.0e  to ldr_lights_low  f# 3e0  to ldr_lights_high ;
: night-profile ( - ) f# 14.0e to ldr_lights_low  f# 15e0 to ldr_lights_high ;

: LightsOff ( - )
\ Message                             ServerID   Communication
  s" -2130706452 F1 Q:1"                    12   (SendUdp)
  s" nn=On"                                  6   SendTcpInBackground 50 ms
  s" GET /BForm?nn=OnSwitchOff HTTP/1.1"    11   SendTcpInBackground 50 ms
  23 17 do   s" GET LedsOff NoReply-HTTP"    i   SendTcpInBackground 50 ms
        loop ;

: LightsOn ( - )
   lights-#changes  1+ to lights-#changes
   s" -2130706452 F0 Q:2 On"                 12   (SendUdp)
   s" nn=Off"                                 6   SendTcpInBackground 50 ms
   s" GET /BForm?nn=OnSwitchOn HTTP/1.1"     11   SendTcpInBackground 50 ms
   s" GET LedsOn NoReply-HTTP "              17   SendTcpInBackground 50 ms
   23 18 do  s" GET LightShowOn NoReply-HTTP" i   SendTcpInBackground 50 ms
         loop ;


\ -------------- Multi port gate logic --------------

2variable lights-multiport                   \      - Step 1: Create a 2variable for a multiport gate

0 lights-multiport bInput: i_lights_present  \ 0    - Step 2: Enumerate and name the input bits
                  bInput: i_lights_Ldr       \ 1
                  bInput: i_lights_sunset    \ 2
                  bInput: i_lights_automatic \ 3
                  bInput: i_lights_#changes  \ 4
          2dup    >#bInputs  c!              \       - Step 3: Store the  >#bInputs  ( #bits &multiport - )
                  >threshold c!              \                 properties >threshold ( #bits &multiport - )

\ Set the inputs
   1 i_lights_present   bInput!   \ ( flag input# &multiport - ) Flag: Nonzero values are seen as 1.
     i_lights_automatic bInputOn

: inq_ldr_lights ( - )
  Ldrf@% ldr_lights_low f<
     if    i_lights_Ldr bInputOn
     else  Ldrf@% ldr_lights_high f>
             if  i_lights_Ldr bInputOff
             then
    then ;

0 value day-lights

: inq_light_Hours_1_time ( - )
    day-lights time&date 2drop >r 3drop r@ <> \ new day?
        if    time>mmhh reset_time_lights >   \ time to reset?
                  if   i_lights_sunset bInputOff r@ to day-lights
                       day-profile 0 to lights-#changes
                  then
        else  i_lights_#changes  bInput@      \ same day
               if  sunset-still-today?
                     if  MinutesBeforeSunSet - 0<
                          if    i_lights_sunset bInputon
                          then
                     then
                then
         then  r> drop ;


: inq-lights-#changes ( - )  lights-#changes lights-#changes-max <= i_lights_#changes bInput! ;

: eval-light-net ( - flag )
   inq_ldr_lights inq-lights-#changes inq_light_Hours_1_time
   [ lights-multiport all-bits ] literal lights-multiport match-mp ;


: Set_lights_present ( - )     (standby) not i_lights_present bInput! ;
' Set_lights_present standby-chain  chained


: .eval-light-net ( - ) eval-light-net lights-multiport .inputs-mp ." Result: " . ;

0 value previous-state-lights

create Lightchange$ 20 allot

: Lightchange ( - ) (time) Lightchange$ place ;

Lightchange s" :Started." Lightchange$ +place

: lights-on/off ( - )
   eval-light-net dup previous-state-lights <>
     if  Lightchange dup to previous-state-lights
          if     night-profile ['] LightsOn s" :On" Lightchange$ +place
          else   ['] LightsOff s" :Off" Lightchange$ +place
          then   execute-task drop
     else drop
     then ;


\ -------------- Html --------------

ALSO HTML

: lights-header ( - )
   <td> HTML| Item |   <<strong>> </td>
   <td> HTML| Flag |   <<strong>> </td>
   <td> HTML| Actual | <<strong>> </td>
   <td> HTML| On |     <<strong>> </td>
   <td> HTML| Off |    <<strong>> </td> ;

: Lights-data ( - )
    eval-light-net

  <tr> <tdL> +HTML| ldr% | </td>
      <td>  i_lights_Ldr bInput@ .html </td>
      <tdR> Ldrf@%   .fHtml </td>
      <tdR> ldr_lights_low  .fHtml </td>
      <tdR> ldr_lights_high .fHtml </td>
  </tr>

   <tr> <tdL> +HTML| #limit | </td>
        <td>  i_lights_#changes bInput@ .html </td>
        <tdR> lights-#changes  .html </td>
         2 <#tdC> lights-#changes-max .html </td>
   </tr>


  <tr> <tdL> +HTML| Waits | </td>
       <td>   i_lights_sunset bInput@ .html </td>
       3 <#tdC>  sunset-still-today?
                if    MinutesBeforeSunSet - 0 max s>f fdays&time" 4 - 3 /string +html
                else  drop +HTML| -|
                then  </td>
   </tr>

   <tr> <tdL> +HTML| Present | </td>
        <td>  i_lights_present bInput@ .html </td>
        3 <#tdC>   .HtmlBl </td>
   </tr>

   <tr> <tdL> +HTML| Automatic | </td>
        <td>  i_lights_automatic bInput@ .html </td>
        3 <#tdC>   .HtmlBl </td>
   </tr>

   <tr> <tdL> +HTML| Result | </td>
        <td>   i_lights_automatic bInput@
                  if     abs .Html
                  else   drop +HTML| - |
                  then   </td>
        3 <#tdC>   Lightchange$ count +HTML  </td>
   </tr> ;

: LightsButtons
  <tr><td>  .HtmlSpace </td></tr>
  <tr><td>   s" On"        s" AutoLightOn"  0  <CssBlue|GrayButton>  </td></tr>
  <tr><td>   s" Off"       s" AutoLightOff" 0  <CssBlue|GrayButton>  </td></tr>
  <tr><td>  .HtmlSpace </td></tr>
  <tr><td>   s" Automatic" s" AutoLight"    i_lights_automatic bInput@  <CssBlue|GrayButton>  </td></tr>
   ;

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

: LightsControl  ( - )
      s" LightsControl" NearWhite 0 <HtmlLayout>
       <tdLTop> <fieldset>
                <legend> <aHREF" +homelink  +HTML| /lightscontrol">| +HTML| Statistics | </a> </legend>
             +HTML| <table border="1" cellpadding="4px" cellspacing="0"  width="10%" height="230px">|
                           lights-header Lights-data
                    </table> </fieldset>
      </td>
      <tdLTop> <fieldset> s" Lights" <<legend>>
              +HTML| <table border="0" cellpadding="1px" cellspacing="2"  width="10%"  height="230px">|
                     Report-lights
                     </table> </fieldset>
      </td>
       <tdLTop> <fieldset> s" Settings" <<legend>>
                  +HTML| <table border="0" cellpadding="4px" cellspacing="0"  width="10%"  height="230px">|
                            <Form>   LightsButtons  </form>
                    </table> </fieldset>
      </td>
      <EndHtmlLayout> ;


\ -------------- Incomming --------------

ALSO TCP/IP DEFINITIONS

: 200Down        ( - )  3 to lights-#changes ;
: /lightscontrol ( - )  ['] LightsControl set-page  ;
: AutoLight      ( - )  0 to lights-#changes i_lights_automatic invert-bit-input ;

: AutoLightOn    ( - )
    Lightchange  s" :On." Lightchange$ +place
    i_lights_automatic bInputoff    ['] LightsOn  execute-task drop ;

: AutoLightOff   ( - )
     Lightchange  s" :Off." Lightchange$ +place
     i_lights_automatic bInputoff   ['] LightsOff execute-task drop ;

FORTH DEFINITIONS PREVIOUS PREVIOUS
\ \s
