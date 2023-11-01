?f<< lib/annotate.f

create doc-magic 2 c, 127 c, 'D' c,

: _ doc-magic entry begin in< dup c, LF = until ;
' _ to \\

: add-doc ( w -- )
  begin current word? not while (annotate) repeat drop ;

: .doc ( w -- )
  preventry dup word? not if dup .doc then
  dup doc-magic has-name? if
    begin c@+ dup emit LF = until
  then drop ;

: doc ' .doc ;

\\ Create a new constant
' const add-doc
