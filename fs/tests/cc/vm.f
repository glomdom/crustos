\ C Compiler Virtual Machine Tests

?f<< tests/harness.f
?f<< asm.f
?f<< cc/vm.f

testbegin

\ binop[+](binop[*](const[2],const[3]),const[1])
ops$
code test1
  0 0 vmprelude,
  selop1 2 const>op
  selop2 3 const>op
  vmmul,
  selop2 1 const>op
  vmadd,
  vmret,

test1 7 #eq

\ binop[+](binop[-](const[3], const[1]),binop[*](const[2],const[3]))
ops$
code test2
  0 0 vmprelude,
  selop1 3 const>op
  selop2 1 const>op
  vmsub,
  selop1 oppush
  selop1 2 const>op
  selop2 3 const>op
  vmmul,
  selop2 oppop
  vmadd,
  vmret,

test2 8 #eq

\ sub 2 args
ops$
code test3
  8 0 vmprelude,
  selop1 4 sf+>op
  selop2 0 sf+>op
  vmsub,
  vmret,

54 12 test3 42 #eq

\ assign 2 local vars
ops$
code test4
  0 8 vmprelude,

  selop2 42 const>op
  selop1 4 sf+>op
  vmmov,
  ops$

  selop2 5 const>op
  selop1 0 sf+>op
  vmmov,
  ops$

  selop1 4 sf+>op
  selop2 0 sf+>op

  vmadd,
  vmret,

test4 47 #eq

\ variable reference and dereference
ops$
code test5
  0 8 vmprelude,

  selop2 42 const>op
  selop1 4 sf+>op
  vmmov,
  ops$

  selop2 4 sf+>op
  &op>op
  selop1 0 sf+>op
  vmmov,
  ops$

  selop1 0 sf+>op
  *op>op
  vmret,

test5 42 #eq

\ assign and dereference
ops$
code test6
  0 8 vmprelude,

  selop2 42 const>op
  selop1 4 sf+>op
  vmmov,
  ops$

  selop2 4 sf+>op
  &op>op
  selop1 0 sf+>op
  vmmov,
  ops$

  selop2 54 const>op
  selop1 0 sf+>op
  *op>op
  vmmov,
  ops$

  selop1 4 sf+>op
  vmret,

test6 54 #eq

\ Absolute Memory Location
ops$
here 1234 , ( a )
code test7
  0 0 vmprelude,
  selop1 mem>op
  vmret,

test7 1234 #eq

testend
