\ Initialization Layer
\ Called at the end of boot.f

f<< sys/doc.f
f<< lib/io.f
f<< sys/scratch.f
f<< sys/drive.f
RAMDRVSECSZ to drvblksz
fatfs( to ramdrv(
' ramdrv@ to (drv@)
' ramdrv! to (drv!)
f<< sys/file.f
f<< lib/nfmt.f
f<< lib/diag.f
f<< sys/xhere.f
f<< sys/rdln.f
f<< lib/btrace.f

: init S" crustOS" stype nl> .free rdln$ quit ;
init
