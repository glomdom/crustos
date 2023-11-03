bootfile fs/fatlo.f

\ The "low" part of a FAT12/FAT16 Filesystem Implementation

\ This is a subset of FAT12/FAT16. It is designed to be embedded
\ right after `boot.f` and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide a read-only access to FAT12/FAT16 volumes. The "write"
\ part is in fs/fat. This unit is more than strictly necessary to get through
\ the boot process, but it is organized thus so that we can leverage a maximum
\ of logic from this unit in fs/fat. All in all, "read and core stucture" is
\ here, "write" is in fs/fat.

\ This unit has access to a very small set of words, that is, words implemented
\ by boot.f as well as (drv@) and drvblksz from the "drive" protocol, which is
\ implemented by a driver that is also inserted in the boot sequence.

\ See fs/fat.f for complete implementation details.

create bpb 0 here (drv@) $18 allot

: BPB_BytsPerSec bpb $0b + w@ ;
: BPB_SecPerClus bpb $0d + c@ ;
: BPB_RsvdSecCnt bpb $0e + w@ ;
: BPB_NumFATs bpb $10 + c@ ;
: BPB_RootEntCnt bpb $11 + w@ ;
: BPB_TotSec16 bpb $13 + w@ ;
: BPB_FATSz16 bpb $16 + w@ ;
: RootDirSectors
  BPB_RootEntCnt 32 * BPB_BytsPerSec /mod swap if 1+ then ;
: FirstDataSector BPB_RsvdSecCnt BPB_NumFATs BPB_FATSz16 * + RootDirSectors + ;
: FirstSectorOfCluster ( n -- sec )
  dup << BPB_BytsPerSec BPB_FATSz16 * >= if abort" cluster out of range" then
  1- 1- BPB_SecPerClus * FirstDataSector + ;
: FirstRootDirSecNum BPB_RsvdSecCnt BPB_NumFATs BPB_FATSz16 * + ;
: ClusterSize BPB_SecPerClus BPB_BytsPerSec * ;
: DataSec BPB_TotSec16 BPB_FATSz16 BPB_NumFATs * BPB_RsvdSecCnt + RootDirSectors + - ;
: CountOfClusters DataSec BPB_SecPerClus / ;
: FAT12? CountOfClusters 4085 < ;

create fatbuf( BPB_BytsPerSec allot
here const )fatbuf
0 value bufsec \ sector number of current buf
0 value bufseccnt \ number of sectors ahead for sequential read
0 value bufcluster \ cluster number of current buf

: readsector ( sec cnt -- ) to bufseccnt dup to bufsec fatbuf( (drv@) ;

: FAT12' ( cluster -- 'entry )
  dup >> + BPB_BytsPerSec /mod
  BPB_RsvdSecCnt + 0 readsector
  fatbuf( + ;
: FAT12@ ( cluster -- entry )
  dup FAT12' w@ swap 1 and if 4 rshift else $fff and then ;
: FAT16' ( cluster -- entry )
  << BPB_BytsPerSec /mod
  BPB_RsvdSecCnt + 0 readsector
  fatbuf( + ;
: FAT16@ ( cluster -- entry ) FAT16' w@ ;
: FAT@ ( cluster -- entry ) FAT12? if FAT12@ else FAT16@ then ;

: EOC? ( cluster -- f )
  FAT12? if $ff8 else $fff8 then tuck and = ;

: nextsector? ( -- f )
  bufseccnt if
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

\ Dummy entry so that we can reference the root directory as a "directory"
create rootdirentry( DIRENTRYSZ allot0

\ Directory entry of currently selected directory. If first byte is 0, this
\ means that we're on the root dir
create curdir( DIRENTRYSZ allot0

create fnbuf( FNAMESZ allot
here const )fnbuf

: upcase ( c -- c ) dup 'a' - 26 < if $df and then ;
: fnbufclr fnbuf( FNAMESZ SPC fill ;

: _ ( -- direntry-or-0 )
  fatbuf( begin
    dup )fatbuf < while
    fnbuf( over DIR_Name []= not while DIRENTRYSZ + repeat
    else drop 0 then ;

\ Find current fnbuf( in current directory buffer and return a directory entry
: findindir ( -- direntry )
  begin
    _ ?dup not while nextsector? not if abort" file not found" then
  repeat ;

\ Read specified `direntry` in fatbuf(
: readdir ( direntry -- )
  DIR_Cluster ?dup if \ not root entry
    dup FirstSectorOfCluster BPB_SecPerClus else \ root entry
    1 FirstRootDirSecNum RootDirSectors then
  readsector to bufcluster ;

\ Find the parent directory of `path`, that is - go up directories in `path` until
\ the last element is reached, but don't look for that last element, return
\ directory's direntry instead. As this word returns, fnbuf( will be set with
\ the last element of the path.
\ If path starts with "/", we start from root directory. Otherwise, `curdir`.
: fatfindpathdir ( path -- direntry )
  A>r fnbufclr fnbuf( >A c@+
  over c@ '/' = if 1- >r 1+ rootdirentry( else >r curdir( then
  readdir begin
    c@+ case
      '.' of =
        A> fnbuf( = A> 1- c@ '.' = or if
          '.' Ac!+ else fnbuf( 8 + >A then
      endof
      '/' of = findindir readdir fnbufclr fnbuf( >A endof
      r@ upcase Ac!+ A> )fnbuf = if abort" filename too long" then
    endcase
  next r>A ;

: fatfindpath ( path -- direntry ) fatfindpathdir drop findindir ;

\ Change current directory to `path`
: fatchdir ( path -- )
  fatfindpath curdir( DIRENTRYSZ move ;

\ File cursor
\ 12b IO handler prelude
\ 4b flags. all zeroes = free cursor
\    b0 = used
\    b1 = buffer is dirty
\ 4b current cluster in buf 0=nothing. the cluster is not actually read
\    until the first position of the cluster is needed.
\ 4b current cluster index. -1=nothing
\ 4b offset, on disk, of direntry
\ 4b cur pos (offset from beginning of file)
\ 4b file size
\ Xb current cluster X=ClusterSize
10 const FCURSORCNT \ Maximum number of opened files
: FCursorSize ClusterSize 36 + ;
: FCUR_flags ( fcur -- n ) 12 + @ ;
: FCUR_free? ( fcur -- f ) FCUR_flags not ;
: FCUR_dirty? ( fcur -- f ) FCUR_flags 2 and ;
: FCUR_flags! ( n fcur -- ) 12 + ! ;
: FCUR_cluster ( fcur -- n ) 16 + @ ;
: FCUR_cluster! ( n fcur -- ) 16 + ! ;
: FCUR_clusteridx ( fcur -- n ) 20 + @ ;
: FCUR_clusteridx! ( n fcur -- n ) 20 + ! ;
: FCUR_pos ( fcur -- n ) 28 + @ ;
: FCUR_pos! ( n fcur -- n ) 28 + ! ;
: FCUR_pos+ ( n fcur -- ) 28 + +! ;
: FCUR_size ( fcur -- n ) 32 + @ ;
: FCUR_size! ( n fcur -- ) 32 + ! ;
: FCUR_buf( ( fcur -- a ) 36 + ;
: FCUR_)buf ( fcur -- a ) FCUR_buf( ClusterSize + ;
: FCUR_bufpos ( fcur -- a ) dup FCUR_pos ClusterSize mod swap FCUR_buf( + ;
: FCUR_dirent ( fcur -- dirent )
  24 + @ BPB_BytsPerSec /mod 1 readsector fatbuf( + ;
: FCUR_cluster0 ( fcur -- cl ) FCUR_dirent DIR_Cluster ;

create fcursors( FCursorSize FCURSORCNT * allot0

: findfreecursor ( -- fcursor )
  FCURSORCNT >r fcursors( begin
    dup FCUR_free? if r~ exit then FCursorSize + next
  abort" out of file cursors" ;

\ Read multiple sectors in buf
: readsectors ( sec u buf -- )
  A>r swap >r swap >A begin
    A> over (drv@) A+ drvblksz + next drop r>A ;

: readcluster ( cluster dst -- )
  over 2 - $fff6 > if abort" cluster out of range" then
  swap FirstSectorOfCluster swap BPB_SecPerClus swap readsectors ;

\ Set `fcursor` to `pos`. If new `pos` crosses cluster boundaries compared to current
\ `pos`, flush current buffer and read a new sector from disk.
: fatseek ( pos fcursor -- )
  over 0< if abort" can't seek to negative pos" then
  over ClusterSize / over FCUR_clusteridx = not if
    dup dup 8 + @ execute >r
    dup ClusterSize / dup r@ FCUR_clusteridx!
    r@ FCUR_cluster0
    swap ?dup if >r begin FAT@ next then
    dup r@ FCUR_buf( readcluster
    r@ FCUR_cluster! r>
  then FCUR_pos! ;

: fatreadbuf ( n fcursor -- a? n )
  dup >r FCUR_size r@ FCUR_pos -
  dup 1- 0< if 2drop r~ 0 exit then
  min
  r@ FCUR_pos r@ fatseek
  r@ FCUR_bufpos r@ FCUR_)buf over -
  rot min
  dup r> FCUR_pos+ ;

: fatopenlo ( path -- fcursor )
  fatfindpath findfreecursor >r
  ['] fatreadbuf r@ ! ['] abort r@ 4 + ! ['] drop r@ 8 + !
  0 r@ FCUR_cluster! 1 r@ FCUR_flags!
  dup fatbuf( - bufsec BPB_BytsPerSec * + r@ 24 + !
  -1 r@ FCUR_clusteridx! 0 r@ FCUR_pos!
  DIR_FileSize r@ FCUR_size! r> ;

: fatclose ( fcursor ) dup dup 8 + @ execute 0 swap FCUR_flags! ;
