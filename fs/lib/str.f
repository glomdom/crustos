\ String/Range Utilities

\\ Maximum value of strings (including the size byte)
$100 value STR_MAXSZ

: ws? SPC <= ;
: s) c@+ + ;

\\ Index of `c` inside range `a u`. -1 if not found.
: [c]? ( c a u -- i )
  ?dup not if 2drop -1 exit then A>r over >r >r >A
  begin dup Ac@+ = if leave then next
  A- Ac@ = if A> r> - else r~ -1 then r>A ;

: sappend ( c str -- ) tuck s) c! dup c@ 1+ swap c! ;

\\ Checks if str1 contains all of str2 (is str2 a substring?)
: scontains ( str1 str2 -- f )
  >r c@+ begin
    dup r@ c@ >= while
    over r@ c@+ []= if
      r> drop 2drop 1 exit
    then
    1- swap 1+ swap
  repeat r> drop 2drop 0 ;

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
