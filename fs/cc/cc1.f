\ C Compiler Stage 1
\ Requires cc/gen.f, cc/ast.f, asm.f and wordtbl.f

\ compiles input coming from the `cc<` alias (defautls to `in<`) and writes the
\ result to here
\
\ aborts on error

: cc1, ( -- )
  xhere$ xhere[ parseast curunit _debug if dup printast nl> then ]xhere
  gennode ;
: cc1<< ( -- ) ccopen cc1, ccclose ;
