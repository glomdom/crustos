\ File I/O
\ Requires sys/scratch

\ This creates a `f<` reader with the file descriptor embedded in it. This
\ allows for a straightforward override of input/output words.
: [f<] ( curfd -- word )
  scratch[ litn compile fgetc exit, ]scratch ;

: .floaded floaded begin dup while dup 4 + stype nl> @ repeat drop ;

: require word dup floaded? not if stype abort"  required" else drop then ;
