marker webcontrols.f          \ 24-05-2024 webcontrols.f by J.v.d.Ven
Needs  Web-server-light.f     \ Contains the htmlpage$ buffer
Needs TimeDiff.f

\ Tags added to the buffer in htmlpage$:

VOCABULARY HTML also HTML HTML DEFINITIONS \ For all html controls/tags

: >|          ( -- ) +HTML| >| ;
: ">          ( -- ) +HTML| ">| ;
: .Html       ( n -- )   (.) +html ;
: .fHtml      ( f: n - ) (f.2) +html ;
: +1html      ( char -- )  sp@ 1 +html drop ;
: +crlf       ( -- ) crlf" +html ;
: <body>      ( -- ) +HTML| <body>| ;
: </body>     ( -- ) +HTML| </body>| ;
: <br>        ( -- ) +crlf +HTML| <br>|  ;
: <br-space>  ( -- ) <br> +HTML| &nbsp;| ;
: 2<br>       ( -- ) <br> <br> ;
: <aHREF"     ( -- ) +HTML| <a href="| ;
: </a>        ( -- ) +HTML| </a>| ;
: <center>    ( -- ) +HTML| <center>| ;
: </center>   ( -- ) +HTML| </center>| ;
: </div>      ( -- ) +HTML| </div>| ;
: <fieldset>  ( -- ) +HTML| <fieldset>|  ;
: </fieldset> ( -- ) +HTML| </fieldset>| ;
: </font>     ( -- ) +HTML| </font>| ;
: <form>      ( -- ) +HTML| <form>| ;
: </form>     ( -- ) +HTML| </form>| ;
: <FormAction>	( actiontxt cnt -- ) +html| <form action="| +html  [char] " +1html ;
: <h2>		( -- ) +HTML| <h2>| ;
: </h2>		( -- ) +HTML| </h2>| ;
: <h3>		( -- ) +HTML| <h3>| ;
: </h3>		( -- ) +HTML| </h3>| ;
: <h4>		( -- ) +HTML| <h4>| ;
: </h4>		( -- ) +HTML| </h4>| ;
: <head>      ( -- ) +HTML| <head>|  ;
: </head>     ( -- ) +HTML| </head>| ;
: <html>      ( -- ) +HTML| <html lang="en">| ;
: </html>     ( -- ) +HTML| </html>| ;
: <legend>    ( -- ) +HTML| <legend>|  ;
: </legend>   ( -- ) +HTML| </legend>| ;
: <p>         ( -- ) +crlf +HTML| <p>|  ;
: </p>        ( -- ) +crlf +HTML| </p>|  ;
: <span>      ( -- ) +HTML| <span>| ;
: </span>     ( -- ) +HTML| </span>| ;
: <strong>    ( -- ) +HTML| <strong>|  ;
: </strong>   ( -- ) +HTML| </strong>| ;
: <style>     ( -- ) +HTML| <style>|  ;
: </style>    ( -- ) +HTML| </style>| ;
: <sup>       ( -- ) +HTML| <sup>|  ;
: </sup>      ( -- ) +HTML| </sup>| ;
: </table>    ( -- ) +HTML| </table>| ;
: <td>        ( -- ) +crlf +HTML| <td valign="center" align="center">| ;
: <tdCTop>    ( -- ) +crlf +HTML| <td valign="top" align="center">| ;
: <tdL>       ( -- ) +crlf +HTML| <td valign="center" align="left">|  ;
: <tdLTop>    ( -- ) +crlf +HTML| <td valign="top" align="left">|  ;
: <tdR>       ( -- ) +crlf +HTML| <td valign="center" align="right">| ;
: </td>       ( -- ) +HTML| </td>| ;
: </td><td>   ( -- ) </td> <td> ;
: </td><tdL>  ( -- ) </td> <tdL> ;
: <title>     ( -- ) +HTML| <title>| ;
: </title>    ( -- ) +HTML| </title>| ;
: </tr>       ( -- ) +HTML| </tr>| ;
: <tr>        ( -- ) +HTML| <tr>|  ;
: <tr><td>    ( -- ) <tr> <td> ;
: <tr><tdL>   ( -- ) <tr> <tdL> ;
: <tr><tdR>   ( -- ) <tr> <tdR> ;
: </td></tr>  ( -- ) </td> </tr> ;
: <ul>        ( -- ) +HTML| <ul>| ;
: </ul>       ( -- ) +HTML| </ul>| ;

\ Further extensions:
: .HtmlSpace  ( - ) +HTML| &nbsp;| ;
: .HtmlBl     ( - ) +HTML|  | ;
: NoName>     ( - ) +HTML|  name="nn"> | ;

: hold"    ( - ) [CHAR] " hold ;
: hold"bl  ( - ) bl hold hold" ;
: SignedDouble ( n - sign dabs ) s>d tuck dabs ;
: "."   ( n - "n" cnt )   SignedDouble <# hold"bl  #s  rot sign  hold" #> ;
: ".%"  ( n - "n%" cnt )  SignedDouble <# hold"bl  [char] % hold  #s  rot sign  hold" #> ;
: ".px" ( n - "npx" cnt ) SignedDouble <# [char] x hold [char] p hold #s  rot sign #> ;

: h6#  ( sign d - ) base @ >r hex  # # # # # #  r> base !  ;

: (H6.)  ( n - 6hex cnt )  SignedDouble <#  h6# rot sign #>  ;

: "#h." ( n - "#6hexnum"$ cnt ) \ format for a color. Eg: Blue="#0000FF"
    SignedDouble <# hold"bl h6# rot sign  [char] # hold  hold" #> ;

: (#h.) ( n - #6hexnum$ cnt )   \ format for a color. Eg: Blue=#0000FF
    SignedDouble <# h6# rot sign [char] # hold #> ;

: (h.)    ( n -- hexnum$ cnt )
    SignedDouble <#  base @ >r hex #s  r> base !  rot sign  #> ;

: <<td>>     ( str cnt - )     <td> +html </td> ;
: <<strong>> ( str cnt - ) <strong> +html </strong> ;
: <<label>> ( label-name - ) +HTML| <label for="| +HTML  +HTML| "> </label>| ;
: <<legend>> ( str cnt - ) <legend> +html </legend> ;
: <<Link>>   ( LinkAdr cnt text cnt - ) <aHREF" 2swap +HTML "> +HTML </a> ; \ For simple links

: <<TopLink>>	( LinkAdr cnt text cnt - )
   +HTML| <a target="_top" href="|  2swap +HTML +HTML| ">|
   +HTML +HTML| </a> | ;

: aria-label>  ( - ) +HTML|  aria-label="nn">| ;

: <select  ( name cnt size  - )
   +crlf -rot +HTML| <SELECT NAME="| +HTML
    +HTML| " SIZE=| "." 1- +HTML aria-label> ;

: </select> +crlf +HTML| </SELECT>| ;



: <option> ( text cnt index DropDownDefault - )
   +crlf +HTML| <OPTION |
      if  +HTML| SELECTED |
      then
    +HTML| VALUE=| "." 1- +HTML >|   +HTML  +HTML| </option> | ;


: Upc-BlankDashes ( adr cnt - )
   over dup c@ upc swap c! \ Uppercase 1st char
   s" -" BlankStrings ;    \ Remove dashes

: <<option-cap>> ( adr cnt index chosen - )
   over =
   +crlf +HTML| <OPTION |
      if  +HTML| SELECTED |
      then
    +HTML| VALUE=| "." 1- +HTML >|
    htmlpage$ lcount + over 2>r +HTML
    2r> Upc-BlankDashes
   +HTML| </option> | ;


: <FontSizeColor> ( pxSize RgbColor - )
   +HTML| <font color=| "#h." +html
   +HTML| style="font-size:| .Html +HTML| px" >|  ;

: <FontFace  ( name cnt - ) +HTML| <font face="| +html +HTML| ">|  ;

create Small$ 40 allot
: <<FontSizeColor>> ( pxSize RgbColor string cnt - )
   Small$ place <FontSizeColor> Small$ count +html </font> ;

: <hr>        ( color size -- )
   +HTML| <hr size=|  "." +html
   +HTML| width="100%" color=| "#h." +html >| ;

: <hrWH>      ( color w h -- )
   +HTML| <hr size=|  "." +html
   +HTML| width=| "." +html   +HTML| px" color=| "#h." +html >| ;

: <#td ( #HtmlCells - )
      +crlf +HTML| <td colspan= | dup "." +html
      +HTML| width=| 100 swap / 1 max ".%" +html ;

: <tdColor    ( color -- )
     +crlf +HTML| <td valign="center" align="center" bgcolor= |
     "#h." +html  ;

: <tdColor>    ( color -- ) <tdColor >| ;

: <<#td>>   ( n - )      <#td </td> ;
: <#tdC>    ( n - )  <#td +HTML| align="center"> | ;
: <#tdL>    ( n - )  <#td +HTML| style="text-align:left"> | ;
: <#tdR>    ( n - )  <#td +HTML| style="text-align:right"> | ;
: +</td>    ( str cnt - ) +html  </td> ;


\ Elememtary colors
$000000 constant Black
$0000FF constant Blue
$00FF00 constant Green
$FF0000 constant Red
$FFFF00 constant Yellow
$DEDE00 constant DkYellow
$FFFFFF constant White

\ Other
$8080FF constant lightSlateBlue
$A0A0FF constant ltBlue

$999999 constant DkGreen
$CCAACC constant LtMangenta
$CC22CC constant DkMangenta
$FEFFE6 constant NearWhite  \ Very pale (mostly white) yellow.
                            \ See https://www.colorhexa.com/feffe6

$4646FF constant ColorOn
$444444 value    ColorOff
$444444 constant Grey4
$7F7F7F constant Grey5
$BFBFBF constant Grey6
$e7e7e7 constant ButtonWhite

: <tdBlack>    ( -- ) Black <tdColor> ;
: <tdCec>      ( -- ) Grey4    <tdColor> ;
: <tdHL>       ( -- ) Grey5    <tdColor> ;
: <BgOff>      ( -- ) ColorOff <tdColor> ;
: <BgON>       ( -- ) ColorOn  <tdColor> ;
: <TdBg>       ( flag - )  if  <BgON>  else  <BgOff>  then ;
: EmptyCell    ( - )  <td>      </td> ;
: BlackCell    ( - )  <tdBlack> </td> ;

: <tdCols>     ( w% colspan -- )
  +HTML| <td colspan=| "."  +html
  +HTML|  width=| ".%" +html >|  ;

0  value bordercolor
0  value bordercolordark
0  value bordercolorlight
-1 value bgcolorTable  \ 0< means not in use

: SetColorsTableBorders ( bordercolorlight bordercolordark bordercolor - )
   to bordercolor to bordercolordark to bordercolorlight ;

: +tableColors ( - )
   +HTML| bordercolor=|      bordercolor      "#h." +html
   +HTML| bordercolordark=|  bordercolordark  "#h." +html
   +HTML| bordercolorlight=| bordercolorlight "#h." +html
   bgcolorTable 0>=
     if +HTML| bgcolor=|     bgcolorTable     "#h." +html
     then ;

: <table ( cellspacing padding border -- )
  +HTML| <table border=| dup "." +html
     if   +tableColors
     then
  +HTML| cellpadding=| "." +html
  +HTML| cellspacing=| "." +html ;

: <table> ( w% h% cellspacing padding border -- )
  <table
  +HTML| height=| ".%" +html
  +HTML| width=|  ".%" +html  >| ;

: <tablePx> ( wPx hPx cellspacing padding border -- )
  <table
  +HTML| height=| "." +html  .HtmlBl
  +HTML| width=|  "." +html  >| ;

: <button> ( btntxt cnt  cmd cnt - ) \ The btntxt and the btnCmd will be received in the request
  +HTML| <button type="submit" NAME="| +html
  +HTML| " VALUE="| 2dup +html  +HTML| "|
  +HTML|  class="btn ">|  +html
  +HTML| </button>| ;

: <StyledButton> ( BackgrColor FontColor  btntxt cnt  cmd cnt - )
  +HTML| <button type="submit" NAME=| +html
  +HTML|  VALUE="| 2dup +html  +HTML| "|
   2swap +HTML|  style="background-color:#|
   swap (H6.) +html  +HTML| ; color:#| (H6.) +html
  +HTML| " ; class="btn">|  +html
  +HTML| </button>| ;

: <GreyBlackButton>  ( value$ btntxt cnt cmd cnt  - )
   2>r 2>r Grey6 black  2r> 2r> <StyledButton> ;

\ <Btn starts a css-button. The content of the value is used as keyword in Forth.
\ The value name 'nn' needed in the browser is ignored in Forth.
: <Btn    ( btnCmd cnt - ) +html| <button type="submit" NAME="nn" VALUE="| +html  [char] " +1html ;
: Btn>    ( btntxt cnt - ) +html  +html| </button>| ;

: nn" ( - adr cnt ) s" nn" ;

: <CssButton> ( btntxt cnt btnCmd cnt - )  \ btntxt van be the same as btnCmd
   <Btn  +html| " class="btn"  style="background-color:#BFBFBF">|  Btn> ;    \ ONLY the btnCmd will be received in the request

: <CssBlueButton> ( btntxt cnt btnCmd cnt - )
   <Btn +html| " class="btn" style="background-color:#A0A0FF">| Btn> ;

: <CssBlue|GrayButton> ( btntxt cnt btnCmd cnt colorflag - )
      if   <CssBlueButton>
      else <CssButton>
      then ;

: <SmallButton>   ( btntxt cnt cmd cnt - ) \ For a small CSS button
     <Btn
      +html| "  style="padding: 1px 10px; font-size: 16px";  class="btn">|
     Btn> ;


: NameValueForm> ( value$ cnt name cnt - )  <button> +HTML| </FORM></td>| ;
: FormTarget ( - ) +crlf +crlf +HTML| <FORM method="get" action="topframe.html" target=| ;
: <FormTop   ( - )  FormTarget +HTML| "top"> |  ;
: <Formclr   ( - )  FormTarget +HTML| "_top"> | ;


: "BtnBg  ( name cnt val$ cnt - )  2swap <FormTop <td>      NameValueForm> ; \ OK
: "BtnHL  ( name cnt val$ cnt - )  2swap <FormTop <tdHL>    NameValueForm> ; \ Nok
: "BtnBlk ( name cnt val$ cnt - )  2swap <FormTop <tdBlack> NameValueForm> ;
: "BtnClr ( name cnt val$ cnt - )  2swap <Formclr <td>      NameValueForm> ;

: "Btn1/0 ( flag name cnt val$ cnt  - )
   2>r here place here count  +HTML| <form action="|  +homelink
   +HTML| /Start" target="_top"> |
   rot <TdBg> 2r> 2swap NameValueForm> ;

: "BtnHL1/0  ( flag name cnt val$ cnt  - )
     ColorOff >r Grey5 to ColorOff "Btn1/0 r> to ColorOff ;

\in-system-ok : BtnBg"  ( name cnt <value$"> - )   postpone s" postpone "BtnBg  ; immediate
\in-system-ok : BtnClr" ( name cnt <value$"> - )   postpone s" postpone "BtnClr ; immediate
\in-system-ok : BtnHL"  ( name cnt <value$"> - )   postpone s" postpone "BtnHL  ; immediate
\in-system-ok : BtnBlk" ( name cnt <value$"> - )   postpone s" postpone "BtnBlk ; immediate
\in-system-ok : Btn1/0" ( f name cnt <value$"> - ) postpone s" postpone "Btn1/0 ; immediate
\in-system-ok : BtnHL1/0" ( f name cnt <value$"> - ) postpone s" postpone "BtnHL1/0 ; immediate


: <Radiobutton ( name$ cnt value$ cnt - )
   +HTML| <input type="radio" name="|  2swap +html
   +HTML| " value="| +html +HTML| "| ;

: ?Checked> ( RadioButtonState RadioButtonId - )
    = if   +HTML|  checked|
      then aria-label> ;

: DoBell    ( -- htmlpage$ lcount )  s" Bell" place-last-html-cmd beep  ;
: GetHtmlInputValue      ( string$ cnt - d1 flag )   [char] =  bl ExtractNumber? ;
: ExtractNumberBetween=& ( pkt cnt -  d1 flag ) [char] = [char] & ExtractNumber? ;

: FindValue=&  (  pkt cnt str cnt - n flag )
   search
     if    ExtractNumberBetween=& nip
     else  0 0
     then ;

: <InputNumber           ( min max size default - ) \ Starting a spinner
   +HTML| <input type="number" value=| "." +html
   +HTML| size=| "." +html
   +HTML| max=| "."  +html
   +HTML| min=| "."  +html
   +HTML| step="1" | ;

\ EG:         0 999999 6 1449 <InputNumber +HTML| name="MinVersion"/>|
\ Produces:  <input type="number" value="1449" size="6" max="999999" min="0" step="1" name="MinVersion"/>

: <input-text> ( HtmlName$ cnt HtmlValue$ cnt size - )
   >r +HTML| <input type="text"style="text-align:center"NAME="| 2swap +HTML
   +HTML| "VALUE="| +HTML
   r>  +HTML| "SIZE="| .html  ">  ;

: .HtmlZeros  ( n - ) 0 ?do +HTML| 0| loop ;

: +HtmlNoWrap { adr cnt -- }      \ Replaces spaces by '&nbsp;' will ensure
   adr cnt + adr                  \ that a long string will be shown in one line.
      ?do   i c@ bl =             \ A small table will be enlarged.
            if    .HtmlSpace
            else  i 1 +HTML
            then
      1 +loop ;

: .HtmlSpaces ( n - )
    abs dup 2 <
      if    drop .HtmlBl
      else  0
            ?do .HtmlSpace
            loop
      then ;

: <EmptyParaGraph> ( - ) <p>  .HtmlSpace </p> ;
: <EmptyLine>      ( - ) <br> .HtmlSpace <br> ;

: (u.r)Html  ( u w -- adr cnt )
    0 swap >r (d.) r> over - 0 max .HtmlZeros  upad place upad"  ;

: 4w.intHtml   ( n - )       4 (u.r)Html +html ;
: f.2HtmlCell  ( F: f - )    <tdR> (f.2) +html </td> ;
: f.3HtmlCell  ( F: f - )    <tdR> (f.3) +html </td> ;
: 4w.HtmlCell  ( n - )       <tdR> 4w.intHtml  </td> ;
: TypeHtmlCell ( adr cnt - ) <tdR> +html       </td> ;

: <FormBox> ( legend$ cnt flag - )
   +crlf +HTML| <form style="background-color:|
      if   ColorOn
      else ColorOff
      then
   (#h.) +html
   +HTML| "><fieldset><legend>|   +html
   +HTML| </legend>| ;


: </FormBox>  ( - ) +crlf +HTML| </fieldset></form>| ;

: <doctype4.01>  ( - ) \ for frames
   +HTML| <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN"|
   +HTML| "http://www.w3.org/TR/html4/frameset.dtd">| ;

: <html5>   ( - )  +HTML| <!DOCTYPE html>| ; \ html5

: (+TimePicker$) ( hhmmss  - adr$ cnt )  10000 /mod [char] T  +## 100 / [char] : +##  utmp"  ;
: TimePicker$    ( hhmmss  - adr$ cnt )  utmp$ off  (+TimePicker$) 1 /string ;
: DatePicker$ ( hhmmss yyyymmdd - adr$ cnt )
    utmp$ off 10000 /mod (.) +utmp$   100 /mod  [char] - +##  [char] - +## (+TimePicker$) ;


: <<HiddenInput>>  ( adrName cnt adrValue cnt - )
   +HTML| <input type="hidden" name="|   +HTML  +HTML| "VALUE="| +HTML "> ;

\ Eg: 171612 20161023  DatePicker$ type abort \ 2016-10-23T17:16


: <InputTime> ( name& cnt  hhmm - )
   100 * >r  2dup <<label>>
   +HTML| <input type="time" value="| r> TimePicker$ +HTML  +HTML| "|
   2dup +HTML|  2dup id="| +HTML  +HTML| " name="|   +HTML "> ;

: ExtractTime ( adrBuffer cnt - time|ior )  \ EG: s" 23%3A59" ExtractTime for 23:59
   2dup [char] % extract$ s>number? >r d>s 100 *
   -rot  s" 3A" search drop 2 /string s>number?  r> and
   if    d>s +
   else  3drop -1
   then ;


: HomeLink ( - ) \ To be used inside a fieldset
   <aHREF" +homelink +HTML| /home "| aria-label> hostname$ count <<strong>> </a> ;

:  .px; ( n - ) ".px" +html +HTML| ;| ;

: +cssButton{  ( WidthButtonPx FontSizePx - )
     +crlf
        +HTML| .btn {|
         +crlf +HTML| display: block; |
         +crlf +HTML| background-color: #e7e7e7;|
         +crlf +HTML| border: none;|
         +crlf +HTML| color: black;|
         +crlf +HTML| padding: 5px 1px;|
\         +crlf +HTML| margin: 4px 2px;|
         +crlf +HTML| text-align: center;|
         +crlf +HTML| text-decoration: none;|
         +crlf +HTML| display: inline-block;|
         +crlf +HTML| cursor: pointer;|
         +crlf +HTML| border-radius: 15px;|
         +crlf +HTML| font-size: | .px;
         +crlf +HTML| width: |     .px;

         +crlf +HTML| background-color: #e7e7e7; |
         +crlf +HTML| box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.5); |
         +crlf +HTML| cursor: pointer; } |

         +crlf +HTML| .btn:active { |
         +crlf +HTML| top: 2px; |
         +crlf +HTML| left: 1px; |
         +crlf +HTML| box-shadow: none;  |
 ;

: }|             ( - )    +crlf +HTML|  }| ;
: +cssButton{}   ( WidthButtonPx FontSizePx - ) +cssButton{ }| ;

: +cssButtonData ( WidthButtonPx FontSizePx - )
      +cssButton{  +crlf +HTML| margin: 6px 4px;|   }| ;

16000 constant //HtmlPage-layout-reserved
/HtmlPage //HtmlPage-layout-reserved - constant //HtmlPage

: LoadDataFile ( At$ hndl - )                      \ Load a complete file when it fits OR
   dup>r file-size throw d>s  //HtmlPage  2024 - 2dup > \ only the last part when it does not fit
        if     - s>d r@ reposition-file throw
              upad maxcounted r@ read-line throw 2drop
        else  2drop
        then
   //HtmlPage  r@ read-file throw
   r> CloseFile htmlpage$ +! ;

: IncludeFile ( title$ cnt filename cnt - )
   r/w bin open-file throw >r
   (date) +html s" , " +html (time) +html 1 spaces$ +html  +html \ include the title
    +HTML| <pre>|  htmlpage$ lcount +   \ Start reading at
     r> LoadDataFile   +HTML| </pre>|
     <aHREF" +homelink +HTML| /home">| +HTML| Home| </a> ;

: +hfile ( filename cnt - )
   r/w bin open-file throw >r   htmlpage$ lcount +   r> LoadDataFile ;

: LoadHtmlFile ( title$ cnt filename cnt - )
   <yellow-page IncludeFile
   yellow-page> ;

: DecodeHtmlChar { adr --  char #UsedInput } \ limited version
  adr c@
      case
        [char] +  of  bl 1 endof
        [char] %  of  adr  1+ c@ upad c!   adr 2 + c@ upad 1+ c!
                      upad 2 base @ >r hex s>number?
                         if    d>s 3
                         else  2drop bl 1
                         then r> base ! endof
                 1 over
      endcase ;

: DecodeHtmlInput ( adr n  - out cnt )
    utmp$ off  bounds
      do   i DecodeHtmlChar swap sp@ 1 +utmp$ drop
      +loop
    utmp" ;

: logFile"    ( - adr$ cnt )    s" web.log"  Add/Tmp/Dir ;

: PageLogs   ( - )   s" Last part of the logfile: " logFile" LoadHtmlFile ;
: Comment"   ( - adr cnt ) s" <strong> Comment: </strong>" ;

: Html-title-header ( title$ cnt - )
    <title> hostname$ count +HTML space" +HTML +HTML </title>
    +HTML| <meta http-equiv="Content-Type"|
    +HTML|  content="text/html; charset=utf-8">|
    +HTML| <meta name="viewport" content="width=device-width, initial-scale=1">|
    ;

: svg_style-header ( - )
    +HTML| #svgelem{ |
    +HTML| position: relative; |
    +HTML| left: 2%; } |
    +HTML| fieldset { border:2px solid green;} | ;

: CssStyles ( - )    
   +HTML| <style> | svg_style-header
    s" a:link, a:visited {  cursor: pointer; } " +HTML
   95 14 +cssButton{}   \ Round buttons
   +HTML|  fieldset { border:2px solid black } |
   +HTML| .vertslidecontainer [type="range"][orient="vertical"] { |
     +HTML| height: 200px; |
     +HTML| width: 70px; |
     +HTML| cursor: pointer; |
     +HTML| writing-mode: bt-lr; |
     +HTML| appearance: slider-vertical; } |

   +HTML| </style> | ;

: +AppVersion ( Version -  MayorVs.MinorVS$ cnt )
     0 upad ! dup 0<
        if   s" -" +upad abs
        then
     SplitVersion (.) +upad  dot" +upad (.) +upad" ;

: 3tables { legendtxt$ cnt bgcolor Border -- }
   +HTML| <body bgcolor=| bgcolor "#h." +html >| <form> <center>
   10 10 0 1 0 <table> <tr> <tdCTop> \ A table to lock all tables
   10 10 0 1 0 <table> <tr> <tdLTop> \ A table to lock the inner table
   <fieldset>  <legend>   SitesIndex HomeLink  .HtmlBl
                          legendtxt$ cnt +HTML  .HtmlBl
            &Version @ dup 0>
                if    +HTML|  vs:| +AppVersion +html
                else   drop
                then  </legend>
   +HTML| <font size="3" face="Segoe UI" color="#000000">|
    10 10 0 4 Border  <table>  ; ( w% h% cellspacing padding border -- )

: <<NoReferrer>> ( - )  +HTML| <meta name="referrer" content="never" /> | ;

: <HtmlLayout> ( legendtxt$ cnt bgcolor Border - )
   htmlpage$ off <html5> <html> <head> <<NoReferrer>>
   2over  Html-title-header CssStyles </head> 3tables ;

: <EndHtmlLayout>   ( - )
     </table>  </font> </fieldset> </td></tr> </table>  </td></tr> </table>
   </center> </form> </body>  </html>  ;

: html-header   ( title cnt - )
   htmlpage$ off <html5> <html> <head>
    Html-title-header <<NoReferrer>> CssStyles </head> ;

: .Html-Time-from-UtcTics (  f: UtcTics - )
    fdup f0>=
      if   bl
      else fabs [char] -
      then
    >r Time-from-UtcTics
    r> swap ##$ +html
    2 0 do  [char] : swap ##$ +html  loop ;

: .GforthDriven ( - )
    s" Segoe UI" <FontFace 14 $0 s" <em>Gforth&nbsp;driven&nbsp;</em>" <<FontSizeColor>> </font> ;


: y/nPage ( text$ count action$ count - )
     htmlpage$ off  s"  " Html-title-header <HEAD> <style> 50 18 +cssButton{}
     +HTML|  fieldset { border:2px solid blue } | </style>  </HEAD>
     +HTML| <body bgcolor="#444444">|
      2>r
     +HTML| <div valign="center" align="center">|
     +HTML| <form> <table border="0" cellspacing="7" width="30%" bgcolor="#FFFFF0">|
     <tr><td>
        +HTML| <fieldset style="color:black">|
          s" Warning:" <<legend>> <br>  +html
          <br> <br>
          s" Yes"  2r>  <CssButton>  +HTML| &nbsp; &nbsp;|
          s" No"   nn" <CssButton>
        +HTML| <br> &nbsp;| </fieldset> </td></tr>
     </table> </form> </div> </body> </html> ;

logFile" start-logfile  \ Start a logging.

0 value &favicon

s" favicon.ico" r/o bin open-file throw
dup dup file-size throw d>s dup cell+ allocate throw
dup to &favicon  \ hdnl hndl size &favicon
cell+ -rot swap read-file throw  swap CloseFile
&favicon !   &favicon lcount

: favicon.ico     ( - ) &favicon lcount  htmlpage$ lplace ;

also TCP/IP TCP/IP DEFINITIONS

' noop  alias get
' noop  alias HTTP/1.1
' noop  alias NoReply-HTTP
' noop  alias nn            \ no name attached to value of the button
' noop  alias No+
' order alias order
' words alias words
' noop  alias Yes+

: /main.css ( - )  htmlpage$ off ['] CssStyles set-page ;
:  /favicon.ico   ( - )  ['] favicon.ico set-page ;
: AskShutDownPage ( - ) s" Shutting down, continue?"   s" DoShutdown" ['] y/nPage set-page ;
: AskRebootPage   ( - ) s" Rebooting, continue?"       s" DoReboot"   ['] y/nPage set-page ;
: AskQuitPage     ( - ) s" Exit to console, continue?" s" DoQuit"     ['] y/nPage set-page ;
: AskByePage      ( - ) s" Exit Forth, continue?"      s" DoBye"      ['] y/nPage set-page ;


: \quit     ( - )  quit  ;
\in-system-ok : +f       ( - ) also forth  ;

previous previous forth definitions

\s
