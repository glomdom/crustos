\ Initialization Layer
\ Called at the end of boot.f

0 S" sys" fchild S" file.f" fchild fload

f<< sys/doc.f
f<< sys/scratch.f
f<< sys/drive.f
RAMDRVSECSZ to drvblksz
fatfs( to ramdrv(
' ramdrv@ to (drv@)
' ramdrv! to (drv!)
f<< lib/nfmt.f
f<< lib/diag.f
f<< sys/xhere.f
f<< sys/rdln.f
f<< lib/btrace.f

: init S" crustOS" stype nl> .free rdln$ quit ;
init
