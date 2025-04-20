cr Marker SitesIndex.fs  .latest  \  Creates a master index
\ You need to adapt this file for your sites.

-1 value (pm25)  -1 value (Time_pm25)
: +pm25 ( - )
   (Time_pm25) 100 /mod mh>mh$ +html
   +HTML|  pm2.5: |  (pm25) s>f 100e f/ (f.2) +html ;

[defined] Bme280Sensor [if]
: (+.Inside) ( - )    GetTemperature +HTML| Inside: |  (n.1) +html  +HTML| <br>&nbsp;| ;
[else] : (+.Inside) ( - )  +HTML| Na <br>&nbsp;|  ;
[then]

defer (+.Outside) ' noop is (+.Outside)

[UNDEFINED]  (+.Nightmode) [IF]
: (+.Nightmode)  ( - ) ;
[THEN]

ALSO HTML

0 [if] If needed, change downloaded SVG files from https://www.svgrepo.com/ as follows:
       Insert: the width and height before  viewBox=".....
       So it could looks like: width="150" height="150" viewBox=".....
  [then]

: svg-link (  page$ cnt #server - ) \ '</svg>' should be the latest added string in the htmlpage$ buffer
  htmlpage$ lcount dup 20 - /string s" </svg>" capssearch
     if    nip negate htmlpage$ +!
     else  2drop cr ." </SVG> tag missing"
     then
  Tophref=" <pagelink +HTML
  +HTML| <rect x="0" y="0" width="100%" height="100%" style="fill:currentcolor;fill-opacity:0.0;stroke-opacity:0.5"|
  s" /> " pagelink>  +HTML| </svg> | ;

: NoteInputBox  ( - )
    +HTML| <td colspan="2" width="100%" align="center"> |
    <form>
            +HTML| <textarea maxlength="254" name="textarea" style="width:275px;height:90px;">|
                    s" note.txt" +hfile +HTML| </textarea>|
            2<BR>
           +HTML| <INPUT type="submit" class="btn" value="Save">  &nbsp;  &nbsp; <INPUT type="reset" class="btn" value="Reset">|
   </form>  </td>
 ;

true value SavedNote

: +Novalue<br-space> ( - )   +HTML| &nbsp;| <br-space> ;

create ShowActivity$ 12 allot s" Pc" ShowActivity$ place
0 value LightsDB


0e fvalue HumidityIncrease

: OnHumIncrease ( recv-pkt$ cnt -- recv-pkt$ cnt )
    2dup [char]  _ bl ExtractNumber?
       if     d>f fdup 0e f>
                if    100e f/   log" Rain?"
                else  0e
                then
       else   0e
       then
    to  HumidityIncrease ;

: +HumidityIncrease ( - )
   HumidityIncrease 0e f>
    if  <br>  +HTML| <font style="background-color:#0000FF" color = "#FFFFFF"> |
        <strong> .HtmlSpace +HTML| &#x1F327; +| HumidityIncrease (f.2) +html
                   +HTML| %| .HtmlSpace </strong> </font>
    else  <br-space>
    then ;

: <fieldset-style> ( - )  +HTML| <fieldset style=" border: 1px #6C7780 solid;border-radius: 3px;">| ;


: <<td-legend>>  ( legend$ cnt - ) <td> <fieldset-style>
   HTML| <font size="2">| upad place
   s" <strong>"  upad +place
   upad +place  s" </strong>"  upad +place s" </font>" upad +place upad count  <<legend>>  ;

: <</td-legend>> ( - )             </fieldset>  </td> ;



s" Documents/LinksSitesIndex.fs" file-status nip 0= [IF]

NEEDS Documents/LinksSitesIndex.fs \ To load your own links for Links-first-row and Links-second-row

[ELSE]

: .SoundSystem ( - )
\       File-SVG-pictogram                    Points to page    ServerId   link
        s" Home theater" <<td-legend>>
          s" sound-system-svgrepo-com.svg" +hfile  s" /home"      0       svg-link
\     s" App/sound-system-svgrepo-com.svg" +hfile  s" /home"      0       svg-link \ Case: own app
          <br>  ShowActivity$ count +HTML <br>  (PM25) 0>
                if    +pm25
                else  .HtmlSpace
                then
    <</td-legend>> ;

: .History ( - )
    s" History" <<td-legend>>
           s" thermometer-svgrepo-com.svg"  +hfile  s" /home"   FindOwnId   svg-link
           (+.Inside)  (+.Outside)
    <</td-legend>> ;

: .CentralHeating ( - )
    s" Central heating"  <<td-legend>>
           s" thermostat-svgrepo-com.svg"   +hfile  s" /Ch%20menu" FindOwnId svg-link
              [defined] CentralHeating
                      [if]   (+.Nightmode)
                      [else] <br> .HtmlSpace <br>  .HtmlSpace <br>
                      [then]

    <</td-legend>> ;

: .on/off-html ( flag - )
    if    +HTML| On|
    else  +HTML| Off|
    then <br>
 ;

: .ControlLights ( - )
    s" Lights"  <<td-legend>>
           s" light-bulb-svgrepo-com.svg"   +hfile  s" /LightsControl" FindOwnId svg-link
           [DEFINED] ControlLights [IF]
           eval-light-net .on/off-html  i_sleep_lights bInput@
               if    +HTML| Sleeping |
               else  i_Manual_lights bInput@ 0=
                    if     +HTML| Automatic|
                    else   +HTML| Manual|
                    then
               then
            [ELSE]   +HTML| Off| <br> +HTML| Manual|  .HtmlSpace
            [THEN]

    <</td-legend>> ;


: .ControlWindow ( - )
    s" Window"  <<td-legend>>
           s" window-svgrepo-com.svg"       +hfile  s" /WindowControl" FindOwnId svg-link
           [DEFINED] ControlLights [IF]
           i_window_Automatic bInput@
                 if  eval-wnd-net
                      if    +HTML| Open|
                      else  +HTML| Close|
                      then  <br> +HTML| Automatic|
                 else  +HTML| Manual| <br> .HtmlSpace
                 then
                    ( +HumidityIncrease )
           [ELSE]   +HTML| Off| <br> +HTML| Manual|   .HtmlSpace
           [THEN]
    <</td-legend>> ;


: Links-first-row ( - )
\ A page with links to an option or device.
\ It uses ServerId's that are created in autogen_ip_table.fs
\ To see a list try: .servers
\ Each link uses one cell in a html-table consisting of:
\ 1) A SVG-pictogram with a link to the page of the option/device.
\ 2) 2 lines of additional text.
    .SoundSystem
    .History
    .CentralHeating
    .ControlLights
    .ControlWindow   ;


: .Linux ( - )
    s" Linux"  <<td-legend>>  \ A linux PC
    s" linux-svgrepo-com.svg"           +hfile  s" /home"          9  svg-link
    <</td-legend>> ;

: .Administration ( - )
    s" Rpi Administration"  <<td-legend>>
    s" administrator-work-svgrepo-com.svg" +hfile s" /Admin"       FindOwnId  svg-link
    <</td-legend>> ;

: .Editnote ( - )
    s" Edit note"  <<td-legend>>
    s" document-svgrepo-com.svg"   +hfile  s" /ModifyNote"         FindOwnId  svg-link
    <</td-legend>> ;

: .SavedNote ( - )
    SavedNote
        if    2 <#tdC>  s" note.txt" +hfile   <br>
              </td>
        else  NoteInputBox
        then ;

: Links-second-row ( - )
   .Linux
   .Administration
   .Editnote
   .SavedNote ;

[THEN]

: Links-to-pages ( - ) \ Most visited pages. Should be adapted for your site.
        +HTML| <table  style=" border-spacing: 15px 0; border-collapse: separate;"|
        +HTML| border="0" cellpadding="0" height="100%" width="100%" >|
        Links-first-row
        <tr>  4 <#tdL> .HtmlSpace <td> </tr> \ seperator
        Links-second-row   ;

: <HtmlLayoutSitesIndex> ( legendtxt$ cnt bgcolor Border - )
   htmlpage$ off <html5> <html> <head> <<NoReferrer>>
   s" Main index"   Html-title-header CssStyles </head> 3tables ;


: .SitesIndex ( - )
   htmlpage$ off  \ First used as a temporary buffer.
   <aHREF" +homelink  +HTML| /Schedule">| +HTML| <strong> Schedule</strong>| </a>
   +HTML|  Main index |  htmlpage$ lcount pad place
   pad count NearWhite 0 <HtmlLayoutSitesIndex> \ Starts a table at htmlpage$ with a legend
    Links-to-pages
    <tr> 4 <#tdL>
            +HTML| Favorites: |
            s" https://www.novabbs.com/devel/thread.php?group=comp.lang.forth" s" Clf" <<TopLink>> .HtmlSpace
            s" https://www.facebook.com/"                   s" Faceb."            <<TopLink>> .HtmlSpace
            s" https://github.com/Jos-Ven?tab=repositories" s" Git JV"            <<TopLink>> .HtmlSpace
            s" https://www.rosettacode.org/wiki/Category:Forth" s" Rosetta Forth" <<TopLink>> .HtmlSpace
            s" https://www.taygeta.com/fsl/sciforth.html"   s" SciForth"          <<TopLink>>
         <br> +Arplink s" /UpdateLinksIndex"  Sitelinks  \ Takes time
         </td>
     +HTML| <td align="right" valign="bottom">|  .GforthDriven  </td> </tr> </table>
    <EndHtmlLayout>  ;

: SaveNote ( adr n -  )
    254 min DecodeHtmlInput dup 0>
       if    s" note.txt" r/w create-file  drop dup>r
             write-file drop r> CloseFile true to SavedNote
       else  2drop
       then
     ;

s" note.txt" file-status nip
  [if]
   s" note.txt" r/w create-file  drop
         s" -" 2 pick write-file drop CloseFile
  [then]


PREVIOUS

' (SitesIndex) is SitesIndex \ Makes the index link visible

TCP/IP DEFINITIONS

: /SitesIndex  ( - )  ['] .SitesIndex set-page ;
' /SitesIndex         alias /UpdateLinksIndex

: /ModifyNote  ( - )  SavedNote not to SavedNote /SitesIndex ;
: textarea     ( <HtmlTxt>- )  parse-name SaveNote /SitesIndex ;

: Gforth::HumIncrease ( - ) udpin$ lcount OnHumIncrease Ignore-remainder ;
: Gforth::LightsON    ( - ) udpin$ lcount  SendConfirmation true  to LightsDB Ignore-remainder ;
: Gforth::LightsOFF   ( - ) udpin$ lcount  SendConfirmation false to LightsDB Ignore-remainder ;


FORTH DEFINITIONS

\s
