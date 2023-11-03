\ File I/O
0 S" lib" fchild S" io.f" fchild fload

0 value curdir
create _buf $100 allot

: findpathdir ( path -- dirid? name-or-0 )
  A>r 0 _buf c!+ >A c@+
  over c@ '/' = if 1- >r 1+ 0 else >r curdir then swap
  begin
    c@+ dup '/' = if
      drop swap _buf fchild
      ?dup not if drop 0 r~ r>A exit then swap
      0 _buf c!+ >A
    else
      Ac!+ _buf c@ 1+ _buf c! then
  next drop _buf r>A ;

: findpath ( path -- id-or-0 )
  findpathdir ?dup if fchild else 0 then ;

: findpath# ( path -- id ) findpath ?dup not if abort" path not found" then ;

: chdir ( path -- ) findpath ?dup if to curdir else abort" not found" then ;

: f<< word findpath# fload ;
: floaded? ( id -- f )
  floaded begin
    dup while 2dup 4 + @ = if 2drop 1 exit then @ repeat 2drop 0 ;
: ?f<< word findpath# dup floaded? if drop else fload then ;

: fseek ( pos hdl -- ) dup 12 + @ execute ;
: fclose ( hdl -- ) dup 16 + @ execute ;

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
  scratch[ litn compile getc exit, ]scratch ]with ;

: require word dup findpath# floaded? not if
  stype abort"  required" else drop then ;
: with-stdin-file ( w str -- )
  to@ stdin >r findpath# fopen dup >r
  [f<] to stdin execute
  r> fclose r> to stdin ;
