needs webcontrols.f  bl emit .latest .(  12-07-2023 )      \ by J.v.d.Ven.
needs table_sort.f

marker FileLister.f  .latest


0 value hFilenames
: FileNameList ( - adr cnt ) s" ForthFileList.tmp" ;

0 value &FileList-table

: init-FileList-table
   /table init-table  to &FileList-table
\   0 &FileList-table >#records !
   36 cells &FileList-table >record-size ! ;

init-FileList-table

0 value fcounter

: AddFilename ( adr cnt - )
   1 +to fcounter
   upad &FileList-table >record-size @ 1+ bl fill   s" N" upad place    upad +place crlf" upad +place
   upad 1+ &FileList-table >record-size @ hFilenames write-file  drop ;


s" gforth" ENVIRONMENT? [IF] 2drop

s" Documents/MachineSettings.fs" file-status nip 0= [if]
            needs Documents/MachineSettings.fs    \ Optional to override settings
            [THEN]


[defined]  AdminPage  [IF] needs Master.fs  [ELSE] needs slave.fs  [THEN] \ Includes the webserver-light


: .file-name ( filename cnt - )  cr 1 +to fcounter fcounter . space type ;

: traverse-matched-dir-files ( addrdir u1 addrmatch u2 xt -- )
    0 { d: match xt w^ buf } open-dir throw { handle }
    [ $100 6 cells - ]L buf $!len
     0 to fcounter
    BEGIN  buf handle try-read-dir  WHILE
	   buf $@ drop swap 2dup match filename-match
	    IF    xt execute
            ELSE  2drop
            THEN  REPEAT
   drop buf $free  handle close-dir throw ;

\  upad $300 get-dir s" *.f*" ' .file-name  cr traverse-matched-dir2


: write-sorted-list
   FileNameList r/w create-file
       if    drop cr ." Can't create file list with sorted files."
       else  to hFilenames   &FileList-table >#records @ 0
                  do   i  &FileList-table nt>record  &FileList-table >record-size @
                       hFilenames write-file  drop
                  loop
       then
    hFilenames dup  flush-file  drop CloseFile ;

2variable Fhndl

: UnMapFileNames ( - )   Fhndl 2@ 2dup MS_SYNC msync drop unmap ;

: MapFileNames   ( file$ cnt - vadr size )
   2dup r/w open-file drop   dup>r file-size drop d>s 0=
     if  upad &FileList-table >record-size @ 1+ bl fill
         s"  None " upad place
         upad 1+ &FileList-table >record-size @ r@ write-file drop
     then
   r> CloseFile
   r/w map-file 2dup Fhndl 2!  ;

1 &FileList-table >record-size @ key: FileNames  FileNames  Ascending $sort

: sort-dir-file ( filename$ cnt - )
   MapFileNames swap &FileList-table !
   &FileList-table >record-size @ / dup
   &FileList-table >#records ! allocate-ptrs
   dup &FileList-table >table-aptrs !
   &FileList-table >record-size @ &FileList-table >#records @ build-ptrs
   by[ FileNames ]by  &FileList-table table-sort

   write-sorted-list  &FileList-table >table-aptrs @ free throw
   UnMapFileNames ;

: AddNone ( hndl - )
         upad  &FileList-table >record-size @ bl fill
         s"  None" upad place crlf$ count upad +place
         upad &FileList-table >record-size @
         rot write-file drop ;

: ListFiles  ( filter$ cnt - )
   0 to fcounter
   2>r s" ForthFileListUnsorted.tmp" 2dup r/w create-file
       if    drop cr ." Can't create file list for " 2r> type  ." files."
       else  to hFilenames upad 300 get-dir   2r>
             ['] AddFilename traverse-matched-dir-files
       then
   fcounter 0=
       if  hFilenames AddNone
       then
   hFilenames  dup  flush-file  drop CloseFile sort-dir-file ;

[THEN]


S" win32forth" ENVIRONMENT? [IF] DROP

: .dir->file-list-name ( --  )
        _win32-find-data 11 cells+              \ adrz
        zcount                                  \ adrz scan-len slen
        AddFilename                             \ adrz len  ;print file name
        2drop ;

\ s" *.f*" ' .dir->file-list-name  ForAllFileNames

map-handle Fhndl

: UnMapFileNames ( - )
   Fhndl >hfilelength @
     if   Fhndl close-map-file drop
     then ;

: MapFileNames   ( file$ cnt - vadr size )
   2dup r/o open-file over file-size drop d>s 0>
    if    drop CloseFile
          Fhndl open-map-file abort" can't map file."
          Fhndl >hfileAddress @
          Fhndl >hfilelength  @
    else  4drop 0 dup dup Fhndl >hfilelength !
    then ;

\ Map ListFiles: selected-YN-char Filename-32-chars
: ListFiles  ( filter$ cnt -- )
    2>r FileNameList r/w create-file
      if     drop cr ." Can't create file list for " 2r> type  ." files."
      else   to hFilenames 2r> ['] .dir->file-list-name  ForAllFileNames
      then
    hFilenames dup  flush-file  drop CloseFile ;

[THEN]



FileNameList file-status nip  [IF] s" *.f*" ListFiles [THEN]

create selected-file$ 40 allot  s" none"  selected-file$ lplace

HTML DEFINITIONS


: (AddFileOptions)  ( n - )
    0
        ?do  dup i &FileList-table >record-size @ * + dup 1+ dup
             &FileList-table >record-size @ 0x0d scan drop
             over -  rot  c@ [char] Y = dup
                 if  -rot 2dup selected-file$ lplace rot
                 then
             i swap <option>
        loop
      UnMapFileNames drop ;


: AddFileOptions  ( - )
   FileNameList 2dup file-exist? not
     if  2dup FileNameList r/w create-file drop CloseFile
     then
   MapFileNames dup 0>
     if    &FileList-table >record-size @ /  (AddFileOptions)
     else  drop s" None" 2dup selected-file$ lplace 0 0 <option> drop
     then ;


: ClearSelection ( vadr n - )
   &FileList-table >record-size @ / 0
      ?do   [char] N  over c! &FileList-table >record-size @ +
      loop
   drop ;

: SetSelectedFile ( n - )
   &FileList-table >record-size @ *  FileNameList MapFileNames dup 0>
      if   2dup ClearSelection drop +
           [char] Y swap c! UnMapFileNames
      else 3drop
      then ;

\s EG:

: SelectFIle  ( - )
   <tdLTop> <fieldset>  s" File selector " <<legend>> 10 125 1 4 0 <tablePx> <form>
         <tr><tdL> s" File: "  +HtmlNoWrap                                 </td>
             <td>  s" SelectedFile" 1 <SELECT  AddFileOptions </SELECT>    </td>
             <td>  ButtonWhite Black s" < UpdateList"   nn" <StyledButton> </td></tr>
      <tr> 3 <#tdR> ButtonWhite Black s" Select file"   nn" <StyledButton> </td></tr>

         <tr><td>  s" Last selected: " +HtmlNoWrap      </td>
             <td> selected-file$ lcount +html           </td></tr> \ Shows the selected file
   </form> </table> </td> </fieldset> ;

: home-page ( - )
     htmlpage$ off  s" Site " NearWhite 0 <HtmlLayout>  SelectFIle  <EndHtmlLayout>  ;

: NewListFiles ( - )
     s" *.f*" ListFiles  0 SetSelectedFile  home-page ;


TCP/IP DEFINITIONS ALSO HTML

: /home          ( - ) NewListFiles home-page ;
: %3C+UpdateList ( - ) NewListFiles ;

: SelectedFile	 ( <fileNo> - ) parse-name  s>number d>s SetSelectedFile  ;
: Select+file    ( --  ) home-page ;

PREVIOUS FORTH DEFINITIONS

\ ---- Starting the application in the webserver ------------------------------------------------

S" win32forth" ENVIRONMENT? [IF] DROP


\ ---- Start server configuration ---------------------------------------------------------------
\ --- Servertypes:

\ Section for allocating servers only.
\ Group the servers by it's manufacturer and model.

Servers[                 \ Starting adres for allotting servers.
#servers to ServerHost   ' open-#Webserver  GetIpHost$  HtmlPort  hostname$ count add-server
]Servers

.servers                 \ In this case only one server at port 8080

\ ---- End server configuration -----------------------------------------------------------------


\ The web server locks the console in Win32Forth.
\ That can be prevented by running it in a separate thread.

cls   .( Web server at: ) SetHomeLink homelink$ count type cr
start-servers \quit \ Start the webserver in a task in the background and stop compiling.

[THEN]


S" gforth" ENVIRONMENT? [IF] 2drop

start-servers

[THEN]


