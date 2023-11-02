\ C Compiler Tests

?f<< tests/harness.f
?f<< cc/cc.f

testbegin

cc<< tests/cc/test.c

retconst 42 #eq
neg -42 #eq
bwnot $ffffffd5 #eq
exprbinops 7 #eq
binopand 42 #eq
binopor 42 #eq
binopxor 42 #eq
binopshl 336 #eq
binopshr 10 #eq
2 3 binop1 1 #eq
boolops 0 #eq
variables 82 #eq
funcall 42 #eq
42 pushpop 42 #eq
2 3 adder 5 #eq
3 2 subber 1 #eq
42 plusone 43 #eq
ptrget 42 #eq
ptrset 54 #eq
12 condif 13 #eq
42 condif 142 #eq
42 incdec 43 #eq
54 incdecp 55 #eq
exprparens 9 #eq
cnoop scnt 0 #eq
42 ptrari 46 #eq
array 52 #eq
global 1234 #eq
42 142 sysword 142 #eq
helloworld S" Hello, World!" #s=
42 40 50 isinrange 1 #eq
42 30 40 isinrange 0 #eq
42 5 forloop 47 #eq

testend
