4 stringlist typenames "void" "char" "short" "int"
: typesigned? ( type -- flags ) 2 rshift 1 and ;
: type*lvl ( type -- lvl ) 3 rshift 3 and ;
: type*lvl! ( lvl type -- type ) $f and swap 3 lshift or ;
: type*lvl+ ( type -- type ) dup type*lvl 1+ swap type*lvl! ;

create _ 0 c, 1 c, 2 c, 4 c,
: typesize ( type -- size-in-bytes )
  dup type*lvl if drop 4 else 3 and _ + c@ then ;

\ Returns a "pointer arithemtic unit size" for type, that is - the size of
\ a "single element" in pointer arithmetics. This allows, for example `ptr + 1`
\ to generate `ptr + 4` in native code, if `ptr` is an `int`
\
\ Pointers to pointers always return 4. Non-Pointers always return 1.
\ 1st level pointers return the data they're pointing to
: *ariunitsz ( type -- n )
  dup type*lvl case
    0 of = drop 1 endof
    1 of = typesize endof
    drop 4
  endcase ;

: parseType ( tok -- type? f )
  dup S" unsigned" s= if drop $04 nextt else $00 swap then ( type tok )
  typenames sfind dup 0>= if ( type idx ) or 1 else 2drop 0 then ( type ) ;

: printtype ( type -- )
  dup typesigned? if ." unsigned" then
  dup 3 and typenames slistiter stype
  type*lvl ?dup if >r begin '*' emit next then ;
