?f<< lib/str.f
?f<< lib/with.f

SPC value filter-delim

\ Internal State
create filter-buf $100 allot
0 value filter-str
alias abort filter-out

: filter-chunk
  filter-buf filter-str scontains if
    filter-buf ['] stype to' filter-out @ to' emit with
    filter-delim filter-out
  then
  0 filter-buf c! ;

: filter-char ( c -- )
  dup filter-delim = if drop
    filter-chunk
  else
    filter-buf sappend
  then ;

: with-filter-str ( w str -- )
  to filter-str
  0 filter-buf c!
  to' emit @ to filter-out
  ['] filter-char to' emit with filter-chunk ;

: filter ( "word" "query" -- ) ' word with-filter-str ;
