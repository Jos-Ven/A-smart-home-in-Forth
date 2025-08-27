marker autogen_ip_table.fs  .latest  \ Generates ip_table.bin initial filled
                                     \  with IP4 numbers, portnumbers and later hostnames.
\ When a ip_table.bin exists it will be mapped for futher use.
\ Delete ip_table.bin to get a new table.

needs Server-controller.f \ Controls a number of servers in an array
needs Web-server-light.f
needs unix/mmap.fs

create ip_table$ ," ip_table.bin"         \ File that contains the servers with ip-addresses etc. See .servers

10 constant FirstIpRange                  \ End first IP-range for Webserver-light servers that can be updated.
                                          \ Initial 7 servers allocated.
FirstIpRange 0 range-Gforth-servers 2!    \ Store the range of Gforth servers.

2variable hMapIpTable

: MapIpTable ( - )
   ip_table$ count r/w map-file 2dup hMapIpTable 2!
   /server / to #servers  to &servers
   #servers 0
     ?do   0 i r>Online !
     loop ;

ip_table$ count file-status nip 0<>
   [IF]          \  Skip if the file in ip_table$ exists


\ \\\\\ The parameters to create an ip table for 20 servers are:

55  constant Max#servers         \ When a range starts at x00.
52  Max#servers min to #servers  \ MAXIMAL number of Raspberry servers and other servers


: FindIpStartRange ( - IpStartRange )
    GetIpHost$ 3 SkipDots
    pad place  pad (number?) not abort" FindIpStartRange failed, check OwnIP$"
    10 / 10 * ;  \ An IpStartRange ends with a zero in it's IPnumber

FindIpStartRange constant  IpStartRange   \ Webserver-light servers that can be updated.
IpStartRange 10 + constant SecondIpRange  \ For other systems

: CreateIpTable (  - )
   #servers /server * dup allocate throw dup>r swap
   2dup erase
   ip_table$ count  r/w  create-file throw dup>r  write-file  throw
   r> CloseFile
   r> free drop ;


: InitHostNames (  #servers #from  -- ) \ Initial just a space and the last 3 numbers of the IP adress
          \ As soon as the Admin page is used the real name should be in the table dor Rpi's
     ?do  space" utmp$ place
          i IpStartRange + (.) +utmp$
          utmp" i r>HostName place
     loop ;


: FillIpNumbers { subnet$ count FirstServer #servers #from -- }
   -1  #servers #from
     ?do  HtmlPort i r>port !
          0 i r>Version !
          0 i r>Uptime !
          0 i r>5mLoad !
          0 i r>Master !
          1+ dup FirstServer + CompleteIp i r>ipAdress place
          space" utmp$ place i IpStartRange + (.)  +utmp$
                 utmp" i r>HostName place
    loop
    drop #servers #from InitHostNames ;

: ModifyHosts { Prefix$ count IPport #IDLastserver #from  -- }
   #IDLastserver 1+ #from
     ?do  Prefix$ count utmp$ place
          i  (.) +utmp$
          utmp" i r>HostName place
          IPport i r>port !
     loop  ;

: autogen_ip_table ( - )
    cr ." Creating "  ip_table$ count type
    CreateIpTable MapIpTable ;

\ The IP-port for the webservers of the Rpi's are defined in  Web-server-light.f

#servers /sock * newuser &socks_   ' &socks_ is &socks
 SetSubnet autogen_ip_table
 subnet$ count IpStartRange  FirstIpRange 0   FillIpNumbers       \ gForth-servers (First range)
 subnet$ count SecondIpRange #servers FirstIpRange FillIpNumbers  \ set IP-range for other servers
  s" Esp"    80 #servers FirstIpRange  ModifyHosts \ ESP8266 servers modifing the names and IP-port
  s" Debian" 8080 9 9    ModifyHosts \ 1 other server  modifing the name  and IP-port
  s" Esp"    8899 14 12  ModifyHosts \ ESP8266 1 server modifing the name and IP-port
  s" Esp"    8899 51 51  ModifyHosts \ ESP8266 also not a webserver
\ s" Esp"    16 r>HostName place \ patch name

[ELSE]
  cr ip_table$ count type .(  detected.) MapIpTable
  #servers /sock * newuser &socks_   ' &socks_ is &socks
[THEN]

WaitForIpAdress
.servers
\\\


