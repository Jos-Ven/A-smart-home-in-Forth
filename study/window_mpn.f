marker window_mpn.f  \ Simulation to control a window.

needs multiport_gate.f
0 [if]

22-12-2023, 15:43:48	     Limits during opening hours
Item	       inputs	Actual	Open	Close	JobMin	JobMax
Light (lux)	o	101.90	1.00	0.06	0.00	246.33
Pressure (hPA)	c	1003.88	1010.00	1007.00	1003.39	1004.02
Temperature (C)	c	19.92	23.00	21.00	16.85	17.62
#Changes	o	0	0	4
Opening hours	c	15:43  06:00:00 11:00:00
Month	        c	12	0409

[then]

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
         bInput: i_Override   \ 1
                 >#bInputs c! \ 2

2variable out-mp
0 out-mp bInput: i_autom      \ 0
         bInput: i_gui        \ 1
                 >#bInputs c! \ 2

: init-net ( - )  0 autom-mp !   0 gui-mp !   0 out-mp ! ;

: set-override ( - ) i_Automatic  i_Override   invert-dest-input ;

: eval-wnd-net ( - result-output )     \ Open when true
   set-override                        \ New input for Destination
   [ autom-mp all-bits ] literal autom-mp match-mp     i_autom  bInput!
   [ gui-mp   all-bits ] literal gui-mp   match-mp     i_gui    bInput!
   out-mp any-mp ;

: .eval-wnd-net   ( - ) \ To Track the inputs and outputs.
   eval-wnd-net drop
   cr .line-- space .time
   cr ." Automation " [ autom-mp all-bits ] literal autom-mp .match-mp
   cr ." Gui "        [ gui-mp   all-bits ] literal gui-mp   .match-mp
   cr ." Out "        out-mp .any-mp ;

init-net .eval-wnd-net

0 [if]
    i_Light         bInputOn
    i_Pressure      bInputOn
    i_Temperature   bInputOn
    i_#Changes      bInputOn
    i_OpeningHours  bInputOn
    i_Month         bInputOn  .eval-wnd-net

    i_Automatic     bInputOn  .eval-wnd-net

    i_Temperature   bInputOff .eval-wnd-net

    i_Automatic bInputoff .eval-wnd-net
    i_open      bInputOn  .eval-wnd-net
    i_open      bInputOff .eval-wnd-net

  eval-wnd-net .
[then]


