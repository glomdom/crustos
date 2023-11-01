\ Dictionary
: preventry ( w -- w ) 5 - @ ;
: preventry! ( w w -- ) 5 - ! ;
: wordlen ( w -- len ) 1- c@ $3f and ;
: wordname[] ( w -- sa sl )
  dup wordlen swap 5 - over - ( sl sa ) swap ;

: word? ( w -- f ) dup if wordname[] if c@ 127 = not else drop 0 then then ;
: (prevword) ( w -- w ) begin dup while dup word? not while preventry repeat then ;
: prevword ( w -- w ) preventry (prevword) ;
: lastword ( -- w ) current (prevword) ;
: .word ( w -- ) wordname[] rtype ;
: words ( -- )
  lastword begin dup while dup .word spc> prevword repeat drop ;
