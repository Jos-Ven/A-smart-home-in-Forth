marker schedule_daily.fs  .latest \ Actions at a planned time.

needs Common-extensions.f
needs Sun.f
needs table_sort.f
needs schedule-tool.fs


also html

6  value RenewLogDay        \ 6=Saturday
27 value RestartServerDay   \ On the 27th

: LogToday ( - )
    s" *** " upad place (date) +upad  s"  *** " +upad" +log ;

: Good-morning ( - )
    log" Good morning " LogToday  &last-line-packet$ count write-log-line
          [DEFINED]  ControlWindow   [IF]  0 to #changes [THEN]
    FreeMem" write-log-line
     ;

: Reset-logging-saturday ( - )
   date-now jd week-day RenewLogDay =
      if    close-log-file  logFile" start-logfile
      then  ;

: Reset-webserver_27th ( - )
    date-now 2drop RestartServerDay =
    if   RestartGforth  tid-http-server kill then    ;

: Rebuild-arptable ( - )  ClearArpTable  true to RebuildArpTable-  ;
: send-time-sync   ( - )  SendTCPTimesyncToAll ;

here dup to &options-table \ Options used by run-schedule
\                        Map: xt      cnt adr-string
   ' Good-morning            dup , >name$ , , \ Executed when the schedule is empty
   ' Reset-logging-saturday  dup , >name$ , ,
   ' Rebuild-arptable        dup , >name$ , ,
   ' Reset-webserver_27th    dup , >name$ , ,
   ' Reset-sleep             dup , >name$ , ,
   ' send-time-sync          dup , >name$ , ,

here swap - /option-record / to #option-records
create file-schedule-daily ," schedule-daily.dat"

: Schedule-page  ( - )
   start-html-page
   [ifdef]  SitesIndex  SitesIndex [then]
   s" /home"    s" home"      <<TopLink>>
   +TimeDate/legend
   ['] add-options-dropdown html-schedule-list  ;


TCP/IP DEFINITIONS

' noop alias /NewPage

: /Schedule  ( - )  ['] Schedule-page set-page ;
: /Scheduled  ( - ) clr-req-buf ['] Schedule-page set-page ;

: SetEntrySchedule  ( id hh mm #DropDown - )
   SetEntry-schedule   /Schedule ;

: AddEntrySchedule ( - ) AddEntry-schedule /Schedule ;


FORTH DEFINITIONS


file-schedule-daily init-schedule start-schedule


previous
\s
