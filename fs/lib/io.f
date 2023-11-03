\ I/O Aliases

\ Defines stdin (and soon stdout) which is used by many programs and words as
\ their main I/O. In addition to those words, this subsystem also implements
\ some convenience words to manage where they point to.

?f<< /lib/str.f

alias in< stdin ( -- c )

create _buf( STR_MAXSZ allot
here value _)buf

\ Read stdin for a maximum of STR_MAXSZ-1 characters until LF is encountered,
\ then return a string representing that read line. The LF character is not
\ included. Aborts on LNSZ overflow.
: readline ( -- str )
  A>r _buf( 1+ >A begin ( )
    A> _)buf = if abort" readline overflow" then
    in< dup LF = not while Ac!+ repeat drop
  A> _buf( - 1- ( len ) _buf( c! _buf( ( str ) r>A ;
