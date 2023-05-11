\ Tests for asm.f

?f<< tests/harness.f
?f<< asm.f

testbegin

code foo
  eax 42 i32 mov,
  ebp 4 i32 sub,
  [ebp] eax mov,
  ret,

foo 42 #eq

here 1234 , ( a )
code foo
  ebx [i32] mov,
  ebp 4 i32 sub,
  [ebp] ebx mov,
  ret,

foo 1234 #eq

testend
