needs slave.fs             \ Will load all that is needed for the Web server light
cr Marker _down.fs .latest \  1 page only.

\ ---- The HTML-page for the application --------------------------------------------------------


ALSO HTML

: button-line ( textButton cnt cmd cnt - )   <tr><td>  <CssButton> </td><tdL> ;

: .Buttons ( - )
    10 10 14 4 0 <table>  \ ( w% h% cellspacing padding border -- )
     s" Reboot"   s" AskRebootPage"    button-line
     s" Shutdown" s" AskShutDownPage"  button-line
    </table> ;

: down-home-page ( - )
    s"  " NearWhite 0 <HtmlLayout> \ Starts a table in a htmlpage with a legend
    <tr><td> <strong> +HTML| Reboot / Shutdown|  </strong> ( <br> .HtmlSpace)  </td></tr>
    <tr><td> .Buttons  </td></tr> \ Buttons + feedback of the last given command
    <tr><td> +HTML| Uptime: | GetUptime Uptime>Html  </td></tr>
    <tr><td> <aHREF" +homelink  +HTML| /Schedule">| +HTML| Schedule| </a>
    <tr><td>  HTML| Loggings: | +HtmlNoWrap LogLinks </td></tr> \ Optional to see the links to the log-page
    <tr><td> +Arplink   s" /UpdateLinks" Sitelinks   </td></tr>
    <tr> +HTML| <td align="right" valign="bottom">| .GforthDriven </td></tr>
    <EndHtmlLayout> ;

: shutdown-webserver ( - ) down ;

here dup to &options-table \ Options used by run-schedule
\                        Map: xt      cnt adr-string
' Good-morning            dup , >name$ , , \ Executed when the schedule is empty
' Reset-logging-saturday  dup , >name$ , ,
' Rebuild-arptable        dup , >name$ , ,
' reboot                  dup , >name$ , ,
' Reset-webserver_27th    dup , >name$ , ,
' shutdown-webserver      dup , >name$ , ,

here swap - /option-record / to #option-records \ Pointing to the new option list

PREVIOUS


\ ---- Controlling the application --------------------------------------------------------------

TCP/IP DEFINITIONS   \ Adding words in the tcp/ip dictionary for the GUI.

: /home  ( - )       \ Must be executed AFTER all other controls have been executed
         ['] down-home-page set-page ;

\ : Switch (  On|Off - )   if  WhenOn  else  WhenOff  then ;

forth definitions

\ ---- Starting the webserver application ---------------------------------------------


cr order

\ ' (handle-request) is handle-request  \ Default
\ ' see-request is handle-request       \ To see the complete received request

cr  .( Starting the webserver. )
start-servers

\s
