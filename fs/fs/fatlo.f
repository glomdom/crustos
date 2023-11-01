\ The "low" part of a FAT12/FAT16 Filesystem Implementation

\ This is a subset of FAT12/FAT16. It is designed to be embedded
\ right after `boot.f` and provide the means to continue bootstrapping
\ on.

\ Its goal is to provide fopen, fclose and fread. Nothing more. The rest of the
\ FAT12/FAT16 implementation is in fs/fat.f

\ This unit has access to a very small set of words, that is, words implemented
\ by boot.fs as well as (drv@) and drvblksz from the "drive" protocol, which is
\ implemented by a driver that is also inserted in the boot sequence.

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

create buf( BPB_BytsPerSec allot
here const )buf
0 value bufsec \ sector number of current buf
0 value bufseccnt \ number of sectors ahead for sequential read
0 value bufcluster \ cluster number of current buf

: readsector ( sec cnt -- ) to bufseccnt dup to bufsec buf( (drv@) ;

: FAT12@ ( cluster -- entry )
  dup dup >> + BPB_BytsPerSec /mod
  BPB_RsvdSecCnt + 0 readsector
  buf( + w@
  swap 1 and if 4 rshift else $fff and then ;
: FAT16@ ( cluster -- entry )
  << BPB_BytsPerSec /mod
  BPB_RsvdSecCnt + 0 readsector
  buf( + w@ ;
: FAT@ ( cluster -- entry )
  FAT12? if FAT12@ else FAT16@ then ;

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

create fnbuf( FNAMESZ allot
here const )fnbuf

: upcase ( c -- c ) dup 'a' - 26 < if $df and then ;
: fnbufclr fnbuf( FNAMESZ SPC fill ;

\ We assume a 8.3 name - DO NOT call this with an inadequate name.
: _tofnbuf ( fname -- )
  A>r >A Ac@+ >r fnbufclr fnbuf( begin
    Ac@+ dup '.' = if 2drop fnbuf( 8 + else upcase swap c!+ then
    next drop r>A ;

: _ ( -- direntry-or-0 )
  buf( begin
    dup )buf < while
    fnbuf( over DIR_Name []= not while DIRENTRYSZ + repeat
    else drop 0 then ;
: _findindir ( -- direntry )
  begin
    _ ?dup not while nextsector? not if abort" file not found" then
  repeat ;

\ Searches in the directory that is currently loaded in `dirbuf`
\ Returns the address of the direntry entry, and aborts if it isn't found
: findindir ( fname -- direntry ) _tofnbuf _findindir ;

\ Make the current directory the root
: readroot 1 to bufcluster FirstRootDirSecNum RootDirSectors readsector ;

\ Read specified `direntry` in dirbuf(
\ Errors if it has more entries than BPB_RootEntCnt
: readdir ( direntry -- )
  DIR_Cluster dup to bufcluster FirstSectorOfCluster BPB_SecPerClus readsector ;

: findpath ( path -- direntry )
  A>r fnbufclr fnbuf( >A c@+ >r readroot begin
    c@+ case
      '.' of = fnbuf( 8 + >A endof
      '/' of = _findindir readdir fnbufclr fnbuf( >A endof
      r@ upcase Ac!+ A> )fnbuf = if abort" filename too long" then
    endcase
  next drop
  _findindir r>A ;

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

: fat16open ( path -- fcursor ) findpath openfile ;

: fat16getc ( fcursor -- c )
  dup FCUR_pos over FCUR_size = if drop -1 exit then
  dup FCUR_pos+ ClusterSize mod over FCUR_buf( + c@
  over FCUR_pos ClusterSize mod not if
    over FCUR_cluster FAT@
    dup EOC? if drop else
      dup 2 < if abort" cluster out of range" then
      rot 2dup FCUR_cluster!
      tuck FCUR_buf( readcluster swap then
  then nip ;

: fat16close ( fcursor ) 0 swap w! ;
