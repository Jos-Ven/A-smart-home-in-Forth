\  Calendrical Calculations - Arithmetical

0 [IF] =======================================================
                                          Wil Baden 1999-09-11

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*                                                           *
*   Gregorian, Julian, ISO, Islamic, and Hebrew Calendars   *
*                                                           *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Forth versions of several calendrical functions.

<A HREF="http://emr.cs.uiuc.edu/home/reingold/calendar-book/index.html">

Calendrical Calculations,
<CITE> Dershowitz and Reingold </CITE></A>

Environmental dependency on 32 bit arithmetic.

<A HREF="calencal.txt"><BIG>TEXT</BIG></A><BR><BR>

<SMALL>

GLOSSARY

    'th-Weekday   */_   */_MOD   /_   /_MOD   Advent   BCE
    Birkath-Ha-Hama   CALENDAR   CE   Christmas
    Day-Number   Day-of-Week-from-Fixed
    Daylight-Savings-End   Daylight-Savings-Start
    Days-Remaining   Days-in-Hebrew-Year   Easter
    Eastern-Orthodox-Christmas   Election-Day   Epiphany
    FIRST   Fixed-from-Gregorian   Fixed-from-Hebrew
    Fixed-from-ISO   Fixed-from-Islamic   Fixed-from-JD
    Fixed-from-Julian   Gregorian-Date-Difference
    Gregorian-Epoch   Gregorian-Leap-Year?
    Gregorian-Year-from-Fixed   Gregorian-from-Fixed
    Hebrew-Birthday   Hebrew-Calendar-Elapsed-Days
    Hebrew-Epoch   Hebrew-Leap-Year?
    Hebrew-New-Year-Delay   Hebrew-from-Fixed
    ISO-from-Fixed   Independence-Day   Islamic-Epoch
    Islamic-from-Fixed   JD-Start   JD-from-Moment
    Julian-Epoch   Julian-Leap-Year?   Julian-from-Fixed
    Julian-in-Gregorian   LAST   Labor-Day
    Last-Day-of-Hebrew-Month   Last-Month-of-Hebrew-Year
    Long-Heshvan?   Memorial-Day   Moment-from-JD
    Nicaean-Rule-Easter   Omer   Passover   Pentecost
    Purim   Sh-Ela   Short-Kislev?   Ta-Anith-Esther
    Thanksgiving   Tisha-B-Av   Weekday-After
    Weekday-Before   Weekday-Nearest   Weekday-on-or-After
    Weekday-on-or-Before   Yahrzeit   Yom-Ha-Zikaron
    Yom-Kippur   _MOD

/GLOSSARY

</SMALL>

-------------------------------------------------------- [THEN]
0 [IF] ========================================================
        Needed from Tool Belt

NEEDS
        THIRD   FOURTH   ANDIF
/NEEDS

-------------------------------------------------------- [THEN]

[UNDEFINED] THIRD  [IF] : THIRD  ( x y z -- x y z x )  2 PICK ;     [THEN]
[UNDEFINED] FOURTH [IF] : FOURTH ( w x y z -- w x y z w )  3 PICK ; [THEN]
: ANDIF  S" DUP IF DROP " EVALUATE ; IMMEDIATE

0 [IF] ========================================================

        Operators for Floored Arithmetic

From Forth Standard Annex, A.6.1.1561.

/_MOD           ( dividend divisor -- remainder quotient )
    `/MOD`  with floored arithmetic.

/_              ( dividend divisor -- quotient )
    `/`  with floored arithmetic.

_MOD            ( dividend divisor -- remainder )
    `MOD`  with floored arithmetic.

*/_MOD          ( amount multiplier divisor -- remainder quotient )
    `*/MOD`  with floored arithmetic.

*/_             ( amount multiplier divisor -- quotient )
    `*/`  with floored arithmetic.

------------------------------------------------------- [THEN]

: /_MOD           ( dividend divisor -- remainder quotient )
    >R S>D R> FM/MOD ;

: /_    ( dividend divisor -- quotient )  /_MOD NIP ;

: _MOD  ( dividend divisor -- remainder )  /_MOD DROP ;

: */_MOD ( amount multiplier divisor -- remainder quotient  )
    >R M* R> FM/MOD ;

: */_   ( amount multiplier divisor -- quotient )  */_MOD NIP ;

0 [IF] =======================================================

`SUN MON TUE WED THU FRI SAT`
    IDs for day of week.  {0...6}

`JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC`
    IDs for months of Julian/Gregorian calendar.  {1...12}

Day-of-Week-from-Fixed  ( fixed-date -- day-of-week )
    The ID of the day of the week of date  {0...6}

------------------------------------------------------- [THEN]

 0 DUP CONSTANT SUN
1+ DUP CONSTANT MON
1+ DUP CONSTANT TUE
1+ DUP CONSTANT WED
1+ DUP CONSTANT THU
1+ DUP CONSTANT FRI
1+ DUP CONSTANT SAT
DROP

 1 DUP CONSTANT JAN
1+ DUP CONSTANT FEB
1+ DUP CONSTANT MAR
1+ DUP CONSTANT APR
1+ DUP CONSTANT MAY
1+ DUP CONSTANT JUN
1+ DUP CONSTANT JUL
1+ DUP CONSTANT AUG
1+ DUP CONSTANT SEP
1+ DUP CONSTANT OCT
1+ DUP CONSTANT NOV
1+ DUP CONSTANT DEC
DROP

: Day-of-Week-from-Fixed     ( fixed-date -- day-of-week )
    7 _MOD ;

0 [IF] =======================================================
JD-Start    ( F: -- x )
    Fixed time _x_ of start of julian day numbers.

Moment-from-JD         ( F: julian-day-number -- moment )
    Fixed time _moment_ of astronomical _julian-day-number_.

Fixed-from-JD       ( F: julian-day-number -- )( -- fixed-date )
    _fixed-date_ of astronomical _julian-day-number_.

JD-from-Moment     ( F: moment -- julian-day-number )
    Astronomical _julian-day-number_ of fixed moment _moment_.
------------------------------------------------------- [THEN]

-1721424.5E0 FCONSTANT JD-Start

: Moment-from-JD          ( F: julian-day-number -- moment )
    JD-Start F+ ;

: Fixed-from-JD   ( F: julian-day-number -- )( -- fixed-date )
    Moment-from-JD FLOOR F>D D>S ;

: JD-from-Moment          ( F: moment -- julian-day-number )
    JD-START F- ;

0 [IF] =======================================================

        Gregorian Calendar

Gregorian-Epoch   ( -- fixed-date )
    _fixed-date_ at start of the (proleptic) Gregorian calendar.

Gregorian-Leap-Year?  ( gregorian-year -- flag )
    True if _gregorian-year_ is a leap year in the Gregorian
    calendar

Day-Number  ( month day year -- +n )
    Day number in year of Gregorian date.

Fixed-from-Gregorian  ( month day year -- fixed-date )
    _fixed-date_ equivalent to the Gregorian date.

Gregorian-Year-from-Fixed  ( fixed-date -- gregorian-year )
    The _gregorian-year_ corresponding to the _fixed-date_.

Gregorian-from-Fixed      ( fixed-date -- gregorian-date . . )
    Gregorian month day year corresponding to _fixed-date_.

CALENDAR        ( fixed-date -- )
    Display month calendar from fixed-date.  The fixed date
    will be flagged.  (Added by Wil Baden.)

------------------------------------------------------- [THEN]

1 CONSTANT Gregorian-Epoch

: Gregorian-Leap-Year?  ( gregorian-year -- flag )
    DUP    4 _MOD 0=         ( gregorian-year flag)
    OVER 100 _MOD 0= NOT AND
    SWAP 400 _MOD 0= OR      ( flag)
    ;

: Day-Number             ( month day year -- day-of-year )
    >R  SWAP                        ( day month)( R: year)
        DUP >R                            ( R: year month)
            367 *  362 -  12 / +        ( day-of-year)
        R> 2 > IF  \  Adjust for MAR..DEC.      ( R: year)
            R@ Gregorian-Leap-Year? IF  1-  ELSE  2 - THEN
        THEN
    R> DROP ;

: Fixed-from-Gregorian    ( month day year -- fixed-date )
    DUP 1- >R                          ( R: previous-year)
    Day-Number                              ( day-of-year)
    R@   4 /_  +
    R@ 100 /_  -
    R@ 400 /_  +
    R> 365 * + ;

: Gregorian-Year-from-Fixed  ( fixed-date -- gregorian-year )
    Gregorian-Epoch -        ( d0)
    146097 /_MOD             ( d1 n400)
        400 * SWAP           ( year d1)
    36524  /_MOD             ( year d2 n100)
        DUP >R               ( year d2 n100)( R: n100)
        100 *  ROT + SWAP    ( year d2)
    1461   /_MOD             ( year d3 n4)
        4 * ROT + SWAP       ( year d3)
    365    /_                ( year n1)
        DUP >R               ( year n1)( R: n100 n1)
        +                    ( year)
    R> 4 = R> 4 = OR NOT IF 1+ THEN ;

: Gregorian-from-Fixed      ( fixed-date -- month day year )
    DUP Gregorian-Year-from-Fixed >R              ( R: year)
    DUP JAN 1 R@ Fixed-from-Gregorian -   ( date prior-days)
    OVER MAR 1 R@ Fixed-from-Gregorian < NOT IF
        R@ Gregorian-Leap-Year? IF  1+  ELSE 2 +  THEN
    THEN
    12 *  373 +  367 / >R            ( date)( R: year month)
    2R@ 1 ROT Fixed-from-Gregorian - 1+               ( day)
    R> SWAP R> ( month day year) ;

: CALENDAR  ( fixed -- )
    DUP Gregorian-from-Fixed NIP         ( fixed month year)
    CR  8 SPACES  OVER 1- 3 * CHARS
        S" JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC" DROP + 3 TYPE
    SPACE DUP . CR
    2DUP >R  1+ 1  R> Fixed-from-Gregorian >R
        1 SWAP Fixed-from-Gregorian   ( fixed first-of-month)
        DUP Day-of-Week-from-Fixed 4 * SPACES
    R> OVER - 1+ 1 DO
        I 2 .R
        2DUP = IF  ." * "  ELSE  2 SPACES  THEN
        1+  DUP Day-of-Week-from-Fixed 0= IF CR THEN
    LOOP
    Day-of-Week-from-Fixed IF CR THEN
    DROP ;

: CAL ( month day year -- )  Fixed-from-Gregorian Calendar ;

0 [IF] =======================================================
Gregorian-Date-Difference  ( greg-date-1 . . greg-date-2 . . -- n )
    Number of days from Gregorian date _greg-date-1_ until _greg-date-1_.

Days-Remaining    ( gregorian-date . . -- +n )
    Days remaining in year after Gregorian date _gregorian-date_.
------------------------------------------------------- [THEN]

: Gregorian-Date-Difference         ( g-date-1 . . g-date-2 . . -- n )
    Fixed-from-Gregorian >R Fixed-from-Gregorian R> SWAP - ;

: Days-Remaining                    ( month day year -- n )
    DUP  DEC 31 ROT  Gregorian-Date-Difference ;

0 [IF] =======================================================
  `Kday` has been changed to `Weekday`.

  `Nth-Kday` has been changed to `'th-Weekday`.

Weekday-on-or-Before  ( fixed-date-1 weekday -- fixed-date-2 )
    _fixed-date-2_ of the _weekday_ on or before
    _fixed-date-1_. _weekday_=0 means Sunday, _weekday_=1
    means Monday, and so on.

Weekday-on-or-After   ( fixed-date-1 weekday -- fixed-date-2 )
    _fixed-date_ of the _weekday_ on or after _fixed-date_.
    _weekday_=0 means Sunday, _weekday_=1 means Monday, and
    so on.

Weekday-Nearest       ( fixed-date-1 weekday -- fixed-date-2 )
    _fixed-date_ of the _weekday_ nearest _fixed-date_.
    _weekday_=0 means Sunday, _weekday_=1 means Monday, and
    so on.

Weekday-After    ( fixed-date-1 weekday -- fixed-date-2 )
    _fixed-date_ of the _weekday_ after _fixed-date_.
    _weekday_=0 means Sunday, _weekday_=1 means Monday, and
    so on.

Weekday-Before  ( fixed-date-1 weekday -- fixed-date-2 )
    _fixed-date_ of the _weekday_ before _fixed-date_.
    _weekday_=0 means Sunday, _weekday_=1 means Monday, and
    so on.

'th-Weekday    ( n weekday month day year -- fixed-date )
    _fixed-date_ of _n_'th _weekday_ after _month day year_.
    If _n_>0, return the _n_'th _weekday_ on or after the date. If
    _n_<0, return the _n_'th _weekday_ on or before the date. A
    _weekday_ of 0 means Sunday, 1 means Monday, and so on.

FIRST   ( -- n )
    Index for selecting a _weekday_.

LASTi   ( -- n )   \ To avoid overwriting LAST
    Index for selecting a _weekday_.
------------------------------------------------------- [THEN]

: Weekday-on-or-Before     ( date k -- date' )
    OVER SWAP - Day-of-Week-from-Fixed - ;

: Weekday-on-or-After  ( date k -- date' )
    SWAP 6 + SWAP Weekday-on-or-Before ;

: Weekday-Nearest     ( date k -- date' )
    SWAP 3 + SWAP Weekday-on-or-Before ;

: Weekday-After     ( date k -- date' )
    SWAP 7 + SWAP Weekday-on-or-Before ;

: Weekday-Before     ( date k -- date' )
    SWAP 1- SWAP Weekday-on-or-Before ;

: 'th-Weekday  ( n k month day year -- date )
    Fixed-from-Gregorian       ( n k date)
    SWAP ROT >R                ( date k)( R: n)
    R@ 0< IF  Weekday-After  ELSE  Weekday-Before  THEN ( date)
    R> 7 * + ;

1 CONSTANT FIRST
-1 CONSTANT LASTi

0 [IF] =======================================================

            "Holidays"

Independence-Day    ( gregorian-year -- fixed-date )
    _fixed-date_ of American Independence Day in _gregorian-year_.

Labor-Day   ( gregorian-year -- fixed-date )
    _fixed-date_ of American Labor Day in _gregorian-year_--the
    first Monday in September.

Memorial-Day   ( gregorian-year -- fixed-date )
    _fixed-date_ of American Memorial Day in Gregorian
    year--the last Monday in May.

Election-Day    ( gregorian-year -- fixed-date )
    _fixed-date_ of American Election Day in Gregorian
    year--the Tuesday after the first Monday in November.

Daylight-Savings-Start      ( gregorian-year -- fixed-date )
    _fixed-date_ of the start of American daylight savings time
    in _gregorian-year_--the first Sunday in April.

Daylight-Savings-End   ( gregorian-year -- fixed-date )
    _fixed-date_ of the end of American daylight savings time
    in _gregorian-year_--the last Sunday in October.

Thanksgiving        ( gregorian-year -- fixed-date )
    _fixed-date_ of Christmas in _gregorian-year_.

Christmas  ( gregorian-year -- fixed-date )
    _fixed-date_ of Christmas in _gregorian-year_.

Advent   ( gregorian-year -- fixed-date )
    _fixed-date_ of Advent in _gregorian-year_.

Epiphany    ( gregorian-year -- fixed-date )
    _fixed-date_ of Epiphany in _gregorian-year_.

------------------------------------------------------- [THEN]

: Independence-Day                  ( greg-year -- fixed-date )
    JUL 4 ROT  Fixed-from-Gregorian ;

: Labor-Day  ( year -- fixed-date )
    >R  FIRST MON SEP 1 R> 'th-Weekday ;

: Memorial-Day   ( year -- fixed-date )
\    >R  LASTi MON MAY R> 'th-Weekday ;
    >R  LASTi MON MAY 31 R> 'th-Weekday ;

: Election-Day  ( year -- fixed-date )
    >R FIRST TUE NOV 2 R> 'th-Weekday ;

: Daylight-Savings-Start  ( year -- fixed-date )
    >R FIRST SUN APR 1 R> 'th-Weekday ;

: Daylight-Savings-End  ( year -- fixed-date )
    >R LASTi SUN OCT 31 R> 'th-Weekday ;

: Thanksgiving  ( year -- fixed-date )
    >R 4 THU NOV 1 R> 'th-Weekday ;

: Christmas  ( year -- fixed-date )
    DEC 25 ROT Fixed-from-Gregorian ;

: Advent  ( year -- fixed-date )
    NOV 30 ROT Fixed-from-Gregorian SUN Weekday-Nearest ;

: Epiphany  ( year -- fixed-date )
    1- Christmas 12 + ;

0 [IF] =======================================================

        ISO Calendar

Fixed-from-ISO   ( week day year -- fixed-date )
    _fixed-date_ equivalent to ISO (week day year).

ISO-from-Fixed   ( fixed-date -- week day year )
    ISO (week day year) corresponding to the _fixed-date_.

------------------------------------------------------- [THEN]

: Fixed-from-ISO  ( week day year -- fixed-date )
    >R          ( week day)( R: year)
    SWAP SUN DEC 28 R> 1- ( day week sun month day year)
    'th-Weekday + ;

: ISO-from-Fixed  ( fixed-date -- week day year )
    DUP >R                       ( R: date )
    3 - Gregorian-Year-from-Fixed    ( approx)
    1 1 THIRD 1+ Fixed-from-ISO R@ > NOT -  ( year)
    1 1 THIRD Fixed-from-ISO R@ SWAP - 7 /_ 1+  ( year week)
    R> 1- 7 _MOD 1+                         ( year week day)
    ROT ( week day year) ;

0 [IF] =======================================================

        Julian Calendar

Julian-Epoch         ( fixed-date )
    _fixed-date_ of start of the Julian calendar.

BCE  ( standard-year -- julian-year )
    Negative value to indicate a BCE Julian year.

CE       ( standard-year -- julian-year )
    Positive value to indicate a CE Julian year.

Julian-Leap-Year?   ( julian-year -- flag )
    True if year is a leap year on the Julian calendar.

Fixed-from-Julian  ( julian-date -- fixed-date )
    _fixed-date_ equivalent to the Julian date.

Julian-from-Fixed      ( fixed-date -- julian-date )
    Julian (month day year) corresponding to _fixed-date_.
------------------------------------------------------- [THEN]

DEC 30 0 Fixed-from-Gregorian CONSTANT Julian-Epoch

: Julian-Leap-Year?                    ( j-year -- flag )
    DUP >R  4 _MOD  R> 0> IF  0  ELSE  3  THEN = ;

: Fixed-from-Julian    ( month day year -- fixed-date )
    >R SWAP                         ( day month)( R: year)
        DUP >R  367 * 362 - 12 /  + ( day)( R: year month)
    R> 2 > IF                             ( day)( R: year)
        R@ Julian-Leap-Year? IF  1-  ELSE  2 -  THEN
    THEN
    Julian-Epoch + 1-
    R> DUP 0< - 1- DUP >R  365 * +  R> 4 /_ + ;

: Julian-from-Fixed  ( fixed-date -- month day year )
    DUP Julian-Epoch - 4 *  1464 +  1461 /_    ( date approx)
    DUP 0> NOT + >R                         ( date)( R: year)
        DUP JAN 1 R@ Fixed-from-Julian -   ( date prior-days)
        OVER MAR 1 R@ Fixed-from-Julian < NOT IF
            R@ Julian-Leap-Year? IF  1+  ELSE  2 +  THEN
        THEN
        12 *  373 +  367  /_                    ( date month)
        SWAP OVER 1 R@ Fixed-from-Julian - 1+    ( month day)
    R> ( month day year) ;

0 [IF] =======================================================
        Ecclesiastical Calendars

Nicaean-Rule-Easter   ( julian-year -- fixed-date )
    _fixed-date_ of Easter in positive Julian year, according
    to the rule of the Council of Nicaea.

Easter    ( gregorian-year -- fixed-date )
    _fixed-date_ of Easter in _gregorian-year_.

Pentecost    ( gregorian-year -- fixed-date )
    _fixed-date_ of Pentecost in _gregorian-year_.

Julian-in-Gregorian   ( j-month j-day greg-year -- list-of-fixed-dates )
    The list of the _fixed-dates_ of Julian month, day that occur
    in _gregorian-year_.

Eastern-Orthodox-Christmas  ( gregorian-year -- list-of-fixed-dates )
    List of zero or one _fixed-dates_ of Eastern Orthodox
    Christmas in _gregorian-year_.

------------------------------------------------------- [THEN]

: Nicaean-Rule-Easter      ( j-year -- date )
    DUP >R                                      ( R: j-year)
    19 MOD 11 * 14 + 30 MOD                 ( shifted-epact)
    APR 19 R> Fixed-from-Julian SWAP -       ( paschal-moon)
    SUN Weekday-After ;

: Easter                   ( greg-year -- date )
    DUP >R                                      ( R: greg-year)
    100 / 1+                                      ( century)
    R@ 19 MOD 11 * 14 +             ( century shifted-epact)
    OVER 3 * 4 / -
    SWAP 8 * 5 + 25 / +                     ( shifted-epact)
    30 MOD
    DUP 0= IF  1+
    ELSE  DUP 1 = 10 R@ 19 MOD < AND IF  1+
    THEN THEN                              ( adjusted-epact)
    APR 19 R> Fixed-from-Gregorian SWAP -    ( paschal-moon)
    SUN Weekday-After ;

: Pentecost  ( greg-year -- date )
    Easter 49 + ;

: Ash-Wednesday ( greg-year -- date )
    Easter 46 -  ;


0 [IF] =======================================================
        Islamic Calendar

Islamic-Epoch  ( -- fixed-date )
    _fixed-date_ of start of the Islamic calendar.

Fixed-from-Islamic  ( islamic-date -- fixed-date )
    _fixed-date_ equivalent to Islamic date.

Islamic-from-Fixed  ( fixed-date -- islamic-date )
    Islamic date (month day year)
    corresponding to _fixed-date_.

------------------------------------------------------- [THEN]

JUL 16 622 Fixed-from-Julian CONSTANT Islamic-Epoch

: Fixed-from-Islamic  ( month day year -- fixed )
    >R SWAP              ( day month)( R: year)
    1- 295 * 5 + 10 /_ +
    R@ 1- 354 * +
    R> 11 * 3 + 30 /_ +
    Islamic-Epoch + 1- ;

: Islamic-from-Fixed   ( fixed -- month day year )
    DUP Islamic-Epoch - 30 * 10646 + 10631 /_ >R ( R: year)
    DUP 29 - 1 1 R@ Fixed-from-Islamic - 2* 59 /_MOD SWAP IF 1+ THEN
    1+ 12 MIN   ( date month)
    SWAP OVER 1 R@ Fixed-from-Islamic - 1+  ( month day)
    R> ( month day year) ;

0 [IF] =======================================================

        Hebrew Calendar

Hebrew-Epoch          ( -- fixed-date )
    _fixed-date_ of start of the Hebrew calendar, that is,
    Tishri 1, 1 AM.

Hebrew-Leap-Year? ( hebrew-year -- flag )
    True if year is a leap year on Hebrew calendar.

Last-Month-of-Hebrew-Year ( hebrew-year -- hebrew-month )
    Last month of Hebrew year.

Long-Heshvan? ( hebrew-year -- flag )
    True if Heshvan is long in Hebrew year.

Short-Kislev?  ( hebrew-year -- flag )
    True if Kislev is short in Hebrew year.

Last-Day-of-Hebrew-Month ( hebrew-month hebrew-year  -- hebrew-day )
    Last day of month in Hebrew year.

Hebrew-Calendar-Elapsed-Days  ( hebrew-year -- n )
    Number of days elapsed from the (Sunday) noon prior to
    the epoch of the Hebrew calendar to the mean conjunction
    (molad) of Tishri of Hebrew year h-year, or one day
    later.

Hebrew-New-Year-Delay  ( hebrew-year -- [0,1,2] )
    Delays to start of Hebrew year to keep ordinary year in
    range 353-356 and leap year in range 383-386.

Days-in-Hebrew-Year  ( hebrew-year -- [353,354,355,383,384,385] )
    Number of days in Hebrew year.  Calls Fixed-from-Hebrew
    for value that does not in turn require
    Days-in-Hebrew-Year.

------------------------------------------------------- [THEN]
OCT 7 -3761 Fixed-from-Julian CONSTANT Hebrew-Epoch

: Hebrew-Leap-Year?
    7 *  1+  19 _MOD  7 < ;

: Last-Month-of-Hebrew-Year
    Hebrew-Leap-Year? IF  13  ELSE  12  THEN ;

: Hebrew-Calendar-Elapsed-Days  ( h-year -- day )
    235 * 234 - 19 /_      ( months-elapsed)
    DUP 13753 * 12084 +    ( month-elapsed parts-elapsed)
    25920 /_ SWAP 29 * +   ( day)
    DUP 1+ 3 * 7 _MOD 3 < - ;

: Hebrew-New-Year-Delay  ( h-year -- n )
    DUP 1- Hebrew-Calendar-Elapsed-Days ( year ny0)
    OVER Hebrew-Calendar-Elapsed-Days   ( year ny0 ny1)
    ROT 1+ Hebrew-Calendar-Elapsed-Days ( ny0 ny1 ny2)
    OVER - 356 = IF  2DROP  2
    ELSE SWAP - 382 = IF    1
    ELSE                    0
    THEN THEN ;

DEFER Fixed-from-Hebrew  ( month day year -- date )

: Days-in-Hebrew-Year    ( h-year -- days )
    >R  7 1 R@ 1+ Fixed-from-Hebrew
    7 1 R> Fixed-from-Hebrew - ;

: Long-Heshvan?  ( h-year -- flag )
    Days-in-Hebrew-Year 10 MOD 5 = ;

: Short-Kislev?  ( h-year -- flag )
    Days-in-Hebrew-Year 10 MOD 3 = ;

: Last-Day-of-Hebrew-Month  ( month year -- day )
    \  Bits  2 4 6 10 13
    OVER 1 SWAP LSHIFT
       [ 2 BASE ! ] 10010001010100 [ DECIMAL ]
    AND
        IF 2DROP  29  EXIT THEN

    OVER 12 = IF
        DUP Hebrew-Leap-Year? NOT IF 2DROP  29  EXIT THEN
    THEN

    OVER 8 = IF
        DUP Long-Heshvan? NOT     IF 2DROP  29  EXIT THEN
    THEN

    OVER 9 = IF
        DUP Short-Kislev?         IF 2DROP  29  EXIT THEN
    THEN

    2DROP  30 ;

0 [IF] =======================================================

Fixed-from-Hebrew  ( hebrew-date -- fixed-date )
    _fixed-date_ from Hebrew date. This function is designed so
    that it works for Hebrew dates month, day, year even if
    the month has fewer than day days--in that case the
    function returns the (day-1)st day after month 1, year.
    This property is required by the functions
    hebrew-birthday and yahrzeit.

Hebrew-from-Fixed   ( fixed-date -- hebrew-date )
    Hebrew (month day year) corresponding to _fixed-date_. The
    fraction can be approximated by 365.25.

------------------------------------------------------- [THEN]

: (Fixed-from-Hebrew)    ( month day year -- date )
    Hebrew-Epoch           ( month day year date)
    OVER Hebrew-Calendar-Elapsed-Days +
    OVER Hebrew-New-Year-Delay +  THIRD +  1 -
    FOURTH 7 < IF
        OVER Last-Month-of-Hebrew-Year 1+ 7 DO
            OVER I SWAP Last-Day-of-Hebrew-Month +
        LOOP
        FOURTH 1 ?DO
            OVER I SWAP Last-Day-of-Hebrew-Month +
        LOOP
    ELSE
        FOURTH 7 ?DO
            OVER I SWAP Last-Day-of-Hebrew-Month +
        LOOP
    THEN
    NIP NIP NIP ;

' (Fixed-from-Hebrew) IS Fixed-from-Hebrew

: Hebrew-from-Fixed  ( date -- month day year )
    DUP >R                          ( R: date)
    Hebrew-Epoch -  98496  35975351  */_    ( approx)
    BEGIN  7 1 THIRD Fixed-from-Hebrew  R@ > NOT WHILE
           1+
    REPEAT 1- >R                     ( )( R: date year)
    2R@ 1 1 ROT Fixed-from-Hebrew < IF 7 ELSE 1 THEN
                                            ( start)
    BEGIN  DUP DUP R@ Last-Day-of-Hebrew-Month
           R@ Fixed-from-Hebrew 2R@ DROP <
    WHILE  1+  REPEAT                       ( month)
    DUP 1 R@ Fixed-from-Hebrew 2R@ DROP SWAP - 1+
                                        ( month day)
    R> ( month day year)  R> DROP ;

0 [IF] =======================================================

            Hebrew Holidays and Fast Days

Yom-Kippur ( gregorian-year -- fixed-date )
    _fixed-date_ of Yom Kippur occurring in
    _gregorian-year_.

Passover ( gregorian-year -- fixed-date )
    _fixed-date_ of Passover occurring in _gregorian-year_.

Omer ( fixed-date -- omer-count )
    Number of elapsed weeks and days in the omer at date.
    Returns bogus if that date does not fall during the
    omer.

Purim   ( gregorian-year -- fixed-date )
    _fixed-date_ of Purim occurring in _gregorian-year_.

Ta-Anith-Esther ( gregorian-year -- fixed-date )
    _fixed-date_ of Ta'anith Esther occurring in
    _gregorian-year_.

Tisha-B-Av ( gregorian-year -- fixed-date )
    _fixed-date_ of Tisha B'Av occurring in Gregorianyear.

Birkath-Ha-Hama  ( gregorian-year -- list-of-fixed-dates )
    List of _fixed-date_ of Birkath HaHama occurring in
    _gregorian-year_, if it occurs.

Sh-Ela ( gregorian-year -- fixed-date )
    _fixed-date_ of Sh'ela occurring in _gregorian-year_.

Yom-Ha-Zikaron ( gregorian-year -- fixed-date )
    _fixed-date_ of Yom HaZikaron occurring in _gregorian-year_.

------------------------------------------------------- [THEN]

: Yom-Kippur        ( gregorian-year -- fixed-date )
    7 10 ROT Hebrew-Epoch Gregorian-Year-from-Fixed - 1+
    Fixed-from-Hebrew ( date) ;

: Rosh-Hashanah        ( gregorian-year -- fixed-date )
    7 1 ROT Hebrew-Epoch Gregorian-Year-from-Fixed - 1+
    Fixed-from-Hebrew ;

: Passover            ( gregorian-year -- fixed-date )
    1 15 ROT Hebrew-Epoch Gregorian-Year-from-Fixed -
    Fixed-from-Hebrew ;

: Purim   ( gregorian-year -- fixed-date )
    Hebrew-Epoch Gregorian-Year-from-Fixed - ( h-year)
    DUP Last-Month-of-Hebrew-Year  ( h-year month)
    14 ROT    ( month day year)
    Fixed-from-Hebrew ( date) ;

: Esther    ( gregorian-year -- fixed-date )
    Purim DUP Day-of-Week-from-Fixed SUN =
        IF 3 - ELSE 1- THEN
    ;

: Yom-Hashoah    ( gregorian-year -- fixed-date )
    1 27 ROT Hebrew-Epoch Gregorian-Year-from-Fixed -
    Fixed-from-Hebrew ( date) ;

: Hanukkah        ( gregorian-year -- fixed-date )
    9 25 ROT Hebrew-Epoch Gregorian-Year-from-Fixed - 1+
    Fixed-from-Hebrew ( date) ;

0 [IF] =======================================================

            Days of Personal Interest

Hebrew-Birthday ( hebrew-birthdate . . hebrew-year -- fixed-date )
    _fixed-date_ of the anniversary of _hebrew-birthdate_
    occurring in _hebrew-year_.  This function assumes that the
    function `Fixed-from-Hebrew` works for Hebrew _month
    day year_ even if the month has fewer than _day_ days--in
    that case the function returns the (_day_-1)st day after
    _month_ 1 _year_.

Yahrzeit     ( hebrew-deathdate . . hebrew-year -- fixed-date )
    _fixed-date_ of the anniversary of _hebrew-deathdate_
    occurring in _hebrew-year_.  This function assumes that the
    function `Fixed-from-Hebrew` works for Hebrew _month
    day year_ even if the month has fewer than _day_ days--in
    that case the function returns the (_day_-1)st day after
    _month_ 1 _year_.

------------------------------------------------------- [THEN]

: Hebrew-Birthday  ( b-month b-day b-year h-year -- date )
    >R             ( b-month b-day b-year)( R: h-year)
    THIRD SWAP Last-Month-of-Hebrew-Year = IF ( month day)
        R@ Last-Month-of-Hebrew-Year OVER R>
    ELSE
        2DUP R>
    THEN
    Fixed-from-Hebrew  NIP NIP ;

: Yahrzeit ( death-month death-day death-year h-year -- date )
    >R     ( death-month death-day death-year)( R: h-year)
    THIRD 8 =
    ANDIF OVER 30 =
    ANDIF DUP 1- Long-Heshvan? NOT
    THEN  THEN
        IF  3DROP  9 1 R> Fixed-from-Hebrew  1- EXIT THEN

    THIRD 9 =
    ANDIF OVER 30 =
    ANDIF DUP 1+ Short-Kislev?
    THEN  THEN
        IF  3DROP  10 1 R>  Fixed-from-Hebrew  1- EXIT THEN

    THIRD 13 = IF
        DROP NIP R@ Last-Month-of-Hebrew-Year SWAP R>
        Fixed-from-Hebrew  EXIT THEN

    THIRD 12 =
    ANDIF OVER 30 =
    ANDIF R@ Hebrew-Leap-Year? NOT
    THEN  THEN
        IF  3DROP  11 30 R> Fixed-from-Hebrew  EXIT THEN

    DROP R> Fixed-from-Hebrew ;

\s \  End of Calendrical Calculations
