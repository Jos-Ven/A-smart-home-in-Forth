marker slave.fs  \ To update the configuered Gforth systems in a network.

needs Common-extensions.f
needs Sun.f
Needs Web-server-light.f
needs webcontrols.f
needs uptime.fs
needs LoadAvg.fs
needs chains.fs
needs autogen_ip_table.fs  \ Set parameters first at the start of autogen_ip_table.fs


variable exit-chain
defer KillTasks    ' noop is KillTasks
' KillTasks exit-chain chained

2000 value ngettime \ Next time at 20:00
: -name" \ Compiletime: ( - ) Runtime: ( - Name -cnt )
   last-lit, postpone name>string postpone negate ; immediate

[defined] hMapIpTable
    [if]      : UnmapIpTable ( - )   hMapIpTable 2@ ['] unmap catch
                     upad /pad erase  upad to &servers ;
    [else]    : UnmapIpTable ( - )  ;
    [then]

: CloseSaveLogging ( - )
   cr ." CloseWebserver"  CloseWebserver
\   cr ." UnmapIpTable"    UnmapIpTable  \ uncaught exception: Invalid memory address
    ;

' CloseSaveLogging exit-chain chained

: RestartGforth ( - )
   cr .current-time&date ."  Restarting Gforth."
   log" Running the exit-chain. "
   exit-chain chainperform
   s" sudo ./gf.sh" system \ Must also kill gforth if still exist!
  bye
   ;

: RemoveNupdate.sh ( - )
  s" nupdate.sh" file-status nip not
     if   s" sudo cp -f nupdate.sh nupdate.tmp" system
          s" sudo rm -f nupdate.sh" system
     then ;

RemoveNupdate.sh

: RunLinuxScript ( - flag )
    s" nupdate.sh" file-status nip not       \ run a received nupdate.sh
       if    log" Executing nupdate.sh"
             s" sudo chmod +x *.sh" system
             s" sh ./nupdate.sh >nupdate.log" system
             true
       else  false
       then  ;

: UpdateThisSystem ( - ) \ Look for an update
    log" *** Updating files with nget ***"
     s" sh ./nget.sh >nget.log" system \  get the updates
    RunLinuxScript
       if     RestartGforth  \ Will also enable ping again after a restart
       else   log" No nupdates received"
       then ;

: WaitTillnget ( -- )
    begin  cr ." Update from the NAS planned at: " ngettime .mh
           ngettime  WaitUntil UpdateThisSystem
    again ;



20 constant /max-host$
create StateResp$ ," State"

0 value ErrorWebApp-


: GetTimeFromMaster ( - )
   s" AskTimeUdp" AdminServer SendUdp$ ;

also html

: ConsoleLogFile ( - adr cnt )  s" gf.log" ;

: GfLogs    ( - )
    ConsoleLogFile file-status nip
       if    s" No gf.log found.  "  htmlpage$ +lplace
       else  s" The last part of gf.log: " ConsoleLogFile IncludeFile
       then ;

: WebLogs   ( - )
    hlogfile dup 0<>
      if    flush-file drop
      else  drop
      then
    s" The last part of the web logging: " logFile" IncludeFile ;

: LogLinks ( - )
      HTML| 1. | +HtmlNoWrap  HTML| /gflogSlv|  HTML| Console| <<Link>>
      HTML|  2. | +HtmlNoWrap  HTML| /updlogSlv| HTML| Update|  <<Link>>
      HTML|  3. | +HtmlNoWrap <aHREF" +HTML| /weblogSlv">|  HTML| Web activity | +HtmlNoWrap </a> ;


: SlaveLinks ( - )
      +HTML| Loggings: | ErrorWebApp-
         if   +HTML|  <strong> (with error) </strong> |
         then
      <br> LogLinks ;

: .ErrorWebApp ( - )
    ErrorWebApp-
       if    GfLogs
       then ;

: SlaveSite   ( - )
    <tr> <tdLTop>  SlaveLinks </td>
         <tdLTop>  +HTML| Links: | <br> s" /UpdateLinks" SiteLinks </td>
     <tr> 2 <#tdR>  .GforthDriven  </td></tr> ;

defer SosLayout

: "SlaveLayout ( title cnt - ) NearWhite 0 <HtmlLayout> SlaveSite  ;

: SlaveLayout ( - ) \ Starts a table in a htmlpage with a legend
   s" Logging slave" "SlaveLayout ;

' SlaveLayout is SosLayout

: SlavePage ( - htmlpage$ lcount )
    SosLayout
    <tr> 2 <#tdL>  .ErrorWebApp  </td></tr>
    <EndHtmlLayout> ;

: ClearArpTable ( - )
   log" ClearArpTable " s" sudo ip neigh flush all" system
   ['] PingTcpServers execute-task drop ;


: gflogSlv ( - )
    SosLayout  <tr> 2 <#tdL>  GfLogs  </td></tr>
    <EndHtmlLayout> ;

: weblogSlv ( - )
    SosLayout  <tr> 2 <#tdL>  WebLogs </td></tr>
    <EndHtmlLayout> ;

: updlogSlv  ( - )
    s" rm -f updatelog.tmp" system
\    s" echo Received: >updatelog.tmp" system

    FindOwnId r>Master @
       if    s" cat npush.log >>updatelog.tmp"
       else  s" cat nget.log >>updatelog.tmp"
       then
    system

    s" echo . >>updatelog.tmp" system
    s" echo ---- End ---- >>updatelog.tmp" system

    s" cat nupdate.log >>updatelog.tmp" system

    SosLayout
    <tr> 2 <#tdL>  s" The last part of the update logging: "
               s" updatelog.tmp" IncludeFile </td></tr>
    <EndHtmlLayout> ;


: ArpPage             ( -  )
    s"  " NearWhite 0 <HtmlLayout> \ Starts a table in a htmlpage with a legend
    <tr>
    GetMacList
    s" Last part of the arp-scan : " s" /tmp/maclist.tmp" IncludeFile

      .HtmlSpace s" /ArpPage "   +HTML| <a href="| +homelink +HTML +HTML| ">|
         +HTML| Refesh | +HTML| </a>|

      .HtmlSpace s" /RebuildArpTable "   +HTML| <a href="| +homelink +HTML +HTML| ">|
         +HTML| Rebuild tabel | +HTML| </a>|
    </tr>
    <EndHtmlLayout>  ;


: check-ip4? ( adr cnt - adr cnt|0 )
   3 SkipDots 2dup s>number?
     if    2drop  GetIpHost$ 2dup 3 SkipDots nip -
           upad place +upad upad"
     else  2drop 2drop 0 0
     then ;

: RemoveFromArp  ( ip4$ cnt - )
  check-ip4? dup
     if    s" sudo arp -d " tmp$ place
           tmp$ +place
           tmp$ count system
     else  2drop
     then  ;


8899 constant IPPORT_UDP
-2130706460 constant AnswerWsPingCode

: AnswerWsPing ( ip4$ cnt -- )
   check-ip4? dup
    if   IPPORT_UDP SOCK_DGRAM IPPROTO_UDP open-port-socket  dup 0<>
            if  >r  AnswerWsPingCode (.) utmp$ place
                s"  PingReply " +utmp$ GetIpHost$ +utmp$
                utmp"  r@ send-packet drop r> close-socket
                log"  "
            else   drop  s"  Failed to open port." +utmp$ utmp"  +log
            then
    else  2drop
    then  ;


false value RebuildArpTable- \ see also schedule_daily.fs

tcp/ip definitions

: Ignore-remainder ( - ) postpone \ ;

: /gflogSlv	( - ) ['] gflogSlv   set-page ;
: /weblogSlv	( - ) ['] weblogSlv  set-page ;
: /updlogSlv	( - ) ['] updlogSlv set-page ;

: /ArpPage	( - ) ['] ArpPage    set-page ;
: -arp		( <ip4> - )  parse-name RemoveFromArp Ignore-remainder ;
: /RebuildArpTable  ( - ) ClearArpTable  /ArpPage  ;

: PingReply	( AnswerWsPingCode - ) drop Ignore-remainder ; \ For the ARP-table

: wsping	( wsping- <ip4> - ) drop parse-name AnswerWsPing Ignore-remainder ; \ The OS needs some traffic for the ARP-table

: Gforth::Time ( - )
   udpin$ lcount bl NextString
     [char] t  bl ExtractNumber?
     if     d>f Time&Date-from-UtcTics
            utmp$ off  html| sudo date -s  "| +utmp$
            +PlaceYmdTime  s"  UTC" +utmp$    html| "| +utmp$
            utmp" ShGet 2drop
            @time ftime" s" New time: " upad place +upad" +log
            RebuildArpTable-
              if  PingTcpServers ( ClearArpTable ) false to RebuildArpTable-
              then
    then  Ignore-remainder ;

: Gforth_State ( - ) \ To the AdminServer from a slave
     s" Gforth::State >" utmp$  place
     hostname$  count    +utmp$
     s"  V" +utmp$  &Version @  ErrorWebApp- if   negate   then  (.) +utmp$
     s"  U" +utmp$ GetUptime    (.) +utmp$
     s"  L" +utmp$ 5mLoadAvg 100e f* f>s     (.) +utmp$
     utmp" AdminServer 0 max SendUdp$ Ignore-remainder ;

:  Gforth_UpdateSignal  ( - )   UpdateThisSystem ;  \ Update this client from Forth through sock.


FORTH DEFINITIONS PREVIOUS


: NtpActive? ( - flag )
   s" timedatectl | grep synchronized" ShGet s"  yes" search nip nip ;

needs schedule_daily.fs       \ Actions at a planned time.

cr .( NTP is ) NtpActive? not [if] .( NOT )  [then] .( active.)

defined Master.fs not [if]

: TimeCheck ( - )
   stacksize4 NewTask4 activate NtpActive?
      if    ['] restart-ntp-service is sync-time
            log" No time synchronisation with the master."
      else  30000 ms
               begin   web-server-sock
               while   GetTimeFromMaster #Ns2Hours ns
               repeat
            cr .date space .time ."  Bye TimeCheck" Bye
      then ;

' TimeCheck init-webserver-gforth-chain chained

[else] ' restart-ntp-service is sync-time
[then]

SentNewArp

\s

