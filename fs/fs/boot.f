\ Boot Filesystem Implementation

\ This is a subset of FAT16. It is designed to be embedded
\ right after `boot.f` and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide fopen and fread. Nothing more. The rest of the
\ FAT16 implementation is in fs/fat16.f

\ This unit has access to a very small set of words, that is, words implemented
\ by boot.f as well as the `drive` protocol, which is implemented by a driver
\ that is inserted between boot.f and this unit.

$18 const BPBSZ
create bpb BPBSZ allot
0 drv@ drvbuf( bpb BPBSZ move

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
: FirstSectorOfCluster 1- 1- BPB_SecPerClus * FirstDataSector + ;
: FirstRootDirSecNum BPB_RsvdSecCnt BPB_NumFATs BPB_FATSz16 * + ;
: ClusterSize BPB_SecPerClus BPB_BytsPerSec * ;

\ Read multiple sectors in buf
: readsectors ( sec u buf -- )
  A>r swap >r swap >A begin
    A> over (drv@) A+ drvblksz + next drop r>A ;

create FAT16( BPB_BytsPerSec BPB_FATSz16 * allot
here value )FAT16
: readFAT BPB_RsvdSecCnt BPB_FATSz16 FAT16( readsectors ;

32 const DIRENTRYSZ
11 const FNAMESZ
: DIR_Name ( direntry -- sa sl ) FNAMESZ ;
: DIR_Cluster ( direntry -- cluster ) 26 + w@ ;
: DIR_FileSize ( direntry -- sz ) 28 + @ ;

\ A buffer where dir entries are copied before we search in them. It's big
\ enough to hold the root dir entries. This means that no directory in the
\ filesystem can have more than BPB_RootEntCnt entries.
create dirbuf( RootDirSectors BPB_BytsPerSec * allot
here const )dirbuf
create fnbuf FNAMESZ allot

: upcase ( c -- c ) dup 'a' - 26 < if $df and then ;

\ We assume a 8.3 name - DO NOT call this with an inadequate name.
: _tofnbuf ( fname -- )
  A>r >A Ac@+ >r fnbuf FNAMESZ SPC fill fnbuf begin
    Ac@+ dup '.' = if 2drop fnbuf 8 + upcase swap c!+ then
    next drop r>A ;

\ Search in the directory that is currently loaded in dirbuf.
\ Returns the address of the dir entry, aborts if not found.
: findindir ( fname -- direntry ) _tofnbuf
  dirbuf( begin
    dup )dirbuf < while
    fnbuf over DIR_Name []= not while DIRENTRYSZ + repeat
    else abort" file not found" then ;

\ Make the current dir the root dir
: readroot FirstRootDirSecNum RootDirSectors dirbuf( readsectors ;

\ Get the cluster following this one
: nextcluster ( cluster -- nextcluster )
  abort" TODO" ;

\ File cursor
\ 2b first cluster
\ 2b current cluster in buf
\ 4b cur pos (offset from beginning of file)
\ 4b file size
\ Xb current cluster X=ClusterSize
4 const FCURSORCNT \ maximum number of opened files
: FCursorSize ClusterSize 12 + ;
: FCUR_cluster0 ( fcur -- n ) w@ ;
: FCUR_cluster ( fcur -- n ) 2 + w@ ;
: FCUR_pos ( fcur -- n ) 4 + @ ;
\ return pos and post-inc it
: FCUR_pos+ ( fcur -- n ) 4 + dup @ 1 rot +! ;
: FCUR_buf( ( fcur -- a ) 12 + ;

create fcursors( FCursorSize FCURSORCNT * allot
here value )fcursor
fcursors( value nextfcursor

: readcluster ( cluster dst -- )
  swap FirstSectorOfCluster swap BPB_SecPerClus swap readsectors ;

: fat16open ( direntry -- fcursor )
  nextfcursor )fcursor = if abort" out of file cursors!" then
  dup DIR_Cluster dup nextfcursor FCUR_buf( readcluster
  dup nextfcursor w! nextfcursor 2 + w!
  0 nextfcursor 4 + ! DIR_FileSize nextfcursor 8 + !
  nextfcursor FCursorSize to+ nextfcursor ;

: fat16read ( fcursor -- c )
  dup FCUR_pos+ ClusterSize mod over FCUR_buf( + c@
  over FCUR_pos ClusterSize mod not if
    abort" TODO"
  then nip ;
