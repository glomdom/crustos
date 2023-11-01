\ FAT filesystem implementation

\ Because FAT is a bootable filesystem, this unit rests on the "fatlo" part,
\ which has been loaded at boot time (or simply prior to this unit, if the boot
\ filesystem wasn't FAT).

\ Because it uses words from "fatlo" that aren't always prefixed with "fat",
\ it's better to have this until loaded early in init.f to avoid name clashes.

\ For now, this FS only supports FAT16 and FAT12.

\ Like any filesystem in Crust, path separator char is "/".

?f<< fs/fatlo.f

$ffff const EOC

: writecursector ( -- ) bufsec fatbuf( (drv!) ;

: FAT12! ( entry cluster -- )
  dup FAT12' dup w@ rot 1 and if
    $f and rot 4 lshift or
  else
    $f000 and rot $fff and or then
  swap w! ;
: FAT16! ( entry cluster -- ) FAT16' w! ;
: FAT! ( entry cluster -- ) FAT12? if FAT12! else FAT16! then writecursector ;

: zerocluster ( cluster -- )
  fatbuf( BPB_BytsPerSec 0 fill
  FirstSectorOfCluster BPB_SecPerClus >r begin
    fatbuf( (drv!) 1+ next drop ;

\ Find a free cluster from the FAT.
: findfreecluster ( -- cluster )
  1 begin 1+ dup FAT@ not until ;

\ Get next FAT entry and if it's EOC, allocate a new one
: FAT@+ ( cluster -- entry )
  dup FAT@ dup EOC? if
    drop findfreecluster 2dup swap FAT!
    EOC swap FAT!
  else nip then ;

\ Try to find in the current buffer.
: _findinsec ( -- a-or-0 )
  fatbuf( begin
    dup c@ dup $e5 = swap not or if exit then
    DIRENTRYSZ + dup )fatbuf >= until drop 0 ;

\ Find free `direntry` in current buffer.
: findfreedirentry ( -- direntry )
  begin
    _findinsec ?dup not while
    nextsector? while
  repeat \ nothing found, extend chain
    findfreecluster dup zerocluster
    dup bufcluster FAT! EOC swap FAT!
    nextsector? fatbuf(
  else \ found, return `a` if good
  then ;

\ Creates a new file at `path`
: fatnewfile ( path -- direntry )
  fatfindpathdir findfreedirentry
  dup DIRENTRYSZ 0 fill
  fnbuf( swap FNAMESZ move writecursector ;

\ Write multiple sectors from `buf`
: writesectors ( sec u buf -- )
  A>r swap >r swap >A begin
    A> over (drv!) A+ drvblksz + next drop r>A ;

: writecluster ( cluster src -- )
  over 2 - $fff6 > if abort" cluster out of range!" then
  swap FirstSectorOfCluster swap BPB_SecPerClus swap writesectors ;

: _ ( fcursor -- ) \ fatflush
  dup FCUR_dirty? not if drop exit then
  dup FCUR_cluster over FCUR_buf( writecluster
  dup FCUR_dirent over FCUR_size swap DIR_FileSize!
  writecursector
  dup FCUR_flags $fffffffd and swap FCUR_flags! ;
current to fatflush

\ Grow `fcursor` to `newsz`, if needed.
: fatgrow ( newsz fcursor -- )
  2dup FCUR_size <= if 2drop exit then
  dup >r FCUR_size! r@ FCUR_cluster0
  ?dup not if findfreecluster then
  r@ FCUR_dirent 2dup DIR_Cluster!
  r@ FCUR_size swap DIR_FileSize! writecursector
  r> FCUR_size ClusterSize / ?dup if
    >r begin FAT@+ next then drop ;

\ Write `c` to `fcursor` and advance the position by 1, growing the file
\ if needed.
: fatputc ( c fcursor -- )
  dup >r FCUR_pos 1+ dup 1+ r@ fatgrow
  r@ fatseek
  r@ FCUR_flags 2 or r@ FCUR_flags!
  r> FCUR_bufpos c! ;
