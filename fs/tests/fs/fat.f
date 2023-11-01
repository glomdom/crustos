\ Tests for fs/fat

\ These tests run on a few assumptions:
\ 1. the boot fs is a FAT16 fs
\ 2. current drive has it at its 0th block
\ 3. it has only one FAT (no backup FAT)
\ 4. it has a 512 sector size

?f<< tests/harness.f
?f<< fs/fat.f

: readN ( fcursor n -- ) >r begin dup fatgetc drop next drop ;

testbegin

S" tests/fattest" fatfindpath
openfile dup fatgetc 'T' #eq
dup $ff readN
dup fatgetc 'f' #eq dup fatgetc 'o' #eq dup fatgetc 'o' #eq
dup $fd readN
dup fatgetc 'b' #eq
dup $dfc readN
dup fatgetc 'E' #eq dup fatgetc 'O' #eq dup fatgetc 'F' #eq
dup fatgetc -1 #eq
fatclose

S" lib" fatchdir
S" str.f" fatfindpath # \ found
S" /lib/str.f" fatfindpath # \ found

\ lets go back one
S" .." fatchdir
S" lib/str.f" fatfindpath # \ found
S" /lib/str.f" fatfindpath # \ found

\ can we create new file?
S" newfile" fatnewfile #
S" /newfile" fatfindpath # \ yes we can

\ lets try writing to it
S" /newfile" fatfindpath openfile
dup FCUR_cluster0 0 #eq \ no cluster allocated yet
'4' over fatputc '2' over fatputc fclose
f<< /newfile 42 #eq

testend
