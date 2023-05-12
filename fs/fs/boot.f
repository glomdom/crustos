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

: fat16$ 0 drv@ drvbuf( bpb BPBSZ move ;
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
create fnbuf 11 allot

: upcase ( c -- c ) dup 'a' - 26 < if $df and then ;

\ We assume a 8.3 name - DO NOT call this with an inadequate name.
: _tofnbuf ( fname -- )
  A>r >A Ac@+ >r fnbuf 11 SPC fill fnbuf begin
    Ac@+ dup '.' = if 2drop fnbuf 8 + upcase swap c!+ then
    next drop r>A ;

\ Search in the directory that is currently loaded in drvbuf.
\ Returns the address of the directory entry, or 0 if not found.
\ TODO: Support more than 1 sector dir entry
: findindir ( fname -- )
  16 >r drvbuf( begin
    fnbuf over 11 []= if r~ exit then DIRENTRYSZ + next
  abort" file not found" ;
