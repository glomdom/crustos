\\ Helper word to save and restore variables across function calls
: with ( w u addr -- ) dup >r dup @ >r ! execute r> r> ! ;


\ Inline variant of `with`
\ ( u addr ) with[ ... ]with
: with[ [compile] ahead here swap ; immediate
: ]with exit, [compile] then litn compile rot> compile with ; immediate
