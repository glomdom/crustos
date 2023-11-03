\ x86 bootloader
?f<< /asm/i386.f

here to ORG here $200 0 fill
$26 jmp,    \ bypass BPB
$21 allot
ax $0e58 i) mov,
$10 int,
here jmp,
$55 ORG $1fe + c!+ $aa swap c!
