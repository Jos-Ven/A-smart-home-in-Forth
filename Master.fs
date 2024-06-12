needs slave.fs             \ For restarting / updating it self. 20-4-2023
cr marker Master.fs  .latest
needs autogen_ip_table.fs  \ Set parameters first at the start of autogen_ip_table.fs

\ A system can be Offline. That happens when it could not be pinged
\ A negative version number means: An update has been sent. No new version number received yet.
\ Send a new IP table to a system that is no longer used as a master
\ otherwise it wil not sent it's version number to it's master

FindOwnId SetMasterIndication

: NegateR>Version ( server# - )
   r>Version dup @ negate swap ! ;

: SentUpdateSignal1System ( #server - )
    dup NegateR>Version
    s" Out: UpdateSignal to server " upad place
    dup (.) +upad crlf$ count +upad" +log
    s" Gforth_UpdateSignal"  rot SendUdp$ ;

: SetVersionFile ( n - )
    &Version cell+ count r/w map-file
    >r  tuck !  r> unmap ;

: IncreaseVersionFile ( - )
   &Version cell+ count r/w map-file
   over @ 1+ -rot unmap
   SetVersionFile ;

create nupdate.sh$ ," nupdate.sh"

: WriteFirstCharE ( - ) \ Making sure it will be copied since it has been changed.
  nupdate.sh$ count r/w open-file throw >r
  s" e" r@ write-file throw
  r> CloseFile ;

: (SentUpdateSignalToAllSystems ( - ) \ Sends a update to all systems
   WriteFirstCharE
   s" ./npush.sh >npush.log" system   \ copy the changed files to the NAS
   log" *** UpdateAllSystems version: ***"
   GetVersion# &Version @ (.) +log
   range-Gforth-servers 2@
      ?do    i ServerHost <>  \ Excl SELF
                if   i  SentUpdateSignal1System
                then
      loop ;

: SentUpdateSignalToAllSystemsToSync  \ Connected systems Update when their version number
  (SentUpdateSignalToAllSystems       \ is different.
  RestartGforth ;                     \ NO linux scripts are executed on the host

: SentUpdateSignalToAllSystems
   (SentUpdateSignalToAllSystems
   RunLinuxScript drop  \ Runs the linux script nupdate.sh
   RestartGforth ;

: ExtractNumberBetween?= ( pkt cnt -  d1 flag )
     [char] ? [char] = ExtractNumber? ;

: UpdateHostInTable ( hostnameResp$ count #server - ) \ When needed
   dup>r r>HostName 1+ c@ bl =
    if    r> r>HostName place
    else  r>drop 2drop
    then  ;

also html
: <TdVersionColored> ( Version - )
    dup 0>
      if    <td>
      else  ButtonWhite <tdColor>
      then
    +AppVersion +html  ;

: ReportHostToHtmlBuffer ( #server - )
   >r <tr><tdL> <strong> +HTML| *| hostname$ count 2dup r@ UpdateHostInTable +html </strong> </td>
           &Version @ <TdVersionColored> </td>
           <tdR> GetUptime   Uptime>Html </td>
           <td>  5mLoadAvg (f.2) +html   </td>
           <td>  s" Update" r> (.) <GreyBlackButton> </td></tr> ;

: ReportOfflineToHtmlBuffer (  #server - )
    <tr><td> r>HostName count +html </td>
    4 <#tdC>  +HTML| Offline |  </td></tr> ;

: NetWorkStateHeader
    <tr><td>  +HTML| System:|  </td>
        <td>  +HTML| Version:| </td>
        <td>  +HTML| Uptime:|  </td>
        <td>  +HTML| 5m&nbsp;Load:|   </td>
        <td>  +HTML| 1&nbsp;System:|  </td></tr> ;

: ReportRemoteToHtmlBuffer ( #server - )
    >r <tr><td>  r@ <strong> Sitelink </strong> </td>
                 r@ r>Version @ <TdVersionColored>  </td>
           <tdR> r@ r>Uptime  @ Uptime>Html </td>
           <td>  r@ r>5mLoad  @ s>f 100e f/ (f.2) +html </td>
           <td>  s" Update" r> (.) <GreyBlackButton>   </td></tr> ;

: ReportNetWorkStates ( -  )  \ After /UpdateLinks
   NetWorkStateHeader  range-Gforth-servers 2@
       ?do  i r>Online @
               if  i ServerHost =
                    if    i ReportHostToHtmlBuffer
                    else  i ReportRemoteToHtmlBuffer
                    then
              else i ReportOfflineToHtmlBuffer
              then
      loop ;

: GetGforth_States ( - )
  log" *** Get network state ***"
  range-Gforth-servers 2@
       ?do  i r>Online @
            if  s" Gforth_State?" i SendUdp$
            then
       loop ;

0 value UpdateOption

: +UpdateOption ( UpdateOption - )
        case
        0 of s" Restart Gforth and compile."      endof
        1 of s" Remove *.bak* and *.tmp files."   endof
        2 of s" Update Linux."                    endof
        3 of s" Update Gforth after download."    endof
        4 of s" Update the ip table and iplist.txt." endof
        5 of s" Reboot."                          endof
        6 of s" Shutdown."                        endof
                abort" Invallid update option."
        endcase +HtmlNoWrap ;

: HtmlContent ( - )
    <tr> 3 <#tdL> <aHREF" +homelink  +HTML| /Admin/Settings ">| HTML| Update settings:| +HtmlNoWrap </a>
       .HtmlSpace UpdateOption +UpdateOption </td>
         <td>  s" UpdateNas" 0 (.) <GreyBlackButton> </td>
</tr>
    <tr><tdL> +HTML| All&nbsp;systems:| </td>
        <td>  s" Scan"  s" AdminScan" <GreyBlackButton> </td>
        <td>  s" Synchronize" 0 (.) <GreyBlackButton> </td>   \ Feedback of the last given command
        <td>  s" UpdateAll"  31 (.) <GreyBlackButton> </td></tr>

        <tr> 4 <#tdC>  <fieldset>  <legend>
             +HTML| Network report | (date) +html +HTML| , | (time) +html  </legend>
             ltBlue ltBlue  ltBlue SetColorsTableBorders
             90 100 0 4 1 <table>  ReportNetWorkStates  </table>
             Black Black  Black SetColorsTableBorders   </fieldset> </td></tr> ;

: +HTML_BuildTime ( - )
    q_elapsed
    +HTML| Build time: |
    (ud,.) +HTML +HTML|  Ms.| ;

: VersionLink ( Version - )
   +HTML|  vs:| <aHREF" +homelink  +HTML| /Admin/SetVersion ">|
   +AppVersion +html </a> ;

: 3tablesExtraLink { legendtxt$ cnt bgcolor Border -- }
   +HTML| <body bgcolor=| bgcolor "#h." +html >| <form> <center>
   10 10 0 1 0 <table> <tr> <tdCTop> \ A table to lock all tables
   10 10 0 1 0 <table> <tr> <tdLTop> \ A table to lock the inner table
   <fieldset>  <legend>  SitesIndex  HomeLink  legendtxt$ cnt +HTML
            &Version @ dup 0>
                if    VersionLink
                else   drop
                then  </legend>
   +HTML| <font size="3" face="Segoe UI" color="#000000">|
    10 10 0 4 Border <table>  ( w% h% cellspacing padding border -- ) ;

: <HtmlLayoutMod> ( legendtxt$ cnt bgcolor Border - )
    htmlpage$ off <html5> <html> <head> <<NoReferrer>> 2over
    Html-title-header CssStyles </head> 3tablesExtraLink ;

0 value (server)

ALSO TCP/IP

: AdministrationPage ( - )
   /UpdateLinks GetGforth_States
    s"  Administration" NearWhite 0 <HtmlLayoutMod> HtmlContent
   <tr>  3 <#tdL> +HTML_BuildTime </td>
           <tdR> .GforthDriven   </td></tr>
   <EndHtmlLayout> ;

Needs SetVersionPage.fs

: SentUpdateSignal#System ( #server - )   \ Uses an iptable
   dup r>ipAdress count   ServerHost r>ipAdress count   compare 0=  \ OwnIP?
     if   drop &Version @ negate &Version !
               AdministrationPage htmlpage$ lcount send-last-packet
               RunLinuxScript drop  RestartGforth
     else  s" ./npush.sh >npush.log" system
           SentUpdateSignal1System
     then ;


2500 constant TimeoutUpdate

: SubmitUpdate ( - ) \ Send an update signal to all other systems
   ['] SentUpdateSignalToAllSystems execute-task drop
   TimeoutUpdate ms  ;

: AllShutDownWarning ( - htmlpage$ lcount )
   s" Shutting ALL down, continue?" s" DoSentShutdownSignalToAllSystems" ['] y/nPage set-page ;


\  update => push RunLinuxScript restart
: DoSentUpdateSignalToAllSystems ( - ) \ Also increases the version number
   timer-reset IncreaseVersionFile
   UpdateOption 6 =
     if     AllShutDownWarning exit
     else   SubmitUpdate
     then  ;

: <<UpdateButton>> ( buttontxt cnt - )
   <tr><td>  2dup upad place s" UpdateHit" +upad upad count <CssButton> </td> ;

: WriteStartNupdate.sh ( - hdnl )
   nupdate.sh$ count r/w create-file throw >r
   s" echo Running nupdate.sh" r@ write-line throw
   s" date" r@ write-line throw r> ;

: WriteEndNupdate.sh ( hdnl - )
  >r s" date" r@ write-line throw
  s" echo End nupdate.sh" r@ write-line throw
  s" exit 0" r@ write-line throw
  r> CloseFile
  s" sudo chmod +x " upad place nupdate.sh$ count +upad" system ;

: <<UpdateButtonOption>>  ( buttontxt cnt Option - )
    -rot <<UpdateButton>>  <tdL> +UpdateOption  </td></tr> ;

: UpdateOptions ( - )
  s" Normal"   0 <<UpdateButtonOption>>
   <tr> 2 <#tdC> +HTML| Linux scripts:| </td></tr>
  s" Cleanup"  1 <<UpdateButtonOption>>
  s" Linux"    2 <<UpdateButtonOption>>
  s" Gforth"   3 <<UpdateButtonOption>>
  s" IPtable"  4 <<UpdateButtonOption>>
  s" Reboot"   5 <<UpdateButtonOption>>
  s" Shutdown" 6 <<UpdateButtonOption>>
  s" TimeSync"   <<UpdateButton>>
       <tdL> HTML| Time sync. to network.| +HtmlNoWrap </td></tr>
  s" Execute"    <<UpdateButton>>
       <tdL> HTML| Execute the linux script on this system. | +HtmlNoWrap </td></tr>
       <tr> <tdL> s" Shutdown" s" AskShutDownPage"  <CssButton>  </td>
             <tdL> +html| Shutdown master.|  </td></tr>
        ;

: AdminLink    ( - ) <aHREF" +homelink  +HTML| /Admin ">|  +HTML| Administration | </a> ;

: SetUpdateSettingsPage ( - )
   s"  Update settings" NearWhite 0 <HtmlLayout>
   <tr> 2 <#tdL> +HTML| To: | AdminLink <br>
    +HTML| for a push and: | UpdateOption +UpdateOption <br> </td></tr>
    UpdateOptions
   <EndHtmlLayout> ;

: WriteNupdate.sh ( cmd$ cnt UpdateOption - )
  to UpdateOption
  WriteStartNupdate.sh >r
  r@ write-line throw
  r> WriteEndNupdate.sh ;

: SetUpdateSettings ( cmd$ cnt UpdateOption  - htmlpage$ lcount )
   WriteNupdate.sh  SetUpdateSettingsPage  ;


: ShutDownWarning ( #server -  )
     to (server) s" Shutting down, continue?"
     s" DoSentShutdownSignal1System"  ['] y/nPage set-page ;



: WaitTillNextSec ( - )   @time  1e f+ ftrunc @time f- Nanoseconds f* f>d ns ;

: SendTimesync    ( #server - )
   s" Gforth::Time t" utmp$ place
   WaitTillNextSec @time f>d (d.) +utmp$
   utmp" rot SendUdp$ ;


: StartTimesync    ( #server - ) 1 stacksize4 NewTask4 pass SendTimesync short-timeout ;

: DoTimesync ( pkt cnt - )
   FindSender
     if    StartTimesync
     else  drop
     then    ;

: +fd>Udp-line2$  ( f: n - ) f>d (d.) UdpOut$ +place s"  "  UdpOut$ +place ;

: SendTCPTimesync    ( #server - )
   s" GET " UdpOut$ place
   WaitTillNextSec @time fdup    +fd>Udp-line2$ \ Time in UtcTics
     UtcOffset        +fd>Udp-line2$
     date-now sunrise +fd>Udp-line2$
     date-now sunset  +fd>Udp-line2$
   s" TcpTime HTTP/1.1" UdpOut$ +place
   UdpOut$ count rot  SendTcp drop ;

: SendTCPTimesyncToAll ( - )
    #servers 0
       do  i r>Online @
             if  i ServerHost <>
                   if   i SendTCPTimesync
                   then
             then
       loop ;

: CopyIpTable ( - ) s" cp ip_table.bin ip_table.fbin" system ;

: MsgGfSlavesRebuildArpTable ( - )
    range-Gforth-servers 2@
     ?do  i TcpPort?                \ Filter ports 80 and 8080
          if  i ServerHost <>       \ Exclude myself
               if   s" GET /RebuildArpTable" i SendUdp \ SendUdp$
               then
          then
     loop log" " ;


 s" # None" s" nupdate.sh" fsearch nip not
 [if]   s" # None" 0 WriteNupdate.sh
 [then]

: MasterSite   ( - )
    <tr> <tdLTop>  SlaveLinks </td>
         <tdLTop>  +HTML| Links: | <br> s" /UpdateLinks" SiteLinks </td>
     <tr><tdL> <strong> HTML| System: | +HtmlNoWrap AdminLink </strong> </td>
         <tdR> .GforthDriven  </td></tr> ;

: MasterLayout ( - ) \ Starts a table in a htmlpage with a legend
   s" Logging master" NearWhite 0 <HtmlLayout>  MasterSite ;

' MasterLayout is SosLayout

: MasterPage ( - )
    MasterLayout
    <tr> 2 <#tdL>  .ErrorWebApp  </td></tr>
    <EndHtmlLayout> ;


previous


TCP/IP DEFINITIONS \ Adding the requests to the tcp/ip dictionary

\ Administrations page:
: /Admin			( - ) 	['] AdministrationPage set-page ;
' noop alias AdminScan   \ Used after the scan button on the AdministrationPage
' noop alias Scan        \ Used after the scan button on the AdministrationPage

: UpdateNas                     ( n - )
   drop timer-reset IncreaseVersionFile   s" ./npush.sh >npush.log" system  GetVersion#  ;

: Update                        ( #server -  ) \ Update the NAS and increase the version number
     UpdateOption 6 =
        if    ShutDownWarning
        else  IncreaseVersionFile  SentUpdateSignal#System     \ Send the update signal to 1 system
        then ;

: UpdateAll                     ( - ) \ Also increases the version number
   timer-reset IncreaseVersionFile
   UpdateOption 6 =
     if     AllShutDownWarning
     else   SubmitUpdate
     then  ;

: Synchronize                   ( -  ) \ Leave the version number unchanged
   timer-reset UpdateOption 6 =
     if    AllShutDownWarning exit
     then
   ['] SentUpdateSignalToAllSystemsToSync execute-task drop \ Send an update signal to all systems
   TimeoutUpdate ms ;

: DoSentShutdownSignalToAllSystems ( - )  timer-reset 6 to UpdateOption  SubmitUpdate ;

: DoSentShutdownSignal1System   (  - ) \ After yes on ShutDownWarning
   timer-reset s" ./upd_shutdown.sh" 6 WriteNupdate.sh
   IncreaseVersionFile  (server) SentUpdateSignal#System ;


\ Version page:
: /Admin/SetVersion		( - ) 	['] SetVersionPage set-page ;
: VersionCancel	  		( - )   2drop /Admin ;


\ Update settings page:
: /Admin/Settings		( - )   ['] SetUpdateSettingsPage set-page ;
: NormalUpdateHit		( - ) s" # None" 0 WriteNupdate.sh ;
: CleanupUpdateHit		( - ) s" ./upd_cleanup.sh"  1 WriteNupdate.sh ;
: LinuxUpdateHit		( - ) s" ./upd_os.sh"       2 WriteNupdate.sh ;
: GforthUpdateHit		( - ) s" ./upd_gforth.sh"   3 WriteNupdate.sh ;

: IpTableUpdateHit		( - ) CopyIpTable  s" iplist.txt" FileIps
                        s" cp ip_table.fbin ip_table.bin"   4 WriteNupdate.sh ;

: RebootUpdateHit 		( - ) s" ./upd_reboot.sh"   5 WriteNupdate.sh ;
: ShutdownUpdateHit		( - ) s" ./upd_shutdown.sh" 6 WriteNupdate.sh  ;
: ExecuteUpdateHit		( - ) s" bash ./nupdate.sh >./nupdate.log" system  ;
: TimeSyncUpdateHit             ( - ) SendTCPTimesyncToAll /admin ;

: Gforth::State			( - )
     udpin$ lcount
     2dup FindSender swap dup>r #servers <= swap and
             if    2dup  [char] > bl Find$Between   r@ UpdateHostInTable
                   2dup  [char] V bl ExtractNumber? drop d>s r@ r>Version !
                   2dup  [char] U bl ExtractNumber? drop d>s r@ r>Uptime !
                         [char] L bl ExtractNumber? drop d>s r> r>5mLoad !
             else  r>drop 2drop
             then
    Ignore-remainder
       ;

\ Other options
: Gforth_Time	( <serverID> - )  parse-name +blank" DoTimesync  ;
' Gforth_Time alias AskTimeUdp

: TcpTime	( <serverID> - )  \ After removing the "?" of TcpTime?
   0 set-page parse-name  +blank" FindSender
      if    SendTCPTimesync Ignore-remainder
      else  drop
      then ;

: ask_time ( host-id - )
   dup 256 <=
    if    dup host-id>#server r>Online on SendTCPTimesync
    else  drop log" Invalid host-id"
    then ;

: arpnew			( - ) MsgGfSlavesRebuildArpTable  Ignore-remainder ;


FORTH DEFINITIONS


\s
