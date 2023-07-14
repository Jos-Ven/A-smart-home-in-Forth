cr Marker SitesIndex.fs  .latest  \  Creates a master index

needs sitelinks.fs

0 [IF]

NOTES:
sitelinks.fs is now build for _SensorWeb1.fs
#IndexSite   in sitelinks.fs    points to the ID of the server that contains an index of all sites.
MARKER SitesIndexOpt     \ to activate the index sites page
MARKER AdminPage         \ Is also needed
You need to adapt it for your sites.

[THEN]

ALSO HTML

: svg-link (  page$ cnt #server - ) \ '</svg>' should be the latest added string in the htmlpage$ buffer
  htmlpage$ lcount dup 20 - /string s" </svg>" capssearch
     if    nip negate htmlpage$ +!
     else  2drop cr ." </SVG> tag missing"
     then
  Tophref=" <pagelink +HTML
  +HTML| <rect x="0" y="0" width="100%" height="100%" style="fill:currentcolor;fill-opacity:0.0;stroke-opacity:0.5"|
  s" /> " pagelink>  +HTML| </svg> | ;

0 [if] Change downloaded SVG files from https://www.svgrepo.com/ as follows:
       Insert: the width and height before  viewBox=".....
       So it could looks like: width="150" height="150" viewBox=".....
  [then]

: NoteInputBox  ( - )
    +HTML| <td <td colspan="3" width="100%" align="center"> |
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

: 5cLine    ( - )    <tr>  5 <#tdC>  Blue 3 <hr> </td>  </tr>  ;

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

: +Dashboard ( - )
   5cLine
   <tr>
\       <td>  ShowActivity$ count +HTML <br-space>    </td>
       <td>  ShowActivity$ count +HTML <br>  (PM25) 0>
                if    +pm25
                else  .HtmlSpace
                then  </td>
       <td>  (+.Inside)  (+.Outside)  </td>
       <td> (+.Nightmode)           </td>
       <td> +HTML| Lights:| LightsDB
              if    +HTML| On|
              else  +HTML| Off|
              then
            <br-space>   </td>
       <td> (+.Window)
        +HumidityIncrease </td>
   </tr>
   5cLine ;


: Links-to-pages ( - ) \ Most visited pages. Should be adapted for your site. See .servers for the ServerId
    100 100 0 4 0 <table>    ( w% h% cellspacing padding border -- )
\ NwLine NwCell  File-SVG-pictogramm           Points to page  ServerId        EndCell

   <tr>
     <td>  s" sound-system-svgrepo-com.svg" +hfile  s" /home"       0  svg-link </td>
     <td>  s" thermometer-svgrepo-com.svg"  +hfile  s" /home"       1  svg-link </td>
     <td>  s" thermostat-svgrepo-com.svg"   +hfile  s" /CV%20menu"  1  svg-link  </td>
     <td>  s" light-bulb-svgrepo-com.svg"   +hfile  s" /topframe.html?93=Extra" 0 svg-link </td>
     <td>  s" window-svgrepo-com.svg"       +hfile  s" /home"       2  svg-link </td>
           </td>
   </tr>
   +Dashboard
   <tr>
     <td>  s" linux-svgrepo-com.svg"        +hfile  s" /home"       9  svg-link  </td>   \ A linux PC
     <td>  s" administrator-work-svgrepo-com.svg" +hfile s" /Admin" 1  svg-link  </td>
     <td>  s" document-svgrepo-com.svg"     +hfile  s" /ModifyNote" 1  svg-link  </td>
   SavedNote
        if   s" note.txt"  3   <#tdC>   +hfile </td>
        else   NoteInputBox
        then
   </tr> </table> ;


: .SitesIndex ( - )
    s" Main index " NearWhite 0 <HtmlLayout>    \ Starts a table in a htmlpage with a legend
    <td> Links-to-pages   </td>
    <tr> +HTML| <td align="left" valign="bottom">|
            +HTML| Favorites: |
            s" https://groups.google.com/g/comp.lang.forth" s" Clf"           <<TopLink>> .HtmlSpace
            s" https://www.facebook.com/"                   s" Fb"            <<TopLink>> .HtmlSpace
            s" https://github.com/Jos-Ven?tab=repositories" s" Git JV"        <<TopLink>> .HtmlSpace
            s" https://rosettacode.org/wiki/Category:Forth" s" Rosetta Forth" <<TopLink>> .HtmlSpace
            s" https://www.taygeta.com/fsl/sciforth.html"   s" SciForth"      <<TopLink>>
         <br> +Arplink s" /UpdateLinksIndex"  Sitelinks
         </td>
    +HTML| <td align="right" valign="bottom">| .GforthDriven </td></tr>
    <EndHtmlLayout> ;

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
: /ModifyNote  ( - )    SavedNote not to SavedNote /SitesIndex ;
: textarea     ( <HtmlTxt>- )  parse-name SaveNote /SitesIndex ;

: Gforth::HumIncrease ( - ) udpin$ lcount OnHumIncrease Ignore-remainder ;
: Gforth::LightsON  ( - ) udpin$ lcount  SendConfirmation true  to LightsDB Ignore-remainder ;
: Gforth::LightsOFF ( - ) udpin$ lcount  SendConfirmation false to LightsDB Ignore-remainder ;


FORTH DEFINITIONS

\s
