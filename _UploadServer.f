s" favicon.ico" file-status nip 0<> [if] cr
cr .( favicon.ico not found.)
cr .( TRY: cd sources_location   before starting Forth and compiling. )  quit [then]

needs Common-extensions.f \ See https://github.com/Jos-Ven/A-smart-home-in-Forth
cr marker _UploadServer.f  bl emit .latest .( 11-06-2024 )      \ by J.v.d.Ven.

0 [IF]
This makes it possible to upload sources to the file system of an ESP32 or ESP12F.
For Installation, notes and known issues see:
Installation_upload_server.pdf

[THEN]

needs FileLister.f        \ To select a file from a list. Also loads webcontrols.f and Web-server-light.f

s" ConfigUdpWeb.dat" ConfigFile$ place

Config$:       flash-to$
Config$:       Extension$
Config$:       dir$

ConfigVariable FlashUpd

ConfigFile$ count file-exist? not
EnableConfigFile

S" gforth" ENVIRONMENT? [IF] 2drop

 s" Documents/MachineSettings.fs" file-status nip 0= [if]
            needs Documents/MachineSettings.fs    \ =optional to override settings
            [THEN]

[defined]  AdminPage    [IF] needs Master.fs  [ELSE] needs slave.fs  [THEN] \ Includes the webserver-light
-status
: submit-task ( cfa - )
  here !  spawn-task here @ execute ;

[THEN]


S" win32forth" ENVIRONMENT? [IF] DROP

\ Start a webserver at port 8080.  See HtmlPort in Web-server-light.f

needs Web-server-light.f

: open#Webserver   ( #server - sock|ior )
   dup ipAdress$ 2dup +log
   rot r>port @  SOCK_STREAM IPPROTO_TCP open-port-socket ;

: open-#Webserver  ( #server - )  dup  open#Webserver  swap r>sock ! ;

\ ---- Start server configuration ---------------------------------------------------------------
\ --- Servertypes:

\ Section for allocating servers only.
\ Group the servers by it's manufacturer and model.

Servers[                 \ Starting adres for allotting servers.
#servers to ServerHost   ' open-#Webserver  GetIpHost$  HtmlPort  hostname$ count add-server
]Servers

.servers

: .dir->file-list-name ( --  )
        _win32-find-data 11 cells+              \ adrz
        zcount                                  \ adrz scan-len slen
        AddFilename                             \ adrz len  ;print file name
        2drop ;

\ s" *.forth" ' .dir->file-list-name  ForAllFileNames

map-handle Fhndl

: UnmapFileOptions ( - )   Fhndl close-map-file drop ;

: MapFileOptions   ( file$ cnt - vadr size )
   Fhndl open-map-file abort" can't map file."
   Fhndl >hfileAddress @
   Fhndl >hfilelength  @ ;

wTasks webserver-tasks   Start: webserver-tasks
: submit-task ( cfa - )  Submit: webserver-tasks ;

[THEN]


FileNameList file-status nip  [IF] Extension$ lcount  ListFiles [THEN]
0 value MsLastIn

needs UdpSender.f

: NewListFiles ( - )
   Extension$ lcount ListFiles  0 SetSelectedFile
   ReportDate s" New file list ready." report$ +place ;

80 value RemotePort

: ReceiverForm ( - )
   <form>
   +html| <input type="submit" onclick="return false" hidden="true"/>|  \ Disables the key Enter
         <tr><tdL>  HTML| <a target="_blank" rel="noopener noreferrer" href="http://| upad place
                    flash-to$ lcount +upad  s" :" +upad RemotePort (.) +upad
                    HTML| /home">| +upad s" Receiver:" +upad  HTML| </a>| +upad upad count  +Html
             </td><tdL> s" SaveBtn"  flash-to$   lcount 14 <input-text> </td>
   </form> ;

: FileForms ( - )
   <td> <form>
         ButtonWhite  Black s" Reboot"        nn" <StyledButton>
   </form> </td> </tr>
         <tr><tdL>  s" File "  +HtmlNoWrap
          HTML| <a target="_blank" rel="noopener noreferrer" href="http://| upad place
                flash-to$ lcount +upad  s" :" +upad RemotePort (.) +upad
                HTML| /update">| +upad s" Rem: " +upad  HTML| </a>| +upad
                upad  count  +Html
          </td>
              <tdL> s" SavFileNo" 1 <SELECT  AddFileOptions  </SELECT> </td> <td>
    <form> ButtonWhite  Black s" < UpdateList"  nn" <StyledButton>
    </form> </td></tr>
         <tr><tdL> s" Ext:" +HtmlNoWrap </td>
             <tdL> s" SavExt"  Extension$  lcount 5 <input-text>   </td>
             <tdL> ltBlue  Black s" Save"               nn"    <StyledButton> </td></tr>
        </form> ;

: DirForm ( - )
   <tr><tdL> <form> s" Dir:" +HtmlNoWrap               </td>
   <tdL> s" SetDir" dir$ count dup 5 max <input-text>  </td>
   <tdL> ButtonWhite  Black s" Set" nn" <StyledButton> </td></tr> </form> ;

: FlashSettings  ( - )
   <tdLTop> <fieldset>  HTML| Settings| <<legend>>
        10 145 1 4 0 <tablePx>
         ReceiverForm  FileForms  DirForm
    </table> </td> </fieldset> ;

: FlashReport ( - )
    <tdLTop> <fieldset>   s" Report" <<legend>> 240 145 1 0 0 <tablePx>
             <tdLTop> report$ count 75 min [char] & scan nip \ Overwrite report during transfer
                       if  s" Upload session incomplete!&nbsp;<BR>for: " report$ place
                           fldone @ s>d (ud,.) +report$ s"  bytes."  +report$
                       then
             report$ count +HTML </td>
    </table> </td> </fieldset> ;

: FlashOptions ( - )
    <tdL>   <fieldset>  s" Options" <<legend>> 10 10 10 1 0 <table> <form>
              <td>   $FF6400      Black s" Send"     nn"   <StyledButton>   </td>
              <td>   ButtonWhite  Black s" Load"     nn"   <StyledButton>   </td>
              <td>   ButtonWhite  Black s" Report"   nn"   <StyledButton>   </td>
     </form> </table>  </td> </fieldset> ;

: ServerShutdown ( - )
    <tdLTop> <fieldset>  s" Server" <<legend>> 10 10 10 1 0 <table> <form>
              <td>    ButtonWhite  Black s" Shutdown"  s" AskShutDownPage" <StyledButton>  </td>
    </form> </table> </td> </fieldset> ;

: InitDir ( newdir cnt - )
    2dup set-dir
      if    2drop upad 255 get-dir  \ nok change to the current dir
      then
    dir$ place  ;

: CheckDir ( - )
  upad 255 get-dir dir$ count compare
    if  dir$ count InitDir
    then ;

: FlashPage ( - )
     CheckDir   htmlpage$ off
     s" Upload server " NearWhite 0 <HtmlLayout>
         FlashSettings FlashReport
         <tr> FlashOptions ServerShutdown </tr>
     <EndHtmlLayout>  ;

:  SaveIp ( - )
     false to ignore-hangs
     ReportDate flAdress @
        if    StopTransmitting ReportDate
              s" Transfer interrupted.<BR>Settings NOT saved." report$ +place
        else  parse-name flash-to$ lplace
              udp-sock-client dup 0 <>
                 if    close-port
                 else  drop
                 then
              open-udp-port
        then
        TestConnection
 ;

open-udp-port

: Send-recv-pkt ( recv-pkt$ cnt  - recv-pkt$ cnt   )  log" Server: N/A. Sending the received packet."  ;


TCP/IP DEFINITIONS ALSO HTML

: /home ( - )           ['] FlashPage set-page ;
: RemoteOk ( - )  ConnectionRes on ReportDate s" Connection successful." +report$  ;

: Reboot ( - ) RebootESP postpone \ ;

: %3C+UpdateList ( - ) NewListFiles ;

: SaveBtn       ( - ) SaveIp ;
: SavFileNo	( <SelectedFile> - ) parse-name  s>number d>s SetSelectedFile  ;
: SavExt	( <Extension> - )    parse-name  1 max 7 min Extension$ lplace ;

: SetDir ( <htmlStyleDirName>- )
   parse-name DecodeHtmlInput 2dup set-dir 0=
     if    dir$ place NewListFiles
     else  2drop
     then  ;

' noop  alias Set
' noop  alias Save
' noop  alias Shutdown
' /home alias Report
' /home alias /

: Send ( - )  PushFlash  ; \ Pushes the involved file size and targeted sector to the client
: Load ( - )  LoadOnESP ;


: /udp  ( #rec n - ) ['] DoDropped  set-page ; \ To sent a dropped packet
: /udpf ( - )        ['] DoSendFile set-page postpone \ ; \ To transfer the file

: TestCon     ( - )  3000 ms TestConnection  ;
: DelayedTest ( - )  ['] TestCon submit-task ;


 DelayedTest
PREVIOUS FORTH DEFINITIONS

\ ---- Starting the application in the webserver ------------------------------------------------
S" win32forth" ENVIRONMENT? [IF] DROP

\ The web server locks the console in Win32Forth.
\ That can be prevented by running it in a separate thread.

cls   .( Web server at: ) SetHomeLink homelink$ count type cr
start-servers \quit \ Start the webserver in a task in the background and stop compiling.

[THEN]


S" gforth" ENVIRONMENT? [IF] 2drop

\ ' see-UDP-request  is udp-requests
\ ' see-request is handle-request \ Option to see the complete received request
cr  .( Starting the webserver. )
start-servers

[THEN]

\s
