marker multiport_gate.f  \ 6-2-2024 by J.v.d.Ven

0 [if]

A multiport gate can be used make a decision depending on multiple conditions.
One multiport gate uses 2 cells.
The first cell contains the inputs.
The second cell contains its properties.
One input uses only one bit.
The output is limited to 0 or 1
A network of multiport gates is possible.

Advantages:
- All inputs and results are easy to track.
- Simulation is possible.
- Less chance for errors.
- Creates compact code.
- One multiport gate compares only one value and one variable (cell) to make a
  decision, instead of having to check a number of separate variables.

[then]

s" win32forth" ENVIRONMENT? [IF] DROP
dup-warning-off sys-warning-off
[then]


\ ------  Primitives

begin-structure /multiport
  lfield: inputs
  cfield: >threshold \ For sum-mp
  cfield: >#bInputs  \ Set the number of used bits
  cfield: >last-out  \ Optional to be set by an application
  cfield: >reserved2
end-structure

: b.     ( n -  )  base @ 2 base ! swap u. base ! ;

0 constant 1st-bInput
: .line-- ( - ) cr ." ---------------------" ;

: .(result) ( flag  activation-value - )
   cr ." Activation value: "  .
   cr ."       Output ---> "
     if   ." Activated!"
     else ." off"
     then  .line-- ;

s" win32forth" ENVIRONMENT? [IF] DROP
dup-warning-on sys-warning-on
[then]


\ ------  Adressing the bits on the stack:

: activate-bit ( bit# - n+shift1bit )  1 swap lshift ;
: bit@         ( n bit# - bit )        activate-bit and ;
: test-bit     ( n bit# - true/false ) bit@ 0<> ;

: bit!  ( n 1/0 bit# - n-bit! )      \ Sets a bit ( 1/0 ) at position bit# in n
   dup activate-bit rot
       if   rot or nip               \ 1 ( 1 1-bit# - 1-bit )
       else drop over swap bit@ dup
            if   -                   \ 3 ( 0 1-bit# - 0-bit )
            else drop                \ 2 ( 0 0-bit# - 0-bit )
            then
       then ;

: push-bits  ( #bits - bits-pushed )
   0 swap 0
      do  i activate-bit or
      loop ;

: sum-bits   ( n #bits- #active-bits )
   0 swap 1st-bInput
     do  over i bit@ 0> swap +
     loop
   nip abs ;


\ ------ Adressing the inputs of a multiport gate:

: binput:
   create dup , swap dup , 1+ swap  \ compile-time: ( input# &multiport - input#+1 &multiport )
   does> 2@ ;                       \     run-time: ( - input# &multiport )

: bInput@    ( input# &multiport - input-value ) @ swap test-bit abs ;
: bInput!    ( flag input# &multiport - )  dup >r @ -rot bit! r> ! ;
: bInputon   ( input# &multiport - )      1 -rot bInput! ;
: bInputoff  ( input# &multiport - )      0 -rot bInput! ;
: .bInput    ( input# &multiport - )      over . bInput@ .  ;
: .inputs    ( #inputs &inputs - )
   cr ." # Input"
   swap 1st-bInput
     do    i over cr .bInput
     loop  drop ;

: activated-bit#    ( bit# &multiport - activated-bit ) drop activate-bit ;
: all-bits          ( &multiport - all-used-bits ) >#bInputs c@ push-bits ;

: invert-bit-input  ( input# &multiport  - )
   2dup bInput@ not -rot bInput!  ;

: invert-dest-input ( input#_source &multiport input#_dest &multiport - )
   2swap bInput@ not -rot bInput! ;


\ ------ Queries:

: sum-inputs ( &multiport - sum-inputs ) dup @ swap >#bInputs c@ sum-bits ;

: sum-mp     ( &multiport - flag )       dup sum-inputs  swap >threshold c@  >=  ;
: .sum-mp    ( &multiport - )
     dup >r >#bInputs c@ r@ .inputs
   cr r@ sum-inputs  dup
   ." Output," r> >threshold c@   \ Minimal needed
   ." threshold: "  dup .   >= swap     .(result)  ;

: match-mp   ( pattern &multiport - flag ) @ over and = ;
: .match-mp  ( pattern &multiport - )
   dup >r >#bInputs c@ r@ .inputs
   cr dup r@ match-mp
      ."     Input value: " r> ?
   cr ."        Match at: " swap . dup  .(result) ;

: any-mp     ( &multiport - flag ) @ 0<> ;
: .any-mp    ( &multiport - )
   dup >r >#bInputs c@ r@ .inputs
   cr     r@ any-mp
      ."     Input value: " r> ?
   cr ."             Any: " dup . dup   .(result) ;


\ ------ Use:

0 [if] \ Change the 0 into 1 for the following test case

2variable eg-multiport

0 eg-multiport bInput: i_present     \ 0
               bInput: i_Temperature \ 1
               bInput: i_Light       \ 2
               >#bInputs c!          \ 3
3 eg-multiport >threshold c!

 i_present     bInputOn
 i_Temperature bInputOn
 i_Light       bInputOn  cr eg-multiport .sum-mp  \ Slow

: .test-multiport  ( - )  \ Fast!
  [ eg-multiport all-bits ] literal eg-multiport .match-mp ;

cr .test-multiport

\ eg-multiport dup >#bInputs c@ swap .inputs
\ eg-multiport >threshold c@ .
\ eg-multiport ?
[then]
