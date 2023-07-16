needs Common-extensions.f \ Basic tools for Gforth and Win32Forth
Marker _demo1.f .latest   \ A minimal example for Win32Forth or a Raspberry Pi

needs Server-controller.f \ Controls a number of servers in an array
needs Web-server-light.f  \ A minimal fast web server for Gforth. It also runs on Win32Forth
needs webcontrols.f       \ Html extensions to generate a web page

\ Start a demo webserver at port 8080.  See HtmlPort in Web-server-light.f
\ The server will send the demo-home-page to the client after a request.
\ Then the client can send a response back to the server.
\ In demo-handle-request the requests and responses are processed.

\ ---- Start server configuration ---------------------------------------------------------------

\ --- Servertypes:

\ Section for allocating servers only.
\ Group the servers by it's manufacturer and model.

Servers[                 \ Starting adres for allotting servers.
#servers                 \ Starting a number of new type of servers
#servers to ServerHost   ' open-#Webserver  GetIpHost$  HtmlPort  hostname$ count add-server

S" gforth" ENVIRONMENT? [IF] 2drop
 #servers SWAP range-Gforth-servers 2!   \ Store the range this type of servers
 [ELSE] drop
 [THEN]

]Servers

.servers                 \ In this case only one server at port 8080

\ ---- End server configuration -----------------------------------------------------------------



\ ---- The HTML-page for the application --------------------------------------------------------

ALSO HTML

: .Buttons ( - )             \ All buttons in one cell of a table
   <tr> 2 <#tdC> <strong> s" Controls" +html </strong> </td></tr>
   <tr><td> s" Hello"    2dup                 <CssButton> </td><tdL> +HTML| Say hello.|       </td></tr>
   <tr><td> s" Quit"     s" AskQuitPage"      <CssButton> </td><tdL> +HTML| Exit to console.| </td></tr>
   <tr><td> s" Bye"      s" AskByePage"       <CssButton> </td><tdL> +HTML| Exit Forth.|      </td></tr>
   <tr><td> s" Shutdown" s" AskShutDownPage"  <CssButton> </td><tdL>
                                                      HTML| Shutdown the system.| +HtmlNoWrap </td></tr> ;

: home  ( - )
    s" Demo1 " NearWhite 0 <HtmlLayout> \ Starts a table with a form in a htmlpage with a legend
    .Buttons
    <tr>  2 <#tdC> &last-html-cmd count +html </td></tr>  \ Feedback of the last given command
    <tr> EmptyCell +HTML| <td align="right" valign="bottom">| .GforthDriven </td></tr>
    <EndHtmlLayout> ;

ALSO TCP/IP DEFINITIONS      \ All the actions are in the tcp/ip dictionary.

: /home  ( - ) ['] home set-page ; \ So it will be executed after all other controls have been executed
: Hello  ( - ) s" Hello!" place-last-html-cmd  cr s" Hello!" wall  ;

forth definitions previous previous

0 [if]  Note:
   If the button hello is pushed Forth gets: GET /home?nn=Hello HTTP/1.1
   That will be changed into: GET /home nn Hello HTTP/1.1
   That line will be evaluated
   /home must be executed AFTER all the other options have been executed
   since the other options might impact the home-page!
[then]


\ ' (handle-request) is handle-request  \ Default
\ ' see-request is handle-request       \ To see the complete received request


\ ---- Starting the application in the webserver ------------------------------------------------


S" win32forth" ENVIRONMENT? [IF] DROP

\ The web server locks the console in Win32Forth.
\ That can be prevented by running it in a separate thread.
cls

.( Web server at: ) SetHomeLink homelink$ count type cr
start-servers \quit \ Start the webserver in a task in the background and stop compiling.


[THEN]

cr order
S" gforth" ENVIRONMENT? [IF] 2drop
cr  .( Starting the webserver. )
start-servers
[THEN]
\s

