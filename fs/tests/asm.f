?f<< tests/harness.f
?f<< asm.f

testbegin
\ Tests for asm.f

code foo
  eax 42 i32 mov,
  ebp 4 i32 sub,
  [ebp] eax mov,
  ret,

foo 42 #eq

testend
