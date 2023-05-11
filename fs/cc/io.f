\ C Compiler I/O Words

0 value ccfd
: cc< ccfd fread ;

0 value putback
: _cc< ( -- c ) putback ?dup if 0 to putback else cc< then ;
: ccopen word fopen to ccfd ;
: ccclose ccfd fclose 0 to ccfd ;
