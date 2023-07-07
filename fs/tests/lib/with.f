?f<< lib/with.f
?f<< tests/harness.f

testbegin

create cell1 7 ,
: foo cell1 @ 55 #eq ;
: bar ['] foo 55 cell1 with ;

bar cell1 @ 7 #eq

testend
