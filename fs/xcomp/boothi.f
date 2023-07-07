0 value curfd   \ file descriptor of the file currently being read
0 value floaded \ address of the current loaded file structure
0 value fecho

: f< ( -- c ) curfd fread fecho if dup emit then ;
: fload ( fname -- )
  floaded here to floaded ,
  dup c@ 1+ move, 0 c,
  curfd >r
  floaded 5 + zfopen to curfd
  to' in< @ >r ['] f< to in<
  begin maybeword ?dup if runword 0 else 1 then until
  r> to in< curfd fclose r> to curfd ;

: f<< word fload ;
f<< init.f