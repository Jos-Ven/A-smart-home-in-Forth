needs Common-extensions.f
needs webcontrols.f
marker LoadAvg.fs

: GetLoadAvg ( - LoadAvgLine$ count )
    s" /proc/loadavg" r/o open-file throw >r
    upad dup 80 r@ read-file throw
    r> close-file throw ;

: Find5mLoadAvg ( - LoadAvgLine$ count  15LoadAvgStart$ remainder )
    2 /string  bl scan ;

: 5mLoadAvg ( F: - 15mLoadAvg ) \ Should be positive
    GetLoadAvg Find5mLoadAvg
    bl bl Find$Between  >float not
       if   -9e
       then ;
\\\
