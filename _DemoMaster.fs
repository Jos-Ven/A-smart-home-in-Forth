Needs  Master.fs \ Will also load all the Web-server-light and autogen_ip_table.fs 16-07-2023
                 \ Change Max#servers first at the start of autogen_ip_table.fs !

Marker _DemoMaster.fs .latest \ A demo that uses webcontrols.f 1 page only the shutdown button works.
needs  gpio.fs                \ To control and administer GPio pins

\ ---- Assigning GPio pins ----------------------------------------------------------------------

0 \ 1st device in the table. The following GpioPin(s) are used:
\ GPIOpin#   Name     Resistor         Input OR Output
  24 GpioPin: Light_1  AsPinOutput
 cr dup . .( Gpio pin[s] used.) to #pins \ Lock table and save the actual number of used pins
 InitPins .pins cr                       \ Start and list the used GPio pins.

\ ---- The HTML-page for the application --------------------------------------------------------


ALSO HTML

: <StyledButton><br>  ( BackgrColor FontColor  value$ cnt  name cnt - )
   (.) <StyledButton> <br> .HtmlSpace  <br> ;

: GpioButton ( GpioButton - )
    \State
       if    ltBlue 1
       else  Grey6  0
       then  >r black  s" Switch" r> <StyledButton><br> ;

: .Buttons ( - ) \ Put all buttons in a new table
     100 100 0 16 0 <table>    ( w% h% cellspacing padding border -- )
         <tr><td> ReadPins <strong> s" Light Master:" +HtmlNoWrap </strong> 2<br>
                   Light_1 GpioButton  </td>
         <tdCTop>   s" Reboot"   s" AskRebootPage"    <CssButton>  2<br> .HtmlSpace
                    s" Shutdown" s" AskShutDownPage"  <CssButton> 2<br> </td></tr>
     </table> ;

: SwitchPage ( - )
    s" Light switch" NearWhite 0 <HtmlLayout> \ Starts a table in a htmlpage with a legend
    <td> .Buttons
         &last-html-cmd count  +</td>         \ Feedback of the last given command
    <tr><td>  +HTML| Settings: | AdminLink .HtmlSpace
              <aHREF" +homelink  +HTML| /Schedule">| +HTML| Schedule| </a>   </td></tr>
    <tr><td>  HTML| Loggings: | +HtmlNoWrap LogLinks  </td></tr> \ Optional to see the links to the log-page
    <tr><td>  +Arplink s" /UpdateLinks" SiteLinks </td></tr>

    <tr> +HTML| <td align="right" valign="bottom">| .GforthDriven </td></tr>
    <EndHtmlLayout> ;

PREVIOUS
\ Responses to the various buttons:
: switch-off    ( - )   \ Put the light off
   Light_1 -off s" Switch off" place-last-html-cmd SwitchPage ;

: switch-on    ( -  )  \ Put the light on
   Light_1 -on  s" Switch on" place-last-html-cmd SwitchPage ;

: shutdown-webserver ( - ) down ;

here dup to &options-table \ Options used by run-schedule
\                        Map: xt      cnt adr-string
' Good-morning            dup , >name$ , , \ Executed when the schedule is empty
' Reset-logging-saturday  dup , >name$ , ,
' Rebuild-arptable        dup , >name$ , ,
' reboot                  dup , >name$ , ,
' Reset-webserver_27th    dup , >name$ , ,
' shutdown-webserver      dup , >name$ , ,
' switch-off              dup , >name$ , ,
' switch-on               dup , >name$ , ,

here swap - /option-record / to #option-records \ Pointing to the new option list

\ ---- Controlling the application --------------------------------------------------------------

TCP/IP DEFINITIONS   \ Adding words in the tcp/ip dictionary for the GUI.

: /home  ( - )       \ Must be executed AFTER all other controls have been executed
         ['] SwitchPage set-page ;

: Switch (  On|Off - )   if  switch-off  else  switch-on  then ;


forth definitions

\ ---- Starting the webserver application ---------------------------------------------


cr order

\ ' (handle-request) is handle-request  \ Default
\ ' see-request is handle-request       \ To see the complete received request

cr  .( Starting the webserver. )
start-servers

\s
