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

32 const DIRENTRYSZ
\ A buffer where dir entries are copied before we search in them. It's big
\ enough to hold the root dir entries. This means that no directory in the
\ filesystem can have more than BPB_RootEntCnt entries.
create dirbuf( RootDirSectors BPB_BytsPerSec * allot
here const )dirbuf
11 const FNAMESZ
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
    fnbuf over FNAMESZ []= not while DIRENTRYSZ + repeat
    else abort" file not found" then ;
  
\ Make the current dir the root dir
: readroot A>r RootDirSectors >r FirstRootDirSecNum >A dirbuf( begin
  A> over (drv@) A+ drvblksz + next drop r>A ;
