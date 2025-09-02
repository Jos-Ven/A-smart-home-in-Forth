marker sitelinks.fs  .latest \ To link other Forth servers to a home page

1 value #IndexSite           \ Points to the ID of the server that contains an index of all sites.

: +quote ( counted-dest$ - ) >r [char] " sp@ 1 r> +place drop ;
: </a>2sp       ( - )  +HTML| </a>&nbsp; | ;


: (Tophref)     ( - )   html| <a target="_top" href="| ;
: Tophref="     ( - )  (Tophref) +html ;

: <pagelink ( page$ cnt #server - adr cnt )
    >r s" http://" upad place
   r@ r>ipAdress count +upad  s" :" +upad
   r> r>port @ (.) +upad
   +upad upad +quote  s" >" +upad upad count ;

: pagelink> ( link-text cnt - )   +HTML </a>2sp ;

: Sitelink ( #server - )
   upad off Tophref="  >r  s" /home" r@ <pagelink +HTML
   r> r>HostName count  pagelink> ;

: +Arplink ( - )
   s" /ArpPage" +HTML| <a href="| +homelink +HTML  +HTML| ">|
         +HTML| Network| +HTML| </a>: | ;

also tcp/ip

: Sitelinks ( page$ cnt - )  \ EG: /UpdateLinks or /SitesIndex
   #servers 0 over 1 >
      if  /UpdateLinks
         ?do  i  r>Online @   i TcpPort?  and
                if  i ServerHost <> \ Skip ServerId 0 (=host)
                     if  i Sitelink
                     then
                then
         loop
         +HTML| <a href="| +homelink +HTML +HTML| ">|
         +HTML| Refresh | +HTML| </a>|
      else  2drop 2drop
      then  ;

previous


: (SitesIndex) ( - ) \ make the index link visible
    s" /SitesIndex" #IndexSite <pagelink here place
   (Tophref) upad place here count +upad
    s" <strong>Index</strong>" +upad   s" </a> " +upad upad count +html  ;

' noop is SitesIndex           \ Default is off
   [DEFINED] SitesIndexOpt                    \ When SitesIndexOpt
   [IF]   ' (SitesIndex) is SitesIndex
   [THEN]


\s



