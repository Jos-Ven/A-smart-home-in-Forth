Marker bme280-logger.fs

needs unix/mmap.fs
needs mcp3008.fs
needs bme280.fs      \ Sensor for humidity temperature pressure
needs mq135.fs       \ Sensor for air quality.
needs ldr.fs         \ Sensor For light intensity.
needs Wifi_signal.fs \ For WiFi signal strength

needs avsampler.fs   \ Calculates an average for a number of samples.
needs resetbutton.fs \ In case the system hangs
needs Common-extensions.f


8 constant /location

create extension$ ," .bme280"

: yearToday ( - ) time&date >r 2drop 2drop drop r> ;

yearToday value   InitialYear
20        newuser filename$

: (SetFilename ( year - )
    (.) filename$ place  extension$ count filename$ +place  ;

0 value FileError

: SetFilename ( year - )
   (SetFilename   filename$ count file-status nip
      if   yearToday  (SetFilename  true to FileError
      then ;

: SetFileYearToday  ( - )  yearToday  SetFilename  ;

SetFileYearToday    \ Name of the logfile. Eg: 2017.bme280

0 value &bme280Record

begin-structure /bme280Record \ The definition of ONE INLINE record
  lfield: >Date
  lfield: >Time
  lfield: >Location \ counted string
  xfield: >Pressure
  xfield: >Temperature
  xfield: >Humidity
  xfield: >Pollution
  xfield: >Light
end-structure

/bme280Record dup here swap allot dup to &bme280Record swap erase

: SetLocation ( str adr -- ) /location 1- min  &bme280Record >Location place ;

s" Kamer" SetLocation

: DateTimeCode ( d m Y - ymmdd )   10000 * swap 100 * + + ;

: .bme280Record ( &bme280Record - )
  cr
  dup >Date        ? space
  dup >Time        ? space
  dup >Location    count type space
  dup >Pressure    f@ f. space
  dup >Temperature f@ f. space
  dup >Humidity    f@ f. space
  dup >Pollution   f@ f. space
      >Light       f@ f. space ;

: OpenCreateLogfile  ( - file-id )
  filename$ count 2dup file-status  nip 0<>
   if     r/w  bin create-file    throw
   else   r/w  bin open-file      throw
          dup dup file-size   throw
          rot reposition-file throw
   then ;

Samples: PressureSamples
Samples: TemperatureSamples
Samples: HumiditySamples
Samples: PollutionSamples
Samples: LdrSamples

: WiFiBitRate@|Mq135f@  ( - f )
   [DEFINED] WiFiBitRate
   [IF]    WiFiBitRate@
   [ELSE]  Mq135f@
   [THEN]  ;

: WiFiSignalLeve@|Ldrf@%   ( - f )
   [DEFINED] WiFiBitSignal
   [IF]    WiFiSignalLeve@
   [ELSE]  Ldrf@%
   [THEN]    ;

: logInlineRecord ( fd - ) \ ( f: _Pollution Humidity Temperature  -  )
   time&date DateTimeCode &bme280Record >Date !  DateTimeCode &bme280Record >Time !
   Bme280>f &bme280Record >Pressure f! &bme280Record >Temperature f! &bme280Record >Humidity f!  \ Bme280
   WiFiBitRate@|Mq135f@    >Pollution f!
   WiFiSignalLeve@|Ldrf@%  >Light f!  ;

: OnNewYear ( - ) \ Creates each year a new logfile
   InitialYear yearToday <>
     if  yearToday dup to InitialYear SetFilename
         OpenCreateLogfile CloseFile
     then ;

 60 1000 * #samples / constant SampleTime

: takeSample ( fd-Bme280 - )
     dup 0<>
     if  Bme280>f PressureSamples  sample!
                  TemperatureSamples sample!
                  HumiditySamples  sample!
     else   drop
            0.0001e   PressureSamples    sample!
            0.0001e   TemperatureSamples sample!
            0.0001e   HumiditySamples    sample!
     then
     WiFiBitRate@|Mq135f@ PollutionSamples sample!
     WiFiSignalLeve@|Ldrf@%       LdrSamples       sample!
     incr-sample  ;

false value \Overshoot  \ Change \Overshoot into true to see the time after 10 samples
2000 constant overshoot \ Time in MS passed 1 minute after taking 10 samples on my system

60 1000 * overshoot - constant MsTimeout
\ MsTimeout #samples * .

: RunningSampletime ( - RunningSampletime )
   MsTimeout time&date drop 2drop 2drop 1000 * - #samples /
   [ overshoot 10 / 1 max ] literal max ;

: SaveTime ( - )
   time&date DateTimeCode &bme280Record >Date !  DateTimeCode &bme280Record >Time ! ;

: SeeOvershoot ( - )
   \Overshoot
      if  postpone cr postpone .time
      else exit
      then ; immediate

: takeSamples ( fd-Bme280 - )
  RunningSampletime  SaveTime
   #samples 0
     do    over takeSample dup ms
     loop  2drop  SaveTime
   SeeOvershoot
  PressureSamples    AverageSamples &bme280Record >Pressure f!
   TemperatureSamples AverageSamples &bme280Record >Temperature f!
   HumiditySamples    AverageSamples &bme280Record >Humidity f!
   PollutionSamples   AverageSamples &bme280Record >Pollution f!
   LdrSamples         AverageSamples &bme280Record >Light f! ;


: FileRecords  ( fd-Bme280   - )
    begin  OnNewYear
           dup takeSamples
           OpenCreateLogfile    \ It seems it is not save to extend or write to a file when it is mapped.
           &bme280Record >Pressure f@ &bme280Record >Humidity f@ f+ 0e f>
              if &bme280Record >Date  /bme280Record   2 pick write-file  throw
                \ dup flush-file drop  \ cr .InlineRec
              else cr (date) type space .time ." Invalid record"
              then
          CloseFile
    again ;

: (LogValues ( - )
   CheckSPI
      if   initSpi fdBme280 dup ChipId@ 0<
              if   drop 0
              then
      else 0
      then
   FileRecords  ;

: LogValues ( - )   ['] (LogValues execute-task drop ;

1 cells newuser &bme280-FileRecords \ Pointer to the records in the logfile

: r>bme280-FileRecord      ( n - &FileRecord ) \ Pointer to 1 record in the logfile
   /bme280Record * &bme280-FileRecords @ + ;

\ For the various fields in one record in the logfile:
: r>DateBme280   ( n - addr ) r>bme280-FileRecord >Date       ;
: r>TimeBme280  ( n - addr ) r>bme280-FileRecord >Time        ;
: r>Location    ( n - addr ) r>bme280-FileRecord >Location    ;
: r>Pressure    ( n - addr ) r>bme280-FileRecord >Pressure    ;
: r>Temperature ( n - addr ) r>bme280-FileRecord >Temperature ;
: r>Humidity    ( n - addr ) r>bme280-FileRecord >Humidity    ;
: r>Pollution   ( n - addr ) r>bme280-FileRecord >Pollution   ;
: r>Light       ( n - addr ) r>bme280-FileRecord >Light       ;

ALSO HTML

' r>TimeBme280 is r>Time
' r>DateBme280 is r>Date


1 cells newuser #records
1 cells newuser record-size
1 cells newuser Bme280Hndl

PREVIOUS

: MapFid ( fid -- addr u ) \ For older Gforth versions 
    >r r@ file-size throw d>s 0 over PROT_RW MAP_SHARED r@ fileno 0 mmap
    dup ?ior swap r> CloseFile ;

: MapBme280Data ( -- vadr count|0  )
    filename$ count 2dup file-status nip
      if    2drop 0 0
      else  r/w  open-file throw dup Bme280Hndl ! MapFid
            over &bme280-FileRecords !
            dup /bme280Record dup record-size ! / 1- 0 max #records !
      then ;


: UnMapBme280Data ( vadr count|0  -- )
   dup
     if    unmap-file
     else  2drop
     then  ;

\Overshoot  [if] cr .( Wait at least 2 minutes) cr (LogValues abort  [then]
\\\

\ InitBme280  cr bme280_i2c_address cr .(   I2c addres: ) h. dup 2 spaces .ChipId .bme280
 1 .interval
\ 1 .CsvRecords
\\\
