Marker Wifi_signal.fs

needs Common-extensions.f

: WiFiSignalLeve@ ( f: - SignalLevel_WiFi )
    s" awk 'NR==3 {print  $4 }' /proc/net/wireless" ShGet
    2 - s>number? drop d>f ;

: scanNum { adr cnt -- adr cnt1 }
     adr cnt adr 0 cnt 0
       do   i adr + c@ dup [char] 0 [char] 9 between  swap [char] - = or
              if drop i leave  \ Leave if the found char is less or equal then char-
              then
       loop
   nip /string ;

: WiFiBitRate@ ( f: - Mb/s_WiFi )  \
    s" iwconfig wlan0| awk -F= ' NR==3'" ShGet \ wlan0=name WiFI
  scanNum
    s>float 0=
     if   0e
     then ;
\\\
