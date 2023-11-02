\ Scratchpads
?f<< /lib/struct.f

\ Scratchpads are circular buffers for placing semi-temporary strings (or
\ other sequences). The scratchpad has a running pointer and when we need
\ holding space, we reserve the current pointer and then allocate some space.
\ The pointer advances and is ready for the next piece of data. When it gets
\ at the end of the buffer, it goes back to the beginning.

\ The system scratchpad lives at sys/scratch.

struct Scratchpad
  field scratchsize
  field scratch>
  'field scratch(

0 value _here

: scratchpad$ ( size "name" -- ) create dup , here CELLSZ + , allot ;
: scratch) scratch( scratchsize + ;
: scratchallot ( n -- a )
  scratch> over + scratch) >= if ." scratch reload" nl> scratch( to scratch> then
  scratch> swap to+ scratch> ;

\ Push a range to the scratchpad as a string.
: []>str ( a u -- str )
  dup 1+ scratchallot >r dup r@ c!+ swap move r> ;

\ Open a scratch area for writing
: scratch[ ( -- ) here to _here scratch> to here ;

\ Stop writing to the scratch area and restore here.
\ Returns the address of the beginning of the written area.
: ]scratch ( -- a ) scratch> here to scratch> _here to here ;
