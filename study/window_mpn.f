marker window_mpn.f  \ Simulation to control a window.

needs multiport_gate.f

2variable autom-mp
0 autom-mp bInput: i_Light        \ 0
           bInput: i_Pressure     \ 1
           bInput: i_Temperature  \ 2
           bInput: i_#Changes     \ 3
           bInput: i_OpeningHours \ 4
           bInput: i_Month        \ 5
           bInput: i_Automatic    \ 6 \ Choose between automatic or manual (Gui)
                     >#bInputs c! \ 7

2variable gui-mp
0 gui-mp bInput: i_open       \ 0
         bInput: i_Override   \ 1  (inverted i_Automatic)
                 >#bInputs c! \ 2

2variable out-mp
0 out-mp bInput: i_autom      \ 0
         bInput: i_gui        \ 1
                 >#bInputs c! \ 2

: init-net      ( - )  0 autom-mp l!   0 gui-mp l!   0 out-mp l! ;

: set-override  ( - ) i_Automatic  i_Override   invert-dest-input ;

: eval-wnd-net  ( - result-output )  \ Updates the relations. Result: Open window when true
   set-override                      \ New input for i_Override
   [ autom-mp all-bits ] literal autom-mp match-mp     i_autom  bInput!
   [ gui-mp   all-bits ] literal gui-mp   match-mp     i_gui    bInput!
   out-mp any-mp ;


: .char##     (  n seperator -- )
    swap s>d <# # #  2 pick hold  #> rot 0= abs /string type ;

: .time&date ( - )
   time&date bl .char##  [char] - .char## [char] - .char##
             bl .char##  [char] : .char## [char] : .char## ;

: .eval-wnd-net ( - )  \ To Track the inputs and outputs.
   eval-wnd-net drop   \ eval-wnd-net is needed to update the relations!
   cr .line--  .time&date
   cr ." Autom " [ autom-mp all-bits ] literal autom-mp .match-mp
   cr ." Gui "   [ gui-mp   all-bits ] literal gui-mp   .match-mp
   cr ." Out "   out-mp .any-mp ;

   init-net .eval-wnd-net

0 [if]
    i_Light         bInputOn
    i_Pressure      bInputOn
    i_Temperature   bInputOn
    i_#Changes      bInputOn
    i_OpeningHours  bInputOn
    i_Month         bInputOn  \ of autom-mp

 autom-mp .inputs-mp
   gui-mp .inputs-mp
   out-mp .inputs-mp
 .eval-wnd-net

    i_Automatic     bInputOn    .eval-wnd-net

\ autom-mp .inputs-mp

    i_Temperature   bInputOff   .eval-wnd-net

    i_Automatic bInputoff .eval-wnd-net
    i_open      bInputOn  .eval-wnd-net \ of gui-mp
    i_open      bInputOff .eval-wnd-net

\  eval-wnd-net .
[then]

cr .( window_mpn.f compiled)
