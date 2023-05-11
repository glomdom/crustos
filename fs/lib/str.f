\ String Utilities
\ All string utitilies operate on an "active string", which is set with `>s`

\\ Maximum value of strings (including the size byte)
$100 value STR_MAXSZ

: ws? SPC <= ;
: s) c@+ + ;

: sfind -1 rot> begin
  rot 1+ rot>
  2dup s= if 2drop exit then
  s) dup c@ not until 2drop drop -1 ;

: slistiter
  swap dup if >r begin s) next else drop then ;

\ Given a list of character ranges, which are given in the form of a string of
\ character pairs, return whether the specified character is in one of the ranges.
: rmatch
  A>r >A Ac@+ >> >r begin
    dup Ac@+ Ac@+ =><= if drop r~ r>A 1 exit then
  next drop 0 r>A ;

create _ 2 c, ," 09"
: 0-9? _ rmatch ;
create _ 4 c, ," AZaz"
: A-Za-z? _ rmatch ;
create _ 6 c, ," AZaz09"
: alnum? _ rmatch ;

\ Create a list of strings (same format as sfind above) with the specified
\ number of elements. Each element must be "quoted" with no space (unless you
\ want them in the string) in the quotes.
\
\ Example: 3 stringlist mylist "foo" "bar" "hello world!"
: stringlist create >r begin
  begin in< dup ws? while drop repeat
  '"' = not if '"' emit abort"  expected" then
  [compile] S" drop next 0 c, ;
