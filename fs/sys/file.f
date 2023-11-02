\ File I/O
?f<< /lib/scratch.f
?f<< /lib/with.f

\ We need a private scratchpad here because some cursors can be quite
\ long-lived. If we use the system scratchpad, short-lived data will overwrite
\ our cursors.
$200 scratchpad$ filespad

\ This creates a `f<` reader with the file descriptor embedded in it. This
\ allows for a straightforward override of input/output words.
: [f<] ( curfd -- word )
  filespad to' Scratchpad with[
  scratch[ litn compile fgetc exit, ]scratch ]with ;

: .floaded floaded begin dup while dup 4 + stype nl> @ repeat drop ;
: require word dup floaded? not if stype abort"  required" else drop then ;
: with-stdin-file ( w str -- )
  to@ stdin >r fopen dup >r
  [f<] to stdin execute
  r> fclose r> to stdin ;
