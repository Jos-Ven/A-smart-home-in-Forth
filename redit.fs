needs Common-extensions.f
marker redit.fs   .latest \ To edit *.bme280 files.

0 [IF]

 When the rpi hangs and you need to disconnect the power then
 a record filled with zero's is sometimes inserted.
 Make a copy of your *.bme280 file.
 Then To correct it, load this file and type:

.0rec     \ Should show the record filled with zero’s.
          \ Do NOT use the next line if it does NOT show such a record
delrec 4l \ ONLY If the first line of 0rec shows a record filled with zero’s
bye

[THEN]

defer r>Time  ( - Relative_offset_to_time )
defer r>Date  ( - Relative_offset_to_date )

needs webcontrols.f
needs bsearch.f
needs bme280-logger.fs
needs bme280-output.fs

yearToday  SetFilename \ Will set the filename to the current year
\ 2022 SetFilename     \ Could be changed.

: n>a   ( #N - Vadr ) \ Finds the adress for the Nth record in a mapped file.
  /bme280Record * &bme280-FileRecords @ +  ;

: ListintervalRecords (  #End #Start-- )
   cr  s" I        Adress    Date     time  loc  PressH  TempC Humm% Pollx Ldr%" type
     swap 1+ swap
     do  cr i dup .  n>a . i ListRecord  loop  ;

0 value iptr \ Contains the current record number

: map-handle create 0 , 0 , ; immediate

: >hfileAddress ( map-handle - >hfileAddress )  ;
: >hfileLength  ( map-handle - >hfileLength ) cell + ;

map-handle mhndl-file

: xl ( n - )       \ List n lines starting at iptr
  iptr dup rot + swap
    do i dup cr . ListRecord loop  ;

: 4l ( - )  4 xl ;  \ List 4 lines starting at iptr

: AddIptr ( n - ) iptr + 0 max to iptr  ; \ Add n to iptr
: +l ( - )  1 AddIptr ; \ Add 1 to iptr
: -l ( - ) -1 AddIptr ; \ Subtract 1 from iptr

: maplog ( - )
    filename$ count r/w map-file
    mhndl-file >hfileLength ! dup mhndl-file >hfileAddress !
    &bme280-FileRecords ! ;

: FlushCloseFile ( fd - )
   dup flush-file drop  close-file drop  ;

: .0rec ( - )                 \ find record with  r>Date @ 0=
    mhndl-file >hfileLength @ \ And stores the found record number in iptr
    /bme280Record  / 0
    do   I dup to iptr r>Date @ 0=
         if  i  cr .  4l  leave
         then
    loop ;

: .0hum ( - )                 \ find record with  r>Humidity f@ 27e f<
    mhndl-file >hfileLength @ \ And stores the found record number in iptr
    /bme280Record  / 0
\    do   I dup to iptr r>Humidity @ 0=
    do   I dup to iptr r>Humidity f@ 27e f<
         if  i  cr .  4l  leave
         then
    loop ;

: .0temp ( - )                 \ find record with  r>Temperature f@ 46e f>
    mhndl-file >hfileLength @ \ And stores the found record number in iptr
    /bme280Record  / 0
    do   I dup to iptr  r>Temperature f@ 46e f>
         if  i  cr .  4l  leave
         then
    loop ;

: .-rec ( - )                  \ find record with  r>Light f@ 0e f>
    mhndl-file >hfileLength @  \ And stores the found record number in iptr
    /bme280Record  / 0
    do   I dup to iptr r>Light f@ 0e f>
         if  i  cr .  4l  leave
         then
    loop ;

: .-prec ( - )                 \ find record with r>Pressure f@ 810e f<
    mhndl-file >hfileLength @  \ And stores the found record number in iptr
    /bme280Record  / 0
    do   I dup to iptr r>Pressure f@ 810e f<
         if  i  cr .  4l  leave
         then
    loop ;

: fldrecOFF ( - ) \ Puts the field r>Light OFF for the ENTIRE year ( No warning )
    mhndl-file >hfileLength @  \ And stores the last record number in iptr
    /bme280Record  / 0
    do   I dup to iptr  0e r>Light f!
    loop ;

: .frec ( date time - ) \ find recored filled with date time. EG: 20231101 301 .frec
    locals| _time _date |  \ And stores the found record number in iptr
    mhndl-file >hfileLength @
    /bme280Record / 0
    do   I dup to iptr dup r>Date @ _date =
         swap r>Time @ 100 / _time  = and
         if  i  cr .  4l  leave
         then
    loop ;

: ResizeFile ( NewLength - )
    mhndl-file >hfileAddress @ mhndl-file >hfileLength @  unmap dup
      if     >r filename$ count r/w bin open-file abort" Couldn't open the file to write to"
             r> s>d 2 pick resize-file abort" Can't resize the file"
             FlushCloseFile  maplog
      else   drop
      then ;

: delrec ( - )     \ Removes the record at iptr and resizes the file.
  iptr r>Date dup  \ start
  /bme280Record +  \ end
  mhndl-file >hfileLength @
  iptr 1-  /bme280Record * - \ size
  dup 0>
    if    >r swap r> cmove
    else  2drop drop 0
    then
  mhndl-file >hfileLength @  /bme280Record - ResizeFile ;

: SetRec { adr } ( time date addr - ) ( f: Humidity Temperature Pressure - )
  adr >Date !  adr >Time ! s" patch" adr >Location place
  adr >Pressure f! adr >Temperature f! adr >Humidity f! ;

\ EG: 103501 20161030  59.52e 18.44e 1033.04e 37427 SetRec

begin-structure  /NewBme280Record  \ define a NEW record FIRST when converting
   lfield: n_Date
   lfield: n_Time
   lfield: n_Location \ counted string
   xfield: n_Pressure
   xfield: n_Temperature
   xfield: n_Humidity
   xfield: n_Pollution
   xfield: n_Light
end-structure

/NewBme280Record dup  allocate drop  dup  value &NewBme280Record swap   erase
 s" Kamer" /location 1- min  &NewBme280Record n_Location place

: loadNewRecord ( adr - ) >Date  &NewBme280Record n_Date /bme280Record cmove ;
: WriteNewRecord ( fd - ) &NewBme280Record n_Date /bme280Record rot write-file throw ;

: #bme280records ( -- #recordsInFile )        \ including the record at 0
   mhndl-file >hfileLength @  /bme280Record / ;

: cut#recsFromEnd ( #records - ) \  EG: 2080 cut#recsFromEnd
   #bme280records swap - /bme280Record * ResizeFile ;

: ExportRecords ( hndl &End &start - )
     do   i loadNewRecord dup WriteNewRecord  /bme280Record
     +loop
   dup flush-file drop
   close-file drop ;

: ConvertFile ( - ) \  Test first on a copy ! \ EG: maplog  ConvertFile
   s" Out-file.res"  r/w bin create-file  throw
    #bme280records n>a 0 n>a ExportRecords ;

: ExportFile ( dateStart timeStart dateEnd timeEnd - ) \ EG: maplog 20170717 0700 20170717 1130 ExportFile
   s" demo-file.res" r/w  create-file  throw >r
   .frec  iptr n>a >r .frec  r> iptr n>a r> -rot ExportRecords ;

maplog \ Map the file

 #bme280records 1- dup 4 - ListintervalRecords \ List the last 4 records


\\\

EG after a a file has been mapped:
+l 190 xl
-l 10 xl
delrec 4l

.0rec 4l
20231115 318 .frec 2 xl

\\\
