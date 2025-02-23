marker multiport_gate.f  \ 21-02-2025 by J.v.d.Ven

0 [if]
A multiport gate can be used make a decision depending on multiple conditions.
One multiport gate uses 2 lfields (64 bits variable).
The first lfield contains the inputs.
The second lfield contains its properties.
One input uses only one bit.
The output is limited to 0 or 1
A network of multiport gates is possible.
Needs: x:structures pack like struct200x.f
Tested on  Cforth, Gforth 32 bits and 64 bits and Win32Forth.

Advantages:
- All inputs and results are easy to track.
- Simulation is possible.
- Less chance for errors.
- Creates compact code.
- One multiport gate compares only ONE value and the content of ONE lfield to make a
  decision, instead of having to check a number of separate variables or bytes.

28-1-2025
- Now it uses l@ and l! for a 64 bits Forth like Gforth.
- Removed the dependicies on Common-extensions.f outside cforth
- Better structure of /multiport

[then]


\ ------  Check for l! l@  (32 bits ! and 32 bits @)

decimal

s" cforth" ENVIRONMENT? [if] drop
   \ Assumes:
   \ 1) Clone: https://github.com/Jos-Ven/cforth
   \ 2) Build: ~/cforth/build/esp32-extra
   needs lfield: Common-extensions.f \ Should be in flash memory by now.
   alias !l !
   [else]   [undefined]  l! also environment max-n previous 2147483647 = and [if]
                 synonym l! !    synonym l@ @     \ For 32 bits Forth systems (200x)
            [ELSE]     [undefined]  l! [if]       \ For 64 bits Forth systems
            cr .( Error: Define l! and l@ here and disable this line. )  abort
                       [then]
            [then]
   [then]


s" gforth" ENVIRONMENT? [IF] 2drop
: bfield: ( n1 <"name"> -- n2 ) ( addr -- 'addr )  #1 +field ;
[then]


s" win32forth" ENVIRONMENT? [if] drop
   dup-warning-off sys-warning-off
\   cls font NewFont  18 height: NewFont  NewFont SetFont: cmd   synonym es reset-stacks
[then]

\ ------  Primitives

begin-structure /multiport
  lfield: inputs
  bfield: >threshold \ For sum-mp
  bfield: >#bInputs  \ The number of used bits
  bfield: >last-out  \ Optional to be set by an application
  bfield: >reserved1
end-structure

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

: binput:       \ Compile-time: ( input# &multiport <name> - input#+1 &multiport )
   create dup , swap dup , 1+ swap
   does> 2@ ;   \ Run-time: ( - input# &multiport )

: bInput@     ( input# &multiport - input-value ) l@ swap test-bit abs ;
: bInput!     ( flag input# &multiport - )  dup >r l@ -rot bit! r> l! ;
: bInputon    ( input# &multiport - )      1 -rot bInput! ;
: bInputoff   ( input# &multiport - )      0 -rot bInput! ;
: .bInput     ( input# &multiport - )      over . bInput@ .  ;

: .inputs    ( #inputs &inputs - )
   cr ." # Input"  swap 1st-bInput
     do    i over cr .bInput
     loop  drop ;

: .inputs-mp ( &multiport - ) dup >#bInputs c@ swap .inputs ;

: activated-bit#    ( bit# &multiport - activated-bit ) drop activate-bit ;
: all-bits          ( &multiport - value-all-used-bits ) >#bInputs c@ push-bits ;

: invert-bit-input  ( input# &multiport  - )
   2dup bInput@ 0= -rot bInput!  ;

: invert-dest-input ( input#_source &multiport input#_dest &multiport - )
   2swap bInput@ 0= -rot bInput! ;


\ ------ Queries:

: sum-inputs ( &multiport - sum-inputs ) dup l@ swap >#bInputs c@ sum-bits ;

: sum-mp     ( &multiport - flag )       dup sum-inputs  swap >threshold c@  >=  ;
: .sum-mp    ( &multiport - )
     dup >r .inputs-mp
   cr r@ sum-inputs  dup
   ." Output," r> >threshold c@   \ Minimal needed
   ." threshold: "  dup .   >= swap     .(result)  ;

: l? ( adr - ) l@ . ;

: match-mp   ( pattern &multiport - flag ) l@ = ;
: .match-mp  ( pattern &multiport - )
   dup >r .inputs-mp \ >#bInputs c@ r@ .inputs
   cr dup r@ match-mp
      ."     Input value: " r> l?
   cr ."        Match at: " swap . dup  .(result) ;

: any-mp     ( &multiport - flag ) l@ 0<> ;
: .any-mp    ( &multiport - )
   dup >r .inputs-mp
   cr     r@ any-mp
      ."     Input value: " r> l?
   cr ."             Any: " dup . dup   .(result) ;


\ ------ Use:

1 [if] \ Change the 0 into 1 for the following test case

create eg-multiport 8 allot          \    Step 1: Create a 64 bits variable for a multiport gate

0 eg-multiport bInput: i_present     \ 0  Step 2: Enumerate and name the input bits
               bInput: i_Temperature \ 1
               bInput: i_Light       \ 2
                       >#bInputs c!  \ 3  Step 3: Set >#bInputs and >threshold
3 eg-multiport >threshold c!

cr .( eg-multiport defined.) cr


\ Set the inputs
     i_present bInputOn
 i_Temperature bInputOn
   1   i_Light bInput! \ Nonzero values are replaced by 1.


\ eg-multiport sum-inputs .
\ eg-multiport sum-mp . \ Slow  ( uses: do...loop )

: eval-eg-multiport  ( - flag )   \ Fast!
  [ eg-multiport all-bits ] literal eg-multiport match-mp ;

: .eval-eg-multiport ( - )
    eg-multiport .inputs-mp
    cr eval-eg-multiport dup .  if  ." Active."   else  ." Off."   Then ;

.eval-eg-multiport

\ eg-multiport >threshold c@ .
\ eg-multiport l?
\ i_present invert-bit-input .eval-eg-multiport

[then]
