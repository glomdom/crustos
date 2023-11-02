bootfile drv/ramdrive.f

\ Drive in RAM

\ This implements the "drive" protocol, which for now is undocumented, on top
\ of an area in RAM

512 const RAMDRVSECSZ
0 value ramdrv(

: _addr ( blkno -- a ) RAMDRVSECSZ * ramdrv( + ;
: ramdrv@ ( blkno buf -- )
  swap _addr swap RAMDRVSECSZ move ;
: ramdrv! ( blkno buf -- )
  swap _addr RAMDRVSECSZ move ;
