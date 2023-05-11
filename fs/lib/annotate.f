: (annotate) ( w -- w' )
  current dup preventry to current >r
  dup preventry r@ preventry!
  r@ swap preventry! r> ;

: annotate (annotate) drop ;

: [][]= ( a u a u -- f )
  rot over = if []= else 2drop drop 0 then ;

: has-name? ( w str -- f )
  c@+ rot wordname[] [][]= ;
