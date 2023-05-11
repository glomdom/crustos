\ Extra "here" space
\ This subsystem is a preallocated buffer for transitionary data. It's very
\ similar to lib/scratch, but for written (with "," words) data. Unlike the
\ sratchpad, this is not a rolling buffer. You're expected to know when you
\ start using it, and when you stop.

\ You initialize it with here$, and then activate it with here[. From that
\ moment, everything you write is temporary. You return to your regular "here"
\ with ]here.

\ This is used, for example, as a temporary space for the C compiler AST and
\ mapping. Without xhere, this data is written to here and permanently uses
\ system memory.

32 1024 * const XHERESZ
1024 const XHEREWARN

create _buf XHERESZ allot
_buf value _ptr
0 value _oldhere

: xhere$ _buf to _ptr ;
: xhere[ here to _oldhere _ptr to here ;
: ]xhere
  here to _ptr _oldhere to here
  _ptr XHEREWARN + _buf XHERESZ + > if
    ." running out of xhere space! " nl> then ;
