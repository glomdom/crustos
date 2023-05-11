\ C Compiler Abstract Syntax Tree
\ requires cc/tok.f and cc/ops.f

\ Unary Operators
7 const UOPSCNT
UOPSCNT stringlist UOPTlist "-" "~" "!" "&" "*" "++" "--"

: uopid ( tok -- opid? f )
  UOPTlist sfind dup 0< if drop 0 else 1 then ;
: uoptoken ( opid -- tok ) UOPTlist slistiter ;

\ Postfix Operators
2 const POPSCNT
POPSCNT stringlist POPTlist "++" "--"

: popid ( tok -- opid? f )
  POPTlist sfind dup 0< if drop 0 else 1 then ;
: poptoken ( opid -- tok ) POPTlist slistiter ;

\ Binary Operators
13 const BOPSCNT
BOPSCNT stringlist BOPTlist
"+" "-" "*" "/" "<" ">" "<=" ">=" "==" "!=" "&&" "||" "="

create bopsprectbl  1 c, 1 c, 0 c, 0 c, 2 c, 2 c, 2 c, 2 c,
                    3 c, 3 c, 4 c, 4 c, 5 c,

: bopid ( tok -- opid? f )
  BOPTlist sfind dup 0< if drop 0 else 1 then ;
: bopprec ( opid -- precedence ) BOPSCNT min bopsprectbl + c@ ;
: boptoken ( opid -- tok ) BOPTlist slistiter ;

15 const ASTIDCNT
0 const AST_DECLARE
1 const AST_UNIT
2 const AST_FUNCTION
3 const AST_RETURN
4 const AST_CONSTANT
5 const AST_STATEMENTS
6 const AST_ARGSPECS
7 const AST_LVALUE
8 const AST_UNARYOP
9 const AST_POSTFIXOP
10 const AST_BINARYOP
11 const AST_LIST
12 const AST_IF
\ 13 unused
14 const AST_FUNCALL

\ It's important that decl.name and func.name have the same offset.
\ Poor man's polymorphism..
NODESZ      ufield ast.decl.name
NODESZ 4 +  ufield ast.decl.type
NODESZ 8 +  ufield ast.decl.nbelem
NODESZ 12 + ufield ast.decl.sfoff       \ for global vars, this is an absolute address
NODESZ      ufield ast.func.name
NODESZ 4 +  ufield ast.func.sfsize
NODESZ 8 +  ufield ast.func.type
NODESZ 12 + ufield ast.func.address
NODESZ      ufield ast.const.value
NODESZ      ufield ast.lvalue.name
NODESZ      ufield ast.uop.opid
NODESZ      ufield ast.pop.opid
NODESZ      ufield ast.bop.opid
NODESZ      ufield ast.funcall.funcname

ASTIDCNT stringlist astidnames
"declare" "unit" "function" "return" "constant" "stmts" "args" "lvalue"
"unaryop" "postop" "binop" "list" "if" "_" "call"

0 value curunit

: idname ( id -- str ) astidnames slistiter ;

: ast.unit.find ( name -- fnode-or-0 )
  curunit firstchild begin
    ?dup while
    over over ast.func.name s= if
      nip exit then
    nextsibling repeat drop 0 ;

\ Number of bytes required to hold this variable declaration in memory.
: ast.decl.totsize ( dnode -- size-in-bytes )
  dup ast.decl.type ( dnode type )
  typesize swap ast.decl.nbelem ( nbelem )
  1 max * ;

: ast.decl.isarg? ( dnode -- f ) parentnode nodeid AST_ARGSPECS = ;
: ast.decl.isglobal? ( dnode -- f ) parentnode nodeid AST_UNIT = ;

: _ ( name args-or-stmts -- dnode-or-0 )
  firstchild begin ( name node )
    ?dup while ( name node )
    dup nodeid AST_DECLARE = if
      over over ast.decl.name s= if ( name node )
        nip exit then then
    nextsibling repeat ( name ) drop 0 ;

: ast.func.finddecl ( name fnode -- dnode-or-0 )
  firstchild 2dup _ ?dup if
    nip nip else nextsibling _ then ;

: ast.func.argsize ( fnode -- size-in-bytes )
  firstchild firstchild 0 begin
    over while
    over nodeid AST_DECLARE = _assert
    over ast.decl.totsize +
    swap nextsibling swap repeat nip ;

: _[ '[' emit ;
: _] ']' emit ;

ASTIDCNT wordtbl astdatatbl ( node -- node )
:w ( Declare ) _[
  dup ast.decl.type printtype spc>
  dup ast.decl.name stype
  dup ast.decl.nbelem dup 1 > if _[ .x _] else drop then spc>
  dup ast.decl.sfoff .x1 _] ;
'w noop ( Unit )
:w ( Function ) _[
  dup ast.func.type printtype spc>
  dup ast.func.name stype _] ;
'w noop ( Return )
:w ( Constant ) _[ dup ast.const.value .x _] ;
'w noop ( Statements )
'w noop ( ArgSpecs )
:w ( LValue ) _[ dup ast.lvalue.name stype _] ;
:w ( UnaryOp ) _[ dup ast.uop.opid uoptoken stype _] ;
:w ( PostfixOp ) _[ dup ast.pop.opid poptoken stype _] ;
:w ( BinaryOp ) _[ dup ast.bop.opid boptoken stype _] ;
'w noop ( Unused )
'w noop ( If )
'w noop ( Unused )
:w ( FunCall ) _[ dup ast.funcall.funcname stype _] ;

: printast ( node -- )
  ?dup not if ." null" exit then
  dup nodeid dup AST_FUNCTION = if nl> then idname stype
  astdatatbl over nodeid wexec
  firstchild ?dup if
    '(' emit begin
      dup printast nextsibling dup if ',' emit then ?dup not until
    ')' emit then ;

: newnode ( parent nodeid -- newnode )
  createnode ( parent node ) dup rot addnode ( node ) ;

: _err ( -- ) abort" parsing error" ;
: _assert ( f -- ) not if _err then ;

: isType? ( tok -- f ) S" int" s= ;
: expectType ( tok -- type ) parseType not if _err then ( type ) ;
: expectConst ( tok -- n ) dup parse if nip else _err then ;
: isIdent? ( tok -- f )
  dup 1+ c@ identifier1st? not if drop 0 exit then
  c@+ >r begin ( a )
    c@+ identifier? not if r~ drop 0 exit then next drop 1 ;
: expectIdent ( tok -- tok ) dup isIdent? _assert ;
: expectChar ( tok c -- )
  over 1+ c@ = _assert dup c@ 1 = _assert drop ;
: read; ( -- ) nextt ';' expectChar ;

\ Parse Words

alias noop parseExpression ( tok -- node )

: parseList
  AST_LIST createnode nextt dup S" }" s= if drop exit then
  begin
    case
      of isIdent?
        AST_LVALUE createnode swap , over addnode endof
      of parse
        AST_CONSTANT createnode swap , over addnode endof
      _err
    endcase

    nextt
    case
      S" }" of s= r~ exit endof
      S" ," of s= endof
    endcase

  nextt again ;

: parsePostfixOp ( tok lvnode -- node )
  over S" [" s= if
    nip AST_BINARYOP createnode 0 ,
    tuck addnode
    AST_CONSTANT createnode nextt parse _assert ,
    nextt ']' expectChar
    over addnode
    AST_UNARYOP createnode 4 ,
    tuck addnode
  else
    over popid if
      AST_POSTFIXOP createnode swap ,
      tuck addnode nip
    else swap to nexttputback then then ;

\ A Factor can be:
\ 1. a constant
\ 2. an lvalue
\ 3. a unaryop/postfixop containing a factor
\ 4. a function call
: parseFactor ( tok -- node-or-0 )
  case
  S" (" of s= ( )
    nextt parseExpression nextt ')' expectChar endof
  of uopid ( opid )
    AST_UNARYOP createnode swap , ( opnode )
    nextt parseFactor ?dup _assert over addnode ( opnode ) endof
  of isIdent? ( )
    r@ nextt ( prevtok newtok ) dup S" (" s= if                   \ FunCall
      drop AST_FUNCALL createnode swap , begin ( node )
        nextt dup parseFactor ?dup while \ an argument
        nip over addnode
        nextt dup S" ," s= if drop else to nexttputback then
      repeat ( tok ) ')' expectChar
    else
      swap AST_LVALUE createnode swap , parsePostfixOp
    then
  endof
  r@ parse if AST_CONSTANT createnode swap , else 0 then
  endcase ;

\ An expression can be 2 things:
\ 1. a factor
\ 2. a binaryop containing two expressions
: _ ( tok -- exprnode ) ( parseExpression )
  parseFactor ?dup _assert nextt ( factor nexttok )
  dup bopid if ( factor tok binop )
    nip ( factor binop ) AST_BINARYOP createnode swap , ( factor node )
    tuck addnode nextt ( binnode tok )

    \ consume tokens until binops stop coming
    begin ( bn tok )
      parseFactor ?dup _assert nextt ( bn factor tok )
      dup bopid while ( bn fn tok bopid )
      nip AST_BINARYOP createnode swap , ( bn1 fn1 bn2 )

      \ precedence
      rot over ast.bop.opid bopprec
      over ast.bop.opid bopprec < if
        rot> tuck addnode dup rot addnode
      else
        rot over addnode over addnode
      then

      nextt
    repeat

    rot> over addnode swap
    \ bn not result, rootnode is
    swap rootnode swap
  then

  to nexttputback ;

current to parseExpression

: parseType* ( type -- type tok )
  begin nextt dup S" *" s= while drop type*lvl+ repeat ;

: parseNbelem ( tok -- nblem-or-0 )
  dup S" [" s= if
    drop nextt parse _assert nextt ']' expectChar else
    to nexttputback 0 then ;

: parseDeclare ( type parentnode -- dnode )
  AST_DECLARE newnode
  swap parseType*
  expectIdent , ,
  nextt parseNbelem ,
  dup AST_FUNCTION parentnodeid ?dup _assert
  dup ast.func.sfsize , over ast.decl.totsize swap to+ ast.func.sfsize ;

: parseDeclareInit ( dnode tok -- node )
  dup S" =" s= not if ';' expectChar drop exit then
  drop nextt dup S" {" s= if
    drop parseList else
    parseExpression then
  read; swap addnode ;

: parseArgSpecs ( funcnode -- )
  AST_ARGSPECS newnode nextt
  dup S" )" s= if 2drop exit then
  begin ( argsnode tok )
    expectType over parseDeclare drop
    nextt dup S" )" s= not while
    ',' expectChar nextt repeat 2drop ;

alias noop parseStatements ( funcnode -- )

2 stringlist statementnames "return" "if"
2 wordtbl statementhandler ( snode -- snode )
:w ( return )
  dup AST_RETURN newnode ( snode rnode )
  nextt dup S" ;" s= if
    2drop else
    parseExpression read; ( snode rnode expr ) swap addnode
  then ( snode ) ;
:w ( if ) dup AST_IF newnode ( snode ifnode )
  nextt '(' expectChar
  nextt parseExpression ( sn ifn expr ) over addnode
  nextt ')' expectChar
  dup parseStatements ( snode ifnode )
  nextt dup S" else" s= if ( sn ifn tok )
    drop parseStatements else
    to nexttputback drop then ;

: _ ( parentnode -- )
  nextt '{' expectChar AST_STATEMENTS newnode nextt
  begin
    dup S" }" s= not while
    dup statementnames sfind dup 0< if
      drop dup parseType if
        nip over parseDeclare nextt parseDeclareInit else
        parseExpression over addnode read; then
    else nip statementhandler swap wexec then

    nextt repeat 2drop ;
current to parseStatements

\\ Parse the next element in a `Unit` node
: parseUnit ( unitnode tok -- )
  parseType _assert parseType*
  expectIdent rot nextt case
    S" (" of s=
      AST_FUNCTION newnode rot> , 0 , , 0 ( address ) ,
      dup parseArgSpecs parseStatements
    endof

    AST_DECLARE newnode rot> , ,
    r@ parseNbelem , 0 ,
    nextt parseDeclareInit
  endcase ;

: parseast ( -- )
  AST_UNIT createnode dup to curunit
  nextt? ?dup not if exit then begin
    over swap parseUnit nextt? ?dup not until drop ;