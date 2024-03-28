\ x86 bootloader

1 to realmode

create ORG here $200 0 fill
$26 jmp,    \ bypass BPB
$23 allot
cli, cld,

ax $0201 i) mov, bx $8000 i) mov, cx $0002 i) mov, dx $0000 i) mov, $13 int,
ax $8000 i) mov, ax jmp,
ORG $1fe + to here $55 c, $aa c,
