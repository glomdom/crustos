\ Number Formatting

\ Hexadecimal
create _ ," 0123456789abcdef"
: .xh $f and _ + c@ emit ;
: .x1 dup 4 rshift .xh .xh ;
: .x2 dup 8 rshift .x1 .x1 ;

\\ Print the top of the stack in hexadecimal
: .x ( n -- ) dup 16 rshift .x2 .x2 ;

\ Decimal
: _ 10 /mod ?dup if _ then '0' + emit ;
: . ( n -- )
  ?dup not if
    '0' emit else
    dup 0< if '-' emit 0 -^ _ else _ then
  then ;

\ Size
create _ ," KMG"
: .sz ( size-in-bytes -- )
  0 begin
    swap 1024 /mod ?dup while
    nip swap 1+ repeat
  . ?dup if 1- _ + c@ emit then 'B' emit ;
