\ Tests for asm/i386.f

?f<< /tests/harness.f
?f<< /asm/i386.f

: spit ( a u -- ) A>r >r >A begin Ac@+ .x1 next r>A ;

testbegin

code foo1
  ax 42 i) mov,
  bp 4 i) sub,
  bp 0 d) ax mov,
  ret,
foo1 42 #eq

here 1234 ,
code foo2
  bx m) mov,
  bp 4 i) sub,
  bp 0 d) bx mov,
  ret,
foo2 1234 #eq

\ Test call in its different forms
code foo3
  ' foo1 call,
  ax ' foo1 i) mov,
  ax call,
  ret,
foo3 42 #eq 42 #eq

\ Test shr/shl
code foo4
  ax 42 i) mov,
  ax 3 i) shl,
  cl 2 i) mov,
  ax shrcl,
  bp 4 i) sub,
  bp 0 d) ax mov,
  ret,
foo4 84 #eq

\ Test single operands
code foo5
  ax 42 i) mov,
  bx 3 i) mov,
  bx mul,
  ax ax test,
  bl setnz,
  al bl add,
  bp 4 i) sub,
  bp 0 d) ax mov,
  ret,
foo5 127 #eq

\ push/pop
code foo6
  42 i) push,
  dx pop,
  bp 4 i) sub,
  bp 0 d) dx mov,
  ret,
foo6 42 #eq

\ MOV immediate to r/m
code foo7
  bp 4 i) sub,
  bp 0 d) 42 i) mov,
  ret,
foo7 42 #eq

\ Displacement for ESP
code foo8
  42 i) push,
  ax sp 0 d) mov,
  sp 4 i) add,
  bp 4 i) sub,
  bp 0 d) ax mov,
  ret,
foo8 42 #eq

testend
