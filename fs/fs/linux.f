\ Filesystem implemented as Linux System Calls
\ Requires a `lnxcall` word in the kernel

: fclose ( fd -- ) 6 ( close ) swap 0 0 ( close fd 0 0 ) lnxcall drop ;

create _buf $100 allot
: _tozstr ( s -- zs )
  c@+ >r _buf r@ move 0 _buf r> + c! _buf ;

create _ 'C' c, 'a' c, 'n' c, ''' c, 't' c, $20 c, 'o' c, 'p' c, 'e' c, 'n' c,

: fopen ( fname -- fd )
  _tozstr 5 swap 0 0 lnxcall
  dup 0< if _ 10 rtype abort then ;

create _ 1 allot
: fread ( fd -- c-or-0 ) 3 ( read ) swap _ 1 lnxcall 1 = if _ c@ else 0 then ;
