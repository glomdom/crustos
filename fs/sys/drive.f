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

\ The Drive subsystem holds a temporary buffer and manages it. This buffer can
\ be larger than `drvblksz` to accommodate the possibility of hot-switching
\ storage drivers, but it *has* to be at least `drvblksz` in bytes.

$400 const DRVBUFSZ
create drvbuf( DRVBUFSZ allot
DRVBUFSZ value drvblksz

( blkno buf -- )
alias abort (drv@)

( blkno buf -- )
alias abort (drv!)

: drv@ ( blkno -- ) drvbuf( (drv@) ;
: drv! ( blkno -- ) drvbuf( (drv!) ;
