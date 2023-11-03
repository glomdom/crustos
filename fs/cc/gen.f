\ C compiler code generation

\ Code generation

\ This unit takes an AST and generates native code using cc/vm operations. We
\ do so by starting from the root Unit node, iterate children (Functions) and
\ recursively "resolve" them.

\ As a general rule, we stay with Op1 (in cc/vm) active. Op2 usage is an
\ exception. However, it's very important that "regular" node handler *don't*
\ explicitely select Op1, because when we select Op2 for these exceptional
\ reasons, we generally want to to this recursively, all the way down. This is
\ why we don't see "selop" calls except in those exceptional places. We always
\ target the "active" op.

\ Binary Op resolution strategy
\ The Binary Op node generation logic a few lines below needs a bit of an
\ explanation. A binary op needs the two VM operands at once, apply an operation
\ on them and return the result in Op1. Yes, Op1, not "active" op.

\ A binary op can have 3 basic configuration for its two children:
\ 1. Both children are "single ops" (or lvalues, or constants... nothing that
\    requires 2 ops.
\ 2. One of the child is or contains a node that needs 2 ops and the other is
\    simple.
\ 3. Both children are or contain nodes that need 2 ops.

\ The first configuration is easy to solve, no need for anything. You resolve
\ the first in op1, the second in op2, then apply the operation.

\ The second configuration needs careful threading. Because the binop requires
\ both VM operands, it should be executed first. If the binop is "left" (the
\ first child), then nothing special needs to be done, Op1 has the proper value.
\ If the binop is "right", then we need to swap Op1 and Op2 after having
\ resolved it so that its result sits in the proper Op.

\ The third configuration is the tricky one. If nothing is done, the result of
\ the first binop will be overwritten by the calculation made by the second
\ binop. We need to:
\ 1. resolve the first node
\ 2. save the result
\ 3. resolve the second node
\ 4. swap the result to Op2
\ 5. restore the result to Op1.

\ cc/vm abstracts away the save/restore mechanism through oppush/oppop.
?f<< lib/wordtbl.f
?f<< cc/vm.f
?f<< cc/ast.f

: _err ( -- ) abort" gen error" ;
: _assert ( f -- ) not if _err then ;

\ Result of the last identified call.
0 value lastidentfound

alias noop gennode ( node -- ) \ forward declaration

: genchildren ( node -- )
  firstchild ?dup if begin dup gennode nextsibling ?dup not until then ;

: spit ( a u -- ) A>r >r >A begin Ac@+ .x1 next r>A ;
: identfind ( inode -- dnode-or-fnode-or-0 )
  dup ast.ident.name dup rot AST_FUNCTION parentnodeid ( name name fnode )
  ast.func.finddecl ?dup not if ( name )
    ast.unit.find else nip then dup to lastidentfound ;

\ Multiply the value of "node" by a factor of "n"
\ TODO: support lvalues and expressions
: node*=n ( n node -- )
  dup nodeid case ( n node )
    AST_CONSTANT of = tuck ast.const.value * swap to ast.const.value endof
    _err
  endcase ;

\ Return the "pointer arithmetic size" of "node".
: node*arisz ( node -- n )
  dup nodeid AST_IDENT = if ( node )
    identfind ?dup _assert dup ast.decl.type ( dnode type )
    swap ast.decl.nbelem ( nbelem ) 1 > if type*lvl+ then *ariunitsz ( n ) else
    drop 1 then ;

\ given a BinaryOp node "bnode", verify whether pointer arithmetic adjustments
\ are necessary. If one of the operands is a pointer and the other is not,
\ multiply the "not a pointer" one by the pointer's "arithmetic size".
: bop*ari ( bnode -- )
  firstchild ?dup _assert dup nextsibling ?dup _assert ( n1 n2 )
  2dup node*arisz swap node*arisz 2dup = if \ same *arisz, nothing to do
    2drop 2drop else \ different *arisz, adjust
    ( n1 n2 sz2 sz1 ) < if swap then ( node-to-adjust pointer-node )
    node*arisz swap node*=n then ;

\ Does node need 2 VM operands?
: needs2ops? ( node -- f )
  dup nodeid dup AST_BINARYOP = swap AST_FUNCALL = or if drop 1 exit then
  firstchild begin ?dup while dup needs2ops? not while nextsibling repeat
    ( needs2ops? == true ) drop 1 else ( end of children ) 0 then ;

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
'w noop ( << )
'w noop ( >> )
'w noop ( < )
'w noop ( > )
'w noop ( <= )
'w noop ( >= )
'w noop ( == )
'w noop ( != )
'w noop ( & )
'w noop ( ^ )
'w noop ( | )
'w noop ( && )
'w noop ( || )
'w noop ( = )
'w noop ( <<= )
'w noop ( >>= )

BOPSCNT wordtbl bopgentblpost ( -- )
'w vmadd, ( + )
'w vmsub, ( - )
'w vmmul, ( * )
:w ( / ) abort" TODO" ;
'w vm<<,
'w vm>>,
'w vm<, ( < )
:w ( > ) abort" TODO" ;
:w ( <= ) abort" TODO" ;
:w ( >= ) abort" TODO" ;
'w vm==, ( == )
:w ( != ) abort" TODO" ;
:w ( & ) vm&, ;
:w ( ^ ) vm^, ;
:w ( | ) vm|, ;
'w vm&&, ( && )
'w vm||, ( || )
:w ( = ) vmmov, ;
'w vm<<=,
'w vm>>=,

: decl>op ( dnode -- ) case
    of ast.decl.isglobal? r@ ast.decl.address mem>op endof
    of ast.decl.isarg? r@ ast.decl.address ps+>op endof
    r@ ast.decl.address sf+>op
    r@ ast.decl.nbelem 1 > if &op>op then
  endcase ;

ASTIDCNT wordtbl gentbl ( node -- )
:w ( Declare ) dup ast.decl.isglobal? if
    here over to ast.decl.address
    dup ast.decl.totsize allot
    dup firstchild nodeid case ( dnode )
      AST_CONSTANT of =
        dup firstchild ast.const.value
        over ast.decl.address !
      endof
    endcase drop
  else ( node )
    dup >r AST_FUNCTION parentnodeid dup ast.func.cursf ( fnode cursf )
    r@ ast.decl.totsize - ( fnode cursf )
    dup rot to ast.func.cursf ( cursf )
    r@ to ast.decl.address ( )
    r@ firstchild ?dup if ( node )
      selop1 gennode ( value in op1 ) op1<>op2
      selop1 r@ decl>op vmmov,
    then r~
  then ;
'w genchildren ( Unit )
:w ( Function )
  _debug if ." debugging: " dup ast.func.name stype nl> then
  ops$
  dup ast.func.flags 1 and if
    dup ast.func.name entry then
  here over to ast.func.address
  dup ast.func.args ast.args.totsize over ast.func.locsize
  vmprelude, dup genchildren
  ast.func.cursf not _assert \ all decl nodes have been "processed"
  _debug if current here current - spit nl> then ;
:w ( Return ) genchildren vmret, ;
:w ( Constant ) ast.const.value const>op ;
:w ( Statements )
  \ we run ops$ between each statement to discard any unused Result
  dup firstchild begin ?dup while dup gennode ops$ nextsibling repeat
  dup ast.stmts.funcbody? if
    lastchild ?dup if nodeid AST_RETURN = not if vmret, then else vmret, then
  else drop then ;
:w ( ArgSpecs )
  dup ast.args.totsize over parentnode to ast.func.cursf
  dup genchildren
  parentnode dup ast.func.locsize swap to ast.func.cursf ;
:w ( Ident ) dup identfind ?dup if ( inode dnode )
    nip decl>op else ( inode )
    ast.ident.name find ?dup _assert mem>op then ;
:w ( UnaryOp )
  _debug if ." unaryop: " dup printast nl> .ops then
  dup genchildren
  ast.uop.opid uopgentbl swap wexec ;
:w ( PostfixOp )
  dup genchildren
  ast.pop.opid popgentbl swap wexec ;
\ See "Binary op resolution strategy" in opening comment
:w ( BinaryOp )
  _debug if ." binop: " dup printast nl> then
  selectedop >r ( node ) >r
  r@ bopgentblpre r@ ast.bop.opid wexec ( node )
  firstchild dup nextsibling swap ( n2 n1 )
  over needs2ops? if \ n2 == 2ops
    \ Resolve n2 before n1
    swap gennode \ result in op1
    dup needs2ops? if \ both need 2ops
      oppush rot gennode selop2 oppop else
      selop2 gennode op1<>op2 then
  else \ nothing special needed, regular resolution
    selop1 gennode selop2 gennode then
  bopgentblpost r> ast.bop.opid wexec
  r> ( selectedop ) if op1<>op2 else selop1 then ;
\ TODO: this doesn't work with lvalues yet
:w ( List )
  dup childcount dup 1+ 4 * scratchallot dup >r ( node len a )
  over >r tuck ! 4 + swap firstchild begin ( a node )
    dup ast.const.value ( a node value ) rot tuck ! ( node a )
    4 + swap nextsibling next ( a node ) 2drop
  r> constarray>op ;
:w ( If )
  firstchild ?dup not if _err then dup gennode ( exprnode )
  vmjz[, swap ( jump_addr exprnode ) ops$
  nextsibling ?dup not if _err then dup gennode ( jump_addr condnode )
  nextsibling ?dup if ( jump_addr elsenode )
    vmjmp[, ( ja1 enode ja2 ) rot ]vmjmp ( enode ja2 )
    swap gennode ( ja2 ) then ( jump_addr ) ]vmjmp ;
:w ( StrLit )
  vmjmp[, here ( snode jaddr saddr )
  rot ast.strlit.value dup c@ ( jaddr saddr str len )
  1+ move, ( jaddr saddr ) const>op ]vmjmp ;
:w ( FunCall )
  \ Resolve address node
  0 to lastidentfound
  dup firstchild gennode \ op has call address
  lastidentfound swap
  oppush rot
  \ pass arguments
  dup childcount 1- 4 * callargallot,
  firstchild nextsibling ?dup if -4 swap begin ( cursf+ argnode )
    dup selop1 gennode swap dup selop2 ps+>op op1<>op2 vmmov, selop1 opdeinit
    4 - swap nextsibling ?dup not until drop then
  \ call
  oppop vmcall, ?dup if dup nodeid AST_FUNCTION = if
    ast.func.type if selop1 vmpspop, then else drop then then ;
:w ( For )
  firstchild dup _assert dup gennode ops$ \ initialization
  here swap
  nextsibling dup _assert dup gennode \ control
  vmjz[, swap ops$
  nextsibling dup _assert dup gennode ops$ \ adjustment
  nextsibling dup _assert gennode \ body
  swap vmjmp, ]vmjmp ;
:w ( PSPush ) firstchild dup _assert gennode vmpspush, ;
:w ( PSPop ) drop vmpspop, ;

: _ ( node -- ) gentbl over nodeid wexec ;
current to gennode
