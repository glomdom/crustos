\ The "low" part of a FAT12/FAT16 implementation

\ This is a subset of a FAT12/FAT16 implementation. It is designed to be
\ embedded in the boot sequence and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide a read-only access to FAT12/FAT16 volumes. The "write"
\ part is in fs/fat. This unit is more than strictly necessary to get through
\ the boot process, but it is organized thus so that we can leverage a maximum
\ of logic from this unit in fs/fat. All in all, "read and core stucture" is
\ here, "write" is in fs/fat.

\ This unit has access to a very small set of words, that it, words implemented
\ by boot.fs as well as (drv@) and drvblksz from the "drive" protocol, which is
\ implemented by a driver that is also inserted in the boot sequence.

\ See fs/fat.fs for complete implementation details.

create bpb 0 here (drv@) $18 allot

: BPB_BytsPerSec bpb $0b + w@ ;
: BPB_SecPerClus bpb $0d + c@ ;
: BPB_RsvdSecCnt bpb $0e + w@ ;
: BPB_NumFATs bpb $10 + c@ ;
: BPB_RootEntCnt bpb $11 + w@ ;
: BPB_TotSec16 bpb $13 + w@ ;
: BPB_FATSz16 bpb $16 + w@ ;
: RootDirSectors
  BPB_RootEntCnt 32 * BPB_BytsPerSec /mod ( r q ) swap if 1+ then ;
: FirstDataSector BPB_RsvdSecCnt BPB_NumFATs BPB_FATSz16 * + RootDirSectors + ;
: FirstSectorOfCluster ( n -- sec )
  dup << BPB_BytsPerSec BPB_FATSz16 * >= if abort" cluster out of range" then
  1- 1- BPB_SecPerClus * FirstDataSector + ;
: FirstRootDirSecNum BPB_RsvdSecCnt BPB_NumFATs BPB_FATSz16 * + ;
: ClusterSize BPB_SecPerClus BPB_BytsPerSec * ;
: DataSec
  BPB_TotSec16 BPB_FATSz16 BPB_NumFATs * BPB_RsvdSecCnt + RootDirSectors + - ;
: CountOfClusters DataSec BPB_SecPerClus / ;
: FAT12? CountOfClusters 4085 < ;

\ Buffer for either reading FAT sectors or Directory contents. It is one sector
\ in size and knows the number of sequential sector read it has in front of it.
create fatbuf( BPB_BytsPerSec allot
here const )fatbuf
0 value bufsec \ sector number of current buf
0 value bufseccnt \ number of sectors ahead for sequential read
0 value bufcluster \ cluster number of current buf

\ "cnt" is the number of sectors ahead of "sec" that are available for a
\ seqential read.
: readsector ( sec cnt -- ) to bufseccnt dup to bufsec fatbuf( (drv@) ;

: FAT12' ( cluster -- 'entry )
  dup >> + ( cl offset ) BPB_BytsPerSec /mod ( cl secoff sec )
  BPB_RsvdSecCnt + 0 readsector ( cl secoff )
  fatbuf( + ;
: FAT12@ ( cluster -- entry )
  dup FAT12' w@ swap 1 and if 4 rshift else $fff and then ;
: FAT16' ( cluster -- 'entry )
  << ( offset ) BPB_BytsPerSec /mod ( secoff sec )
  BPB_RsvdSecCnt + 0 readsector ( secoff )
  fatbuf( + ;
: FAT16@ ( cluster -- entry ) FAT16' w@ ;
: FAT@ ( cluster -- entry ) FAT12? if FAT12@ else FAT16@ then ;

: EOC? ( cluster -- f )
  FAT12? if $ff8 else $fff8 then tuck and = ;

\ Read next sector if a sequential read is available, else return false.
: nextsector? ( -- f )
  bufseccnt if \ still on a sector streak
    bufseccnt 1+ bufseccnt 1- readsector 1
  else \ out of sector, try next cluster
    bufcluster FAT@ dup EOC? if drop 0 else \ we have another cluster
    dup to bufcluster FirstSectorOfCluster BPB_SecPerClus readsector 1
  then then ;

32 const DIRENTRYSZ
11 const FNAMESZ
: DIR_Name ( direntry -- sa sl ) FNAMESZ ;
: DIR_Cluster ( direntry -- cluster ) 26 + w@ ;
: DIR_Cluster! ( cluster direntry -- ) 26 + w! ;
: DIR_FileSize ( direntry -- sz ) 28 + @ ;
: DIR_FileSize! ( sz direntry -- sz ) 28 + ! ;

\ Just a dummy entry so that we can reference the root directory as a "direntry"
create rootdirentry( DIRENTRYSZ allot0
\ directory entry of currently selected directory. If first byte is 0, this
\ means that we're on the root dir
create curdir( DIRENTRYSZ allot0
create fnbuf( FNAMESZ allot
here const )fnbuf

: upcase ( c -- c ) dup 'a' - 26 < if $df and then ;
: fnbufclr fnbuf( FNAMESZ SPC fill ;
: fnbuf! ( name -- )
  fnbufclr dup S" ." s= over S" .." s= or if
    c@+ ( a len ) fnbuf( swap move exit then
  A>r c@+ >r >A fnbuf( begin ( dst )
    Ac@+ dup '.' = if
      2drop fnbuf( 8 + else
      upcase swap c!+ then ( dst+1 )
    dup )fnbuf = if leave then next drop r>A ;

: _ ( -- direntry-or-0 )
  fatbuf( begin ( a )
    dup )fatbuf < while ( a )
    fnbuf( over DIR_Name []= not while ( a ) DIRENTRYSZ + repeat
    ( success ) else ( not found ) drop 0 then ( a ) ;

\ Find current fnbuf( in current dir buffer and return a dir entry.
: findindir ( -- direntry )
  begin
    _ ?dup not while nextsector? while
  repeat ( not found ) 0 then ;

\ Read specified "direntry" in fatbuf(
: readdir ( direntry -- )
  DIR_Cluster ?dup if \ not root entry
    dup FirstSectorOfCluster BPB_SecPerClus else \ root entry
    1 FirstRootDirSecNum RootDirSectors then ( cluster sec cnt )
  readsector ( cluster ) to bufcluster ;

\ Get DirEntry address from FS ID "id"
: getdirentry ( id -- direntry )
  ?dup if
    BPB_BytsPerSec /mod ( offset sec ) 1 readsector ( off ) fatbuf( +
  else rootdirentry( then ;

\ Get ID for direntry
: getid ( direntry -- id ) fatbuf( - bufsec BPB_BytsPerSec * + ;

: fatchild ( dirid name -- id-or-0 )
  fnbuf! getdirentry readdir findindir dup if getid then ;

\ File cursor
\ 12b IO handle prelude
\ 8b File handle prelude
\ 4b flags. all zeroes = free cursor
\    b0 = used
\    b1 = buffer is dirty
\ 4b current cluster in buf 0=nothing. the cluster is not actually read
\    until the first position of the cluster is needed.
\ 4b current cluster index, -1=nothing.
\ 4b offset, on disk, of direntry
\ 4b cur pos (offset from beginning of file)
\ 4b file size
\ Xb current cluster X=ClusterSize
10 const FCURSORCNT \ maximum number of opened files
: FCursorSize ClusterSize 44 + ;
: FCUR_flags ( fcur -- n ) 20 + @ ;
: FCUR_free? ( fcur -- f ) FCUR_flags not ;
: FCUR_dirty? ( fcur -- f ) FCUR_flags 2 and ;
: FCUR_flags! ( n fcur -- ) 20 + ! ;
: FCUR_cluster ( fcur -- n ) 24 + @ ;
: FCUR_cluster! ( n fcur -- ) 24 + ! ;
: FCUR_clusteridx ( fcur -- n ) 28 + @ ;
: FCUR_clusteridx! ( n fcur -- n ) 28 + ! ;
: FCUR_pos ( fcur -- n ) 36 + @ ;
: FCUR_pos! ( n fcur -- n ) 36 + ! ;
: FCUR_pos+ ( n fcur -- ) 36 + +! ;
: FCUR_size ( fcur -- n ) 40 + @ ;
: FCUR_size! ( n fcur -- ) 40 + ! ;
: FCUR_buf( ( fcur -- a ) 44 + ;
: FCUR_)buf ( fcur -- a ) FCUR_buf( ClusterSize + ;
: FCUR_bufpos ( fcur -- a ) dup FCUR_pos ClusterSize mod swap FCUR_buf( + ;
: FCUR_dirent ( fcur -- dirent ) 32 + @ getdirentry ;
: FCUR_cluster0 ( fcur -- cl ) FCUR_dirent DIR_Cluster ;

create fcursors( FCursorSize FCURSORCNT * allot0

: findfreecursor ( -- fcursor )
  FCURSORCNT >r fcursors( begin ( a )
    dup FCUR_free? if ( found! ) r~ exit then FCursorSize + next
  abort" out of file cursors!" ;

\ read multiple sectors in buf
: readsectors ( sec u buf -- )
  A>r swap >r swap >A begin ( buf )
    A> over (drv@) A+ drvblksz + next ( buf ) drop r>A ;

: readcluster ( cluster dst -- )
  over 2 - $fff6 > if abort" cluster out of range!" then
  swap FirstSectorOfCluster ( dst sec ) swap BPB_SecPerClus swap readsectors ;

\ set fcursor to pos. If new pos crosses cluster boundaries compared to current
\ pos, flush current buffer and read a new sector from disk.
: fatseek ( pos fcursor -- )
  over 0< if abort" can't seek to negative pos" then
  over ClusterSize / over FCUR_clusteridx = not if
    dup dup 8 + @ ( 'flush ) execute >r ( pos )
    dup ClusterSize / dup r@ FCUR_clusteridx! ( pos idx )
    r@ FCUR_cluster0 ( pos idx cl )
    swap ?dup if >r begin ( pos cl ) FAT@ next then ( pos cl )
    dup r@ FCUR_buf( readcluster ( pos cl )
    r@ FCUR_cluster! r> ( pos fc )
  then ( pos fcursor ) FCUR_pos! ;

: fatreadbuf ( n fcursor -- a? n )
  dup >r FCUR_size r@ FCUR_pos - ( n maxn )
  dup 1- 0< if ( EOF ) 2drop r~ 0 exit then
  min ( n ) \ make sure that n doesn't go over size
  r@ FCUR_pos r@ fatseek ( n )
  r@ FCUR_bufpos r@ FCUR_)buf over - ( n a nmax )
  rot min ( a n )
  dup r> FCUR_pos+ ( a n ) ;

: fatclose ( fcursor ) dup dup 8 + @ ( 'flush ) execute 0 swap FCUR_flags! ;

\ This is the "low" part. Complete open is finalized in fs/fat
: fatopenlo ( id -- hdl )
  getdirentry findfreecursor >r
  \ write IO handle prelude: readbuf, writebuf, flush
  ['] fatreadbuf r@ ! ['] abort r@ 4 + ! ['] drop r@ 8 + !
  \ write File handle prelude: fseek fclose
  ['] fatseek r@ 12 + ! ['] fatclose r@ 16 + !
  \ write the rest
  0 r@ FCUR_cluster! ( dirent ) 1 r@ FCUR_flags!
  dup fatbuf( - bufsec BPB_BytsPerSec * + ( dirent doffset ) r@ 32 + !
  -1 r@ FCUR_clusteridx! 0 r@ FCUR_pos!
  DIR_FileSize r@ FCUR_size! ( ) r> ;
