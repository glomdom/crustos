\ The "low" part of a FAT12/FAT16 Filesystem Implementation

\ This is a subset of FAT12/FAT16. It is designed to be embedded
\ right after `boot.f` and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide fopen, fclose and fread. Nothing more. The rest of the
\ FAT12/FAT16 implementation is in fs/fat.f

\ This unit has access to a very small set of words, that is, words implemented
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
: FAT16'
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
: DIR_FileSize ( direntry -- sz ) 28 + @ ;

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
\ 2b first cluster ; 0 = free cursor
\ 2b current cluster in buf
\ 4b cur pos (offset from beginning of file)
\ 4b file size
\ Xb current cluster X=ClusterSize
10 const FCURSORCNT \ Maximum number of opened files
: FCursorSize ClusterSize 12 + ;
: FCUR_cluster0 ( fcur -- n ) w@ ;
: FCUR_cluster ( fcur -- n ) 2 + w@ ;
: FCUR_cluster! ( n fcur -- ) 2 + w! ;
: FCUR_pos ( fcur -- n ) 4 + @ ;
: FCUR_pos+ ( fcur -- n ) 4 + dup @ 1 rot +! ;
: FCUR_size ( fcur -- n ) 8 + @ ;
: FCUR_buf( ( fcur -- a ) 12 + ;

create fcursors( FCursorSize FCURSORCNT * allot0

: findfreecursor ( -- fcursor )
  FCURSORCNT >r fcursors( begin
    dup FCUR_cluster0 not if r~ exit then FCursorSize + next
  abort" out of file cursors" ;

\ Read multiple sectors in buf
: readsectors ( sec u buf -- )
  A>r swap >r swap >A begin
    A> over (drv@) A+ drvblksz + next drop r>A ;

: readcluster ( cluster dst -- )
  swap FirstSectorOfCluster swap BPB_SecPerClus swap readsectors ;

\ Opens the specified `direntry` into one of the free cursors and returns
\ the cursor
: openfile ( direntry -- fcursor )
  findfreecursor >r
  dup DIR_Cluster dup r@ FCUR_buf( readcluster
  dup r@ w! r@ FCUR_cluster!
  0 r@ 4 + ! DIR_FileSize r@ 8 + ! r> ;

: fatopen ( path -- fcursor ) fatfindpath openfile ;

: fatgetc ( fcursor -- c )
  dup FCUR_pos over FCUR_size = if drop -1 exit then
  dup FCUR_pos+ ClusterSize mod over FCUR_buf( + c@
  over FCUR_pos ClusterSize mod not if
    over FCUR_cluster FAT@
    dup EOC? if drop else
      dup 2 < if abort" cluster out of range" then
      rot 2dup FCUR_cluster!
      tuck FCUR_buf( readcluster swap then
  then nip ;

: fatclose ( fcursor ) 0 swap w! ;
