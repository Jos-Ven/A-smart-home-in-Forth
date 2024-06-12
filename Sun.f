\ From: https://groups.google.com/d/msg/comp.lang.forth/p-334hzSQBw/hHF8q99QiCAJ
\ sun 05.08.11 NAB
\ Sunrise/d calculations.
\
\ This is the kForth port of Neal Bridges' sunrise/sunset calculator
\   for Quartus Forth.  K. Myneni 2005-08-20
\
\ -- Original code and documentation may be found in
\      http://quartus.net/files/PalmOS/Forth/Examples/sun.zip
\
\ -- This version uses Wil Baden's Julian Day calculator (jd.4th).
\
\ -- Modified for Forths without separate fp stack. For Forths with separate
\      fp stack, modify the word TIME>MH
\
\ -- local sunrise and sunset words require that the local offset be hardcoded
\      in the word d.
\
\ April 3rd, 2015 Added code for Win32Forth and Gforth to take DST in account.
\ July 6th, 2017  Made the calculations thread safe.

\ Replaced local-offset by UtcOffset
\ and UnixTics-suntime now returns UtcTics on the floating point stack
\ Moved time related calculations to TimeDiff.f

needs TimeDiff.f
Marker Sun.f .latest 

\ -- For use with standard ANS Forth, uncomment line below:

: ?allot here swap allot ;


\ \ ======== kForth compatibility ===========
\ : d>s drop ;
\ \ ======= end kForth compatibility ========


\ Local latitude and longitude
\ (west and south are negative, east and north are positive):
fvariable latitude
fvariable longitude

\ Sun's zenith for sunrise/sunset:
fvariable zenith \ ok

S" gforth" ENVIRONMENT? [IF] 2drop   VOCABULARY HIDDEN  [THEN]

HIDDEN DEFINITIONS

\ Other working variables:


newfuser lngHour
newfuser T
newfuser L
newfuser M
newfuser RA
newfuser sinDec
newfuser cosDec
newfuser cosH
newfuser H

: range360 ( f1 -- f2 )
\ Adjust so the range is [0,360).
  fdup f0< if  360e f+
  else  fdup 360e f> if  360e f-  then
  then ;

\ { 383e range360 f>s -> 23 }
\ { -17e range360 f>s -> 343 }

: floor90 ( f1 -- f2 )
\ Round down to the nearest multiple of 90.
  90e ftuck f/ floor f* ;

\ { 97e floor90 f>s -> 90 }

: range24 ( f1 -- f2 )
\ Adjust so the range is [0,24):
  fdup  24e f> if  24e f-  then
  fdup  f0< if  24e f+  then ;


FORTH DEFINITIONS ALSO HIDDEN

: set-location ( long lat -- )
  latitude f!  longitude f! ;

: set-zenith ( zenith -- )  zenith f! ;

: zenith: ( f -- )
\ Builds zenith-setting words.
  create  ( here f!)  1 dfloats ?allot f!
  does> ( -- )  f@ set-zenith ;


90.83333e  zenith:  official-zenith
      96e  zenith:  civil-zenith
     102e  zenith:  nautical-zenith
     108e  zenith:  astronomical-zenith

: day-of-year ( d m y -- day )
\ Calculate the day-of-year number of a given date (January 1=day 1).
  dup >r  ( dmy>date) jd
  1 January r> ( dmy>date) jd - 1+ ;

\ { 20 July 1984 day-of-year -> 202 }

\ Floating-point helper words:
\ : ftuck ( a b -- b a b )  fswap fover ;
\ : f>s ( f -- n )  f>d d>s ;

: time>mh ( f: h.m -- min hour )
\ Convert a floating-point h.m time into integer minutes and hours.
  fdup floor  fover fswap  f-
\  60e f*  f>s  >r floor  f>s r> swap ;   \ integrated stack Forth.
  60e f*  f>s  floor  f>s ;              \ Separate fp stack.

\ { 3.5e time>mh -> 30 3 }

\ : f> ( r1 r2 -- f )    fswap f< ;

[undefined] pi [if] 3.14159265358979e fconstant pi [then]

: deg>rad ( r1 -- r2 ) [ pi 180e f/ ] fliteral f* ;

: rad>deg ( r2 -- r1 ) [ 180e pi f/ ] fliteral f* ;


\ The algorithm works in degrees, so we need separate versions of the
\ trig functions that operate on degrees rather than radians:
: fsind  deg>rad fsin ;
: fcosd  deg>rad fcos ;
: ftand  deg>rad ftan ;
: fasind  fasin rad>deg ;
: facosd  facos rad>deg ;
: fatand  fatan rad>deg ;

false constant rising
true constant setting

: UTC-suntime  ( d m y set? -- h.m )
\ Calculate the UTC sunrise or sunset time for a given day of the year,
\  using the location set in the longitude and latitude fvariables.
  >r  \ preserve rise/set value
  day-of-year  0 d>f  T f!
  longitude f@ 15e f/ lngHour f!                 \ let lngHour=longitude/15:
  r@ rising = if
    18e lngHour f@ f- 24e f/ T f@ f+ T f!        \ let T=T+((18-lngHour)/24):
  else \ setting
    6e lngHour f@ f- 24e f/ T f@ f+ T f!         \ let T=T+((6-lngHour)/24):
  then
  0.9856e T f@ f* 3.289e f- M f!                 \ let M=(0.9856*T)-3.289:

\  let L=range360(M+(1.916*sin(M))+(0.020*sin(2*M))+282.634):
  M f@ 2e f* fsind 0.020e f* M f@ fsind 1.916e f* f+ M f@ f+ 282.634e f+
  range360 L f!

\  let RA=range360(atan(91764*tan(L))):
  L f@ ftand 0.91764e f* fatand range360 RA f!

\  let RA=(RA+(floor90(L)-floor90(RA)))/15:
  L f@ floor90 RA f@ floor90 f- RA f@ f+ 15e f/ RA f!

  L f@ fsind 0.39782e f* sinDec f!                \ let sinDec=0.39782*sin(L):
  sinDec f@ fasind fcosd cosDec f!                \ let cosDec=cos(asin(sinDec)):

\  let cosH=(cos(zenith)-(sinDec*sin(latitude)))/(cosDec*cos(latitude)):
  zenith f@ fcosd latitude f@ fsind sinDec f@ f* f-
  latitude f@ fcosd cosDec f@ f* f/ cosH f!


  cosH f@ fabs 1e f> ABORT" Fatal Error"   \  let abs(cosH): 1e f> -11 and  throw
  cosH f@ facosd 15e f/ H f!               \  let H=acos(cosH)/15:
  r> rising = if  24e H f@ f- H f! ( let H=24-H:)  then

\ let H+RA-(0.06571*T)-6.622 -lngHour:
  H f@ RA f@ f+ 0.06571e T f@ f* f- 6.622e f- lngHour f@ f-
;

\ {  \ Toronto, Canada: 43.6N 79.4W
\    -79.4e 43.6e set-location
\    official-zenith
\    20 July 1989 setting UTC-suntime
\    time>mh -> 53 0 }
\ { 20 July 1989 rising UTC-suntime
\    time>mh -> 54 9 }

\ : local-offset ( -- local-offset. )
\ \ Return the total offset in minutes
\ \  of the timezone and DST settings.
\ \ Requires PalmOS 4 and above.
\  PrefTimeZone >byte
\  PrefGetPreference
\  PrefDaylightSavingAdjustment
\  >byte  PrefGetPreference  d+ ;

: UnixTics-suntime  ( d m y set? -- f: UtcTics )
\ Calculate sunrise or sunset time
\  for the specified date, adjusting
\  for the local timezone & DST.
  over >r 2over 2>r \ Saving y and d m
   UTC-suntime      \ UTC time excl. daylight saving adjustment
\ Convert UTC value to local time incl. daylight saving adjustment
  \ local-offset d>f 60e f/ f+
  range24 0 time>mh
  2r> r> UtcTics-from-Time&Date ;

: date-now   ( -- d m y ) time&date >r 2swap 2drop 2 roll drop r> ;
: sunrise    ( d m y -- f:  UtcTics ) rising  UnixTics-suntime ;
: sunset     ( d m y -- f:  UtcTics ) setting UnixTics-suntime ;
: mh>mh$     ( m h -- hh:mm$ count )  ## [char] : +## utmp" ;
: .hh:mm     ( m h -- )               mh>mh$ type ;
: .mh        ( mh -- )                100 /mod .hh:mm ;

: till-next-time ( f: UtcFrom UtcStart - UtcTimeDif ) ( - NextDay )
   f- fdup f0< ;

: time&date>smh ( -- s m h ) time&date 2drop drop ;

: UtcTics-from-hm ( hhmmToday - ) ( f: - UtcTics )
    100 /mod 0 -rot date-now  UtcTics-from-Time&Date ;

: #SecondsToDay ( f: - #SecondsToDay ) \ Taking DST changes in account
   60 59 23 date-now UtcTics-from-Time&Date
   00 00 00 date-now UtcTics-from-Time&Date f- ;

: #NsTill  ( hhmmTargetLocal -- ) ( F: -- NanosecondsUtc )
  UtcTics-from-hm  UtcTics-from-LocalTics @time f2dup f<
      if   fswap #SecondsToDay f+ fswap \ Next day when the time has past today
      then
   f- Nanoseconds f* ;


: WaitUntil ( hhmmTargetLocal -- )
   dup #NsTill  #Ns2Hours d>f f/ f>s 1- 0 max 0
     ?do    #Ns2Hours ns
     loop
   #NsTill f>d ns ;

: wait-time-sun ( f: UtcTics -- UtcTicsTimeDif ) ( - flag  )  @time till-next-time ;

: sunset-still-today?  ( - minutes flag )
   date-now sunset wait-time-sun not f>s 60 / swap ;

: .wait-time-sun ( f: UtcTics -- flag )
   fdup  wait-time-sun
     if    fdrop ."  was done at " .ftime
     else  fswap ."  is expected at "  .ftime
           ." . Wait time: " .fdays&time
     then .dot ;

: .sunset   ( d m y -- ) ." The sunset"   sunset .wait-time-sun  ;
: .sunrise  ( d m y -- ) ." The sunrise" sunrise .wait-time-sun  ;


\ http://www.timeanddate.com/worldclock/netherlands/amsterdam
 4.54e 52.22e set-location official-zenith \ Amsterdam, Netherlands 52'22'' North 4'54'' East

: Minutes* ( minutes - ms )  [ 60 1000 * ] literal * ;

: .current-time&date ( -- )  (date) type   ." , " .time .dot ;

: today   ( -- ) time&date >r swap r> cal  3drop ;

: report-sunset-sunrise
   cr date-now >r
   today cr ." At "
   2dup r@ jd week-day day" type ." : " .current-time&date
   cr 2dup r@ .sunset
   cr      r> .sunrise cr ;

PREVIOUS

report-sunset-sunrise
\s
