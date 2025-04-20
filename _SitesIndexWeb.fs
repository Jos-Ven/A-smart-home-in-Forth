s" favicon.ico" file-status nip 0<> [if] cr
cr .( favicon.ico not found.)
cr .( TRY: cd sources_location   before starting Forth and compiling. )  quit [then]

needs Common-extensions.f  cr    \ Basic tools for Gforth and Win32Forth.
marker _SitesIndexWeb.fs .latest \ A framework for an index with SVG-pictograms. By J.v.d.Ven. 18-04-2025
                                 \ It needs Gforth on a Raspberry Pi with linux (Jessie or Bullseye)
0 [if]
This is a framework for your own extensions and svg-pictograms
The dependicies of the RPI are removed.
It should work under Linux Debian and the RPI.

The idea is as follows:
1) Create a new directory 'App' in your source directory
2) Put SitesIndex.fs in it.
3) Then cd source directory
4) $ sudo gforth-itc
5) needs _SitesIndexWeb.fs
If it works then you can modify SitesIndex.fs to your own wishes.
[then]

cr .( Activated options:)
 MARKER AdminPage     .latest \ For a link to the AdministrationPage for multiple RPI's or multiple ESP32 systems
 MARKER SitesIndexOpt .latest \ Makes the index with links visible

s" App/MachineSettings.fs" file-status nip 0= [if]
            needs App/MachineSettings.fs           \ Optional, to load machine depended markers.
            [THEN]

\ Options depended on the activated marker
[defined] AdminPage      [IF]  Needs Master.fs      [ELSE] needs slave.fs   [THEN]  \ Also loads the webserver

[defined] SitesIndexOpt
      [IF]    needs sitelinks.fs      \ Contains the #IndexSite defined for the slaves.
              cr cr .( NOTE: In sitelinks.fs the server-id for the index page for slaves is set to:)
              #IndexSite dup .  cr .( The ip address for it is:) ipAdress$ type
              FindOwnId to #IndexSite \ #IndexSite is network wide!
              cr .( This system has server-ID:) FindOwnId dup .
              cr .( It's ip address is:) ipAdress$ type
              s" App/SitesIndex.fs" file-status nip [if]
                     needs SitesIndex.fs                 \ A page with SVG pictograms.
              [ELSE] needs App/SitesIndex.fs        \ Use your own page with SVG pictograms and
              [THEN]                                     \ right links to your application.
      [THEN]

needs schedule_daily.fs    \ Actions at a planned time.

\ -------------- Html page --------------------------

ALSO HTML

: FrameWork ( - )
    s" Your comment" NearWhite 0 <HtmlLayout>
    430 100 0 4 1 <tablepx>   ( wPx hPx cellspacing padding border -- )
    <tr> <td> +HTML| Just an example | </td> </tr>
    </table>
    <EndHtmlLayout> ;

\ -------------- Incomming through tcp --------------


ALSO TCP/IP DEFINITIONS \ Adding the page and it's actions to the tcp/ip dictionary

: /home  ( - ) ['] FrameWork set-page  ; \ Redefine it.

\ ---------------------------------------------------

PREVIOUS PREVIOUS

\ Options to see the complete received request:
\ ' see-UDP-request  is udp-requests
\ ' see-request is handle-request

cr cr .( Starting the webserver-light.)
cr    .( The context will be TCP/IP only !  +a will get Forth again.)

start-servers
