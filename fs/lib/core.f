\ Core Forth words which are hard to live without

\ Compiling Words
: [compile] ' call, ; immediate
: const code litn exit, ;
4 const CELLSZ
: alias ' code compile (alias) , ;
: doer code compile (does) CELLSZ allot ;
: does> r> ( exit current definition ) current 5 + ! ;

\ Stack
: 2drop drop drop ;
: 2dup over over ;

\ Memory
: c@+ ( a -- a+1 c ) dup 1+ swap c@ ;
: c!+ ( c a -- a+1 ) tuck c! 1+ ;
: Ac@+ Ac@ A+ ;
: Ac!+ Ac! A+ ;
: fill ( a u b -- ) A>r rot> >r >A begin dup Ac!+ next drop r>A ;
: allot0 ( n -- ) here over 0 fill allot ;

\ Arithmetic
: > swap < ;
: 0>= 0< not ;
: >= < not ;
: <= > not ;
: -^ swap - ;
: / /mod nip ;
: mod /mod drop ;
: << <<c drop ;
: >> >>c drop ;
: ?swap ( n n -- l h ) 2dup > if swap then ;
: min ?swap drop ; : max ?swap nip ;
: =><= ( n l h -- f ) over - rot> ( h n l ) - >= ;

\ Emitting
$20 const SPC $0d const CR $0a const LF
$08 const BS  $04 const EOF

: nl> CR emit LF emit ;
: spc> SPC emit ;

\ Emit all chars of `str`
: stype ( str -- ) c@+ rtype ;
: ," begin in< dup '"' = if drop exit then c, again ;
: S" ( comp: -- ) ( not-comp: -- str )
  compiling if compile (s) else here then
  here 1 allot here ," here -^ ( 'len len ) swap c! ; immediate
: ." [compile] S" compile stype ; immediate
: abort" [compile] ." compile abort ; immediate

\ Flow Control
: leave r> r~ 1 >r >r ;

\ while..repeat
: while [compile] if swap ; immediate
: repeat [compile] again [compile] then ; immediate

\ case..endcase
\ The case statement is very similar to what we see in other Forths, but with
\ one major difference: the "of" word specifies the truth word. So, the
\ "of" we see in other Forths is equivalent to "of =" in crust. The comparator
\ has to be a single word following "of".
\ case x of = ... endof y of < ... endof ... endcase
\ is syntactic sugar for:
\ >r x r@ = if ... else y r@ < if ... else ... then then r~
\ NOTE: if you want to access your reference value in the final "else", you
\ need to use "r@".
: case ( -- then-stopgap ) 0 compile >r ; immediate
: of ( -- jump-addr ) compile r@ ' call, [compile] if ; immediate
alias else endof immediate
: endcase ( then-stopgap jump1? jump2? ... jumpn? -- )
  ?dup if begin [compile] then ?dup not until then compile r~ ; immediate

\ Sequences
: [c]? ( c a u -- i )
  ?dup not if 2drop -1 exit then A>r over >r >r >A ( c )
  begin dup Ac@+ = if leave then next ( c )
  A- Ac@ = if A> r> - ( i ) else r~ -1 then r>A ;
: s= ( s1 s2 -- f ) over c@ 1+ []= ;

\ Doc Comment Placeholder
alias \ \\