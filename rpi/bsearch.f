\ bsearch.f for Gforth or Win32Forth

[undefined] newuser [if]
: newuser    ( size <name> -- )  Header reveal douser,  uallot , ;
[then]

1 cells newuser bs-record-size

: bs-mid        ( n - mid )   2/ dup bs-record-size @ mod -  ;

\ Stack at needed at the executed compare: ( $candidate $target - f )
: bs-number  ( $candidate $target - f ) @ swap @   < ;
: bs-doubles ( $candidate $target - f ) 2@ rot 2@ d< ;
: bs-strings ( $candidate $target - f ) count rot bs-record-size @ compare 0< ;

: bsearch ( 'compare &data bs-record-size $target -- &result )
    over             \ binary searches a sorted array at &data for a
      if  >r 2dup  bs-mid + r@ 4 pick execute \ target stored at $target
             if    bs-mid
             else  dup bs-mid bs-record-size @ + tuck - -rot + swap
             then
          r> recurse exit
      then  2drop nip bs-record-size @ - ;

: bsearch-numbers ( &data #elements target bs-record-size - &result )
  bs-record-size !     >r ['] bs-number -rot bs-record-size @ * r>
  2 pick @  max  pad !  pad  bsearch ;

: bsearch-doubles ( &data #elements Dtarget bs-record-size - &result )
  bs-record-size !  2>r ['] bs-doubles -rot bs-record-size @ * 2r>
  3 pick 2@ dmax pad 2! pad  bsearch ;

: bsearch-strings ( &data #elements target$ count bs-record-size - &result )
  bs-record-size !
  2dup 2>r 3 pick bs-record-size @ compare 0<
    if    2r> 2drop drop
    else  ['] bs-strings -rot bs-record-size @ *  2r>
          pad place pad bsearch
    then ;


0  [if]  \ Tests:

4 value #records \ When used by more threads a user should be used.
create data  -4 , -3 , -1 , 0 ,    cell value /data

create dataRecords
  -4 , -17 , -27 , -37 ,
  -3 , -16 , -26 , -36 ,
  -1 , -14 , -24 , -34 ,
   0 , -10 , -20 , -30 ,
here dataRecords - #records / value /dR

create ddata -1 , -4 , -1 , -3 , -1 , -1 ,  0 ,  0 ,
here ddata - #records / value /ddata

create ddataRecords
  -1 , -4 , -1 , -17 , -1 , -27 , -1 , -37 ,
  -1 , -3 , -1 , -16 , -1 , -26 , -1 , -36 ,
  -1 , -1 , -1 , -14 , -1 , -24 , -1 , -34 ,
   0 ,  0 , -1 , -10 , -1 , -20 , -1 , -30 ,
here ddataRecords - #records / value /ddR

create data$Records ," first hello there zlast "
data$Records count #records /  value /d$R

cr
 data #records -5 /data bsearch-numbers ?
 data #records -4 /data bsearch-numbers ?
 data #records -3 /data bsearch-numbers ?
 data #records -2 /data bsearch-numbers ?
 data #records -1 /data bsearch-numbers ?
 data #records -0 /data bsearch-numbers ?
 data #records  5 /data bsearch-numbers ?

cr
 dataRecords #records -5 /dR bsearch-numbers ?
 dataRecords #records -4 /dR bsearch-numbers ?
 dataRecords #records -3 /dR bsearch-numbers ?
 dataRecords #records -2 /dR bsearch-numbers ?
 dataRecords #records -1 /dR bsearch-numbers ?
 dataRecords #records -0 /dR bsearch-numbers ?
 dataRecords #records  5 /dR bsearch-numbers ?

cr
 ddata #records -5 s>d /ddata bsearch-doubles 2@ d.
 ddata #records -4 s>d /ddata bsearch-doubles 2@ d.
 ddata #records -3 s>d /ddata bsearch-doubles 2@ d.
 ddata #records -2 s>d /ddata bsearch-doubles 2@ d.
 ddata #records -1 s>d /ddata bsearch-doubles 2@ d.
 ddata #records -0 s>d /ddata bsearch-doubles 2@ d.
 ddata #records  5 s>d /ddata bsearch-doubles 2@ d.

cr
 ddataRecords #records -5 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records -4 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records -3 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records -2 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records -1 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records -0 s>d /ddR bsearch-doubles 2@ d.
 ddataRecords #records  5 s>d /ddR bsearch-doubles 2@ d.

6 bs-record-size !   data$Records 1+  cr
  dup #records s" 00000 " /d$R bsearch-strings bs-record-size @ type
  dup #records s" first " /d$R bsearch-strings bs-record-size @ type
  dup #records s" hello " /d$R bsearch-strings bs-record-size @ type
  dup #records s" none  " /d$R bsearch-strings bs-record-size @ type
  dup #records s" zlast " /d$R bsearch-strings bs-record-size @ type
      #records s" zzzzz " /d$R bsearch-strings bs-record-size @ type
 abort [then]

\\\
0 [if] Output:

-4 -4 -3 -3 -1 0 0
-4 -4 -3 -3 -1 0 0
-4 -4 -3 -3 -1 0 0
-4 -4 -3 -3 -1 0 0
first first hello hello zlast zlast


[then]
