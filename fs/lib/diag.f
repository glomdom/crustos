\ Diagnostic tools
: psdump scnt not if exit then
  scnt >A begin dup .x spc> >r scnt not until
  begin r> scnt A> = until ;
: .S ( -- )
  S" SP " stype scnt .x1 spc> S" RS " stype rcnt .x1 spc>
  S" -- " stype stack? psdump ;
: .free
  here ['] 2drop ( first word in boot.fs ) - .sz ."  used "
  heremax here - .sz ."  free" ;

: dump ( a -- ) \ dump 8 lines of data after "a"
  A>r >A 8 >r begin
    ':' emit A> dup .x spc> ( a )
    8 >r begin Ac@+ .x1 Ac@+ .x1 spc> next ( a ) >A
    16 >r begin Ac@+ dup SPC - $5e > if drop '.' then emit next
  nl> next r>A ;
