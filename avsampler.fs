Marker avsampler.fs  .latest  \ To collect samples from sensors and to calculate the avarage for a few samples.

10 value #samples     0 value >sample     0 value full

: incr-sample  ( - )
   1 >sample + dup #samples >=
     if   drop 0  true to full
     then to >sample ;

: sample!     ( f: ValueSample - ) ( &Samples - ) >sample  floats + f! ;

: EraseSamples ( &Samples - )
   #samples  0
      do   dup 0e i floats + f!
      loop drop ;

: Samples:     ( - ) create here #samples floats allot EraseSamples ;

: .samples     ( &Samples - )
   #samples 0
      do    cr i . dup i floats + f@ f.
      loop  drop ;

: AverageSamples ( &Samples - ) ( f: - AverageSamples )
   0e #samples 0
      do   dup i floats + f@ f+
      loop
   drop full
      if    #samples
      else  >sample  1 max
      then  s>f f/ ;

[undefined] /DataParms [if]

\in-system-ok begin-structure /DataParms  \ For additional information about the various fields for an SVG-plot
   field: >CfaDataLine      \ CFA of a pointer to a field in the first record in the logfile
   field: >CfaLastDataPoint \ CFA that gets the last data point in a plot.
  xfield: >FirstEntry
  xfield: >LastEntry
  xfield: >MinStat
  xfield: >MaxStat
  xfield: >AverageStat
  xfield: >Compression
   field: >Color
end-structure

: DataItem: ( <name> -- )  \ Define an inline record for additional information.
\in-system-ok   /DataParms dup here swap allot dup value swap erase ;

[then]

\\\ EG:
Samples: testsamples

: Testsamples! ( - )
   205 0
     do  i s>f testsamples sample! incr-sample
     loop ;

Testsamples! testsamples .samples
cr testsamples AverageSamples f.
