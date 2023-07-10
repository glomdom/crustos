\ C Compiler Code Generation Utils
\ Requires lib/wordtbl, cc/vm and cc/ast

\ Code generation

: _err ( -- ) abort" gen error" ;
: _assert ( f -- ) not if _err then ;

alias noop gennode

: genchildren
  firstchild ?dup if begin dup gennode nextsibling ?dup not until then ;

: spit A>r >r >A begin Ac@+ .x1 next r>A ;
: lv>decl ( inode -- dnode-or-0 )
  dup ast.ident.name dup rot AST_FUNCTION parentnodeid
  ast.func.finddecl ?dup not if
    ast.unit.find else nip then ;

\\ Multiply the value of "node" by a factor of "n"
\\ FIXME: doesnt support lvalues and expressions
: node*=n
  dup nodeid case
    AST_CONSTANT of = tuck ast.const.value * swap to ast.const.value endof
    _err
  endcase ;

\\ Return the "pointer arithmetic size" of "node"
: node*arisz ( node -- n )
  dup nodeid AST_IDENT = if
    lv>decl ?dup _assert dup ast.decl.type
    swap ast.decl.nbelem 1 > if type*lvl+ then *ariunitsz else
    drop 1 then ;

\\ Given a BinaryOp node, verify whether pointer arithmetic adjustments
\\ are necessary. If one of the operands is a pointer and the other isn't,
\\ multiply the "not a pointer" one by the pointer's arithmetic size
: bop*ari
  firstchild ?dup _assert dup nextsibling ?dup _assert
  2dup node*arisz swap node*arisz 2dup = if
    2drop 2drop else
    < if swap then
    node*arisz swap node*=n then ;

\\ Does the node need 2 VM operands?
: needs2ops? ( node -- f )
  dup nodeid dup AST_BINARYOP = swap AST_FUNCALL = or if drop 1 exit then
  firstchild begin ?dup while dup needs2ops? not while nextsibling repeat
    drop 1 else 0 then ;

UOPSCNT wordtbl uopgentbl ( -- )
:w ( - ) vmneg, ;
:w ( ~ ) vmnot, ;
:w ( ! ) vmboolnot, ;
'w &op>op ( & )
'w *op>op ( * )
:w ( ++ ) vm++op, ;
:w ( -- ) vm--op, ;

POPSCNT wordtbl popgentbl ( -- )
:w ( ++ ) vmop++, ;
:w ( -- ) vmop--, ;

BOPSCNT wordtbl bopgentblpre ( node -- node )
:w ( + ) dup bop*ari ;
'w noop ( - )
'w noop ( * )
'w noop ( / )
'w noop ( < )
'w noop ( > )
'w noop ( <= )
'w noop ( >= )
'w noop ( == )
'w noop ( != )
'w noop ( && )
'w noop ( || )
'w noop ( = )

BOPSCNT wordtbl bopgentblpost ( -- )
'w vmadd, ( + )
'w vmsub, ( - )
'w vmmul, ( * )
:w ( / ) abort" TODO" ;
'w vm<, ( < )
:w ( > ) abort" TODO" ;
:w ( <= ) abort" TODO" ;
:w ( >= ) abort" TODO" ;
'w vm==, ( == )
:w ( != ) abort" TODO" ;
'w vm&&, ( && )
'w vm||, ( || )
:w ( = ) vmmov, ;

: decl>op ( dnode -- )
  dup ast.decl.isglobal? if
    ast.decl.sfoff mem>op
  else
    dup ast.decl.sfoff sf+>op
    ast.decl.nbelem 1 > if &op>op then
  then ;

ASTIDCNT wordtbl gentbl ( node -- )
:w ( Declare )
  dup ast.decl.isglobal? if
    here over to ast.decl.sfoff
    dup ast.decl.totsize allot
    dup firstchild nodeid case
      AST_CONSTANT of =
        dup firstchild ast.const.value
        over ast.decl.sfoff !
      endof
    endcase drop
  else
    dup firstchild ?dup if
      selop1 gennode op1<>op2
      selop1 decl>op vmmov,
    else drop then
  then ;

'w genchildren ( Unit )
:w ( Function )
  _debug if ." debug: " dup ast.func.name stype nl> then
  ops$
  dup ast.func.name entry
  here over to ast.func.address
  over ast.func.argsize over ast.func.sfsize over - vmprelude,
  genchildren
  _debug if current here current - spit nl> then ;
:w ( Return )
  genchildren vmret, ;
:w ( Constant )
  ast.const.value const>op ;
:w ( Statements )
  firstchild ?dup if begin dup gennode ops$ nextsibling ?dup not until then ;
'w genchildren ( ArgSpec )
:w ( Ident )
  dup lv>decl ?dup if
    nip decl>op else
    ast.ident.name find ?dup _assert mem>op then ;
:w ( UnaryOp )
  _debug if ." unaryop: " dup printast nl> .ops then
  dup genchildren
  ast.uop.opid uopgentbl swap wexec ;
:w ( PostfixOp )
  dup genchildren
  ast.pop.opid popgentbl swap wexec ;
:w ( BinaryOp )
  _debug if ." binop: " dup printast nl> .ops then
  selectedop >r >r
  r@ bopgentblpre r@ ast.bop.opid wexec
  firstchild dup nextsibling swap
  over needs2ops? if
    swap gennode
    dup needs2ops? if
      oppush rot gennode selop2 oppop else
      selop2 gennode op1<>op2 then
  else
    selop1 gennode selop2 gennode then

  bopgentblpost r> ast.bop.opid wexec
  r> if op1<>op2 else selop1 then ;
:w ( List )
  dup childcount dup 1+ 4 * scratchallot dup >r
  over >r tuck ! 4 + swap firstchild begin
    dup ast.const.value rot tuck !
    4 + swap nextsibling next 2drop
  r> constarray>op ;
:w ( If )
  firstchild ?dup not if _err then dup gennode ( exprnode )
  vmjz, swap ops$
  nextsibling ?dup not if _err then dup gennode ( jump_addr condnode )
  nextsibling ?dup if
    vmjmp, rot vmjmp!
    swap gennode then vmjmp! ;
:w ( StrLit )
  vmjmp, here
  rot ast.strlit.value dup c@
  1+ move, const>op vmjmp! ;
:w ( FunCall )
  \ Resolve the address node
  dup firstchild gennode
  oppush rot

  \ Pass the arguments
  dup childcount 1- 4 * callargallot,
  firstchild nextsibling ?dup if -4 swap begin
    dup selop1 gennode swap dup selop2 sf+>op op1<>op2 vmmov, selop1 opdeinit
    4 - swap nextsibling ?dup not until drop then
  
  \ Call
  oppop vmcall>op, ;

: _ ( node -- ) gentbl over nodeid wexec ;
current to gennode
