marker cHeating_net.f \ A network for a central heating system

needs multiport_gate.f

2variable autom-mp
0 autom-mp bInput: i_TimeSpan  \ 0 OpeningHours-
           bInput: i_Present   \ 1 inverted StandBy-
           bInput: i_Automatic \ 2
>#bInputs c!                   \ 3

2variable gui-mp
0 gui-mp bInput: i_Mode        \ 0
         bInput: i_Override    \ 1
>#bInputs c!                   \ 2

2variable out-mp
0 out-mp bInput: i_autom       \ 0
         bInput: i_gui         \ 1
>#bInputs c!                   \ 2

: init-ch-net ( - )
   3 autom-mp >threshold c!
   2 gui-mp   >threshold c!
   1 out-mp   >threshold c!
   0 autom-mp !   0 gui-mp !   0 out-mp ! ;

i_Automatic  bInputOn \ Choose between automatic or manual (Gui)

: add_inputs ( - )
  [DEFINED]  OpeningHours- [IF]  OpeningHours- i_TimeSpan bInput! [THEN] ;
\    OpeningHours- i_TimeSpan bInput! ;

: set-override ( - )
   i_Automatic  i_Override   invert-dest-input  ;

: eval-ch-net ( - output-ch-net ) \ Updates all relations and evaluate the network.
   set-override add_inputs            \ Flag Output  To destination
    [ autom-mp all-bits ] literal autom-mp match-mp  i_autom bInput!
    [ gui-mp   all-bits ] literal gui-mp   match-mp  i_gui   bInput!
    out-mp any-mp ;

: .eval-ch-net   ( - )
   eval-ch-net drop               \ Update all relations and evaluate the network.
   cr .line-- space .time         \ Output for each mp:
   cr ." Automation " [ autom-mp all-bits ] literal autom-mp .match-mp
   cr ." Gui " [ gui-mp all-bits ] literal gui-mp .match-mp
   cr ." Out " out-mp .any-mp ;

   init-ch-net

0 [if] \ Simulation
    i_TimeSpan   bInputOn
    i_Present    bInputOn
    i_Automatic  bInputOn  .eval-ch-net
 quit

    i_Automatic  bInputOff .eval-ch-net  \ Ignore the job
    i_Mode       bInputOn  .eval-ch-net
    i_Automatic  bInputOn  .eval-ch-net  \ Use the job

  eval-ch-net .

abort
[then]

\s

