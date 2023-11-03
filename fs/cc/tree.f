\ C Compiler Tree Structure

20 const NODESZ
0 ufield nodeid
4 ufield parentnode
8 ufield firstchild
12 ufield nextsibling
16 ufield prevsibling

: rootnode ( n -- n ) dup parentnode if parentnode rootnode then ;

: nextnode ( ref node -- ref next )
  dup firstchild ?dup if nip else begin ( ref node )
    2dup = if drop 0 exit then
    dup nextsibling ?dup if nip exit then
    parentnode 2dup = until drop 0
  then ;
: nextnodeid ( ref node id -- ref node )
  >r begin nextnode dup not if r~ exit then dup nodeid r@ = until r~ ;
: parentnodeid ( node id -- node )
  >r begin parentnode dup not if r~ exit then dup nodeid r@ = until r~ ;

: lastchild ( node -- child )
  firstchild dup if begin dup nextsibling ?dup not if exit then nip again then ;
: nodedepth ( node -- n ) firstchild ?dup if nodedepth 1+ else 0 then ;
: childcount ( node -- n )
  0 swap firstchild ?dup if begin swap 1+ swap nextsibling ?dup not until then ;
: childindex ( child node -- idx )
  swap >r 0 swap firstchild begin
    ?dup while
    r@ over = not while
    swap 1+ swap nextsibling repeat
    drop r~ else abort" child not found" then ;
: createnode ( id -- node ) here >r , 16 allot0 r> ;
: addnode ( node parent -- )
  2dup swap to parentnode ( node parent )
  dup lastchild ?dup if ( n p lc )
    nip ( n lc ) 2dup to nextsibling swap to prevsibling
  else
    to firstchild then ;
: removenode ( node -- )
  dup parentnode firstchild over = if
    dup nextsibling over parentnode to firstchild
  else
    dup nextsibling over prevsibling to nextsibling then
  dup nextsibling if
    dup prevsibling swap nextsibling to prevsibling
  else drop then ;
