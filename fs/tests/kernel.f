?f<< tests/harness.f

testbegin

\ Arithmetic
3 5 * 15 #eq
11 3 /mod 3 #eq 2 #eq

\ Semantics: to
42 value foo
43 to foo
foo 43 #eq
5 to+ foo
foo 48 #eq
to' foo @ 48 #eq
