bootfile xcomp/boothi.f

0 value curfd   \ file descriptor of the file currently being read
0 value fecho

: f< ( -- c ) curfd fgetc fecho if dup emit then ;
: fload ( fname -- )
  floaded, curfd >r
  floaded 4 + fopen to curfd
  to' in< @ >r ['] f< to in<
  begin maybeword ?dup if runword 0 else 1 then until
  r> to in< curfd fclose r> to curfd ;
: f<< word fload ;
: floaded? ( str -- f )
  floaded begin dup while 2dup 4 +
  s= if 2drop 1 exit then @ repeat 2drop 0 ;
: ?f<< word dup floaded? if drop else fload then ;

f<< init.f
