needs Common-extensions.f  cr \ Basic tools for Gforth and Win32Forth.
marker _SensorWeb1.fs .latest \ To support extra sensors. By J.v.d.Ven. 17-07-2023
                              \ It needs Gforth on a Raspberry Pi with linux (Jessie or Bullseye)
                              \ Enable the interfaces I2c and Spi with: sudo raspi-config

cr .(  Extra options that can be activated by deleting the backslash before the marker:)
\ The following lines are used as optional flags.
\ MARKER AdminPage      .latest \ For a link to the AdministrationPage
\ MARKER Bme280Outside  .latest \ Changes the abstract if the bme280 is placed outside
\ MARKER CentralHeating .latest \ To set a Central heating in the nightmode
\ MARKER DisableLogging .latest \ Disable logging after starting the webserver
\ MARKER Floorplan      .latest \ Changes the abstract to print a floorplan
\ MARKER FloordataToMsgBoard .latest \ Sent floordata also to a message board
\ MARKER LowLightLevel  .latest \ Used to put all lights on in the main room
\ MARKER NegateLdr      .latest \ Reverses the LDR values
\ MARKER PushBme280Data .latest \ To send Bme280Data to another Rpi
\ MARKER SendingState   .latest \ Sent sensor (Bme280Data) state and gpio state to the admin server
\ MARKER SitesIndexOpt  .latest \ Makes the index link visible needs sitelinks.fs
\ MARKER WarningLight   .latest \ Used to put a warning light on when the presure drops below 1007 HPA
\ MARKER WiFiBitRate    .latest \ Overwrites mq135 data with the WiFiBitRate in Wifi_signal.fs in the graph.
\ MARKER WiFiBitSignal  .latest \ Overwrites ldr data with the signal level of the WiFi connection in the graph.
\ MARKER DisableUpdServer  .latest \ For applications that uses a special udp-server like in  _UploadServer.f
cr
0 [if]

: WiFiBitRate@|Mq135f@  ( - f )
   [DEFINED] WiFiBitRate
   [IF]    WiFiBitRate@
   [ELSE]  Mq135f@
   [THEN]  ;


[THEN]


[defined] AdminPage     [IF] Needs Master.fs  [ELSE] needs slave.fs  [THEN]


30 constant MinutesBeforeSunSet \ After which it can trigger a LightsOn msg ( Needs LDR )
true value StandBy-

\ GPio pins:
needs wiringPi.fs          \ From: https://github.com/kristopherjohnson/wiringPi_gforth
needs gpio.fs              \ To control and administer GPio pins

[defined] CentralHeating [defined] Floorplan or  [IF] needs CentralHeating.fs    [ELSE] : OnStandby ; [THEN]

\ Added devices:
needs resetbutton.fs       \ In case the system hangs

true value Humidity-
true value Light-
True value Pollution-
true value Pressure-
true value Temperature-
2 value RightLabel

CheckI2c [IF]
        needs bme280.fs    \ For the BME280 sensor through I2c at channel 77
[ELSE]  0 value  fdBme280
[THEN]


fdBme280 ChipId@ 0<= [IF]
   false to Humidity-
   false to Pressure-
   false to Temperature-
   3     to RightLabel
 MARKER WiFiBitRate    .latest
 MARKER WiFiBitSignal  .latest
[THEN]

CheckSPI [IF]
 needs mcp3008.fs initSpi  \ To read an ADC on the Spi interface at Channel 0
 needs mq135.fs            \ For air quality sensor through the ADC at channel 1
 needs ldr.fs              \ For light intensity through the ADC at channel 0
       [defined] NegateLdr [IF] ' LdrNeg@ is Ldr@  [THEN]
[ELSE]
 MARKER WiFiBitRate    .latest
 MARKER WiFiBitSignal  .latest
[THEN]

: Pollution"  ( -- adr count )
    [DEFINED] WiFiBitRate
   [IF]    s" Bit&nbsp;rate"
   [ELSE]  s" Pollution"
   [THEN]  ;

: PollutionUnitOnly"  ( -- adr count )
   [DEFINED] WiFiBitRate
   [IF]    s" Mb/s"
   [ELSE]  s" X:"
   [THEN]  ;

: PollutionUnit"  ( -- adr count )
   [DEFINED] WiFiBitRate
   [IF]    s" WiFi&nbsp;Bit&nbsp;rate&nbsp;(Mb/s)"
   [ELSE]  s" Pollution&nbsp;(X):"
   [THEN]  ;

: Light"  ( -- adr count )
   [DEFINED] WiFiBitSignal
   [IF]    s" Signal&nbsp;level"
   [ELSE]  s" Light"
   [THEN]  ;


create signalUnit$ 8 allot

s" iwconfig| grep dBm" ShGet nip
    [IF]    s" dBm"
    [ELSE]  s" %"
    [THEN] signalUnit$ place

: LightUnitOnly"  ( -- adr count )
   [DEFINED] WiFiBitSignal
   [IF]    signalUnit$ count
   [ELSE]  s" X:"
   [THEN]  ;

: LightUnit"  ( -- adr count )
   [DEFINED] WiFiBitSignal
   [IF]    s" WiFi&nbsp;Signal&nbsp;level&nbsp;(" upad place
           signalUnit$ count +upad s" )" +upad upad count
   [ELSE]  s" Light&nbsp;(%):"
   [THEN]  ;



\ Data management:
needs avsampler.fs         \ Calculates an average for a number of samples.
needs svg_plotter.f        \ To plot simple charts for a web client
needs bsearch.f            \ For a quick search in a sorted file.
needs bme280-logger.fs     \ Contains also the data definitions
needs bme280-output.fs     \ To format the output


\ ---- The Html part ----------------------------------------------------------------------------

0 constant LabelPollution
1 constant LabelPressure
2 constant LabelHumidity
3 constant LabelLight

180  value #LastMin
false value dates-

ALSO HTML

: DatePickerInput> ( hhmmss yyyymmdd - )
   DatePicker$  +html  +HTML| " size="16"| aria-label>  ;

: <tdFlag>  ( flag -- )
   +crlf +HTML| <td |
     if  +HTML| bgcolor="#b0b0FF" |
     then
   +HTML| width="20%" valign="center" align="center">| ;

: .RangeDates  ( - )
    +HTML| <td width="40%" align="center" valign="center" > |
    +HTML| <input type="datetime-local" name="Start_date" value="|
            Startdate 2@ DatePickerInput> <EmptyLine>
            +HTML| <input type="datetime-local" name="End_date" value="|
             Enddate 2@  DatePickerInput>  </td>
    dates- <tdFlag> <p>  <strong>  FileError
                if    +HTML| Invalid date|
                else  Startdate @ 10000 / .html
                then
            </strong>
                        <br> +HTML| Start / End | </p>
    s" Range" nn" <button>  </td> ;

: .LastSamplesLine  ( - )
    <form>  +HTML| <td width="40%" align="center"> Last |
            +HTML| <input type="number" style="text-align:center" name="nn" value=|
                    #LastMin "." +html  +HTML| size="4" min="2" max="1000000" | aria-label> </td>
    dates- not <tdFlag>
           s" Samples" 2dup <CssButton> </form>  </td> ;

: Indicator      ( - )       s" &nbsp;*" <<strong>> ;
: ?Indicator     ( flag - )  if  Indicator  then ;
: RightLabel?Ind ( label - ) RightLabel = ?Indicator ;

: PollLabel ( - )
  [DEFINED] WiFiBitRate
   [IF]   +HTML| Bit rate.|
   [ELSE] +HTML| Poll.|
   [THEN]
 ;

: .LabelLine  ( - )
    <td> <form>
       s" nn"
       2dup s" RadPol"  <Radiobutton  RightLabel LabelPollution ?Checked>
              PollLabel   LabelPollution RightLabel?Ind
       2dup s" RadPres" <Radiobutton  RightLabel LabelPressure  ?Checked>
              +HTML| Press.|   LabelPressure RightLabel?Ind
       <br>
       2dup s" RadLight" <Radiobutton  RightLabel LabelLight    ?Checked>
               Light" +HTML   LabelLight RightLabel?Ind

              s" RadHum"  <Radiobutton RightLabel LabelHumidity ?Checked>
              +HTML| Humid.|   LabelHumidity RightLabel?Ind
    </td>
    <tdL>   s" Right label" nn" <button> </td> </form> ;

false value Compression-

: .Compression  ( - )
    <td> </td> <form>
     Compression- <tdFlag>  s" Compression" nn" <button> </td> </form> ;

: NoneSlected?       ( -- f )  Humidity-  Light- or Pollution- or Pressure- or  not ;

: .Included)  ( - )
    NoneSlected?
      if true to Temperature-
      then
    +HTML| <td colspan="2"> | <form> <fieldset> s" Include" <<legend>> <center>
    Humidity-
      if    &Humidity    >Color @ 0x555500 +
      else  ButtonWhite
      then  black s" Humidity"    nn" <StyledButton> .HtmlSpace
    Light-
      if    &Light       >Color @
      else  ButtonWhite
      then  black  Light"         nn" <StyledButton> .HtmlSpace White 1  <hr>
    Pollution-
      if    &Pollution   >Color @
      else  ButtonWhite
      then  black Pollution"      nn" <StyledButton> .HtmlSpace
    Pressure-
      if    &Pressure    >Color @
      else  ButtonWhite
      then  black s" Pressure"    nn" <StyledButton> .HtmlSpace White 1  <hr>
    Temperature-
      if    &Temperature >Color @
      else  ButtonWhite
      then  black s" Temperature" nn" <StyledButton>
    </center> </fieldset> </td> </form>  ;


: .ControlPlot ( - )
    +HTML| <fieldset style="width:310px"><legend>Settings</legend>|
    100 1 0 2 1 <table>  \ <table>: ( w% h% cellspacing padding border -- )
      <form> .RangeDates      </form>
      <tr>   .LastSamplesLine </tr>
      <tr>   .Compression     </tr>
      <tr>   .LabelLine       </tr>
      <tr>   .Included)       </tr>
    </table> +HTML|  </fieldset> | ;

: f@.2HtmlCell ( adr - ) f@ f.2HtmlCell ;
: f@.3HtmlCell ( adr - ) f@ f.3HtmlCell ;

: .Legend ( &Item - ) 16 swap >Color @ s" &#9608; " <<FontSizeColor>> ;

: .Statistic ( DescriptionLeftCell$ cnt &Item - )
       >r <tr><tdL>    r@ .Legend +html </td>
       r@ >FirstEntry dup f@.3HtmlCell
       r@ >LastEntry  dup f@.3HtmlCell
       f@ f@ f-            f.3HtmlCell
       r@ >MinStat        f@.3HtmlCell
       r@ >MaxStat        f@.3HtmlCell
       r> >AverageStat    f@.3HtmlCell
</tr> ;


: FirstRowStatistics ( - )
    <tr>  s" Parameter" <<td>>
          s" Start"     <<td>>
          s" End"       <<td>>
          s" Change"    <<td>>
          s" Low"       <<td>>
          s" High"      <<td>>
          s" Average"   <<td>>
    </tr> ;

: .Statistics ( - )
    <fieldset> s" Statistics" <<legend>>
    100 100 0 4 1 <table>
      FirstRowStatistics
      s" Humidity&nbsp;(%):"    &Humidity    .Statistic
      s" Pressure&nbsp;(hPA):"  &Pressure     .Statistic
      s" Temperature&nbsp;(C):" &Temperature .Statistic
      LightUnit"                &Light       .Statistic
      PollutionUnit"            &Pollution   .Statistic
    </table> </fieldset> ;

4 constant #floors 5 constant #floorItems
create &floorplan #floors #floorItems * cells allot
\ Floor 0 = Outside
\ Floor 1 = This system

: >floorItem ( #floor #item - adr )  cells swap #floorItems * cells + &floorplan + ;

: @hm_time ( - hm ) time&date>smh 100 * + nip ;

\ OnFloor for a packets like: GET Floor F0 T878 H6027 a-4175 b-4175  @3 HTTP/1.1

: OnFloor  ( recv-pkt$ cnt --   )  \ Incoming
   2dup SendConfirmation  bl NextString 2dup 2>r
    [char] F bl  ExtractNumber?     \ #Floor
       if   d>s  @hm_time over 0  >floorItem !
            2r>  #floorItems 1    \  Got 7 items extracting 5 (1-5)
               do    bl NextString 1 /string  2dup bl scan-
                     s>number? drop d>s  3 pick i  >floorItem !
               loop   3drop
       else   2r>  2drop 2drop
       then  ;

-4141 value Window0

: OnWindow0   ( recv-pkt$ cnt -- recv-pkt$ cnt )  \ Incoming
   2dup SendConfirmation [char] C bl  ExtractNumber?
     if    d>s to Window0
     else  2drop
     then  ;


: TemperatureClassification ( Temp - str cnt )
   dup  5 < if s" Cold"  else
   dup 18 < if s" Fresh" else
   dup 23 < if s" Nice"  else
   dup 25 < if s" Warm"  else s" Hot"
   then then then then rot drop ;

-4096 value coded

[defined] Bme280Outside [IF]


: .Abstract ( - )
    <fieldset> s" Abstract" <<legend>>
    100 40 0 0 0 <table> <tr><tdL> <br>
   +HTML| A temperature of | &Temperature >LastEntry f@ fdup (f.2) +html
    +HTML|  outside is: | f>s TemperatureClassification +html    dot" +html 2<br>
   </td></tr> </table> </fieldset>        ;

[THEN]

-1 value (pm25)
-1 value (Time_pm25)

: +pm25 ( - )
   (Time_pm25) 100 /mod mh>mh$ +html
   +HTML|  pm2.5: |  (pm25) s>f 100e f/ (f.2) +html ;

[defined] Floorplan [IF]
: DummyFloor
   #floors #floorItems * 0
      do   i &floorplan i cells + !
      loop ;

DummyFloor

: .Floors
   #floors 0
     do  cr #floorItems 0
           do    j i >floorItem @  .
           loop
    loop ;

: FloorHeader ( - )
   <tr><td>
    +HTML| Floor|  </td><td>
    +HTML| Time| </td><td>
    +HTML| Temp&nbsp;C| </td><td>
    +HTML| Hum&nbsp;%|  </td><td>
    +HTML| wnd1|   </td><td>
    +HTML| wnd2|
     </td></tr>  ;

: (n.1) ( n -- ) ( -- c-addr u )
   dup 0<
     if    abs -1
     else  0
     then  swap s>d <# # .#-> ;


\ coded char O negate + 1 2  >floorItem !
\ coded char c negate + 1 3  >floorItem !

coded char - negate + dup 1 3  >floorItem ! 1 4  >floorItem !

: .FloorItem ( n - )
   dup coded <
     if    abs 0x0ff and +1html
     else   (n.1) 4 min +html
     then ;

: GetTemperature ( - temp*10 )  &bme280Record >Temperature f@ 10e f* f>s ;

: FloorData ( - )
  @hm_time 1 0  >floorItem !
  GetTemperature 1 1  >floorItem !   \ Set Temperature in >floorItem ( =Floor 0 )
  Window0 1 3         >floorItem !   \ Set window0 in >floorItem
  &bme280Record >Humidity    f@ 10e f* f>s 1 2  >floorItem !
   1 #floors 1-
     do <tr><td>  i 1- .html </td><td>
                  i 0  >floorItem @   100 /mod mh>mh$ +html </td> \ time
          #floorItems  1
           do   <td> j i >floorItem @ .FloorItem </td>
           loop
         </td></tr>
      -1 +loop
   <tr><td> +HTML| Outside| </td>
   <td> 0 0 >floorItem @ 100 /mod mh>mh$ +html  </td>  \ time
   <td> 0 1 >floorItem @ 10 /  dup (n.1) +html  </td>  \ Temp
\   <td> 0 2 >floorItem @ 10 /      (n.1) +html  </td>  \ humidity
   <td> 0 2 >floorItem @ dup -4141 =
             if    drop +HTML| -|
             else  10 / (n.1) +html
             then  </td>  \ humidity

   2 <#tdC>  10 / TemperatureClassification +html
   </td></tr> ;

: (+.Window) ( - )
  +HTML| Window:|
     Window0 dup -4175 =
       if    drop +HTML| Open|
       else   -4195 =
              if   +HTML| Close|
              else +HTML| ?|
              then
       then \  <br-space>
       ;

: (+.Outside) ( - ) \ For the index
    0 1 >floorItem @ 10 / dup
    +HTML| Outside:| 10 / TemperatureClassification +html .HtmlSpace (n.1) +html ;

: (+.Inside) ( - )    GetTemperature +HTML| Inside: |  (n.1) +html <br-space> ;


: .Abstract ( - )
    <fieldset> s" Floor sensors" <<legend>>
    100 40 0 3 1 <table> FloorHeader  FloorData  </table>
    </fieldset> ;

[ELSE]
: (+.Window)   ( - ) ;
: (+.Outside)  ( - ) ;
: (+.Inside)   ( - ) ;
: (+.Nightmode)  ( - ) ;
[THEN]

[defined] Floorplan  [DEFINED] Bme280Outside + 0= [IF]

: .Abstract ( - )
    <fieldset> s" Abstract" <<legend>>
    100 40 0 0 0 <table> <tr><tdL>
    +HTML| For the graph a BME280 and a MQ135 are 10 times read in every minute. |
    +HTML| Then their average values are added to a logfile. |
    +HTML| Peak detection and scaling are used to determine the best points in the graph. |
    +HTML| Compression is not used for pollution.|
    +HTML| <br> <br> The sensors can also be monitored in a <a href="javascript:ref()">combined plot</a> |
    +HTML| or in <a href="javascript:ref2()">separate plots</a> with a 10 second update.|
    </td></tr> </table> </fieldset> ;

[THEN]


3 value DataLineWidth

: Set_plot ( Width Height - ) to SvgHeight  to SvgWidth ;

: MoveLeft_InRightMargin ( #pixels - Y-pos ) SvgWidth swap - ;

: ?y-labels-right ( radiobuttonNo - )
   RightLabel =
      if   104 MoveLeft_InRightMargin
           3   color-y-labels-right ['] Anchor-Justify-left y-labels
      then ;

: PlotDataLine  ( #end #start &DataLine  - ) ( f: interval - )
    >r 2dup 1- 0 max r@ >CfaDataLine perform f@  r@ >FirstEntry f!
    r@ >CfaDataLine perform f@  r@ >LastEntry f!
    r@ <poly_line_sequence  DataLineWidth  r@ >Color @ dup to color-y-labels-right poly_line>
    MinYBotExact r@ >MinStat f!  MaxYtopExact r@ >MaxStat f!
    Average r> >AverageStat f! ;


: DupPdata ( #end #start -  #end #start  #end #start ) ( f: interval - interval interval)
   2dup fdup  ;

: svg_plot ( #end #start - ) ( f: interval - )
     65 to BottomMargin   57 to RightMargin  65 to BottomMargin
      InitSvgPlot >r
      #X_Lines dup 1- r@ *  s>f to MaxXtop  #Max_Y_Lines   SetGrid
      r@  Light-
             if   DupPdata    &Light    PlotDataLine   LabelLight     ?y-labels-right
             then
          Humidity-
             if   DupPdata    &Humidity PlotDataLine   LabelHumidity  ?y-labels-right
             then
          Temperature- NoneSlected? or
             if   DupPdata &Temperature PlotDataLine
                    -4 3 Red ['] Anchor-Justify-right  y-labels       \ y-labels left side
             then
          Pollution-
             if   DupPdata    &Pollution PlotDataLine
                  Temperature- NoneSlected? or not
                        if    -4 3 DkGreen ['] Anchor-Justify-right  y-labels       \ y-labels left side
                        else  LabelPollution ?y-labels-right
                        then
             then
          Pressure-
             if    DupPdata   &Pressure  PlotDataLine   LabelPressure  ?y-labels-right
             then
      drop
      BottomMargin 5 >
        if  r@ 2dup swap s>f s>f f- ['] x-label-text
            color-x-labels  Rotation-x-labels  x-labels \ x-labels at the bottom
        then
      r> +HTML| </svg> | 2drop fdrop ;

: findDateTarget ( &date - #record )
   >r &bme280-FileRecords @ #records @ r>
   2@ record-size @ bsearch-doubles 2 pick - record-size @ / 1+ ;

: find-date-interval  ( &records data-size - &records data-size #end #start ) ( f: interval )
   Startdate findDateTarget  >r
   Enddate  findDateTarget   r>
   2dup - dup SetXResolution
   s>f #X_Lines xResolution * 1- 1 max s>f f/ ;


: InitDataParms ( - )
   Compression- \ drop 0
      if   1.08e 1e 1.02e 1.02e 1.0001e
      else 1e 1e 1e 1e 1e
      then
   &Pressure    >Compression f!
   &Humidity    >Compression f!
   &Temperature >Compression f!
   &Pollution   >Compression f!
   &Light       >Compression f!
   ['] r>Pressure    &Pressure    >CfaDataLine !
   ['] r>Pollution   &Pollution   >CfaDataLine !
   ['] r>Humidity    &Humidity    >CfaDataLine !
   ['] r>Temperature &Temperature >CfaDataLine !
   ['] r>Light       &Light       >CfaDataLine ! ;

: SetLastDataPointsExact ( - )
   ['] LastPointExact &Pressure    >CfaLastDataPoint !
   ['] LastPointExact &Pollution   >CfaLastDataPoint !
   ['] LastPointExact &Humidity    >CfaLastDataPoint !
   ['] LastPointExact &Temperature >CfaLastDataPoint !
   ['] LastPointExact &Light       >CfaLastDataPoint !

   DkMangenta &Pressure  >Color !
   Blue     &Humidity    >Color !
   Red      &Temperature >Color !
   DkGreen  &Pollution   >Color !
   Yellow   &Light       >Color !

   Black to color-x-labels
   4 to DataLineWidth ;

: TimeHdr ( - adr count )   (time) upad place space" +upad" ;

: JavaPartLink ( - )
   +HTML| <meta http-equiv="Content-Type" |
   +HTML| content="text/html; charset=iso-8859-1"> |
   +HTML| <script langauge="javascript">|
   +HTML| function ref() { |
   +HTML| location.href = "BodyCombinedPlots?" + window.innerWidth + "?" + window.innerHeight + "?PlotsWH"; } |
   +HTML| function ref2() { |
   +HTML| location.href = "BodySeparatePlots?" + window.innerWidth + "?" + window.innerHeight + "?PlotsWH"; } |
   +HTML| </script> | ;

: find-interval  ( #LastMin - #end #start ) ( f - interval )
    1- 1 max #records @ dup rot - 0 max
    2dup - dup SetXResolution
    s>f #X_Lines xResolution * 1- 1 max s>f f/ ;

: GetStartEndPlot (  -- vadr count #end #start ) ( f: - interval )
   dates-         \ Uses Defaults or the entered data from the user.
     if  MapBme280Data find-date-interval fdup  f0=
            if   2drop  fdrop  #LastMin  find-interval
                 false to dates-   true to FileError
            else false to FileError
            then
     else   SetFileYearToday  MapBme280Data #LastMin find-interval
     then ;

: .Links ( - )
     <fieldset> s" Links" <<legend>>
    100 40 0 0 0 <table> <tr><tdL>
    +HTML| Monitor: <a href="javascript:ref()">Combined plot</a> |
    +HTML| <a href="javascript:ref2()">Separate plots</a>| <br>
    +HTML| Options: |
     [DEFINED] Master.fs  [IF]
               AdminLink .HtmlSpace  [THEN]

     [DEFINED] CentralHeating.fs  [IF]
               <aHREF" +homelink  +HTML| /CV menu ">|
               +HTML| Central heating | </a> .HtmlSpace [THEN]

               <aHREF" +homelink  +HTML| /Schedule">|
               +HTML| Schedule| </a>

     [DEFINED] Master.fs [IF]
               <br> +HTML| Loggings: | LogLinks [THEN]
           <br>
           +Arplink  s" /Home" Sitelinks
    </td></tr> </table> </fieldset> ;

: BuildHtmlPage  ( -- )
   GetStartEndPlot
   <body>
      #records @ 3 <
      if     +HTML| Collecting data. Just wait 3 minutes.|
      else
   s" Verdana" <FontFace  12 0 <FontSizeColor>
   100 100 0 0 0 <table> <tr><td>  <br> \ The Outer table with one cell is used to center the whole page
     4 4 0 0 1 <table>  <tr><td> \ A table for an outer border
         4 4 1 0 0 <table>    \ A table to prevent floating cells
         <tr> +HTML| <td valign="top" rowspan="2">|
            +HTML| <fieldset style="width:570px">|
                 <legend>  SitesIndex  TimeHdr +html hostname$ count +html
                 +HTML|  Vs:| &Version @ +AppVersion +HTML .HtmlSpace
                 +HTML| Uptime: | GetUptime Uptime>Html </legend>
                 570 370 Set_plot svg_plot   </fieldset>
                 .Statistics  </td>
            +HTML| <td valign="top">| .ControlPlot .Abstract .Links </td></tr>
         <tr> +HTML|  <td align="right" valign="bottom">| .GforthDriven  </td></tr>
        </table>
      </td></tr> </table>
     </td></tr> </table> </font>
      then </body> </html>
     UnMapBme280Data ;

: sensor-home-page ( - )
    htmlpage$ off
    <html5> <html> <head> <<NoReferrer>>
     s"  " Html-title-header  JavaPartLink
    +HTML| <style> | svg_style-header
           95 14 +cssButton{}            \ Round buttons
    +HTML| </style> |
    </head>
    InitDataParms SetLastDataPointsExact  BuildHtmlPage
    crlf" +html ;


: GetHtmldate ( adr cnt -- yyyymmdd ) \ Extracted from the first: =Y-M-DT
  2dup 2>r
        [char] - extract$ s>number?
          if    d>s 10000 *
          else  2drop 0
          then
  2r@  [char] - [char] -  ExtractNumber?
          if    d>s   100 *
          else  2drop 0
          then  +
  2r>  [char] - [char] T Find$Between
       [char] - scan dup 0=
          if    2drop 2drop  time&date EncodeDate nip
          else  1 /string  s>number? drop d>s +
          then ;


: GetHtmltime ( adr cnt -- hhuuss ) \ Extracted from the first: =Y-M-DTu%3Au& ??
       2dup 2>r
       [char] T [char] % ExtractNumber?
          if    d>s 100 *
          else  2drop 0
          then
       2r> [char] % scan  3 /string s>number?
          drop d>s + 100 * ;


: ExtractTimeDate ( adr cnt - hhuuss yyyymmdd )   2dup 2>r GetHtmltime 2r> GetHtmldate ;
: MinimalDate     ( time date - Mintime Mindate ) time&date EncodeDate dmin ;

: DateSeparatorsFound? ( recv-pkt$ cnt - f ) \ date=
   true -rot  2dup [char] H scan  nip -
   [char] = scan 1 /string  4 0
      do  [char] - scan 1 /string
          dup 0< if rot drop 0 -rot leave then
      loop
   2drop ;

: SetDatesInTheSameYear ( - )
   Startdate @ 10000 /
   Enddate @ 10000 /mod
   drop swap 10000 * + Enddate ! ;


: Dodates (   StartTime StartDate EndTime EndDate -- )
    true to dates-
   2swap MinimalDate Startdate 2!
   MinimalDate 2dup Startdate 2@ d>
            if    Enddate  2! SetDatesInTheSameYear
            else  2dup Enddate 2! swap drop 0 swap 1- Startdate 2!
            then
   Startdate @ 10000 / SetFilename ;

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
            then  swap close-file drop
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


0  constant  LdrDataReceiver    \ Server that gets the Ldr Data
1.6e fconstant MinimalLdr      \ When the LDR gets below MinimalLdr \ was 1.8
0 value LowLightLevelsent

cr .( Ldr:) Ldrf@% f.

: SendLowLightLevel ( Server# - )
   Ldrf@% MinimalLdr f<
    if    s" Gforth::LowLight" rot SendConfirmUdp$
          if    log" SendLowLightLevelOnce done."
          else  log" Failed."
          then  true to LowLightLevelsent
          Ldrf@% (f.2) +log
          0001 WaitUntil  0 to LowLightLevelSent   log" Reset LowLightLevelSent"
    else  drop
    then ;

: SendLowLightLevelOnceAfter ( - )
   LowLightLevelsent  0=
    if   sunset-still-today?
      if MinutesBeforeSunSet <
             if  StandBy- not
                    if  log" LowLightLevelTime"  LdrDataReceiver  SendLowLightLevel
                    then
             then
     else drop
     then
    then ;

: SendFloorDataRequests  ( - )
   AdminServer ServerHost =
    if    s" /I0"  0 SendUdp$   \  To be adapted for your network
          s" /I0"  2 SendUdp$
          s" /I0"  3 SendUdp$
          s" /I0" 13 SendUdp$
          s" /I0" 14 SendUdp$
    then  ;

: JobSendBme280   ( - )
    20000 ms SendFloorDataRequests
    0 to LowLightLevelsent
        begin   web-server-sock
        while   Bme280DataReceiver SendBme280Data
                10 Minutes* ms
        repeat
      cr  .date space .time ."  Bye JobSendBme280" Bye  ;

: LowLevelPressureWarning      ( - )
   PressureSamples  AverageSamples 1007e f<  \ Give a warning when the presure gets below 1007 Hpa
            if    s" /w10" 11 SendTcp   \ The 11th server is an ESP8266F
            then
;

: JobSentToWarningLight   ( - )
    7000 ms
    log" JobSentToWarningLight started"
         begin   web-server-sock
         while   [DEFINED] WarningLight  [IF]  LowLevelPressureWarning  [THEN]
                 1 Minutes*   ms
         repeat
   cr  .date space .time ."  Bye JobSentToWarningLight" Bye  ;

: JobSendLowLightLevel   ( - )
    5000 ms
    log" JobSendLowLightLevel started"
         begin   web-server-sock
         while  SendLowLightLevelOnceAfter  1 Minutes*   ms
         repeat
   cr  .date space .time ."  Bye JobSendLowLightLevel" Bye  ;


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
  15 value    HumidityDecreaseTimeSpan \ Minimal 1 minute
  15 value    HumidityIncreaseTimeSpan \ Minimal 15 minutes
  15 value    TimeoutFloorJob          \ In minutes


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

: Send-Floor-job ( - )
    60000 ms Send-Floor 0e  send-data-humidity sent-temp-hum-to-msgboard
      begin  true   \  humidity-increase not yet sent
         TimeoutFloorJob 0   do   dup
                       if  send-humidity-increase
                       else 0
                       then
                     0=
                       if  drop false
                       then
                     web-server-sock    0=
                       if     20 ms leave
                       then   60000 ms
                loop
         log" 15 minutes."
         drop  0e  send-data-humidity
         sent-temp-hum-to-msgboard
         Send-Floor
         web-server-sock 0=
      until
      cr  .date space .time ."  Bye Send-Floor-job" Bye  ;


0 value Tid-Send-Floor-job


[then]




: Send-recv-pkt ( recv-pkt$ cnt  - recv-pkt$ cnt   )
   log" Server: N/A. Sending the received packet."  ;

needs SensorWeb2.fs

PREVIOUS

[defined] SitesIndexOpt [defined] AdminPage and [IF] needs SitesIndex.fs  [THEN]  \ =Optional for multiple sites
[defined] SitesIndexOpt [IF] ' (SitesIndex) is SitesIndex [THEN]

LogValues

0 value TidJobSendBme280
0 value TidJobSentToWarningLight
0 value TidJobSendLowLightLevel

cr .( Starting the support jobs )  \ Receiving servers should be adapted
    [DEFINED] PushBme280Data [IF] ' JobSendBme280          execute-task to TidJobSendBme280         [THEN]
    [DEFINED] WarningLight   [IF] ' JobSentToWarningLight  execute-task to TidJobSentToWarningLight [THEN]
    [DEFINED] LowLightLevel  [IF] ' JobSendLowLightLevel   execute-task to TidJobSendLowLightLevel  [THEN]
    [DEFINED] SendingState   [IF] ' Send-Floor-job         execute-task to Tid-Send-Floor-job       [THEN]


: (KillTasks ( - )
     [DEFINED] SendingState        [IF] Tid-Send-Floor-job       kill [THEN]
     [DEFINED] CentralHeating.fs   [IF] TidJobNightService       kill [THEN]
     [DEFINED] PushBme280Data      [IF] TidJobSendBme280         kill [THEN]
     [DEFINED] WarningLight        [IF] TidJobSentToWarningLight kill [THEN]
     [DEFINED] LowLightLevel       [IF] TidJobSendLowLightLevel  kill [THEN]

 ;

' (KillTasks is KillTasks

TCP/IP DEFINITIONS \ Adding the page and it's actions to the tcp/ip dictionary

: /home  ( - ) ['] sensor-home-page set-page ; \ So it will be executed after all other controls have been executed
' /home alias /

: Start_date ( <YYYY-MM-12THH%3AMM> - hhuuss yyyymmdd ) parse-name ExtractTimeDate ;
: End_date   ( hhuuss yyyymmdd - ) Start_date dodates ;
' noop alias Range

: Samples ( n - ) to #LastMin false to dates- SetFileYearToday  ;

' noop alias Right+label
: RadPol   ( - ) 0 to RightLabel ;
: RadPres  ( - ) 1 to RightLabel ;
: RadHum   ( - ) 2 to RightLabel ;
: RadLight ( - ) 3 to RightLabel ;

: Humidity     ( - )   Humidity-    not to Humidity-    ;
: Light        ( - )   Light-       not to Light-       ;
: Pollution    ( - )   Pollution-   not to Pollution-   ;
: Pressure     ( - )   Pressure-    not to Pressure-    ;
: Temperature  ( - )   Temperature- not to Temperature- ;
: Signal%C2%A0level ( n - ) Light ;
: Bit%C2%A0rate ( n - ) Pollution ;
: Compression  ( - )   Compression- not to Compression- /home  ;

: /BodyCombinedPlots ( - 'BodyCombinedPlots ) ['] BodyCombinedPlots ;
: /BodySeparatePlots ( - 'BodySeparatePlots ) ['] BodySeparatePlots ;
: PlotsWH            ( 'Plots w h - )        0 set-page rot Dynpage ;

: Ask_HumidityStandBy ( host-id - )
   cr dup . ." HumidityStandBy "
   &bme280Record >Humidity f@ 100.e f* f>s (.) tmp$ place s"  " tmp$ +place
   StandBy- (.) tmp$ +place
   s"  HumidityStandBy"  tmp$ +place
   tmp$ count rot SendTcp ;

[DEFINED] SendingState [IF]

: /I0   ( - ) Send-floor-data ;
: /IM   ( - ) sent-temp-hum-to-msgboard ;

[THEN]

: /floor ( <FN> - )
    udpin$ lcount parse-name s" W0" compare
      if     OnFloor
      else   OnWindow0
      then
    Ignore-remainder ;

: pm25         ( pm2.5 from - ) drop to (pm25) @hm_time to (Time_pm25) ;

: Gforth::Standby     ( parm from - ) s" OnStandby" +log  OnStandby ;

: Gforth_Bme280Data  ( - )
    udpin$ lcount  FindSender
      if    SendBme280Data
      else  drop
      then
    Ignore-remainder ;


FORTH DEFINITIONS


\ ' see-UDP-request  is udp-requests
\ ' see-request is handle-request \ Option to see the complete received request
cr .( The context will be TCP/IP only !  +f will get Forth again.)
start-servers
