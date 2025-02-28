Marker ldr.fs   .latest
needs mcp3008.fs

0 constant ChLdr    \ Channel# on which the LDR is connected to the ADC.

: LdrPos@   ( - rawValue )    spiMcp3008 ChLdr Adc@ ;
: LdrNeg@   ( - rawValue )    #StepsAdc f>s spiMcp3008 ChLdr Adc@ - ;

defer Ldr@  ' LdrPos@ is Ldr@
: Ldrf@% ( f: - %OfTotal ) Ldr@  Adc% ;

[defined] NegateLdr [IF] ' LdrNeg@ is Ldr@  [THEN]

\\\ EG:

fdSpi 0= [if] initMcp3008 [then]

cr .( Ldr: )  Ldrf@% f. abort

\ Output:  Ldr: 81.13
\\\
