\ 15-11-2023 A web server by J.v.d.Ven.

0 [if]

For small applications.
Runs in windows under Win32Forth 6.15.04 or in Linux 8 or better under Gforth.
Last tested under:
- The Bullseye (Kernel: Linux 5.15.32+) on a raspberry zero
- The bookworm (Kernel: Linux 6.1.0-9-amd64) on a PC
- Windows 11

07-11-2022: Uses recv instead of read-socket in the web-server under Linux.
            A browser should send a packet within 300 MS.
            Otherwise, the accepted socket is ignored. (No packet received)

08-07-2023  - Almost all manual searches on incoming requests are removed.
              Incoming request are now adapted and evaluated by Forth!
            - An HTML dictionary is now used for html tags and svg parts.
            - TcpTime is changed to Forth-style messages for ESP32/ESP8266
            - To start the servers use:  start-servers and NOT Start-http-server
            - Renamed: <#tdC      to <#tdC>     <#tdL to <#tdL>   <#tdR to <#tdR>
                       <<option>> to <option>   .<<option>> to <<option-cap>>
            - Added a schedule with a web-gui for a Daily_schedule
13-11-2023  - Moved the project to https://github.com/Jos-Ven/A-smart-home-in-Forth
            - Changes are now logged on Git.
[then]

needs Common-extensions.f
needs Server-controller.f


marker Web-server-light.f .latest

s" favicon.ico" file-status nip  [IF] cr .( favicon.ico is missing! ) abort [THEN]

8080 value HtmlPort \ The default port for the webserver

\ Buffers to allocate:
 0 value htmlpage$   \ Default home page
 0 value pkt$        \ Webpage to send back incl header
 0 value response$   \ A small buffer for MsgServer

\ Size buffers:
0 value /maxheader
2048    constant /req-buf               \ max packet to receive
$ffff /maxheader - constant /HtmlPage   \ max packet to send excl header
/HtmlPage  /maxheader +  constant /pkt  \ max packet to send incl header

create req-buf /req-buf allot

: allocate-lcounted-buffer ( size - adr ) cell+ allocate abort" Memory allocation failed" ;

cell newuser aSock
-1   value   web-server-sock

create &last-html-cmd 256 allot

defer OptionalInsert ' noop is OptionalInsert

: place-last-html-cmd ( adr cnt -- )
   maxcounted min
   &last-html-cmd off   OptionalInsert
   (time) &last-html-cmd +place  s" : " &last-html-cmd +place
   &last-html-cmd +place ;


: +pkt_   ( adr cnt -- )  pkt$ +lplace ;
: +pkt    ( adr cnt -- )  +pkt_ crlf" +pkt_ ;

10 constant max-chars ( 32bits forth)
/pkt       allocate-lcounted-buffer to pkt$

: make-hdr ( size - )
     pkt$ off
      s" HTTP/1.0 200 OK"                        +pkt
      S" Server: Minimal webserver in Forth"     +pkt
      S" Content-Type: text/html; charset=utf-8" +pkt
      S" Accept-Encoding: x-compress; x-zip"     +pkt
      S" Connection: close"                      +pkt
      S" Content-Length: " +pkt_ (.) dup>r       +pkt
      max-chars r> - S" Label: filler............"  rot 7 + min  +pkt
      crlf"                                +pkt_ ;

1 make-hdr pkt$ @ to /maxheader

: make-packet  ( html$ cnt - packet$ cnt )
   dup make-hdr pkt$ +! drop  pkt$ lcount ;  \ Also removes the lcount of htmlpage$

: +html   ( adr cnt -- )
    htmlpage$ lcount nip over + /HtmlPage >
       if    cr ." Buffer /HtmlPage of " /HtmlPage h.
             ."  is too small. Split your page" abort
       else  htmlpage$ +lplace
       then  ;

: +1html   ( char - )  sp@ 1 +html drop ;
: +html|   ( -<string|>- )    [char] | parse postpone sliteral postpone +html ; immediate


create &last-line-packet$ 80 allot
 s" - - - - - - - - - - - - - - - - - - - - - - - - -" &last-line-packet$ place

crlf" &last-line-packet$ +place

defer handle-request \  handle-request ( recv-pkt$ cnt -- )


defer SitesIndex ' noop is SitesIndex
0 value ClientIaddr
create allowed-ip$ ," ." \ A dot to allow any IPv4 connection. Could be " 192.168.21.103"

: LogRequest ( adr n type n - ) \ Logs the first line only
  crlf" upad place  +upad  s" : " +upad
  2dup crlf" search
   if    nip - 120 min
   else  2drop 80 min
   then +upad upad"  +log ;

: send-html-page ( packet cnt sock - )
     -rot make-packet rot send-packet drop ;


S" win32forth" ENVIRONMENT? [IF] DROP

cr .( On Win32Forth)

needs itools.frt

1 PROC inet_ntoa ( in_addr -- *char )

: iaddr>str   ( iaddr -- str len )  inet_ntoa zcount ;
: sock-read?  ( sock -- n )   fionread  0 >r rp@ ioctlsocket drop r> ;

: accept-socket ( sock -- aSock iaddr )
    16 >r rp@ sockaddr-tmp rot call accept r> drop
    dup invalid_socket =
       if    0
       else  sockaddr-tmp 4 + @
       then  ;

: create-server ( p -- sock )
    sockaddr-tmp 4 cells erase
    htonl AF_INET or sockaddr-tmp !
    0 sock_stream AF_INET call socket dup
    dup 0< abort" no free socket" >r
    16 sockaddr-tmp rot call bind 0= if  r> exit  endif
    r> drop true abort" bind :: failed" ;

: allocate-buffers ( - )
   /pkt   allocate-lcounted-buffer to pkt$
   pkt$  /maxheader + to htmlpage$
   /maxheader allocate-lcounted-buffer to response$ ;

: initWebServer ( - )  ;

: listen  ( socket /queue -- ) swap Call listen
  0< if log" listen() failed" then ;

\ Not used
\ --------

: ShutdownConnection ( sock - ) drop ;
: NoTcpDelay         ( sock - ) drop ;

\ --------

2 constant timeout-sock-read?
2 constant #timeouts-sock-read?

: wait-for-packet  ( aSock - n )
   0 swap  #timeouts-sock-read? 0
      do  dup sock-read? dup 0<>
            if  nip swap leave
            then
          drop  timeout-sock-read? ms
      loop
   drop ;

: elapsed        ( - d )  ms@ start-time - s>d ;

: LogElapsed$    ( d - )
   s" - - - - - - - " upad place (ud,.) +upad s"  Ms " +upad
   &last-line-packet$ count +upad upad"  write-log-line ;

synonym  handle-requests noop
synonym Add/Tmp/Dir noop

: html-responder ( packet-in$ cnt - )
      dup 0>  \ errors?
              if  2dup s" TCP/IP" LogRequest handle-request  \ Act on the received packet
               else     if    log" No data from read-socket."
                        else  log" read-socket failed."              \ zero pack
                        then  drop
               then ;


: handle-web-packet ( aSock - )
     dup aSock !
         wait-for-packet crlf"  write-log-line  timer-reset dup
         if  aSock @  req-buf rot /req-buf min read-packet 0=
                 if     html-responder
                 else   2drop log" read-packet failed."
                 then
         else   s" 0 packet detected." +log drop
         then
   elapsed LogElapsed$
 ;


Needs security.f \ For 'Down' to shutdown the PC

: DoReboot    ( - )    cr ." Reboot is not yet possible."  ;
: ((bye))     ( - )    bye ;

: Set_SO_Buf  ( n n n - ) 3drop ;

: IP-adress-allowed? ( iaddr - flag )
   dup to ClientIaddr iaddr>str 2dup allowed-ip$ count
   search nip nip -rot
   s" ("  upad place depth (.) +upad  s" ) " +upad
   s" In: --->" +upad +upad  upad"  +log ;


[THEN]



S" gforth" ENVIRONMENT? [IF] 2drop

: warnmsg ( err_catch - )  (DoError) ;

[THEN]


\ ---- The HttpRequest parser for GET requests

0 [IF]
A link to a new page must executed AFTER all controls are executed
set-page is needed to ensure this.
[then]


cell newuser xt-htmlpage

: set-page ( xt - ) xt-htmlpage ! ;

: FaviconLink ( - )
   +html| <link rel="shortcut icon" href="/favicon.ico" type="image/x-icon">| ;


: StartHeader ( - )
  htmlpage$ off
  +html| <html> <head>|
  +html| <style> body {line-height: 18px;} </style>|
  +html| <title>Webserver light in 4th</title>|
  FaviconLink +html| </head>| ;


VOCABULARY TCP/IP \ Holds the words for incomming requests

: trim-stack	( ...?   - )
    sp@ sp0 @ u<  cr ." Stack "
      if     .s ." TRIMMED."
      else   ." UNDERFLOW."
      then
    sp0 @ sp! cr ;

cell newuser depth-target

: save-stack	( ...ToBeSaved - )
   s" depth-target off  begin depth while >r 1 depth-target +! repeat "
   evaluate ; immediate

: restore-stack	( - ...saved )
   s"  begin depth-target @ while  r> -1 depth-target +! repeat "
   evaluate ; immediate

: cut-line	( adrBuf lenBuf -- adr len ) 2dup $0d scan nip - ;



: .err-msg  ( adr cnt - )   cr .date space .time cr ." Stack error at: " type  ;

: .catch-error ( adr len errcode - ) \ The line after the separators are removed.
   >r cr ." ******* Request aborted! ******* "
\in-system-ok  cr .date space .time  ." Order: " order    \ Words must be defined in the TCP/IP dictionary !
    cr ." Error at: " 2dup  type
    r> warnmsg
    StartHeader             \ Put the error on the html-page
    +html| <body bgcolor="#FEFFE6"><font size="4" face="Segoe UI" color="#000000" ><BR> |
    +html| <br> | (date) +html  s"  " +html (time) +html
    +html| <br> <br> Sorry, the page you requested cannot be found.|
    +html| <br> <br> Error 404 at: | +html
    +html| <br> For web page: |
    xt-htmlpage @ dup 0<>
       if    name>string +html
       else  drop +html| Na |
       then
    +html| </font></body></html>|  ;

: evaluate_cleaned ( adr len - res-catch )
  #255 min  evaluate xt-htmlpage @ dup 0<>
    if    catch dup 0<>
            if    xt-htmlpage @ name>string rot .catch-error
            else drop
            then
    else  drop
    then ;

\ evaluating_tcp/ip looks after stack mismatches and syntax errors
\ It does not protect against hanging definitions!
: evaluating_tcp/ip { adr len -- }
     save-stack               \ Save/empty the stack here
     adr len 2dup +log ['] evaluate_cleaned catch dup 0<>
       if   >r 0 set-page
             adr len r> .catch-error 0 to len
       else  drop
       then
    sp@ sp0 @ <>
        if  len 0>
               if  adr len .err-msg
               then
            trim-stack   \ The stack should be empty without trimming it
        then
    restore-stack     \ Restore the previous state
   ;

: remove_seperator ( adr len char - ) \ replace them by a space
   -rot bounds
      ?do  i c@ over =
             if   bl i c!
             then
      loop drop ;

: remove_seperators  ( adr len - )
  2dup [char] ? remove_seperator
  2dup [char] = remove_seperator
       [char] & remove_seperator ;

cell newuser ms_req
: see-request ( adrRequest lenRequest -- )
   cr .date space .time cr ."  Request: "
  2dup type  cr                       \ Optional to see the complete received packet
   ms@ ms_req !
   cut-line                           \ Extract the line with GET
\   2dup type  cr                     \ Optional to see the first line only
   2dup remove_seperators
   ."  Evaluate: "  2dup type cr      \ Optional to see what goes to the interpreter of Forth
   evaluating_tcp/ip
   ."  Html-page: " xt-htmlpage @ dup 0<>
\in-system-ok      if   .id
                   else drop ." Na"
                   then
   htmlpage$ lcount aSock @ send-html-page
   ms@ ms_req @ -
   cr 20 0 do [char] - emit loop  space . ." ms." cr xt-htmlpage off ;

: (handle-request) ( adrRequest lenRequest -- )
   cut-line  \ Extract the line with GET
   2dup remove_seperators
   evaluating_tcp/ip
   htmlpage$ lcount aSock @ send-html-page xt-htmlpage off ;

\  ' see-request is handle-request       \ To see the complete received request
   ' (handle-request) is handle-request  \ To see errors only

\ ----


\  In &Version the part less than 1.000.000 represent the minor part of the version number
create &Version -1 , ," version.fbin"
: SplitVersion ( MinVs MajVs - ) 1000000 /mod ;

Create homelink$ 0 c, 255 chars allot
: +homelink           ( - )  homelink$ count +html ;

4 value ms-short-timeout
: short-timeout ( - ) ms-short-timeout ms ;

1 constant TCP_NODELAY


S" gforth" ENVIRONMENT? [IF] 2drop

cr cr
.( Linux: )  OsVersion" type cr
.( Dir: )    upad 255 get-dir type cr


needs chains.fs

c-library socketExt
    \c #include <netdb.h>
    \c #include <unistd.h>
    \c #include <sys/types.h>
    \c #include <sys/socket.h>
    c-function getsockopt getsockopt n n n a n -- n ( sockfd level optname optval optlen -- r )
end-c-library

: allocate-buffers ( - )
   /pkt   allocate-lcounted-buffer to pkt$
   pkt$  /maxheader + to htmlpage$
   /maxheader allocate-lcounted-buffer to response$ ;

7 constant SO_SNDBUF
8 constant SO_RCVBUF
9 constant SO_KEEPALIVE
2 constant IP_TTL

: GetSockOption ( fileno-sock optval option -- parm )
   swap upad upad upad !  255 upad cell+ ! upad cell+ getsockopt  ?ior upad l@ ;

: GetSolOpt ( fileno-sock SO_OPTION -- parm )  SOL_SOCKET GetSockOption ;

: SetSockOption ( tcp-sock optval p2 p1 size option - )
   swap >r >r upad 2! r> swap upad r> setsockopt ?ior ;

: SetSolOpt ( tcp-sock optval p2 p1 size - )   SOL_SOCKET SetSockOption ;

: reuseaddr   ( sock - ) SO_REUSEADDR  -1 -1 cell SetSolOpt ;

: Set_SO_Buf  { fileno-sock #units SO_Buf -- } \ SO_Buf= SO_RCVBUF or SO_SNDBUF
   cr ." Set_SO_Buf: " SO_Buf . #units .
   cr ." Before:" fileno-sock SO_Buf  GetSolOpt .
   fileno-sock SO_Buf 0 #units swap cell SetSolOpt
   cr ." After:"  fileno-sock SO_Buf  GetSolOpt . ;

: iaddr>str   ( iaddr -- str len )
    upad ! utmp$ off  4 0
      do   i upad + c@ (.) +utmp$
           dot" +utmp$
      loop
    utmp" 1- ;

cell newuser pMsStart
: q_elapsed          ( - d )  ms@  pMsStart @ - s>d  ;

8899 constant UdpPORT \ Could be another port
5  constant SO_DONTROUTE
254 constant /pad

: open-upd-port   ( #server port - sock|0 )
   swap ipAdress$ rot SOCK_DGRAM IPPROTO_UDP
   open-port-socket  dup dup 0=
      if    drop
      else  dup fileno reuseaddr  true blocking-mode  4 ms
      then ;

: open#Webserver   ( #server|host-id - sock|ior )
   dup  dup 100 <
    if    r>port @ swap ipAdress$
    else  drop 80 swap host-id>ip$  \ for esp-systems
    then

   2dup +log
   rot SOCK_STREAM IPPROTO_TCP open-port-socket ;

\ A client for an other LOCAL tcp server:

: open-#Webserver  ( #server - )  dup  open#Webserver  swap r>sock ! ;

: (SendUdp)         ( msg$ cnt #server -- )
        over /pad >
            if    log" Message not send. > /pad" 3drop
            else  UdpPORT open-upd-port dup  \ Uses: SOCK_DGRAM (UDP)
                   if   dup >r fileno
                        dup SO_DONTROUTE   -1 -1 cell SetSolOpt
                            IP_PMTUDISC_DO -1 -1 cell SetSolOpt
                        SOCK_CLOEXEC r@ SetMode
                        r@ send-packet drop         \ Sends msg$
                        r> close-socket
                   else 3drop
                   then
            then ;

: SendUdp         ( msg$ cnt #server -- )
  CheckGateway
    if    (SendUdp)
    else  3drop drop log" No gateway."
    then ;

: accept-socket   ( server -- asocket iaddr )
    sockaddr_in alen !
    sockaddr-tmp alen accept()
    dup reuseaddr
    dup ?ior SOCK_CLOEXEC over fd>file  SetMode   sockaddr-tmp 4 + @ ;

: listen          ( socket /queue -- )
   listen()
   0< if log" listen() failed"
      then ;

: Show. ( - ) last-lit, postpone name>string postpone place-last-html-cmd ; immediate
: Sh: :  postpone Show. ; immediate

: GetVersion# ( - )
   &Version cell+ count 2dup file-status 0<>
   if    drop R/W   create-file throw >r
         0 &Version cell r@ write-file throw
         r> close-file throw
   else  drop  R/W map-file over @ -rot
         unmap-file
   then  &Version ! ;


variable init-webserver-gforth-chain

: initWebServer   ( - )
    cr GetVersion# s" InitWebServer version: " upad place &Version @
       SplitVersion (.) +upad  s" ." +upad  (.) +upad
    init-webserver-gforth-chain chainperform ;


: LockConsole ( - )
  cr ." Console locked till ^c" cr
    begin pause 60000 ms   again  ;

#500000. socket-timeout-d 2!  \ Increased to prevent TCP zero windows (read-packet failed)


: LogElapsed$ ( d - )
   s" - - - - "  upad place
   depth (.) +upad s"  " +upad  \ Add depth
   s" - -  " +upad  (ud,.) +upad s"  Ms " +upad
   &last-line-packet$ count +upad" write-log-line ;

: html-responder ( packet-in$ cnt - )
      dup 0>  \ errors?
              if  2dup s" TCP/IP" LogRequest handle-request    \ Act on the received packet
               else     if    log" No data from read-socket."
                        else  log" read-socket failed."        \ zero pack
                        then  drop
               then ;

: NoTcpDelay ( tcp-sock - ) TCP_NODELAY 1 dup cell SetSolOpt ;

: FindSender ( &Packet cnt - #server flag )     \ &Packet cnt should contain @numberBL
    [char] @ bl  ExtractNumber? >r d>s abs r> ;

: Confirmations?  ( received$ cnt - flag )      \ &Packet cnt looks like: '/F0 Confirm @1 '
    s" /F0 " search
     if  FindSender
         if  dup #servers <=
              if    0 swap Set#F0  true         \ To stop repeating in logRetryUdpMsg
              else  drop false
              then
         then
     else   2drop false
     then  ;

: ShutdownTCPConnection ( aSock - )  dup ShutdownConnection close drop ;

: .LinuxError ( n - )
   -1 =
      if   -512 errno - >stderr error$ cr type
      then ;


: recv_tcp { sock -- adr length } \ A browser should send a packet within 24 MS.
   0 6 0                      \ Otherwise, the accepted socket is ignored. (No packet received)
     do  sock req-buf cell+ /req-buf MSG_DONTWAIT recv dup 0>
           if    nip leave
           else  drop
           then
        4 ms
   loop  req-buf ! req-buf lcount ;

: linger-tcp ( fileno - )  SO_LINGER 1 sp@ 2 cells SetSolOpt ;

: handle-web-packet ( aSock - )
   dup fd>file  aSock !
   dup linger-tcp
       recv_tcp
   2dup Confirmations?
      if     2drop  log" confirmation packet."
      else   dup 0=
             if    2drop log" Zero pack."
             else  ms@ pMsStart ! html-responder  q_elapsed LogElapsed$
             then
      then ;

: IP-adress-allowed? ( iaddr - flag )
   dup to ClientIaddr iaddr>str 2dup allowed-ip$ count
   search nip nip -rot
   depth  (.) upad place  s"  " +upad
   s" In: <---" +upad +upad   upad"  +log ;

#-2130706456 constant wsPing-      \ The value is reserved for UdpSender.f

: Send1WsPing ( #server - )
\   s" Send1WsPing @" here place dup (.) here +place  here count +log
   wsPing- (.) utmp$ place  space" +utmp$
   s"  wsping " +utmp$
   OwnIP$ count +utmp$
   utmp" rot (SendUdp) 25 ms ;

: TcpPort? ( #server - flag ) r>port @ dup 8080 = swap 80 = or ;

: PingTcpServers ( - )             \ See also -ArpToGforthServers
  CheckGateway
    if  log"  " #servers  0
         ?do  i TcpPort?               \ Filter ports 80 and 8080
               if  i ServerHost <>      \ Exclude myself
                   if   i Send1WsPing
                   then
               then
         loop
     then ;

: ClearTcpServers ( - )
   #servers  0
     ?do  i TcpPort?                \ Filter ports 80 and 8080
          if  i ServerHost <>       \ Exclude myself
               if   i r>Online off
               then
          then
     loop  ;

: SetTcpServerOnline ( buffer len - )
    over >r bl scan  drop  r@ - r> swap
    FindServer# dup 0<
      if   drop
      else dup TcpPort? drop true
             if  r>Online on
             else drop
             then
      then ;

: GetMacList ( - )
   s" sudo arp | grep : | sort >/tmp/maclist.tmp" system ;

tcp/ip definitions

: /UpdateLinks ( - )
   GetMacList  ClearTcpServers
   s" /tmp/maclist.tmp" r/o  open-file drop >r
   begin  upad 90 r@ read-line drop
   while  upad swap SetTcpServerOnline
   repeat
   r> CloseFile drop ;

forth definitions

needs sitelinks.fs         \ To link other Forth servers to a home page

[THEN]

allocate-buffers

: CloseWebserver  ( - )
   web-server-sock 0<>
      if    web-server-sock  closesocket drop 0 to web-server-sock
      then  close-log-file ;

: contain?  ( search$ cnt  WebPacket cnt - flag )
   dup 0>
       if    2swap search  -rot 2drop
       else  2drop 2drop false
       then ;

: send-last-packet ( - )
   beep htmlpage$ lcount aSock @
   -rot make-packet rot send-packet drop
   CloseWebserver ;

: SetHomeLink ( -- )
   GetIpHost$ 1 max dup 1 =
     if    2drop s" 9" homelink$ place
     else  s" http://" homelink$ place
           homelink$ +place s" :" homelink$ +place
           ServerHost r>port @ (.) homelink$ +place
     then ;

: wait-for-connection ( - aSock iaddr )
   web-server-sock accept-socket ;

: LogIpWebserver ( adr cnt - )  +log ;

: http-server ( port - )    \ Started by execute-task
   create-server dup to web-server-sock
    \ .s quit
   dup NoTcpDelay
\   dup reuseaddr
   dup 255 listen
       0x400 SO_RCVBUF Set_SO_Buf
   log" Starting the connection loop"
   &last-line-packet$ count   write-log-line
   begin  wait-for-connection web-server-sock
      while  homelink$ c@ 1 = \ aSock iaddr
                  if  SetHomeLink
                  then
               dup 0<>
                  if  IP-adress-allowed?
                        if    dup handle-web-packet   \ aSock
                        else  log" IP-adress not allowed!"
                        then   [DEFINED]  fd>file
                                  [if]    ShutdownTCPConnection
                                  [ELSE]  close-socket
                                  [THEN]
                  else 2drop
                  then  htmlpage$ off
      repeat 2drop  bye ;

: Starting-http-server ( -- )  ServerHost r>port @ http-server ;

false value tid-http-server
[defined] -status [IF] -status [THEN]

: start-web-server ( -- )
     Log" Activating the web server" \
     initWebServer
           1000 ms log" Web server at: " SetHomeLink homelink$ count 2dup +log
           ServerHost r>HostName count upad place space" +upad (time) +upad
           s" : Webserver started at: " +upad  +upad s" /home" +upad" Wall
     [ [DEFINED] DisableLogging ] [IF] Log" Disable logging" 0 to hlogfile [THEN]
     [ [DEFINED] execute-task ] [IF]   ['] noop is dobacktrace  \ Gforth
                                       ['] Starting-http-server execute-task to tid-http-server \ Background
                                [ELSE] Starting-http-server     \ Win32Forth
                                [THEN]
 \   Starting-http-server  \ Foreground Gforth
   ;


: <yellow-page  ( - )
    StartHeader
    +html| <body bgcolor="#FEFFE6"><font size="4" face="Segoe UI" color="#000000" ><BR> | ;

:  yellow-page> ( - ) +html| </font></body></html>| ;

: IncludeSitelinks ( - )
  +html| <font size="2" > <BR> |
  [ [DEFINED] sitelinks.fs ] [IF] s" /UpdateLinks" Sitelinks [THEN] +html| </font>| ;

: shutdownpage ( - )
    <yellow-page SitesIndex
     +html| <br> <br> *** Shutting down *** <br>| IncludeSitelinks yellow-page> ;

: bye-page     ( - )
    <yellow-page SitesIndex
    +html| <br> <br> *** Bye, Forth *** <br>| IncludeSitelinks yellow-page> ;

0 value #send
3 constant #max-attempts           256 newuser UdpOut$

: UdpOut"    ( - upad count )          UdpOut$ count  ;
: +UdpOut    ( adr cnt -- )           UdpOut$ +place ;
: .UdpOut    ( n -- )                 (.) +UdpOut ;

: ExtractDataLine ( adr cnt - adrData cnt )
   bl NextString  bl NextString  \ skip get cmd
   over swap  s" HTTP/" search
     if    drop  over -
     else  rot drop              \ No HTTP/ found, keep all
     then ;

S" win32forth" ENVIRONMENT? [IF]
DROP

: open-upd-port ( #server port - sock|0 )  1 abort" open-upd-port not defined"  ;
: SendUdp       { msg$ cnt #server -- }    1 abort" SendUdp undefined"   ;

 wTasks webserver-tasks  Start: webserver-tasks


: start-servers ( - )
  \in-system-ok also tcp/ip
  ['] Start-web-server Submit: webserver-tasks
\in-system-ok seal order ;

TCP/IP DEFINITIONS

: DoShutdown    ( -- )
   log" Shuttingdown"  shutdownpage  htmlpage$ lcount aSock @
   -rot make-packet rot send-packet
   down ;

: DoQuit         ( -- )
   log" Exit server."
    <yellow-page SitesIndex
    +html| <br> <br> *** Exit server *** <br>| IncludeSitelinks yellow-page>
\in-system-ok     send-last-packet  cr ." Enter +f to include Forth. Order: " order quit  ;

: DoBye       ( -- )
   log" Bye, Forth." bye-page  send-last-packet
   bye ;

FORTH DEFINITIONS


[ELSE]   \ Gforth

: ((Bye))         ( -- )
   log" Bye, Forth." bye-page  send-last-packet
   s" sudo ./kf.sh" system ;

: (SendTcp) ( msg$ cnt #server -- )    \ No checks Using: SOCK_STREAM (TCP/IP)
    >r s" TCP/IP: ---> " upad place   2dup +upad s"  @" +upad r@ (.) +upad  upad"  +log
    r@ open#Webserver dup 0=
       if    3drop r@ r>Online off
             r>  (.) upad place s"  can not be reached." +upad" +log
       else  dup>r fileno  dup reuseaddr linger-tcp
             SOCK_CLOEXEC r@ SetMode
             r@ send-packet drop r>  close-socket r> drop
       then  ;

 : SendTcp ( msg$ cnt #server -- )     \ With checks Using: SOCK_STREAM (TCP/IP)
    CheckGateway
      if  host-id>#server dup r>Online @
          if   (SendTcp)
          else  (.) upad place s"  is offline." +upad" +log 2drop
          then
      else  3drop drop log" No gateway."
      then ;


200 constant MsWaitTimeConfirmation    \ There schould be a response within 200 ms
50 constant MsWaitUnit

: WaitForF0   ( #server - flag )
   MsWaitUnit ms 0 swap MsWaitTimeConfirmation MsWaitUnit / 1 max 0
     do   dup  Get#F0 0=
              if nip true swap leave    \ Got a conformation
              then
           MsWaitUnit ms
     loop                               \ Look again
   drop ;

80 constant /udp-minimal

: add-id ( adr-target$ - )   >r s"  @" r@ +place    ServerHost (.) r@ +place space" r> +place ;

: InitUdpOutMsg ( msg cnt - )
   UdpOut$  dup>r place
   r@ add-id \ s"  @" r@ +place    ServerHost (.) r@ +place
   /udp-minimal 3 - r@ c@ max spaces$ r@ +place  space" r@ +place
   crlf" r> +place ;


: LogFn  ( flag - )
     if     s" ?"
     else   s" -"
     then  +upad
    s" -->" +upad ;

: logRetryUdpMsg  { msg$ cnt #server -- flag }    \ EG: F0 on server 1 is sent as: F0 @1    xxx
    CheckGateway
       if msg$ cnt InitUdpOutMsg false
          #max-attempts 1+ 1                      \ Depends on: >F0 of #server
                 do   i  (.) upad place s"  UDP: " +upad
                      #server Get#F0  LogFn
                      #server r>ipAdress count +upad space" +upad
                      UdpOut$ count  +upad  crlf" +upad" +log
                      UdpOut$ count #server SendUdp
                      #server WaitForF0
                           if  drop true leave
                           then
                 loop
          0
       else  true dup
       then  #server Set#F0   ;

: SendUdp$ ( msg$ cnt<240 #server --  )         \ Sending a msg and not waiting for a confirmation
    dup ServerHost <>                           \ Exclude myself
       if    dup WaitForF0 drop 0 over Set#F0   \ without retries
             logRetryUdpMsg drop
       else  3drop
       then ;

: SendUdpRt$ ( msg$ cnt<240 #server --  flag )  \ 1: Sending a msg like s" Gforth::LowLight " 0 SendUdpRt$
    dup ServerHost <>                           \    and wait for a confirmation for 200 ms. T
       if    dup WaitForF0 drop 0 over Set#F0   \ NO retries, The receiver should send a Confirmation.
             logRetryUdpMsg          \ It takes about 37 ms on my network to get a confirmation
       else  3drop
       then ;

: SendConfirmUdp$ ( msg$ cnt<240 #server --  flag )  \ Sending a msg and wait for a confirmation
    dup ServerHost <>                \ for 600 ms. The receiver should send a Confirmation.
       if    dup WaitForF0 drop
             dup true swap Set#F0    \ WITH retries (max 3* after 200ms)
             logRetryUdpMsg          \ See SendConfirmation
       else  3drop false
       then ;

: SendConfirmation ( &IncommingPacket cnt - )           \ 2: By the receiver. The sender is extracted from the incomming packet.
    FindSender                                          \ See .servers for their ID
            if     s" /F0 Confirm"  utmp$ place
                    utmp$ add-id  utmp$ count
                   rot SendUdp                          \ Sent the confirmation
            else   drop
            then ;

\ &Packet cnt looks like: '/F0 Confirm @1 '
\ 3: The sender resets the flag in Confirmations?

: sent-arp ( server# - )
   s"  -arp " utmp$ place GetIpHost$  +utmp$
   utmp" rot SendUdp$ ;

: -ArpToGforthServers ( - )     \ see also  PingTcpServers
   range-Gforth-servers 2@
     ?do  i ServerHost <>       \ Exclude myself
               if   i sent-arp
               then
     loop  ;

: SentNewArp ( - )
   s" GET arpnew" utmp$ place utmp" AdminServer dup 0>
     if   SendUdp$
     else 3drop
     then
   log" " ;


TCP/IP DEFINITIONS

: DoShutdown    ( -- )
   log" Shuttingdown"  shutdownpage  htmlpage$ lcount aSock @
   -rot make-packet rot send-packet
   -ArpToGforthServers
    aSock fileno ShutdownConnection
   down quit ;

: DoReboot ( - )
   s" Rebooting" +log
   <yellow-page s\" *** Rebooting *** <br>" +html IncludeSitelinks yellow-page>  send-last-packet
   s\" sudo shutdown 0 -r " ShGet 0 0 sh$ 2! bye ;

: DoQuit         ( -- )
   log" Exit server."
    <yellow-page SitesIndex
    +html| <br> <br> *** Exit server *** <br>| IncludeSitelinks yellow-page>
     send-last-packet  cr ." Enter +f to include Forth. Order: " order cold  ;

: DoBye       ( -- )
   log" Bye, Forth." bye-page  send-last-packet 25 ms
   ((bye)) ;

: ` ( - )  0 to web-server-sock bye ;


FORTH DEFINITIONS


create udpin$ 80 allot

: logLinuxError ( n - )
   -1 =
      if   -512 errno - >stderr error$ +log
      then ;

: read-udp-server  ( server c-addr maxlen -- addr size|0 )
    swap dup >r cell+ swap msg_waitall recv
    \ dup logLinuxError \ ignore
    0 max   \  No checks make size 0
    r> 2dup ! cell+ swap ;


: see-UDP-request ( adrRequest lenRequest -- )
   cr  .date space .time cr ."  UDP Request, "
   ms@ >r ." evaluate: " 2dup type
   evaluating_tcp/ip ms@ r> -
   cr 20 0 do [char] . emit loop  space . ." ms." cr ;

defer udp-requests  ( adr len --)

 ' evaluating_tcp/ip is udp-requests

0 value Udp-server-sock

: Udp-server ( - )
   UdpPORT  create-udp-server dup to Udp-server-sock
     begin  web-server-sock
     while  Udp-server-sock   udpin$ dup off
            80 ['] read-udp-server catch
               if      ." read-udp-server failed"  2drop
               else     dup 0>
                        if    2dup remove_seperators  2dup s" UDP In" LogRequest
                              2dup Confirmations?
                                   if   2drop
                                   else udp-requests
                                  then
                        else  2drop
                        then
               then
            pause
   repeat
  cr ." Udp-server Ended"
  Udp-server-sock close-socket bye ;

0 value Tid-Udp-server

: fsearch   ( c-addr1 u1 c-addr2 u2 c-filename3 u3 -- u4 flag )
   2dup file-status 0= \  u4 = characters remaining in the file
      if    drop r/w map-file
            2dup 2>r 2swap search 2r> unmap-file rot drop
      else  2drop 2drop drop 0 false
      then ;

: TmpDir ( - adr_counted$ )
   s" /tmp" file-status nip 0>=
     if    s" /tmp/" upad place
     else  0 upad !
     then  upad count ;

: Add/Tmp/Dir ( &filename cnt - &/tmp/filename cnt )
   TmpDir upad place +upad" ;

: start-servers ( - )
   tcp/ip seal
     [DEFINED] DisableUpdServer [IF]
     [ELSE]    ['] Udp-server execute-task to Tid-Udp-server \ Start the udp server
     [THEN]
   s" yes" s" background.log"  Add/Tmp/Dir  fsearch nip      \ See also gf.sh for background operations
      if   s" background.log"  Add/Tmp/Dir r/w  open-file throw
           dup s" Done! " rot write-file throw
           close-file drop
           ['] noop IS dobacktrace
     then
   start-web-server 200 ms
   PingTcpServers
   [ [DEFINED] LockConsole ]    [IF] LockConsole ." console NOT locked"  [THEN]
 ;


[THEN]

0 value #received \  for stats.

\s


