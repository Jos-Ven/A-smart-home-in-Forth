marker graphics.fs .latest cr \ 04-06-2024 To plot various items


variable Graphic-flags
0 Graphic-flags bInput: Humidity-
                bInput: Light-
                bInput: Pollution-
                bInput: Pressure-
                bInput: Temperature-
                bInput: Compression- 2drop

true Graphic-flags !

2 value RightLabel

[UNDEFINED] Bme280Sensor [IF]
   Humidity-    bInputoff
   Pressure-    bInputoff
   Temperature- bInputoff
   3     to RightLabel
 [UNDEFINED] WiFiBitRate
    [IF]  MARKER WiFiBitRate    .latest
    [THEN]
[THEN]

[UNDEFINED] WiFiBitRate
    [IF]  MARKER WiFiBitRate    .latest
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
   [DEFINED] WiFiBitSignal [UNDEFINED] Ldrf@% [ OR ]
   [IF]    s" Signal&nbsp;level"
   [ELSE]  s" Light"
   [THEN]  ;


create signalUnit$ 8 allot

s" iwconfig| grep dBm" ShGet nip
    [IF]    s" dBm"
    [ELSE]  s" %"
    [THEN] signalUnit$ place

: LightUnitOnly"  ( -- adr count )
   [DEFINED] WiFiBitSignal   [UNDEFINED] Ldrf@%  [ OR ]
   [IF]    signalUnit$ count
   [ELSE]  s" X:"
   [THEN]  ;

: LightUnit"  ( -- adr count )
   [DEFINED] WiFiBitSignal    [UNDEFINED] Ldrf@%  [ OR ]
   [IF]    s" WiFi&nbsp;Signal&nbsp;level&nbsp;(" upad place
           signalUnit$ count +upad s" )" +upad upad count
   [ELSE]  s" Light&nbsp;(%):"
   [THEN]  ;

\ Data management:
\ needs avsampler.fs         \ Calculates an average for a number of samples.
\ needs svg_plotter.f        \ To plot simple charts for a web client
\ needs bsearch.f            \ For a quick search in a sorted file.
\ needs bme280-logger.fs     \ Contains also the data definitions
\ needs bme280-output.fs     \ To format the output


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
   [THEN] ;

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

: .Compression  ( - )
    <td> </td> <form> Compression- bInput@ <tdFlag>  s" Compression" nn" <button>
    </td> </form> ;


: NoneSlected?       ( -- f )
\   Humidity- bInput@  Light- bInput@ or Pollution- bInput@ or Pressure- bInput@ or not
   [ Humidity- activated-bit#   Light- activated-bit#
     Pollution- activated-bit#  Pressure- activated-bit# or or or ] literal
    Graphic-flags @ and not ;

: .Included)  ( - )
    NoneSlected?
      if  Temperature- bInputOn
      then
    +HTML| <td colspan="2"> | <form> <fieldset> s" Include" <<legend>> <center>
    Humidity-  bInput@
      if    &Humidity    >Color @ 0x555500 +
      else  ButtonWhite
      then  black s" Humidity"    nn" <StyledButton> .HtmlSpace
    Light-  bInput@
      if    &Light       >Color @
      else  ButtonWhite
      then  black  Light"         nn" <StyledButton> .HtmlSpace White 1  <hr>
    Pollution-  bInput@
      if    &Pollution   >Color @
      else  ButtonWhite
      then  black Pollution"      nn" <StyledButton> .HtmlSpace
    Pressure-  bInput@
      if    &Pressure    >Color @
      else  ButtonWhite
      then  black s" Pressure"    nn" <StyledButton> .HtmlSpace White 1  <hr>
    Temperature-  bInput@
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

[undefined] (pm25) [IF]
-1 value (pm25)  -1 value (Time_pm25)
[THEN]


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


\ coded char O negate + 1 2  >floorItem !
\ coded char c negate + 1 3  >floorItem !

coded char - negate + dup 1 3  >floorItem ! 1 4  >floorItem !

: .FloorItem ( n - )
   dup coded <
     if    abs 0x0ff and +1html
     else   (n.1) 4 min +html
     then ;

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

[DEFINED] ControlWindow [IF] Needs windowcontrol.f [THEN]

: ((+.Outside)) ( - )
    0 1 >floorItem @ 10 / dup
    +HTML| Outside:| 10 / TemperatureClassification +html .HtmlSpace
     (n.1) +html  .HtmlSpace +HTML| c| ;

' ((+.Outside)) is (+.Outside)

: .Abstract ( - )
    <fieldset> s" Floor sensors" <<legend>>
    100 40 0 3 1 <table> FloorHeader  FloorData  </table>
    </fieldset> ;

[THEN]

[UNDEFINED]  (+.Inside) [IF]
: (+.Inside)   ( - ) ;
[THEN]

[UNDEFINED]  (+.Nightmode) [IF]
: (+.Nightmode)  ( - ) ;
[THEN]


[defined] Floorplan  [DEFINED] Bme280Outside + 0= [IF]

: .Abstract ( - )
    <fieldset> s" Abstract" <<legend>>
    100 40 0 0 0 <table> <tr><tdL>
    +HTML| The sensors are 10 times read per minute. |
    +HTML| Then their average values are added to a logfile. |
    +HTML| Peak detection and scaling are used to determine the best points in the graph. |
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
      r@  Light- bInput@
             if   DupPdata    &Light    PlotDataLine   LabelLight     ?y-labels-right
             then
          Humidity-  bInput@
             if   DupPdata    &Humidity PlotDataLine   LabelHumidity  ?y-labels-right
             then
          Temperature- bInput@ NoneSlected? or
             if   DupPdata &Temperature PlotDataLine
                    -4 3 Red ['] Anchor-Justify-right  y-labels       \ y-labels left side
             then
          Pollution-  bInput@
             if   DupPdata    &Pollution PlotDataLine
                  Temperature- bInput@ NoneSlected? or not
                        if    -4 3 DkGreen ['] Anchor-Justify-right  y-labels       \ y-labels left side
                        else  LabelPollution ?y-labels-right
                        then
             then

          Pressure-  bInput@
             if    DupPdata   &Pressure  PlotDataLine   LabelPressure  ?y-labels-right
             then
      drop
      BottomMargin 5 >
        if  r@ 2dup swap s>f s>f f- ['] x-label-text
            color-x-labels  Rotation-x-labels  x-labels \ x-labels at the bottom
        then
      r> +HTML| </svg> | 2drop fdrop ;

: find-date-interval  ( &records data-size - &records data-size #end #start ) ( f: interval )
   Startdate findDateTarget  >r
   Enddate  findDateTarget   r>
   2dup - dup SetXResolution
   s>f #X_Lines xResolution * 1- 1 max s>f f/ ;


: InitDataParms ( - )
   Compression- bInput@
      if   1.08e
           [DEFINED] WiFiBitRate [if] 1.2e [else] 1.0e [then]
           1.02e 1.02e 1.0001e
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
   DkYellow &Light       >Color !

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
      if  2drop fdrop  +HTML| Collecting data. Just wait 3 minutes.|
      else
   s" Verdana" <FontFace  12 0 <FontSizeColor>
   100 100 0 0 0 <table> <tr><td>  <br> \ The Outer table with one cell is used to center the whole page
     4   4 0 0 0 <table>  <tr><td>  <fieldset>  <legend> SitesIndex HomeLink </legend> \ A table for an outer border
     4   4 1 0 0 <table>    \ A table to prevent floating cells
         <tr> +HTML| <td valign="top" rowspan="2">|
            +HTML| <fieldset style="width:570px">|
                 <legend> <aHREF" +homelink  +HTML| /home">| +HTML| History| </a> +HTML| : | TimeHdr +html
                 +HTML|  Vs:| &Version @ +AppVersion +HTML .HtmlSpace
                 +HTML| Uptime: | GetUptime Uptime>Html </legend>
                 570 370 Set_plot svg_plot   </fieldset>
                 .Statistics  </td>
            +HTML| <td valign="top">| .ControlPlot .Abstract .Links </td></tr>
         <tr> +HTML|  <td align="right" valign="bottom">| .GforthDriven  </td></tr>
        </table>
      </fieldset> </td></tr> </table>
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


: Send-recv-pkt ( recv-pkt$ cnt  - recv-pkt$ cnt   )
   log" Server: N/A. Sending the received packet."  ;

needs SensorWeb2.fs

PREVIOUS

LogValues


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

: Humidity      ( - )   Humidity-    invert-bit-input ;
: Light         ( - )   Light-       invert-bit-input ;
: Pollution     ( - )   Pollution-   invert-bit-input ;
: Pressure      ( - )   Pressure-    invert-bit-input ;
: Temperature   ( - )   Temperature- invert-bit-input ;
: Signal%C2%A0level ( n - ) Light ;
: Bit%C2%A0rate ( n - ) Pollution ;
: Compression   ( - )   Compression- invert-bit-input /home  ;

: /BodyCombinedPlots ( - 'BodyCombinedPlots ) ['] BodyCombinedPlots ;
: /BodySeparatePlots ( - 'BodySeparatePlots ) ['] BodySeparatePlots ;
: PlotsWH            ( 'Plots w h - )        0 set-page rot Dynpage ;

: Ask_HumidityStandBy ( host-id - )
   &bme280Record >Humidity f@ 100.e f* f>s (.) tmp$ place s"  " tmp$ +place
   (standby) (.) tmp$ +place
   s"  HumidityStandBy"  tmp$ +place
   tmp$ count rot SendTcp ;

: pm25         ( pm2.5 from - ) drop to (pm25) @hm_time to (Time_pm25) ;

FORTH DEFINITIONS
\  \s
