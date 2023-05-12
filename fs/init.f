\ Initialization Layer
\ Called at the end of boot.f

f<< lib/core.f
f<< lib/dict.f
f<< lib/annotate.f
f<< sys/doc.f
f<< lib/io.f
f<< sys/scratch.f
f<< sys/drive.f
f<< drv/ramdrive.f
fatfs( to ramdrv(
RAMDRVSECSZ to drvblksz
' ramdrv@ to (drv@)
' ramdrv! to (drv!)
f<< lib/file.f
f<< lib/nfmt.f
f<< lib/diag.f
f<< sys/xhere.f
f<< sys/rdln.f

: init S" crustOS" stype nl> .free rdln$ ;
init
