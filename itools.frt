0 [IF]

Change Notes
============
20070430 MHX001 Copied SFP's framework from benchmrk.fth

Introduction
============
This is an attempt to define socket utilities that can run
on a large number of Forth systems.

[THEN]

DECIMAL


\ ************************************************
\ Select system to be tested, set FORTHSYSTEM
\ to value of selected target.
\ Set SPECIFICS false to avoid system dependencies.
\ Set SPECIFICS true to show off implementation tricks.
\ Set HACKING false to use the base source code.
\ Set HACKING true to optimise the source code.
\ ************************************************

1  CONSTANT VfxForth3		\ MPE VFX Forth v3.x
3  CONSTANT SwiftForth20	\ FI SwiftForth 2.0
5  CONSTANT Win32Forth		\ Win32Forth 4.2
9  CONSTANT iForth20		\ iForth 2.0 8 June 2002
11 CONSTANT gforth-fast		\ gforth-fast 0.6.2
12 CONSTANT iForth64		\ iForth 64-bit for Linux

\    VfxForth3	\ select system to test
\ SwiftForth20
  S" IFORTH64"   ENVIRONMENT? [IF] DROP  iForth64     [THEN] ( -1 -- )
  S" win32forth" ENVIRONMENT? [IF] DROP  Win32Forth   [THEN] ( -1 -- )
  S" iforth"     ENVIRONMENT? [IF] DROP  iForth20     [THEN] ( -1 -- )
  S" gforth"     ENVIRONMENT? [IF] 2DROP gforth-fast  [THEN] ( addr u ) \ version string, e.g. "0.6.2"
CONSTANT ForthSystem


  0 CONSTANT specifics		\ true to use system dependent code
  0 CONSTANT hacking		\ true to use "guru" level code that
				\ makes assumptions of an optimising compiler.
 -1 CONSTANT ANSSystem		\ Some Forth 83 systems cannot compile
				\ all code without carnal knowledge,
				\ especially if the compiler
				\ checks control structures.

: .specifics	\ -- ; display trick state
  ."  using"  specifics 0=
  IF  ."  no"  THEN
  ."  extensions"
;

: .hacking	\ -- ; display hack state
  ."  using"  hacking 0=
  IF  ."  no"  THEN
  ."  hackery"
;

: .testcond	\ -- ; display test conditions
  .specifics ."  and" .hacking
;


\ *****************************
\ VFX Forth for Windows harness
\ *****************************

VfxForth3 ForthSystem = [IF]

[defined] +idata [if]
  +idata			\ turn on P4 optimisations
  variable zzz			\ trigger IDATA allocation
[then]

((
: COUNTER 	\ -- ms
  GetTickCount ;
))

[undefined] m*/ [if]
[-sin
: m*/		\ d1 n2 +n3 -- dquot
\ *G The result dquot=(d1*n2)/n3. The intermediate value d1*n2
\ ** is triple-precision. In an ANS Forth standard program n3
\ ** can only be a positive signed number and a negative value
\ ** for n3 generates an ambiguous condition, which may cause
\ ** an error on some implementations.
    >r					\ -- d1 n2 ; R: -- n3
    s>d >r abs				\ -- d1 |n2| ; R: -- n3 sign(n2)
    -rot				\ -- |n2| d1 ; R: -- n3 sign(n2)
    s>d r> xor				\ -- |n2| d1 d1h*sign(n2) ; R: -- n3
    r> swap >r >r			\ -- |n2| d1 ; R: -- d1h*sign(n2) n3
    dabs rot				\ -- |d1| |n2| ; R: -- d1h*sign(n2) n3
    tuck um* 2swap um*			\ -- d1h*n2 d1l*n2 ; R: -- d1h*sign(n2) n3
    swap >r  0 d+ r> -rot		\ -- t ; R: -- d1h*sign(n2) n3
    r@ um/mod -rot r> um/mod nip swap
    r> IF dnegate THEN
;
sin]
[then]

Extern: BOOL PASCAL QueryPerformanceCounter( void * int64 );
Extern: BOOL PASCAL QueryPerformanceFrequency( void * int64 );

: Counter	\ -- ms
\ *G Return a ticker count in milliseconds.
\ *E seconds = count / freq
\ ** ms      = (count * 1000) / freq
\ *P Note that we assume that frequency can be expressed as
\ ** a positive 32 bit number.
  { | count[ 2 cells ] freq[ 2 cells ] -- ms }
  count[ QueryPerformanceCounter drop
  freq[ QueryPerformanceFrequency drop
  count[ 2@ swap			\ count
  #1000 freq[ @ m*/ drop		\ ms
;

[undefined] >pos [if]
: >pos          \ n -- ; step to position n
  out @ - spaces
;
[then]

: [o/n]		\ --
  postpone []
; immediate

: 0<= ( n -- bool ) 0> 0= ;
: MS@ ( -- ms ) GetTickcount ;

: ?FILE ( ior -- )
   DUP IF ." file error# " DUP U. . ABORT THEN DROP ;

: strlen ( addr -- count )
	0 SWAP 	BEGIN  COUNT
		WHILE  SWAP 1+ SWAP
		REPEAT
	DROP ;

: $PUT ( c-addr1 u1 c-addr2 -- ) SWAP CMOVE ;

: $+ 	( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 )
	LOCALS| u2 c-addr2 u1 c-addr1 |
	u1 u2 + ALLOCATE THROW
	c-addr1 u1  2 PICK       $PUT
	c-addr2 u2  2 PICK u1 +  $PUT
	u1 u2 + ;

CHAR [ CONSTANT '['
CHAR ] CONSTANT ']'
CHAR : CONSTANT ':'
CHAR ! CONSTANT '!'
CHAR O CONSTANT 'O'

0 CONSTANT U>D

\ socket interface

library: wsock32.dll
extern int PASCAL WSAStartup( WORD, void * );
extern int PASCAL WSAGetLastError( void );
extern HANDLE PASCAL socket( int, int, int );
extern int PASCAL connect( int, unsigned int, int);
extern int PASCAL closesocket( HANDLE );
extern LONG PASCAL htonl( LONG );
AliasedExtern: accept() int PASCAL accept( HANDLE, void *, unsigned int *);
extern int PASCAL listen( HANDLE, int );
extern int PASCAL ioctlsocket( HANDLE, unsigned int, void * );
extern int PASCAL recv( HANDLE, char *, int, int );
extern int PASCAL send( HANDLE, char *, int, int );
extern int PASCAL gethostbyname( char * );
extern int PASCAL gethostname( unsigned int, int );

CREATE sockaddr-tmp  sockaddr-tmp 4 CELLS DUP ALLOT ERASE  ( family+port, sin_addr, dpadding )

: host>addr ( addr u -- x )
    >R PAD R@ CMOVE  0 PAD R> + C!
    PAD gethostbyname DUP 0= ABORT" address not found"
    ( hostent) 3 CELLS + ( h_addr_list) @ @ @ ;

: OPEN-SERVICE ( c-addr u port -- handle )
    htonl PF_INET OR sockaddr-tmp !
    host>addr sockaddr-tmp CELL+ ( sin_addr) !
    PF_INET SOCK_STREAM IPPROTO_TCP socket
    DUP 0<= ABORT" no free socket" >R
    R@ sockaddr-tmp 16 connect 0< ABORT" can't connect"
    R> ;

        0 CONSTANT MSG_WAITALL
$8004667E CONSTANT FIONBIO
2000 VALUE SOCKET-TIMEOUT
CREATE CRLF 2 C, 13 C, 10 C,
CREATE hostname$ 256 CHARS ALLOT
CREATE on_off 0 ,

: errno ( -- #error ) WSAGetLastError ;

: BLOCKING-MODE ( socket flag -- )
	0= on_off !  FIONBIO on_off ioctlsocket
	SOCKET_ERROR = IF  CR ." BLOCKING-MODE :: error #" errno DUP .R THROW  ENDIF ;

: HOSTNAME ( -- c-addr u ) hostname$ COUNT ;
: SET-SOCKET-TIMEOUT ( u -- ) 200 + TO SOCKET-TIMEOUT ;
: GET-SOCKET-TIMEOUT ( -- u ) SOCKET-TIMEOUT 200 - ;
: WRITE-SOCKET ( c-addr size socket -- ) -ROT 0 send 0< THROW ;
: CLOSE-SOCKET ( socket -- ) closesocket DROP ;
: +CR  ( c-addr1 u1 -- c-addr2 u2 ) CRLF COUNT $+ ;

: (RS)  ( socket c-addr maxlen -- c-addr size )
	2 PICK >R R@ FALSE BLOCKING-MODE
	  OVER >R MSG_WAITALL recv 0 MAX ( -- size )
	  errno DUP 0<> SWAP WSAEWOULDBLOCK <> AND ABORT" (rs) :: socket read error"
	  R> SWAP
	R> TRUE BLOCKING-MODE ;

: READ-SOCKET ( socket c-addr maxlen tmax -- c-addr size )
	MS@ SOCKET-TIMEOUT + LOCALS| tmax maxlen c-addr socket |
	BEGIN
	   socket c-addr maxlen (RS) DUP 0=
	   MS@ tmax U< AND
	WHILE
  	   2DROP
	REPEAT ;

	$101 PAD WSAStartup [IF] CR .( Something wrong with winsock ) [THEN]

	PAD 1+ 255 gethostname DROP
	PAD 1+ strlen PAD C!
	PAD hostname$ PAD C@ 1+ CMOVE

[THEN]

\ ********************
\ SwiftForth20 harness
\ ********************

SwiftForth20 ForthSystem = [IF]
: >pos          \ n -- ; step to position n
  get-xy drop - spaces
;

: [o/n]		\ -- ; stop optimiser treating * DROP etc as no code
  postpone noop
; immediate

\ socket interface

: MS@ ( -- u ) counter ;

: 0<=  ( n -- bool ) 0> 0= ;

[UNDEFINED] ENDIF [IF] : ENDIF POSTPONE THEN ; IMMEDIATE [THEN]

: $PUT ( c-addr1 u1 c-addr2 -- ) SWAP CMOVE ;

: $+ 	( c-addr1 u1 c-addr2 u2 -- c-addr3 u3 )
	LOCALS| u2 c-addr2 u1 c-addr1 |
	u1 u2 + ALLOCATE THROW
	c-addr1 u1  2 PICK       $PUT
	c-addr2 u2  2 PICK u1 +  $PUT
	u1 u2 + ;

: strlen ( addr -- count )
	0 SWAP 	BEGIN  COUNT
		WHILE  SWAP 1+ SWAP
		REPEAT
	DROP ;

: ?FILE ( ior -- )
   DUP IF ." file error# " DUP U. . ABORT THEN DROP ;

: Split-At-Word  ( addr1 n1 addr2 n2 -- addr1 n3 addr1+n4 n1-n4 )
	DUP LOCALS| sz |
	2OVER 2SWAP SEARCH 0= IF  + 0 EXIT  ENDIF
	DUP >R   sz /STRING   ROT R> - -ROT ;

CHAR [ CONSTANT '['
CHAR ] CONSTANT ']'
CHAR : CONSTANT ':'
CHAR ! CONSTANT '!'
CHAR 0 CONSTANT '0'
CHAR O CONSTANT 'O'
CHAR P CONSTANT 'P'
CHAR = CONSTANT '='
CHAR + CONSTANT '+'
CHAR & CONSTANT '&'
CHAR % CONSTANT '%'

0 CONSTANT U>D

REQUIRES WINSOCK

CREATE sockaddr-tmp  sockaddr-tmp  16 CELLS DUP ALLOT ERASE  ( family+port, sin_addr, dpadding xpadding )
CREATE hostname$ 256 CHARS ALLOT
CREATE on_off  0 ,
CREATE alen   16 ,
CREATE CRLF 2 C, 13 C, 10 C,

        0 CONSTANT MSG_WAITALL
$8004667E CONSTANT FIONBIO
2000 VALUE SOCKET-TIMEOUT

: host>addr ( addr u -- x )
	PAD ZPLACE PAD gethostbyname DUP 0= ABORT" address not found"
	( hostent) 3 CELLS + ( h_addr_list) @ @ @ ;

: OPEN-SERVICE ( c-addr u port -- handle )
	sockaddr-tmp 4 CELLS ERASE
	htonl PF_INET OR sockaddr-tmp !
	host>addr sockaddr-tmp CELL+ ( sin_addr) !
	PF_INET SOCK_STREAM IPPROTO_TCP socket
	DUP 0<= ABORT" no free socket" >R
	R@ sockaddr-tmp 16 connect 0< ABORT" connect :: failed"
	R> ;

\ The new server listens for clients on the returned socket
: CREATE-SERVER  ( port# -- lsocket )
	sockaddr-tmp 4 CELLS ERASE
	htonl PF_INET OR sockaddr-tmp !
	PF_INET SOCK_STREAM 0 socket
	DUP 0< ABORT" no free socket" >R
    	R@ sockaddr-tmp 16 bind 0= IF  R> EXIT  ENDIF
	R> DROP TRUE ABORT" bind :: failed" ;

: errno ( -- #error ) WSAGetLastError ;
: HOSTNAME ( -- c-addr u ) hostname$ COUNT ;
: SET-SOCKET-TIMEOUT ( u -- ) TO SOCKET-TIMEOUT ;
: GET-SOCKET-TIMEOUT ( -- u ) SOCKET-TIMEOUT ;
: WRITE-SOCKET ( c-addr size socket -- ) -ROT 0 send 0< THROW ;
: CLOSE-SOCKET ( socket -- ) closesocket DROP ;
: +CR  ( c-addr1 u1 -- c-addr2 u2 ) CRLF COUNT $+ ;

\ /queue is the maximum number of clients that will be put on hold
\ After LISTEN the server is ready to serve clients
: LISTEN ( lsocket /queue -- )
	listen 0< ABORT" listen :: failed" ;

\ This call blocks the server until a client appears. The client uses socket to
\ converse with the server.
: ACCEPT-SOCKET ( lsocket -- socket )
	16 alen !
	sockaddr-tmp alen accept()
	DUP 0< IF  errno CR ." accept() :: error #" .
		   ABORT" accept :: failed"
	    ENDIF ;

: BLOCKING-MODE ( socket flag -- )
	0= on_off !  FIONBIO on_off ioctlsocket
	SOCKET_ERROR = ABORT" ioctlsocket :: failed" ;

: (RS)  ( socket c-addr maxlen -- c-addr size )
	2 PICK >R R@ FALSE BLOCKING-MODE
	  OVER >R MSG_WAITALL recv 0 MAX ( -- size )
	  errno DUP 0<> SWAP WSAEWOULDBLOCK <> AND ABORT" (rs) :: socket read error"
	  R> SWAP
	R> TRUE BLOCKING-MODE ;

: READ-SOCKET ( socket c-addr maxlen tmax -- c-addr size )
	MS@ SOCKET-TIMEOUT + LOCALS| tmax maxlen c-addr socket |
	BEGIN
	   socket c-addr maxlen (RS) DUP 0=
	   MS@ tmax U< AND
	WHILE
  	   2DROP
	REPEAT ;

	$101 PAD WSAStartup [IF] CR .( Something wrong with winsock ) [THEN]

	PAD 1+ 255 gethostname DROP
	PAD 1+ strlen PAD C!
	PAD hostname$ PAD C@ 1+ CMOVE

[THEN]

\ ******************
\ Win32Forth harness
\ ******************

Win32Forth ForthSystem = [IF]

: COUNTER 	\ -- ms
  Call GetTickCount ;

: >pos          \ n -- ; step to position n
  getxy drop - spaces
;

: M/            \ d n1 -- quot
  fm/mod nip
;

: buffer:	\ n -- ; -- addr
  create
    here  over allot  swap erase
;

: 2-		\ n -- n-2
  2 -
;

: [o/n]		\ -- ; stop optimiser treating * DROP etc as no code
; immediate

: SendMessage	\ h m w l -- res
  swap 2swap swap		\ Win32Forth uses reverse order
  Call SendMessage
;

: GetTickCount	\ -- ms
  Call GetTickCount
;

: 0<= 0> 0= ; ( n -- bool )

: ?FILE	  DUP IF  ." file error# " DUP U. . ABORT  THEN DROP ; ( ior -- )

: $PUT ( c-addr1 u1 c-addr2 -- ) SWAP CMOVE ;

: $+ { c-addr1 u1 c-addr2 u2 -- c-addr3 u3 }
	u1 u2 + ALLOCATE THROW
	c-addr1 u1  2 PICK       $PUT
	c-addr2 u2  2 PICK u1 +  $PUT
	u1 u2 + ;

CHAR [ CONSTANT '['
CHAR ] CONSTANT ']'
CHAR : CONSTANT ':'
CHAR ! CONSTANT '!'
CHAR O CONSTANT 'O'

0 CONSTANT U>D

: strlen  ( addr -- count )
	0 SWAP
	BEGIN  COUNT
	WHILE  SWAP 1+ SWAP
	REPEAT DROP ;

\ socket interface

WinLibrary WS2_32.DLL

	1 PROC htonl 		( hostlong -- u_long )
	3 PROC socket 		( af, type, proto -- SOCKET )
	3 PROC connect 		( s, 'sock len -- int )
	1 PROC closesocket 	( s -- int )
	3 PROC ioctlsocket 	( s, cmd, *argp -- int )
	2 PROC listen 		( s, backlog -- int )
	4 PROC recv 		( s, *buf, len, flags -- int )
	4 PROC send 		( s, *buf, len, flags -- int )
	3 PROC gethostbyaddr 	( addr, len, type -- hostent )
	1 PROC gethostbyname 	( name -- hostent )
	2 PROC gethostname 	( name, namelen -- int )
	2 PROC WSAStartup 	( ver_req 'data -- int )
	0 PROC WSAGetLastError 	( -- int )

: socket	swap rot Call socket ;
: connect  	swap rot Call connect ;
: ioctlsocket	swap rot Call ioctlsocket ;
: listen	swap Call listen ;
: recv		swap 2swap swap Call recv ;
: send		swap 2swap swap Call send ;
: gethostbyaddr	swap rot Call gethostbyaddr ;
: gethostname	swap Call gethostname ;
: WSAStartup 	swap Call WSAStartup ;

CREATE sockaddr-tmp  sockaddr-tmp 4 CELLS DUP ALLOT ERASE  ( family+port, sin_addr, dpadding )

: host>addr ( addr u -- x )
    >R PAD R@ CMOVE  0 PAD R> + C!
    PAD gethostbyname DUP 0= ABORT" address not found"
    ( hostent) 3 CELLS + ( h_addr_list) @ @ @ ;

: OPEN-SERVICE ( c-addr u port -- handle )
    htonl PF_INET OR sockaddr-tmp !
    host>addr sockaddr-tmp CELL+ ( sin_addr) !
    PF_INET SOCK_STREAM IPPROTO_TCP socket
    DUP 0<= ABORT" no free socket" >R
    R@ sockaddr-tmp 16 connect 0< ABORT" can't connect"
    R> ;

        0 CONSTANT MSG_WAITALL
$8004667E CONSTANT FIONBIO
2000 VALUE SOCKET-TIMEOUT
CREATE CRLF 2 C, 13 C, 10 C,
CREATE hostname$ 256 CHARS ALLOT
CREATE on_off 0 ,

: errno ( -- #error ) WSAGetLastError ;

: BLOCKING-MODE ( socket flag -- )
	0= on_off !  FIONBIO on_off ioctlsocket
	SOCKET_ERROR = IF  CR ." BLOCKING-MODE :: error #" errno DUP .R THROW  ENDIF ;

: HOSTNAME ( -- c-addr u ) hostname$ COUNT ;
: SET-SOCKET-TIMEOUT ( u -- ) TO SOCKET-TIMEOUT ;
: GET-SOCKET-TIMEOUT ( -- u ) SOCKET-TIMEOUT ;
: WRITE-SOCKET ( c-addr size socket -- ) -ROT 0 send 0< THROW ;
: CLOSE-SOCKET ( socket -- ) closesocket DROP ;
: +CR  ( c-addr1 u1 -- c-addr2 u2 ) CRLF COUNT $+ ;

: (RS)  ( socket c-addr maxlen -- c-addr size )
	2 PICK >R R@ FALSE BLOCKING-MODE
	  OVER >R MSG_WAITALL recv 0 MAX ( -- size )
	  errno DUP 0<> SWAP WSAEWOULDBLOCK <> AND ABORT" (rs) :: socket read error"
	  R> SWAP
	R> TRUE BLOCKING-MODE ;

: READ-SOCKET ( socket c-addr maxlen tmax -- c-addr size )
	MS@ SOCKET-TIMEOUT + LOCALS| tmax maxlen c-addr socket |
	BEGIN
	   socket c-addr maxlen (RS) DUP 0=
	   MS@ tmax U< AND
	WHILE
  	   2DROP
	REPEAT ;

	$101 PAD WSAStartup [IF] CR .( Something wrong with winsock ) [THEN]

	PAD 1+ 255 gethostname DROP
	PAD 1+ strlen PAD C!
	PAD hostname$ PAD C@ 1+ CMOVE

[THEN]


\ ******************
\ iForth 2.x harness
\ ******************

iForth20 ForthSystem = [IF]

: counter ( -- ms ) ?MS ;

1 CELLS constant CELL
   0    constant HWND_DESKTOP
   16   constant WM_CLOSE

: >pos          \ n -- ; step to position n
  ?AT NIP AT-XY ;

: buffer:	\ n -- ; -- addr
  CREATE HERE  OVER ALLOT  SWAP ERASE
  DOES> ;

\ CARRAY  creates a byte size array.
: CARRAY
  CREATE  ALLOT ( n -- )
  DOES>   + ( n -- a ) ;

\ ARRAY  creates a word size array.
: ARRAY
  CREATE  CELLS ALLOT ( n -- )
  DOES>   []CELL ;    ( n -- a )

: [o/n]	;			\ -- ; stop optimiser treating * DROP etc as no code
: SendMessage	3DROP ;  	\ h m w l -- res
: u2/		1 RSHIFT ; 	\ u -- u'

	[DEFINED] NEEDS 0= [IF]  CR .( Trying to make  NEEDS  available ...)
				 S" iforth.prf" INCLUDED
			 [THEN]

	NEEDS -sockets

: strlen ( addr -- count )
	0 SWAP 	BEGIN  COUNT
		WHILE  SWAP 1+ SWAP
		REPEAT
	DROP ;

: PLACE ( c-addr u addr -- ) PACK DROP ;

: MS@ ( -- u ) ?MS ;

[THEN]


\ **************
\ gforth harness
\ **************

gforth-fast ForthSystem = [IF]

variable out	\ -- addr

: temit		\ -- char
  1 out +!  (emit)
; ' temit is emit

: ttype		\ addr len --
  dup out +!  (type)
; ' ttype is type

: cr		\ --
  cr  out off
;

: >pos          \ n -- ; step to position n
  out @ - spaces
;

decimal

: counter	\ -- ms
  utime 1000 um/mod nip
;

: MS@  counter ; ( -- u )

create pocket 256 allot

: c"		\ -- [comp] ; -- addr [interp]
  state @ if
    postpone c"
  else
    [char] " parse   pocket place  pocket
  endif
; immediate

: [o/n] ; IMMEDIATE

: M/            \ d n1 -- quot
  sm/rem nip
;

: buffer:	\ n -- ; -- addr
  create
    here  over allot  swap erase
;

: 2-		\ n -- n-2
  s" 2 -" evaluate
; immediate

: u2/		\ u -- u'
  s" 1 RSHIFT" evaluate
; immediate

: not		\ x -- x'
  s" invert" evaluate
; immediate

0 constant HWND_DESKTOP
16 constant WM_CLOSE

: SendMessage	\ h m w l -- flag
  2drop 2drop  0
;

: ?FILE	  DUP IF  ." file error# " DUP U. . ABORT  THEN DROP ; 		( ior -- )

: $PUT ( c-addr1 u1 c-addr2 -- ) SWAP CMOVE ;

: $+ { c-addr1 u1 c-addr2 u2 -- c-addr3 u3 }
	u1 u2 + ALLOCATE THROW
	c-addr1 u1  2 PICK       $PUT
	c-addr2 u2  2 PICK u1 +  $PUT
	u1 u2 + ;

CHAR [ CONSTANT '['
CHAR ] CONSTANT ']'
CHAR : CONSTANT ':'
CHAR ! CONSTANT '!'
CHAR O CONSTANT 'O'

0 CONSTANT U>D

: strlen  ( addr -- count )
	0 SWAP
	BEGIN  COUNT
	WHILE  SWAP 1+ SWAP
	REPEAT DROP ;

S" unix/socket.fs" INCLUDED

: open-socket ( addr u port -- fid )
    htonl PF_INET [ base c@ 0= ] [IF] $10 lshift [THEN]
    or sockaddr-tmp family+port !
    host>addr sockaddr-tmp sin_addr !
    PF_INET SOCK_STREAM IPPROTO_TCP socket
    dup 0<= abort" no free socket" >r
    r@ sockaddr-tmp $10 connect 0< abort" can't connect"
    r> ;

   4 CONSTANT F_SETFL
  11 CONSTANT EWOULDBLOCK
$100 CONSTANT MSG_WAITALL
$802 CONSTANT O_NONBLOCK|O_RDWR
2000 VALUE    SOCKET-TIMEOUT
CREATE hostname$ 256 CHARS ALLOT

0 (int) libc 'errno      __errno_location ( -- addr )
1 (int) libc closesocket close            ( socket -- ior )
4 (int) libc send        send             ( socket buffer count flags -- size )
4 (int) libc recv        recv             ( socket buffer count flags -- size )
3 (int) libc fcntl 	 fcntl 		  ( fd n1 n2 -- ior )
2 (int) libc gethostname gethostname 	  ( c-addr u -- ior )

CREATE CRLF 2 C, 13 C, 10 C,

: +CR  ( c-addr1 u1 -- c-addr2 u2 ) CRLF COUNT $+ ;

: BLOCKING-MODE ( socket flag -- )
	F_SETFL SWAP IF  0
		   ELSE  O_NONBLOCK|O_RDWR
		   THEN
	fcntl 0< ABORT" blocking-mode failed" ;

: errno ( -- #error ) 'errno @ ;
: HOSTNAME ( -- c-addr u ) hostname$ COUNT ;
: OPEN-SERVICE ( c-addr u port# -- socket ) open-socket ;
: SET-SOCKET-TIMEOUT ( u -- ) 200 + TO SOCKET-TIMEOUT ;
: GET-SOCKET-TIMEOUT ( -- u ) SOCKET-TIMEOUT 200 - ;
: WRITE-SOCKET ( c-addr size socket -- ) -ROT 0 send 0< THROW ;
: CLOSE-SOCKET ( socket -- ) closesocket DROP ;

: (RS)  ( socket c-addr maxlen -- c-addr size )
	2 PICK >R R@ FALSE BLOCKING-MODE
	  OVER >R MSG_WAITALL recv 0 MAX ( -- size )
	  errno DUP 0<> SWAP EWOULDBLOCK <> AND ABORT" (rs) :: socket read error"
	  R> SWAP
	R> TRUE BLOCKING-MODE ;

: READ-SOCKET ( -- c-addr u )
	MS@ SOCKET-TIMEOUT + { socket c-addr maxlen tmax -- c-addr size }
	BEGIN
	   socket c-addr maxlen (RS) DUP 0=
	   MS@ tmax U< AND
	WHILE
  	   2DROP
	REPEAT ;

	PAD 1+ 255 gethostname DROP
	PAD 1+ strlen PAD C!
	PAD hostname$ PAD C@ 1+ CMOVE

[THEN]

\ ****************
\ iForth64 harness
\ ****************

iForth64 ForthSystem = [IF]

   0    CONSTANT HWND_DESKTOP
   1    CONSTANT WM_CLOSE

: COUNTER ( -- ms )
  ?MS ;

: >pos ( n -- ) \ step to position n
  ?AT NIP AT-XY ;

: buffer:  ( n -- )
  CREATE HERE  OVER ALLOT  SWAP ERASE
  DOES>   ( -- addr ) ; ' LIT, IS-IDOES !

-- CARRAY  creates a byte size array.
: CARRAY
  CREATE  ALLOT ( n -- )
  DOES>	  + ;   ( n -- a )  :NONAME LIT, POSTPONE + ; IS-IDOES CARRAY

-- ARRAY  creates a word size array.
: ARRAY
  CREATE  CELLS ALLOT ( n -- )
  DOES>	  []CELL ;    ( n -- a )  :NONAME LIT, POSTPONE []CELL ; IS-IDOES ARRAY

-- stop optimiser treating * DROP etc as no code
: [o/n]	( -- )
; IMMEDIATE

: SendMessage ( h m w l -- res )
  DROP 2DROP ;

INCLUDE sockets.frt

: strlen ( addr -- count )
	0 SWAP 	BEGIN  COUNT
		WHILE  SWAP 1+ SWAP
		REPEAT
	DROP ;

: MS@ ( -- u ) ?MS ;

: Split-At-Word  ( addr1 n1 addr2 n2 -- addr1 n3 addr1+n4 n1-n4 )
	DUP LOCALS| sz |
	2OVER 2SWAP SEARCH 0= IF  + 0 EXIT  ENDIF
	DUP >R   sz /STRING   ROT R> - -ROT ;

[THEN]

\ -- Some tests -----------------------------------------------------------------------------------------------------------

: .QUOTE ( -- )
	HOSTNAME 17 OPEN-SERVICE ( -- socket )
	DUP PAD 2000 READ-SOCKET CR TYPE
	CLOSE-SOCKET ;

: .TIME-OF-DAY ( -- )
	HOSTNAME 13 OPEN-SERVICE ( -- socket )
	DUP PAD 200 READ-SOCKET CR TYPE
	CLOSE-SOCKET ;

\ *** General utilities ***************************************************************************************************

: (TIMESTAMP) ( -- )
	BASE @ >R DECIMAL
	TIME&DATE DROP DROP DROP
	U>D <# # #          #> TYPE
	U>D <# # # ':' HOLD #> TYPE
	U>D <# # # ':' HOLD #> TYPE
	R> BASE ! ;

: .`	[CHAR] ` PARSE POSTPONE SLITERAL POSTPONE TYPE ; IMMEDIATE 	( -- `text` )

\ *** EOF *****************************************************************************************************************
