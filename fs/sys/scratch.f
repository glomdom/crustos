\ Scratchpad

\ The scratchpad is a circular buffer for placing semi-temporary strings (or
\ other sequences). The scratchpad has a running pointer and when we need
\ holding space, we reserve the current pointer and then allocate some space.
\ The pointer advances and is ready for the next piece of data. When it gets
\ at the end of the buffer, it goes back to the beginning.

$4000 value scratchsize
0 value _here

create scratch( scratchsize allot
: scratch) scratch( scratchsize + ;

scratch( value scratch>

: scratchallot ( n -- a )
  scratch> over + scratch) >= if scratch( to scratch> then
  scratch> swap to+ scratch> ( a ) ;

: []>str ( a u -- str )
  dup 1+ scratchallot ( src u dst-1 ) >r dup r@ c!+ swap ( src dst u ) move r> ;

\ Open a scratch area for writing
: scratch[ ( -- ) here to _here scratch> to here ;

\ Stop writing to the scratch area and restore here
\ Returns the address of the beginning of the written area
: ]scratch ( -- a ) scratch> here to scratch> _here to here ;
