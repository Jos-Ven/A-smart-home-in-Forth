marker windowcontrol.f cr .( Loading: window_control.f )

needs multiport_gate.f
needs ldr.fs

\ -------------- Settings --------------


   7e0 fvalue ldr_low             16e0 fvalue ldr_high
1007e0 fvalue pressure_low      1010e0 fvalue pressure_high
  21e0 fvalue Temperature_low     23e0 fvalue Temperature_high
0400    value OpeningHours_low    1630  value OpeningHours_high \ in local time
   4    value Month_low              9  value Month_high
   4    value #changes_high             [DEFINED] #changes 0= [if] 0  value #changes  [then]

25e0   fvalue set-hot-profile       \ Switch when it was a above 25C
  18 constant esp-window-server     \ ID on of the ESP32 that runs the window opener
   0    value previous-state-window \ -3 forces an initial synchronization, 0 assumes the window is closed.

: normal-profile
    9e0    to ldr_low                15e0 to ldr_high
    0400   to OpeningHours_low       1630 to OpeningHours_high ;

: hot-profile
    0.12e0 to ldr_low               0.2e0 to ldr_high
    0400   to OpeningHours_low       0930 to OpeningHours_high  ;


\ -------------- Multi port gate logic --------------


2variable autom-window-mp
0 autom-window-mp bInput: i_window_Light \ 0
           bInput: i_window_Pressure     \ 1
           bInput: i_window_Temperature  \ 2
           bInput: i_window_#Changes     \ 3
           bInput: i_window_OpeningHours \ 4
           bInput: i_window_Month        \ 5
           bInput: i_window_Automatic    \ 6 \ Choose between automatic or manual (Gui)
                     >#bInputs c! \ 7

2variable gui-window-mp
0 gui-window-mp bInput: i_window_open    \ 0
         bInput: i_window_Override       \ 1     (inverted i_window_Automatic)
                 >#bInputs c!            \ 2

2variable out-window-mp
0 out-window-mp bInput: i_window_autom   \ 0
         bInput: i_window_gui            \ 1
                 >#bInputs c!            \ 2

: init-net      ( - )  0 autom-window-mp !   0 gui-window-mp !   0 out-window-mp ! ;

: set-window-override  ( - ) i_window_Automatic  i_window_Override   invert-dest-input ;


init-net  i_window_Automatic bInputOn  \ .eval-wnd-net


: inq_ldr ( - )
   Ldrf@%  ldr_low f<
     if    i_window_Light bInputOff
     else  Ldrf@% ldr_high f>
             if  i_window_Light bInputOn
             then
    then ;

: inq_pressure ( - )
   PressureSamples AverageSamples fdup pressure_low f<
     if    fdrop i_window_Pressure bInputOff
     else  pressure_high f>
             if  i_window_Pressure bInputOn
             then
    then ;

: inq_Temperature ( - )
   TemperatureSamples AverageSamples fdup Temperature_low f<
     if    fdrop i_window_Temperature bInputOff
     else  Temperature_high f>
             if  Temperature_high (f.2) +log i_window_Temperature bInputOn
             then
    then ;

: set-profile ( - )
    TemperatureSamples AverageSamples set-hot-profile f>
       if    hot-profile
       else  normal-profile
       then ;

: daily-reset-window ( - )
   time>mmhh  OpeningHours_low 10 -  OpeningHours_low 1- between
    if  0 to #Changes
        i_window_Temperature bInputOff
        set-profile
    then ;

: inq_OpeningHours  ( - )
   daily-reset-window
   time>mmhh  OpeningHours_low OpeningHours_high between
   i_window_OpeningHours bInput! ;

: current-month ( - month )  time&date drop >r 3drop drop r> ;

: inq_Month ( - )
   current-month Month_low Month_high between
   i_window_Month bInput! ;

: inq_#changes ( - )
   #changes   #changes_high <=
   i_window_#changes bInput! ;

: eval-wnd-net  ( - result-output )  \ Updates the relations. Result: Open window when true
   set-window-override                      \ New input for i_window_Override          \ 1
   inq_ldr inq_pressure inq_Temperature inq_OpeningHours inq_Month inq_#changes
   [ autom-window-mp all-bits ] literal autom-window-mp match-mp     i_window_autom  bInput!  \ 2
   [ gui-window-mp   all-bits ] literal gui-window-mp   match-mp     i_window_gui    bInput!  \ 3
   out-window-mp any-mp ;                                                       \ 4

create window-status& 80 allot
create window-date& 30 allot

: +WindowLineStartDate ( - )
   (date) window-date& place   s"  " window-date& +place (time) window-date& +place
   s" <br>" window-date& +place ;

  +WindowLineStartDate   s" has been started. " window-status& place


: send-open-window  ( - )
   +WindowLineStartDate s" /home?nn=AuxOn"   esp-window-server SendTcp
      if    s" is open."
      else  s" is offline.<br>Opening failed."
      then  window-status& place ;

: send-close-window ( - )
   +WindowLineStartDate s" /home?nn=AuxOff"  esp-window-server SendTcp
      if    s" is closed."
      else  s" is offline.<br>Closing failed."
      then  window-status& place ;

: send-stop-window  ( - )
   +WindowLineStartDate s" /home?nn=AuxStop" esp-window-server SendTcp
      if    s" stopped."
      else  s" is offline.<br>Stopping failed."
      then  window-status& place ;

: open/close-window ( - ) \  Runs each minute. see JobSendLowLightLevel in  _SensorWeb1.fs
   eval-wnd-net dup previous-state-window <>
     if  +WindowLineStartDate
         dup to previous-state-window  #changes 1+ to #changes
         TemperatureSamples AverageSamples  (f.2) +log
          if   send-open-window
          else send-close-window
          then
     else drop
     then ;

: .eval-wnd-net ( - )  \ To Track the inputs and outputs.
   eval-wnd-net drop   \ eval-wnd-net is needed to update the relations!
   cr .line-- space .time
   cr ." Autom-window-mp " [ autom-window-mp all-bits ] literal autom-window-mp .match-mp
   cr ." Gui-window-mp "   [ gui-window-mp   all-bits ] literal gui-window-mp   .match-mp
   cr ." Out-window-mp "   out-window-mp .any-mp ;


\ -------------- Html --------------

ALSO HTML

: window-header ( - )
   <tr><td> HTML| Item | <<strong>>  </td>
   <td> HTML| Flag |   <<strong>> </td>
   <td> HTML| Actual | <<strong>> </td>
   <td> HTML| Open |   <<strong>> </td>
   <td> HTML| Close |  <<strong>> </td></tr> ;

: +last-sample ( item - )  AverageSamples .fHtml  ;

: window-data
  <tr> <tdL> +HTML| ldr% | </td>
      <td> i_window_Light bInput@ .html </td>
      <tdR> Ldrf@%   .fHtml </td>
      <tdR> ldr_high .fHtml </td>
      <tdR> ldr_low  .fHtml </td>
  </tr>

  <tr> <tdL> +HTML| Pressure (hPA) | </td>
      <td> i_window_Pressure bInput@ .html </td>
      <tdR> PressureSamples +last-sample </td>
      <tdR> pressure_high .fHtml </td>
      <tdR> pressure_low  .fHtml </td>
  </tr>

  <tr> <tdL> +HTML| Temperature&nbsp;(C)&nbsp;| </td>
      <td> i_window_Temperature bInput@ .html </td>
      <tdR> TemperatureSamples +last-sample </td>
      <tdR> Temperature_high .fHtml </td>
      <tdR> Temperature_low  .fHtml </td>
  </tr>

  <tr> <tdL> +HTML| Opening hours | </td>
      <td>  i_window_OpeningHours bInput@ .html </td>
      <tdR> (time) 3 - +html </td>
      <tdR> OpeningHours_low  UtcTics-from-hm fdup UtcOffset f- ftime" 3 - +html </td>
      <tdR> OpeningHours_high UtcTics-from-hm fdup UtcOffset f- ftime" 3 - +html </td>
  </tr>

  <tr> <tdL> +HTML| Months| </td>
      <td>  i_window_month bInput@ .html </td>
      <tdR> current-month .html </td>
      <tdR> month_low  .html </td>
      <tdR> month_high .html </td>
  </tr>

  <tr> <tdL> +HTML| #Changes | </td>
      <td> i_window_#Changes bInput@ .html </td>
      <tdR> #changes .html  </td>
      <tdR> .HtmlBl </td>  \ eval-wnd-net result
      <tdR> #changes_high .html </td>
  </tr>

  <tr> <tdL> +HTML| Automatic | </td>
       <td>  i_window_Automatic bInput@ .html </td>
       3 <#tdC> NearWhite 230 4 <hrWH> </td>
  </tr>

  <tr> <tdL>  +HTML| Result| </td>
       <td>   out-window-mp any-mp abs  .html </td>
       3 <#tdL> Comment" +HTML window-date& count +HTML  +HTML|  The |
         <aHREF" s" /home " 18 <pagelink +HTML  s" window"  pagelink>
         window-status& count +HTML
      </td>
   </tr>
 ;

: WindowButtons ( - )
  <tr><td> .HtmlSpace </td></tr>
  <tr><td>  s" Open"       s" WindowOpen"  0  <CssBlue|GrayButton>  </td></tr>
  <tr><td> .HtmlSpace </td></tr>
  <tr><td>  s" Close"      s" WindowClose" 0  <CssBlue|GrayButton>  </td></tr>
  <tr><td> .HtmlSpace </td></tr>
  <tr><td>  s" Stop"       s" WindowStop"  0  <CssBlue|GrayButton>  </td></tr>
  <tr><td> .HtmlSpace </td></tr>
  <tr><td> .HtmlSpace </td></tr>
  <tr><td>  s" Automatic"  s" AutoWindow"  i_window_Automatic bInput@  <CssBlue|GrayButton> </td></tr> ;

: Window  ( - )
      s" WindowControl" NearWhite 0 <HtmlLayout>
     <tdLTop> <fieldset>
              <legend> <aHREF" +homelink  +HTML| /WindowControl">| +HTML| Statistics | </a> </legend>
     +HTML| <table border="1" cellpadding="4px" cellspacing="0"  width="10%" height="330px">|
        <Form> window-header window-data </form>
        </table> </fieldset>
     </td>

     <tdLTop> <fieldset> s" Settings" <<legend>>
                  +HTML| <table border="0" cellpadding="4px" cellspacing="0"  width="10%" height="330px">|
                            <Form>    WindowButtons   </form>
                    </table> </fieldset>
     </td>

    <EndHtmlLayout> ;

 eval-wnd-net
\ -------------- Incomming --------------


ALSO TCP/IP DEFINITIONS

: q bye ;
: /windowcontrol ( - ) ['] Window set-page  ;
: AutoWindow     ( - ) i_window_Automatic invert-bit-input  ;
: WindowOpen     ( - ) i_window_Automatic bInputoff send-open-window ;
: WindowClose    ( - ) i_window_Automatic bInputoff send-close-window ;
: WindowStop     ( - ) send-stop-window ;

FORTH DEFINITIONS PREVIOUS PREVIOUS

0 [if] \ Test and simulation
    i_window_Light         bInputOn
    i_window_Pressure      bInputOn
    i_window_Temperature   bInputOn
    i_window_#Changes      bInputOn
    i_window_OpeningHours  bInputOn
    i_window_Month         bInputOn  \ of autom-window-mp

    i_window_Automatic     bInputOn    .eval-wnd-net

    i_window_Temperature   bInputOff   .eval-wnd-net

    i_window_Automatic bInputoff .eval-wnd-net \ switch to manual
    i_window_open      bInputOn  .eval-wnd-net \ of gui-window-mp
    i_window_open      bInputOff .eval-wnd-net

\  eval-wnd-net .
[then]

