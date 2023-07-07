\ File I/O
\ Requires sys/scratch

\ This creates a `f<` reader with the file descriptor embedded in it. This
\ allows for a straightforward override of input/output words.
: [f<] ( curfd -- word )
  scratch[ litn compile fgetc exit, ]scratch ;

\ Autoloading

: floaded? ( str -- f )
  floaded begin dup while 2dup 4 +
  s= if 2drop 1 exit then @ repeat 2drop 0 ;
: .floaded floaded begin dup while dup 4 + stype nl> @ repeat drop ;
: ?f<< word dup floaded? if drop else fload then ;

: require word dup floaded? not if stype abort"  required" else drop then ;
