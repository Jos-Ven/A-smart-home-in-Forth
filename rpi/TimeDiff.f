Marker TimeDiff.f \ For Gforth and Win32Forth. By J.v.d.Ven 07-11-2022

needs Common-extensions.f
needs calencal.f
needs jd.f

defer sync-time ' noop is sync-time

: -swap    ( n1 n2 n3 - n2 n1 n3 )                      >r swap r> ;
: -ftrunc  ( f: n.x - .x )                          fdup ftrunc f- ;
: .##      ( - )             s>d tuck dabs <# # # rot sign #> type ;
: fbetween ( f: n rlow rhigh -- ) ( - flag ) 2 fpick f>= f< 0= and ;

 1  constant  January
 2  constant  February
 3  constant  March
 4  constant  April
[undefined]   May [if] 5  constant  May [then]
 6  constant  June
 7  constant  July
 8  constant  August
 9  constant  September
10  constant  October
11  constant  November
12  constant  December

: month" ( month -- adr$ cnt )
        case
        January   of s" January"    endof
        February  of s" February"   endof
        March     of s" March"      endof
        April     of s" April"      endof
        May       of s" May"        endof
        June      of s" June"       endof
        July      of s" July"       endof
        August    of s" August"     endof
        September of s" September"  endof
        October   of s" October"    endof
        November  of s" November"   endof
        December  of s" December"   endof
                abort" a bad month"
        endcase ;

: day"  ( day -- adr$ cnt )
        case
        0 of s" Sunday"     endof
        1 of s" Monday"     endof
        2 of s" Tuesday"    endof
        3 of s" Wednesday"  endof
        4 of s" Thursday"   endof
        5 of s" Friday"     endof
        6 of s" Saturday"   endof
                abort" a bad day"
        endcase ;


86400e fconstant #SecondsOneDay
3600    constant #SecondsOneHour

: UtcTics-from-Jd&Time  ( ss mm uu JD -  ) ( f: - UtcTics )
   2440588 - s>f #SecondsOneDay f* #SecondsOneHour * swap 60 * + + s>f f+ ;

: Jd-from-UtcTics       ( f: UtcTics - fjd )  #SecondsOneDay f/ 2440588e f+  ;

: Date-from-jd          ( f: fjd  - ) ( - dd mm year )
   ftrunc Moment-from-JD f>s  Gregorian-from-Fixed -swap ;

: Time-from-UtcTics     ( f: UtcTics - ) ( - ss mm uu )
   Jd-from-UtcTics -ftrunc #SecondsOneDay f*  f>s
   #SecondsOneHour /mod swap 60 /mod 60 /mod drop rot ;

:  +PlaceTime ( ss mm uu  - )  0 +##  [char] : +##  [char] : +## ;
:  +PlaceDate ( dd mm year - ) (.) +utmp$  [char] - +##   [char] - +## ;

: +PlaceYmdTime  ( ss mm uu dd mm year - )
   +PlaceDate 1 spaces$ +utmp$ +PlaceTime ;

: .Date&Time  ( ss mm uu dd mm year - )
    utmp$ off +PlaceYmdTime  utmp" type ;

: TimeOnly"  ( ss mm uu  - ) utmp$ off +PlaceTime utmp"  ;
: .TimeOnly  ( ss mm uu  - ) TimeOnly" type ;


S" win32forth" ENVIRONMENT? [IF] DROP
needs src\lib\Ext_classes\WaitableTimer.f

2 constant time_zone_id_daylight

\in-system-ok begin-structure /tzidinfo
          field: >Bias
    32 2* +field >StandardName
 time-len +field >StandardDate
          field: >StandardBias
    32 2* +field >DaylightName
 time-len +field >DaylightDate
          field: >DaylightBias
end-structure

\in-system-ok begin-structure /systemTime
       wfield: >wYear
       wfield: >wMonth
       wfield: >wDayOfWeek
       wfield: >wDay
       wfield: >wHour
       wfield: >wMinute
       wfield: >wSecond
       wfield: >wMilliseconds
end-structure

create timezoneinfo /tzidinfo allot

: GetTimeZoneInformation ( timezoneinfo -  )
  call GetTimeZoneInformation dup 0xFFFFFFFF <> (?WinError)
  time_zone_id_daylight <>
   if  timezoneinfo dup >daylightbias off   then ;

: init-timezoneinfo ( - ) timezoneinfo  GetTimeZoneInformation ;

initialization-chain chain-add init-timezoneinfo init-timezoneinfo

\ -- Return the total offset in minutes of the timezone and DST settings
\ at the current time.
\ : local-offset ( -- d ) \ Offset in minutes for your location as a double at the current time
\  timezoneinfo dup GetTimeZoneInformation
\  dup >bias @ swap >daylightbias @  + negate s>d ;
\ local-offset has been replaced by UtcOffset

: w? ( addr - ) w@ . ;

: .wdate ( &systemTime - )
    dup>r >wMonth w?
       r@ >wDayOfWeek w?
       r@ >wDay w?
       r@ >wHour w?
       r@ >wMinute w?
       r@ >wSecond w?
       r> >wMilliseconds w? ;

: timezoneDate@ ( &timezoneinfoDate - wSecond wMinute wHour wDay wDayOfWeek wMonth  )
    dup>r >wSecond w@
       r@ >wMinute w@
       r@ >wHour w@
       r@ >wDay w@
       r@ >wDayOfWeek w@
       r> >wMonth w@ ;

: .StandardDate ( - )         timezoneinfo >StandardDate .wdate ;
: .DaylightDate ( - )         timezoneinfo >DaylightDate .wdate ;
: UtcBias@      ( - seconds ) timezoneinfo >bias @ 60 * negate ;
: daylightbias@ ( - seconds ) timezoneinfo >daylightbias @ 60 * negate ;

5 constant LastInMonth

: LastwDayOfWeekOfMonth ( month year - fixed )
   1 swap Fixed-from-Gregorian 31 + Gregorian-from-Fixed
   nip 1 swap Fixed-from-Gregorian 1- Gregorian-from-Fixed
   2>r  lasti wDayOfWeek rot 2r> 'th-Weekday ;

: wkDay>date { last|n wDayOfWeek month year -- day month year }
  last|n LastInMonth <
    if    last|n wDayOfWeek month 1 year 'th-Weekday
    else  month year LastwDayOfWeekOfMonth
    then  Gregorian-from-Fixed -swap ;

: TimeChange ( &DaylightDate|&StandardDate year - ss mm uu dd mm year )
   >r timezoneDate@ r> wkDay>date ;

: DstOffset          ( f: UtcTics - DstSeconds ) ( year - )  \ timezoneinfo must be filled !
   UtcBias@ s>f f+
   >r timezoneinfo >DaylightDate r@ TimeChange  jd UtcTics-from-Jd&Time
      timezoneinfo >StandardDate r> TimeChange  jd UtcTics-from-Jd&Time daylightbias@ s>f f-
   fbetween
     if    daylightbias@ s>f
     else  0e
     then ;

: UtcOffset          ( f: UtcTics - UtcOffsetSeconds )
   fdup Jd-from-UtcTics Date-from-jd nip nip DstOffset UtcBias@ s>f f+ ;

: .TimeChange ( &TimezoneinfoDate year - )  TimeChange .Date&Time ;

: .TimeChanges ( year - )
   cr timezoneinfo >DaylightDate over .TimeChange
   cr timezoneinfo >StandardDate swap .TimeChange ;

12 SET-PRECISION

((  About @time: The windows epoch starts 1601-01-01T00:00:00Z.
It's 11644473600 seconds before the UNIX/Linux epoch (1970-01-01T00:00:00Z).
The Windows ticks are in 100 nanoseconds.
Leap seconds were introduced in 1972. Thus irrelevant in the conversion.
The alternative API is GetSystemTime, which is 20 times slower and
has double the structure size,
A function to get seconds from the UNIX epoch will be as follows:

unsigned WindowsTickToUnixSeconds(long long windowsTicks)
{
     return (unsigned)(windowsTicks / WINDOWS_TICK - SEC_TO_UNIX_EPOCH);
}  ))

10000000e fconstant windows_tick     11644473600e fconstant sec_to_unix_epoch

1 PROC GetSystemTimeAsFileTime

: @time                      ( f: - UtcTics )
  0 dup SP@ GetSystemTimeAsFileTime drop swap
  d>f windows_tick f/ sec_to_unix_epoch f- ;


[ELSE]

S" gforth"     ENVIRONMENT? [IF] 2DROP
\ Made for a Rasberry Pi using a working NTP server in a Bash shell.

: restart-ntp-service ( - ) \ To synchronize the time with a NTP server
  cr ." PID: "  s" echo $$" ShGet type
  ." Restarting NTP"
  cr s" sudo /etc/init.d/ntp stop" ShGet type 2000 ms
  cr s" sudo /etc/init.d/ntp restart" ShGet type  2000 ms
  cr s" ntpq -p" ShGet type
 ;

\ ' restart-ntp-service is sync-time

: dst ( +uu:mm$ cnt - minutes ) \ Expects +hh:mm or -hh:mm
   drop dup >r 1+ 2 $>s 60 *
   r@ 4 + 2 $>s +   r> c@ [char] - =
      if negate then ;

: UtcOffset          ( f: UtcTics - UtcOffsetSeconds )
   s" date --date=" utmp$ place
   html| '@| +utmp$  f>d (d.) +utmp$
   html| ' +"%:z"| +utmp$ utmp"  ShGet dst 60 * s>f ;

 [ELSE]

 cr .( UtcOffset not yet defined ) abort


 [THEN]
[THEN]

\ : local-offset ( -- d ) \ In minutes
\    time&date UtcTics-from-Time&Date  @time ftrunc f- 60e f/ f>d ;
\ local-offset has been replaced by UtcOffset


\ Converting the output of time&date into a unix timestamp.
\ Floats are used to avoid the problem of 2038.

: UtcTics-from-Time&Date      ( ss mm uu dd mm year - ) ( f: - UtcTics )
   jd UtcTics-from-Jd&Time fdup UtcOffset f- ;

: LocalTics-from-UtcTics      ( f: UtcTics - LocalTics )  fdup UtcOffset f+ ;
: local-time-now              ( - f: UtcTics )   @time LocalTics-from-UtcTics  ;
: time>mmhh                   ( - mmhh )  local-time-now time-from-utctics #100 * + nip ;

: Time&Date-from-UtcTics      ( f: UtcTics -  ss mm uu dd mm yearUtc )
   fdup Time-from-UtcTics Jd-from-UtcTics Date-from-jd ;

: Time&DateLocal-from-UtcTics ( f: UtcTics -  ss mm uu dd mm yearLocal )
   LocalTics-from-UtcTics Time&Date-from-UtcTics ;

: LocalTics-from-Time&Date    ( ss mm uu dd mm yearLocal - ) ( f: - LocalTics )
   UtcTics-from-Time&Date LocalTics-from-UtcTics ;

: ftime"             ( f: utcTics - ) ( - uu:mm cnt ) Time&DateLocal-from-UtcTics 3drop TimeOnly" ;
: fUtctime"          ( f: utcTics - ) ( - uu:mm cnt ) Time&Date-from-UtcTics 3drop TimeOnly" ;
: .ftime             ( f: UtcTics - ) ftime" type ;
: .fUtcTime          ( f: UtcTics - ) fUtctime" type ;
: .fDateLocal&Time   ( f: UtcTics - ) Time&DateLocal-from-UtcTics .Date&Time ;
: .fUtcDate&Time     ( f: UtcTics - ) Time&Date-from-UtcTics .Date&Time ;

: .Local&Time-from-Utc&Time (  ss mm uu dd mm yearUTC - )
    UtcTics-from-Time&Date LocalTics-from-UtcTics .ftime ;

: .Utc&Time-from-Local&Time (  ss mm uu dd mm yearLocal - )
     UtcTics-from-Time&Date .fUtcTime ;

: fdays&time"            ( - fdays&time$ count ) ( f: UtcTics - )
   fdup #SecondsOneDay f/ fdup 1e f>=
     if    f>d d.
     else  fdrop
     then
   fdup Time&Date-from-UtcTics ( Time&DateLocal-from-UtcTics)  3drop utmp$ off +PlaceTime
   s" ," +utmp$ -ftrunc 1000e f* f>d  dabs <# # # # #> +utmp$
   utmp"   ;

: .fdays&time        ( f: UtcTics - )   fdays&time" type  ;
: .day               ( f: UtcTics - )   Jd-from-UtcTics f>s week-day day" type bl emit ;

: UtcTics-from-UnixTicsLocal ( f: UnixTicsLocal - UtcTics ) fdup UtcOffset f+ ;

: .UTCoffset                 ( f: UnixTicsLocal - )
    ."  UTC " UtcOffset f>s  #SecondsOneHour /mod dup 0>=
        if    [char] + emit
        then  .## .## ;

: EncodeDate ( ss min 24hrs day month year - time date )
    10000 * swap 100 * + + swap 10000 * rot 100 * + rot + swap ;

2variable Enddate     time&date EncodeDate Enddate 2!
2variable Startdate   time&date EncodeDate nip 1 swap Startdate 2!

: delta-minute       ( f: - Seconds ) \ Time after the last minute has started
   @time 60e f/ fdup  ftrunc f- 60e f*  ;

                                       1e9 fconstant Nanoseconds
#SecondsOneHour 2* s>f Nanoseconds  f* f>d 2constant #Ns2Hours

: WaitTillNextMinute ( -- )     60e delta-minute f- Nanoseconds f* f>d ns ;

\s Eg:

cr .time bl emit .date
cr @time fdup .day fdup .fDateLocal&Time .UTCoffset
cr @time ftrunc time&date LocalTics-from-Time&Date f- f.
cr @time ftrunc time&date UtcTics-from-Time&Date   f- f.
\s

