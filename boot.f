: = - not ;
: 0< <<c nip ;

: immediate current 1- dup c@ $80 or swap c! ;
: ['] ' litn ; immediate
: to ['] ! [to] ;
: to+ ['] +! [to] ;
: to' ['] noop [to] ;

: compile ' litn ['] call, call, ; immediate
: if compile (?br) here 4 allot ; immediate
: then here swap ! ; immediate
: else compile (br) here 4 allot here rot ! ; immediate
: begin here ; immediate
: again compile (br) , ; immediate
: until compile (?br) , ; immediate
: next compile (next) , ; immediate

: code word entry ;
: create code compile (cell) ;
: value code compile (val) , ;

: \ begin in< $0a = until ; immediate

: ( begin
  word dup c@ 1 = if
    1+ c@ ')' = if exit then else drop then
  again ; immediate

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

\ File I/O
: fclose ( fd -- ) 6 ( close ) swap 0 0 ( close fd 0 0 ) lnxcall drop ;

create _ 'C' c, 'a' c, 'n' c, ''' c, 't' c, $20 c, 'o' c, 'p' c, 'e' c, 'n' c,

: zfopen ( zfname -- fd )
  5 swap 0 0 lnxcall
  dup 0< if _ 10 rtype abort then ;

create _ 1 allot
: fread ( fd -- c-or-0 ) 3 ( read ) swap _ 1 lnxcall 1 = if _ c@ else 0 then ;

0 value curfd   \ file descriptor of the file currently being read
0 value floaded \ address of the current loaded file structure
0 value fecho

: f< ( -- c ) curfd fread fecho if dup emit then ;
: fload ( fname -- )
  floaded here to floaded ,
  dup c@ 1+ move, 0 c,
  curfd >r
  floaded 5 + zfopen to curfd
  to' in< @ >r ['] f< to in<
  begin maybeword ?dup if runword 0 else 1 then until
  r> to in< curfd fclose r> to curfd ;

: f<< word fload ;
f<< init.f
