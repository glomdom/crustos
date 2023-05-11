\ File I/O
\ Requires sys/scratch

: fopen ( fname -- fd ) str>zstr zfopen ;

\ Autoloading
\ Entries in the floaded list have both a length byte and
\ a null termination byte. The null termination is used only
\ by the linux syscall, and may be removed in the future.

: floaded? ( str -- f )
  floaded begin dup while 2dup 4 +
  s= if 2drop 1 exit then @ repeat 2drop 0 ;
: .floaded floaded begin dup while dup 4 + stype nl> @ repeat drop ;
: ?f<< word dup floaded? if drop else fload then ;
