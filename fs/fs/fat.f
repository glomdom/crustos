\ FAT filesystem implementation

\ Because FAT is a bootable filesystem, this unit rests on the "fatlo" part,
\ which has been loaded at boot time (or simply prior to this unit, if the boot
\ filesystem wasn't FAT).

\ because it uses words from "fatlo" that aren't always prefixed with "fat",
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
: FAT! ( entry cluster -- ) FAT12? if FAT12! else FAT16! then ;

: zerocluster ( cluster -- )
  fatbuf( BPB_BytsPerSec 0 fill
  FirstSectorOfCluster BPB_SecPerClus >r begin
    fatbuf( (drv!) 1+ next drop ;

\ Find a free cluster from the FAT.
: findfreecluster ( -- cluster )
  1 begin 1+ dup FAT@ not until ;

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
