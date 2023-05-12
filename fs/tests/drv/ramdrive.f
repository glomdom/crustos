\ Tests for the ramdrive
\ Requires sys/scratch

?f<< tests/harness.f
?f<< drv/ramdrive.f

require sys/scratch.f

testbegin

fatfs( to ramdrv(
0 here ramdrv@
here $36 + 8 []>str S" FAT16   " #s=

testend
