\\ Helper word to save and restore variables across function calls
: with ( w u addr -- ) dup >r dup @ >r ! execute r> r> ! ;
