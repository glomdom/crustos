exitonabort

\ `#` means `assert`
: # ( f -- ) not if abort" assert failed" then ;
: #eq ( n n -- ) 2dup = if 2drop else swap .x ."  != " .x abort then ;

create _buf $100 allot
0 value _sz

: _emit ( c -- )
  _buf _sz + 1+ c! 1 to+ _sz
  _sz $ff > if abort" capture overflow" then ;

\ Capture is called with one word to call with capture on. It returns
\ the captured string. $ff bytes max.
: capture ( -- str )
  word ['] _emit to emit 0 to _sz runword
  ['] (emit) to emit
  _sz _buf c! _buf ;

: #s= ( s1 s2 -- ) 2dup s= if 2drop else swap stype ."  != " stype abort then ;

: testbegin 1 to fecho ;
: testend .S nl> .free nl> 0 to fecho scnt 0 #eq ;
