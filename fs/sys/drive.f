\ Drive Subsystem

\ Allow access to mass storage in a standardized manner. This subsystem
\ defines the (drv@) and (drv!) aliases and a storage driver is expected to plug
\ into it.

\ Blocks: this subsystem deals with the concept of "blocks", which is a bunch
\ of bytes of a definite size, always the same for a given device. It's the
\ driver that defines the size of those blocks and sets the `drvblksz` value to
\ this proper value.

\ (drv@) and (drv!) expect block number arguments, which means that we consider
\ the data held by the storage device to be an array of contiguous blocks of
\ `drvblksz` bytes in size.

\ The Drive subsystem holds a temporary buffer and manages it. This buffer should
\ be atleast twice as large as the largest drvblksz it's ever going to handle.
\ Being able to hold 2 blocks in memory in necessary for `drvseek`.

$1000 const DRVBUFSZ
create drvbuf( DRVBUFSZ allot
DRVBUFSZ >> value drvblksz

\ Block number currently in drvbuf(
-1 value drvcurblk

( blkno buf -- )
alias abort (drv@)

( blkno buf -- )
alias abort (drv!)

: drv@ ( blkno -- ) dup to drvcurblk drvbuf( (drv@) ;
: ?drv@ ( blkno -- ) dup drvcurblk = if drop else drv@ then ;

\ Ensure that the block containing the offset `off` (in bytes) is loaded and that
\ there's atleast `u` bytes following that offset which is present in the buffer.
\ `u` cannot be larger than `drvblksz`
: drvseek ( off u - a )
  dup drvblksz > if abort" cannot ensure that many bytes in drive buffer" then
  swap drvblksz /mod ?drv@
  tuck + drvblksz >= if drvcurblk 1+ drvbuf( drvblksz + (drv@) then
  drvbuf( + ;
