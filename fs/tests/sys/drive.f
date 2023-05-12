\ Tests for sys/ramdrive
\ Requires sys/scratch

?f<< tests/harness.f

testbegin

$36 8 drvseek 8 []>str S" FAT16   " #s=

testend
