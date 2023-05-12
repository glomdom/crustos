\ Tests for sys/ramdrive
\ Requires sys/scratch

?f<< tests/harness.f

testbegin

0 drv@
drvbuf( $36 + 8 []>str S" FAT16   " #s=

testend
