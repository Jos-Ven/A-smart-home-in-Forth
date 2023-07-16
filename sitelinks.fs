marker sitelinks.fs \ To link other Forth servers to a home page

: +quote ( counted-dest$ - ) >r [char] " sp@ 1 r> +place drop ;
: </a>2sp       ( - )  +HTML| </a>&nbsp; | ;


: (Tophref)     ( - )   html| <a target="_top" href="| ;
: Tophref="     ( - )  (Tophref) +html ;

: <pagelink ( page$ cnt #server - adr cnt )
    >r s" http://" pad place
   r@ r>ipAdress count +pad  s" :" +pad
   r> r>port @ (.) +pad
   +pad pad +quote  s" >" +pad pad count ;

: pagelink> ( link-text cnt - )   +HTML </a>2sp ;

: Sitelink ( #server - )
   pad off Tophref="  >r  s" /home" r@ <pagelink +HTML
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

1 constant #IndexSite \ Points to the ID of the server that contains an index of all sites.

: (SitesIndex) ( - )
    s" /SitesIndex" #IndexSite <pagelink here place
   (Tophref) pad place here count +pad
    s" <strong>Index</strong>" +pad   s" </a> " +pad pad count +html  ;

' noop is SitesIndex           \ Default is off
[defined] SitesIndexOpt                    \ When SitesIndexOpt
  [IF] ' (SitesIndex) is SitesIndex 
  [THEN] \ make the index link visible


\s



