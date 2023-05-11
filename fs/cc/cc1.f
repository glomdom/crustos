\ C Compiler Stage 1
\ Requires cc/gen.f, cc/ast.f, asm.f and wordtbl.f

\ Compiles input coming from stdin and writes the result to here.
\ Aborts on error.
: cc1, ( -- )
  xhere$ xhere[ parseast curunit _debug if dup printast nl> then ]xhere
  gennode ;

: cc1<< ( -- ) word fopen dup [f<] to stdin cc1, fclose ;
