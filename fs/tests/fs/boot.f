\ Tests for fs/boot

\ These tests run on a few assumptions:
\ 1. the boot fs is a FAT16 fs
\ 2. current drive has it at its 0th block
\ 3. it has only one FAT (no backup FAT)
\ 4. it has a 512 sector size

?f<< tests/harness.f
?f<< fs/boot.f

testbegin

readroot
S" init.f" findindir
FNAMESZ []>str S" INIT   FS " #s=

testend
