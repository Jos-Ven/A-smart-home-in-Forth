Marker SetVersionPage.fs  .latest

: SetVersionPage  ( - )
   s"  SetVersion" NearWhite 0 <HtmlLayout>
  <tr><td> +HTML| Major&nbsp;vs.| </td>  <td> +HTML| Minor&nbsp;vs.|  7 .HtmlSpaces +html|   |  </td></tr>
  <tr><td> GetVersion# &Version @ SplitVersion >r
               0 999    3 r> <InputNumber +HTML| name="nn"/>| </td>      \ Major vs.
      <td>  >r 0 999999 6 r> <InputNumber +HTML| name="nn"/>|  </td></tr> \ Minor vs.
  <tr><td>  s" SetVersion"   s" AdminSetVersion"  <CssButton> </td>
      <td>  s" Cancel"       s" VersionCancel"  <CssButton> </td>  <td> .HtmlSpace </td>
  </tr> ;

TCP/IP DEFINITIONS

: AdminSetVersion ( Major-vs Minor-vs - ) swap  1000000 * + SetVersionFile ;

FORTH DEFINITIONS  PREVIOUS

\s
