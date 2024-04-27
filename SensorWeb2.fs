Marker SensorWeb2.fs

\ A link to the dynamic page looks like:
\ http://nnn.nnn.n.n:8080/dynpageW1165H684
\ Change the number after the W or H to change the width or the height of the plot.

false value S5? \ to detect my S5

: JavaRefresh ( - )
   +HTML| <script langauge="javascript"> window.setInterval("refreshDiv()", 10000); |
   +HTML| function refreshDiv(){ |
   +HTML| window.location.reload(false); |
   +HTML| } |
   +HTML| </script> | ;

: MetaHeaderRefresh ( - )
   +HTML| <META HTTP-EQUIV="refresh" CONTENT="10"> | ;

: RefreshCmd ( - )
   htmlpage$ off
   <html5>  <html> <head> s" Monitor" Html-title-header
    +HTML| <meta http-equiv="Cache-control" content="private"> |
    +HTML| <META HTTP-EQUIV="Expires" CONTENT="-1">
     S5? if   JavaRefresh
         else MetaHeaderRefresh
         then
    </head>  ;

: LastPressure    ( #end #start &DataLine  - ) ( f: - Pressure )    3drop PressureSamples    AverageSamples ;
: LastPollution   ( #end #start &DataLine  - ) ( f: - Pollution )   3drop PollutionSamples   AverageSamples ;
: LastHumidity    ( #end #start &DataLine  - ) ( f: - Humidity )    3drop HumiditySamples    AverageSamples ;
: LastTemperature ( #end #start &DataLine  - ) ( f: - Temperature ) 3drop TemperatureSamples AverageSamples ;
: LastLdr         ( #end #start &DataLine  - ) ( f: - Temperature ) 3drop LdrSamples         AverageSamples ;

560 constant SmallScreen
90  value SfSize
70  value BfSize
14  value vsFont
20  value DescrFont

: SetFontsDataLineSize ( DataLineSize SfSize BfSize - )
    to BfSize to SfSize to DataLineWidth ;

0 value WidthViewPort
0 value HeightViewPort

: GetViewport ( w h - ) to HeightViewPort  to WidthViewPort ;

: SetSizesFixed ( - )
   6 60 90  SetFontsDataLineSize 16 to vsFont
   595 550  Set_plot ;

: SetSvgFonts ( - )
    WidthViewPort
     if   HeightViewPort dup
          if   SmallScreen <
               if    4 30 50
               else  5 40 50
               then  SetFontsDataLineSize 14 to vsFont
          else  drop
          then
     then ;

: SetLastDataPointsToSamples ( - )
   ['] LastPressure    &Pressure    >CfaLastDataPoint !
   ['] LastPollution   &Pollution   >CfaLastDataPoint !
   ['] LastLdr         &Light       >CfaLastDataPoint !
   ['] LastHumidity    &Humidity    >CfaLastDataPoint !
   ['] LastTemperature &Temperature >CfaLastDataPoint !
   LtMangenta      &Pressure    >Color !
   lightSlateBlue  &Humidity    >Color !
   Red             &Temperature >Color !
   Yellow          &Light       >Color !
   Green  dup      &Pollution   >Color ! to color-y-labels-right
   NearWhite to color-x-labels ;

: greenHr ( - ) $00FF00 1 <hr> ;

: .ShortAbstract  ( - )
    vsFont NearWhite
    2dup time&date >r swap 2>r 2drop drop r> (.) <<FontSizeColor>>
    2dup s" -"  <<FontSizeColor>>
    2dup r> (.)  <<FontSizeColor>>
    2dup s" -"  <<FontSizeColor>>
    2dup r> (.)  <<FontSizeColor>>
    2dup s" , "  <<FontSizeColor>>
    2dup (time)  <<FontSizeColor>>
    2dup s" . "  <<FontSizeColor>>
    2dup #LastMin s>d (ud,.)     <<FontSizeColor>>
         s" &nbsp;samples&nbsp;evaluated." <<FontSizeColor>> ;

: addchar ( adr cnt char - adr cnt )
    -rot upad place sp@ 1 +upad drop upad count ;

: .CombinedPlot ( - )
    s" Verdana" <FontFace .ShortAbstract
    Green dup &Pollution >Color ! to color-y-labels-right
    #LastMin find-interval svg_plot
    <br>
    vsFont lightSlateBlue s" Humidity, "          <<FontSizeColor>>
    vsFont Yellow         Light" [char] , addchar <<FontSizeColor>>
    vsFont LtMangenta     s" Pressure,"          <<FontSizeColor>>
    vsFont Green          Pollution"   bl addchar <<FontSizeColor>>
    vsFont Red            s" and Temperature."    <<FontSizeColor>>
    </font> ;

: SetSvgSizeRel ( w% h% - )
   HeightViewPort swap % to SvgHeight WidthViewPort swap % to SvgWidth  ;

: (HtmlSpaceStart) ( - ) s" &nbsp;" upad place ;
: ((inlude$))      ( adr cnt - adr2 cnt2  ) +upad upad count ;

: .SensorValues ( - )
    s" Trebuchet MS" <FontFace
          BfSize  SfSize
          over lightSlateBlue HumiditySamples AverageSamples (f.2) <<FontSizeColor>>
          dup  lightSlateBlue s" &nbsp;%"   <<FontSizeColor>>  greenHr
          over Yellow      LdrSamples         AverageSamples (f.2) <<FontSizeColor>>
          dup  Yellow      (HtmlSpaceStart)   LightUnitOnly"      drop 1  ((inlude$))   <<FontSizeColor>>  greenHr
          over Green       PollutionSamples   AverageSamples (f.2) <<FontSizeColor>>
          dup  Green       (HtmlSpaceStart)   PollutionUnitOnly"  drop 1  ((inlude$))   <<FontSizeColor>>  greenHr
          over LtMangenta  PressureSamples    AverageSamples (f.2) <<FontSizeColor>>
          dup  LtMangenta  s" &nbsp;h" <<FontSizeColor>>  greenHr
          swap Red         TemperatureSamples AverageSamples (f.2) <<FontSizeColor>>
               Red         s" &nbsp;C"      <<FontSizeColor>>  greenHr
    </font> ;

: .GforthDriven_ ( - )
   vsFont $FEFFE6   s" <em>Gforth driven </em>" <<FontSizeColor>> ;

: BodyCombinedPlots ( - )
   \ GetViewport
   S5?
      if   SetSizesFixed
      else 50 70 SetSvgSizeRel SetSvgFonts
      then
   95 4 0 0 0 <table>  ( w% h% cellspacing padding border -- ) \ Table for the field set
   <tr> +HTML| <td align="right" rowspan="2">| .SensorValues    </td> \ 1. Cell on the left
        <td> 148 NearWhite s" &nbsp;" <<FontSizeColor>> </td>         \ 2. Cell in the middle
        <td> .CombinedPlot  </td>  ( 3. Cell on the right )   </tr>
   <tr>             \ 1. Got a cell here from ' rowspan="2" '
         <td> </td> \ 2. The next cell in the 2nd row is empty
        +HTML| <td align="right" valign="bottom">| .GforthDriven_ </td></tr> \ 3. 3rd cell on the right
   </table> ;

: x-label-time ( n - )  r>Time @ 100 / 4w.intHtml  ;

: Plot1Graph ( &item - )
   s" Verdana" <FontFace   #LastMin find-interval
   InitSvgPlot >r
   #X_Lines dup 1- r@ *  s>f to MaxXtop  #Max_Y_Lines   SetGrid
     r@  2dup fdup 4 pick  PlotDataLine
        -4 3   4 roll >color @ ['] Anchor-Justify-right  y-labels
     2dup swap s>f s>f f- ['] x-label-time
        color-x-labels  Rotation-x-labels  x-labels \ x-labels at the bottom
     r> +HTML| </svg> |
     2drop fdrop </font>  ;

: <FontTrebuchet ( - )   s" Trebuchet MS" <FontFace ;

: .DecscriptionPlot ( str cnt - )  DescrFont NearWhite 2swap <<FontSizeColor>> .HtmlSpace ;

: .Unit ( unit$ cnt Number$ cnt - ) ( f: Sample - )
   <FontTrebuchet
   SfSize Green  2swap <<FontSizeColor>>
   +HTML| &nbsp;|
   SfSize 70 % Green  2swap <<FontSizeColor>>
   </font> ;

: GraphHum ( - )
   &Humidity   Plot1Graph s" Humidity:"      .DecscriptionPlot
   s" %" HumiditySamples  AverageSamples (f.2)  .Unit ;

: GraphLight ( - )
   &Light Plot1Graph       Light"   [char] : addchar      .DecscriptionPlot
   LightUnitOnly" LdrSamples   AverageSamples (f.2) .Unit ;

: GraphPol ( - )
   &Pollution  Plot1Graph Pollution"   [char] : addchar  .DecscriptionPlot
   PollutionUnitOnly" PollutionSamples AverageSamples (f.2) .Unit ;

: GraphPres ( - )
   &Pressure Plot1Graph  s" Pressure:"       .DecscriptionPlot
   s" hPA" PressureSamples AverageSamples (f.2) .Unit ;

: GraphTemp ( - )
   &Temperature Plot1Graph  s" Temperature:" .DecscriptionPlot
   s" C" TemperatureSamples AverageSamples (f.2) .Unit ;

: BodySeparatePlots  ( - )
   30 35 SetSvgSizeRel SetSvgFonts
   WidthViewPort 90 %  HeightViewPort 75 %  0 0 0 <tablePx>  \ Table for the field set

      34 to BottomMargin 12 to RightMargin  52 to LeftMargin
      <tr><td> GraphHum   </td>
          <td> GraphLight </td>
          Pollution-  bInput@ if  <td> GraphPol   </td> then </tr>
      <tr><td> GraphPres  </td>
          <td> GraphTemp  </td>
          <td> .ShortAbstract 2<br> .GforthDriven_  </td></tr>
   </table> ;

: DetectS5 ( webpacket$ cnt - ) req-buf lcount s" Safari/534.30" search to S5? 2drop ;

: Dynpage ( w h xt -  ) 
   >r MapBme280Data 2>r DetectS5 GetViewport $0 to ColorOff   RefreshCmd
    +HTML|  <body style="background-color:#000000">|
    WidthViewPort 90 %  HeightViewPort 75 % 0 0 0 <tablePx> S5?  \ The Outer table. One cell is used
            if   <tdL> \ to left justfy
            else <td>  \ or to center
            then
          4 4 0 0 0 <table>  <tdL>   \ A table to prevent floating cells
             +HTML|  <fieldset style="width: 100%; height: 100%;">
             <legend>
                    [DEFINED] SitesIndexOpt  [IF]
                           <aHREF" s" /SitesIndex " #IndexSite <pagelink
                           +html 14 yellow <FontSizeColor> +HTML| Index |
                           </font> </a>
                   [THEN]
                <aHREF" homelink$ count +html +HTML| /home ">|
                14 yellow <FontSizeColor> hostname$ count +html </font> </a>
             </legend>
              2r>  InitDataParms SetLastDataPointsToSamples
                      r>   execute  \ For the text and plot inside the fieldset.
              UnMapBme280Data
             +HTML| </fieldset> |
          </font> </td> </table>
    </td> </table> </body> </html>  ;


\\\
