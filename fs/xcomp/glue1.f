bootfile xcomp/glue1.f

\ Located between the storage driver and the FS Handler

fatfs( to ramdrv(
RAMDRVSECSZ const drvblksz
alias ramdrv@ (drv@)
