Marker mq135.fs .latest \ Returns the air quality related to clean air.
                        \ Adapt rClean to your local situation.

needs mcp3008.fs

1    constant ChMq135   \ Channel# on which the MQ135 is connected to the ADC.
                        \ The first channel starts at 0.

111e fconstant rClean \ Minimal raw value seen in 'clean' air on the current pcb

: Mq135Raw@   ( - rawValue )     spiMcp3008 ChMq135 Adc@ ;
: Mq/rClean ( raw - ) ( f: - pollution ) s>f rClean f/ 1e fmax ;
: Mq135f@   ( f: - RelativeValue )  Mq135Raw@ Mq/rClean ;

CheckSPI
   [IF]   fdSpi 0=
            [IF] initMcp3008
            [THEN]
          cr cr .( MQ135: )
          cr Mq135Raw@ .(  Raw: ) . Mq135f@ .( RelativeValue: ) f.
          cr
   [ELSE] cr .( The SPI interface is NOT active! ) cr
   [THEN]
\\\
