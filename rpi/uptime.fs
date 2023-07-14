needs Web-server-light.f

marker uptime.fs    \ To get the uptime of the system

\ : AwkUptime$ ( - adr cnt )  \ Awk Version
\   html| awk '{printf("%d %02d:%02d\n",($1/60/60/24),($1/60/60%24),($1/60%60))}' /proc/uptime |
\   ShGet ;

: GetUptime ( - UptimeInSeconds )
   s" /proc/uptime" r/o open-file throw >r
   pad dup 80 r@ read-file throw
   pad swap [char] . scan
   drop pad - $>s
   r> close-file throw ;

: SplitTime ( TimeInSeconds - #minutes #hours #days )  60 / 60 /mod 24 /mod  ;

: ConvertUptime$ ( TimeInSeconds - adr cnt )
   SplitTime  (.) utmp$ place  bl +##  [char] : +## utmp" ;

: Uptime>Html ( TimeInSeconds - adr cnt )
   SplitTime  (.) utmp$ place s" &nbsp;" +utmp$ 0 +##  [char] : +## utmp" +html ;

: uptime" ( - adr cnt )   GetUptime ConvertUptime$ ;

\\\ eg
uptime" type 4 22:08 ok \ = 4 days 22 hours and 8 minutes
\\\

