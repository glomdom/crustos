\ Tests for the C Compiler AST

?f<< tests/harness.f
?f<< cc/cc.f

testbegin

ccopen tests/cc/test.c parseast ccclose

curunit firstchild dup nodeid AST_FUNCTION #eq ( fnode )
dup ast.func.name S" retconst" s= #
firstchild nextsibling dup nodeid AST_STATEMENTS #eq ( snode )
firstchild dup nodeid AST_RETURN #eq ( rnode )
firstchild dup nodeid AST_CONSTANT #eq ( cnode )
ast.const.value 42 #eq

testend
