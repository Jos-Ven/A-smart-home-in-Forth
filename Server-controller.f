marker Server-controller.f
needs Common-extensions.f

: +pad-log ( - )  +upad" +log ;


S" win32forth" ENVIRONMENT? [IF] DROP

include itools.frt
0x8 constant MSG_WAITALL

0x8 constant MSG_WAITALL

: host>addr ( addr u -- x|0 )
    2dup upad place upad +null
    upad 1+ gethostbyname dup 0=
       if    drop upad place s"  --- unknown Host." +pad-log 0
       else  nip nip ( hostent) 3 CELLS + ( h_addr_list) @ @ @
       then ;


: read-packet  { socket c-addr len -- c-addr u ior } \ Waits until the complete packet has been received.
   socket 0=
      if     s" Can't read packet." true 0
      else   MSG_WAITALL len c-addr cell+ socket call recv  dup 0<
                if    drop s" Socket read error" true 0
                else  false swap
                then
      then  c-addr ! c-addr lcount rot ;

: send-packet ( c-addr size socket -- flag )
    dup 0=
      if    3drop false
      else  -rot 0 send pause 0<
               if    log" Write error to sock."  false
               else  true
               then
       then ;

(( In Windows: A call to connect() blocks, until the connection is made, or till
 the connection fails because the host is not responding, or it is refusing a connection.
 That may take 20 seconds ))

\ CREATE sockaddr-tmp  sockaddr-tmp 4 CELLS DUP ALLOT ERASE  ( family+port, sin_addr, dpadding )

CODE a>r@      ( a1 -- n1 )
                mov     ebx, 0 [ebx]
                next    c;

: zGetHostIP ( z" -- IP ior )
  dup c@ [char] 0 [char] 9 between over and
  if   call inet_addr 0
  else \ dup if   then
     call gethostbyname dup
       if  3 cells + a>r@ a>r@ a>r@ 0
       ELSE call WSAGetLastError
       THEN
  then ;

:  #IP   ( du -- 0 ) #s  [char] . hold  2drop 0 ;

: (.ip)  ( ip -- addr u )
   0 256 um/mod 0 256 um/mod 0 256 um/mod
   0 <#  #ip #ip #ip #s #> ;

create my-ip-addr-buf maxstring allot

: GetIpHost$ ( -- ip$ cnt )
  0 my-ip-addr-buf ! my-ip-addr-buf zGetHostIP drop  (.ip) ;

: FillOnlineIndications ( - ) ;

: open-port-socket   ( c-addr u port sock_ ipproto -- handle|0 )
    2>r htonl AF_INET  or sockaddr-tmp !
    AF_INET sockaddr-tmp ( family ) w!
    host>addr dup 0<>
      if  sockaddr-tmp cell+ ( sin_addr) !
          PF_INET   2r> socket
          dup 0<= abort" no free socket"
          dup sockaddr-tmp 16 connect  0<
             if    s" **** Can't connect" +utmp$ drop false
             then
      else 2r> 2drop
      then ;

[THEN]

-1 value ServerHost

S" gforth" ENVIRONMENT? [IF] 2drop

include lib.fs
library libc libc.so.6

6  constant ipproto_tcp
17 constant ipproto_udp

\ S" unix/socket.fs" INCLUDED
S" socket.fs" INCLUDED

c-library socketIPv4
1 (int) libc gethostbyname gethostbyname ( name -- hostent )
end-c-library

c-library socketshutdown
    \c #include <sys/socket.h>
   c-function shutdown shutdown n n -- n ( sockfd how - res )
end-c-library

0x02000000 constant SOCK_CLOEXEC
0x02000000 constant O_CLOEXEC
0x00004000 constant O_NONBLOCK
0x00000002 constant O_RDWR
\ 0x00000004 constant F_SETFL

: (SetMode)   ( flag fileno  -- ) f_setfl rot fcntl ?ior ;
: SetMode     ( flag fd  -- )     fileno (SetMode) ;


0 constant SHUT_RD
1 constant SHUT_WR
2 constant SHUT_RDWR

: host>addr ( addr u -- x|0 )
    \G converts a internet name into a IPv4 address
    \G the resulting address is in network byte order
    c-string gethostbyname dup 0=
      if ." Address host not found" drop false exit
      then
    [ s" os-type" environment? drop s" cygwin" str= ]
      [IF]    &12 +
      [ELSE]  h_addr_list
      [THEN]  @ @ @ ntohl ;

: read-packet  { socket c-addr len -- c-addr u ior } \ Waits until the complete packet has been received.
    socket 0=
       if     s" Can't read socket" 2dup +log true 0
       else   socket fileno c-addr cell+ len msg_waitall recv  dup 0<
                if    drop s" Socket read recv error" 2dup +log true 0
                else  false swap
                then
       then  c-addr ! c-addr lcount rot ;

0x2000 constant MSG_NOSIGNAL \ don't raise SIGPIPE

: send-packet { c-addr size socket -- #LastSent }
   socket 0=
      if   false
      else  socket fileno to socket   3 0
               do  socket c-addr size MSG_NOSIGNAL ['] send catch \ Catching possible Write to broken pipe
                     if    2drop 2drop  leave
                     else  dup size = if to size leave then
                           dup -1 =   if to size leave then
                           \ log" Retry remainder."
                           c-addr size rot /string
                           to size to c-addr
                     then
               loop
            size dup 0<
            if    log" Write error to sock."
            then
      then  ;

: ShutdownConnection ( fileno - )  SHUT_RDWR shutdown drop ;

: close-socket       ( socket -- )
   dup 0<>
       if  fileno closesocket
       then  drop ;

: get-info ( addr u port -- info|0 ) 0 { w^ addrres }
    >r 2dup r> base @ >r  decimal  0 <<# 0 hold #s #>  r> base ! drop
    >r c-string r> hints addrres getaddrinfo #>> ?dup
       if     -rot upad place s"  --- " +upad
	      gai_strerror cstring>sstring +pad-log 0
       else   2drop addrres @
       then ;

13 constant SO_LINGER
\ 20 constant SO_RCVTIMEO
21 constant SO_SNDTIMEO

: get-socket ( info -- socket|0 )
    dup >r >r
       BEGIN  r@
       WHILE  r@ ai_family l@ r@ ai_socktype l@  r@  ai_protocol l@  socket dup 0>=
              IF   SOCK_CLOEXEC over (SetMode)
                   dup r@ ai_addr @ r@ ai_addrlen l@ connect
                       IF    close-server
                       ELSE  fd>file rdrop r> freeaddrinfo  EXIT
                       THEN
               ELSE  drop
               THEN
            r> ai_next @ >r
       REPEAT
    rdrop r> freeaddrinfo  \  !!noconn!! throw
    \ log" Can't connect"  \ Optional
    0 ;

\ sema  sem-openSock

: open-port-socket  ( c-addr u port sock_ ipproto -- handle|0 )
    \ sem-openSock lock
    swap >hints    \ Sets ai_socktype
    AF_INET hints ai_family   l!
            hints ai_protocol l!
    get-info dup 0<>
       if  get-socket
       then
    dup reuse-addr
    \ sem-openSock unlock
     ;

[undefined] strlen [if]
: strlen ( addr -- count )
    0 swap begin  count
           while  swap 1+ swap
           repeat
    drop ;
[then]

[THEN]

$2f constant /max-short$ \ max length of short$
\in-system-ok : short$:  ( n1 <"name"> -- n2 ) ( addr -- 'addr )  /max-short$ +field ;

0 value #servers         \ The number of used servers
0 value &servers         \ Adres of the server array with the following offsets:

\  xfield:   >sock            \ The opened sock

\in-system-ok begin-structure /server
  xfield:   >open            \ The CFA to open a socket
  xfield:   >port            \ The port of a server.
  xfield:   >Online          \ Indication to see that a server is Online

  xfield:   >Version         \ Of the networksoftware
  xfield:   >Uptime          \ Uptime in seconds
  xfield:   >5mLoad          \ The load of the last 5 minutes ( See $ Uptime )
  xfield:   >Master          \ True if that system is the master

  short$:   >ipAdress        \ The name of a server or it's IP-adress + r>+HostName
  short$:   >HostName        \ The host name
  short$:   >account         \ The User name or description ( Optional )
  short$:   >password        \ Password User ( Optional )
  xfield:   >F0              \ Wait time confirmation
end-structure

\in-system-ok begin-structure /sock
  xfield:   >sock            \ The CFA to open a socket
end-structure

defer &socks ( - UserArray&socks )
: r>sock ( n - addr ) /sock * &socks + ;

\ : r>sock      ( n - addr ) r>server >sock ;

: r>server      ( n - &recordServer ) /server * &servers + ;
: r>open        ( n - addr ) r>server >open ;
: r>port        ( n - addr ) r>server >port ;
: r>Online      ( n - addr ) r>server >Online ;
: r>Version     ( n - addr ) r>server >Version ;
: r>Uptime      ( n - addr ) r>server >Uptime ;
: r>5mLoad      ( n - addr ) r>server >5mLoad ;
: r>Master      ( n - addr ) r>server >Master ;
: r>ipAdress    ( n - addr ) r>server >ipAdress ;
: r>HostName    ( n - addr ) r>server >HostName ; \ restore Data r>_account
: r>account     ( n - addr ) r>server >account ; \ ADD >> r>HostName 60  r>_account
: r>password    ( n - addr ) r>server >password ;
: r>F0          ( n - addr ) r>server >F0 ;

: place-short$  ( str len dest - )
    over /max-short$ 1- > abort" String too long" place ;

: set-account ( account$ len password& len server# -- )
    dup >r r>password place-short$ r> r>account place-short$ ;

: .string.l    ( sdr cnt fillup - )  -rot tuck type - 1 max spaces ;
: ipAdress$    ( server# - name len ) r>ipAdress count ;
: .servername  ( server# - ) space r>HostName count 14 .string.l ;
: +servername  ( server# - ) space" +utmp$ r>HostName count +utmp$  utmp" write-log-line ;

: allocate-server-record ( - )
    here  /server allot #servers 0=
       if    to &servers
       else  drop
       then ;

: add-server ( 'open host-name cnt port - )
    allocate-server-record  #servers dup >r  1 + to #servers
    0 r@ r>Online !
      r@ r>HostName place-short$
      r@ r>port !
      r@ r>ipAdress place-short$
      0 r@ r>F0 c!
      r> r>open ! ;

: Servers[ ( - )  \ Starting adres for allotting servers.
     here to &servers ;

: ]Servers ( - )  \ Allocating a user array for socks
     s" #servers /sock * newuser &socks_  ' &socks_ is &socks"  evaluate ; immediate

: close-#server  ( server# - ) r>sock dup @ close-socket off ;
: close-servers ( from to - )  ?do   i close-#server   loop ;

\ NOTE: Open commands should be able to use the following open-#server definition.

: open-#server ( server# - )              dup r>open @ execute ;
: open-servers ( server#nX server#n0 - )  ?do   i open-#server  loop ;
: test-servers ( - ) #servers 0  do  i dup open-#server close-#server  loop ;

: Set#F0       ( n #server - )  r>F0  c! ;
: Get#F0       ( #server - n )  r>F0  c@ ;

: setAllF0     ( n - ) #servers 0  do  dup i Set#F0 loop drop ;

 upad 1+ 255 gethostname drop
 upad 1+ strlen upad c!
 upad hostname$ upad c@ 1+ cmove


: .(u.r)  ( n right -) (u.r) type ;

48  constant INET6_ADDRSTRLEN
create subnet$ INET6_ADDRSTRLEN 1+ allot
create OwnIP$  INET6_ADDRSTRLEN 1+ allot
INET6_ADDRSTRLEN 1+ newuser tmpIP$

: host-id>ip$ ( host-id - ip4$ cnt )
  subnet$ count tmpIP$ place (.) tmpIP$ +place  tmpIP$ count ; \ ip4

2variable range-Gforth-servers


S" gforth" ENVIRONMENT? [IF] 2drop


: GetGateway ( - gateway$ cnt )
\  s" 192.168.21.1" exit              \ Use this line with the right IP adress
   s" ip route show | grep via" ShGet \ when $ ip route show   does not work
   s" via" search
      if   bl bl Find$Between
      else drop 0
      then ;

: CheckGateway ( - flag )   s" ip route show" ShGet  [char] . scan nip 0<> ;

: WaitForGateway ( - )     \ Wait for a gateway or reboot after 1 hour
   0 15 0
       do  CheckGateway
             if  drop true leave
             then
           cr .date space .time  ."  No gateway found, retrying...."  15000 ms  loop
      0=
      if   cr ." No gateway found, rebooting.s " reboot
      then ;


: GetIpHost$         ( - ip$ cnt )  WaitForGateway s" hostname -I" ShGet 2 - ;

: SkipDots ( str$ count #dots - remains$ count )
   0  do [char] . scan dup 0=
            if    leave
            then
         1 /string
      loop ;


: SetSubnet ( - )
\  s" 192.168.21.1"  subnet$ place exit  \ Use this line with the right IP adress
   GetGateway 2dup 3 SkipDots nip -      \ when GetGateway fails
   subnet$ place ;

: CacheOwnIP ( - )  GetIpHost$ OwnIP$ place ;

: AdminServer ( - #server|-1 )
    -1 #servers 0
       ?do  i r>Master @
               if  drop i leave
               then
       loop ;

: FindServer# { Ip$ cnt -- #server|-1 }
    -1 #servers 0
       ?do  i  r>ipAdress count  Ip$ cnt  compare 0=
               if  drop i leave
               then
       loop ;

: FindOwnId ( - #server|-1 ) \ #server or -1
     CacheOwnIP OwnIP$ count FindServer#  ;

: SetMasterIndication ( IdRpi# - )
   #servers  0
      ?do   0 i r>Master !
      loop
    true swap r>Master !   ;

: WaitForIpAdress ( - )
    WaitForGateway
    cr cr .date space .time  ."  Wait for an IP address."
    cr .date space .time 3000 ms ."  Got IP: " FindOwnId dup 0< abort" IP adress not in table"
    true over r>Online !
    dup r>ipAdress count type
    to ServerHost
    cr ." Subnet$: " SetSubnet subnet$ count type cr ;

[THEN]


: CompleteIp ( n - CompleteIp$ count ) \ Places the subnet. before n
   subnet$ count utmp$ place (.) +utmp$ utmp" ;

: .servers ( - )  \  To be used after FillOnlineIndications.
    cr #servers dup . ." server(s) detected at " hostname$ count type
    cr ." id  sock ip            port online  F  name" 0
       ?do   cr i dup               3 .(u.r)
             dup r>sock @           5 .(u.r)
             dup space ipAdress$ type
             dup space r>port @     4 .(u.r)
             dup r>Online @ 3 spaces  if ." Yes" else ." No " then
             dup space r>F0 c@      3 .(u.r)
             dup r>Master @    if ."  *"  else  2 spaces  then
             r>HostName count  14 .string.l
        loop ;

: ModServer ( &IpAdress count  &HostName count port n - )
   dup>r r>port !
     r@ r>HostName place-short$
     r> r>ipAdress place-short$ ;

: ForAllServers { cfa -- }
   #servers  0
     ?do  i cfa  execute \ The executed word should: ( server# cfa - )
     loop ;

: FileIp ( fd server# - fd )
    ipAdress$ upad place space" +upad
    upad count 2 pick write-line
      if  log" FileIp: Can't file IP."
      then ;

: FileIps ( filename$ count - )
   r/w create-file \
     if  log" FileIps: Can't create file."
     then     ( filename$ count - fd )
   ['] FileIp ForAllServers
   CloseFile ;

\s

