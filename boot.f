: = - not ;
: 0< <<c nip ;

: immediate current 1- dup c@ $80 or swap c! ;
: ['] ' litn ; immediate
: to ['] ! [to] ;
: to+ ['] +! [to] ;
: to' ['] noop [to] ;

: compile ' litn ['] call, call, ; immediate
: if compile (?br) here 4 allot ; immediate
: then here swap ! ; immediate
: else compile (br) here 4 allot here rot ! ; immediate
: begin here ; immediate
: again compile (br) , ; immediate
: until compile (?br) , ; immediate
: next compile (next) , ; immediate

: code word entry ;
: create code compile (cell) ;
: value code compile (val) , ;

: \ begin in< $0a = until ; immediate

: ( begin
  word dup c@ 1 = if
    1+ c@ ')' = if exit then else drop then
  again ; immediate

: fclose ( fd -- ) 6 ( close ) swap 0 0 ( close fd 0 0 ) lnxcall drop ;

create _ 'C' c, 'a' c, 'n' c, ''' c, 't' c, $20 c, 'o' c, 'p' c, 'e' c, 'n' c,

: zfopen ( zfname -- fd )
  5 swap 0 0 lnxcall
  dup 0< if _ 10 rtype abort then ;

create _ 1 allot
: fread ( fd -- c-or-0 ) 3 ( read ) swap _ 1 lnxcall 1 = if _ c@ else 0 then ;

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
