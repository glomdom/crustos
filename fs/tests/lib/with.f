?f<< lib/with.f
?f<< tests/harness.f

testbegin

create cell1 7 ,
: foo cell1 @ 55 #eq ;
: bar ['] foo 55 cell1 with ;

bar cell1 @ 7 #eq

: _ 0 cell1 with[ 77 . ]with ; _
: baz $77 cell1 with[ cell1 @ $77 #eq $99 cell1 ! ]with cell1 @ 7 #eq 8 cell1 ! ;
baz cell1 @ 8 #eq

testend
