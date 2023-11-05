\ x86 bootloader
?f<< /asm/i386.f

1 to realmode

create ORG here $200 0 fill
$26 jmp,    \ bypass BPB
$23 allot
ax $0e58 i) mov,
$10 int,
here jmp,

0 jmp,      \ infinite loop
$55 ORG $1fe + c!+ $aa swap c!
