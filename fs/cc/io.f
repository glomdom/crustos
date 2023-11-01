\ C Compiler I/O Words

?f<< lib/io.f

alias stdin cc<

0 value putback
: _cc< ( -- c ) putback ?dup if 0 to putback else cc< then ;
