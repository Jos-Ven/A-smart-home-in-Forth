Marker bme280-output.fs

defer .int
defer .float
defer .float3
defer .type
defer .cr

[undefined] /DataParms [if]

\in-system-ok begin-structure /DataParms  \ For additional information about the various fields for an SVG-plot
   field: >CfaDataLine      \ CFA of a pointer to a field in the first record in the logfile
   field: >CfaLastDataPoint \ CFA that gets the last data point in a plot.
  xfield: >FirstEntry
  xfield: >LastEntry
  xfield: >MinStat
  xfield: >MaxStat
  xfield: >AverageStat
  xfield: >Compression
   field: >Color
end-structure

: DataItem: ( <name> -- )  \ Define an inline record for additional information.
\in-system-ok   /DataParms dup here swap allot dup value swap erase ;

[then]

DataItem: &Pressure
DataItem: &Pollution
DataItem: &Temperature
DataItem: &Humidity
DataItem: &Light

: .intSpace    ( n - )       (.)   type space ;
: .floatSpace  ( f: n - )    (f.2) type space ;
: .float3Space ( f: n - )    (f.3) type space ;
: .typeSpace   ( adr cnt - )       type space ;

: .CsvSeperator ( - ) ." ;" ;

: .intCsv    ( n - )      (.)   type .CsvSeperator ;
: .floatCsv  ( f: n - )   (f.2) type .CsvSeperator ;
: .float3Csv ( f: n - )   (f.3) type .CsvSeperator ;
: .typeCsv   ( adr cnt - )      type .CsvSeperator ;

: Onscreen ( - )
   [']  .intSpace    is .int
   [']  .floatSpace  is .float
   [']  .float3Space is .float3
   [']  .typeSpace   is .type
   [']  (cr)         is .cr ;

Onscreen

: crCsv ( - )    crlf" type ;

: csvFormat
   [']  .intCsv    is .int
   [']  .floatCsv  is .float
   [']  .float3Csv is .float3
   [']  .typeCsv   is .type
   [']  crCsv      is .cr ;

ALSO HTML

: ListRecord ( i - )
  4 set-precision
  dup r>Date         @ .int
  dup r>Time         @ 100 / .int
  dup r>Location count .type
  dup r>Pressure    f@ .float
  dup r>Temperature f@ .float
  dup r>Humidity    f@ .float
  dup r>Pollution   f@ .float3
      r>Light       f@ .float ;

PREVIOUS

: ListRecords (  vadr size interval -- )
  -rot .cr  s" Date      time  loc   Press  Temp   Humidity" .type
   nip /bme280Record / 0
     do  .cr i ListRecord  dup +loop
   drop ;

: .interval ( interval -- )
     >r filename$ count r/w  map-file
     2dup over &bme280-FileRecords !
     r>   ListRecords
     unmap-file ;

\ 1 .interval abort
\\\
