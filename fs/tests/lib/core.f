?f<< tests/harness.f

testbegin

\ Number Formatting
42 capture .x1 S" 2a" #s=
$1234 capture .x S" 00001234" #s=
42 capture . S" 42" #s=
-1984 capture . S" -1984" #s=
0 capture . S" 0" #s=
0 capture .sz S" 0B" #s=
1024 1024 * 1- capture .sz S" 1023KB" #s=
42 1024 * 1024 * capture .sz S" 42MB" #s=
-1 capture .sz S" 3GB" #s=

\ Words: Does
: incer doer , does> @ 1+ ;
41 incer foo
101 incer bar

foo 42 #eq
bar 102 #eq

\ Words: Case
: foo ( n ) case
  1 of = 111 endof
  42 of > 222 endof
  333
  endcase ;

1 foo 111 #eq
2 foo 222 #eq
3 foo 222 #eq
42 foo 333 #eq

\ Words: While & Repeat
: foo begin dup 9 20 =><= not while dup 3 5 =><= not while 1+ repeat
  100 + else 200 + then ;

1 foo 103 #eq
10 foo 210 #eq
6 foo 209 #eq
20 foo 220 #eq

\ Words: prevword ;
: bar ;
: baz ;
' baz prevword ' bar #eq

\ Autoloading
floaded #

S" some_nonexistant_file" floaded? not #
S" tests/harness.f" floaded? #

testend
