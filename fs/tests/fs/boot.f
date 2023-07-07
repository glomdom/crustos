\ Tests for fs/boot

\ These tests run on a few assumptions:
\ 1. the boot fs is a FAT16 fs
\ 2. current drive has it at its 0th block
\ 3. it has only one FAT (no backup FAT)
\ 4. it has a 512 sector size

?f<< tests/harness.f
?f<< fs/boot.f

: readN ( fcursor n -- ) >r begin dup fat16getc drop next drop ;

testbegin

readFAT
readroot

S" tests" findindir readdir
S" fattest" findindir
openfile dup fat16getc 'T' #eq
dup $ff readN
dup fat16getc 'f' #eq dup fat16getc 'o' #eq dup fat16getc 'o' #eq
dup $fd readN
dup fat16getc 'b' #eq
dup $dfc readN
dup fat16getc 'E' #eq dup fat16getc 'O' #eq dup fat16getc 'F' #eq
fat16getc 0 #eq

testend
