marker UdpSender.f s" gforth" ENVIRONMENT? [IF] 2drop .latest [THEN] \ 13-07-2023

0 [if]

The protocol is intended to send ASCII files to
an ESP-12F or ab ESP32 on a local network.
The receiver uses rcvfile.fth under cforth.

The protocol assumes the receiver has been started with 'r' and does the following:

1) The sender sends the file size and the filename of the file to be send to the receiver.
2) The receiver prepares a flash-session and sends a "/udpf " packet back
3) Then the sender sends the file in UDP packets to the receiver.
4) When the sender is ready it sends an AllDone packet.
5) Then the receiver asks for the missing packets.
6) When all packets are received the receiver sends: -1 ask-missing-packet
7) The sender ends the session by closing the file.

There are 2 kinds of packets in use/
1.) A data packet contains a positive number containing the position of the data to be saved and its data.
2.) An info packet contains a negative number and one or more parameters.

[THEN]

\ ------- Parameters
\ if UdpTimeOut is too small the UPDpackket can get corrupted. That might damage the file!
 45 value UdpTimeOut   \ For a slow wifi networks: 45 / 30

8899 constant IPPORT_UDP     \ UDP port to send the file to be flashed

\ The webserver uses port 8080 as the tcp-port

\ The following &UdpPacket must be same as in rcvfile.fth
12                      constant /num
/num                    constant DataOffset
768                     constant /UdpData
/UdpData   DataOffset + constant /UdpPacket

create &UdpPacket /UdpPacket allot

&UdpPacket DataOffset + constant &UdpData

4 constant /CellRcv \ cforth is 32 bits
\ Used in exe-vector in rcvfile.fth
0x7F000000 dup constant FlashCmd       \ 2130706432
/CellRcv + dup constant LoadCmd        \ 2130706436
/CellRcv + dup constant RebootCmd      \ 2130706440
/CellRcv + dup constant CheckCmd       \ 2130706444
/CellRcv + dup constant AllDone        \ 2130706448
/CellRcv + dup constant reserved       \ 2130706452 \ For extra applications
/CellRcv +     constant (WsPing)       \ 2130706456 \ For WsPing


 variable flAdress
 variable flSize
 variable fldone
 variable #fl-retries

create report$ 260 allot

20 constant UDP_CHECKSUM_COVERAGE
0  value MsFlash
0  value udp-sock-client

\ ------ Tools
: send-udp-pack-client ( &udp-pack count  - )
     s" udp-sock-client  send-packet drop"   evaluate ; immediate

: BlData            ( - )          spcs  &UdpPacket DataOffset cmove ;
: SetFlashPosition  ( Position - ) s" (.) &UdpPacket  swap cmove"  evaluate ; immediate
: PackInfo          ( n - )        BlData negate SetFlashPosition ;
: FlashReady?       ( - flag )     flAdress @ 0= ;
: SetData   ( n &Data- )         dup>r /num bl fill (.) r> swap cmove ;
: SetIp4    ( Ip4Server$ cnt - ) &UdpData /num 2 * + 1 -  place ;
: SetFilename ( fname$ cnt - )   &UdpData /num 4 * + 1 - dup>r place s"  " r> +place ;
: SetSIze   ( Size - )           &UdpData /num + SetData ;
: SetSector ( sector - )         &UdpData SetData ;
: +report$  ( adr cnt - )        report$ +place ;
: +.report  ( n - )              (.) +report$ ;
: SentInfoPacked    ( nAbs - )   &UdpPacket /num bl fill  PackInfo
                                 &UdpPacket /num 10 * send-udp-pack-client ;
: ReportDate ( - )
   (date)  report$ place s"  "  +report$ (time)  +report$ s" .<BR>" +report$ ;

: ReportNoReply ( - )
   ReportDate
   s" NO reply yet, check report. <br> Or receiver not started, bad connection, or receiver offline."  +report$
   s"  TCP port "     +report$ HtmlPort   +.report
   s"  and UDP port " +report$ IPPORT_UDP +.report
   s"  must be allowed."                  +report$ ;


\ ------ The send protoccol

defer retry-cmd     ' noop is retry-cmd

: Send-CheckCmd ( - )
   ServerHost  r>ipAdress count SetIp4
   CheckCmd SentInfoPacked ;

variable ConnectionRes

: 0TestConnection  ( - )
    200 ms ConnectionRes off Send-CheckCmd  ReportNoReply ;

: TestConnection  ( - )
    ConnectionRes off Send-CheckCmd  ReportNoReply 200 ms ;


: #transfers ( - n ) fldone @ #fl-retries @ + ;

S" gforth" ENVIRONMENT? [IF] 2drop

: open-udp-port   ( - )
   flash-to$ lcount IPPORT_UDP SOCK_DGRAM IPPROTO_UDP
   open-port-socket dup to udp-sock-client  dup 0=
      if    drop
      else  dup fileno
            dup IP_PMTUDISC_DO -1 dup cell SetSolOpt
                SO_SNDTIMEO   200 -1  [ 2 cells ] literal SetSolOpt
            true blocking-mode
      then ;

: close-port   ( sock - ) fileno close drop  ;

: MapFlashFile   ( file$ cnt - adr size ) r/w map-file ;
: UnmapFlashFile ( - )  flAdress @  flSize @ unmap  flAdress off ;

sema  sem-prev-hangs

: lock_sem-prev-hangs ( - )  sem-prev-hangs lock   ;
: unlock_sem-prev-hangs ( - )  sem-prev-hangs unlock   ;

[THEN]


S" win32forth" ENVIRONMENT? [IF] DROP
needs src\lib\Ext_classes\WaitableTimer.f

: open-udp-port   ( - )
   flash-to$ lcount IPPORT_UDP SOCK_DGRAM IPPROTO_UDP
   open-port-socket to udp-sock-client    ;

synonym close-port  close-socket

map-handle ahndl

: UnmapFlashFile ( - )   ahndl close-map-file drop flAdress off ;

: MapFlashFile   ( file$ cnt - adr size )
   ahndl open-map-file abort" can't map file."
   ahndl >hfileAddress @
   ahndl >hfilelength  @ ;

Semaphore  PreventHangingSem
0 1 0 0  CreateSemaphore: PreventHangingSem
: lock_sem-prev-hangs ( - )  INFINITE DecreaseWait: PreventHangingSem ;
: unlock_sem-prev-hangs   ( - )  false  Increase: PreventHangingSem 2drop ;

[THEN]

: .modk ( n div1000 - )
   /mod  +.report dup 999 >
      if  1000 /
      then s>d
   <# # # # [char] . hold #> +report$ ;

: ReportDrops ( - )  ReportNoReply s"  Too many dropped packets!" +report$ ;

true value ignore-hangs

: StopTransmitting ( - )
   flAdress @
     if   true to ignore-hangs UnmapFlashFile
     then
   ReportDrops  ;

: Send-all-done ( - )
   ConnectionRes @
    if    AllDone SentInfoPacked
    else  StopTransmitting
    then  ;

\ Packets of 440 bytes from linux are not received
\ So all packs are the size \ of /UdpPacket
: SendFlashLine ( position - BytesSent )
    ConnectionRes @
      if    >r BlData
            r@ SetFlashPosition
            r@ flAdress  @  +  &UdpData
            flSize @  r> - dup 0>
                  if    /UdpData min dup>r cmove   \ add ASCII data from mapping don't send zero's
                  else   3drop 0 exit
                  then
\           &UdpPacket r@ DataOffset + send-udp-pack-client \ better but unreliable
            &UdpPacket /UdpPacket send-udp-pack-client
            r>
      else  drop StopTransmitting 0
      then   ;

: DoDropped ( Position done? --  ) \ 5)  Request: /udp -768 9
\  cr ." 1>> "  2dup dump
   swap ConnectionRes @
      if dup 1 #fl-retries +!    \ 6)
          if   0<
               if     drop true to ignore-hangs flAdress @
                         if  ms@ >r  [char] < emit cr \ 7)
                             UnmapFlashFile                \ Keep the line open for requests from the client
                             ReportDate s" Session complete. Statistics:<BR>Transferred: " +report$
                             fldone @ s>d (ud,.) +report$     s"  bytes.<BR>Time: " +report$
                             r> MsFlash - dup  1000 .modk     s"  sec. #Retries: "  +report$
                             #fl-retries @ 1-  +.report       s" .<BR>Speed: "      +report$
                             fldone @ 8 * swap .modk          s"  kbit/s."          +report$
                         then
               else   UdpTimeOut ms  SendFlashLine  drop
                      UdpTimeOut ms  fldone @ SentInfoPacked
                      [CHAR] r emit  \ Retry
               then
          else  2drop
          then
      else   true to ignore-hangs StopTransmitting
      then
     ms@ to MsLastIn  ;


500 value MsMaxInactive
0 value TidPreventHangingReceiver

: PreventHangingReceiver ( - )
    lock_sem-prev-hangs
      begin  ignore-hangs
                if  lock_sem-prev-hangs \ sem-prev-hangs lock
                then
             ms@ MsLastIn  - MsMaxInactive >
                if  AllDone UdpTimeOut ms SentInfoPacked [char] h emit
                then
             MsMaxInactive ms
      again ;

0 value PrevUdpTimeOut

: Send-#FlashLines ( lineSize n  - )
    ms@ to PrevUdpTimeOut 10 ms
    0
      ?do  UdpTimeOut ms@ PrevUdpTimeOut - - 0 max ms
           ConnectionRes @
            if    BlData       i SetFlashPosition
                  i flAdress @ + &UdpData /UdpData  flSize @  min cmove   \ add ASCII data from mapping don't send zero's
                  &UdpPacket over send-udp-pack-client
                  /UdpData flSize @ min fldone +!
            else  StopTransmitting  drop unloop exit
            then  /UdpData  ms@ to PrevUdpTimeOut
     +loop ;

: SendFlashLines (  - ) \ 3)
   s" Flashing.&nbsp;" report$ place
   /UdpData DataOffset +  \ = lineSize
   flSize @ dup /UdpData <=
      if    UdpTimeOut 2* ms
      then
   [char] t emit   \ Transfering
  /UdpData / /UdpData * ( 1 max)
   ms@ to MsFlash  \ Starting to measure the transfer time.
   Send-#FlashLines
   &UdpData /UdpData bl fill
   UdpTimeOut ms fldone @ SendFlashLine fldone +!
   UdpTimeOut ms AllDone SentInfoPacked drop  \ 4)
   ms@ to MsLastIn false to ignore-hangs unlock_sem-prev-hangs  ;

: DoSendFile (  - ) \  Request: /udpf
   SendFlashLines
   ['] Send-all-done is retry-cmd ;  \ 2)

: FlashFile ( file$ cnt - )  \ 1)
   ConnectionRes @ not
     if  StopTransmitting 2drop ReportNoReply
     else   2dup 2>r 2dup +log file-status nip 0=
         if     2r@ MapFlashFile dup>r flSize ! flAdress !  fldone off #fl-retries off
                ServerHost  r>ipAdress count SetIp4
                r> SetSIze
                2r@ SetFilename
                FlashUpd @ SetSector
                FlashCmd SentInfoPacked \ Contains: FlashCmd, Size, Sector, and Ip4adress
                ReportDate s" Sending a file." +report$
                 ." U:" UdpTimeOut .  ." Sending:" 2r> type ."  >e"
         else   2r> 2drop  200 ms AllDone SentInfoPacked
                s"  File not found"  report$ place
         then
     then  ;

: DoFlash  ( recv-pkt$ cnt --  recv-pkt$ cnt htmlpage$ lcount )
   2dup bl scan dup
      if    bl bl Find$Between  FlashFile
      else  2drop
      then
   here -1  ;

: extract-input ( adr count - adrRemains countRemains  adrRes countRes )
   [char] = scan 2dup  [char] & scan swap >r dup >r - 1 /string   r> r> swap 2swap  ;

: LoadOnESP  ( -- )
   ConnectionRes @ not
       if  2drop StopTransmitting ReportNoReply
       else FlashReady?
              if    selected-file$ lcount SetFilename LoadCmd SentInfoPacked
                    ReportDate s" Compiling: " +report$
                    selected-file$ lcount +report$
              else  ReportDate s" Retry again later.<BR>Flash sesion not complete." +report$
             then
       then
  ;

: RebootESP  ( recv-pkt$ cnt --  recv-pkt$ cnt htmlpage$ lcount )
   ConnectionRes @
       if    RebootCmd  SentInfoPacked
             ReportDate s" Rebooting remote." +report$
       else  ReportNoReply
       then ;

: PushFlash ( -- )
   FlashReady?
      if    selected-file$ lcount FlashFile
      else  ReportDate s" Allready flashing." +report$
      then
     ;

S" gforth" ENVIRONMENT? [IF] 2drop
' PreventHangingReceiver execute-task to TidPreventHangingReceiver \ @@
[THEN]

S" win32forth" ENVIRONMENT? [IF] DROP
 ' PreventHangingReceiver Submit: webserver-tasks
[THEN]

\s
