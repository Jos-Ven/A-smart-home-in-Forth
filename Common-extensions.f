Marker Common-extensions.f \ For Gforth and Win32Forth. By J.v.d.Ven 31-07-2023

: CloseFile ( fid - ) dup flush-file drop close-file drop ;

S" gforth" ENVIRONMENT? [IF] 2drop

needs unbuffer.fs
needs unix/pthread.fs
needs unix/mmap.fs

: unmap-file ( vadr count  -- )     2dup MS_ASYNC msync drop unmap ;
: \in-system-ok ( -- )              ; immediate \ Used in Win32Forth to suppress a number of messages.
: (d.)       ( d -- addr len )      tuck dabs <# #s rot sign #> ;
: (.)        ( n -- addr len )      s>d (d.) ;
: dup>r      ( n1 -- n1 ) ( R: -- n1 ) s" dup >r"  evaluate ; immediate
: f#         ( - )                  ; immediate
: 3drop      ( n1 n2 n3 -- )        2drop drop ;
: between    ( n lo hi - flag )     1+ within ;
: word-join  ( high low - lowhigh ) 16 lshift or ;
: word-split ( lowhigh - high low ) dup $FFFF and swap 16 rshift ;
: newuser    ( size <name> -- )     aligned ['] sp0 create-from reveal uallot , ;
: newfuser   ( <name> -- )                      \ Avoids error: Address alignment exception
   udp @ dup faligned swap - uallot drop float newuser ;

: upc ( char - upc-char )
   dup [char] a [char] z between if
      #32 invert and
   then ;

\ Colorization:
0xC >FG to error-color     \ Yellow for errors put it also in: ~/.config/gforthrc
' drop is Attr!            \ disables the escapes for colorization

' 0=          alias not     ( x -- x' )
' name>string alias >name$

255 constant maxcounted
create spcs  maxcounted allot
spcs         maxcounted blank
synonym      cls        page

-status

[THEN]

maxcounted 1+ newuser utmp$
0 value hLogfile
maxcounted 1+ newuser log-line$
maxcounted 1+ newuser upad    \ needs to be multi user from this point

: utmp"   ( - addr cnt )          utmp$ count ;
: +utmp$  ( adr cnt -  )         utmp$ +place ;
: space"  ( -- adr cnt )                s"  " ;
: dot"    ( -- adr cnt )                s" ." ;
: .dot    ( -- )                    dot" type ;
: upad"   ( - upad count )         upad count ;
: +upad   ( adr cnt -- )          upad +place ;
: +upad"  ( adr cnt --  adr2 cnt2 ) +upad upad" ;

: +blank" ( adr cnt --  adr cnt2 )  utmp$ place  space" +utmp$  utmp" ;

: ##$     ( seperator n -- adr cnt )
    s>d <# # #  2 pick hold  #> rot 0= abs /string ;

: ##      ( n --  )   0 swap ##$  utmp$ place ;
: +##     ( n seperator -- )  swap ##$ +utmp$ ;
: %       ( n % - n*% ) 100 */ ;

: (date) ( - adr$ cnt )
    utmp$ off time&date rot
    ##  swap [char] - +## s" -" +utmp$ (.) +utmp$ 3drop utmp" ;

: (time) ( -- adr$ cnt )
    utmp$ off time&date 3drop
    ## [char] : +##   [char] : +##  utmp" ;

: close-log-file ( - ) hlogfile 0<> if hlogfile CloseFile 0 to hlogfile then ;

: write-log-line ( adr cnt - )
     hlogfile 0<>
     if    hlogfile write-line abort" can't write to logfile"
           hlogfile flush-file drop
     else  2drop
     then ;

: CharNonReadable? ( char - char FlagBin )
    dup bl 126 between 0= ;

: IncrCCount ( &cnt - )  dup c@ 1+ swap c!  ;

: +PlaceFilteredChars { str cnt dest --  }
  dest dup c@ 1+ + str cnt + str 0 to cnt
       do  i c@ CharNonReadable?
           if   drop
           else dest IncrCCount over c! 1+ 0 to cnt
           then
       loop drop ;

: BlankString  ( adrs cnts adr cnt - adrEnd cntEnd|0 )
  dup >r search
    if    swap  dup r> bl fill swap
    else  r> 2drop 0
    then ;

: BlankStrings ( adrs cnts adr cnt -- )
     begin  2over 2over BlankString dup
     while  2rot 2drop 2swap
     repeat
   3drop 3drop ;

\ string concatenation:  $1 + $2 -> $1+$2 in pad
: $concat ( $1 n $2 n - upad n1+2 )
    utmp$ place             \ Save old $2.
    upad   place             \ Put $1 in place.
    utmp" +upad              \ Add old $2.
    upad"  ;

: format-logline ( adr cnt -  'adr cnt_total )
    (time) log-line$ place space"
    log-line$ +place
    maxcounted log-line$ count nip - min
    log-line$ +PlaceFilteredChars
    log-line$ count ;

S" gforth" ENVIRONMENT? [IF] 2drop


: (+log ( adr cnt - )   write-log-line ;

: +log  ( adr cnt -  )  format-logline (+log   ;

: def-logged ( latest adr cnt -  )
    s" - " upad place
    rot name>string +upad  s"  - " +upad +upad
     upad count format-logline (+log ;

: last-lit, ( - ) latest postpone lit ,  ;

: log"  ( -<string|>- )
    last-lit,   \ postpone name>string \ type
   [char] " parse postpone sliteral postpone def-logged ; immediate


User sh$  cell uallot drop

: ShGet ( addr u -- addr' u' ) \ Differs from the sh-get version in scrip.fs
    \G open command addr u, and read in the result
    sh$ free-mem-var
    r/o open-pipe throw dup >r slurp-fid
    r> close-pipe throw to $? 2dup sh$ 2! ;

: OsVersion" ( - adr cnt ) s" cat /etc/os-release | grep VERSION=" ShGet 1- ;

: Wall ( msg$ count - ) \ Puts a msg on the terminal, even if it running in the background
   s" echo '\a'" 2swap $concat 2drop
   s" | sudo wall -n "  +upad  upad"  system ;

\ Checking some used interfaces:
: CheckSPI    ( - f )  s" lsmod | grep spi_" ShGet nip 0<> ;
: CheckI2c    ( - f )  s" lsmod | grep i2c_bcm" ShGet nip 0<> ;
: CheckSerial ( - f )  s" /dev/ttyAMA0" file-status nip 0= ;

: old-thread-init ( - ) [ ' thread-init defer@ ] literal execute ;
:noname defers thread-init old-thread-init #0. sh$ 2! ; is thread-init

[undefined] c+!  [if]  : c+!     ( u c-addr -- )     dup c@  rot + swap c! ; [then]
[undefined] dms@ [if] : dms@ ( -- d: u )  utime 1 1000 m*/  ; [then]
: ms@     ( -- ms ) dms@  drop ;
: h.      ( -- )    base @ swap hex u. base ! ;
: .date   ( -- )    (date) type ;
: .time   ( -- )    (time) type ;
: beep    ( -- )    bell ;
: lcount  ( addr -- addr' len )     dup cell+ swap @ ;

' rdrop  alias r>drop
' \\\    alias \s

: f2dup   ( fs: r1 r2 -- r1 r2 r1 r2 )  fover fover ;
: f2drop  ( fs: r1 r2 -- )              fdrop fdrop ;

: cells+ ( a1 n1 -- a1+n1*cell ) \ multiply n1 by the cell size and add
          cells + ;              \ the result to address a1

: +cells ( n1 a1 -- n1*cell+a1 ) \ multiply n1 by the cell size and add
          swap cells+ ;          \ the result to address a1

create crlf$  2 c, 13 c, 10 c,

: $>s     ( adr cnt -- n )   upad place upad number d>s ;
: 0max    ( n -- 0max )      0 max ;
: down    ( -- )             s" sudo shutdown 0 -h " ShGet #0. sh$ 2! bye ;
: reboot  ( -- )             s" sudo shutdown 0 -r " ShGet #0. sh$ 2! bye ;
: HTML|   ( -<string|>- )    [char] | parse postpone sliteral ; immediate
: .latest ( - ) cr latest name>string type ;

\ Double number display with commas from Win32Forth

: (xud,.)       ( ud commas -- a1 n1 )
                >r
                <#                      \ every 'commas' digits from right
                r@ 0 do # 2dup d0= ?leave loop
                begin   2dup d0= 0=     \ while not a double zero
                while   [char] , hold
                        r@ 0 do # 2dup d0= ?leave loop
                repeat  #> r> drop ;

: (ud,.)        ( ud -- a1 n1 )
                base @             \ get the base
                dup  10 =          \ if decimal use comma every 3 digits
                swap  8 = or       \ or octal   use comma every 3 digits
                4 + (xud,.) ;      \ display commas every 3 or 4 digits

: ud,.r         ( ud l -- )        \ right justified, with ','
                >r (ud,.) r> over - spaces type ;

: u,.r          ( n1 n2 -- )       \ display double unsigned, justified in field
                0 swap ud,.r ;

: uc? ( c - uc )   [char] A [char] Z 1+ within ;
: >lc  ( c - lc )  dup uc? if [char] A - [char] a +  then ;

: lower ( adr$ count - )
    0
       ?do   dup i + dup  c@ >lc
             swap  c!
       loop   drop ;

2variable start-time

: timer-reset ( -- )  ntime start-time 2! ;

: .elapsed ( -- )
    ntime start-time 2@ d- d>f 1000000e f/ f>d u,.r ."  Ms." ;

pthread-id constant pthread-id0 \ id of task 0

defer close-http-server ' noop is close-http-server

: system2 ( cmd2$ cnt cmd1$ cnt - ) \ Note: words with system are expensive
  upad place space" +upad +upad" system ;

: CpuLed ( ledcmd$ cnt - ) \ Led0
  s" | sudo tee /sys/class/leds/led0/brightness > /dev/null" 2swap system2 ;

s" /sys/class/leds/led1/brightness" file-status nip \ led1 does not exist on a Rpi zero
[IF]   ' CpuLed alias PowerLed
: PowerLedOn  ( - )      s" echo 0" PowerLed ;
: PowerLedOff ( - )      s" echo 1" PowerLed ;
: PowerLed?  ( - flag )  s" cat /sys/class/leds/led0/brightness" ShGet drop c@ [char] 0 = ;

[ELSE]
: PowerLed ( ledcmd$ cnt - )
                         s" | sudo tee /sys/class/leds/led1/brightness > /dev/null" 2swap system2 ;
: PowerLedOn  ( - )      s" echo 1" PowerLed ;
: PowerLedOff ( - )      s" echo 0" PowerLed ;
: PowerLed?  ( - flag )  s" cat /sys/class/leds/led1/brightness" ShGet drop c@ [char] 0 <> ;

[THEN]


: InvertPowerLed ( - )   PowerLed?  if  PowerLedOff  else  PowerLedOn  then ;


: CpuLedOff ( - )        s" echo 0" CpuLed ;
: CpuLedOn  ( - )        s" echo 1" CpuLed ;
: CpuLed?   ( - flag )   s" cat /sys/class/leds/led0/brightness" ShGet drop c@ [char] 0 <> ;
: InvertCpuLed ( - )     CpuLed?  if  CpuLedOff  else  CpuLedOn  then ;

: GetFreeMem" ( - adr cnt )
    s" free -m | grep Mem | awk '{print  $4}'" ShGet 1- ;

: GetFreeMem  ( - mem )  GetFreeMem" s>number? drop d>s ;

: FreeMem" ( - adr cnt )
    s" Free mem: " GetFreeMem" $concat 2drop s"  MB" +upad  upad"  ;


: drop_caches ( - )   \
    FreeMem" +log
   s" sudo sh -c  sync" system
   s" sudo sh -c 'echo 1 >/proc/sys/vm/drop_caches'" system
   s" sudo sh -c 'echo 2 >/proc/sys/vm/drop_caches'" system
   s" sudo sh -c 'echo 3 >/proc/sys/vm/drop_caches'" system
   log" ready"
   FreeMem" +log ;

[THEN]

needs Config.f           \ For saving data, variables and strings in a file

S" win32forth" ENVIRONMENT? [IF] DROP

Needs MultiTaskingClass.f
Needs security.f

\in-system-ok : newfuser  ( <name> -- )  1 floats newuser ;

: dms@   ( - msL msH )       ms@ s>d ;
: ,|     ( -<string|>- )     [char] | parse ", 0 c, align ;
: HTML|  ( -<string|>- )     compile (s")  ,| ;  immediate
: ftuck  ( f: a b -- b a b ) fswap fover ;
: f0>=   ( -- f ; f: r -- )  fdup F0= F0> or ;
: seal   ( - )               context @ #1 set-order ;

: set-dir   ( a1 n1 -- ior )  { \ current$ }
    max_path 1+ LocalAlloc: current$ dup
      if  current$ place current$ dup +null 1+ $current-dir! 0=
      else  2drop 0
      then ;

: get-dir   ( buf buflen -- buf cnt )   \ get the full path to the current directory
      maxcounted min over swap call GetCurrentDirectory ;

: fmutex:   \ Compiletime: ( msSpinlock - )  Runtime: ( xt - ) \ For short wait times
     create 0 , ,
     does> >r 1 r@ r@
         begin  @
         while  r@ r@ cell+ @ ms
         repeat
     +!   execute   -1 r> +! ;


3 fmutex: LogSlot

: (+log  (  adr cnt -  )
    (time) log-line$ place space"
    log-line$ +Place
    maxcounted log-line$ count nip - min
    log-line$ +PlaceFilteredChars log-line$ count write-log-line  ;

: +log        ( adr cnt - )  ['] (+log LogSlot  ;
: log"        ( -<string">- )    compile (s") ,"  compile +log ; immediate
: name>string ( cfa - name cnt ) >name count ;
: 0>=         ( n - flag )       0< 0= ;
: >name$      ( cfa - adr n )    >name count ;

: def-logged ( latest adr cnt -  )
      s" - " upad place
      rot name>string +upad  s"  - " +upad +upad"
      ['] (+log LogSlot
      ;

synonym s>number? (number?)
synonym pause     winpause

: s>number    ( adr count - d1 )  s>number? drop ;
: Wall        ( msg$ count - ) type ; \ Perhaps not possible here.
: drop_caches ( - )  ;
\in-system-ok : .latest ( - ) latestxt @ .name ;

[THEN]



0x1B constant escape

: crlf"   ( - crlf$ count ) crlf$ count ;

: file-it  ( buffer cnt filename cnt - ) \ Write a buffer to a file
    r/w create-file throw >r
    r@  write-file throw
    r@  flush-file drop
    r>  close-file drop ;

: @file ( buffer cnt filename cnt - #read ) \ Place a file in a buffer
    r/o open-file throw  dup>r
    read-file throw
    r> close-file drop  ;


: Start-logfile  ( name cnt - )
     r/w create-file  abort" can't create logfile" to hlogfile
     log"  ******* Start logfile *******" ;

: +lplace ( addr len dest -- ) 2dup 2>r lcount chars + swap cmove 2r> +! ; \ NO CLIPPING
: lplace  ( addr len dest -- ) dup off +lplace ; \ NO CLIPPING
: dwithin ( D Dlimit1 Dlimit2+1 -- f ) 2over d- 2>r d- 2r> du< ;
: spaces$    ( n -- adr n ) 0 max spcs swap ;

: NextString { a n delimiter -- a1 n1 }
    a n dup 0
       ?do  delimiter scan dup 0=
            if     leave
            else   1 /string over c@  delimiter <>
                   if  leave
                   then
            then
       loop ;

: Find$Between ( string$ cnt CharStart CharEnd  - string$ cnt )
    >r scan dup 0>
      if    1 /string 2dup r> scan nip dup 0>
              if    -
              else  nip
              then
      else  r>drop
      then ;

: extract$ ( adr count limiter - adrRes countRes  )  >r 2dup r> scan  nip - ;

: extract-sub$ ( adr count - adrRemains countRemains  adrRes countRes ) \ strings between '=' and '&'
   [char] = scan 2dup  [char] & scan swap >r dup >r - 1 /string   r> r> swap 2swap  ;

: ExtractNumber?  ( string$ cnt c1 c2 - d1 flag )  Find$Between s>number? ;

: scan- { adr cnt char- -- adr cnt1 }
    adr 0 cnt 0
       do   i adr + c@ char- <=
              if drop i leave  \ Leave if the found char is less or equal then char-
              then
       loop  ;

: $find   ( str cnt -- str 0 | cfa flag )  upad place upad find ;

: s>float ( adr cnt - flag ) ( - f )       bl scan- >float ;

: (u.r)  ( u w -- adr cnt )
    0 swap >r (d.) r> over - spaces$ upad place +upad"  ;

: f>dint ( f: n magn - ) ( d: - n )  f* fround f>d tuck dabs ;
: .#-> [char] . hold  #s rot sign #>  ;
: (f.2) ( f -- ) ( -- c-addr u )   100e  f>dint <# # # .#-> ;
: (f.3) ( f -- ) ( -- c-addr u )   1000e f>dint <# # # # .#-> ;

: tcrc ( tsum char -- tsum2 ) 8 lshift xor     \ lshift = shl   (( n N -> shl -> n ))
   8 0 do  dup 0x7fff >
          if    1 lshift  0xffff and 0x1021 xor
          else  1 lshift
          then
      loop ;

: tcrc$ ( adr cnt - n  )
  0 -rot over + swap
    ?do  i c@ tcrc
    loop ;

cr .date space .time

s" Documents/MachineSettings.fs" file-status nip 0= [if]
            needs Documents/MachineSettings.fs    \ =optional to override settings
            [THEN]
\s


