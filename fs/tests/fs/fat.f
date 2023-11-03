?f<< tests/harness.f
?f<< fs/fat.f

: fatgetc ( fcursor -- c ) 1 swap fatreadbuf if c@ else -1 then ;

testbegin

\ These tests run on a few assumptions:
\ 1. the boot fs is a FAT16 fs
\ 2. current drive has it at its 0th block
\ 3. it has only one FAT (no backup FAT)
\ 4. it has a 512 sector size

S" tests/fattest" findpath# fatopen
dup fatgetc 'T' #eq
$100 over fatseek
dup fatgetc 'f' #eq dup fatgetc 'o' #eq dup fatgetc 'o' #eq
$200 over fatseek
dup fatgetc 'b' #eq
$ffd over fatseek
dup fatgetc 'E' #eq dup fatgetc 'O' #eq dup fatgetc 'F' #eq
dup fatgetc -1 #eq
fatclose

\ can we create new file?
0 S" newfile" fatnewfile #
S" /newfile" findpath# \ yes we can

\ lets try writing to it
fatopen
dup FCUR_cluster0 0 #eq \ no cluster allocated yet
dup S" 42" c@+ rot fatwritebuf 2 #eq fclose
f<< /newfile 42 #eq

testend
