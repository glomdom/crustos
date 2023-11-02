\ Tests for asm.f

?f<< tests/harness.f
?f<< asm.f

testbegin

code foo1
  eax 42 i32 mov,
  ebp 4 i32 sub,
  [ebp] eax mov,
  ret,

foo1 42 #eq

here 1234 , ( a )
code foo2
  ebx [i32] mov,
  ebp 4 i32 sub,
  [ebp] ebx mov,
  ret,

foo2 1234 #eq

code foo3
  ' foo1 call,
  eax ' foo1 i32 mov,
  eax call,
  ret,

foo3 42 #eq 42 #eq

\ Test for shr/shl
code foo4
  eax 42 i32 mov,
  eax 3 i32 shl,
  cl 2 i32 mov,
  eax cl shr,
  ebp 4 i32 sub,
  [ebp] eax mov,
  ret,

foo4 84 #eq

testend
