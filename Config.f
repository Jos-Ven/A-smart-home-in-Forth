needs table_sort.f

0 value /ConfigDef        \ Keeps how big the size of the config file should be.

create ConfigFile$   maxcounted allot   s" Config.dat" ConfigFile$ place


S" win32forth" ENVIRONMENT? [IF] DROP
needs Common-extensions.f

map-handle config-mhndl


: map-config-file     ( - )             ConfigFile$ count config-mhndl  open-map-file throw ;
: map-hndl>vadr       ( m_hndl - vadr ) >hfileAddress @ ;
: vadr-config         ( - vadr-config ) config-mhndl map-hndl>vadr ;
: DisableConfigFile   ( - )
    config-mhndl dup flush-view-file drop close-map-file drop ;

[THEN]


S" gforth" ENVIRONMENT? [IF] 2drop

2variable config-ghndl  \  vadr size

: map-config-file     ( - )             ConfigFile$ count  r/w map-file config-ghndl 2!  ;
: map-hndl>vadr       ( m_hndl - vadr ) cell+ @ ;
: vadr-config         ( - vadr-config ) config-ghndl map-hndl>vadr ;
: DisableConfigFile   ( - )             config-ghndl 2@ 2dup MS_SYNC msync drop  unmap ;

[THEN]

marker Config.f    .latest \ For saving data, variables and strings in a file.

: file-exist?         ( adr len -- true-if-file-exist )  file-status nip 0= ;
: file-size>s         ( fileid -- len )       file-size drop d>s  ;

: CreateConfigFile  ( - )
   /ConfigDef
   ConfigFile$ count r/w bin create-file abort" Can't create configuration file"
   extend-file
;

: check-config   ( -- ) \ creates a config-file with the right size.
   ConfigFile$ count file-exist?
     if    ConfigFile$ count r/w bin open-file  abort" Can't open the cofiguration file"
           /ConfigDef over file-size>s   2dup >   \ Extend it when it is needed.
                if    - swap extend-file          \ Keep the extisting data.
                else  2drop CloseFile             \ Do nothing when it is right.
                then
     else  CreateConfigFile
     then
  ;

: AllotConfigDef        ( size - )  /ConfigDef dup , + to /ConfigDef ;
: OffsetInConfigDef     ( adr - )   @ vadr-config + ;

\ A ConfigVariable directly acceses the config file.
\ They only work when the config file is mapped.

: ConfigVariable               \ Allocates variables in a configuration file
  create cell AllotConfigDef   \ Compiletime: ( -< name >- )
  does>  OffsetInConfigDef     \ Runtime: ( - AdrInMappedConfigFile )
 ;

: Config$:                         \ Allocates strings in a configuration file
  create maxcounted AllotConfigDef  \ Compiletime: ( -< name >- )
  does>  OffsetInConfigDef         \ Runtime: ( - AdrInMappedConfigFile )
 ;

: DataArea:                     \ Allocates a data area in a configuration file
  create AllotConfigDef         \ Compiletime: ( size -< name >- )
  does>  OffsetInConfigDef      \ Runtime: ( - AdrInMappedConfigFile )
 ;

: EnableConfigFile ( - )  check-config  map-config-file ;

\s Disable this line to see it's use:

\ Define ConfigVariables to access the mapped file.

ConfigVariable LBs/Inches-
ConfigVariable SingCutoff-
Config$: DataFile$
ConfigVariable ShowObese-
8 DataArea: Test

EnableConfigFile \ Make sure there is a config file with the right size and map it

1 LBs/Inches- !
2 SingCutoff- !

s" c:\appl\test.dat" DataFile$  place

3 ShowObese- !
-1 Test !

DisableConfigFile   \ When you are ready.



EnableConfigFile   \ To use the config file again.

cr .( The saved values are: ) LBs/Inches- ?  SingCutoff- ?  ShowObese- ?
cr .( The name of the DataFile$ in the config file is: ) DataFile$ count type
vadr-config /ConfigDef dump

DisableConfigFile   \ When you are ready.
\s
