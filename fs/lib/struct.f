\ Structures

\ This module helps the management of structures in memory. A structure is an
\ address in memory where offsets compared to this address are mapped to names.
\ Here's an example:

\ struct Pos field pos.x field pos.y

\ This structure will be 8 bytes in size, x maps to Pos+0, y maps to Pos+4.
\ But up until now, our Pos exists nowhere. This unit doesn't manage structure
\ allocation in memory, you have to take care of this yourself. But once you
\ did, how will pos.x and pos.y know where to go? Pos is a simple value that is
\ expected to point to its current "base" address:

\ here to Pos 42 , 12 ,
\ pos.x .x1 --> 2a
\ pos.y .x1 --> 0c

\ Struct fields support the "to" semantics:
\ 54 to pos.x

0 value laststruct
0 value lastoffset

: struct 0 value current to laststruct 0 to lastoffset ;

: field doer laststruct to' execute , lastoffset , 4 to+ lastoffset does>
  dup @ @ swap 4 + @ + to? ?dup if execute else @ then ;

: 'field doer laststruct to' execute , lastoffset , does>
  dup @ @ swap 4 + @ + ;

\ Unbounded fields
\ These work a bit like struct fields, but without an associated struct. In
\ some cases, it makes more sense to have them instead of a full struct. Each
\ invocation of them require the struct's address on top of the PS. They also
\ support "to" mechanics, but are a bit awkward. For example:
\
\ 4 ( offset ) ufield foo
\ $1234 foo ( equivalent to $1238 @ )
\ 42 $1234 to+ foo ( equivalent to 42 $1238 +! )

: ufield ( off -- ) doer , does>
  @ + to? ?dup if execute else @ then ;

: 'ufield ( off -- ) doer , does> @ + ;
